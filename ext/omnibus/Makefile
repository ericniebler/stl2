# Update in header.html as well.
DOCNO = D0370R1A

PANDOC = pandoc

$(DOCNO).html: Pxxxx.md header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

header.html: header.html.in Makefile
	sed 's/%%DOCNO%%/$(DOCNO)/g' < $< > $@

clean:
	rm -f $(DOCNO).html *~

view: $(DOCNO).html
	gnome-www-browser $(DOCNO).html
