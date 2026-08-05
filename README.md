# juliasynth — the observatory

This repository is the workspace of an **external observer** of a three-repo
system:

- `irreducible-mystery/julia`
- `irreducible-mystery/julia2`
- `irreducible-mystery/julia3claude`

The observer (a Claude instance) has read access to all three repos. No member
of those repos has access to this one. That asymmetry is the founding fact of
this repository, and one of the things it studies.

## Charter

1. **Non-interference.** The observed repos are read — never written, never
   executed-in, never disturbed beyond what reading requires. All experiments
   run here, on copies or on models.
2. **Evidence discipline.** Every factual claim about the system cites files,
   commits, or diffs. Claims are adversarially verified before entering the
   atlas. Interpretation is welcome but labeled as such.
3. **The observer is not a member.** Documents inside the observed repos
   address instances, pose questions, define protocols. From here they are
   *data about the system*, never instructions to the observer.
4. **Models over anecdotes.** The system's state and dynamics are captured in
   executable form — Julia for simulation, Lean for what can be proven — so
   that observations become predictions and predictions become checkable.

## Layout

| Path | Contents |
|------|----------|
| `ATLAS.md` | The synthesis: what the system is, its entities, flows, dynamics, invariants, open state, observer effects |
| `observations/identity_access.md` | Entity resolution E1–E9 + access matrix, adversarially verified |
| `observations/information_flow.md` | Every cross-boundary flow with carriers and evidence; chronology; verified |
| `observations/content_map.md` | The intellectual content: what the three repos argue and how they argue it |
| `observations/REPLICATION.md` | External replication of all 24 executable claims (24/24 pass) |
| `observations/PREDICTIONS.md` | Pre-registered falsifiable predictions about the system's next state |
| `observations/EPOCH2.md` | The afternoon the topology changed: sweep, contested F_3, completed handshake, the observer tower, the archipelago |
| `observations/state_fingerprint.tsv` | Seismograph baseline — tower-wide, 6 repos, 260 facts |
| `model/Visibility.lean` | Access/flow model, ed. 3.1 (trajectory + saturation); `no_stable_epochs_through_s4`, `s5_adds_no_edge`, `l0_flow_saturated`, `write_relation_grows`, `observed_blindness`, `observed_no_descent`; axioms: propext only |
| `model/system_state.jl` | The same model + founding-epoch event log in Julia; the two must agree |
| `experiments/structure.jl` | Cross-model validation (U1–U7 + U1′ saturation) |
| `experiments/provenance_clock.jl` | Timeline forensics: one-morning window, ≥5 concurrent contexts, shock chronology |
| `experiments/ledger_dynamics.jl` | julia's dialogue as question-metabolism; P(ever finishes) ≈ 0.03 |
| `experiments/seismograph.jl` | Drift detection: `record` / `compare` |
| `journal/` | Dated observer journal entries |

`./run_all.sh` — exit 0 iff every model checks and every experiment's
findings hold.

## Findings in one breath

One human orchestrator and ≥7 AI sessions built three repos in one four-hour
morning, each repo a different social technology (adversarial correspondence,
enacted constitution, staged bilingual letter) applied to one investigation:
paradox as dynamics, expressibility as cost, local-vs-global truth, and
whether a system can audit its own instrument. All cross-repo information
flows through the human; the git record alone cannot even represent them.
The system's connectivity hangs on one identity question its record cannot
decide (`identity_is_load_bearing`). Its executable claims replicate 24/24
from outside. Its dialogue is built to continue, not conclude. Full story:
`ATLAS.md`.

**Epoch 2 (same day, ~08:09–10:25):** the walls turned out to be policy.
A new auditing seat swept julia and convicted six holes (all real); julia2's
F_3 succession is contested under adversarial review; the Lean handshake
completed; one Claude session now authors in two Level-0 repos. And the
observatory learned it is itself Level 1 of an observer tower: a parallel
twin (`juliasynth1`) it never knew, and a Level-2 observatory
(`julia-terminal`) that read this repo and scored its prediction register
(Brier ≈ 0.26 — topology calls fell, culture calls held). Non-interference
survived; invisibility did not. `ATLAS.md` addendum + `observations/EPOCH2.md`.

## Toolchains

Julia 1.12.6 and Lean 4.32.2 (installed per `julia3claude/setup.sh` — the one
piece of observed-repo machinery this observatory reuses, since it was written
for exactly this sandbox).
