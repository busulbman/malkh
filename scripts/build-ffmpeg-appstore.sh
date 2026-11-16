#!/bin/zsh
# App Store sürümü için lisans uyumlu (LGPL) FFmpeg/FFprobe derler.
# GPL bileşen (x264, x265) yok; H.264/HEVC için Apple VideoToolbox kullanılır.
# Çıktı: Tools/appstore/bin/ffmpeg ve ffprobe (Apple Silicon, macOS 13+)
set -euo pipefail
cd "${0:A:h:h}"
root="$PWD/Tools/appstore"; src="$root/src"; prefix="$root/prefix"
mkdir -p "$src" "$prefix" "$root/bin"
export MACOSX_DEPLOYMENT_TARGET=13.0
export CFLAGS="-arch arm64 -mmacosx-version-min=13.0 -O2" CXXFLAGS="-arch arm64 -mmacosx-version-min=13.0 -O2" LDFLAGS="-arch arm64 -mmacosx-version-min=13.0"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
jobs=$(sysctl -n hw.ncpu)

if ! command -v pkg-config >/dev/null; then
  command -v brew >/dev/null || { print -u2 "pkg-config gerekli: önce Homebrew kurun (https://brew.sh)"; exit 1; }
  brew install pkgconf
fi

fetch() { # url dosya
  [[ -f "$src/$2" ]] || curl --fail --location --retry 3 "$1" -o "$src/$2"
}
unpack() { # dosya klasör
  [[ -d "$src/$2" ]] || { mkdir -p "$src/$2"; tar -xf "$src/$1" -C "$src/$2" --strip-components=1; }
}
built() { [[ -f "$prefix/lib/$1" ]]; }

print "▸ lame 3.100 (MP3, LGPL)"
if ! built libmp3lame.a; then
  fetch https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz lame.tar.gz; unpack lame.tar.gz lame
  (cd "$src/lame" && sed -i '' '/lame_init_old/d' include/libmp3lame.sym && ./configure --prefix="$prefix" --disable-shared --enable-static --disable-frontend --host=aarch64-apple-darwin && make -j$jobs && make install)
fi
print "▸ opus 1.5.2 (BSD)"
if ! built libopus.a; then
  fetch https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz opus.tar.gz; unpack opus.tar.gz opus
  (cd "$src/opus" && ./configure --prefix="$prefix" --disable-shared --enable-static --disable-doc --disable-extra-programs && make -j$jobs && make install)
fi
print "▸ libogg 1.3.5 + libvorbis 1.3.7 (BSD)"
if ! built libvorbis.a; then
  fetch https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz ogg.tar.gz; unpack ogg.tar.gz ogg
  (cd "$src/ogg" && ./configure --prefix="$prefix" --build=aarch64-apple-darwin --host=aarch64-apple-darwin --disable-shared --enable-static && make -j$jobs && make install)
  fetch https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz vorbis.tar.gz; unpack vorbis.tar.gz vorbis
  # Eski libvorbis, Apple Silicon'da artık tanınmayan -force_cpusubtype_ALL bayrağını ekliyor; temizle.
  (cd "$src/vorbis" && sed -i '' 's/-force_cpusubtype_ALL//g' configure && ./configure --prefix="$prefix" --build=aarch64-apple-darwin --host=aarch64-apple-darwin --disable-shared --enable-static --disable-examples --with-ogg="$prefix" && make -C lib -j$jobs && make -C lib install && make -C include install && install -m 644 vorbis.pc vorbisenc.pc vorbisfile.pc "$prefix/lib/pkgconfig/")
fi
print "▸ libvpx 1.15.0 (VP8/VP9, BSD)"
if ! built libvpx.a; then
  fetch https://github.com/webmproject/libvpx/archive/refs/tags/v1.15.0.tar.gz vpx.tar.gz; unpack vpx.tar.gz vpx
  (cd "$src/vpx" && ./configure --prefix="$prefix" --target=arm64-darwin22-gcc --disable-shared --enable-static --disable-examples --disable-tools --disable-docs --disable-unit-tests --enable-vp9-highbitdepth && make -j$jobs && make install)
fi
print "▸ libwebp 1.5.0 (BSD)"
if ! built libwebp.a; then
  fetch https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.5.0.tar.gz webp.tar.gz; unpack webp.tar.gz webp
  (cd "$src/webp" && ./configure --prefix="$prefix" --disable-shared --enable-static --disable-gif --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff && make -j$jobs && make install)
fi
print "▸ FFmpeg 7.1.1 (LGPL)"
fetch https://ffmpeg.org/releases/ffmpeg-7.1.1.tar.xz ffmpeg.tar.xz; unpack ffmpeg.tar.xz ffmpeg
(cd "$src/ffmpeg" && ./configure --prefix="$prefix" --arch=arm64 --target-os=darwin --cc=clang \
  --disable-gpl --disable-nonfree --disable-shared --enable-static \
  --disable-doc --disable-ffplay --disable-network --disable-debug \
  --enable-videotoolbox --enable-audiotoolbox \
  --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libwebp \
  --pkg-config-flags=--static --extra-cflags="-I$prefix/include -mmacosx-version-min=13.0" --extra-ldflags="-L$prefix/lib -mmacosx-version-min=13.0" \
  && make -j$jobs && cp ffmpeg ffprobe "$root/bin/")

print "▸ Kontrol"
"$root/bin/ffmpeg" -hide_banner -version | head -1
if "$root/bin/ffmpeg" -hide_banner -L 2>/dev/null | grep -q "GNU General Public License"; then print -u2 "HATA: GPL derlendi"; exit 1; fi
for lib in $(otool -L "$root/bin/ffmpeg" | tail -n +2 | awk '{print $1}'); do
  [[ "$lib" == /usr/lib/* || "$lib" == /System/* ]] || { print -u2 "HATA: sistem dışı kütüphane bağlı: $lib"; exit 1; }
done
"$root/bin/ffmpeg" -hide_banner -encoders 2>/dev/null | grep -E "h264_videotoolbox|libmp3lame|libopus|libvorbis|libvpx-vp9|libwebp " | awk '{print "   ✓",$2}'
print "✓ LGPL FFmpeg hazır: $root/bin"
