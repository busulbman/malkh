#!/bin/zsh
# Mac App Store paketi: derler, sandbox ile imzalar, .pkg üretir.
# Kullanım: scripts/build-appstore.sh 1.0.0 1
# Gerekenler (bir kez): Xcode'da "Apple Distribution" ve "Mac Installer Distribution" sertifikaları,
# Configuration/Malkh_AppStore.provisionprofile (developer.apple.com → Profiles → Mac App Store Connect).
set -euo pipefail
cd "${0:A:h:h}"
if (( $# != 2 )); then print -u2 'Kullanım: scripts/build-appstore.sh SÜRÜM YAPI   örn: scripts/build-appstore.sh 1.0.0 1'; exit 1; fi
version=$1 build=$2 bundle_id=com.busulbman.malkh
out="$PWD/build/appstore"; app="$out/Malkh.app"; pkg="$out/Malkh-$version-$build.pkg"
profile="Configuration/Malkh_AppStore.provisionprofile"

print "▸ 1/6  Sertifikalar ve profil kontrol ediliyor"
identities=$( { security find-identity -v -p codesigning; security find-identity -v -p basic; security find-identity -v; } 2>/dev/null || true)
app_identity=$(print -r -- "$identities" | grep -E '"(Apple Distribution|3rd Party Mac Developer Application):' | head -1 | sed -E 's/.*"(.*)"/\1/' || true)
installer_identity=$(print -r -- "$identities" | grep -E '"(3rd Party Mac Developer Installer|Mac Installer Distribution):' | head -1 | sed -E 's/.*"(.*)"/\1/' || true)
if [[ -z "$app_identity" || -z "$installer_identity" ]]; then
  print -u2 "Bu Mac'te bulunan imza sertifikaları:"; { print -r -- "$identities" | grep '"' | sort -u >&2; } || print -u2 "   (hiç yok — security find-identity boş döndü)"
fi
[[ -n "$app_identity" ]] || { print -u2 "Apple Distribution sertifikası yok. Xcode → Settings → Accounts → Manage Certificates → + → Apple Distribution"; exit 1; }
[[ -n "$installer_identity" ]] || { print -u2 "Mac Installer Distribution sertifikası yok. Xcode → Settings → Accounts → Manage Certificates → + → Mac Installer Distribution"; exit 1; }
team=$(print -r -- "$app_identity" | sed -E 's/.*\(([A-Z0-9]{10})\)$/\1/')
[[ -f "$profile" ]] || { print -u2 "Provisioning profile yok: $profile (developer.apple.com → Profiles → + → Mac App Store Connect → $bundle_id)"; exit 1; }
print "   İmza: $app_identity"
print "   Yükleyici: $installer_identity"
print "   Takım: $team"

print "▸ 2/6  Gömülü araçlar hazırlanıyor"
[[ -x Tools/appstore/bin/ffmpeg && -x Tools/appstore/bin/ffprobe ]] || scripts/build-ffmpeg-appstore.sh
[[ -f Tools/ExifTool/exiftool ]] || scripts/setup-exiftool.sh

print "▸ 3/6  App Store sürümü derleniyor (birkaç dakika)"
scratch=/tmp/malkh-appstore-build
MALKH_APPSTORE=1 swift build --scratch-path "$scratch" -c release --product Malkh -Xswiftc -file-prefix-map -Xswiftc "$PWD=/malkh" -Xswiftc -file-compilation-dir -Xswiftc /malkh
bin=$(MALKH_APPSTORE=1 swift build --scratch-path "$scratch" -c release --show-bin-path)

print "▸ 4/6  Uygulama paketi oluşturuluyor"
rm -rf "$app"; mkdir -p "$app/Contents/MacOS" "$app/Contents/Helpers" "$app/Contents/Resources/Tools"
cp "$bin/Malkh" "$app/Contents/MacOS/Malkh"; /usr/bin/strip -S "$app/Contents/MacOS/Malkh"
cp Resources/Info.plist "$app/Contents/Info.plist"
plist="$app/Contents/Info.plist"
for key in SUAllowsAutomaticUpdates SUAutomaticallyUpdate SUEnableAutomaticChecks SUEnableSystemProfiling SURequireSignedFeed SUScheduledCheckInterval SUSignedFeedFailureExpirationInterval SUVerifyUpdateBeforeExtraction SUFeedURL SUPublicEDKey NSAppTransportSecurity MalkhExternalTools MalkhPublicUpdateRepository; do
  plutil -remove "$key" "$plist" 2>/dev/null || true
done
plutil -replace CFBundleIdentifier -string "$bundle_id" "$plist"
plutil -replace CFBundleShortVersionString -string "$version" "$plist"
plutil -replace CFBundleVersion -string "$build" "$plist"
plutil -replace ITSAppUsesNonExemptEncryption -bool false "$plist"
python3 scripts/generate-localizations.py >/dev/null
ditto Resources/Localizations "$app/Contents/Resources"
[[ -d "$bin/Malkh_MalkhCore.bundle" ]] && ditto "$bin/Malkh_MalkhCore.bundle" "$app/Contents/Resources/Malkh_MalkhCore.bundle"
cp Tools/appstore/bin/ffmpeg Tools/appstore/bin/ffprobe "$app/Contents/Helpers/"
# ExifTool: yalnızca çalışan betik ve kütüphanesi (test/örnek dosyaları App Store doğrulamasını bozar).
mkdir -p "$app/Contents/Resources/Tools/ExifTool"
cp Tools/ExifTool/exiftool "$app/Contents/Resources/Tools/ExifTool/exiftool"
ditto Tools/ExifTool/lib "$app/Contents/Resources/Tools/ExifTool/lib"
[[ -f Tools/ExifTool/LICENSE ]] && cp Tools/ExifTool/LICENSE "$app/Contents/Resources/Tools/ExifTool/LICENSE"
ditto Resources/Sounds "$app/Contents/Resources/Sounds"
cp Resources/PagesInterop.js Resources/PDFLib.js Resources/PDFInterop.js Resources/MalkhIcon.icns Resources/THIRD-PARTY-NOTICES.txt "$app/Contents/Resources/"
ditto Resources/licenses "$app/Contents/Resources/licenses"
rm -f "$app/Contents/Resources/licenses/FFmpeg-GPL-2.0.txt"
cp Tools/appstore/src/ffmpeg/COPYING.LGPLv2.1 "$app/Contents/Resources/licenses/FFmpeg-LGPL-2.1.txt"
print "FFmpeg 7.1.1 is used under the LGPL 2.1. Source: https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz — built with scripts/build-ffmpeg-appstore.sh in https://github.com/busulbman/malkh" > "$app/Contents/Resources/licenses/FFmpeg-SOURCE.txt"
cp "$profile" "$app/Contents/embedded.provisionprofile"
find "$app" -name .DS_Store -delete; xattr -cr "$app"

# Apple yalnızca imzalı arm64 programları kabul eder; paket içinde başka Mach-O dosyası kalmasın.
stray=$(find "$app" -type f ! -path "*/Contents/MacOS/Malkh" ! -path "*/Contents/Helpers/*" -exec sh -c 'file -b "$1" | grep -q "Mach-O" && echo "$1"' _ {} \; || true)
if [[ -n "$stray" ]]; then print -u2 "Beklenmeyen program dosyaları siliniyor:"; print -u2 -- "$stray"; print -r -- "$stray" | while IFS= read -r f; do rm -f "$f"; done; fi
print "▸ 5/6  İmzalanıyor"
entitlements="$out/Malkh.entitlements"
sed "s/TEAM_ID/$team/g" Configuration/AppStore.entitlements > "$entitlements"
for helper in "$app/Contents/Helpers/"*; do
  codesign --force --sign "$app_identity" --entitlements Configuration/AppStoreHelper.entitlements "$helper"
done
codesign --force --sign "$app_identity" --entitlements "$entitlements" "$app"
codesign --verify --deep --strict "$app"
codesign -d --entitlements - "$app" 2>/dev/null | grep -q app-sandbox || { print -u2 "Sandbox yetkisi eksik"; exit 1; }

print "▸ 6/6  Yükleme paketi (.pkg) oluşturuluyor"
rm -f "$pkg"
productbuild --component "$app" /Applications --sign "$installer_identity" "$pkg"
print ""
print "✓ Hazır: $pkg"
print "  Yüklemek için: Transporter uygulamasını aç, bu .pkg dosyasını sürükle, Deliver'a bas."
open -R "$pkg" 2>/dev/null || true
