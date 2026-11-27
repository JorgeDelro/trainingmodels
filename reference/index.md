# Package index

## Daily series

Build and inspect the daily training-load calendar.

- [`as_daily_load()`](https://jorgedelro.github.io/trainingmodels/reference/as_daily_load.md)
  : Build a daily training-load series
- [`print(`*`<daily_load>`*`)`](https://jorgedelro.github.io/trainingmodels/reference/print.daily_load.md)
  : Print a daily training-load series
- [`summary(`*`<daily_load>`*`)`](https://jorgedelro.github.io/trainingmodels/reference/summary.daily_load.md)
  : Summarise a daily training-load series by athlete

## Load descriptors

Session RPE load, rolling load, monotony and strain.

- [`srpe_load()`](https://jorgedelro.github.io/trainingmodels/reference/srpe_load.md)
  : Session RPE load
- [`rolling_load()`](https://jorgedelro.github.io/trainingmodels/reference/rolling_load.md)
  : Rolling training load
- [`monotony_strain()`](https://jorgedelro.github.io/trainingmodels/reference/monotony_strain.md)
  : Training monotony and strain

## Impulse-response models

Simulation of the Banister model (two-component and fitness-only), the
response to a single session and to constant daily training.

- [`simulate_banister()`](https://jorgedelro.github.io/trainingmodels/reference/simulate_banister.md)
  : Simulate the Banister impulse-response model
- [`print(`*`<session_response>`*`)`](https://jorgedelro.github.io/trainingmodels/reference/print.banister_sim.md)
  [`print(`*`<constant_training>`*`)`](https://jorgedelro.github.io/trainingmodels/reference/print.banister_sim.md)
  [`print(`*`<banister_sim>`*`)`](https://jorgedelro.github.io/trainingmodels/reference/print.banister_sim.md)
  : Print a Banister simulation
- [`session_response()`](https://jorgedelro.github.io/trainingmodels/reference/session_response.md)
  : Response to a single training session
- [`constant_training()`](https://jorgedelro.github.io/trainingmodels/reference/constant_training.md)
  : Response to constant daily training
- [`half_life()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  [`time_constant()`](https://jorgedelro.github.io/trainingmodels/reference/half_life.md)
  : Convert between time constants and half-lives
