pandoc -f markdown_github -t html -o appendices.html --number-sections -s -S appendices.md 
pandoc -f markdown_github+yaml_metadata_block+citations -t html -o P0022R1.html --filter pandoc-citeproc --csl=acm-sig-proceedings.csl --number-sections --toc -s -S --template=pandoc-template --include-before-body=header.html --include-after-body=appendices.html --include-in-header=pandoc.css Dxxxx.md 
