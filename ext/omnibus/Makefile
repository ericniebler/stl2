PANDOC = $(HOME)/.cabal/bin/pandoc

Pxxxx.html: Pxxxx.md header.html pandoc-template.html
	$(PANDOC) -f markdown_github+yaml_metadata_block+citations -t html -o $@ --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html $<

clean:
	rm -f Pxxxx.html *~

view: Pxxxx.html
	gnome-www-browser Pxxxx.html
