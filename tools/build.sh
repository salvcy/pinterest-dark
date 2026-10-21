#!/usr/bin/env bash
# Builds Pinterest Dark from extension/ for each browser.
#
#   tools/build.sh                   chrome, firefox, and safari (when Xcode is installed)
#   tools/build.sh chrome firefox    only the named targets
#
#   chrome   dist/chrome/                              load unpacked in any Chromium browser
#            dist/pinterest-dark-<version>-chrome.zip  for the Chrome Web Store / Edge Add-ons
#   firefox  dist/firefox/                             load as a temporary add-on, or sign it
#            dist/pinterest-dark-<version>-firefox.xpi unsigned package
#   safari   build/Build/Products/Release/Pinterest Dark.app
#
# extension/manifest.json holds everything the browsers share; manifest_for adds the keys that
# differ. Needs jq and zip; safari also needs Xcode. Safari builds are signed with the first
# "Apple Development" identity in the keychain so Safari keeps the extension enabled; set
# SIGN_IDENTITY="Apple Development: …" to pick one, or SIGN_IDENTITY=- for an ad-hoc build.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=extension
DIST=dist
VERSION=$(jq -r .version "$SRC/manifest.json")
GECKO_ID="pinterest-dark@salvcy"

manifest_for() {
  case "$1" in
    chrome) jq '. + {
      background: {service_worker: "background.js"},
      minimum_chrome_version: "102"
    }' ;;
    firefox) jq --arg id "$GECKO_ID" '. + {
      background: {scripts: ["background.js"]},
      browser_specific_settings: {gecko: {
        id: $id,
        strict_min_version: "128.0",
        data_collection_permissions: {required: ["none"]}
      }}
    }' ;;
    # Safari tints toolbar icons itself, so it gets the monochrome glyphs.
    safari) jq '. + {
      background: {service_worker: "background.js"},
      browser_specific_settings: {safari: {strict_min_version: "16.4"}}
    } | .action.default_icon = {
      "16": "icons/toolbar-16.png", "19": "icons/toolbar-19.png", "32": "icons/toolbar-32.png",
      "38": "icons/toolbar-38.png", "48": "icons/toolbar-48.png"
    }' ;;
  esac < "$SRC/manifest.json"
}

# Writes dist/<target>/: the shared files plus that browser's manifest.
stage() {
  local out="$DIST/$1"
  rm -rf "$out"
  mkdir -p "$out/icons"
  cp "$SRC/background.js" "$SRC/main.js" "$out/"
  manifest_for "$1" > "$out/manifest.json"
  if [[ $1 == safari ]]; then
    cp "$SRC"/icons/*.png "$out/icons/"
  else
    cp "$SRC"/icons/icon-*.png "$out/icons/"
    rm -f "$out/icons/icon-1024.png" # only the Safari app icon uses it
  fi
}

package() { # target, file extension
  local file="pinterest-dark-$VERSION-$1.$2"
  rm -f "$DIST/$file"
  (cd "$DIST/$1" && zip -qrX "../$file" .)
  echo "$1: $DIST/$1/ and $DIST/$file"
}

has_xcode() {
  [[ $(uname) == Darwin ]] && xcrun --find safari-web-extension-converter >/dev/null 2>&1
}

build_safari() {
  has_xcode || { echo "safari: needs macOS with Xcode" >&2; return 1; }
  stage safari

  local app="Pinterest Dark" bundle_id="com.salvcy.PinterestDark"
  local project="xcode/$app/$app.xcodeproj"
  xcrun safari-web-extension-converter "$DIST/safari" \
    --project-location xcode --app-name "$app" --bundle-identifier "$bundle_id" \
    --swift --macos-only --no-open --no-prompt --force >/dev/null

  # The converter derives the app target's identifier from the app name ("…Pinterest-Dark") while
  # the extension gets "$bundle_id.Extension"; Xcode requires the extension to be prefixed by the app.
  sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = \"${bundle_id%.*}.Pinterest-Dark\";/PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;/" \
    "$project/project.pbxproj"

  local identity="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
    | sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -1)}"
  local signing
  if [[ -n $identity && $identity != - ]]; then
    local team
    team=$(security find-certificate -c "$identity" -p | openssl x509 -noout -subject \
      | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p')
    signing=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" PROVISIONING_PROFILE_SPECIFIER="")
    echo "safari: signing with $identity (team $team)"
  else
    signing=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="")
    echo "safari: signing ad hoc (Safari needs Developer → Allow unsigned extensions)"
  fi

  # clean first: incremental builds leave resources removed from the extension inside the bundle.
  xcodebuild -project "$project" -scheme "$app" -configuration Release -derivedDataPath build \
    "${signing[@]}" clean build 2>&1 | grep -E "(^|: )error: |(BUILD|CLEAN) (SUCCEEDED|FAILED)"
  echo "safari: build/Build/Products/Release/$app.app"
}

for tool in jq zip; do
  command -v "$tool" >/dev/null || { echo "tools/build.sh needs $tool" >&2; exit 1; }
done

if [[ $# -eq 0 ]]; then
  set -- chrome firefox
  if has_xcode; then set -- "$@" safari; fi
fi

for target in "$@"; do
  case "$target" in
    chrome) stage chrome && package chrome zip ;;
    firefox) stage firefox && package firefox xpi ;;
    safari) build_safari ;;
    *) echo "unknown target: $target (use chrome, firefox or safari)" >&2; exit 1 ;;
  esac
done
