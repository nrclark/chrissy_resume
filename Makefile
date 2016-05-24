MAIN_FILE := caw_resume.tex
AUX_FILES := sweet_resume.sty
USERNAME := $(strip $(shell id -un))
PDF_LATEX := sudo -u $(USERNAME) xelatex
AUTHOR := Christine Waynick

AUTHOR_SANITIZED := $(strip $(shell printf "$(AUTHOR)" |\
tr '[:upper:]' '[:lower:]' | tr ' ' '_'))

OUTPUT := $(AUTHOR_SANITIZED)_resume.pdf

OS := $(strip $(shell uname | tr A-Z a-z))
OS := $(findstring cygwin,$(OS))$(findstring darwin,$(OS))
OS := $(if $(OS),$(OS),linux)

ifeq ($(OS),cygwin)
	PDFVIEW := $(if $(strip $(shell which evince 2>/dev/null)),evince,cygstart)
else ifeq ($(OS),darwin) 
	PDFVIEW := open -a preview
else
	PDFVIEW := evince
endif

all default: $(OUTPUT)

.SECONDEXPANSION:
.DELETE_ON_ERROR:
.INTERMEDIATE: $(foreach x,pdf log aux metadata.txt metadata.pdf,$(MAIN_FILE:%.tex=%.$x))

%.pdf %.log %.aux: %.tex $(AUX_FILES)
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<

%.metadata.txt: %.pdf
	printf "InfoBegin\nInfoKey: Author\nInfoValue: $(AUTHOR)\n" > $@
	printf "InfoBegin\nInfoKey: Title\nInfoValue: Resume - $(AUTHOR)\n" >> $@
	pdftk $< dump_data >> $@
	sed -i 's/InfoValue:[ \t]*XeTeX.*/InfoValue:/g' $@
	sed -i 's/InfoValue:[ \t]*xdvi.*/InfoValue:/g' $@

%.metadata.pdf: %.pdf $$*.metadata.txt
	pdftk $< update_info $(lastword $^) output $@

$(OUTPUT): $(basename $(MAIN_FILE)).metadata.pdf
	qpdf \
	--normalize-content=y \
	--linearize \
	$< $@

preview: $(OUTPUT)
	nohup $(PDFVIEW) $(OUTPUT) 1>/dev/null 2>&1 &

clean:
	rm -f $(OUTPUT)
	rm -f $(foreach x,pdf log aux metadata.txt metadata.pdf,$(MAIN_FILE:%.tex=%.$x))

text: $(OUTPUT)
	gs \
	-q \
	-dNODISPLAY \
	-dSAFER \
	-dDELAYBIND \
	-dWRITESYSTEMDICT \
	-dSIMPLE \
	-f ps2ascii.ps \
	"$(OUTPUT)" \
	-dQUIET \
	-c quit
