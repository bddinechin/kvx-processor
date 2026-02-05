DESTDIR?= $(abspath build/)
ARCH?= kvx
CORE?= kv3_v1
export

#FIXME: right now we need to disable TEX default protection by explicitely
# setting openout_any=a. We should instead sort out the file locations so
# that the protection is not triggered.
all install valid install-aux refcard:
	mkdir -p $(DESTDIR)/$(ARCH)
	openout_any=a $(MAKE) DESTDIR=$(DESTDIR)/$(ARCH) ARCH=$(ARCH) CORE=$(CORE) -C kvx $@

