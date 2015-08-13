pandoc -f markdown_github -t html -o appendices.html --number-sections -s -S appendices.md 
pandoc -f markdown_github+yaml_metadata_block+citations -t html -o D0022.html --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html --include-after-body=appendices.html Dxxxx.md 
