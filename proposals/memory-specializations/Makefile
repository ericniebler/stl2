# Makefile for d1033 changes

LATEX=pdflatex
BIBTEX=bibtex

MAIN=d1033

SOURCE=d1033.bib\
       acknowledgements.tex\
       config.tex\
       cover-proposal.tex\
       cxx.tex\
       front.tex\
       intro.tex\
       layout.tex\
       macros.tex\
       $(MAIN).tex\
       styles.tex\
       tables.tex\
       utilities.tex

all: $(SOURCE)
	$(LATEX) $(MAIN).tex
	$(BIBTEX) $(MAIN)
	$(LATEX) $(MAIN).tex

clean:
	rm d1033.pdf *.aux *.idx *.log *.out
