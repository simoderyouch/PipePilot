#!/usr/bin/env bash
# Remote helper used by PipePilot setup_remote_server.
#
# This file is streamed to the remote host through SSH. The local deploy stage
# prepends environment assignments before this script runs, so keep these
# variable names in sync with stages/06_deploy.sh.

set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

detect_pm() {
    if [ "$PACKAGE_MANAGER_CHOICE" != "auto" ]; then
        echo "$PACKAGE_MANAGER_CHOICE"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

install_packages() {
    pm="$(detect_pm)"
    case "$APP_KIND:$BACKEND_RUNTIME_VALUE:$pm" in
        backend:python:apk) PACKAGES="python3 py3-pip py3-virtualenv nginx rsync curl" ;;
    esac

    case "$pm" in
        apt)
            $SUDO apt-get update -y
            DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y $PACKAGES
            ;;
        dnf)
            $SUDO dnf install -y $PACKAGES
            ;;
        yum)
            $SUDO yum install -y $PACKAGES
            ;;
        apk)
            $SUDO apk add --no-cache $PACKAGES
            ;;
        *)
            echo "No supported package manager found" >&2
            exit 113
            ;;
    esac
}

configure_nginx() {
    if ! command -v nginx >/dev/null 2>&1; then
        return 0
    fi

    SERVER_SLUG="$(printf '%s' "$SERVER_NAME" | tr -c 'A-Za-z0-9_.-' '_')"
    LEGACY_SERVER_SLUG="$(printf '%s\n' "$SERVER_NAME" | tr -c 'A-Za-z0-9_.-' '_')"
    EXISTING_CONF=""

    if [ "$SERVER_NAME" != "_" ]; then
        $SUDO rm -f \
            /etc/nginx/sites-enabled/pipepilot-__ \
            /etc/nginx/sites-available/pipepilot-__ \
            /etc/nginx/conf.d/pipepilot-__.conf
    fi

    if [ -f "/etc/nginx/sites-available/pipepilot-$SERVER_SLUG" ]; then
        EXISTING_CONF="/etc/nginx/sites-available/pipepilot-$SERVER_SLUG"
    elif [ -f "/etc/nginx/conf.d/pipepilot-$SERVER_SLUG.conf" ]; then
        EXISTING_CONF="/etc/nginx/conf.d/pipepilot-$SERVER_SLUG.conf"
    fi

    FRONTEND_ROOT=""
    BACKEND_PORT=""

    if [ "$APP_KIND" = "frontend" ]; then
        FRONTEND_ROOT="$TARGET_PATH"
    elif [ -n "$EXISTING_CONF" ]; then
        FRONTEND_ROOT="$(awk '/^[[:space:]]*root[[:space:]]+/ { gsub(/;/, "", $2); print $2; exit }' "$EXISTING_CONF")"
    fi

    if [ -n "$APP_PORT_VALUE" ]; then
        BACKEND_PORT="$APP_PORT_VALUE"
    elif [ -n "$EXISTING_CONF" ]; then
        BACKEND_PORT="$(sed -n 's#.*proxy_pass http://127\.0\.0\.1:\([0-9][0-9]*\).*#\1#p' "$EXISTING_CONF" | head -1)"
    fi

    if [ -n "$FRONTEND_ROOT" ] && [ -n "$BACKEND_PORT" ]; then
        NGINX_BODY="server {
    listen 80;
    server_name $SERVER_NAME;
    root $FRONTEND_ROOT;
    index index.html;

    location = /api {
        return 308 /api/;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:$BACKEND_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}"
    elif [ -n "$BACKEND_PORT" ]; then
        NGINX_BODY="server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:$BACKEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}"
    elif [ -n "$FRONTEND_ROOT" ]; then
        NGINX_BODY="server {
    listen 80;
    server_name $SERVER_NAME;
    root $FRONTEND_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}"
    else
        return 0
    fi

    if [ -d /etc/nginx/sites-available ]; then
        CONF_NAME="pipepilot-$SERVER_SLUG"
        if [ "$LEGACY_SERVER_SLUG" != "$SERVER_SLUG" ]; then
            $SUDO rm -f \
                "/etc/nginx/sites-enabled/pipepilot-$LEGACY_SERVER_SLUG" \
                "/etc/nginx/sites-available/pipepilot-$LEGACY_SERVER_SLUG"
        fi
        echo "$NGINX_BODY" | $SUDO tee "/etc/nginx/sites-available/$CONF_NAME" >/dev/null
        $SUDO ln -sf "/etc/nginx/sites-available/$CONF_NAME" "/etc/nginx/sites-enabled/$CONF_NAME"
        $SUDO nginx -t
        $SUDO systemctl reload nginx || $SUDO service nginx reload || true
    elif [ -d /etc/nginx/conf.d ]; then
        CONF_NAME="pipepilot-$SERVER_SLUG.conf"
        if [ "$LEGACY_SERVER_SLUG" != "$SERVER_SLUG" ]; then
            $SUDO rm -f "/etc/nginx/conf.d/pipepilot-$LEGACY_SERVER_SLUG.conf"
        fi
        echo "$NGINX_BODY" | $SUDO tee "/etc/nginx/conf.d/$CONF_NAME" >/dev/null
        $SUDO nginx -t
        $SUDO systemctl reload nginx || $SUDO service nginx reload || true
    fi
}

install_packages
$SUDO mkdir -p "$TARGET_PATH"
$SUDO chown -R "$REMOTE_USER_NAME":"$REMOTE_USER_NAME" "$TARGET_PATH" 2>/dev/null || true
configure_nginx

if [ -n "$EXTRA_SETUP_CMD" ]; then
    bash -lc "$EXTRA_SETUP_CMD"
fi
