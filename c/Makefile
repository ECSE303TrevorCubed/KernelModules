ifneq ($(KERNELRELEASE),)
obj-m += blink_km.o
obj-m += dht11.o

else
KDIR ?= /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)
DTC  ?= dtc

all: modules dtb

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

blink_km:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

dht11:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

dtb: dht11-overlay.dtb

dht11-overlay.dtb: dht11.dts
	$(DTC) -I dts -O dtb -o $@ -b 0 -@ $<

clean:
	@if [ -d "$(KDIR)" ]; then \
		$(MAKE) -C $(KDIR) M=$(PWD) clean; \
	fi
	rm -f *.o *.ko *.mod *.mod.c *.mod.o *.order *.symvers .*.cmd dht11-overlay.dtb *.dtbo
	rm -rf .tmp_versions

.PHONY: all modules blink_km dht11 dtb clean
endif
