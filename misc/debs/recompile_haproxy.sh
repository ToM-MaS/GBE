rm -rf build-haproxy
mkdir build-haproxy
cd build-haproxy
sudo apt-get install devscripts
sudo apt-get build-dep haproxy
sudo apt-get source haproxy
wget http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-1.5-dev17.tar.gz -O haproxy-1.5.orig.tar.gz
tar xfz haproxy-1.5.orig.tar.gz
mv haproxy-1.5-dev17 haproxy-1.5
cp -r haproxy-1.4.15/debian/ haproxy-1.5
rm -rf haproxy-1.4.15/ haproxy-1.4.15.orig.tar.gz haproxy-1.5/debian/patches/*

cd haproxy-*
sed -i 's/USE_PCRE=1/USE_PCRE=1 \\\n\t USE_OPENSSL=1/' debian/rules
DEBFULLNAME="Julian Pawlowski"
DEBEMAIL="julian.pawlowski@gmail.com"
dch -b -v 1.5-1 --package haproxy Upgrade to new development version 1.5-dev17
dpkg-buildpackage -rfakeroot -b
