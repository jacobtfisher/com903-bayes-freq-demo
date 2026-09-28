# install.R -------------------------------------------------------------------
# Run once:  source("install.R")
# Installs the few CRAN packages the demo needs. No Stan or C++ toolchain is
# required: every Bayesian calculation is done with grid approximation,
# closed-form updating, or the BayesFactor package (the engine behind JASP's
# Bayesian t-test).

pkgs <- c("BayesFactor", "ggplot2", "patchwork", "scales", "knitr", "rmarkdown")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Quick check
invisible(lapply(pkgs, library, character.only = TRUE))
message("All set. Open demo.qmd and run the chunks in order, or click Render.")
