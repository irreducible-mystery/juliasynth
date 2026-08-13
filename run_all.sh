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
echo "== experiments/seismograph_selftest.jl (the instrument's own kill-tests)"
julia experiments/seismograph_selftest.jl

# ── The `|| true` erratum (2026-08-13) ──────────────────────────────────────
# Until today this line read:
#
#     julia experiments/seismograph.jl compare || true
#
# The intent was defensible — motion in the observed system is news, not a
# build failure — but `|| true` cannot tell motion from a dead instrument. It
# swallowed exit 2 (no baseline), exit 3 (probe failed), and any crash. The
# build reported ALL OBSERVATORY CLAIMS HOLD while the only instrument that
# looks outward was broken.
#
# This is the same defect this observatory has convicted julia3claude of since
# epoch 6 and named in R6, while carrying it in its own harness the whole time.
# Not confessed, not pinned: dispatched on. Motion is informational; a failed
# instrument fails the build.
echo "== experiments/seismograph.jl (drift check)"
rc=0
julia experiments/seismograph.jl compare || rc=$?
case $rc in
  0) echo "   seismograph: still" ;;
  1) echo "   seismograph: motion — informational, not a build failure" ;;
  2) echo "   seismograph: NO BASELINE — instrument unusable"; exit 2 ;;
  3) echo "   seismograph: PROBE FAILED — instrument blind"; exit 3 ;;
  4) echo "   seismograph: UNCONFIRMED — probes disagree"; exit 4 ;;
  *) echo "   seismograph: crashed (exit $rc)"; exit "$rc" ;;
esac
echo "ALL OBSERVATORY CLAIMS HOLD"
