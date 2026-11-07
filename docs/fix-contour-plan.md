# Contour Installation Plan for Other Gentoo Hosts

## Purpose

`scripts/install-contour.sh` was written and verified on the source host:

- Gentoo `default/linux/amd64/23.0/systemd`
- Portage 3.0.83
- `ACCEPT_KEYWORDS="amd64"` (stable), with the GURU packages keyword-accepted per package
- Qt 6.11.2 from the main tree (stable on amd64)
- `FEATURES` includes `getbinpkg` and `binpkg-request-signature`
- directory-based `/etc/portage/package.*` configuration
- `virtual/minizip` installed (so `zlib[minizip]` is present)
- `dev-qt/qtwayland` installed

The script fixes the issues found on that host, but it is **not a universal fix**. Before running it on the other three VMs or the hardware host, verify the conditions below and apply the host-specific fixes. Do not run the full installer until every STOP condition in Phase 1 is cleared.

## What the script already handles

- Installs `app-eselect/eselect-repository` if the eselect module is missing.
- Enables and syncs the GURU overlay (warns and continues if either step fails).
- Writes `/etc/portage/package.accept_keywords/contour` for:
  - `gui-apps/contour`, `media-libs/libunicode`, `dev-cpp/boxed-cpp`, `dev-cpp/reflection-cpp`
- Masks `>=media-libs/libunicode-0.8.0` (Contour 0.6.1 is incompatible with the 0.8 grapheme API).
- Writes `/etc/portage/package.use/contour` with `opengl` on `qtbase`, `qtdeclarative`, `qtmultimedia`, plus `sys-libs/zlib minizip`.
- Uses `--binpkg-respect-use=y` so binpkgs with non-matching USE are ignored instead of producing the “binary packages have been ignored” warning block.
- Uses `--oneshot` on the Qt rebuild so those dependencies are not added to `@world`.
- Warns when global USE or another `package.use` file re-enables `qml`/`vulkan`, and prints the effective flags from `equery uses`.
- Provides `--check-only`, which writes the Portage configuration, skips overlay setup (Steps 1–2), and previews both emerge commands with `--pretend`.

## What the script does not handle

| # | Condition | What happens | Required action |
|---|-----------|--------------|-----------------|
| 1 | `/etc/portage/package.use`, `package.accept_keywords` or `package.mask` is a single file, not a directory | `mkdir -p` fails and the script exits at Step 3 | Convert to directories after backing up (Phase 2.1) |
| 2 | Binary-only defaults: `EMERGE_DEFAULT_OPTS` contains `--usepkgonly` or `--getbinpkgonly` | Portage refuses to build from source when no matching binpkg exists; Step 1/6/7 fail | Remove the “only” option for this run (Phase 2.2) |
| 3 | Host tree has no Qt 6.11.x stable, or Qt is keyword-pinned older than Contour needs | `emerge` reports keyword changes or the Contour build fails on Qt API | Accept keywords for the minimum Qt stack, or skip that host (Phase 2.3) |
| 4 | Host is Wayland-only and `dev-qt/qtwayland` is not installed | Contour has no Wayland platform plugin; it may fail to start or fall back to XWayland | Install `dev-qt/qtwayland` if Wayland is the session (Phase 2.5) |
| 5 | No OpenGL 3.3 driver (common in minimal VMs) | Contour cannot create its rendering context | Install/configure Mesa or enable software rendering (Phase 2.6) |
| 6 | `virtual/minizip` is not installed | `sys-libs/zlib minizip` forces an unnecessary zlib rebuild | Optional: drop that line on this host (Phase 2.4) |
| 7 | GURU is unavailable/offline or has a newer Contour | Script warns but continues; a newer version may not need the libunicode mask | Verify GURU and the ebuild version before the full run (Phase 2.7) |
| 8 | Existing files at the three script-written paths | The script overwrites them without a backup | Back up/merge first (Phase 2.8) |
| 9 | `app-eselect/eselect-repository` is newly installed by Step 1 | It may be added to `@world` (Step 1 has no `--oneshot`) | Deselect it afterwards if it should not be in world (Phase 2.9) |
| 10 | `quickshell` is installed | Its GURU ebuild hard-requires `qtbase[vulkan]`; Vulkan cannot be dropped on that host | Leave Vulkan enabled; Contour does not need it (Phase 2.10) |
| 11 | Old Portage does not support `--binpkg-respect-use` | Step 6/7 fail with an unrecognized option | Upgrade Portage or remove the flag (Phase 2.11) |
| 12 | Low disk space or RAM | Qt source builds fail or OOM | Check and adjust before building (Phase 1) |

## Phase 0 — Safety and inventory

Run on each target host as an administrator. Do not skip the backup.

```bash
ts=$(date +%Y%m%d-%H%M%S)
sudo tar -C /etc -czf "/root/portage-backup-$ts.tgz" portage
sudo cp -a /var/lib/portage/world "/root/world-$ts"
```

Record the host facts:

```bash
emerge --version | head -1
eselect profile show | tail -3
portageq envvar ARCH
portageq envvar ACCEPT_KEYWORDS
emerge --info | grep -E '^(ACCEPT_KEYWORDS|USE|FEATURES|EMERGE_DEFAULT_OPTS|PORTAGE_BINHOST)=' | sort
df -h /var/tmp /usr
free -h
nproc
```

Guidelines for a Qt source rebuild (not hard limits): at least 10–15 GB free under `/var/tmp` and `/usr`, at least 4–8 GB RAM, and `MAKEOPTS` sized to the VM. On a small VM, use `--jobs=1` for the Qt emerge or lower `MAKEOPTS` to avoid OOM.

Check the Portage config layout now:

```bash
for p in package.use package.accept_keywords package.mask; do
  if [ -L "/etc/portage/$p" ]; then
    printf '%s -> symlink to %s\n' "$p" "$(readlink -f "/etc/portage/$p")"
  elif [ -d "/etc/portage/$p" ]; then
    printf '%s: directory (OK)\n' "$p"
  elif [ -f "/etc/portage/$p" ]; then
    printf '%s: SINGLE FILE (blocker; see Phase 2.1)\n' "$p"
  else
    printf '%s: missing\n' "$p"
  fi
done
```

## Phase 1 — Preflight and STOP conditions

Run all checks. Record the results in the host worksheet at the end.

### 1.1 GURU overlay

```bash
eselect repository list -i 2>/dev/null | grep -q guru && echo "guru listed" || echo "guru MISSING"
emaint sync -r guru
emerge -p gui-apps/contour 2>&1 | head -40
```

The last command must resolve `gui-apps/contour` without “no ebuilds” or “repository not found”. The script can enable GURU, but if `eselect repository enable guru` fails (network, permissions, missing module), do not continue until it is fixed.

### 1.2 Binary mode

```bash
opts=$(portageq envvar EMERGE_DEFAULT_OPTS 2>/dev/null || true)
printf 'EMERGE_DEFAULT_OPTS=%s\n' "$opts"
printf '%s\n' "$opts" | grep -Eq -- '--usepkgonly|--getbinpkgonly' \
  && echo "STOP: binary-only option present" \
  || echo "source fallback allowed"
emerge --info | grep -E '^(FEATURES|PORTAGE_BINHOST)='
```

`FEATURES=getbinpkg` alone is fine: Portage uses a matching binpkg when available and builds from source otherwise. `--usepkgonly` or `--getbinpkgonly` is a blocker; see Phase 2.2.

### 1.3 Portage option support

```bash
emerge -p --binpkg-respect-use=y sys-apps/portage >/dev/null 2>&1 \
  && echo "binpkg-respect-use supported" \
  || echo "STOP: option unsupported (Phase 2.11)"
```

### 1.4 Keywords and Qt availability

```bash
emerge -p gui-apps/contour 2>&1 | tee /tmp/contour-plan.txt | head -60
grep -nE 'keyword changes|The following|masked|blocked' /tmp/contour-plan.txt || true
emerge -p dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtmultimedia:6 dev-qt/qt5compat 2>&1 | head -40
qlist -Iv dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qt5compat dev-qt/qtwayland 2>/dev/null
```

Expected on a current stable amd64 tree: Qt 6.11.x is stable and Portage selects it without a keyword cascade. If Portage reports keyword changes for Qt, resolve them in Phase 2.3 before running the installer.

### 1.5 USE and Qt flags

```bash
equery -q uses dev-qt/qtbase 2>/dev/null | grep -E '^[+-](opengl|vulkan|qml)$' || true
cat /var/db/pkg/dev-qt/qtbase-*/USE 2>/dev/null || true
grep -RHnE 'dev-qt/(qtbase|qtdeclarative|qtmultimedia|qt5compat|qtquick3d)[[:space:]]' /etc/portage/package.use 2>/dev/null || true
portageq envvar USE | tr ' ' '\n' | grep -E '^(opengl|vulkan|qml)$' || true
```

Required: the final effective `qtbase` flags must include `opengl`. `vulkan` and `qml` are optional for Contour. If another file forces `-opengl` on Qt, resolve the conflict before running the script.

### 1.6 Wayland/X11 platform

```bash
printf 'session=%s\n' "${XDG_SESSION_TYPE:-unknown}"
ls /usr/lib64/qt6/plugins/platforms/ 2>/dev/null || true
qlist -I dev-qt/qtwayland 2>/dev/null || true
```

For a Wayland session, the platform plugin list should include `libqwayland-*.so`, normally from `dev-qt/qtwayland`. For X11, `libqxcb.so` must exist. If the session is Wayland and `qtwayland` is missing, install it (Phase 2.5).

### 1.7 OpenGL / VM graphics

Contour requires OpenGL 3.3, either hardware-accelerated or a software rasterizer (from the Contour 0.6.1 README).

```bash
command -v glxinfo >/dev/null && glxinfo -B | grep -E 'OpenGL renderer|OpenGL core profile version'
command -v eglinfo >/dev/null && eglinfo -B 2>/dev/null | head -20
eselect opengl show 2>/dev/null || true
grep -E '^VIDEO_CARDS=' /etc/portage/make.conf /etc/portage/make.conf/* 2>/dev/null || true
```

If `glxinfo`/`eglinfo` is missing, check whether `x11-apps/mesa-progs` is available:

```bash
emerge -p x11-apps/mesa-progs 2>&1 | head -20
```

If the host has no OpenGL 3.3 context, fix Mesa/driver configuration before installing Contour. A terminal that starts but cannot create a context is not a successful install.

### 1.8 zlib/minizip

```bash
qlist -I virtual/minizip 2>/dev/null || echo "virtual/minizip not installed"
equery -q uses sys-libs/zlib 2>/dev/null | grep -E '^[+-]minizip$' || true
```

If `virtual/minizip` is absent, `zlib[minizip]` is unnecessary. It is not a Contour dependency; it was added on the source host because `media-libs/assimp` pulled in `virtual/minizip`.

### 1.9 Existing configuration

```bash
for f in /etc/portage/package.use/contour \
         /etc/portage/package.accept_keywords/contour \
         /etc/portage/package.mask/libunicode; do
  if [ -e "$f" ]; then echo "--- $f"; sed -n '1,80p' "$f"; fi
done
```

The script overwrites these paths. Back up any file with real content and merge manually. Put host-specific additions in separate files (for example `contour-extra`) so the next script run does not erase them.

### 1.10 STOP conditions

Do not run the full installer if any of these is true:

- [ ] `package.use`, `package.accept_keywords` or `package.mask` is a single file.
- [ ] `EMERGE_DEFAULT_OPTS` contains `--usepkgonly` or `--getbinpkgonly`.
- [ ] `--binpkg-respect-use` is unsupported and Portage has not been upgraded.
- [ ] `emerge -p gui-apps/contour` fails on keywords, masks or missing GURU.
- [ ] Effective `qtbase` USE lacks `opengl` and cannot be enabled cleanly.
- [ ] The host is Wayland-only and has no Wayland Qt platform plugin.
- [ ] OpenGL 3.3 is unavailable.
- [ ] Free space/RAM is insufficient for a Qt source rebuild.

## Phase 2 — Fixes

### 2.1 Convert single-file Portage configuration to directories

The script assumes `/etc/portage/package.use`, `package.accept_keywords` and `package.mask` are directories. If they are files, `mkdir -p` fails and the script exits.

Back up, then convert each single file. Portage treats every regular file in the directory as configuration, so moving the old file into the directory preserves its contents.

```bash
backup=$(date +%Y%m%d-%H%M%S)
for p in package.use package.accept_keywords package.mask; do
  path="/etc/portage/$p"
  if [ -f "$path" ] && [ ! -L "$path" ]; then
    sudo mv "$path" "/root/$p.single-$backup"
    sudo install -d -m 0755 "$path"
    sudo cp -a "/root/$p.single-$backup" "$path/00-existing"
  fi
done
```

Verify Portage still reads the configuration:

```bash
emerge --info >/dev/null && echo "Portage config OK"
```

If the host intentionally keeps a single file managed by another tool, do not convert it: instead patch the script to append to that file with markers rather than overwrite it, and rerun `--check-only`.

### 2.2 Allow source fallback on the binary-first VM

If `EMERGE_DEFAULT_OPTS` contains `--usepkgonly` or `--getbinpkgonly`, Portage will not compile from source. Contour and its Qt dependencies may have no matching binpkg because of `opengl`, or because GURU packages are `~amd64`.

Preferred: remove only the “only” options for this run, preserving the rest:

```bash
opts=$(portageq envvar EMERGE_DEFAULT_OPTS 2>/dev/null || true)
run_opts=${opts//--usepkgonly/}
run_opts=${run_opts//--getbinpkgonly/}
printf 'run EMERGE_DEFAULT_OPTS=%s\n' "$run_opts"
sudo env EMERGE_DEFAULT_OPTS="$run_opts" bash scripts/install-contour.sh --check-only
```

Review the preview. If it is clean, run the full script with the same override:

```bash
sudo env EMERGE_DEFAULT_OPTS="$run_opts" bash scripts/install-contour.sh
```

If the environment override is ignored because `/etc/portage/make.conf` wins, back up and temporarily comment out the “only” option in `make.conf`, run the script, then restore the file and verify with `emerge --info`.

Also check binhost signature setup on hosts using `FEATURES=binpkg-request-signature`:

```bash
emerge --info | grep -E 'PORTAGE_BINHOST|binpkg-request-signature'
command -v getuto >/dev/null && sudo getuto
```

If the binhost key is missing, `getbinpkg` may fail before source fallback. `getuto` (from `app-portage/getuto`) refreshes the trusted keys; otherwise fix the `binrepos.conf` configuration.

Note: with source fallback enabled, the VM may compile Qt. Check Phase 0 resources and expect a long build.

### 2.3 Stable/keyword-pinned host

The current tree has Qt 6.11.2 stable on amd64, and the GURU Contour 0.6.1.7494 ebuild is `~amd64`. The script accepts keywords for Contour, `libunicode`, `boxed-cpp` and `reflection-cpp`, which covers the GURU-only dependencies.

If `emerge -p gui-apps/contour` still reports keyword changes:

1. Read the exact atoms from the `emerge -p` output.
2. Add targeted entries to a **separate** file so the script does not overwrite them:

   ```bash
   # Only if /etc/portage/package.accept_keywords is a directory:
   sudo tee /etc/portage/package.accept_keywords/contour-extra >/dev/null <<'EOF'
   # Add the exact atoms reported by emerge -p here, for example:
   # dev-qt/qtbase ~amd64
   EOF
   ```

3. Alternatively use Portage’s autounmask, then review every change:

   ```bash
   sudo emerge -p --autounmask-write gui-apps/contour
   sudo dispatch-conf
   sudo emerge -p gui-apps/contour
   ```

Do not set a global `ACCEPT_KEYWORDS="~amd64"` just to install Contour. A Qt keyword cascade can pull a large testing stack and change unrelated packages.

If the host’s tree only offers Qt older than 6.11, check whether Contour’s required Qt components resolve:

```bash
emerge -p dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtmultimedia:6 dev-qt/qt5compat
```

Contour 0.6.1 needs Qt 6 Core, Core5Compat, Multimedia, Network, OpenGL, Qml, QuickControls2 and Widgets. If the stable Qt is too old and a keyword cascade is not acceptable, skip Contour on that host or build it in a container instead of changing the host’s Qt stack.

### 2.4 zlib[minizip] is host-specific

If `qlist -I virtual/minizip` prints nothing, the source host’s `sys-libs/zlib minizip` line is unnecessary. Leaving it is safe but forces a zlib rebuild (and may force a source build on the binary VM).

To remove it for this host, patch the script before running:

```bash
sudo sed -i '/^sys-libs\/zlib minizip$/d' scripts/install-contour.sh
```

Only do this if no installed package requires `virtual/minizip`. If `virtual/minizip` is installed, keep the line; it exists to satisfy that package’s `zlib[minizip]` dependency.

### 2.5 Wayland platform plugin

The Contour ebuild does not depend on `dev-qt/qtwayland`. On a Wayland-only host, install it so the Qt Wayland platform plugin exists:

```bash
qlist -I dev-qt/qtwayland >/dev/null 2>&1 || sudo emerge -av dev-qt/qtwayland
ls /usr/lib64/qt6/plugins/platforms/
```

For an X11 session, verify `libqxcb.so` is present; if not, ensure `dev-qt/qtbase` has the X11/xcb support enabled and rebuild it.

### 2.6 VM OpenGL

Check the renderer first:

```bash
glxinfo -B | grep -E 'OpenGL renderer|OpenGL core profile version'
```

- QEMU with virtio-gpu/virgl: ensure `VIDEO_CARDS` includes `virgl` and Mesa is installed.
- VMware: `VIDEO_CARDS=vmware`.
- VirtualBox: `VIDEO_CARDS=virtualbox` (or the guest additions path used by that host).
- If only llvmpipe is available, it still satisfies OpenGL 3.3 but is slow. Force software rendering for a test with `LIBGL_ALWAYS_SOFTWARE=1 contour`.

If `glxinfo` is not installed:

```bash
sudo emerge -av x11-apps/mesa-progs
```

Do not proceed until `contour` can create its window and render. A successful `contour --version` does not prove the GUI works.

### 2.7 GURU availability and version drift

Verify the overlay and the exact ebuild:

```bash
ls -1 /var/db/repos/guru/gui-apps/contour/ 2>/dev/null
emerge -p =gui-apps/contour-0.6.1.7494 2>&1 | head -30
```

The libunicode mask is specific to Contour 0.6.1. If GURU now carries a newer Contour:

- Check whether the newer ebuild still requires `media-libs/libunicode` below 0.8.
- If it supports 0.8, remove `/etc/portage/package.mask/libunicode` (or the mask line) and test the newer version.
- If it does not, pin the tested version or keep the mask and verify with `emerge -p`.

To force the tested version when a newer one appears:

```bash
# Example only; review before use:
sudo tee /etc/portage/package.mask/contour-version >/dev/null <<'EOF'
>=gui-apps/contour-0.6.2
EOF
```

### 2.8 Existing configuration is overwritten

The script writes these paths unconditionally:

- `/etc/portage/package.accept_keywords/contour`
- `/etc/portage/package.mask/libunicode`
- `/etc/portage/package.use/contour`

Back them up before the first run:

```bash
ts=$(date +%Y%m%d-%H%M%S)
for f in /etc/portage/package.use/contour \
         /etc/portage/package.accept_keywords/contour \
         /etc/portage/package.mask/libunicode; do
  [ -e "$f" ] && sudo cp -a "$f" "$f.bak-$ts"
done
```

Put any host-specific additions in separate files (`contour-extra`, `zz-contour-local`) rather than editing the three paths above, because the next run replaces them.

### 2.9 World-file hygiene

Step 6 uses `--oneshot`, so the Qt dependencies are not added to `@world`. Step 1 installs `app-eselect/eselect-repository` without `--oneshot`; if that package was not already installed, it may be added to world.

Check after the install:

```bash
grep -E '^dev-qt/|^app-eselect/eselect-repository$' /var/lib/portage/world || echo "no unexpected entries"
```

If `eselect-repository` should not be in world and the host does not need it:

```bash
sudo emerge --deselect app-eselect/eselect-repository
```

Do not deselect Qt packages that the host selected intentionally before this install.

### 2.10 quickshell and Vulkan

If `quickshell` is installed, its GURU ebuild hard-requires `dev-qt/qtbase:6=[dbus,vulkan,X?]` and has no `vulkan` USE flag. Do not try to rebuild Qt with `-vulkan` on that host; it will fail dependency resolution. Contour itself does not require Vulkan, so leaving `vulkan` enabled is harmless.

If a host has no quickshell and you want to remove Vulkan from Qt, that is a separate project: the quickshell source has a complete OpenGL dmabuf path, but its Vulkan includes and CMake `find_package(VulkanHeaders REQUIRED)` are unconditional, and the ebuild’s dependency is unconditional. It requires patching quickshell, its ebuild, and then rebuilding Qt. Do not attempt it as part of the Contour install.

### 2.11 Portage without `--binpkg-respect-use`

Test support:

```bash
emerge -p --binpkg-respect-use=y sys-apps/portage >/dev/null 2>&1 \
  && echo supported \
  || echo "unsupported: upgrade sys-apps/portage or remove the flag"
```

If upgrading Portage is not possible, patch the script to drop `--binpkg-respect-use=y` from the three emerge commands. The install still works, but Portage may print the “binary packages have been ignored due to non matching USE” warning again. That warning is not a build failure.

## Phase 3 — Run the installer

1. Complete Phase 0–2 and clear every STOP condition.
2. Run the preview:

   ```bash
   sudo bash scripts/install-contour.sh --check-only
   ```

   `--check-only` returning 0 only means the configuration was written. It skips Steps 1–2, so it can still return 0 when GURU is missing and the preview failed. Read the output:

   - The effective Qt flags must show `+opengl` on `qtbase`, `qtdeclarative` and `qtmultimedia`.
   - The Qt preview must resolve without keyword/mask errors.
   - The Contour preview must resolve.
   - “Total: 0 packages” for Qt is normal when the installed USE flags already match.
   - A warning from either preview means the corresponding emerge would fail; fix it before continuing.

3. Run the full install:

   ```bash
   sudo bash scripts/install-contour.sh
   ```

   On a binary host with a modified `EMERGE_DEFAULT_OPTS`, use the same environment override as in Phase 2.2.

4. Do not interrupt a Qt source build. If it fails, inspect the build log path printed by Portage, then resume:

   ```bash
   sudo emerge --resume --jobs=1
   ```

   If Portage reports preserved libraries after a Qt rebuild:

   ```bash
   sudo emerge @preserved-rebuild
   ```

## Phase 4 — Post-install verification

Run on every host:

```bash
command -v contour
contour --version
# Expected: Contour Terminal Emulator 0.6.1

emerge -p gui-apps/contour
# Expected: already installed (a reinstall line is acceptable; no blockers)

equery -q uses dev-qt/qtbase 2>/dev/null | grep -E '^[+-](opengl|vulkan|qml)$' || true
# Expected: +opengl

grep -E '^dev-qt/' /var/lib/portage/world || echo "no Qt entries in world"

ls /usr/lib64/qt6/plugins/platforms/
# Wayland host: libqwayland-*.so present
# X11 host: libqxcb.so present
```

Then launch it in the real session, not just `--version`:

```bash
contour
```

Verify:

- The window opens and renders text.
- No “failed to create OpenGL context” or missing platform plugin error appears.
- The terminal accepts input and can run a command.
- On a Wayland host, `echo "$XDG_SESSION_TYPE"` is `wayland` and the Qt Wayland plugin is in use (no XWayland fallback unless intended).
- On a VM, the renderer is the expected virgl/vmware/llvmpipe path.

Optional health checks:

```bash
sudo revdep-rebuild -p
sudo emerge -p @preserved-rebuild
```

`revdep-rebuild` is from `app-portage/gentoolkit`; if it is not installed, skip it or install gentoolkit first.

## Rollback

1. Remove Contour from world without deleting packages other software uses:

   ```bash
   sudo emerge --deselect gui-apps/contour
   ```

2. Restore the Portage configuration from the Phase 0 backup:

   ```bash
   sudo tar -C /etc -xzf /root/portage-backup-<timestamp>.tgz
   ```

3. If Qt USE flags were changed, rebuild the affected packages with the restored configuration:

   ```bash
   sudo emerge --changed-use --oneshot dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qt5compat
   ```

4. Do not run `emerge --depclean` blindly after removing Contour; review the list first. Qt packages may be used by the desktop.

5. If a Qt rebuild left preserved libraries, run `sudo emerge @preserved-rebuild`.

## Per-host worksheet

Fill this in on each system before running the full installer.

| Host | Profile / arch | ACCEPT_KEYWORDS | Binary mode | Qt version selected | package.* layout | Wayland plugin | OpenGL 3.3 | GURU OK | Blockers / action |
|------|----------------|-----------------|-------------|---------------------|------------------|----------------|------------|---------|-------------------|
| VM 1 | | | | | | | | | |
| VM 2 | | | | | | | | | |
| VM 3 | | | | | | | | | |
| Hardware | | | | | | | | | |

Suggested classification:

- **Testing/source host**: likely closest to the source host; verify directory-based config and OpenGL.
- **Stable VM**: Qt 6.11.x stable is expected to satisfy Contour; verify `emerge -p` and do not add a global `~amd64`.
- **Binary-first VM**: the critical check is the absence of `--usepkgonly`/`--getbinpkgonly`; otherwise fix Phase 2.2 first. Expect source rebuilds when the binhost’s USE does not match.
- **Hardware host**: verify the GPU/OpenGL path and any proprietary driver selection (`eselect opengl`), then follow the same checks.

## Quick reference

| Item | Value on the verified host |
|------|----------------------------|
| Script | `scripts/install-contour.sh` |
| Contour ebuild | `gui-apps/contour-0.6.1.7494` (GURU, `~amd64`) |
| Qt | 6.11.2 (stable amd64 in the current tree) |
| Portage | 3.0.83 |
| Required Qt USE | `qtbase[opengl]`, with matching `opengl` on `qtdeclarative` and `qtmultimedia` |
| libunicode | Mask `>=media-libs/libunicode-0.8.0`, use 0.7.x |
| GURU-only keyword atoms | `gui-apps/contour`, `media-libs/libunicode`, `dev-cpp/boxed-cpp`, `dev-cpp/reflection-cpp` |
| Host-specific flag | `sys-libs/zlib minizip` only when `virtual/minizip` is installed |
| Contour requirement | OpenGL 3.3 (hardware or software rasterizer) |

## References

- `scripts/install-contour.sh` — installer and `--check-only` preview
- `/var/db/repos/guru/gui-apps/contour/contour-0.6.1.7494.ebuild` — dependency and keyword source
- Contour 0.6.1 README — OpenGL 3.3 requirement
- `docs/BOOT-ISSUE-FIX.md` and `docs/INSTALL-GRUB-EFI.md` — style examples for agent runbooks
