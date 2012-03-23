target/upgrade:
	cd ~/janitor && bin/puppy/upgrade
	mkdir -p target
	touch target/upgrade

target/public-dns: target/upgrade
	/usr/bin/ssh alvar.balance.south.virginia.runpup.com janitor/bin/dns/public/publish
	touch target/public-dns

target/ternary-dns: target/public-dns
	/usr/bin/sudo ~/janitor/bin/dns/install
	~/janitor/bin/loopback/mount /dev/loop5 /mnt/dns
	~/janitor/bin/dns/private/config
	~/janitor/bin/dns/private/publish
	~/janitor/bin/dns/cache/config
	touch target/ternary-dns

target/flush-dns: target/ternary-dns
	sudo /usr/sbin/unbound-control -c /etc/unbound/unbound.conf flush_zone .
	touch target/flush-dns

target/data-north-upgrade: target/flush-dns
	./other-upgrade alvar.data.north
	touch target/data-north-upgrade

target/data-south-upgrade: target/flush-dns
	./other-upgrade alvar.data.south
	touch target/data-south-upgrade

target/secondary-dns: target/data-north-upgrade
	./other-dns alvar.data.north
	touch target/secondary-dns

target/primary-dns: target/secondary-dns
	./other-dns alvar.data.south
	touch target/primary-dns

target/secondary-postgresql: target/primary-dns
	./other-postgresql-install alvar.data.north

target/primary-postgresql: target/secondary-postgresql
	./other-postgresql-install alvar.data.south

.PHONEY: upgrade
