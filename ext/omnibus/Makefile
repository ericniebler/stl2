# Update in header.html as well.
DOCNO = 0370
REV = 2
PD = P
SOURCE = P$(DOCNO).md
TARGET = $(PD)$(DOCNO)R$(REV)
PANDOC = pandoc

$(TARGET).html: $(SOURCE) header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

$(TARGET).pdf: $(SOURCE)
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t latex -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(TARGET)/g' < $< > $@

clean:
	rm -f $(TARGET).html *~

view: $(TARGET).html
	gnome-www-browser $(TARGET).html
