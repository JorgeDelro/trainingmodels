# Design decisions

Each entry: id, date, status (approved / proposed / pending), decision,
reason. Approved entries are decided by the author.

## Approved
- D-001 (2026-11-20) Package name `trainingmodels`. Checked with
  pak::pkg_name_check: valid, free on CRAN and Bioconductor.
- D-002 (2026-11-18) First version scope: daily-series core, load
  descriptors, Banister impulse-response model. Later: Busso variable
  dose-response, fitness delay, Kalman filter, Bayesian version, DLNM via
  the dlnm package (wrapped, not reimplemented).
- D-003 (2026-11-18) Every formula is verified against its source before
  implementation; the verification source is recorded per method.
- D-004 (2026-11-18) Every method is documented with its limitations
  (identifiability, wide intervals, assumptions), not only its computation.
- D-005 (2026-11-18) Public repository from day one; issues, pull requests
  and releases; AI use disclosed (see AI_USAGE.md).
- D-006 (2026-11-18) pkgdown site from the start, one article per method.
- D-007 (2026-11-18) Numerical tests against published examples and against
  an independent reference implementation.
- D-008 (2026-11-18) Code, documentation and commits in English.
- D-009 (2026-11-19) All package code is written from the verified formulas;
  third-party code is used only as an external reference for tests, never
  copied.
- D-010 (2026-11-20) The `bib/` folder (copyrighted papers) is never
  committed.
- D-011 (2026-11-24) Impulse-response functions implement both timing
  conventions found in the literature, selected with the argument
  `same_day_load`: "exclude" (sum to n-1; Busso & Chalencon 2023) and
  "include" (Morton et al. 1990, Eqs. 4-5). Reason: the two forms are not
  equivalent and both are in use; see MODELS.md, M-01.
- D-012 (2026-11-24) The default is `same_day_load = "exclude"`. Every
  fitted object stores and prints its convention, because gains fitted under
  one convention are not comparable with the other.
- D-013 (2026-11-24) MODELS.md is the model registry and single source of
  truth for formulas, verification sources, reference values and literature
  discrepancies. Its first version (entries M-01 to M-09) was approved by the
  author on 2026-11-24.

## Proposed (architecture, awaiting author approval)
- A-001 One daily-series class as the single entry point: validates input,
  sums same-day sessions, marks each day as observed, rest or missing.
- A-002 Daily-calendar core adapted from the author's ACWR 0.2.0 package
  (copied, not imported). ACWR may later become a wrapper.
- A-003 Shiny app in the same repository, shiny in Suggests.
- A-004 One exponential-filter engine for all impulse-response models
  (fitness-only, Banister, fitness delay), computed in recursive form.
- A-005 Two-level fit: linear regression for baseline and gains, numerical
  search only over time constants (Busso & Chalencon 2023).
- A-006 Model comparison with AICc and Akaike weights.
- A-007 Reference values for tests generated outside the package from the
  R script of Busso & Chalencon (2023, Supplemental Digital Content 2) and
  from the dorem package; neither is a dependency.
- A-008 dlnm and REDI as Suggests, from version 0.3.
- A-009 All impulse-response models share one data format (daily load plus
  performance on some days). Example datasets imitate published designs,
  are simulated, and are labelled as simulated; a data-collection template
  ships with the package.

## Pending (product and domain, author to decide)
- P-001 Which outcome students will have for Banister (repeated performance
  tests or not); whether Banister in the app is simulation plus example data.
- P-002 What students record per session and how rest days are told apart
  from missing days.
- P-003 How students access the app (local R or hosted URL).
- P-004 Language of the theory documentation and of the app interface.
- P-005 Planned research use in the next six months (JOSS vs JOSE).
- P-006 Closed 2026-11-24: Morton et al. (1990) was read and uses a
  different timing convention; resolved by D-011 and D-012.
- P-007 Include the fitness-only model in the first version.
- P-008 Every fit reports trivial comparators (mean, straight line).
- P-009 Fit output foregrounds the response to a single session (curve,
  t_n, t_g) over individual parameters.
- P-010 Show half-life alongside time constants.
- P-011 User declares whether higher or lower performance values are better.
- P-012 App shows the link between EWMA and Banister without gains.
- P-013 First version assumes zero initial fitness and fatigue, documented
  as a limitation.
- P-014 Ask T. Busso for the swimmers' dataset.
