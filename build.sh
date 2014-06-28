#!/bin/bash
GECKO_VERSION=33
VERSION=${GECKO_VERSION}.0a1-`date +%d%m%y%H%M`

rm -rf tmp

mkdir -p tmp/opt/b2g
mkdir -p tmp/usr/share/xsessions
mkdir -p tmp/usr/share/unity-greeter #needed if session is unity
mkdir -p tmp /usr/share/xgreeters      #for non-unity based distros
mkdir -p tmp/DEBIAN

#making sure necessary tools are installed
python bootstrap.py
# Clone gaia if needed, or just update.
# Using --depth 1 to get as few git history as possible.
if [ ! -d ../gaia ]; then
echo "Cloning gaia repository"
git clone --depth 1 https://github.com/mozilla-b2g/gaia.git
fi
echo "updating repo  "
cd ../gaia; git pull;DESKTOP_SHIMS=1 NOFTU=1 make; cd ..

# Create an archive of the profile.
tar --directory gaia/profile -cjf  deb-b2g/tmp/opt/b2g/profile.tar.bz2 `ls gaia/profile`
echo "created archive"
# Download the latest b2g desktop build and unpack it.
##wget https://ftp.mozilla.org/pub/mozilla.org/b2g/nightly/latest-mozilla-central/en-US/b2g-${GECKO_VERSION}.0a1.en-US.linux-x86_64.tar.bz2
#If you want to use your own compiled build then run ./mach package after running ./mach build , you will then have a tar.bz2 file of your compiled build at your build directory under dist folder,copy that file to the home directory ,and comment out the previous line that downloads the b2g from ftp using wget.
if [ ! -d gecko-dev]; then
echo "Cloning gecko repository"
git clone --depth 1 https://github.com/mozilla/gecko-dev.git
fi
echo "updating repo  "
cd gecko-dev
git pull
./mach build
./mach package
cp ~/build/dist/b2g-${GECKO_VERSION}.0a1.en-US.linux-x86_64.tar.bz2 ~/
cd
tar --directory deb-b2g/tmp/opt/b2g -xjf  b2g-${GECKO_VERSION}.0a1.en-US.linux-x86_64.tar.bz2
rm b2g-${GECKO_VERSION}.0a1.en-US.linux-x86_64.tar.bz2
cd deb-b2g

cp launch.sh tmp/opt/b2g/launch.sh
cp session.sh tmp/opt/b2g/session.sh
cp b2g.desktop tmp/usr/share/xsessions/b2g.desktop

touch tmp/DEBIAN/control

cat > tmp/DEBIAN/control << EOF
Package: b2g-DE
Version: ${VERSION}
Maintainer: Fabrice Desré <fabrice@desre.org>
Homepage: https://github.com/fabricedesre/deb-b2g
Architecture: amd64
Description: Boot 2 Gecko which is the technical name of Firefox OS (http://www.mozilla.org/en-US/firefox/os/) is a web based operating system .The project’s architecture eliminates the need for apps to be 
 built on platform-specific native APIs which we commonly see in Devices. Using HTML5, developers everywhere
 can write directly to the Web; they can create amazing user experiences and
 apps unencumbered by the rules and restrictions of closely controlled
 platforms.The Current B2G nightly version is 2.1 and this package uses the nightly b2g version.
 As with all Mozilla projects, the Boot to Gecko project is based entirely on
 open standards and the source code is open and accessible to all. WebAPIs to use most of the hardware of devices is being made and we are working with bodies to create APIs which are not yet available.
 .
EOF

fakeroot dpkg-deb -b tmp b2g_${VERSION}_amd64.deb
echo "You can install your b2g package with |sudo dpkg -i b2g_${VERSION}_amd64.deb| and launch it with |/opt/b2g/launch.sh|"
