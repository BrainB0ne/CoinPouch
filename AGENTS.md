# CoinPouch agent notes

## Runtime boundaries

- This is a dependency-free WoW addon, not a standalone Lua program. Use Lua 5.1-compatible syntax; runtime globals come from WoW.
- `CoinPouch.toc` loads `CoinPouch.lua` before `CoinPouchSettings.lua`. The core publishes `_G.CoinPouchAPI`, which settings captures at file load; preserve this order and route settings changes through that API.
- `CoinPouchDB` is the SavedVariables table. Core initialization runs on this addon's `ADDON_LOADED`; preserve existing saved preferences when adding defaults.
- `CoinPouchLegacyAPI.lua` contains LuaLS annotation stubs, not implementations. Never load it in the TOC or ship it as runtime code.
- Support both Retail and Forever: retain feature-detected modern/legacy metadata and settings APIs. The TOC declares both interface versions; README compatibility prose is narrower than the actual configuration.

## Development and verification

- Keep the checkout outside the game installation. From PowerShell at the repo root, deploy with `.\Scripts\deploy.ps1 -Client Forever`; `Retail` and `All` are also accepted (`Forever` is the default).
- Deployment requires ignored `Scripts/deploy.local.ps1` defining `$AddonPaths` with `Forever`/`Retail` keys pointing to existing `Interface\AddOns` directories. See README for the config template; do not commit machine-specific paths.
- No automated test suite, CI, or repository lint/typecheck commands are configured. Deploy, then use `/reload` in the target game client. Check changed behavior there; `/coinpouch settings` opens settings and `/coinpouch reset` resets position.
- Keep regular and nonzero bag-family storage separate; count the reagent bag only when `Enum.BagIndex.ReagentBag` exists. Resolve equipped bag slots by name using `C_PaperDollInfo.GetInventorySlotInfo` with the legacy global as a fallback. On `BAG_UPDATE_DELAYED`, refresh both the widget and any open Shift-hover tooltip.
- The widget and `UIParent` use different effective scales. Preserve the conversions in drag saving and `KeepOnScreen`. WoW changes the anchor during dragging, so restore the saved center anchor even when no clamping is needed. Check screen edges after scaling, width changes, and reload.
- `.vscode/` is ignored local tooling, not shared configuration. The current LuaLS setup uses Lua 5.1 and external WoW API annotations.

## Packaging

- Both `Scripts/deploy.ps1` and `Scripts/package.ps1` maintain explicit runtime-file allowlists. When adding runtime files, update both lists and the TOC as appropriate; artwork under `Assets/` is not runtime media.
- Run `.\Scripts\package.ps1` from PowerShell to create ignored `Releases/CoinPouch-v<version>.zip` with a `CoinPouch/` root directory. Version comes from `## Version:` in the TOC (also displayed by the UI); keep README's project version aligned when bumping it.
- `-Force` builds a temporary ZIP before replacing an existing release. Keep `[NullString]::Value` as the `File.Replace()` backup-path argument: Windows PowerShell can bind `$null` as an invalid empty path.
