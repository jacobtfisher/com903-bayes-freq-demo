# helpers.R -------------------------------------------------------------------
# Small, transparent functions used by demo.qmd. Everything here is base R +
# ggplot2 so you can read exactly what each calculation does. The only
# "black box" we lean on is BayesFactor::ttestBF(), and Scene 2 checks our own
# Bayes factor function against it.

suppressPackageStartupMessages({
  library(ggplot2)
})

# ---- Colors and plot theme ----------------------------------------------------
# Three categorical colors (validated for color-vision deficiency as a set) plus
# a neutral gray for "prior / null / reference" marks. Every series is also
# labeled directly on the plot, so no meaning rides on color alone.
pal <- c(
  blue   = "#2a78d6",
  orange = "#eb6834",
  aqua   = "#1baf7a",
  gray   = "#898781",
  ink    = "#0b0b0b",
  ink2   = "#52514e",
  grid   = "#e1e0d9"
)

theme_demo <- function(base_size = 15) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background  = element_rect(fill = "#fcfcfb", color = NA),
      panel.grid.major = element_line(color = pal[["grid"]], linewidth = 0.3),
      panel.grid.minor = element_blank(),
      axis.text        = element_text(color = pal[["ink2"]]),
      axis.title       = element_text(color = pal[["ink2"]]),
      plot.title       = element_text(color = pal[["ink"]], face = "bold"),
      plot.subtitle    = element_text(color = pal[["ink2"]]),
      plot.caption     = element_text(color = pal[["gray"]], hjust = 0),
      legend.position  = "none",
      strip.text       = element_text(face = "bold", color = pal[["ink"]])
    )
}

fmt_p <- function(p) {
  ifelse(p < .001, "< .001", sub("^0", "", sprintf("%.3f", p)))
}
fmt_bf <- function(bf) {
  ifelse(bf >= 1000 | bf < 0.001, formatC(bf, format = "e", digits = 1),
         ifelse(bf >= 10, sprintf("%.0f", bf), sprintf("%.2f", bf)))
}

# ---- Data summaries -----------------------------------------------------------
# Two-group summary for the story data. Group 1 = rewarded, group 2 = punished,
# so a positive difference means "rewarded ending enjoyed more".
two_group <- function(d, y = "enjoyment", g = "condition",
                      g1 = "rewarded", g2 = "punished") {
  y1 <- d[[y]][d[[g]] == g1]; y2 <- d[[y]][d[[g]] == g2]
  n1 <- length(y1); n2 <- length(y2); df <- n1 + n2 - 2
  sp <- sqrt(((n1 - 1) * var(y1) + (n2 - 1) * var(y2)) / df)   # pooled SD
  se <- sp * sqrt(1 / n1 + 1 / n2)                               # SE of the difference
  diff <- mean(y1) - mean(y2)
  t <- diff / se
  list(n1 = n1, n2 = n2, df = df, m1 = mean(y1), m2 = mean(y2), sp = sp,
       diff = diff, se = se, t = t, d = diff / sp,
       neff = n1 * n2 / (n1 + n2),                               # "effective n" for delta
       p = 2 * pt(-abs(t), df),
       ci = diff + c(-1, 1) * qt(.975, df) * se)
}

# ---- Default Bayes factor (JASP's Bayesian t-test) ---------------------------
# x = rewarded, y = punished, so positive effects mean "rewarded ending enjoyed more".
# (The formula interface of ttestBF orders groups alphabetically, which would
# flip the sign; it does not matter for the symmetric default prior, but it
# does for directional priors, so we pass the groups explicitly.)
bf_default <- function(d, rscale = "medium") {
  BayesFactor::ttestBF(x = d$enjoyment[d$condition == "rewarded"],
                       y = d$enjoyment[d$condition == "punished"], rscale = rscale)
}

# ---- Frequentist: the p-value function (a.k.a. compatibility curve) -----------
# For every hypothesized difference mu0, the two-sided p-value of the data
# against mu0. The 95% CI is exactly the set of mu0 values with p > .05
# (Greenland et al., 2016, p. 340).
p_function <- function(s, mu0) 2 * pt(-abs((s$diff - mu0) / s$se), s$df)

# ---- Bayesian estimation on the raw scale (grid approximation) ----------------
# Likelihood of a true difference mu given the data. With the usual
# noninformative prior on the SD, the data enter only through a t density
# centered on the observed difference. Grid approximation: evaluate
# prior x likelihood at many candidate values and normalize.
lik_diff <- function(s, mu) dt((s$diff - mu) / s$se, s$df) / s$se

grid_posterior <- function(grid, prior_dens, lik) {
  step <- diff(grid[1:2])
  post <- prior_dens * lik
  post <- post / sum(post * step)
  prior_n <- prior_dens / sum(prior_dens * step)
  lik_n <- lik / sum(lik * step)
  data.frame(x = grid, prior = prior_n, likelihood = lik_n, posterior = post)
}

post_summary <- function(grid, dens, rope = NULL) {
  step <- diff(grid[1:2])
  cdf <- cumsum(dens * step)
  q <- function(pr) grid[which.min(abs(cdf - pr))]
  out <- c(mean = sum(grid * dens * step),
           lo95 = q(.025), hi95 = q(.975),
           p_pos = sum(dens[grid > 0] * step))
  if (!is.null(rope)) {
    out["p_rope"] <- sum(dens[grid > rope[1] & grid < rope[2]] * step)
  }
  out
}

# ---- Bayes factors as a prediction contest ------------------------------------
# A hypothesis about the standardized effect delta predicts a distribution of
# t statistics: for each delta, t follows a noncentral t with
# ncp = delta * sqrt(n_eff); average those over the prior on delta.
# BF between two hypotheses = ratio of how well each predicted the observed t
# (Rouder et al., 2009; Gronau, Ly, & Wagenmakers, 2020).
#   prior: a density function of delta, or the string "null" for delta = 0.
# Integration runs over |delta| <= 4, where all of the likelihood mass lies for
# these datasets (checked against BayesFactor to ~1e-10). With tiny n or huge
# |t|, widen the limits and check again; R's noncentral t is also less exact
# for very large noncentrality parameters.
pred_t <- function(t, s, prior, lower = -4, upper = 4) {
  if (identical(prior, "null")) return(dt(t, s$df))
  sapply(t, function(tt) {
    suppressWarnings(integrate(
      function(dl) dt(tt, s$df, ncp = dl * sqrt(s$neff)) * prior(dl),
      lower, upper, rel.tol = 1e-8, subdivisions = 500L)$value)
  })
}

bf_vs_null <- function(s, prior) pred_t(s$t, s, prior) / pred_t(s$t, s, "null")

# Posterior for delta under any prior (grid; likelihood = noncentral t density)
delta_posterior <- function(s, prior, grid = seq(-1.5, 1.5, by = 0.001)) {
  lik <- suppressWarnings(dt(s$t, s$df, ncp = grid * sqrt(s$neff)))
  grid_posterior(grid, prior(grid), lik)
}

# Priors on delta used to encode the stylized theories in Scene 2
prior_default <- function(x) dcauchy(x, 0, sqrt(2) / 2)   # JASP default r = 0.707
prior_adt     <- function(x) dnorm(x,  0.30, 0.15)         # ADT: "rewarded > punished, small"
prior_tragedy <- function(x) dnorm(x, -0.30, 0.15)         # tragedy: "punished > rewarded, small"

# ---- Equivalence test (TOST) --------------------------------------------------
# Two one-sided tests against the smallest effect size of interest (+/- bound).
tost <- function(s, bound) {
  p_lower <- pt((s$diff + bound) / s$se, s$df, lower.tail = FALSE)  # H0: diff <= -bound
  p_upper <- pt((s$diff - bound) / s$se, s$df, lower.tail = TRUE)   # H0: diff >= +bound
  list(p_lower = p_lower, p_upper = p_upper, p_tost = max(p_lower, p_upper),
       ci90 = s$diff + c(-1, 1) * qt(.95, s$df) * s$se)
}

# ---- Normal-normal updating (for accumulating studies) ------------------------
# Treat each study's estimate as normal with its SE; combine with a normal prior.
update_normal <- function(prior_mean, prior_sd, est, se) {
  w0 <- 1 / prior_sd^2; w1 <- 1 / se^2
  c(mean = (w0 * prior_mean + w1 * est) / (w0 + w1), sd = sqrt(1 / (w0 + w1)))
}

# ---- Simulating the story study -------------------------------------------------
# One randomized two-group study: story enjoyment on a 1-7 scale.
# delta = true standardized effect (rewarded - punished); ratings are rounded
# and kept inside the scale, like real Likert-type responses.
simulate_study <- function(n_per_group, delta = 0.30, sd = 1.2,
                          mean_punished = 4.24, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  rewarded <- rnorm(n_per_group, mean_punished + delta * sd, sd)
  punished <- rnorm(n_per_group, mean_punished, sd)
  to_scale <- function(x) pmin(7, pmax(1, round(x)))
  data.frame(
    id = seq_len(2 * n_per_group),
    condition = rep(c("rewarded", "punished"), each = n_per_group),
    enjoyment = to_scale(c(rewarded, punished))
  )
}
