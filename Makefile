VERSION=$(shell ./version.sh)

all: debexec_$(VERSION)_amd64.deb

clean:
	rm -rf debexec

debexec/DEBIAN/control: debian/control.in
	mkdir -p debexec/DEBIAN
	cat debian/control.in | sed "s/@@VERSION@@/$(VERSION)/" > debexec/DEBIAN/control

debexec/usr/bin:
	mkdir -p debexec/usr/bin
	ln -s /usr/share/debexec/bin/debexec debexec/usr/bin/debexec

debexec/usr/share/debexec:
	mkdir -p debexec/usr/share/debexec/

debexec/usr/share/debexec/version.sh: debexec/usr/share/debexec
	echo "printf '%s' '$(VERSION)'" > debexec/usr/share/debexec/version.sh
	chmod +x debexec/usr/share/debexec/version.sh

debexec/usr/share/debexec/bin: debexec/usr/share/debexec
	cp -a bin debexec/usr/share/debexec/

debexec/usr/share/debexec/lib: src/debexec-preload.so
	mkdir -p debexec/usr/share/debexec/lib
	cp -a src/debexec-preload.so debexec/usr/share/debexec/lib/

debexec/usr/share/debexec/scripts:
	mkdir -p debexec/usr/share/debexec
	cp -a scripts debexec/usr/share/debexec/

debexec_$(VERSION)_amd64.deb: debexec/DEBIAN/control debexec/usr/share/debexec/version.sh debexec/usr/bin debexec/usr/share/debexec/bin debexec/usr/share/debexec/lib debexec/usr/share/debexec/scripts
	dpkg-deb --build debexec debexec_$(VERSION)_amd64.deb
