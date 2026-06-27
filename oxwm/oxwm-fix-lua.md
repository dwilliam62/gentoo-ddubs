# OxWM Lua Undefined Variable Warning Fix (Neovim)
This document captures all steps used to resolve the `accessing undefined variable "oxwm"` warnings in Neovim while editing `~/.config/oxwm/config.lua`.
## 1) Confirm where diagnostics came from
There were two sources of warnings:
- `lua_ls` (language server)
- `luacheck` via `nvim-lint` on `BufWritePost` (save)
The save-time warnings persisted even after `:LspRestart`, which indicated linting was also involved.
## 2) Install OxWM Lua type stubs for editor/LSP
Created local stub path:
- `~/.config/oxwm/lib/oxwm.lua`
Command used:
```sh
install -Dm644 /usr/share/oxwm/oxwm.lua /home/dwilliams/.config/oxwm/lib/oxwm.lua || install -Dm644 /home/dwilliams/oxwm/templates/oxwm.lua /home/dwilliams/.config/oxwm/lib/oxwm.lua
```
(`templates/oxwm.lua` was used as fallback if `/usr/share/oxwm/oxwm.lua` was missing.)
## 3) Add LuaLS workspace config in OxWM config directory
Created:
- `~/.config/oxwm/.luarc.json`
Content:
```json
{
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime": {
    "version": "Lua 5.4"
  },
  "workspace": {
    "library": [
      "./lib"
    ],
    "checkThirdParty": false
  }
}
```
## 4) Patch Neovim `lua_ls` config to include OxWM
File changed:
- `~/.config/nvim/lua/servers/lua_ls.lua`
Changes:
- Added `oxwm` to diagnostics globals.
- Added these paths to `workspace.library`:
  - `~/.config/oxwm/lib`
  - `~/.config/oxwm`
  - `~/oxwm/templates`
Relevant setting after fix:
```lua
diagnostics = {
  globals = { 'vim', 'hl', 'oxwm' },
},
workspace = {
  library = {
    vim.fn.expand '$VIMRUNTIME/lua',
    vim.fn.expand '$XDG_CONFIG_HOME' .. '/nvim/lua',
    vim.fn.expand '$HOME/.config/hypr',
    vim.fn.expand '$HOME/.config/oxwm/lib',
    vim.fn.expand '$HOME/.config/oxwm',
    vim.fn.expand '$HOME/oxwm/templates',
  },
},
```
## 5) Patch save-time lint (`luacheck`) config
This was the key reason warnings still appeared immediately on save.
File changed:
- `~/.config/nvim/lua/plugins/nvim-lint.lua`
Change:
- Added `oxwm` to `luacheck` globals.
Relevant args after fix:
```lua
lint.linters.luacheck.args = {
  '--globals',
  'vim',
  'hl',
  'oxwm',
  '--formatter',
  'plain',
  '--codes',
  '--ranges',
  '-',
}
```
## 6) Fix remaining real warnings in `config.lua`
File changed:
- `~/.config/oxwm/config.lua`
Changes:
1. Fixed undefined variable:
   - `oxwm.gaps.set_smart(enabled)` → `oxwm.gaps.set_smart(true)`
2. Removed long-line warning by extracting the long shell command into:
   - `local centered_pavucontrol_cmd = ...`
   and using that variable in the `Super+V` keybind.
## 7) Validation command used
```sh
luacheck --globals vim hl oxwm -- /home/dwilliams/.config/oxwm/config.lua
```
Result after fixes:
- `OK`
- `0 warnings / 0 errors`
## 8) Neovim reload steps
After config changes:
1. Full Neovim restart (needed for plugin config reload like `nvim-lint`).
2. Optional: `:LspRestart`
3. Optional: `:lua require('lint').try_lint()`
