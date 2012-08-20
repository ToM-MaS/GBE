#!/bin/bash -ex
#

rm -f *.tar.gz *.tar.xz *.dsc *.build *.changes *.deb

# Install basic Debian maintainer packages
#sudo apt-get -y --force-yes install -qq sox flac

[ ! -d ./freeswitch-sounds ] && git clone git://github.com/traviscross/freeswitch-sounds.git freeswitch-sounds


cd freeswitch-sounds

git clean -fdx && git reset --hard HEAD

# building music package
./debian/bootstrap.sh -p freeswitch-music-default
./debian/rules get-orig-source
tar -xv --strip-components=1 -f *_*.orig.tar.xz && mv *_*.orig.tar.xz ../
dpkg-buildpackage -uc -us -Zxz -z9
git clean -fdx && git reset --hard HEAD

# building sounds-en package
./debian/bootstrap.sh -p freeswitch-sounds-en-us-callie
./debian/rules get-orig-source
tar -xv --strip-components=1 -f *_*.orig.tar.xz && mv *_*.orig.tar.xz ../
dpkg-buildpackage -uc -us -Zxz -z9
git clean -fdx && git reset --hard HEAD

cd -