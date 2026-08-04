#!/usr/bin/env bash
# The observatory's own claims, executable. Exit 0 iff every model checks and
# every experiment's findings hold. (The observed system's convention: read
# exit codes, not prose. Prose is ledger, not evidence.)
set -e
cd "$(dirname "$0")"
echo "== model/Visibility.lean (kernel + axiom ledger)"
lean model/Visibility.lean
echo "== experiments/structure.jl (cross-model validation)"
julia experiments/structure.jl
echo "== experiments/provenance_clock.jl (timeline forensics)"
julia experiments/provenance_clock.jl
echo "== experiments/ledger_dynamics.jl (question metabolism)"
julia experiments/ledger_dynamics.jl
echo "== experiments/seismograph.jl (drift check — informational)"
julia experiments/seismograph.jl compare || true
echo "ALL OBSERVATORY CLAIMS HOLD"
