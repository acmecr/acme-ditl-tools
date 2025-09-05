
SH_SCRIPTS=\
capture-dnscap.sh \
capture-tcpdump.sh \
pcap-submit-to-oarc.sh

all:
	@for f in ${SH_SCRIPTS} ; do \
		echo "test -s $$f" ; \
		test -s $$f ; \
	done

install:
	@for f in ${SH_SCRIPTS} ; do \
		echo "chmod 755 s $$f" ; \
		chmod 755 $$f ; \
	done

clean:
