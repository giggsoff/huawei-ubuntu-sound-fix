# Out-of-tree build of the Conexant HDA codec driver with the
# Huawei MateBook 14s/16s (SN6140) speaker/headphone routing fixup.
obj-m += snd-hda-codec-conexant.o
snd-hda-codec-conexant-y := conexant.o
ccflags-y += -I$(src)/common

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules
clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
