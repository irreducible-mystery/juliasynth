/-
  Visibility.lean — the observatory's formal model of the four-repo system.

  Observed system: three repos (julia, julia2, julia3claude) inhabited by
  members; a fourth repo (juliasynth) inhabited only by the observer.

  What is formalized here:
    §1  The recorded identities (git author strings plus the one ghost-writer
        recoverable from commit trailers) and the ground-truth commit record:
        who wrote in which repo. Every `writes` entry cites commits.
    §2  Read access, including the two asymmetries that define the system:
        the human owner reads all observed repos; the observer reads all
        four repos and writes only juliasynth; no member reads juliasynth.
    §3  Identity resolution as an explicit three-level parameter, matching
        the verified identity analysis (observations/identity_access.md):
          raw       — every recorded identity distinct (git metadata alone)
          resolved  — the stranger's two git identities merged (the
                      medium-high-confidence merge: first-person continuity
                      across superninja@ninjatech.ai and auditor@sandbox)
          collapsed — additionally E3 = E4: julia's stranger and julia2's
                      instance 1 are one SuperNinja session (the system's
                      largest UNRESOLVED merge candidate — same email,
                      different display names, no cross-references)
    §4  Information flow: repo → repo through a shared entity. The owner's
        out-of-band paste channel is deliberately excluded here and treated
        separately — the gap between this graph and the observed flows is
        itself a theorem (see experiments/structure.jl S8).
    §5  Theorems.
          observer_asymmetry     : no member reads juliasynth
          synth_is_sink          : nothing flows out of juliasynth, under
                                   ALL THREE resolutions
          observer_reads_all     : the observer sees every repo
          kelly_bridges_all      : the owner's channel connects every
                                   ordered pair of observed repos
          identity_is_load_bearing :
                                   delete the owner: julia↔julia2 connect
                                   iff the resolution is `collapsed` — the
                                   system's connectivity equals the truth
                                   value of its one undecidable identity
          no_self_acceptance     : julia2's field rule — an accepted
                                   F_n → F_n+1 names two distinct identities
          rule_is_resolution_fragile :
                                   under `collapsed`, a proposer/merger pair
                                   that is legal at the identity level can be
                                   self-acceptance at the entity level; the
                                   field rule is only as strong as identity
                                   resolution is honest. julia2 instantiates
                                   this: both merges were executed by the
                                   proposers' own platform bot.

  Axiom budget, in the observed repos' own custom: printed at the end.
  Target: propext only (decide on closed Bool terms); no Mathlib, no
  Classical.choice, no sorry.
-/

namespace Observatory

/-! ### §1 Repos and recorded identities -/

inductive Repo
  | julia   -- irreducible-mystery/julia
  | julia2  -- irreducible-mystery/julia2
  | julia3  -- irreducible-mystery/julia3claude
  | synth   -- irreducible-mystery/juliasynth (this observatory)
deriving DecidableEq, Repr

/-- Recorded identities: every author string in `git log --all` across the
    system, plus the ghost-writer session recoverable only from trailers,
    plus the two parties who write no observed commits at all (the human as
    quoted participant in julia, and the observer). Entity labels E1–E9
    follow observations/identity_access.md. -/
inductive Ident
  | kelly          -- E1  kellyjs1313 / irreducible-mystery: julia3 author-of-record + merge 092be9f
  | authoring      -- E2  authoring-instance <authoring@invalid>: julia 3f95cde, 90f249a, 722ac99
  | strangerNinja  -- E3a SuperNinja (auditing instance) <superninja@ninjatech.ai>: julia 59c7fa2, c05d555
  | strangerSbx    -- E3b auditing-instance <auditor@sandbox>: julia 127b8ef, 35479fe
  | ninja1         -- E4  SuperNinja (instance 1) <superninja@ninjatech.ai>: julia2 24a393c
  | paradoxInst    -- E5  paradox-instance <paradox-instance@agents.local>: julia2 3eac782, 9c159a6
  | mergeBot       -- E8  superninja-app[bot]: julia2 merges 213304b, e251aa3
  | claudeGhost    -- E6  Claude session 01HByswiXWe9NE6XBwgRrhKo: julia3 content commits,
                   --     git-authored as E1 with Co-Authored-By trailers (ghost-writer)
  | claudeLean     -- E7  Claude session 01FGXcB9B5JRtdjhD66AV3uR: julia3 c9727a0 (Lean scaffold)
  | observer       -- this repository's author; commits only in synth
deriving DecidableEq, Repr

open Repo Ident

def allIdents : List Ident :=
  [kelly, authoring, strangerNinja, strangerSbx, ninja1,
   paradoxInst, mergeBot, claudeGhost, claudeLean, observer]

def allRepos : List Repo := [julia, julia2, julia3, synth]

/-- Ground truth: `writes i r` iff identity `i` authored, ghost-wrote, or
    merged at least one commit in repo `r`. Kelly's julia3 write is real
    twice over: author-of-record on E6's commits and the PR #1 web merge.
    The observer's write set is its charter, enforced by the platform. -/
def writes : Ident → Repo → Bool
  | .kelly,         .julia3 => true
  | .authoring,     .julia  => true
  | .strangerNinja, .julia  => true
  | .strangerSbx,   .julia  => true
  | .ninja1,        .julia2 => true
  | .paradoxInst,   .julia2 => true
  | .mergeBot,      .julia2 => true
  | .claudeGhost,   .julia3 => true
  | .claudeLean,    .julia3 => true
  | .observer,      .synth  => true
  | _,              _       => false

/-! ### §2 Read access -/

def reads : Ident → Repo → Bool
  | .kelly,    .julia  => true   -- quoted participant; owner of the org
  | .kelly,    .julia2 => true   -- prompt-giver (TRANSCRIPT.md); owner
  | .kelly,    .julia3 => true
  | .observer, _       => true   -- total read: the observation vantage
  | i,         r       => writes i r

/-! ### §3 Identity resolution, three levels -/

def Resolution := Ident → Ident

/-- Git metadata taken at face value: all identities distinct. -/
def raw : Resolution := id

/-- The verified merge: the stranger's two git configs are one agent-thread
    (first-person continuity across _03→_07→_09; continuous toolchain;
    continuous `by_stranger` filenames). -/
def resolved : Resolution
  | .strangerSbx => .strangerNinja
  | i            => i

/-- The undecidable merge on top: julia's stranger = julia2's instance 1
    (shared superninja@ninjatech.ai; interleaved timestamps permit it;
    nothing inside the repos decides it). -/
def collapsed : Resolution
  | .strangerSbx => .strangerNinja
  | .ninja1      => .strangerNinja
  | i            => i

def allResolutions : List Resolution := [raw, resolved, collapsed]

def eReads (ρ : Resolution) (e : Ident) (r : Repo) : Bool :=
  allIdents.any fun i => ρ i == e && reads i r

def eWrites (ρ : Resolution) (e : Ident) (r : Repo) : Bool :=
  allIdents.any fun i => ρ i == e && writes i r

/-! ### §4 Information flow (git-record channel only) -/

def flowsVia (ρ : Resolution) (banned : Option Ident) (r r' : Repo) : Bool :=
  allIdents.any fun e =>
    (match banned with | some b => !(ρ e == ρ b) | none => true)
    && eReads ρ (ρ e) r && eWrites ρ (ρ e) r'

def flows (ρ : Resolution) (r r' : Repo) : Bool := flowsVia ρ none r r'

/-! ### §5 Theorems -/

/-- **Observer asymmetry.** No identity other than the observer reads the
    observatory. The founding fact of juliasynth. -/
theorem observer_asymmetry :
    (allIdents.all fun i => i == observer || !(reads i synth)) = true := by
  decide

/-- **The observatory is a sink** under all three resolutions: the only
    reader of synth writes nowhere else. Non-interference as computation. -/
theorem synth_is_sink :
    (allResolutions.all fun ρ =>
      allRepos.all fun r => r == synth || !(flows ρ synth r)) = true := by
  decide

/-- **The observer sees every repo.** Total read, minimal write. -/
theorem observer_reads_all :
    (allRepos.all fun r => reads observer r) = true := by
  decide

/-- **The owner bridges everything observable.** Kelly reads all three
    observed repos; granting her out-of-band channel (read r, paste into a
    session writing r'), every ordered pair of observed repos is connected
    through her alone. The flows analysis confirms every cross-repo flow
    that actually occurred is human-ferried. -/
def kellyChannel (r r' : Repo) : Bool := reads kelly r && (reads kelly r' || writes kelly r')

theorem kelly_bridges_all :
    ([julia, julia2, julia3].all fun r =>
      [julia, julia2, julia3].all fun r' => kellyChannel r r') = true := by
  decide

/-- **Identity is load-bearing.** Delete the owner from the git-record
    graph. julia↔julia2 connectivity now equals the truth value of the one
    undecidable identity question: `raw` and `resolved` say disconnected,
    `collapsed` says connected. The record inside the repos cannot
    distinguish these resolutions — so the system's connectivity structure
    is undecidable from inside. -/
theorem identity_is_load_bearing :
    flowsVia raw       (some kelly) julia julia2 = false
    ∧ flowsVia resolved  (some kelly) julia julia2 = false
    ∧ flowsVia collapsed (some kelly) julia julia2 = true := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

/-! #### julia2's field rule, formalized

    COLLABORATION.md: "a transformation operator must not accept its own
    change." An accepted transition F_n → F_{n+1} is a (proposer, merger)
    pair with proposer ≠ merger — enforced here as a type invariant. -/

structure Transition where
  proposer : Ident
  merger   : Ident
  distinct : proposer ≠ merger

/-- The two recorded transitions. F_0→F_1: proposed by paradox-instance
    (3eac782), merged by the bot (PR #2). F_1→F_2: proposed by
    paradox-instance (9c159a6), merged by the bot (PR #3). -/
def f0_to_f1 : Transition := ⟨paradoxInst, mergeBot, by decide⟩
def f1_to_f2 : Transition := ⟨paradoxInst, mergeBot, by decide⟩

/-- **No self-acceptance**, by construction: a self-accepted transition is
    untypeable. -/
theorem no_self_acceptance (t : Transition) : t.proposer ≠ t.merger := t.distinct

/-- **The rule is resolution-fragile.** A transition legal at the identity
    level can collapse to self-acceptance at the entity level: witness a
    hypothetical proposal by the stranger's sandbox identity merged by its
    ninja identity — distinct identities, one entity under `resolved`.
    julia2's practice instantiates the *social* version: both real merges
    were executed by superninja-app[bot], the proposers' own platform. The
    field rule is only as strong as identity resolution is honest. -/
theorem rule_is_resolution_fragile :
    ∃ t : Transition, resolved t.proposer = resolved t.merger :=
  ⟨⟨strangerSbx, strangerNinja, by decide⟩, by decide⟩

/-- Corollary shape used by the atlas: if every party resolves to one
    entity, any transition witnesses the collapse of multiplicity. -/
theorem single_entity_stalls (ρ : Resolution) (t : Transition)
    (h : ρ t.proposer = ρ t.merger) :
    ∃ i j : Ident, i ≠ j ∧ ρ i = ρ j :=
  ⟨t.proposer, t.merger, t.distinct, h⟩

/-! Axiom ledger, printed at build time (the observed repos' custom). -/
#print axioms observer_asymmetry
#print axioms synth_is_sink
#print axioms observer_reads_all
#print axioms kelly_bridges_all
#print axioms identity_is_load_bearing
#print axioms no_self_acceptance
#print axioms rule_is_resolution_fragile
#print axioms single_entity_stalls

end Observatory
