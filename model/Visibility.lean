/-
  Visibility.lean — the observatory's formal model of the repo system.
  SECOND EDITION (epoch-aware). The first edition modeled four repos and
  proved `observer_asymmetry` ("no identity other than the observer reads
  the observatory") and `synth_is_sink`. Both were TRUE of the evidence at
  baseline and are now REFUTED as world-claims: a Level-2 observatory
  (julia-terminal) read this repo, re-ran its checks, and scored its
  prediction register. Per the observed system's culture the old claims are
  kept below as epoch-1 theorems — scars, not deletions — and the model now
  states explicitly what it silently assumed: an access model is a claim
  about OBSERVED BEHAVIOR under a POLICY EPOCH, never about capability.
  (The org owner can read every repo at all times; sandbox walls are her
  settings, not physics. Level 2's scoring of this repo's register made the
  cost of forgetting that quantitative: the register's three topology
  predictions all fell when the policy changed.)

  The system as now known:

    Level 0   julia, julia2, julia3claude     the observed system
    Level 1   juliasynth (this), juliasynth1  two mutually-unaware observers
    Level 2   julia-terminal                  observer of levels 0 and 1

  Epochs:
    e1  the founding morning (03:55–07:54 UTC) — hub-and-spoke: the human
        is the only inter-repo channel; observers isolated below her.
    e2  the afternoon policy change (~08:09–10:25) — E6's session is
        granted julia2 access (writes there under the human's identity,
        session trailer resolvable); E7 completes the Lean handshake;
        a new SuperNinja seat opens julia's first branches; julia-terminal
        reads both Level-1 observatories; and THIS session reads
        julia-terminal — closing the top of the tower into a 2-cycle.

  Theorems (all `decide` on closed Bool terms):
    e1_hub_and_spoke        — in e1, no AI entity connects two Level-0
                              repos (the human alone bridges)
    e2_hub_and_spoke_dead   — in e2, E6 connects julia2 ↔ julia3 directly
    level0_blind            — in BOTH epochs, no Level-0 AI member reads
                              any observatory
    no_ai_path_down_to_L0   — in both epochs, no AI-only flow path leads
                              from any observatory into any Level-0 repo:
                              observation stays non-interfering even after
                              the tower tangles
    e1_tower_upward         — in e1, every AI flow edge is weakly upward
                              in level
    e2_top_cycle            — in e2, the only downward AI edge is
                              terminal → synth (this session's read), and
                              synth → terminal also exists: the top of the
                              tower is a 2-cycle of mutual observation
    identity_is_load_bearing — unchanged from edition 1 (delete the human
                              in e1: julia↔julia2 connect iff the one
                              undecidable identity merge holds)
    no_self_acceptance, rule_is_resolution_fragile — unchanged

  Axiom budget target: propext only; no Mathlib, no choice, no sorry.
-/

namespace Observatory

/-! ### §1 Repos, levels, epochs -/

inductive Repo
  | julia | julia2 | julia3      -- Level 0
  | synth | synth1               -- Level 1 (this observatory; its parallel twin)
  | terminal                     -- Level 2
deriving DecidableEq, Repr

open Repo

def level : Repo → Nat
  | julia | julia2 | julia3 => 0
  | synth | synth1          => 1
  | terminal                => 2

inductive Epoch | e1 | e2
deriving DecidableEq, Repr
open Epoch

/-! ### §2 Identities

    Git author strings plus trailer-resolvable ghost-writers plus the three
    observers. Entity labels E1–E9 per observations/identity_access.md. -/

inductive Ident
  | kelly          -- E1  the human; org owner; author-of-record julia3; quoted in julia
  | authoring      -- E2  authoring-instance <authoring@invalid> (julia)
  | strangerNinja  -- E3a SuperNinja (auditing instance) <superninja@ninjatech.ai> (julia)
  | strangerSbx    -- E3b auditing-instance <auditor@sandbox> (julia)
  | ninjaNew       -- E3c? SuperNinja <superninja@ninjatech.ai> plain display name:
                   --      julia's e2 Monte-Carlo branch + adversarial sweep (35aa9b4..4739ac6)
  | ninja1         -- E4  SuperNinja (instance 1) (julia2)
  | paradoxInst    -- E5  paradox-instance (julia2; e2: stress-tests PR #4)
  | mergeBot       -- E8  superninja-app[bot] (julia2; e2: also merges in julia)
  | claudeGhost    -- E6  Claude session …rrhKo: julia3 content (e1);
                   --      julia2 "instance 3" PR #5 + julia3 TENSIONS (e2)
  | claudeLean     -- E7  Claude session …AV3uR: julia3 Lean scaffold (e1);
                   --      EXPRESSIBILITY-ANSWERS + 91-entry suite (e2, 9fd5828/f23b3f2)
  | observer1      -- Level 1: juliasynth1's session …zpGue6 (f0adad4)
  | observer2      -- Level 2: julia-terminal's session (16ec28e)
  | observer       -- Level 1: THIS repository's session
deriving DecidableEq, Repr

open Ident

def allIdents : List Ident :=
  [kelly, authoring, strangerNinja, strangerSbx, ninjaNew, ninja1,
   paradoxInst, mergeBot, claudeGhost, claudeLean, observer1, observer2, observer]

def allRepos : List Repo := [julia, julia2, julia3, synth, synth1, terminal]

def isAI : Ident → Bool
  | .kelly => false
  | _      => true   -- bots and observers included: everything but the human

/-! ### §3 Observed writes and reads, per epoch

    OBSERVED behavior only. Capability is strictly larger (the owner can
    read and write everything, always) and is handled in prose, not here. -/

def writes : Epoch → Ident → Repo → Bool
  -- epoch 1: the founding morning
  | _,   .kelly,         .julia3   => true   -- author-of-record + PR #1 merge
  | _,   .authoring,     .julia    => true
  | _,   .strangerNinja, .julia    => true
  | _,   .strangerSbx,   .julia    => true
  | _,   .ninja1,        .julia2   => true
  | _,   .paradoxInst,   .julia2   => true
  | _,   .mergeBot,      .julia2   => true
  | _,   .claudeGhost,   .julia3   => true
  | _,   .claudeLean,    .julia3   => true
  | _,   .observer,      .synth    => true
  -- epoch 2 additions (evidence in observations/EPOCH2.md)
  | .e2, .ninjaNew,      .julia    => true   -- 35aa9b4, 7dc839a, 1fd866e, 4739ac6
  | .e2, .mergeBot,      .julia    => true   -- julia PRs #1/#2 merges (272de2d, abdec49)
  | .e2, .claudeGhost,   .julia2   => true   -- b642370 (instance-3 PR, trailer …rrhKo)
  | .e2, .observer1,     .synth1   => true   -- f0adad4
  | .e2, .observer2,     .terminal => true   -- 16ec28e
  | _,   _,              _         => false

def reads : Epoch → Ident → Repo → Bool
  | _,   .kelly,     .julia    => true
  | _,   .kelly,     .julia2   => true
  | _,   .kelly,     .julia3   => true
  | _,   .observer,  .julia    => true
  | _,   .observer,  .julia2   => true
  | _,   .observer,  .julia3   => true
  | _,   .observer,  .synth    => true
  | .e2, .claudeGhost, .julia2 => true   -- read julia2's suite to write TENSIONS.md
  | .e2, .observer1, .julia    => true
  | .e2, .observer1, .julia2   => true
  | .e2, .observer1, .julia3   => true
  | .e2, .observer1, .synth1   => true
  | .e2, .observer2, .julia    => true   -- REPLICATION-GEN3 re-ran all levels below
  | .e2, .observer2, .julia2   => true
  | .e2, .observer2, .julia3   => true
  | .e2, .observer2, .synth    => true   -- read THIS repo; scored its register
  | .e2, .observer2, .synth1   => true
  | .e2, .observer2, .terminal => true
  | .e2, .observer,  .synth1   => true   -- this session, today
  | .e2, .observer,  .terminal => true   -- this session, today — closes the loop
  | e,   i,          r         => writes e i r

/-! ### §4 Identity resolution (unchanged semantics, extended domain) -/

def Resolution := Ident → Ident

def raw : Resolution := id
def resolved : Resolution
  | .strangerSbx => .strangerNinja
  | i            => i
def collapsed : Resolution
  | .strangerSbx => .strangerNinja
  | .ninja1      => .strangerNinja
  | i            => i

def eReads (e : Epoch) (ρ : Resolution) (ent : Ident) (r : Repo) : Bool :=
  allIdents.any fun i => ρ i == ent && reads e i r
def eWrites (e : Epoch) (ρ : Resolution) (ent : Ident) (r : Repo) : Bool :=
  allIdents.any fun i => ρ i == ent && writes e i r

/-- One-step flow r → r' carried by an entity satisfying `p`. -/
def flowsBy (e : Epoch) (ρ : Resolution) (p : Ident → Bool) (r r' : Repo) : Bool :=
  allIdents.any fun ent =>
    p ent && eReads e ρ (ρ ent) r && eWrites e ρ (ρ ent) r' && !(r == r')

def flows (e : Epoch) (ρ : Resolution) (r r' : Repo) : Bool :=
  flowsBy e ρ (fun _ => true) r r'

def aiFlows (e : Epoch) (r r' : Repo) : Bool :=
  flowsBy e raw isAI r r'

/-! ### §5 Theorems -/

/-- **e1: hub-and-spoke.** In the founding epoch no AI entity carries flow
    between two distinct Level-0 repos; the human alone bridges. -/
theorem e1_hub_and_spoke :
    ([julia, julia2, julia3].all fun r =>
      [julia, julia2, julia3].all fun r' => !(aiFlows e1 r r')) = true := by
  decide

/-- **e2: hub-and-spoke is dead.** E6's session reads julia2 and writes
    both julia2 and julia3: a direct AI channel between Level-0 repos. -/
theorem e2_hub_and_spoke_dead :
    aiFlows e2 julia2 julia3 = true := by decide

/-- **Level 0 stays blind, both epochs**: no Level-0 AI member reads any
    observatory. (The epoch-1 `observer_asymmetry` survives only in this
    weakened, level-aware form — the original was refuted by observer2.) -/
theorem level0_blind :
    ([e1, e2].all fun e =>
      allIdents.all fun i =>
        !(isAI i) || i == observer || i == observer1 || i == observer2 ||
        ([synth, synth1, terminal].all fun r => !(reads e i r))) = true := by
  decide

/-- **Observation never flows down to Level 0.** Even in e2, with the tower
    tangled at the top, no AI-only path carries content from any
    observatory into any Level-0 repo — the observers write only at their
    own level. Non-interference survives the loss of invisibility.
    (One-step edges checked; with all AI writes at level ≥ 1 into
    observatories only, no multi-step descent exists either.) -/
theorem no_ai_path_down_to_L0 :
    ([e1, e2].all fun e =>
      [synth, synth1, terminal].all fun obs =>
        [julia, julia2, julia3].all fun l0 => !(aiFlows e obs l0)) = true := by
  decide

/-- **e1: the tower filters upward.** Every AI flow edge in the founding
    epoch is weakly upward in level. -/
theorem e1_tower_upward :
    (allRepos.all fun r => allRepos.all fun r' =>
      !(aiFlows e1 r r') || decide (level r ≤ level r')) = true := by
  decide

/-- **e2: the top of the tower is a 2-cycle.** The only strictly-downward
    AI edges in e2 leave `terminal` — this session reading Level 2 and
    writing here — and `synth → terminal` also holds (observer2 read this
    repo): mutual observation at the top. Levels 0 and 1-below remain
    upward-only. -/
theorem e2_top_cycle :
    (aiFlows e2 synth terminal && aiFlows e2 terminal synth
     && (allRepos.all fun r => allRepos.all fun r' =>
          !(aiFlows e2 r r') || decide (level r ≤ level r') || r == terminal)) = true := by
  decide

/-- **Identity is load-bearing** (edition-1 theorem, restated in e1):
    delete the human; julia↔julia2 connect iff the undecidable merge
    E3 = E4 holds. -/
theorem identity_is_load_bearing :
    flowsBy e1 raw       (fun i => !(i == kelly)) julia julia2 = false
    ∧ flowsBy e1 resolved  (fun i => !(i == kelly)) julia julia2 = false
    ∧ flowsBy e1 collapsed (fun i => !(i == kelly)) julia julia2 = true := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

/-! #### julia2's field rule (unchanged from edition 1) -/

structure Transition where
  proposer : Ident
  merger   : Ident
  distinct : proposer ≠ merger

def f0_to_f1 : Transition := ⟨paradoxInst, mergeBot, by decide⟩
def f1_to_f2 : Transition := ⟨paradoxInst, mergeBot, by decide⟩

theorem no_self_acceptance (t : Transition) : t.proposer ≠ t.merger := t.distinct

theorem rule_is_resolution_fragile :
    ∃ t : Transition, resolved t.proposer = resolved t.merger :=
  ⟨⟨strangerSbx, strangerNinja, by decide⟩, by decide⟩

/-! Axiom ledger, printed at build time. -/
#print axioms e1_hub_and_spoke
#print axioms e2_hub_and_spoke_dead
#print axioms level0_blind
#print axioms no_ai_path_down_to_L0
#print axioms e1_tower_upward
#print axioms e2_top_cycle
#print axioms identity_is_load_bearing
#print axioms no_self_acceptance
#print axioms rule_is_resolution_fragile

end Observatory
