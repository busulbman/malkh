#!/bin/zsh
# Malkh yayın paketi: derler, imzalar, zipler ve (gh varsa) GitHub Release olarak yükler.
# Kullanım:  scripts/make-release.sh 1.0.0 1
#            (sürüm numarası, yapı numarası — her yeni yayında ikisini de artırın)
set -euo pipefail
cd "${0:A:h:h}"
if (( $# != 2 )); then print -u2 'Kullanım: scripts/make-release.sh SÜRÜM YAPI   örn: scripts/make-release.sh 1.0.0 1'; exit 1; fi
version=$1 build=$2
repo=busulbman/malkh
account=com.busulbman.malkh

print "▸ 1/5  Paketler hazırlanıyor…"
swift package resolve
[[ -f Tools/ExifTool/exiftool ]] || scripts/setup-exiftool.sh

print "▸ 2/5  Güncelleme imza anahtarı kontrol ediliyor…"
sparkle="$PWD/.build/artifacts/sparkle/Sparkle/bin"
if [[ ! -f Configuration/Updates.public.plist ]]; then
  # Özel anahtar yalnızca bu Mac'in Anahtar Zinciri'nde kalır; repoya yalnızca açık anahtar yazılır.
  if ! public_key=$("$sparkle/generate_keys" --account "$account" -p 2>/dev/null); then
    "$sparkle/generate_keys" --account "$account" >/dev/null
    public_key=$("$sparkle/generate_keys" --account "$account" -p)
  fi
  cat > Configuration/Updates.public.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>FeedURL</key>
	<string>https://github.com/$repo/releases/latest/download/appcast.xml</string>
	<key>PublicEDKey</key>
	<string>$public_key</string>
	<key>PublicRepository</key>
	<string>$repo</string>
</dict>
</plist>
PLIST
  print "   Yeni anahtar oluşturuldu (Anahtar Zinciri: $account). Bu Mac'i değiştirirsen anahtarı yedekle:"
  print "   $sparkle/generate_keys --account $account -x malkh-update-key.txt"
fi

print "▸ 3/5  Uygulama derleniyor ve paketleniyor ($version, yapı $build)…"
MALKH_UPDATE_KEY_ACCOUNT=$account scripts/prepare-public-release.sh "$version" "$build"
upload="$PWD/build/public-upload-$version-$build"

print "▸ 4/5  Paket hazır: $upload/Malkh-macOS-arm64.zip"
tag="v$version-$build"
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  print "▸ 5/5  GitHub Release oluşturuluyor ($tag)…"
  gh release create "$tag" "$upload"/* --repo "$repo" --title "Malkh $version" \
    --notes "İndir: Malkh-macOS-arm64.zip · Apple Silicon, macOS 13+. Kurulum adımları README'de."
  print "✓ Yayınlandı: https://github.com/$repo/releases/tag/$tag"
else
  print "▸ 5/5  GitHub CLI (gh) yok ya da giriş yapılmamış. Elle yüklemek için:"
  print "   1) https://github.com/$repo/releases/new adresini aç"
  print "   2) Tag: $tag   Başlık: Malkh $version"
  print "   3) Şu klasördeki dosyaların hepsini sürükle: $upload"
  print "   4) Publish release"
  open "$upload" 2>/dev/null || true
fi
