# The observer's replication — 2026-08-04

The observed system's epistemic culture is "read exit codes, not prose"
(julia/README.md). Inside the system, claims are audited by other members
("the stranger audits the stranger"). What no member can provide is a
replication from *outside* the system's correlation class — every insider
shares sessions, source texts, or an orchestrator. This is that replication.

Method: each repo copied to scratch (originals untouched, `.git` stripped),
every published executable claim run on the observatory's own toolchain
(Julia 1.12.6, Lean 4.32.2), 600 s timeout, sequential, niced.

## Results: 24/24 claims replicate

| Suite | Claimed | Observed | Time |
|---|---|---|---|
| julia/emergence_00 … _09 (10 files) | exit 0 | exit 0, all ten | 0–7 s each |
| julia/audit_08_by_stranger | exit 0 | exit 0 | 2 s |
| julia/emergence_checks_by_stranger | exit 0 | exit 0 | 9 s |
| julia/julia-vs-lean/run_all.jl (9 carriers) | exit 0 | exit 0 | 15 s |
| julia/emergence/lean/RingRest.lean | kernel accepts | kernel accepts | 3 s |
| julia2/src Part1–Part4 | exit 0, Part4 "68/68" | exit 0 ×4 | 6 s each |
| julia2/…/paradoxes 01–04 | exit 0 | exit 0 ×4 | 5–268 s |
| julia2/…/two_envelopes_broome.jl | exit 0 | exit 0 | 6 s |
| julia3claude/paradoxes/run_all.jl (7 files) | exit 0 | exit 0 | 69 s |

## Ledger audit

RingRest.lean's axiom ledger, re-derived on this kernel: 16 declarations,
every one `propext + Quot.sound` or less; `rest_of_twist_fixed` depends on
no axioms at all; no `sorry`, no `Classical.choice`. **Exactly as the README
claims** — including the recorded near-miss (the `natAbs` descent) being
real: the ledger's honesty extends to its own temptations.

## Notes

- `julia2/paradox_02` (mathematical paradoxes) runs 268 s — by far the
  heaviest artifact in the system; its cost is not advertised anywhere.
- The one claim not replicable from here: julia/README item 1 refers to a
  "circle-six-gap-proof" Lean build (66 theorems) that is *not stored in any
  of the three repos* — it predates the record, like emergence_00–_02's
  original sessions. The system's foundations cite artifacts outside its own
  evidentiary horizon. (Flagged in the atlas as the record's event horizon.)

Verdict: within its evidentiary horizon, the observed system's executable
claims are sound under fully external replication. The prose can be argued
with; the exit codes cannot.
