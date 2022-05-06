VERSION=$(shell ./version.sh)

all: debexec_$(VERSION)_amd64.deb

clean:
	rm -rf debexec

debexec/DEBIAN:
	mkdir -p debexec/DEBIAN
	cp -a debian/postinst debian/prerm debexec/DEBIAN

debexec/DEBIAN/control: debian/control.in debexec/DEBIAN
	cat debian/control.in | sed "s/@@VERSION@@/$(VERSION)/" > debexec/DEBIAN/control

debexec/usr/bin:
	mkdir -p debexec/usr/bin
	ln -s /usr/share/debexec/bin/debexec debexec/usr/bin/debexec

debexec/usr/share/binfmts:
	mkdir -p debexec/usr/share/binfmts/
	cp -a binfmts/debexec debexec/usr/share/binfmts/debexec

debexec/usr/share/mime/packages/debexec.xml:
	mkdir -p debexec/usr/share/mime/packages/
	cp -a mime/debexec.xml debexec/usr/share/mime/packages/debexec.xml

debexec/usr/share/applications/debexec.desktop:
	mkdir -p debexec/usr/share/applications/
	cp -a mime/debexec.desktop debexec/usr/share/applications/debexec.desktop

.icon-cache:
	mkdir -p .icon-cache
	./icons/render-bitmaps.py --source-path icons/Yaru --dest-path .icon-cache

debexec/usr/share/icons: .icon-cache
	mkdir -p debexec/usr/share/icons/
	cp -a .icon-cache/Yaru debexec/usr/share/icons/hicolor

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

debexec_$(VERSION)_amd64.deb: debexec/DEBIAN/control debexec/usr/share/debexec/version.sh debexec/usr/bin debexec/usr/share/binfmts debexec/usr/share/mime/packages/debexec.xml debexec/usr/share/applications/debexec.desktop debexec/usr/share/icons debexec/usr/share/debexec/bin debexec/usr/share/debexec/lib debexec/usr/share/debexec/scripts
	dpkg-deb --build debexec debexec_$(VERSION)_amd64.deb
