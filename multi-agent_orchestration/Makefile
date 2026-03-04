# --- P4 Project: Multi-Agent Orchestration ---
# Professional Wrapper for Dune

.PHONY: all build run clean test utop setup

all: build

# Standard build command
build:
	dune build

# Runs the main executable (bin/main.ml)
# Use 'make run ARGS="my_program.ma"' to pass arguments
run:
	dune exec multi-agent_orchestration -- $(ARGS)

# P4 Requirement: Testing (Unit and Integration)
test:
	dune runtest

# Interactive REPL - Great for "Problem Analysis" phase
utop:
	dune utop lib

# Setup command for new developers
setup:
	opam install . --deps-only --with-test
	opam install menhir  # For the parser (Week 5)

clean:
	dune clean