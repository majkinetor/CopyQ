#!/bin/bash
# Lays out the portable app folder (what windeployqt does in CI) for the installer.
set -euo pipefail
D=/stage
mkdir -p $D/plugins $D/translations $D/themes
cmake --install /build --prefix $D >/dev/null || true
cp -v /build/copyq.exe $D/ 2>/dev/null || cp -v /build/src/copyq.exe $D/
cp -v /build/plugins/*.dll $D/plugins/
cp -v /build/src/*.qm $D/translations/ 2>/dev/null || true
cp -v /src/shared/themes/* $D/themes/
cp -v /src/AUTHORS /src/LICENSE /src/README.md $D/
# Qt plugins the app needs at run time.
for p in platforms/qwindows styles/qmodernwindowsstyle imageformats/qsvg imageformats/qjpeg imageformats/qgif \
         imageformats/qico imageformats/qwebp iconengines/qsvgicon tls/qschannelbackend tls/qcertonlybackend; do
    f=$QT_WIN/plugins/$p.dll
    [ -f "$f" ] && { mkdir -p $D/$(dirname $p); cp -v "$f" $D/$(dirname $p)/; }
done
# Resolve DLL dependencies recursively.
SEARCH="$QT_WIN/bin $(ls -d /usr/lib/gcc/x86_64-w64-mingw32/*-posix) /usr/x86_64-w64-mingw32/lib"
resolve() {
    for f in "$@"; do
        for dll in $(x86_64-w64-mingw32-objdump -p "$f" | awk '/DLL Name:/ {print $3}'); do
            [ -f "$D/$dll" ] && continue
            for dir in $SEARCH; do
                if [ -f "$dir/$dll" ]; then cp -v "$dir/$dll" $D/; resolve "$D/$dll"; break; fi
            done
        done
    done
}
resolve $(find $D -name '*.dll' -o -name copyq.exe)
