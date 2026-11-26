# Model registry

This file is the single source of truth for every model and formula in
`trainingmodels`. Function documentation, pkgdown articles, the Shiny app texts
and the software paper are derived from it and must not contradict it.

**Rules**

1. A formula is implemented only after its entry here reaches status
   `verified` and the author has approved it (decision D-003).
2. Every entry states which source the formula was checked against and how.
   A secondary source alone is never enough for `verified`.
3. Disagreements found between sources are recorded in the
   [discrepancy log](#discrepancy-log), not silently resolved.
4. Reference values listed here are the numerical targets for unit tests.

**Status vocabulary**

| Status | Meaning |
|---|---|
| `verified` | Formula checked against the source named in the entry; reference values reproduced independently |
| `partly verified` | Checked against an author's code or a peer-reviewed secondary source; the original article has not been read |
| `unverified` | Known only from secondary sources that have not been cross-checked |
| `planned` / `implemented` | Development state, independent of verification |

**How verification was done so far.** Sources were read as Markdown conversions
of the PDFs supplied by the package author, not from the PDFs themselves. A
conversion can introduce transcription errors (the Morton 1990 conversion notes
one restored `+` sign in Eq. 7), so equations that matter were additionally
checked by recomputing published numbers. Reviews were drafted with Claude
(Anthropic) in chat; see `AI_USAGE.md`. Author approval of each entry is
recorded in the entry.

---

## Notation

| Symbol | Meaning |
|---|---|
| $t = 1, \dots, n$ | Day index on a complete daily calendar (rest days have load 0) |
| $w(t)$ | Training load of day $t$ (all sessions of the day summed), arbitrary units |
| $p(t)$ | Modelled performance on day $t$ |
| $p_0$ | Baseline performance |
| $k_1, k_2$ | Gains of the positive (fitness) and negative (fatigue) components |
| $\tau_1, \tau_2$ | Time constants of fitness and fatigue, days |
| $g(t), h(t)$ | Fitness and fatigue components |
| half-life | $\tau \ln 2$ |

---

## M-01 Exponential filter and the two timing conventions

**Status:** `verified` (both conventions) · planned for 0.0.3
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

The literature uses two different discrete forms. They are not equivalent and
the package offers both through the argument
`same_day_load = c("exclude", "include")`. The default is `"exclude"`
(decisions D-011 and D-012).

**Convention "include" (Morton, Fitz-Clarke & Banister 1990, Eqs. 4-5).** The
load of day $t$ counts on day $t$ at full weight; values refer to the end of
day $t$.

$$
g_{\mathrm{inc}}(t) = g_{\mathrm{inc}}(t-1)\,e^{-1/\tau} + w(t)
= \sum_{s=1}^{t} w(s)\,e^{-(t-s)/\tau}
$$

**Convention "exclude" (Busso lineage; sum to $t-1$).** The load of day $t$
does not affect day $t$; yesterday's load is already attenuated by
$e^{-1/\tau}$.

$$
g_{\mathrm{exc}}(t) = \sum_{s=1}^{t-1} w(s)\,e^{-(t-s)/\tau},
\qquad
g_{\mathrm{exc}}(t) = \left[g_{\mathrm{exc}}(t-1) + w(t-1)\right] e^{-1/\tau}
$$

**Exact relationship** (derived here and checked numerically):

$$
g_{\mathrm{inc}}(t) = g_{\mathrm{exc}}(t) + w(t),
\qquad
g_{\mathrm{exc}}(t+1) = e^{-1/\tau}\,g_{\mathrm{inc}}(t)
$$

**Consequences**

- Gains $k$ fitted under one convention are not comparable with gains fitted
  under the other. Every fitted object must store and print its convention.
- The difference matters most when a performance test and a training session
  fall on the same day. "exclude" corresponds to a test done before that day's
  training; "include" to a value at the end of the day.
- Morton et al. (1990) state that the criterion performance was usually done at
  the beginning of a training bout, yet their Eqs. 4-5 include that day's load.

**Verification**

| Convention | Checked against | How |
|---|---|---|
| include | Morton et al. 1990, Eqs. 4-9, Figs. 3-4 | Worked example recomputed (see M-02 reference values) |
| include | Clarke & Skiba 2013, supplemental spreadsheet, sheets 6, 8, 9 | Spreadsheet formulas read; modelled performance on the 9 test days of sheet 8 reproduced exactly |
| exclude | Busso & Chalencon 2023, Supplemental Digital Content 2 (R script) | Matrix algebra of the script emulated with random loads; equals the sum to $t-1$ |
| exclude | Vermeire et al. 2022; Imbach et al. 2022 (Eq. 1); Marchal et al. 2025 | Equation as printed |

**Notes**

- Morton's Eqs. 4-5 allow any spacing $i$ between sessions, including several
  sessions per day. The package aggregates to one value per day; this is a
  simplification of Morton's formulation.
- Initial state is $g(0) = h(0) = 0$ unless set by the user. Morton et al.
  assigned an initial fitness of 1,000 units to one subject.

---

## M-02 Two-component impulse-response model (Banister)

**Status:** `verified` · planned for 0.0.3 (simulation) and 0.1.0 (fit)
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

$$
p(t) = p_0 + k_1\,g(t) - k_2\,h(t)
$$

with $g$ and $h$ the filters of M-01 with time constants $\tau_1$ and $\tau_2$.

- Morton et al. (1990, Eq. 8) write $p(t) = k_1 g(t) - k_2 h(t)$ with no
  baseline. Their $p(t)$ is on an arbitrary scale and is related to criterion
  points by least-squares regression, and $k_1$ is 1 for both subjects in
  their Table 2.
- The form with an explicit baseline and five free parameters is the one used
  by Busso & Chalencon (2023), Vermeire et al. (2022), Imbach et al. (2022)
  and Marchal et al. (2025).
- Attribution: the two-component model is commonly cited as Banister et al.
  (1975). That article has not been read. Until it is, cite Calvert et al.
  (1976) and Morton et al. (1990) for the model and treat 1975 as historical
  origin only.

**Reference values, convention "include"** (Morton et al. 1990, Figs. 3-4;
$w = 100$ per day from day 1, $\tau_1 = 45$, $\tau_2 = 15$, $k_1 = 1$,
$k_2 = 2$, no baseline):

| Quantity | Published | Recomputed |
|---|---|---|
| $k_1 g(60)$ | 3,351 | 3,350.8 |
| $k_2 h(60)$ | 3,044 | 3,044.3 |
| Asymptote of $k_1 g$ | 4,550 | 4,550.2 |
| Asymptote of $k_2 h$ | 3,101 | 3,101.1 |
| Asymptote of $p$ | 1,449 | 1,449.1 |
| Day of minimum $p$ | 16 | 16 (Eq. 10 gives 16.09) |
| Return to baseline | about day 47 | $p$ changes sign between days 47 and 48 |
| Peak after stopping on day 60 | about 1,353 on day 83 | 1,352.9 on day 83 |
| Peak after stopping from steady state | 2,121, 16 days later | 2,121.4, 16 days later |

**Reference fit, convention "include"** (Clarke & Skiba 2013, Fig. 8 and
supplemental sheet 8; one cyclist, 166 days, 9 tests): $p_0 = 261.93$,
$k_1 = 0.18258$, $k_2 = 0.23016$, $\tau_1 = 35.821$, $\tau_2 = 21.340$;
recomputed $R^2 = 0.979$ (published 0.98). The supplemental data are not
redistributed with the package; they are used only as an external check.

**Limitations to document** (sources in brackets): parameters are strongly
correlated and several parameter sets fit equally well [Hellard 2006, not yet
read; Busso & Chalencon 2023, SDC 3; Vermeire 2022, Table 1]; results depend on
starting values with local optimisers [Vermeire 2022]; adding fatigue improved
fit but not prediction in two datasets [Marchal 2025]; with 56-104 tests per
swimmer $R^2$ was 0.29 and prediction error 2-3% [Busso & Chalencon 2023]; the
model is linear in load, so its optimal plan is maximal training followed by
rest [Busso & Chalencon 2023; Ceddia 2025, preprint].

---

## M-03 One-component model (fitness only)

**Status:** `partly verified` · proposed for 0.0.3 (decision P-007 pending)
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

$$
p(t) = p_0 + k_1\,g(t)
$$

Equation as printed in Marchal et al. (2025, "FOM"). Busso, Carasso & Lacour
(1991), the usual original citation, has not been read.

---

## M-04 Response to constant daily training

**Status:** `verified` for convention "include" · planned for 0.0.3 (tests)
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

For $w(t) = T$ every day from day 1 (Morton et al. 1990, Eqs. 6, 9-11):

$$
g_{\mathrm{inc}}(t) = T\,\frac{1 - e^{-t/\tau}}{1 - e^{-1/\tau}},
\qquad
p(\infty) = \frac{k_1 T}{1 - e^{-1/\tau_1}} - \frac{k_2 T}{1 - e^{-1/\tau_2}}
$$

Day of poorest performance (Morton's $t_n$, Eq. 10; rederived here):

$$
t_{\min} = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}\,
\ln\!\left[\frac{\tau_1 k_2 \left(1 - e^{-1/\tau_1}\right)}
{\tau_2 k_1 \left(1 - e^{-1/\tau_2}\right)}\right]
$$

Under convention "exclude" (derived here, not taken from a source):

$$
g_{\mathrm{exc}}(t) = T\,e^{-1/\tau}\,\frac{1 - e^{-(t-1)/\tau}}{1 - e^{-1/\tau}}
$$

---

## M-05 Response to a single session (influence curve)

**Status:** `partly verified` · planned for 0.0.3
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

Effect on performance $u$ days after one unit of load:

$$
L(u) = k_1\,e^{-u/\tau_1} - k_2\,e^{-u/\tau_2}
$$

$$
t_n = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}\,\ln\!\left(\frac{k_2}{k_1}\right),
\qquad
t_g = \frac{\tau_1 \tau_2}{\tau_1 - \tau_2}\,
\ln\!\left(\frac{k_2\,\tau_1}{k_1\,\tau_2}\right)
$$

$t_n$: days until the net effect of the session becomes positive. $t_g$: days
until it is largest. Both were rederived here. Printed in Clarke & Skiba (2013,
Fig. 8B), Busso & Chalencon (2023, Eqs. 12-13) and Ceddia et al. (2025,
Eqs. 3-4, as $t_r$ and $t_p$). The original, Fitz-Clarke, Morton & Banister
(1991), has not been read.

**Reference values**

| Parameters | Source | Published | Recomputed |
|---|---|---|---|
| $k_1 = 0.048$, $k_2 = 0.117$, $\tau_1 = 38$, $\tau_2 = 1.9$ | Ceddia 2025, Fig. 2 (parameters attributed to Busso 1991) | 1.78, 7.77 | 1.78, 7.77 |
| Clarke & Skiba 2013 fit (M-02) | Fig. 8B | 12, 40 | 12.2, 39.6 |

**Name clash.** Morton et al. (1990) use $t_n$ for a different quantity: the
day of poorest performance under constant daily training (M-04). Function and
argument names must not use a bare `t_n`. Proposed names: `time_to_recover`
($t_n$ here), `time_to_peak` ($t_g$), `time_of_minimum` (M-04).

**Recommendation to document:** report the single-session response rather than
individual parameters; two parameter sets with very different $\tau_1$ gave
similar $t_n$ and $t_g$ [Busso & Chalencon 2023, SDC 3].

---

## M-06 Variable dose-response model (Busso)

**Status:** `partly verified` · planned, phase 2
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

$$
p(n) = p_0 + k_1 \sum_{i=1}^{n-1} w(i)\,e^{-(n-i)/\tau_1}
- \sum_{i=1}^{n-1} k_2(i)\,w(i)\,e^{-(n-i)/\tau_2},
\qquad
k_2(i) = k_3 \sum_{j=1}^{i} w(j)\,e^{-(i-j)/\tau_3}
$$

Checked against the R script of Busso & Chalencon (2023, SDC 2) by numerical
emulation, and against the equations printed in Clarke & Skiba (2013). The
fatigue term multiplies by $w(i)$ and the inner sum runs to $i$ inclusive. The
original article, Busso (2003), has not been read. Two secondary sources print
other versions (see discrepancy log).

---

## M-07 Saturating load transform (Hill function)

**Status:** `unverified` · planned, phase 2
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

$$
\omega(s) = \kappa\,\frac{w(s)^{\gamma}}{\delta^{\gamma} + w(s)^{\gamma}}
$$

As printed in Clarke & Skiba (2013, Fig. 10A), applied separately to the
positive and negative components. The original, Hellard et al. (2005), has not
been read.

---

## M-08 Exponentially weighted moving average and its link to M-01

**Status:** `partly verified` · not implemented in this package (D-019)
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

$$
\mathrm{EWMA}(t) = \mathrm{EWMA}(t-1)\,(1 - \lambda) + \lambda\,w(t)
$$

| Parameterisation | $\lambda$ | Source |
|---|---|---|
| Time constant ("CTL"/"ATL" of training platforms) | $1 - e^{-1/\tau}$ | Kontro et al. 2025, Eqs. 17-18 (author manuscript read; check the published version) |
| Span $N$ days | $2 / (N + 1)$ | Williams et al. 2017, read: EWMA_today = Load_today * lambda + (1 - lambda) * EWMA_yesterday, lambda = 2/(N + 1), N = 7 and 28, initialised with the load of day 1 |

With $\lambda = 1 - e^{-1/\tau}$ the EWMA equals $(1 - e^{-1/\tau})\,g_{\mathrm{inc}}(t)$:
the platform "fitness" is the fitness component of M-02 without gains.

EWMA-based loads are provided by the ACWR package (D-019), not by
trainingmodels.

---

## M-09 Training impulse (TRIMP)

**Status:** `partly verified`, with an open discrepancy · not in the first version
**Author approval:** approved 2026-11-24 (entry as written; verification status unchanged)

Morton et al. (1990, Eqs. 1-3):

$$
w = D \cdot x \cdot e^{b x},
\qquad
x = \frac{\mathrm{HR_{ex}} - \mathrm{HR_{rest}}}{\mathrm{HR_{max}} - \mathrm{HR_{rest}}}
$$

with $D$ the duration in minutes, $b = 1.92$ for men and $1.67$ for women.
Clarke & Skiba (2013), citing Banister (1991), print the weighting as
$0.64\,e^{1.92x}$ and $0.86\,e^{1.67x}$. The factors 0.64 and 0.86 do not
appear in Morton et al. (1990). To be resolved before implementation.

---

## M-10 Session RPE load

**Status:** `verified` · planned for 0.0.2
**Author approval:** approved 2026-11-26

$$
w = \mathrm{RPE} \times D
$$

- RPE on the 0-10 category-ratio scale: one global rating for the whole
  session, asked about 30 minutes after it ends.
- $D$: duration in minutes of the entire session, including warm-up,
  cool-down and recovery intervals.
- Sessions of the same day are summed (as for every load; see `as_daily_load()`).

**Verification**

| Checked against | How |
|---|---|
| Foster 1998; Foster et al. 2001 | Definition read; Table 1 of Foster 1998 recomputed |

**Reference values** (Foster 1998, Table 1):

| Duration (min) | 180 | 120 | 20 | 90 | 75 | 20 | 120 |
|---|---|---|---|---|---|---|---|
| RPE | 5 | 7 | 2 | 6 | 7 | 2 | 7 |
| Load | 900 | 840 | 40 | 540 | 525 | 40 | 840 |

Foster et al. 2001, Table 5, prints loads that do not all equal RPE x
duration (discrepancy log, #16); it is not used as a test.

---

## M-11 Rolling load

**Status:** `verified` · planned for 0.0.2
**Author approval:** approved 2026-11-26

For daily loads $w(1), \dots, w(T)$ of one athlete and a window of $k$ days:

$$
S_{\mathrm{inc}}(t) = \sum_{j=t-k+1}^{t} w(j), \quad t \ge k;
\qquad
S_{\mathrm{exc}}(t) = \sum_{j=t-k}^{t-1} w(j), \quad t \ge k + 1
$$

- Rolling mean $= S(t) / k$.
- $S(t)$ is NA where it is not defined or where any day in the window is
  missing (D-016).
- Identity: $S_{\mathrm{exc}}(t) = S_{\mathrm{inc}}(t-1)$.
- Timing option `same_day_load` as in D-020; default `"include"` (D-021).

**Verification**

| Checked against | How |
|---|---|
| Carey et al. 2017, Eq. 1 | Equation as printed; uses the "exclude" form for both windows of a daily workload ratio |

---

## M-12 Monotony and strain

**Status:** `verified` · planned for 0.0.2
**Author approval:** approved 2026-11-26

Foster (1998):

$$
\text{monotony} = \frac{\text{mean daily load of the week}}
{\text{SD of the daily loads of the week}},
\qquad
\text{strain} = \text{weekly load} \times \text{monotony}
$$

- SD is the sample standard deviation ($n - 1$).
- Assumption, not stated by Foster: rest days count as load 0.
- Package generalisation: the week is a rolling window of $k$ days (default 7)
  under either timing option of M-11 (D-022). When all loads in the window
  are equal the SD is 0 and monotony and strain are NA.

**Verification**

| Checked against | How |
|---|---|
| Foster 1998, Table 1 | Recomputed from the daily loads of M-10 with the sample SD |

**Reference values** (Foster 1998, Table 1; loads 900, 840, 40, 540, 525, 40,
840):

| Quantity | Published | Recomputed |
|---|---|---|
| Weekly load | 3725 | 3725 |
| Mean daily load | 532 | 532.142857 |
| SD | 367 | 367.285733 |
| Monotony | 1.44 | 1.448853 |
| Strain | 5397 | 5396.9756 |

The published monotony is truncated, not rounded (discrepancy log, #17).

---

## Discrepancy log

| # | Source | Location | Issue | Found by |
|---|---|---|---|---|
| 1 | Clarke & Skiba 2013 | Fig. 6A vs 6B | Summation runs to $t-1$ ("exclude") but the recursion and the spreadsheet use "include"; presented as equivalent | Algebra; spreadsheet formulas |
| 2 | Ceddia et al. 2025 (preprint) | Eq. 5 | Inner sum of the Busso model runs to $i-1$; Busso's own code runs to $i$ | Emulation of Busso & Chalencon 2023 SDC 2 |
| 3 | Swinton et al. 2021, Part II (preprint) | Eq. 9 vs Eq. 18 | Eq. 9 omits the factor $w(i)$ in the fatigue term; Eq. 18 includes it | Reading; emulation of Busso's code |
| 4 | Clarke & Skiba 2013 | Fig. 10B | Busso formula printed with $k_2(s)$ outside the sum and $w(s)$ in place of $w(j)$; the text equation is correct | Reading |
| 5 | Busso & Chalencon 2023 | Eqs. 3-6 | Written as sums of recursive terms; the script is unambiguous | Reading the script |
| 6 | Busso & Chalencon 2023 | Methods vs SDC 2 | Text states L-BFGS-B; `constrOptim` without a gradient uses Nelder-Mead | Reading the script |
| 7 | Busso & Chalencon 2023 | SDC 2, models TF2 and TIF | Objective function splits the fatigue term onto a line starting with `+`, which R would ignore; may be a PDF artefact | Reading the script |
| 8 | Morton et al. 1990 | Results, subject EWB | $t_n$ reported as 16 days; Eq. 10 with Table 2 values gives 8.8. Subject RHM agrees (11) | Recomputation |
| 9 | Morton et al. 1990 | Experimental validation | Twice-daily training described as starting after 7 days and, later, on the 11th day | Reading |
| 10 | Morton et al. 1990 vs Fitz-Clarke et al. 1991 lineage | Symbol $t_n$ | Same symbol, two different quantities (M-04 and M-05) | Reading |
| 11 | Morton et al. 1990 vs Clarke & Skiba 2013 | TRIMP weighting | Factors 0.64 and 0.86 absent in Morton 1990 | Reading |
| 12 | Ceddia et al. 2025 (preprint) | Eq. 27; Eq. 20; Appendix A | Exponent $-(n-1)$ for $-(n-i)$; $t$ for $j$; impossible inequality $n-1 < t_r < n-2$ | Reading |
| 13 | Swinton et al. 2021, Part II (preprint) | Eq. 22; Eq. 16 | Turner optimum does not match a direct derivation; Kalman update omits the baseline | Rederivation |
| 14 | Kontro et al. 2025 (author manuscript) | Section III text vs Table 1 | Strain coefficient at critical power stated as 0.27; formula and table give 0.25 | Recomputation |
| 15 | Wang et al. 2025 | Eqs. 3-4, 10, 14 | Not an impulse-response model (no accumulation of past loads); gains and constants enter only as differences; stated general solution of Eqs. 1-2 is incorrect; "original model" is a line through the origin | Reading |
| 16 | Foster et al. 2001 | Table 5 | Three printed loads differ from RPE x duration (940 vs 5 x 180 = 900; 390 vs 8 x 75 = 600, twice). The printed monotony 1.26 is not reproduced from the printed daily loads (1.12 with the sample SD, 1.21 with the population SD). Not used as a test | Recalculation |
| 17 | Foster 1998 | Table 1 | Monotony printed as 1.44; the value is 1.449 (truncated). The printed strain 5397 agrees with the unrounded monotony | Recalculation |

---

## Data requirements and published designs

All impulse-response models in this registry need the same data: one load value
per day and performance on some days. Example datasets shipped with the package
are simulated and labelled as such.

| Design | Source | Features |
|---|---|---|
| Overload then detraining | Morton et al. 1990 | 28 days of daily or twice-daily training, then 50 days without formal training; best-effort test at least twice a week; 2 subjects |
| In-season monitoring | Busso & Chalencon 2023 | Two tests per week over one or two seasons; 56-104 tests per swimmer |
| Teaching laboratory | Clarke & Skiba 2013 | Tests at least weekly, 3-15 min maximal efforts, in all phases of training |

---

## Sources

**Read for this registry** (as Markdown conversions): Morton, Fitz-Clarke &
Banister 1990 (*J Appl Physiol* 69:1171-7); Clarke & Skiba 2013 (*Adv Physiol
Educ* 37:134-52) with supplemental spreadsheet; Busso & Chalencon 2023 (*Med
Sci Sports Exerc* 55:1274-85) with SDC 2-3; Vermeire et al. 2022 (*Int J Sports
Physiol Perform* 17:810-3); Imbach et al. 2022 (*Sports Med Open* 8:29);
Marchal et al. 2025 (*Sci Rep* 15:3706); Kontro et al. 2025 (author
manuscript); Wang et al. 2025 (*PLOS One* 20:e0337824); Ceddia et al. 2025
(arXiv preprint); Stephens Hemingway et al. 2021 and Swinton et al. 2021
(SportRxiv preprints, Parts I and II).

**Read as PDF:** Foster 1998; Foster et al. 2001; Carey et al. 2017; Williams
et al. 2017. The Foster 1998 file is a print of the journal web page; its
Table 1 was read from the embedded image.

**Not yet read** (needed before the entries that cite them can be `verified`):
Banister et al. 1975; Calvert et al. 1976; Fitz-Clarke et al. 1991; Busso et
al. 1991; Busso 2003; Hellard et al. 2005 and 2006; Banister 1991.
