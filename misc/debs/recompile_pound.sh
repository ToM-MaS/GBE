rm -rf build-pound
mkdir build-pound
cd build-pound
sudo apt-get source pound
sudo apt-get build-dep pound
dpkg-source -x pound_*.dsc
cd pound-*
sed -i '/.\/configure/ s/$/ --with-maxbuf=8192/' debian/rules
make clean
dpkg-buildpackage -rfakeroot -b
