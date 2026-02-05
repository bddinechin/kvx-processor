ARCH?=kvx

CORE:=kv3_v1

CORE_NAME:=$(subst _,-,$(CORE))

DESTDIR?=$(abspath build/)

LATEX=pdflatex
LATEXOPT=--shell-escape
NONSTOP=--interaction=nonstopmode

LATEXMK=latexmk
LATEXMKOPT=-pdf -outdir=$(DESTDIR)
CONTINUOUS=#-pvc
export TEXINPUTS=$(abspath ../../kvx-family/BE/TEX/$(ARCH)/$(CORE))

TOPDOCS:=$(CORE_NAME)-VLIWCore $(CORE_NAME)-Optimization $(CORE_NAME)-VLIWCoreABI

# Generate top documentations targets
define gen_targets
$(1).pdf: $(1).tex
	$(LATEXMK) $(LATEXMKOPT) $(CONTINUOUS) \
		-pdflatex="$(LATEX) $(LATEXOPT) $(NONSTOP) %O %S" $(1)
endef
$(foreach doc,$(TOPDOCS),$(eval $(call gen_targets,$(doc))))

$(CORE_NAME)-RefCard.pdf:
	cd $(DESTDIR) && \
		pdftex $(abspath $(CORE_NAME)-RefCard.tex) && pdftex $(abspath $(CORE_NAME)-RefCard.tex)


all: $(addsuffix .pdf,$(TOPDOCS)) $(CORE_NAME)-RefCard.pdf

clean:
	rm -f $(addprefix $(DESTDIR)/*,.pdf .bbl .blg .aux .end .fls .log .out .to .fdb_latexmk .glg .glo .gls .ist .idx .ilg .ind)


install:
	mkdir -p $(DOC_INSTALL_DESTDIR)
	install -D $(DESTDIR)/*.pdf $(DOC_INSTALL_DESTDIR)/


install-aux:
	mkdir -p $(DOC_INSTALL_DESTDIR)
	cd "$(DESTDIR)" && find -name "*.aux" | while read d; do install -D $(DESTDIR)/$$d $(DOC_INSTALL_AUX_DESTDIR)/$$d; done


valid:

.PHONY: clean install install-aux valid all $(addsuffix .pdf,$(TOPDOCS))
