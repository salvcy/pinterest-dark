# Pinterest Dark

A browser extension that turns on the dark mode Pinterest has already built into its website.
It works in Chrome, Firefox, Safari, and the browsers built on them.

## What it is

Pinterest Dark is not a theme. It contains no stylesheets and recolours nothing.

Pinterest's website already includes a complete dark mode. Pinterest turns it on for phones and
tablets, but on desktop it keeps it switched off behind a server-side experiment called
`dweb_dark_mode`. This extension switches that experiment on inside your browser, and Pinterest
does everything else with its own code:

- Every colour comes from Pinterest's own dark design.
- Pinterest's own **Theme** setting (Light, Dark, Auto) appears in Display settings.
- Pinterest saves your choice, like any other setting.

Because the extension only flips Pinterest's switch, Pinterest's redesigns can't leave it with
mismatched colours, broken layouts or elements it missed.

## Install

Pinterest Dark isn't published in the Chrome Web Store, Firefox Add-ons or the App Store, so you
install it from this repository's source code. Every browser lets you do this through its
developer options, and the steps below walk through it for each one. Your browser may label the
extension as unpacked, temporary or unsigned, which is expected for an extension loaded from
source.

### Before you start

1. **Sign in to Pinterest** in the browser you're installing it in. Pinterest only enables its
   dark mode for signed-in accounts.
2. **Build the extension.** In a terminal, run:

   ```bash
   git clone https://github.com/salvcy/pinterest-dark.git
   cd pinterest-dark
   tools/build.sh
   ```

   This creates `dist/chrome` and `dist/firefox` inside the `pinterest-dark` folder, plus the
   Safari app when Xcode is installed. The script needs `jq` and `zip`, which come with
   macOS 15 and later; on Linux, install them with your package manager.

**Tip:** to paste a folder path into a file window, press **Cmd+Shift+G** on macOS or **Ctrl+L**
on Linux. On Windows, paste it into the address bar at the top of the window.

### Chrome, Edge, Brave, Opera, Vivaldi, Arc and other Chromium browsers

1. **Open the extensions page.** Paste your browser's address into the address bar and press
   Enter:

   | Browser | Address |
   |---|---|
   | Chrome | `chrome://extensions` |
   | Edge | `edge://extensions` |
   | Brave | `brave://extensions` |
   | Opera | `opera://extensions` |
   | Vivaldi | `vivaldi://extensions` |
   | Arc | `arc://extensions` |

2. **Turn on Developer mode.** In most browsers it's a switch in the top-right corner; in Edge
   it's in the left sidebar. New buttons appear at the top of the page.
3. **Click Load unpacked.**
4. **Choose the `dist/chrome` folder** and click **Select**. Pick the folder itself, not a file
   inside it. A **Pinterest Dark** card appears, switched on.
5. **Reload your Pinterest tabs** (Cmd+R or Ctrl+R). Pinterest turns dark after a brief light
   flash while the page loads.
6. **Optional: pin the button.** Click the puzzle-piece icon in the toolbar, then click the pin
   next to Pinterest Dark.

The extension stays installed after the browser restarts. Keep the `dist/chrome` folder where it
is, because the browser loads the extension from it; moving or deleting the folder removes the
extension. To update, pull the latest code, run `tools/build.sh`, and click the reload icon on
the extension's card.

### Firefox, Zen, LibreWolf, Waterfox, Floorp and other Firefox browsers

Regular Firefox only keeps add-ons that Mozilla has signed. An add-on loaded from source is
temporary: Firefox removes it when it quits, and you load it again the next time. To keep it
installed, see [Keep it installed in Firefox](#keep-it-installed-in-firefox) below.

1. **Open the add-on loader.** Paste this into the address bar and press Enter:

   ```
   about:debugging#/runtime/this-firefox
   ```

2. **Click Load Temporary Add-on…**
3. **Open the `dist/firefox` folder and choose `manifest.json`.** **Pinterest Dark** appears in
   the list of temporary extensions.
4. **Reload your Pinterest tabs** (Cmd+R or Ctrl+R). Pinterest turns dark after a brief light
   flash while the page loads.
5. **Optional: pin the button.** Click the puzzle-piece icon in the toolbar, click the gear next
   to Pinterest Dark, and choose **Pin to Toolbar**.

#### Keep it installed in Firefox

**Sign it with Mozilla.** This works in every Firefox browser. It's free, and the add-on isn't
listed publicly.

1. Create a free account at <https://addons.mozilla.org> and generate API credentials at
   <https://addons.mozilla.org/developers/addon/api/key/>.
2. In a terminal in the `pinterest-dark` folder, run these commands, replacing the placeholders
   with your **JWT issuer** and **JWT secret**:

   ```bash
   export WEB_EXT_API_KEY="your JWT issuer"
   export WEB_EXT_API_SECRET="your JWT secret"
   npx web-ext sign --channel unlisted --source-dir dist/firefox --artifacts-dir dist
   ```

3. Drag the signed `.xpi` file from `dist/` onto a Firefox window and click **Add**.

**Allow unsigned add-ons.** This only works in Firefox Developer Edition, Nightly, ESR, and
Firefox browsers that allow unsigned add-ons.

1. Paste `about:config` into the address bar, press Enter, and accept the warning.
2. Search for `xpinstall.signatures.required` and set it to `false`.
3. Paste `about:addons` into the address bar and press Enter.
4. Click the gear icon, choose **Install Add-on From File…**, and pick the
   `pinterest-dark-<version>-firefox.xpi` file in `dist/`.
5. Click **Add**.

### Safari (macOS)

Safari extensions come inside a Mac app, so the build creates a small app that carries the
extension. You need Xcode.

1. **Build the app.** In a terminal in the `pinterest-dark` folder, run:

   ```bash
   tools/build.sh safari
   ```

2. **Open the app once.** Open `build/Build/Products/Release/Pinterest Dark.app`. Opening it
   registers the extension with Safari, and then you can close it.
3. **Turn on the extension.** In Safari, choose **Safari → Settings → Extensions** and select
   the checkbox next to **Pinterest Dark**.
4. **Allow it on Pinterest.** Open pinterest.com and click the Pinterest Dark button in the
   toolbar. If Safari asks whether Pinterest Dark may access the site, choose **Always Allow on
   This Website**.
5. **Reload the page** (Cmd+R). Pinterest turns dark after a brief light flash while the page
   loads.

If your keychain has an Apple Development certificate, the build is signed with it, and Safari
keeps the extension on after restarts. Otherwise the build is signed ad hoc. You then need to turn
on **Safari → Settings → Developer → Allow unsigned extensions**, which Safari turns off each time
it quits.

## Use

On Pinterest, open **Settings & support** (bottom left) → **Settings** → **Display settings** →
**Theme**, and choose Light, Dark or Auto. The Pinterest Dark toolbar button opens this page
directly.

The first time you use it, Pinterest Dark sets the theme to Dark. After that, only Pinterest's
setting controls the theme.

## Remove

If your Theme is set to Auto, switch it to Light first. Pinterest partly follows your system's
appearance in Auto, even when the extension is off.

- **Chromium browsers:** click **Remove** on the extension's card on the extensions page.
- **Firefox:** temporary add-ons disappear when Firefox quits. For a signed or unsigned install,
  open `about:addons`, click the **…** menu next to Pinterest Dark, and choose **Remove**.
- **Safari:** turn the extension off in **Settings → Extensions**, then delete
  `Pinterest Dark.app`.

## Supported browsers

| Engine | Minimum version | Examples |
|---|---|---|
| Chromium | 102 | Chrome, Edge, Brave, Opera, Vivaldi, Arc |
| Gecko | Firefox 128 | Firefox, Zen, LibreWolf, Waterfox, Floorp |
| WebKit | Safari 16.4 (macOS) | Safari |

## How it works

Pinterest decides whether to offer dark mode by looking up the `dweb_dark_mode` experiment:

```js
(active[name] ?? triggerable[name]) || ""
```

- **Runs first.** `main.js` runs inside the page before any of Pinterest's code.
- **Answers the lookup.** It sets `dweb_dark_mode = "enabled"` as a hidden default on
  `Object.prototype`. Every experiment list Pinterest loads then answers `"enabled"`, including the
  lists it fetches after the page starts.
- **Stays hidden.** The default doesn't show up in `Object.keys`, `JSON.stringify` or `for…in`, so
  it never leaks into anything Pinterest sends or stores.
- **Sends nothing.** Pinterest treats the experiment as already active, so it never sends a
  request to activate it.

`background.js` registers `main.js` on Pinterest's sites and makes the toolbar button open
Display settings.

## Privacy

Pinterest Dark collects no data, makes no network requests, and runs only on Pinterest's sites.
The only thing it writes is Pinterest's own `theme` setting, and only once, when that setting is
empty. Pinterest itself records that its dark theme was shown (`webapp.dark_theme.view`), as it
does for any account in the experiment.

## Known limitations

These all come from Pinterest's own dark mode, which the extension doesn't alter:

- You need to be signed in. Pages stay light when you're signed out.
- Each page briefly shows light while it loads. Pinterest's server sends a light page, and
  Pinterest's code switches it to dark once it starts.
- A few elements stay light: empty image placeholders, the ring around your avatar in the header,
  scrollbars, and Safari's tab bar tint.
- If Pinterest renames the experiment, the extension stops working until it's updated.

## Troubleshooting

- **Pinterest stays light:**
  - Check that you're signed in, then reload the tab.
  - In Chrome or Firefox, click the Pinterest Dark toolbar button. If the browser asks to allow
    access to Pinterest sites, click **Allow**.
  - In a Chromium browser, click **Details** on the extension's card and check that **Site
    access** includes Pinterest.
- **Private windows:** browsers don't run extensions in private windows by default. Allow
  Pinterest Dark in its settings on your browser's extensions page.
- **Firefox lost the extension:** temporary add-ons are removed when Firefox quits. Load it again,
  or follow [Keep it installed in Firefox](#keep-it-installed-in-firefox).

## Project layout

| Path | Purpose |
|---|---|
| `extension/` | Shared source: manifest, `background.js`, `main.js`, icons |
| `tools/build.sh` | Builds `dist/chrome`, `dist/firefox` and the Safari app |
| `tools/make-icons.swift` | Draws the icons |

## License

[MIT](LICENSE). Pinterest is a trademark of Pinterest, Inc. This project isn't affiliated with or
endorsed by Pinterest.
