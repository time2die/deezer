#!/bin/sh

# Maintainer: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Ilya Gulya <ilyagulya@gmail.com>
pkgname="deezer"
pkgver=5.30.70
srcdir="$PWD"

install_dependencies() {
    # Manually install Node.js 12 since the version provided in some Ubuntu distros
    # is older than 10.13.0 which prettier requires.
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt install -y p7zip-full imagemagick nodejs wget g++ make patch
    sudo npm install -g electron@^13 --unsafe-perm=true
    sudo npm install -g --engine-strict asar
    sudo npm install -g prettier
}

prepare() {
    # Download installer
    wget "https://www.deezer.com/desktop/download/artifact/win32/x86/$pkgver" -O "$pkgname-$pkgver-setup.exe"
    # Extract app from installer
    7z x -so $pkgname-$pkgver-setup.exe "\$PLUGINSDIR/app-32.7z" > app-32.7z
    # Extract app archive
    7z x -y -bsp0 -bso0 app-32.7z

    # Extract png from ico container
    convert resources/win/app.ico resources/win/deezer.png

    cd resources/
    rm -rf app "$srcdir/npm_temp" || true
    asar extract app.asar app

    mkdir -p app/resources/linux/

    # Remove NodeRT from package (-205.72 MiB)
    rm -r app/node_modules/@nodert

    # Install extra node modules for mpris-service
    mkdir "$srcdir/npm_temp"; cd "$srcdir/npm_temp"
    npm install  --prefix ./ mpris-service

    for d in node_modules/*; do
        if [ ! -d "$srcdir/resources/app/node_modules/$(basename $d)" ]
        then
            mv "$d" "$srcdir/resources/app/node_modules/"
        fi
    done

    cd "$srcdir/resources/app"
    mkdir -p resources/linux/
    install -Dm644 "$srcdir/resources/win/systray.png" resources/linux/

    prettier --write "build/*.js"
    # Hide to tray (https://github.com/SibrenVasse/deezer/issues/4)
    patch -p1 < "$srcdir/quit.patch"
    # Add start in tray cli option (https://github.com/SibrenVasse/deezer/pull/12)
    patch --forward --strip=1 --input="$srcdir/start-hidden-on-tray.patch"

    cd ..
    asar pack app app.asar
}

package() {
    cd "$srcdir"
    sudo mkdir -p "$pkgdir"/usr/share/deezer
    sudo mkdir -p "$pkgdir"/usr/share/applications
    sudo mkdir -p "$pkgdir"/usr/bin/
    for size in 16 32 48 64 128 256; do
        sudo mkdir -p "$pkgdir"/usr/share/icons/hicolor/${size}x${size}/apps/
    done

    sudo install -Dm644 resources/app.asar "$pkgdir"/usr/share/deezer/
    sudo install -Dm644 resources/win/deezer-0.png "$pkgdir"/usr/share/icons/hicolor/16x16/apps/deezer.png
    sudo install -Dm644 resources/win/deezer-1.png "$pkgdir"/usr/share/icons/hicolor/32x32/apps/deezer.png
    sudo install -Dm644 resources/win/deezer-2.png "$pkgdir"/usr/share/icons/hicolor/48x48/apps/deezer.png
    sudo install -Dm644 resources/win/deezer-3.png "$pkgdir"/usr/share/icons/hicolor/64x64/apps/deezer.png
    sudo install -Dm644 resources/win/deezer-4.png "$pkgdir"/usr/share/icons/hicolor/128x128/apps/deezer.png
    sudo install -Dm644 resources/win/deezer-5.png "$pkgdir"/usr/share/icons/hicolor/256x256/apps/deezer.png
    sudo install -Dm644 "$pkgname".desktop "$pkgdir"/usr/share/applications/
    sudo install -Dm755 deezer "$pkgdir"/usr/bin/

    # Make sure the deezer:// protocol handler is immediately registered as it's needed for login 
    sudo update-desktop-database --quiet
}

install_dependencies && prepare && package
echo "Successfully installed Deezer Desktop!"
