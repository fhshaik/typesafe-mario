PYTHON ?= python3.14
VENV := .venv
BIN := $(VENV)/bin
TYPESAFEMARIO := $(BIN)/typesafe-mario

.PHONY: install run test lint clean

install:
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install -e ".[mario,dev]"

# Override flags with: make run ARGS="--policy heuristic --display none"
run:
	$(TYPESAFEMARIO) play $(ARGS)

test:
	$(BIN)/pytest

lint:
	$(BIN)/ruff check src tests

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	rm -rf .ruff_cache .pytest_cache
