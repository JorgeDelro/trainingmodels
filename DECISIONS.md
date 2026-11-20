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

## Pending (product and domain, author to decide)

- P-001 Which outcome students will have for Banister (repeated
  performance tests or not); whether Banister in the app is simulation
  plus example data.
- P-002 What students record per session and how rest days are told
  apart from missing days.
- P-003 How students access the app (local R or hosted URL).
- P-004 Language of the theory documentation and of the app interface.
- P-005 Planned research use in the next six months (JOSS vs JOSE).
- P-006 Accept Busso & Chalencon (2023) as verification source for the
  Banister formula (sum to n-1), with Morton et al. (1990) only as
  citation check.
- P-007 Include the fitness-only model in the first version.
- P-008 Every fit reports trivial comparators (mean, straight line).
- P-009 Fit output foregrounds the response to a single session (curve,
  t_n, t_g) over individual parameters.
- P-010 Show half-life alongside time constants.
- P-011 User declares whether higher or lower performance values are
  better.
- P-012 App shows the link between EWMA and Banister without gains.
- P-013 First version assumes zero initial fitness and fatigue,
  documented as a limitation.
- P-014 Ask T. Busso for the swimmers’ dataset.
