
all clean install:
	@for d in *; do \
		test -s $$d/Makefile || continue ; \
		echo "(cd $$d; ${MAKE} $@)" ; \
		(cd $$d; ${MAKE} $@) ; \
	done
