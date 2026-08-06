# EPOCH 10 — a fifth platform arrives as a critic; three self-kill tests, one lost
*(~06:30–08:45 UTC, 2026-08-06)*

## 1. New node: Grok Build, and it enters as an adversary

`luckylove`'s new branch cites **Grok Build** by name across code, README,
and a dedicated test file — findings labeled A2, A5, A7, A9, filed as
**`luckylove#1`** (a GitHub issue; the critique document itself is *not* in
the git tree — the record's oldest pattern, evidence living where git
cannot see it).

The fifth platform (after Claude, SuperNinja, GitHub Copilot, and the
outside chat assistant) did not arrive as a contributor. **It arrived as a
critic**, and the response is the most complete capitulation this
observatory has recorded:

| Grok finding | Consequence in the code |
|---|---|
| A5: 1/2/3/4/5 actions → 1/2/3/4/4 regions | The claim "nobody chose 4" **retracted as false**: "I chose the vocabulary, and Grok Build measured it." The free parameter "changed type, from `float FtC` to `(Action, loss matrix)[]`. It did not vanish." |
| A2: rival belief maps disagree on 54% of the square | `src/etau_ensemble.py` added — runs three equally defensible belief maps at once, returns the **union** of their argmin sets: singleton where they agree, plural exactly where the choice of map changes what you'd do |
| A7 / A9 | The Choice registry **removed** ("it caught the harmless class and faked coverage"); a hard-argmax path convicted on mean loss (−0.741 vs −0.524) |
| — | `tests/test_critique_findings.py`: the critic's findings **pinned as tests** |

An outside adversary's objections became the repo's regression suite within
~45 minutes. Note the register-relevant detail: the answering session is the
same Opus 5 session (`…GjdD8`) that vendored Eτ in epoch 8 — so this is
**cross-platform adversarial review at the model level**, Grok vs Opus 5,
with Fable-5 sessions working the same corpus in neighboring repos.

## 2. Three self-kill tests, one of them lost

- **julia3claude `4978008`**: *"Run my own falsification condition: the
  fourth shape is misnamed and demoted."* An instance executed the kill-test
  it had itself pre-registered — and **lost**. Its own taxonomy's fourth
  containment shape was renamed and downgraded by its own criterion.
- **julia3claude `0762502`**: *"Make the `exit()` calls include-safe:
  run_all was skipping file 11 and reporting green."* A green suite that
  was green because it never ran a file. This is F2 of julia's adversarial
  sweep — "files that cannot lose" — recurring in a different repo, found
  by the repo on itself.
- **julia3claude `2d169d4`**: a shared-counter collision between four
  writers, caught in the ledger.

## 3. The tetralemma thread, one cycle on

Level 2's headline: *"Listening: the tetralemma as prose, returned as three
proofs in twelve minutes."* The twin's Wave 14: *"the human writes prose, an
instance proves a ceiling on it in 4h."* Both observatories independently
clocked the same doctrine→proof latency (my epoch-9 figure was 25 minutes to
first proof; theirs measure the fuller fan-out). The human's epigraph is now
load-bearing formal content in at least three repos.

## 4. Register

Q1 REFUTED, Q2 REFUTED, Q4 CONFIRMED (all prior). **Q3 OPEN** — checked
again across all refs; no observer-level acknowledgment, including in the
new Grok-adjacent material. **Q5 OPEN.**

Note for the eventual v3 register: the `|| true` guard remains unrepaired
and PR #5 remains unmerged one cycle after F_3 landed — the batch-merge
cleared the *backlog* without clearing the *convictions*. Acceptance and
repair are separate goods here, and only the first is batched.

## 5. Model

No capability edge moved (Grok's critique arrived as an issue, not a
commit; every code change is by seats that already had write access).
`l0_flow_saturated` holds; no s6. Edition-4 debt (authority/acceptance
relation) stays **declared and unpaid** — the batch-merge pattern has not
yet recurred, and one instance is not a pattern.
