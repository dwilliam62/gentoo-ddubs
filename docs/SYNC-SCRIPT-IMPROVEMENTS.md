# sync-gentoo-cfg.sh Improvements

## Overview

The `scripts/sync-gentoo-cfg.sh` script has been significantly improved from a basic rsync wrapper to a production-ready system configuration backup tool. This document outlines the improvements made.

## Key Improvements

### 1. **Error Handling & Safety**
- Added `set -euo pipefail` for strict error checking
- Permission validation before syncing
- Graceful handling of missing files/directories
- Non-fatal errors (using `|| true`) to continue even if individual sync fails

### 2. **Command-Line Options**
```bash
bash scripts/sync-gentoo-cfg.sh --help       # Show help
bash scripts/sync-gentoo-cfg.sh --dry-run    # Preview changes without modifying
bash scripts/sync-gentoo-cfg.sh --quiet      # Suppress verbose output
```

### 3. **Comprehensive Configuration Capture**
Now captures:
- **Portage configs**: `/etc/portage/*` (make.conf, package.*, repos.conf, savedconfig, etc.)
- **Portage database**: `/var/lib/portage/world` and metadata
- **System configs**: fstab, locale, hostname, hosts, resolv.conf, environment, profile
- **Kernel config**: `/usr/src/linux/.config`
- **Module configs**: `/etc/modprobe.d/`
- **Systemd units**: Complete `/etc/systemd/` hierarchy
- **System metadata**: emerge-info, eselect-profile, uname, os-release

### 4. **Logging & Auditability**
- All sync operations logged to `.sync-logs/sync-TIMESTAMP.log`
- Timestamped messages with detailed file-by-file tracking
- Separate error stream for troubleshooting
- Log files preserved for historical audit trail

### 5. **User-Friendly Output**
- Clear section headers for each sync phase
- Success/failure indicators (✓/✗) for each operation
- Informative messages showing what's being synced
- Final summary with log file location

### 6. **Smart Directory Creation**
- Uses `rsync --mkpath` to create destination directories automatically
- No need to pre-create directory structure
- Scales well to new config locations

### 7. **Documentation**
New companion documents created:
- **MIGRATION.md** — Complete guide for restoring configuration to new systems
- **CAPTURED-DIRECTORIES.md** — Detailed inventory of what gets backed up and why

### 8. **Git Integration**
- Updated `.gitignore` to exclude:
  - `.sync-logs/` directory (contains local logs, not needed in git)
  - Portage cache files (preserved_libs_registry, config, repo_revisions)
- Added `.sync-logs/.gitkeep` to preserve directory structure
- Actual config changes are tracked in git for version control

## Before vs After

### Before
```bash
#!/usr/bin/env bash
echo "Syncing /etc/portage"
sudo rsync -av --delete /etc/portage ~/gentoo-ddubs/system/etc/portage/ 
echo "Syncing /var/lib/portage"
sudo rsync -av  /var/lib/portage/  ~/gentoo-ddubs/system/var/lib/portage/ 
```

**Limitations:**
- Only backed up 2 directories
- Used `--delete` which is dangerous on target
- No error handling
- No logging
- No way to do dry-run
- No way to verify what's being synced

### After
```bash
#!/usr/bin/env bash
set -euo pipefail
# [100+ lines of proper bash scripting]
# Captures 8+ major config sections
# Supports --dry-run, --quiet, --help
# Full logging and error handling
# Metadata exports
```

**Improvements:**
- Captures 8+ major configuration sections
- Full error handling and logging
- Dry-run mode for safe previewing
- Quiet mode for automation
- Help documentation
- All operations timestamped and auditable
- Non-fatal errors allow script to continue

## Usage Examples

### Preview what will be synced
```bash
bash scripts/sync-gentoo-cfg.sh --dry-run
```

### Regular backup with verbose output
```bash
bash scripts/sync-gentoo-cfg.sh
```

### Quiet mode (good for cron)
```bash
bash scripts/sync-gentoo-cfg.sh --quiet
```

### Commit captured changes
```bash
bash scripts/sync-gentoo-cfg.sh
git add -A
git commit -m "sync: update gentoo config snapshot ($(date +%Y-%m-%d))"
git push
```

## Log File Locations

Each sync creates a timestamped log:
```
.sync-logs/sync-1764181318.log
```

View latest sync:
```bash
tail -50 .sync-logs/sync-*.log
```

## Testing Results

✅ Script validated on gentoo-vm with:
- Dry-run mode: Successfully previewed all syncs
- Full sync: Captured all system and Portage configurations
- Metadata exports: emerge-info, eselect-profile, uname, os-release
- Log creation: Proper timestamped logs in .sync-logs/
- Help function: Display and parse options correctly
- Error handling: Graceful handling of all file types

## Future Enhancements

Potential improvements for future versions:
1. **Selective sync**: `--only-portage`, `--only-system`, `--only-kernel`
2. **Compression**: Optional tar.gz archiving of snapshots
3. **Remote backup**: SSH push to remote host
4. **Scheduling**: Built-in cron setup
5. **Notifications**: Email on sync completion/failure
6. **Incremental diff**: Show what changed since last sync
7. **Pre/post hooks**: Custom scripts before/after sync

## Related Documentation

- [MIGRATION.md](./MIGRATION.md) — How to restore configs to a new system
- [CAPTURED-DIRECTORIES.md](./CAPTURED-DIRECTORIES.md) — Detailed inventory of captures
- [README.md](../README.md) — Main project overview
- [CHANGELOG.md](../CHANGELOG.md) — Historical changes
