# Maintainer: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Ilya Gulya <ilyagulya@gmail.com>
pkgname="deezer"
pkgver=4.14.1
pkgrel=3
pkgdesc="A proprietary music streaming service"
arch=('any')
url="https://www.deezer.com/"
license=('custom:"Copyright (c) 2006-2018 Deezer S.A."')
depends=('electron')
provides=('deezer')
options=('!strip')
makedepends=('p7zip' 'asar')
source=(
"$pkgname-$pkgver-setup.exe::https://www.deezer.com/desktop/download/artifact/win32/x86/$pkgver"
"$pkgname.desktop"
)
md5sums=('2fd38dda52c68f739569494f6db9630d'
         '98ec5effa2d9a1d8c3c030125a2937c0')

package() {
    
    mkdir -p "$pkgdir"/usr/share/deezer
    mkdir -p "$pkgdir"/usr/share/applications
    mkdir -p "$pkgdir"/usr/bin/

    # Extract app from installer
    7z x -so $pkgname-$pkgver-setup.exe "\$PLUGINSDIR/app-32.7z" > app-32.7z
    # Extract app archive
    7z x -y -bsp0 -bso0 app-32.7z

    cd resources/
    asar extract app.asar app
    # Fix crash on startup since 4.14.1 (patch systray icon path)
    sed -i 's/build\/linux\/systray.png/..\/..\/..\/share\/deezer\/systray.png/g' app/app/js/main/Utils/index.js
    # Remove NodeRT from package (-205.72 MiB)
    rm -r app/node_modules/@nodert
    # Fix electron 5 incompatibility
    sed -i 's/webPreferences:{dev/webPreferences:{nodeIntegration:true,dev/g' app/app/js/main/App/index.js
    sed -i 's/nodeIntegration:!1/nodeIntegration:true/g' app/app/js/main/App/index.js
    asar pack app app.asar

    cd "${srcdir}"

    echo "#!/bin/sh" > deezer
    echo "exec electron /usr/share/deezer/app.asar \"\$@\"" >> deezer

    install -Dm644 resources/app.asar "$pkgdir"/usr/share/deezer/
    install -Dm644 resources/build/win/app.ico "$pkgdir"/usr/share/deezer/
    install -Dm644 resources/build/win/systray.png "$pkgdir"/usr/share/deezer/
    install -Dm644 "$pkgname".desktop "$pkgdir"/usr/share/applications/
    install -Dm755 deezer "$pkgdir"/usr/bin/

}
