# check_numbers.R -------------------------------------------------------------
# Fast regression check (about 10 seconds). Run from the repo root:
#   Rscript R/check_numbers.R
# Recomputes the headline numbers the notebook's prose and the course notes rely
# on, and compares them with reference values. Exits with an error if any drift.
# If a number changes on purpose, update the reference here AND grep demo.qmd
# for hard-coded copies of it (e.g., the Scene 1 "What each framework lets you
# say" box quotes 0.42 [-0.01, 0.85], p = .054, BF10 = 1.12).

source("R/helpers.R")
suppressPackageStartupMessages(library(BayesFactor))

s15  <- two_group(read.csv("data/story_n15.csv"))
d50  <- read.csv("data/story_n50.csv");  s50  <- two_group(d50)
d150 <- read.csv("data/story_n150.csv"); s150 <- two_group(d150)
neutral <- read.csv("data/story_neutral_n200.csv")
interim <- rbind(head(neutral[neutral$condition == "rewarded", ], 40), head(neutral[neutral$condition == "punished", ], 40))
si <- two_group(interim); sf <- two_group(neutral)
labs <- read.csv("data/story_labs.csv")
ls <- do.call(rbind, lapply(split(labs, labs$lab), function(d) { s <- two_group(d); c(diff = s$diff, se = s$se) }))
w <- 1 / ls[, "se"]^2; fe <- sum(w * ls[, "diff"]) / sum(w); fe_se <- sqrt(1 / sum(w))
obs <- read.csv("data/story_observational.csv")
b <- function(f) coef(lm(f, data = obs))[["chose_rewarded"]]
peek <- read.csv("data/sim_peeking_summary.csv")
h0 <- peek[peek$true_delta == 0 & peek$n_per_group == 100, ]
h1 <- peek[peek$true_delta == 0.3 & peek$n_per_group == 50, ]

checks <- rbind(
  c("S1 n=15 p",                    s15$p,                                   0.1799, 0.001),
  c("S1 n=50 diff",                 s50$diff,                                0.420,  0.0005),
  c("S1 n=50 CI low",               s50$ci[1],                              -0.0075, 0.0005),
  c("S1 n=50 CI high",              s50$ci[2],                               0.8475, 0.0005),
  c("S1 n=50 p",                    s50$p,                                   0.0541, 0.0005),
  c("S1 n=50 BF10 default",         extractBF(bf_default(d50))$bf,           1.124,  0.005),
  c("S1 n=150 diff",                s150$diff,                               0.467,  0.0005),
  c("S1 n=150 BF10 default",        extractBF(bf_default(d150))$bf,          59.18,  0.05),
  c("S2 n=50 BF ADT",               bf_vs_null(s50, prior_adt),              4.899,  0.005),
  c("S2 n=50 BF tragedy",           bf_vs_null(s50, prior_tragedy),          0.1203, 0.0005),
  c("S2 n=150 BF ADT",              bf_vs_null(s150, prior_adt),             307.31, 0.1),
  c("S2 custom BF = BayesFactor",   bf_vs_null(s50, prior_default) - extractBF(bf_default(d50))$bf, 0, 1e-6),
  c("S3 interim TOST p",            tost(si, 0.3)$p_tost,                    0.415,  0.001),
  c("S3 full TOST p",               tost(sf, 0.3)$p_tost,                    0.011,  0.001),
  c("S3 full BF01 vs default",      1 / bf_vs_null(sf, prior_default),       8.754,  0.01),
  c("S3 full BF01 vs happy ending", 1 / bf_vs_null(sf, prior_adt),           5.6,    0.1),
  c("S4 fixed-effect estimate",     fe,                                      0.382,  0.001),
  c("S4 fixed-effect CI low",       fe - 1.96 * fe_se,                       0.193,  0.001),
  c("S5 naive estimate",            b(enjoyment ~ chose_rewarded),           0.893,  0.001),
  c("S5 adjusted estimate",         b(enjoyment ~ chose_rewarded + just_world), 0.345, 0.001),
  c("S5 mediator-adjusted",         b(enjoyment ~ chose_rewarded + just_world + satisfaction), 0.133, 0.001),
  c("S6 H0 peeking p<.05 @100",     h0$peek_p05,                             0.1995, 1e-4),
  c("S6 H0 peeking BF10>3 @100",    h0$peek_bf10_gt3,                        0.075,  1e-4),
  c("S6 d=.3 BF01>3 @50 one look",  h1$fixed_bf01_gt3,                       0.318,  1e-4)
)
res <- data.frame(check = checks[, 1],
                  got = as.numeric(checks[, 2]), expected = as.numeric(checks[, 3]),
                  tol = as.numeric(checks[, 4]))
res$ok <- abs(res$got - res$expected) <= res$tol
res$got <- round(res$got, 4)
print(res[, c("check", "got", "expected", "ok")], row.names = FALSE)
if (!all(res$ok)) stop(sum(!res$ok), " check(s) drifted. See rows with ok = FALSE.")
message("All ", nrow(res), " checks pass.")
