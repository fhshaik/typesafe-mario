# TypeSafe Mario

An experimental controller that lets TypeSafe's Jev model directly choose NES
controller inputs for the original Super Mario Bros.

The model does **not** receive screenshots. The harness translates emulator telemetry
and RAM into compact, object-centric JSON containing Mario's motion, jump trajectory,
upcoming enemies, terrain, measured response delay, recent-control results, and episode
progress. Jev chooses one of the legal controller actions, the emulator advances several
frames, and the loop repeats. The raw local tile grid remains available in debug logs
and the UI, but is not duplicated in the model input.

## Architecture

```text
NES emulator -> telemetry/RAM parser -> structured JSON -> Jev Choice -> controller input
```

The initial action set is intentionally small:

- `noop`
- `right`
- `right_jump`
- `right_run`
- `right_run_jump`
- `jump`
- `left`

## Requirements

- Python 3.13 or newer
- A TypeSafe API key in `TYPESAFE_API_KEY`
- A legal local setup for Super Mario Bros.

This repository contains no Nintendo ROM or other copyrighted game data. You are
responsible for ensuring that your emulator and game files are obtained and used
lawfully.

## Setup

With the Makefile (macOS/Linux):

```bash
make install                    # create .venv and install .[mario,dev]
export TYPESAFE_API_KEY=your-key
```

Or manually (Windows):

```powershell
py -3.13 -m venv .venv
.venv\Scripts\python -m pip install -e ".[mario,dev]"
$env:TYPESAFE_API_KEY = "your-key"
```

Inspect the exact JSON and text that will be sent to TypeSafe without launching the
game or calling the API:

```powershell
.venv\Scripts\typesafe-mario state-demo
```

Run World 1-1 with Jev making a decision every eight emulator steps. The default
display is a single recordable window with the live game and model telemetry:

```bash
make run
# or with extra flags:
make run ARGS="--env SuperMarioBros-1-1-v0 --frames-per-decision 8"
make run ARGS="--policy heuristic --display none"
```

The flags above are the defaults, so plain `make run` is enough. Without make:

```powershell
.venv\Scripts\typesafe-mario play --env SuperMarioBros-1-1-v0 --frames-per-decision 8
```

The dashboard shows the selected action, full Choice probability distribution,
confidence, Jev latency, jump probability, danger score, reward, and parsed game
state. Press `R` or click **Restart** for a fresh episode; the dashboard remains open
after death or level completion. Press `Esc` or `Q` to quit. Use `--display game` for
only the emulator window or `--display none` for a headless benchmark.

Each decision is written to `artifacts/run-<timestamp>.jsonl`. These records include
latency, action probabilities, confidence, canonical model state, raw debug state, and
game outcome, providing the data for a live overlay or rendered social clip.

## What the parser produces

TypeSafe accepts JSON directly, so there is no need to flatten telemetry into prose.
The model-facing object groups observations by meaning:

- `player`: position, velocity, grounded state, jump phase, and power-up
- `trajectory`: airtime, distance since takeoff, and committed gap crossing
- `hazard`: up to three enemies, projected positions, contact timing, and takeoff deadline
- `terrain`: obstacle/gap geometry, observation reliability, and last grounded preview
- `reaction_timing`: action duration and measured observation-to-action delay
- `recent_control`: chosen action, duration, progress gained, and observed outcome
- `episode`: lives, clock, progress, stalls, death, and level completion

For humans, the fuller debug snapshot can still be rendered as compact text:

```text
Goal: Reach the flag in World 1-1 without dying.
Mario: x=172 y=79, moving right, airborne=False, status=small
Progress: 172 (best 172), time=387, lives=2
Nearby enemies: goomba 42px ahead
Local grid (# solid, . empty, E enemy, M Mario):
...........
...........
...........
..M..E.....
###########
```

The structured object is canonical; the text view is only for debugging and UI.

## TypeSafe judgments

Each request evaluates three independent judgments over the same state:

- a `Choice` selects the next controller macro;
- a `Noul` estimates whether a forward jump is useful now;
- a `Score` measures immediate danger for the live visualization.

Exact timing arithmetic stays in code. For example, the parser combines measured
response age, enemy motion, action cadence, and jump-clearance time into a typed
`jump_must_start_this_decision` fact. Jev interprets those facts and still owns the
controller choice—there is no scripted recovery-action override.

## Development

```bash
make test    # pytest
make lint    # ruff check src tests
make clean   # remove caches (.ruff_cache, .pytest_cache, __pycache__)
```

Or manually:

```powershell
.venv\Scripts\ruff format --check src tests
.venv\Scripts\ruff check src tests
.venv\Scripts\python -m pytest -q
```
