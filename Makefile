### -*- mode: makefile-gmake -*-

# Note: If building on Mac OS X, and if you use MacPorts, the following ports
# should be installed:
#
#   texlive-latex
#   texlive-plain-extra
#   texlive-latex-recommended
#   texlive-latex-extra
#   texlive-fonts-recommended
#   texlive-fonts-extra
#   texlive-generic-recommended

FIGURES = $(patsubst %.dot,%.pdf,$(wildcard *.dot))

TSPDF = pdflatex -jobname=$(TARGET) D4569.tex | grep -v "^Overfull"

TARGET = D4569

export TOOLS=./tools

default: rebuild

clean:
	rm -f *.aux $(TARGET).pdf *.idx *.ilg *.ind *.log *.lot *.lof *.tmp *.out

refresh:
	$(TSPDF)

rebuild:
	$(TSPDF)
	bibtex $(TARGET)
	$(TSPDF)
	$(TSPDF)

full: $(FIGURES) grammar xrefs reindex

%.pdf: %.dot
	dot -o $@ -Tpdf $<

grammar:
	sh $(TOOLS)/makegram

xrefs:
	sh $(TOOLS)/makexref

reindex:
	$(TSPDF)
	$(TSPDF)
	$(TSPDF)
	makeindex generalindex
	makeindex libraryindex
	makeindex grammarindex
	makeindex impldefindex
	$(TSPDF)
	$(TSPDF)

### Makefile ends here
