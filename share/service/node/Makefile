node-$(V).tar.gz:
	/bin/rm -f download.tar.gz
	/usr/bin/curl http://nodejs.org/dist/$(V)/node-$(V).tar.gz > download.tar.gz
	@if [ "$(SHA1)" != "$$(sha1sum download.tar.gz | cut -f1 -d' ')" ]; then \
		echo "### SHA1 does match! ###"; exit 1; \
	fi
	/bin/mv download.tar.gz $@
	/bin/touch $@

node-$(V)/Makefile: node-$(V).tar.gz
	/bin/tar zxf $<
	(cd node-$(V) && ./configure --prefix=$(PREFIX))
	/bin/touch $@

node-$(V)/node: node-$(V)/Makefile
	/usr/bin/make -C node-$(V)
	/bin/touch $@

$(PREFIX)/node: node-$(V)/node
	/usr/bin/sudo /usr/bin/make -C node-$(V) install
	/usr/bin/sudo /bin/touch $@

all: $(PREFIX)/node

.PHONEY: node-$(V).tar.gz
