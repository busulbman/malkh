<p align="center"><img src="Resources/Brand/MalkhIcon.png" width="128" alt="Malkh"></p>
<h1 align="center">Malkh</h1>
<p align="center">Ваши файлы — в новом свете. · Dosyaların, yeni bir ışıkta.</p>

<p align="center">
  <a href="https://github.com/busulbman/malkh/releases/latest/download/Malkh-macOS-arm64.zip"><b>⬇︎ Mac için indir</b></a>
  · Apple Silicon (M1/M2/M3/M4) · macOS 13+
</p>

Malkh; görsel, video, ses, PDF ve ofis dosyalarını dönüştürmek ve düzenlemek için hızlı, sade bir Mac uygulaması. Finder'da dosyayı sürüklerken bir tuşa bas, açılan çarktan ne yapmak istediğini seç.

- **Dönüştür** — Shift: PNG, JPG, HEIC, WEBP, PDF, MP4, MP3 ve onlarca format
- **Düzenle** — Command: kırp, sıkıştır, not ekle, arka plan ekle, gizle, meta verileri temizle
- **Taşı ve paylaş** — Control: kopyala, taşı, AirDrop, yüzen raf (Float)
- **Bağlantıdan indir** — Control+Shift+D ile kopyalanan herkese açık video, ses ve görseller
- **Gizlilik** — tüm işlemler senin Mac'inde yapılır; hesap, analiz veya bulut yok
- **Diller** — Русский, Türkçe, English

## Kurulum

1. Yukarıdaki **Mac için indir** bağlantısından `Malkh-macOS-arm64.zip` dosyasını indir.
2. ZIP'e çift tıkla, çıkan **Malkh.app**'i **Uygulamalar** klasörüne sürükle.
3. Malkh'ı aç. macOS ilk açılışta *"Malkh açılamıyor / geliştirici doğrulanamadı"* uyarısı verirse:
   - **Sistem Ayarları → Gizlilik ve Güvenlik**'e git, en altta **Yine de Aç**'a bas ve onayla.
   - Ya da Terminal'de bir kez çalıştır: `xattr -dr com.apple.quarantine /Applications/Malkh.app`
4. İlk açılışta **Eksik araçları indir**'e bas. Medya araçları (FFmpeg, yt-dlp) resmi kaynaklarından indirilip doğrulanır. Görsel ve PDF özellikleri hemen çalışır.

Bu uyarı, uygulama henüz Apple tarafından noter onaylı (notarized) olmadığı için çıkar; yalnızca ilk açılışta bir kez gerekir. Yeni sürümler uygulama içinden güncellenir.

## Installation (English)

Download **Malkh-macOS-arm64.zip** from the link above, unzip it and move **Malkh.app** to Applications. On first launch, if macOS blocks it, open **System Settings → Privacy & Security** and click **Open Anyway** (or run `xattr -dr com.apple.quarantine /Applications/Malkh.app`). Then choose **Download missing tools** to enable media conversions.

## Geliştirme

Gereken: Apple Silicon Mac, macOS 13+, Xcode (Swift 6).

```sh
swift build --product Malkh          # derle
swift run Malkh                      # çalıştır (VS Code'da F5)
scripts/make-release.sh 1.0.0 1      # yayın paketi oluştur ve GitHub'a yükle
```

## Lisans

Geliştiren: **NurAli Khutiev** · MIT — ayrıntılar için [LICENSE](LICENSE). Üçüncü taraf bileşenlerin lisansları `Resources/licenses` ve `Resources/THIRD-PARTY-NOTICES.txt` içinde.
