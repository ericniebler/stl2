DOCNO = 4686
PD = N
SOURCE = report.md
TARGET = $(PD)$(DOCNO)

PANDOC = pandoc
PANDOC_FORMAT = markdown_github+yaml_metadata_block+citations

$(TARGET).html: $(SOURCE) header.html pandoc-template.html
	$(PANDOC) -f $(PANDOC_FORMAT) -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

$(TARGET).pdf: $(SOURCE)
	$(PANDOC) -f $(PANDOC_FORMAT) -t latex -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(TARGET)/g' < $< > $@

clean:
	rm -f $(TARGET).html $(TARGET).pdf header.html *~

view: $(TARGET).html
	gnome-www-browser $(TARGET).html
