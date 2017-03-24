# Makefile for specializations changes

LATEX=pdflatex
BIBTEX=bibtex

MAIN=signed

SOURCE=$(MAIN).bib\
       config.tex\
       cxx.tex\
       layout.tex\
       macros.tex\
       $(MAIN).tex\
       proposal.tex\
       styles.tex\
       tables.tex\

all: $(SOURCE)
	$(LATEX) $(MAIN).tex
	$(BIBTEX) $(MAIN)
	$(LATEX) $(MAIN).tex

clean:
	rm signed.pdf *.aux *.idx *.log *.out
