all:
	$(MAKE) -C c all

modules:
	$(MAKE) -C c modules

dtb:
	$(MAKE) -C c dtb

clean:
	$(MAKE) -C c clean

.PHONY: all modules dtb clean
