# Makefile for specializations changes

LATEX=pdflatex
BIBTEX=bibtex

MAIN=specializations

SOURCE=specializations.bib\
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
	rm specializations.pdf *.aux *.idx *.log *.out
