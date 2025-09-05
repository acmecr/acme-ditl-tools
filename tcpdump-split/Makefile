
PROGS= \
tcpdump-split

CFLAGS = -Wall -g
LDFLAGS = -lpcap

all: $(PROGS) 

install:
	@for f in ${PROGS} ; do \
		echo "install -m 755 $$f /usr/local/bin" ; \
		install -m 755 $$f /usr/local/bin ; \
	done

clean:
	rm -f $(PROGS)
