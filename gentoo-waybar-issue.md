# Waybar reload crash on Gentoo (SIGUSR2 aborts the bar)

Status: **resolved locally** with a Portage user patch. No KooL dots change was made.

Affected host: `xps15` - Gentoo, Waybar 0.15.0 (`gui-apps/waybar::hyproverlay`), GLib 2.88.3.

Fix: `scripts/fix-waybar-reload-crash.sh` (installs `/etc/portage/patches/gui-apps/waybar/99-waybar-per-process-app-id.patch` and rebuilds Waybar). The patch text is embedded in the script, so the script is the single source of truth for it.

## Quick reference

```bash
# is the fix in place?
scripts/fix-waybar-reload-crash.sh --check

# prove the crash, or prove the fix: two throwaway bars, both reloaded
scripts/fix-waybar-reload-crash.sh --test

# apply it: write the user patch and rebuild Waybar
sudo scripts/fix-waybar-reload-crash.sh

# back it out
sudo scripts/fix-waybar-reload-crash.sh --remove
```

---

## 1. Symptom

Reloading Waybar aborts it. In practice the reload is not typed by hand - the KooL dots send
`pkill -SIGUSR2 -x waybar` on every lid, monitor and wallpaper event - so the user-visible
symptom is "the bar vanished":

- Lid opened -> the dots refresh the layout and reload Waybar -> the bar disappears.
- `coredumpctl` shows Waybar dying with `SIGABRT` / `SI_TKILL` at that moment.
- Waybar's own stderr (when it is captured) ends with:

```text
[info] Reloading...
[info] Using configuration file /home/dwilliams/.config/hypr/waybar/config
[info] Using CSS file /home/dwilliams/.config/hypr/waybar/style.css
GLib-GIO:ERROR:../glib-2.88.3/gio/gapplicationimpl-dbus.c:851:g_application_impl_command_line: assertion failed: (object_id != 0)
Bail out! GLib-GIO:ERROR:../glib-2.88.3/gio/gapplicationimpl-dbus.c:851:g_application_impl_command_line: assertion failed: (object_id != 0)
```

It is a clean abort inside GLib, not a segfault and not a config error: `Bail out!` is
`g_assert` calling `abort()`.

## 2. Cause

Two facts combine.

**Every Waybar process uses the same D-Bus application id.** `src/client.cpp` creates the
GTK application with a fixed id:

```cpp
gtk_app = Gtk::Application::create(argc, argv, "fr.arouillard.waybar",
                                   Gio::APPLICATION_HANDLES_COMMAND_LINE);
```

That id is a *well-known bus name*. Only one process can own it. A second Waybar process
starts, draws its own bar, and works - but it never owns the name, so GLib treats its
`GApplication` as **remote**:

```text
$ busctl --user list | grep -i waybar      # two instances running
:1.124   64581 waybar   ...      # instance 1
:1.125   64581 waybar   ...
:1.126   64644 waybar   ...      # instance 2 - no well-known name
:1.127   64644 waybar   ...
fr.arouillard.waybar   64581 waybar   ...      # owned by instance 1 only
```

**A reload creates a second `Gtk::Application` in the same process.** `src/main.cpp` runs the
client in a loop, and `src/client.cpp` creates the application *inside* that loop:

```cpp
do {
  reload = false;
  ret = client->main(argc, argv);   // -> Gtk::Application::create() + gtk_app->run()
} while (reload);                    // reload is set by SIGUSR2 -> Client::reset() -> quit()
```

So on `SIGUSR2`: `reset()` quits the application, `run()` returns, `main()` is entered again,
and a **second** `Gtk::Application` is created for the same id - while the first application
object is still alive (it is referenced until the assignment completes).

For a **remote** application GLib's `g_application_run()` takes the command-line path and
registers a fixed object path, `/org/gtk/Application/CommandLine`, on the session bus. That
registration cannot succeed while the previous application object in the same process still
holds it, so `object_id` comes back `0` and GLib hits its own assertion:

```c
/* gio/gapplicationimpl-dbus.c, g_application_impl_command_line() */
g_assert (object_id != 0);
```

For a **primary** application (the name owner) `g_application_run()` takes the local path,
never registers that object, and the reload works. Hence:

- one Waybar instance -> reload is fine;
- two Waybar instances -> the first survives a reload, the second aborts;
- and because the dots' scripts signal **every** process matching `waybar`, one refresh can
  take out the bar that the layout change just restarted.

## 3. How it was diagnosed

Reproduced deterministically with a two-line config, so the dots' config, its custom modules
and the Hyprland Lua patch are all ruled out:

```bash
# minimal throwaway bar
printf '{ "layer": "top", "position": "top", "height": 30, "modules-left": ["clock"] }\n' > /tmp/wbtest/config
: > /tmp/wbtest/style.css

# one instance: reload survives
setsid waybar -c /tmp/wbtest/config -s /tmp/wbtest/style.css &   # + kill -USR2 -> survives

# two instances: the second one aborts
setsid waybar -c /tmp/wbtest/config -s /tmp/wbtest/style.css &
kill -USR2 <second pid>
# -> g_application_impl_command_line: assertion failed: (object_id != 0) -> SIGABRT
```

Also confirmed on the real crash: the core dump from the lid event contains the string
`Reloading...`, i.e. the process died inside the reload path.

Things that were tried and **rejected**:

- *Reuse the `Gtk::Application` instead of creating a new one.* GLib refuses to run the same
  application twice: `g_application_run: assertion '!application->priv->must_quit_now' failed`.
  Not a viable patch.
- *A newer Waybar.* Upstream `master` still creates the application inside the reload loop
  (`src/client.cpp`), so this is not fixed by version bumping. It is upstream issue
  [Alexays/Waybar#2224](https://github.com/Alexays/Waybar/issues/2224) - same assertion, same
  `Bail out!`, and the same observation that it only happens when more than one bar is running.
- *Changing the dots.* The dots are distro-agnostic and Gentoo is not a supported target, so
  the workaround stays local. (For the record, the three call sites that send the signal are
  `LidSwitch.sh`, `WallustSwww.sh` and `ThemeChanger.sh`.)

## 4. The fix

Give each Waybar process its own application id, so every instance owns its name, is
*primary*, and takes the local reload path:

```cpp
gtk_app = Gtk::Application::create(
    argc, argv, "fr.arouillard.waybar.p" + std::to_string(getpid()),
    Gio::APPLICATION_HANDLES_COMMAND_LINE);
```

This changes nothing about how Waybar behaves in practice: a second instance already ran
independently (it just did not own the name), and nothing in the dots relies on a second
invocation being forwarded to the first one.

It is delivered as a Portage **user patch**, so nothing outside `/etc/portage/patches` is
touched - not the ebuild, not the overlay, not the dots:

```text
/etc/portage/patches/gui-apps/waybar/99-waybar-per-process-app-id.patch
```

EAPI 8's default `src_prepare` calls `eapply_user`, so the patch is applied automatically on
every build of `gui-apps/waybar`, after the overlay's own `add-hyprland-lua-ipc` patch (which
touches different files and does not conflict).

## 5. Using the script

`--check` only reports - it is safe to run at any time and warns when the binary is older than
the patch, or when the installed Waybar is no longer the version the patch was written for.

`--test` is the part worth running twice: once before the fix to see the crash, once after to
see it gone. It starts two throwaway 30px bars, reloads both, and reports which survived. It
must run as the desktop user - it needs `WAYLAND_DISPLAY` and the session bus - so run it
*after* the `sudo` step rather than through it.

Both modes are read-only: they install nothing and leave the running bar alone.

## 6. Verification

Before the patch (installed binary, 2026-10-13 00:54):

```text
$ scripts/fix-waybar-reload-crash.sh --test
starting two throwaway bars (a minimal 30px bar on each monitor)
  pid 64973: survived reload
  pid 65037: DIED on reload

reload crash reproduced. Last lines from the second instance:
[info] Reloading...
GLib-GIO:ERROR:../glib-2.88.3/gio/gapplicationimpl-dbus.c:851:g_application_impl_command_line: assertion failed: (object_id != 0)
Bail out! ...
```

After the patch and rebuild:

```text
$ scripts/fix-waybar-reload-crash.sh --check
waybar version:       0.15.0 (patch written for 0.15.0)
user patch:           present (/etc/portage/patches/gui-apps/waybar/99-waybar-per-process-app-id.patch)
binary vs patch:      binary is newer - the patch is built in

$ scripts/fix-waybar-reload-crash.sh --test
starting two throwaway bars (a minimal 30px bar on each monitor)
  pid 67421: survived reload
  pid 67484: survived reload

PASS: every instance survived its reload
```

The real bar was then started through the dots' own path
(`~/.config/hypr/scripts/WaybarStartup.sh`) and survived a `SIGUSR2` reload.

## 7. Maintenance

- The patch is written against **Waybar 0.15.0** and rewrites a specific block of
  `src/client.cpp`. On a version bump, `eapply_user` will fail and the emerge will stop with
  an error rather than silently dropping the fix. Re-check the block, update the patch, and
  bump `KNOWN_VERSION` in the script.
- If upstream fixes the reload path (see issue #2224), remove the patch with
  `--remove`, rebuild, and confirm with `--test` that a second instance still survives.
- `--check` warns when the installed Waybar version is not the one the patch was written for,
  and when the binary is older than the patch (i.e. the patch is present but not built in).
