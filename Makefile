MAIN_FILE := caw_resume.tex
COVER_LETTER := caw_letter.tex
AUX_FILES := sweet_resume.sty
USERNAME := $(strip $(shell id -un))
PDF_LATEX := sudo -u $(USERNAME) xelatex
AUTHOR := Christine Waynick

AUTHOR_SANITIZED := $(strip $(shell printf "$(AUTHOR)" |\
tr '[:upper:]' '[:lower:]' | tr ' ' '_'))

RESUME := $(AUTHOR_SANITIZED)_resume.pdf
LETTER := $(AUTHOR_SANITIZED)_letter.pdf

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

get_type = $(strip $(shell printf "$(lastword $(subst _, ,$(basename $1)))" |\
	   	     sed -r 's/\<./\U&/g'))
test:
	echo $(call get_type,$(MAIN_FILE))
	echo $(call get_type,$(COVER_LETTER))

all default: $(RESUME)

.SECONDEXPANSION:
.DELETE_ON_ERROR:
.INTERMEDIATE: $(foreach x,pdf log aux metadata.txt metadata.pdf,$(MAIN_FILE:%.tex=%.$x))
.INTERMEDIATE: $(foreach x,pdf log aux metadata.txt metadata.pdf,$(COVER_LETTER:%.tex=%.$x))

%.pdf %.log %.aux: %.tex $(AUX_FILES)
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<

%.metadata.txt: %.pdf
	printf "InfoBegin\nInfoKey: Author\nInfoValue: $(AUTHOR)\n" > $@
	printf "InfoBegin\nInfoKey: Title\nInfoValue: $(call get_type,$<) - $(AUTHOR)\n" >> $@
	pdftk $< dump_data >> $@
	sed -i 's/InfoValue:[ \t]*XeTeX.*/InfoValue:/g' $@
	sed -i 's/InfoValue:[ \t]*xdvi.*/InfoValue:/g' $@

%.metadata.pdf: %.pdf $$*.metadata.txt
	pdftk $< update_info $(lastword $^) output $@

resume: $(RESUME)
$(RESUME): $(basename $(MAIN_FILE)).metadata.pdf
	qpdf \
	--normalize-content=y \
	--linearize \
	$< $@

letter: $(LETTER)
$(LETTER): $(basename $(COVER_LETTER)).metadata.pdf
	qpdf \
	--normalize-content=y \
	--linearize \
	$< $@

preview: $(LETTER) $(RESUME)
	nohup $(PDFVIEW) $^ 1>/dev/null 2>&1 &

clean:
	rm -f $(RESUME) $(LETTER)
	rm -f $(foreach x,pdf log aux metadata.txt metadata.pdf,$(MAIN_FILE:%.tex=%.$x))

text: $(RESUME) $(LETTER)
	gs \
	-q \
	-dNODISPLAY \
	-dSAFER \
	-dDELAYBIND \
	-dWRITESYSTEMDICT \
	-dSIMPLE \
	-f ps2ascii.ps \
	$^ \
	-dQUIET \
	-c quit
