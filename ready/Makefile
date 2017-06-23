DOCNO = 0663
REV = 1
PD = D
SOURCE = P0XXX.md
TARGET = $(PD)$(DOCNO)R$(REV)

PANDOC = pandoc
PANDOC_FMT = markdown_github+yaml_metadata_block+citations

$(TARGET).html: $(SOURCE) header.html pandoc-template.html pandoc.css
	$(PANDOC) -f $(PANDOC_FMT) -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl -s -S --template=pandoc-template --include-before-body=header.html --include-in-header=pandoc.css $<

$(TARGET).pdf: $(SOURCE)
	$(PANDOC) -f $(PANDOC_FMT) -t latex -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(TARGET)/g' < $< > $@ || rm -f $@

clean:
	rm -f header.html $(TARGET).html $(TARGET).pdf *~

view: $(TARGET).html
	gnome-www-browser $(TARGET).html

cooked.txt: raw.txt
	sed -rf cook < $< > $@ || rm -f $@
