# Update in header.html as well.
DOCNO = P0370
REV = 1

PANDOC = pandoc

$(DOCNO)R$(REV).html: P0370.md header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

$(DOCNO)R$(REV).pdf: P0370.md
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t latex -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(DOCNO)R$(REV)/g' < $< > $@

clean:
	rm -f $(DOCNO)R$(REV).html *~

view: $(DOCNO)R$(REV).html
	gnome-www-browser $(DOCNO)R$(REV).html
