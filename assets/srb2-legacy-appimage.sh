#!/bin/bash
# srb2-legacy AppImage build script
# Dependencies: sudo apt install make git git-lfs gcc libsdl2-mixer-dev libpng-dev libcurl4-openssl-dev libgme-dev libopenmpt-dev libfuse2 file

date=$(date +"%Y%m%d%H%M%S")
mkdir "srb2legacy-AppImage"
cd "srb2legacy-AppImage"

# Prepare assets with LFS
git clone https://git.do.srb2.org/STJr/srb2assets-public.git -b SRB2_2.1 assets
cd assets
git lfs pull
echo -e "Downloaded assets: \n\n$(git lfs ls-files)"
cd ..

# Clone the repo and build the application
git clone https://github.com/P-AS/srb2-legacy.git
[ "$(uname -m)" == "i686" ] && IS64BIT="" || IS64BIT="64"
make -C srb2-legacy/src LINUX$IS64BIT=1 -j$(nproc)

# Copy files to bin
install -D srb2-legacy/bin/lsdl2srb2legacy AppDir/usr/bin/srb2legacy
install assets/* AppDir/usr/bin

# Create desktop file
cat > app.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Sonic Robo Blast 2 Legacy (2.1)
Comment=Updated fork of Sonic Robo Blast 2 2.1.25
Exec=AppRun %F
Icon=srb2legacy
Terminal=false
Categories=Game;
EOF

# Copy icon
cp srb2-legacy/srb2.png srb2legacy.png

# create app entrypoint
echo -e \#\!$(dirname $SHELL)/sh >> AppDir/AppRun
echo -e 'HERE="$(dirname "$(readlink -f "${0}")")"' >> AppDir/AppRun
echo -e 'SRB2LEGACYWADDIR=$HERE/usr/bin LD_LIBRARY_PATH=$HERE/usr/lib:$LD_LIBRARY_PATH exec $HERE/usr/bin/srb2legacy "$@"' >> AppDir/AppRun
chmod +x AppDir/AppRun

# Build AppImage
curl --retry 9999 --retry-delay 3 --speed-time 10 --retry-max-time 0 -C - -L https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$(uname -m).AppImage -o linuxdeploy
chmod +x linuxdeploy
NO_STRIP=true ./linuxdeploy --appdir AppDir --output appimage -d app.desktop -i srb2legacy.png

# clean
rm -rf srb2-legacy assets
