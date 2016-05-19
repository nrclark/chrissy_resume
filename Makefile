MAIN_FILE := nrc_resume.tex
AUX_FILES := sweet_resume.sty
PDF_LATEX := pdflatex

OUTPUT := nicholas_clark_resume.pdf
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

.INTERMEDIATE: .$(OUTPUT).temp

.$(OUTPUT).temp: $(MAIN_FILE) $(AUX_FILES)
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	$(PDF_LATEX) $<
	mv $(<:%.tex=%.pdf) $@

$(OUTPUT): .$(OUTPUT).temp
	qpdf \
	--normalize-content=y \
	--linearize \
	$< $@

preview: $(OUTPUT)
	nohup $(PDFVIEW) $(OUTPUT) 1>/dev/null 2>&1 &

clean:
	rm -f $(MAIN_FILE:%.tex=%.pdf)
	rm -f $(OUTPUT)
	rm -f *.log *.aux *.temp

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
