#!/usr/bin/env bash
# Step 5 - Archive / Backup Version.
#
# This file creates timestamped rollback archives and removes older archives
# when --keep is configured. Archive names include the PipePilot version so the
# backup history is connected to semantic versioning.

archive_extension() {
    case "$COMPRESSION" in
        gzip) echo "tar.gz" ;;
        xz) echo "tar.xz" ;;
        zip) echo "zip" ;;
    esac
}

cleanup_old_archives() {
    [[ "$KEEP_ARCHIVES" -gt 0 ]] || return 0
    find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "$(basename "$PROJECT_PATH")-*.*" \
        | sort -r \
        | awk "NR>$KEEP_ARCHIVES" \
        | while IFS= read -r old_archive; do
            rm -f "$old_archive"
            log_info "[ARCHIVE] Removed old archive $old_archive"
        done
}

stage_archive() {
    if [[ "$NO_ARCHIVE" -eq 1 ]]; then
        log_info "[ARCHIVE] Skipped by --no-archive"
        return "$OK"
    fi

    mkdir -p "$ARCHIVE_DIR"
    local project_name archive_name parent_dir base_name
    project_name="$(basename "$PROJECT_PATH")"
    archive_name="${project_name}-$(timestamp)-v$(pipepilot_version).$(archive_extension)"
    LATEST_ARCHIVE="$ARCHIVE_DIR/$archive_name"
    parent_dir="$(dirname "$PROJECT_PATH")"
    base_name="$(basename "$PROJECT_PATH")"

    case "$COMPRESSION" in
        gzip)
            tar -czf "$LATEST_ARCHIVE" -C "$parent_dir" --exclude="$base_name/.git" "$base_name" || return "$ERR_ARCHIVE"
            ;;
        xz)
            tar -cJf "$LATEST_ARCHIVE" -C "$parent_dir" --exclude="$base_name/.git" "$base_name" || return "$ERR_ARCHIVE"
            ;;
        zip)
            require_command zip "$ERR_DEPENDENCY"
            ( cd "$parent_dir" && zip -qr "$LATEST_ARCHIVE" "$base_name" -x "$base_name/.git/*" ) || return "$ERR_ARCHIVE"
            ;;
    esac

    cleanup_old_archives
    log_info "[ARCHIVE] $archive_name created"
    return "$OK"
}

