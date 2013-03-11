#!/bin/bash -ex
#

# settings
#
distro=wheezy
arch=i386
suite=stable
http_proxy=http://localhost:3128/

rm -f *.tar.gz *.tar.xz *.dsc *.build *.changes *.deb

# Install basic Debian maintainer packages
#sudo apt-get -y --force-yes install -qq build-essential git-buildpackage udev autoconf automake autotools-dev debhelper dh-make devscripts fakeroot file gfortran git gnupg lintian patch patchutils pbuilder perl python python xutils-dev libicu-dev libgnutls-dev libtheora-dev libtheora-dev 

[ ! -d /var/cache/pbuilder/base-${distro}-${arch}.cow ] && DIST=${distro} ARCH=${arch} git-pbuilder create || DIST=${distro} ARCH=${arch} git-pbuilder update
[ ! -L /dev/fd ] && sudo ln -s /proc/self/fd /dev/fd
if [ ! -d ./freeswitch ]; then
 git clone -b v1.2.stable git://git.freeswitch.org/freeswitch freeswitch
 (cd freeswitch; git branch master; git branch -D v1.2.stable)
fi


cd freeswitch

ver="$(cat build/next-release.txt | sed -e 's/-/~/g')~n$(date +%Y%m%dT%H%M%SZ)-1~${distro}+1"
git clean -fdx && git reset --hard HEAD

echo "# Do not generate diff for changes in configure.in
extend-diff-ignore = \"configure.in$\"" > debian/source/options

./build/set-fs-version.sh "$ver"
[ -f ../modules_${distro}.conf ] && cp -L ../modules_${distro}.conf debian/modules.conf
(cd debian && ./bootstrap.sh -c $distro)
git add configure.in && git commit -m "bump to custom v$ver"
dch -b -m -v "$ver" --force-distribution -D "$suite" "Custom build."

# Needs sudo right if user!=root:
# username ALL= SETENV: ALL, NOPASSWD: /usr/sbin/cowbuilder
git-buildpackage -b -us -uc \
  --git-verbose \
  --git-pbuilder --git-dist=$distro --git-arch=$arch \
  --git-keyid=09E60DF5 \
  --git-compression-level=1v --git-compression=xz
git reset --hard HEAD^

cd -