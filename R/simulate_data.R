# simulate_data.R -------------------------------------------------------------
# Rebuilds every dataset in data/ from documented data-generating processes.
# Run from the repository root:   source("R/simulate_data.R")
#
# Seeds were chosen so each dataset illustrates its teaching point cleanly
# (as is common for classroom examples). Change a seed and rerun to see how
# much any single study bounces around -- that variability is part of the lesson.

source("R/helpers.R")
suppressPackageStartupMessages(library(BayesFactor))
dir.create("data", showWarnings = FALSE)

# ---- Study 1: the randomized story study (n = 15, 50, 150 per group) ---------
# These three files were generated on 2026-09-15 from the same process as
# simulate_study() (true delta = 0.30, SD = 1.2, punished mean 4.24, ratings
# rounded to the 1-7 scale). They are kept verbatim so the numbers match the
# class notes and the JASP walkthrough; the check below guards that.
ref <- list(story_n15  = c(diff = 0.667, p = 0.180),
            story_n50  = c(diff = 0.420, p = 0.054),
            story_n150 = c(diff = 0.467, p = 0.0004))
for (f in names(ref)) {
  s <- two_group(read.csv(file.path("data", paste0(f, ".csv"))))
  stopifnot(abs(s$diff - ref[[f]]["diff"]) < 0.001,
            abs(s$p - ref[[f]]["p"]) < 0.001)
}

# ---- Study 2: the boundary-condition study (a morally neutral character) -------
# Same endings, but the character does something morally neutral instead of a
# good deed. ADT says viewers then form no disposition toward the character, so
# the ending should not change enjoyment. True delta = 0.
neutral <- simulate_study(200, delta = 0, seed = 100)
neutral$action <- "neutral"
write.csv(neutral, "data/story_neutral_n200.csv", row.names = FALSE)

# ---- Study 3: five more labs run the Study 1 protocol -------------------------
# Lab 1 is the n = 50 Study 1 dataset; labs 2-6 are new draws with the same
# true effect (delta = 0.30) and different sample sizes.
lab_n <- c(40, 60, 30, 80, 45)
labs <- do.call(rbind, c(
  list(cbind(lab = 1, n_per_group = 50, read.csv("data/story_n50.csv"))),
  lapply(seq_along(lab_n), function(i)
    cbind(lab = i + 1, n_per_group = lab_n[i],
          simulate_study(lab_n[i], delta = 0.30, seed = 3100 + i)))
))
write.csv(labs, "data/story_labs.csv", row.names = FALSE)

# ---- Study 4: an observational version (people choose their story) -------------
# A streaming platform shows each viewer a menu; viewers pick the version of the
# episode where the good deed is rewarded or punished. Data-generating process
# (the "true DAG"):
#   just_world    -> chose_rewarded   (people who like just outcomes pick them)
#   just_world    -> enjoyment        (and enjoy stories more regardless)
#   chose_rewarded -> satisfaction -> enjoyment   (a mediated path)
#   chose_rewarded -> enjoyment       (a direct path)
# True total causal effect of the rewarded episode = 0.16 + 0.8 * 0.25 = 0.36
# scale points (delta ~ 0.30, the same as the experiment). Direct effect = 0.16.
simulate_observational <- function(n = 600, seed = 2026) {
  set.seed(seed)
  just_world     <- rnorm(n)                                   # standardized trait
  chose_rewarded <- rbinom(n, 1, plogis(1.5 * just_world))     # self-selection
  satisfaction   <- 0.8 * chose_rewarded + 0.3 * just_world + rnorm(n)
  latent <- 4.24 + 0.16 * chose_rewarded + 0.25 * satisfaction +
            0.45 * just_world + rnorm(n, 0, 0.95)
  data.frame(id = seq_len(n),
             just_world = round(just_world, 2),
             chose_rewarded = chose_rewarded,
             satisfaction = round(satisfaction, 2),
             enjoyment = pmin(7, pmax(1, round(latent))))
}
write.csv(simulate_observational(), "data/story_observational.csv", row.names = FALSE)

# ---- Scene 6: what happens when you peek? --------------------------------------
# 2,000 studies per scenario. Each adds 10 participants per group at a time,
# up to 100 per group, and computes p and the default Bayes factor at every look.
# Takes about a minute; the summary is saved so demo.qmd renders quickly.
simulate_peeking <- function(delta, n_sims = 2000, looks = seq(10, 100, 10), seed = 903) {
  set.seed(seed)
  res <- array(NA, dim = c(n_sims, length(looks), 2),
               dimnames = list(NULL, looks, c("p", "bf10")))
  for (i in seq_len(n_sims)) {
    d <- simulate_study(max(looks), delta = delta)
    r <- d$enjoyment[d$condition == "rewarded"]; u <- d$enjoyment[d$condition == "punished"]
    for (k in seq_along(looks)) {
      n <- looks[k]
      s <- two_group(data.frame(enjoyment = c(r[1:n], u[1:n]),
                                condition = rep(c("rewarded", "punished"), each = n)))
      res[i, k, "p"] <- s$p
      res[i, k, "bf10"] <- exp(ttest.tstat(s$t, n, n, rscale = sqrt(2) / 2)$bf)
    }
  }
  # "Stopped by look k?" = the criterion was met at look k or any earlier look
  first_hit <- function(hit) t(apply(hit, 1, cummax))
  # Sequential Bayes factor design with two boundaries (Schoenbrodt et al., 2017):
  # stop at BF10 > 3 (claim an effect) or BF01 > 3 (claim no effect), whichever comes first.
  first_look <- function(hit) apply(hit, 1, function(h) if (any(h)) which(h)[1] else Inf)
  k_h1 <- first_look(res[, , "bf10"] > 3)
  k_h0 <- first_look(res[, , "bf10"] < 1 / 3)
  kk <- seq_along(looks)
  data.frame(
    true_delta = delta,
    n_per_group = looks,
    fixed_p05       = colMeans(res[, , "p"] < .05),        # one look at this n
    fixed_bf10_gt3  = colMeans(res[, , "bf10"] > 3),
    fixed_bf01_gt3  = colMeans(res[, , "bf10"] < 1 / 3),
    peek_p05        = colMeans(first_hit(res[, , "p"] < .05)),   # stop only if p < .05
    peek_bf10_gt3   = colMeans(first_hit(res[, , "bf10"] > 3)), # stop only if BF10 > 3
    sbf_end_h1      = sapply(kk, function(k) mean(k_h1 <= k & k_h1 < k_h0)),
    sbf_end_h0      = sapply(kk, function(k) mean(k_h0 <= k & k_h0 < k_h1))
  )
}
peeking <- rbind(simulate_peeking(delta = 0), simulate_peeking(delta = 0.30))
write.csv(peeking, "data/sim_peeking_summary.csv", row.names = FALSE)

message("All datasets written to data/.")
