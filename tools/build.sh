#!/bin/zsh
# Regenerates the Safari Xcode project from extension/ and builds "Pinterest Dark.app".
# Signs with the first "Apple Development" identity in the keychain (team read from the
# certificate), so Safari keeps the extension enabled without "Allow unsigned extensions".
# Override with SIGN_IDENTITY="Apple Development: …"; set SIGN_IDENTITY=- for an ad-hoc build.
set -euo pipefail
cd "${0:A:h}/.."

APP="Pinterest Dark"
BUNDLE_ID="com.ahmed.PinterestDark"
PROJECT="xcode/$APP/$APP.xcodeproj"

xcrun safari-web-extension-converter extension \
  --project-location xcode --app-name "$APP" --bundle-identifier "$BUNDLE_ID" \
  --swift --macos-only --no-open --no-prompt --force >/dev/null

# The converter derives the app target's identifier from the app name ("…Pinterest-Dark") while
# the extension gets "$BUNDLE_ID.Extension"; Xcode requires the extension to be prefixed by the app.
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = \"com.ahmed.Pinterest-Dark\";/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/" "$PROJECT/project.pbxproj"

identity="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -1)}"
if [[ -n "$identity" && "$identity" != "-" ]]; then
  team=$(security find-certificate -c "$identity" -p | openssl x509 -noout -subject | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p')
  signing=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" PROVISIONING_PROFILE_SPECIFIER="")
  echo "Signing with $identity (team $team)"
else
  signing=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="")
  echo "Signing ad hoc (Safari needs Developer → Allow unsigned extensions)"
fi

# clean first: incremental builds leave resources removed from extension/ inside the bundle.
xcodebuild -project "$PROJECT" -scheme "$APP" -configuration Release -derivedDataPath build \
  "${signing[@]}" clean build | grep -E "error:|(BUILD|CLEAN) (SUCCEEDED|FAILED)"

echo "Built: build/Build/Products/Release/$APP.app"
