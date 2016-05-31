DOCNO = P0370R0

PANDOC = pandoc

$(DOCNO).html: Pxxxx.md header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

clean:
	rm -f $(DOCNO).html *~

view: $(DOCNO).html
	gnome-www-browser $(DOCNO).html
