# Cross-compiles CopyQ for Windows with mingw-w64 and packs the Inno Setup installer.
#   docker build -f dev/windows-installer/Dockerfile --output type=local,dest=dist .
# Not in the build: tab encryption (QCA), keychain integration and native notifications (KF6).
FROM debian:trixie AS build
ARG QT_VERSION=6.10.3
ARG APP_VERSION=17.0.0.1
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        g++-mingw-w64-x86-64-posix gcc-mingw-w64-x86-64-posix binutils-mingw-w64-x86-64 \
        cmake ninja-build python3-pip python3-venv git ca-certificates \
        libgl1 libglib2.0-0 libxkbcommon0 libfontconfig1 libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/aqt && /opt/aqt/bin/pip install --no-cache-dir aqtinstall
RUN /opt/aqt/bin/aqt install-qt linux desktop ${QT_VERSION} linux_gcc_64 -O /opt/qt \
 && /opt/aqt/bin/aqt install-qt windows desktop ${QT_VERSION} win64_mingw -O /opt/qt
RUN apt-get update && apt-get install -y --no-install-recommends libminiaudio-dev \
    && rm -rf /var/lib/apt/lists/*
ENV QT_HOST=/opt/qt/${QT_VERSION}/gcc_64 QT_WIN=/opt/qt/${QT_VERSION}/mingw_64
COPY dev/windows-installer/toolchain.cmake dev/windows-installer/stage.sh /opt/
COPY . /src
RUN cmake -S /src -B /build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/opt/toolchain.cmake \
        -DCMAKE_CXX_FLAGS="-DWINVER=0x0A00 -D_WIN32_WINNT=0x0A00" \
        -DWITH_QCA_ENCRYPTION=OFF -DWITH_KEYCHAIN=OFF -DWITH_NATIVE_NOTIFICATIONS=OFF -DWITH_TESTS=OFF \
    && GITHUB_REF=refs/tags/v${APP_VERSION} cmake --build /build
RUN APP_VERSION=${APP_VERSION} bash /opt/stage.sh

FROM amake/innosetup AS installer
ARG APP_VERSION=17.0.0.1
COPY --from=build --chown=xclient:xclient /src /home/xclient/work/src
COPY --from=build --chown=xclient:xclient /stage /home/xclient/work/stage
RUN mkdir -p /home/xclient/work/out && cd /home/xclient/work/src/shared \
    && sed -i '/^Source: .*Flags:/ { /skipifsourcedoesntexist/! s/Flags: /Flags: skipifsourcedoesntexist / }' copyq.iss \
    && iscc /O"Z:\\home\\xclient\\work\\out" /DAppVersion=${APP_VERSION} \
        /DRoot="Z:\\home\\xclient\\work\\stage" /DSource="Z:\\home\\xclient\\work\\src" copyq.iss

FROM scratch
COPY --from=installer /home/xclient/work/out/ /
