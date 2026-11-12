#!/bin/zsh
# Tek adımda: kodu GitHub'a gönderir, depoyu herkese açık yapar, yayın ZIP'ini oluşturup Releases'e yükler.
# Kullanım: scripts/publish.sh 1.0.0 1
set -euo pipefail
cd "${0:A:h:h}"
version=${1:-1.0.0} build=${2:-1} repo=busulbman/malkh

print "━━ 1/4  GitHub CLI hazırlanıyor"
if ! command -v gh >/dev/null; then
  if command -v brew >/dev/null; then brew install gh
  else print -u2 "Homebrew yok. Önce https://brew.sh adresindeki tek satırlık komutla Homebrew'u kur, sonra bu görevi tekrar çalıştır."; exit 1; fi
fi
if ! gh auth status >/dev/null 2>&1; then
  print "   Tarayıcıda GitHub girişi açılacak: ekrandaki 8 haneli kodu girip onayla."
  gh auth login --hostname github.com --git-protocol https --web
  gh auth setup-git
fi

print "━━ 2/4  Kod GitHub'a gönderiliyor"
if ! gh repo view "$repo" >/dev/null 2>&1; then gh repo create "$repo" --public --source . --remote origin; fi
git remote set-url origin "https://github.com/$repo.git"
git push -u origin main

print "━━ 3/4  Depo herkese açık yapılıyor (arkadaşların indirebilsin diye)"
gh repo edit "$repo" --visibility public --accept-visibility-change-consequences >/dev/null 2>&1 || true

print "━━ 4/4  Uygulama derleniyor ve yayınlanıyor"
scripts/make-release.sh "$version" "$build"
if [[ -n "$(git status --porcelain Configuration)" ]]; then
  git add Configuration && git commit -qm "Güncelleme anahtarı (açık anahtar)" && git push
fi
print ""
print "✓ Bitti. Arkadaşına gönderilecek link:  https://github.com/$repo"
print "  Doğrudan indirme:  https://github.com/$repo/releases/latest/download/Malkh-macOS-arm64.zip"
