# Captured Directories and Files

This document lists all directories and configuration files captured by `scripts/sync-gentoo-cfg.sh` for migration and restoration purposes.

## Directory Structure in `system/`

```
system/
├── boot/
│   └── config-*                 # Installed kernel configs (reference)
├── etc/
│   ├── environment              # Shell environment variables
│   ├── fstab                    # Filesystem mount configuration
│   ├── hostname                 # System hostname
│   ├── hosts                    # DNS hostname mappings
│   ├── locale.conf              # Locale configuration
│   ├── locale.gen               # Locale generation list
│   ├── profile                  # Shell profile initialization
│   ├── resolv.conf              # DNS resolver configuration
│   ├── modprobe.d/              # Kernel module options
│   │   ├── *.conf               # Module configurations
│   │   └── ...
│   ├── portage/                 # Portage package manager config (CRITICAL)
│   │   ├── make.conf            # Global build flags, USE flags, compiler settings
│   │   ├── make.profile -> ...  # Active profile symlink
│   │   ├── repos.conf/          # Repository configurations (Gentoo, overlays, etc.)
│   │   ├── package.use/         # Per-package USE flags
│   │   ├── package.accept_keywords/  # Per-package keyword settings
│   │   ├── package.env/         # Per-package environment settings
│   │   ├── package.license/     # Per-package license settings
│   │   ├── package.mask/        # Masked packages
│   │   ├── binrepos.conf/       # Binary repository configurations
│   │   ├── savedconfig/         # Saved build-time configurations
│   │   └── postsync.d/          # Post-sync hook scripts
│   └── systemd/                 # Systemd configuration (CRITICAL)
│       ├── journald.conf        # Journal logging configuration
│       ├── logind.conf          # Login manager configuration
│       ├── resolved.conf        # DNS resolver configuration
│       ├── system/              # System service unit files
│       │   ├── *.service        # Service definitions
│       │   ├── *.target         # Target definitions
│       │   └── ...
│       ├── system-generators/   # Generators for unit file creation
│       ├── network/             # Network configuration
│       │   ├── *.netdev         # Virtual network device definitions
│       │   └── *.network        # Network settings
│       ├── network-online.target.wants/  # Network startup dependencies
│       ├── multi-user.target.wants/      # Multi-user target dependencies
│       ├── getty.target.wants/           # TTY startup dependencies
│       └── user/                # User session configuration
└── usr/
    └── src/
        └── linux/
            └── .config          # Kernel build configuration (CRITICAL)
```

## Directory Structure in `var/lib/portage/`

```
var/lib/portage/
├── world                       # Explicitly installed packages (seed list)
├── world_sets                  # Custom package set definitions
├── eclass/                     # Eclass cache (eclasses are Portage templates)
├── preserved-libs/            # Libraries preserved during updates
└── ...other Portage caches...
```

## Metadata Files in `docs/`

```
docs/
├── MIGRATION.md                # Detailed migration and restoration instructions
├── CAPTURED-DIRECTORIES.md     # This file
├── emerge-info.txt             # Portage and system configuration dump
│                               # Includes: Portage version, CFLAGS, USE flags,
│                               # Active profile, mirrors, available profiles, etc.
├── eselect-profile.txt         # Currently active profile
│                               # e.g., "default/linux/amd64/23.0/systemd"
├── os-release.txt              # Distribution identification
│                               # NAME, VERSION, PRETTY_NAME, etc.
└── uname.txt                   # Kernel and hardware information
                                # Includes: kernel version, arch, hostname, etc.
```

## Logs

Sync operations are logged to:

```
.sync-logs/
└── sync-TIMESTAMP.log          # Timestamped log from each sync run
                                # Contains file-by-file rsync output and success/error messages
```

## What Each Section Enables

### Portage Configuration (`etc/portage/`)
- Rebuilds packages with identical build flags and settings
- Includes repository sources (official Gentoo, overlays, binary repos)
- Preserves per-package customizations and masked/unstable packages
- Enables exact recreation of package selection and compilation

### Portage Database (`var/lib/portage/world`)
- Lists all explicitly installed packages
- Allows `emerge @world` to reinstall the same package set on a new system

### System Configuration (`etc/*.conf`, `/etc/modprobe.d/`, `/etc/systemd/`)
- Recreates network setup (hostname, DNS, filesystems)
- Preserves system services (getty, networking, custom units)
- Maintains boot configuration and module options
- Ensures locale and keyboard settings match

### Kernel Configuration (`usr/src/linux/.config`)
- Enables rebuilding the kernel with identical driver and feature selection
- Critical for systems with specific hardware needs (RAID, GPU drivers, etc.)

## Incremental Updates

After the initial sync, run `sync-gentoo-cfg.sh` periodically to capture:
- New packages added to `@world`
- Changes to `/etc/portage/*` (USE flags, keywords, etc.)
- Kernel configuration updates
- Systemd unit modifications
- New or modified system configurations

Each sync creates a timestamped log in `.sync-logs/` for audit purposes.

## Size Estimates

- `system/etc/portage/` — typically 5-30 MB (depending on custom packages and overlays)
- `system/var/lib/portage/world` — typically 10-50 KB
- `system/etc/systemd/` — typically 1-5 MB
- `system/usr/src/linux/.config` — typically 200-500 KB
- `docs/` metadata — typically 20-50 KB

**Total typical repository size: 10-50 MB** (very git-friendly with gzip compression)

## Restoration Priority

If restoring to a new system, apply in this order:

1. **Portage configuration** (`system/etc/portage/`) — enables correct package builds
2. **World set** (`system/var/lib/portage/world`) — defines what to build
3. **System configuration** (`system/etc/*.conf`, systemd, modprobe.d) — critical for boot and system services
4. **Kernel configuration** (`system/usr/src/linux/.config`) — rebuild kernel if needed

See [MIGRATION.md](./MIGRATION.md) for detailed restoration steps.
