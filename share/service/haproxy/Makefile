haproxy-$(V).tar.gz: 
	rm -f download.tar.gz
	curl "http://haproxy.1wt.eu/download/$$(expr "$V" : "\([0-9]\.[0-9]\)")/src/$$(echo "$V" | grep dev > /dev/null && echo 'devel/')haproxy-$V.tar.gz" > download.tar.gz
	@if [ "$(MD5)" != "$$(md5sum download.tar.gz | cut -f1 -d' ')" ]; then \
		echo "### MD5 does match! ###"; exit 1; \
	fi
	mv download.tar.gz $@
	touch $@

haproxy-$(V)/Makefile: haproxy-$(V).tar.gz
	rm -rf haproxy-$(V)
	tar zxf $<
	touch $@

haproxy-$(V)/haproxy: haproxy-$(V)/Makefile
	(cd haproxy-$(V) && make TARGET=linux26 USE_PCRE=1)

/opt/sbin/haproxy: haproxy-$(V)/haproxy
	sudo mkdir -p /opt/sbin
	sudo cp haproxy-$(V)/haproxy /opt/sbin/haproxy

all: /opt/sbin/haproxy

.PHONEY: /opt/sbin/haproxy
