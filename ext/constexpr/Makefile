DOCNO = 0579
REV = 0
PD = D
SOURCE = P$(DOCNO).md
TARGET = $(PD)$(DOCNO)$(REV)

PANDOC = pandoc

$(TARGET).html: $(SOURCE) header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html --include-in-header=pandoc.css $<

$(TARGET).pdf: $(SOURCE)
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t latex -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(TARGET)/g' < $< > $@ || rm -f $@

clean:
	rm -f $(TARGET).html *~

view: $(TARGET).html
	gnome-www-browser $(TARGET).html

cooked.txt: raw.txt
	sed -f cook < $< > $@ || rm -f $@
