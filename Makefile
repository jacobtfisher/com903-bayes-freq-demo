# Shortcuts for working on the demo. Run from the repo root.
#   make preview   live-reloading preview of the site in your browser (re-renders the page you save)
#   make render    rebuild every page of the site into docs/
#   make check     fast check of the headline numbers (~5 s)
#   make data      rebuild data/ from R/simulate_data.R (~2 min; Study 1 files are kept verbatim)
#   make install   install the R packages

.PHONY: preview render check data install

preview:
	LC_ALL=en_US.UTF-8 quarto preview

render:
	LC_ALL=en_US.UTF-8 quarto render

check:
	Rscript R/check_numbers.R

data:
	Rscript R/simulate_data.R

install:
	Rscript -e 'source("install.R")'
