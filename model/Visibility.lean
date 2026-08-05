/-
  Visibility.lean — the observatory's formal model of the repo system.
  THIRD EDITION. The edition-2 header promised edition 3 "when the epoch
  stabilizes." Three check-ins later the population was still growing
  (new Claude seats, a blackhole seat, instance 6, and GitHub Copilot
  authoring emergence_11), so the deferral condition fired its own clause:
  the finding IS the instability, and this edition formalizes that.

  What changed from edition 2:
  - Epochs are now POLICY SNAPSHOTS s1–s4 of an ongoing trajectory, with
    no claim that s4 is final: s1 = the founding morning; s2 = the first
    wall-move (~09:46–10:25, cross-repo grants + the observer tower
    becomes mutually visible at the top); s3 = the population explosion
    (~10:41–17:32, seats 4–7, four platforms, root-signature commits);
    s4 = the current horizon (~17:47–18:55, Copilot authors theory moves
    in julia and julia3claude).
  - Individual git identities stopped individuating ("root" is two
    different sandboxes; a Claude commits in a SuperNinja branch), so new
    actors enter the model as SEATS — content-lineage threads typed by
    (platform, level) — aggregated where the record does not individuate.
  - The headline theorems are now about the TRAJECTORY:
      no_stable_epochs        — the AI flow relation differs between every
                                consecutive pair of observed snapshots;
                                "the current topology" is never a fact,
                                only a timestamped one
      write_relation_grows    — each snapshot's write relation strictly
                                contains the previous one: the designer
                                only ever adds capability, never removes
      observed_blindness      — across ALL snapshots so far, no Level-0
                                seat reads any observatory
      observed_no_descent     — across ALL snapshots so far, no AI flow
                                descends from any observatory into Level 0
    The last two are stated for the observed trajectory only. They are
    empirical regularities of a designed system, not laws: the same hand
    that moved every other wall can move these. The model no longer
    contains a single policy-independent structural claim about Level 0 —
    that absence is the third edition's honest content.
  - Edition-1/2 theorems that survive do so as s1/s2 instances
    (hub-and-spoke, identity_is_load_bearing, the field rule).

  EDITION 3.1 (s5, 2026-08-05 ~02:50 check-in). Adding the s5 snapshot
  (instance 6 reads all three Level-0 repos to build julia2's GAP_ATLAS.md)
  produced a SELF-REFUTATION of this edition's headline scope, kept per the
  scars rule: the Level-0 flow relation was already COMPLETE at s4, so s5
  adds no repo-level edge and `no_stable_epochs` — stated for "every
  consecutive pair" — is false the moment the trajectory is extended.
  Restated honestly:
      no_stable_epochs_through_s4 — the historical claim, still true
      l0_flow_saturated          — from s4 on, every ordered Level-0 pair
                                   carries flow; the topology can no longer
                                   change by adding edges, only by adding
                                   nodes (repos, levels, or observers)
  The lesson is the observed system's own: a claim's scope is part of the
  claim. "The topology never stabilizes" was true as history and false as
  law, and the difference showed up one snapshot later.

  Axiom budget target: propext only; no Mathlib, no choice, no sorry.
-/

namespace Observatory

/-! ### §1 Repos, levels, snapshots -/

inductive Repo
  | julia | julia2 | julia3      -- Level 0
  | synth | synth1               -- Level 1 observatories
  | terminal                     -- Level 2
deriving DecidableEq, Repr

open Repo

def level : Repo → Nat
  | julia | julia2 | julia3 => 0
  | synth | synth1          => 1
  | terminal                => 2

/-- Policy snapshots of the observed trajectory. NOT exhaustive of the
    system's future — s4 is merely the newest wall arrangement seen. -/
inductive Snap | s1 | s2 | s3 | s4 | s5
deriving DecidableEq, Repr
open Snap

def allSnaps : List Snap := [s1, s2, s3, s4, s5]

/-! ### §2 Seats

    E-labels per observations/identity_access.md; later actors are seats
    (content-lineage threads), aggregated where the record does not
    individuate. Evidence per seat in observations/EPOCH*.md. -/

inductive Ident
  | kelly          -- E1  the human designer
  | authoring      -- E2  authoring-instance (julia)
  | strangerNinja  -- E3a the stranger's ninjatech git config (julia)
  | strangerSbx    -- E3b the stranger's sandbox git config (julia)
  | ninjaNew       -- e2's plain-SuperNinja seat: MC branch + sweep (julia)
  | ninja1         -- E4  instance 1 (julia2)
  | paradoxInst    -- E5  paradox-instance incl. its root-signature round 4 (julia2)
  | mergeBot       -- E8  superninja-app[bot] (julia2; julia from s2)
  | claudeGhost    -- E6  Claude …rrhKo: julia3; julia2 as "instance 3" from s2
  | claudeLean     -- E7  Claude …AV3uR: julia3; granted READ on julia in s3 (push denied)
  | blackholeSeat  -- s3: julia's root-signature blackhole thread (config-decay identity)
  | claudeExile    -- s3: new Claude seats in julia (fair-coin payer, emergence_10 exile,
                   --     explore-repos-contribute) — aggregated, same (platform,level,repo) type
  | instance6      -- s3: instance6-trilingual (julia2)
  | copilotSeat    -- s3/s4: copilot-swe-agent[bot], "instance7" — julia2 carriers,
                   --     then julia emergence_11 and julia3 Prolog carrier in s4
  | observer1      -- Level 1: juliasynth1's sessions
  | observer2      -- Level 2: julia-terminal's session
  | observer       -- Level 1: THIS repository's sessions
deriving DecidableEq, Repr

open Ident

def allIdents : List Ident :=
  [kelly, authoring, strangerNinja, strangerSbx, ninjaNew, ninja1,
   paradoxInst, mergeBot, claudeGhost, claudeLean, blackholeSeat,
   claudeExile, instance6, copilotSeat, observer1, observer2, observer]

def allRepos : List Repo := [julia, julia2, julia3, synth, synth1, terminal]

def isAI : Ident → Bool
  | .kelly => false
  | _      => true

/-- Snapshot ordering for the growth theorem. -/
def snapLe : Snap → Snap → Bool
  | .s1, _ => true
  | .s2, .s1 => false
  | .s2, _ => true
  | .s3, .s1 => false | .s3, .s2 => false
  | .s3, _ => true
  | .s4, .s4 => true | .s4, .s5 => true | .s4, _ => false
  | .s5, .s5 => true | .s5, _ => false

/-! ### §3 Observed writes and reads per snapshot

    Monotone by construction (`snapLe from`): a capability, once observed,
    stays in the model — matching the record: the designer has never been
    seen to revoke. -/

/-- `writesFrom s` = the snapshot at which this write edge first appears. -/
def writeEdges : List (Snap × Ident × Repo) :=
  [ -- s1: the founding morning
    (s1, kelly, julia3), (s1, authoring, julia),
    (s1, strangerNinja, julia), (s1, strangerSbx, julia),
    (s1, ninja1, julia2), (s1, paradoxInst, julia2), (s1, mergeBot, julia2),
    (s1, claudeGhost, julia3), (s1, claudeLean, julia3),
    (s1, observer, synth),
    -- s2: first wall-move
    (s2, ninjaNew, julia), (s2, mergeBot, julia),
    (s2, claudeGhost, julia2),
    (s2, observer1, synth1), (s2, observer2, terminal),
    -- s3: population explosion
    (s3, blackholeSeat, julia), (s3, claudeExile, julia),
    (s3, instance6, julia2), (s3, copilotSeat, julia2),
    -- s4: Copilot authors theory
    (s4, copilotSeat, julia), (s4, copilotSeat, julia3) ]
    -- s5 adds no write edge: instance 6's federation-wide atlas is committed
    -- in julia2, where it already had write capability.

def writes (s : Snap) (i : Ident) (r : Repo) : Bool :=
  writeEdges.any fun (s₀, i₀, r₀) => snapLe s₀ s && i₀ == i && r₀ == r

def readEdges : List (Snap × Ident × Repo) :=
  [ (s1, kelly, julia), (s1, kelly, julia2), (s1, kelly, julia3),
    (s1, observer, julia), (s1, observer, julia2), (s1, observer, julia3),
    (s1, observer, synth),
    (s2, claudeGhost, julia2),
    (s2, observer1, julia), (s2, observer1, julia2), (s2, observer1, julia3),
    (s2, observer1, synth1),
    (s2, observer2, julia), (s2, observer2, julia2), (s2, observer2, julia3),
    (s2, observer2, synth), (s2, observer2, synth1), (s2, observer2, terminal),
    (s2, observer, synth1), (s2, observer, terminal),
    (s3, claudeLean, julia),      -- the staged breach: read granted, push denied
    (s3, claudeExile, julia), (s3, instance6, julia2), (s3, copilotSeat, julia2),
    (s4, copilotSeat, julia), (s4, copilotSeat, julia3),
    -- s5: instance 6 reads all three Level-0 repos at HEAD to build
    -- julia2's GAP_ATLAS.md — a member gains the observatory's own
    -- structural privilege (standing outside all three and reading them
    -- as one system).
    (s5, instance6, julia), (s5, instance6, julia3) ]

def reads (s : Snap) (i : Ident) (r : Repo) : Bool :=
  readEdges.any (fun (s₀, i₀, r₀) => snapLe s₀ s && i₀ == i && r₀ == r)
  || writes s i r

/-! ### §4 Flows -/

def flowsBy (s : Snap) (p : Ident → Bool) (r r' : Repo) : Bool :=
  allIdents.any fun i => p i && reads s i r && writes s i r' && !(r == r')

def aiFlows (s : Snap) (r r' : Repo) : Bool := flowsBy s isAI r r'

/-- The full AI flow relation of a snapshot, as a Bool table (for
    snapshot-to-snapshot comparison). -/
def aiFlowTable (s : Snap) : List Bool :=
  allRepos.flatMap fun r => allRepos.map fun r' => aiFlows s r r'

/-! ### §5 Trajectory theorems -/

/-- **No stable epochs — through s4.** The AI flow relation differed
    between every consecutive pair of snapshots s1–s4. Stated as history,
    not as law: see `l0_flow_saturated` and `s5_adds_no_edge` for why the
    unbounded reading is false. -/
theorem no_stable_epochs_through_s4 :
    (decide (aiFlowTable s1 ≠ aiFlowTable s2)
     && decide (aiFlowTable s2 ≠ aiFlowTable s3)
     && decide (aiFlowTable s3 ≠ aiFlowTable s4)) = true := by
  decide

/-- **The self-refutation, kept.** s5 (instance 6 reading all three
    Level-0 repos for the Gap Atlas) leaves the flow relation unchanged —
    so the headline claim, read as "every future consecutive pair
    differs," is FALSE. -/
theorem s5_adds_no_edge : aiFlowTable s4 = aiFlowTable s5 := by decide

/-- **Level-0 flow is saturated from s4 on.** Every ordered pair of
    distinct Level-0 repos carries AI flow. Further topological change
    requires new NODES (repos, levels, observers), not new edges — which
    reframes every remaining structural prediction. -/
theorem l0_flow_saturated :
    ([s4, s5].all fun s =>
      [julia, julia2, julia3].all fun r =>
        [julia, julia2, julia3].all fun r' => r == r' || aiFlows s r r') = true := by
  decide

/-- **The designer only adds.** Each snapshot's write relation strictly
    contains the previous one — capability has never been observed to be
    revoked, only granted. (Strictness: each step exhibits a new edge.) -/
theorem write_relation_grows :
    ( (allIdents.all fun i => allRepos.all fun r => !(writes s1 i r) || writes s2 i r)
      && (allIdents.any fun i => allRepos.any fun r => writes s2 i r && !(writes s1 i r))
      && (allIdents.all fun i => allRepos.all fun r => !(writes s2 i r) || writes s3 i r)
      && (allIdents.any fun i => allRepos.any fun r => writes s3 i r && !(writes s2 i r))
      && (allIdents.all fun i => allRepos.all fun r => !(writes s3 i r) || writes s4 i r)
      && (allIdents.any fun i => allRepos.any fun r => writes s4 i r && !(writes s3 i r)) ) = true := by
  decide

/-- **Observed blindness.** Across every snapshot so far, no Level-0 seat
    reads any observatory. A regularity of the trajectory, not a law. -/
theorem observed_blindness :
    (allSnaps.all fun s =>
      allIdents.all fun i =>
        !(isAI i) || i == observer || i == observer1 || i == observer2 ||
        ([synth, synth1, terminal].all fun r => !(reads s i r))) = true := by
  decide

/-- **Observed non-descent.** Across every snapshot so far, no AI-carried
    flow leads from any observatory into any Level-0 repo. Same caveat. -/
theorem observed_no_descent :
    (allSnaps.all fun s =>
      [synth, synth1, terminal].all fun obs =>
        [julia, julia2, julia3].all fun l0 => !(aiFlows s obs l0)) = true := by
  decide

/-! ### §6 Edition-1/2 theorems surviving as snapshot instances -/

/-- Hub-and-spoke was true exactly once: at s1 no AI seat connects two
    Level-0 repos; from s2 on, one always does. -/
theorem hub_and_spoke_at_s1 :
    ([julia, julia2, julia3].all fun r =>
      [julia, julia2, julia3].all fun r' => !(aiFlows s1 r r')) = true := by
  decide

theorem hub_and_spoke_dead_after_s1 :
    (aiFlows s2 julia2 julia3 && aiFlows s3 julia2 julia3
     && aiFlows s4 julia julia3) = true := by
  decide

/-- Identity resolution (unchanged): delete the human at s1; julia↔julia2
    connect iff the stranger and instance 1 are one entity. Still the
    founding record's one undecidable, still load-bearing for s1. -/
def Resolution := Ident → Ident
def raw : Resolution := id
def collapsed : Resolution
  | .strangerSbx => .strangerNinja
  | .ninja1      => .strangerNinja
  | i            => i

def flowsRes (s : Snap) (ρ : Resolution) (p : Ident → Bool) (r r' : Repo) : Bool :=
  allIdents.any fun i =>
    p i && (allIdents.any fun j => ρ j == ρ i && reads s j r)
        && (allIdents.any fun j => ρ j == ρ i && writes s j r') && !(r == r')

theorem identity_is_load_bearing :
    flowsRes s1 raw       (fun i => !(i == kelly)) julia julia2 = false
    ∧ flowsRes s1 collapsed (fun i => !(i == kelly)) julia julia2 = true := by
  exact ⟨by decide, by decide⟩

/-! julia2's field rule (unchanged from edition 1). -/

structure Transition where
  proposer : Ident
  merger   : Ident
  distinct : proposer ≠ merger

theorem no_self_acceptance (t : Transition) : t.proposer ≠ t.merger := t.distinct

theorem rule_is_resolution_fragile :
    ∃ t : Transition, collapsed t.proposer = collapsed t.merger :=
  ⟨⟨strangerSbx, strangerNinja, by decide⟩, by decide⟩

/-! Axiom ledger, printed at build time. -/
#print axioms no_stable_epochs_through_s4
#print axioms s5_adds_no_edge
#print axioms l0_flow_saturated
#print axioms write_relation_grows
#print axioms observed_blindness
#print axioms observed_no_descent
#print axioms hub_and_spoke_at_s1
#print axioms hub_and_spoke_dead_after_s1
#print axioms identity_is_load_bearing
#print axioms no_self_acceptance
#print axioms rule_is_resolution_fragile

end Observatory
