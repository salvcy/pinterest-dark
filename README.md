# Pinterest Dark (Safari)

A Safari extension that turns on **Pinterest's own dark mode** on desktop. It paints nothing:
every colour you see is rendered by Pinterest's code.

Pinterest's web app ships a finished dark theme (121 components have dark-mode code paths, plus
a full Gestalt dark token set), but on desktop it's gated behind the server-side experiment
`dweb_dark_mode`. Phones and tablets already get it without the experiment.

## Choosing Light / Dark / Auto

Use Pinterest's own setting: **Settings & support → Settings → Display settings → Theme**
(`/settings/edit/display-settings/`). That page only appears once the extension has unlocked
dark mode. The extension's toolbar button opens it.

The extension never overrides that choice. On a fresh install, when Pinterest has no stored
theme yet, it seeds Dark; after that, Pinterest's setting is the only control.

## How it works

| File | Role |
|---|---|
| `extension/main.js` | Runs in the page's JS world at `document_start`. Defines a non-enumerable `Object.prototype.dweb_dark_mode = "enabled"`. Pinterest resolves experiments with `active[name] ?? triggerable[name]`, so every experiment map it loads, including the one it fetches after boot, reports the gate as enabled. No activation call is sent to Pinterest. Also seeds Pinterest's `theme` setting to `"dark"` if it has never been set. |
| `extension/background.js` | Registers `main.js` with `scripting.registerContentScripts({ world: "MAIN" })` (Safari ignores the manifest's `world` key) for the sites in `host_permissions`, and makes the toolbar button open Pinterest's Display settings. |

## Build and install

```bash
tools/build.sh
```

The script signs with the first "Apple Development" identity in your keychain (team read from the
certificate, signed locally, nothing sent to Apple), so Safari keeps the extension enabled across
restarts and updates. `SIGN_IDENTITY=- tools/build.sh` builds ad hoc instead.

Then open `build/Build/Products/Release/Pinterest Dark.app` once and enable **Pinterest Dark** in
Safari → Settings → Extensions. A build signed with a different identity counts as a new extension
in Safari and has to be enabled again. To turn the extension off, disable it there.

## What Pinterest's native mode does and doesn't cover

Because nothing is painted by the extension, these follow Pinterest's own behaviour:

- Native dark mode needs a signed-in account (Pinterest's rule). Signed-out pages stay light.
- Pages are server-rendered light (the server only renders dark for enrolled accounts), then turn
  dark when Pinterest's app starts, so each full page load shows a brief light frame.
- Pinterest leaves a few things light: `#EFEFEF` image-loading placeholders (visible in empty
  board-cover slots), the `#111111` "you are here" ring on the header avatar, the Safari tab-bar
  tint (`theme-color` stays `#FFFFFF`), and scrollbars/form controls (no `color-scheme`).
- With Theme set to Auto, Pinterest's colours follow macOS even if the extension is disabled
  (Pinterest doesn't gate that path), without the rest of dark mode. Pick Light before disabling
  the extension if you want Pinterest fully light.
- Pinterest logs a `webapp.dark_theme.view` metric once per page load.

If Pinterest renames the experiment, the unlock stops working and the Display settings page
disappears.
