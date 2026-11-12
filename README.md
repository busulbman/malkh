# Malkh

Mac için hızlı, sade dosya dönüştürme ve düzenleme uygulaması.

## Derleme

Gereken: Apple Silicon Mac, macOS 13+, Xcode (Swift 6).

```sh
scripts/setup-exiftool.sh
swift build --product Malkh
scripts/build-app.sh release
```

Uygulama `build/Malkh.app` olarak oluşur.

## Lisans

MIT — ayrıntılar için [LICENSE](LICENSE).
