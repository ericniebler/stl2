DOCNO = 0547R1
PD = P
SOURCE = constructible.md
TARGET = $(PD)$(DOCNO)

PANDOC = pandoc

$(TARGET).html: $(SOURCE) header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block -t html -o $@ --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html --include-in-header=pandoc.css $<

$(TARGET).pdf: $(SOURCE)
	$(PANDOC) -f markdown_github+yaml_metadata_block -t latex -o $@ --number-sections --toc -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(TARGET)/g' < $< > $@

clean:
	rm -f $(TARGET).html *~

view: $(TARGET).html
	gnome-www-browser $(TARGET).html
