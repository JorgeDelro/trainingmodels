# Design decisions

Each entry: id, date, status (approved / proposed / pending), decision,
reason. Approved entries are decided by the author.

## Approved

- D-001 (2026-11-20) Package name `trainingmodels`. Checked with
  pak::pkg_name_check: valid, free on CRAN and Bioconductor.
- D-002 (2026-11-18) First version scope: daily-series core, load
  descriptors, Banister impulse-response model. Later: Busso variable
  dose-response, fitness delay, Kalman filter, Bayesian version, DLNM
  via the dlnm package (wrapped, not reimplemented).
- D-003 (2026-11-18) Every formula is verified against its source before
  implementation; the verification source is recorded per method.
- D-004 (2026-11-18) Every method is documented with its limitations
  (identifiability, wide intervals, assumptions), not only its
  computation.
- D-005 (2026-11-18) Public repository from day one; issues, pull
  requests and releases; AI use disclosed (see AI_USAGE.md).
- D-006 (2026-11-18) pkgdown site from the start, one article per
  method.
- D-007 (2026-11-18) Numerical tests against published examples and
  against an independent reference implementation.
- D-008 (2026-11-18) Code, documentation and commits in English.
- D-009 (2026-11-19) All package code is written from the verified
  formulas; third-party code is used only as an external reference for
  tests, never copied.
- D-010 (2026-11-20) The `bib/` folder (copyrighted papers) is never
  committed.
- D-011 (2026-11-24) Impulse-response functions implement both timing
  conventions found in the literature, selected with the argument
  `same_day_load`: “exclude” (sum to n-1; Busso & Chalencon 2023) and
  “include” (Morton et al. 1990, Eqs. 4-5). Reason: the two forms are
  not equivalent and both are in use; see MODELS.md, M-01.
- D-012 (2026-11-24) The default is `same_day_load = "exclude"`. Every
  fitted object stores and prints its convention, because gains fitted
  under one convention are not comparable with the other.
- D-013 (2026-11-24) MODELS.md is the model registry and single source
  of truth for formulas, verification sources, reference values and
  literature discrepancies. Its first version (entries M-01 to M-09) was
  approved by the author on 2026-11-24.
- D-014 (2026-11-25) The package and the app ship pre-built example
  datasets modelled on published studies; they are simulated and
  labelled as simulated. All impulse-response models share one data
  format (daily load plus performance on some days). The app explains
  the format and the variables to collect for users who upload their own
  data.
- D-015 (2026-11-25) Every day has one of three states: training (load
  \> 0), rest (load = 0), missing (load not available). Days with no row
  between an athlete’s first and last date are treated as rest by
  default, with a message listing how many were filled, and a warning
  when more than 7 consecutive days are filled. The user can request
  that such days be treated as missing instead.
- D-016 (2026-11-25) Missing loads are never silently replaced.
  Descriptors return NA for windows containing a missing day.
  Impulse-response models refuse to run on series with missing loads
  unless the user explicitly chooses how to fill them; in the first
  version the only option is zero.
- D-017 (2026-11-25) A data file may contain several athletes (optional
  identifier column) and several load columns; each analysis uses one
  load column chosen by the user.
- D-018 (2026-11-26) A second model family, training load -\> injury,
  enters the package from version 0.3: distributed lag non-linear models
  (wrapping dlnm), the piece-wise exponential additive mixed model with
  cumulative effects of Zumeta-Olaskoaga et al. 2025 (wrapping pammtools
  and mgcv), and tools to evaluate predictions (discrimination,
  calibration). Neural-network and structural-equation approaches are
  not implemented.
- D-019 (2026-11-26) Everything related to the acute:chronic workload
  ratio (ratios, EWMA-based loads, FWF matrices of Matas-Bustos et
  al. 2025) lives only in the author’s ACWR package. trainingmodels does
  not reimplement it; the documentation refers to ACWR.
- D-020 (2026-11-26) Window-based descriptors offer both timing options
  through `same_day_load` (“include”: the window ends on the current
  day; “exclude”: it ends on the previous day, as in Carey et al. 2017,
  Eq. 1).
- D-021 (2026-11-26) The default for descriptors is
  `same_day_load = "include"`. This differs from the impulse-response
  default (D-012) and must be stated in the help of every descriptor.
- D-022 (2026-11-26) Monotony and strain: rolling 7-day window computed
  every day; rest days count as load 0; when all loads in the window are
  equal the standard deviation is 0 and monotony and strain are NA.
- D-023 (2026-11-27) The fitness-only model (MODELS.md, M-03) is
  included, as an option of the same simulation function as the
  two-component model. Closes P-007.
- D-024 (2026-11-27) Half-life (tau x ln 2) is shown in printed output
  next to each time constant. Function arguments are always time
  constants, never half-lives. Closes P-010.
- D-025 (2026-11-27) Initial fitness and fatigue are 0 by default and
  can be set by the user in simulation. Fitting (0.1.0) will keep them
  fixed at 0 in its first version, documented as a limitation. Closes
  P-013.
- D-026 (2026-11-27) Characteristic times are named in words:
  `time_to_recover` and `time_to_peak` (single session, M-05),
  `time_of_minimum` (constant daily training, M-04). They are NA, with
  the reason stated in the help, when they do not exist. No function or
  argument is named `t_n`. Closes the naming question of MODELS.md,
  M-05.

## Proposed (architecture, awaiting author approval)

- A-001 One daily-series class as the single entry point: validates
  input, sums same-day sessions, marks each day as observed, rest or
  missing.
- A-002 Daily-calendar core adapted from the author’s ACWR 0.2.0 package
  (copied, not imported). ACWR may later become a wrapper.
- A-003 Shiny app in the same repository, shiny in Suggests.
- A-004 One exponential-filter engine for all impulse-response models
  (fitness-only, Banister, fitness delay), computed in recursive form.
- A-005 Two-level fit: linear regression for baseline and gains,
  numerical search only over time constants (Busso & Chalencon 2023).
- A-006 Model comparison with AICc and Akaike weights.
- A-007 Reference values for tests generated outside the package from
  the R script of Busso & Chalencon (2023, Supplemental Digital
  Content 2) and from the dorem package; neither is a dependency.
- A-008 dlnm and REDI as Suggests, from version 0.3.
- A-010 The core has no dependencies beyond base R, so that it can run
  in the browser (Shinylive).
- A-011 Every function that takes a daily_load validates it first with
  one internal validator, and returns a plain data frame with one row
  per row of the input, in the same order (athlete, date, load, then
  results).
- A-012 Simulations return a data frame subclass with a print method
  whose header shows the model, the timing convention (D-012), the
  parameters and the half-lives. This is the one exception to “plain
  data frame” in A-011.

## Pending (product and domain, author to decide)

- P-001 Which outcome students will have for Banister (repeated
  performance tests or not); whether Banister in the app is simulation
  plus example data.
- P-002 Closed 2026-11-25: resolved by D-015 to D-017.
- P-003 How students access the app (local R or hosted URL).
- P-004 Language of the theory documentation and of the app interface.
- P-005 Planned research use in the next six months (JOSS vs JOSE).
- P-006 Closed 2026-11-24: Morton et al. (1990) was read and uses a
  different timing convention; resolved by D-011 and D-012.
- P-007 Closed 2026-11-27: resolved by D-023.
- P-008 Every fit reports trivial comparators (mean, straight line).
- P-009 Fit output foregrounds the response to a single session (curve,
  t_n, t_g) over individual parameters.
- P-010 Closed 2026-11-27: resolved by D-024.
- P-011 User declares whether higher or lower performance values are
  better.
- P-012 App shows the link between EWMA and Banister without gains.
- P-013 Closed 2026-11-27: resolved by D-025.
- P-014 Ask T. Busso for the swimmers’ dataset.
