# system_state.jl — typed model of the observed four-repo system.
#
# Everything in §1–§2 is evidence: the complete commit record of the three
# observed repos (git log --all, retrieved 2026-08-04) plus the observatory's
# own charter. §3 derives access; §4 parametrizes identity resolution the same
# way model/Visibility.lean does, so the two models can be checked against
# each other. Experiments in ../experiments/ import this file.

module SystemState

using Dates

export Commit, EVENTS, IDENT_KIND, writes, reads,
       resolve_raw, resolve_resolved, resolve_collapsed, RESOLUTIONS,
       entities, flows_via, reachable, REPOS, idents,
       LEVEL, isai, ai_flows

# ── §1 The event log ────────────────────────────────────────────────────────

struct Commit
    repo::Symbol      # :julia | :julia2 | :julia3
    hash::String
    t::DateTime       # UTC
    ident::Symbol     # recorded author identity
    msg::String
end

const EVENTS = [
    # julia — the adversarial dialogue (history before 03:55 imported wholesale:
    # "Full thread history" means _00.._02 + first audits predate the repo)
    Commit(:julia,  "59c7fa2", DateTime(2026,8,4,3,55,35), :stranger_ninja, "Full thread history + emergence_03: the stranger audits the stranger"),
    Commit(:julia,  "3f95cde", DateTime(2026,8,4,4,7,51),  :authoring,       "emergence_04: move (b) taken"),
    Commit(:julia2, "24a393c", DateTime(2026,8,4,5,3,21),  :ninja1,         "F_0: Julia translation of Organized Change / Generative Fields"),
    Commit(:julia,  "c05d555", DateTime(2026,8,4,5,15,55), :stranger_ninja, "emergence_05 + RingRest.lean: debt (3) paid"),
    Commit(:julia,  "90f249a", DateTime(2026,8,4,5,34,30), :authoring,       "emergence_06: Kelly's injection"),
    Commit(:julia2, "3eac782", DateTime(2026,8,4,6,1,0),   :paradox_inst,    "F_0 -> F_1 candidate: cross-domain paradox suite + transcript"),
    Commit(:julia2, "213304b", DateTime(2026,8,4,6,19,38), :merge_bot,       "F_0 -> F_1: merge PR #2"),
    Commit(:julia3, "4954a3f", DateTime(2026,8,4,6,21,18), :kelly,           "Add Julia + Lean toolchain setup"),
    Commit(:julia,  "127b8ef", DateTime(2026,8,4,6,35,29), :stranger_sbx,   "emergence_07 + RingRest Section 2: the handoff paid"),
    Commit(:julia3, "48390e1", DateTime(2026,8,4,7,2,42),  :kelly,           "Translate ~40 paradoxes into runnable Julia"),
    Commit(:julia2, "9c159a6", DateTime(2026,8,4,7,11,20), :paradox_inst,    "F_1 -> F_2 candidate: Part 4 extension, Broome deep dive"),
    Commit(:julia,  "722ac99", DateTime(2026,8,4,7,12,54), :authoring,       "emergence_08 + shocks/: the paradox taxonomy re-typed"),
    Commit(:julia2, "e251aa3", DateTime(2026,8,4,7,23,43), :merge_bot,       "F_1 -> F_2: merge PR #3"),
    Commit(:julia3, "ea552d2", DateTime(2026,8,4,7,42,51), :kelly,           "Add expressibility essay, with questions for Lean"),
    Commit(:julia3, "c9727a0", DateTime(2026,8,4,7,53,3),  :claude_lean,    "Scaffold Lake package for Lean paradox suite"),
    Commit(:julia,  "35479fe", DateTime(2026,8,4,7,54,9),  :stranger_sbx,   "emergence_09 + RingRest Section 3: (*) closed"),
    Commit(:julia3, "092be9f", DateTime(2026,8,4,7,53,40), :kelly,           "Merge PR #1 (as irreducible-mystery)"),
]

const REPOS = (:julia, :julia2, :julia3, :synth, :synth1, :terminal)

"Tower level per repo: 0 = observed system, 1 = observers, 2 = observer of observers."
const LEVEL = Dict(:julia => 0, :julia2 => 0, :julia3 => 0,
                   :synth => 1, :synth1 => 1, :terminal => 2)

# ── §2 Identities ───────────────────────────────────────────────────────────

const IDENT_KIND = Dict(               # entity labels per observations/identity_access.md
    :kelly          => :human,     # E1  kellyjs1313@gmail.com / irreducible-mystery
    :authoring      => :ai,        # E2  authoring@invalid            (julia)
    :stranger_ninja => :ai,        # E3a superninja@ninjatech.ai      (julia)
    :stranger_sbx   => :ai,        # E3b auditor@sandbox              (julia)
    :ninja1         => :ai,        # E4  superninja@ninjatech.ai      (julia2)
    :paradox_inst   => :ai,        # E5  paradox-instance@agents.local (julia2)
    :merge_bot      => :bot,       # E8  superninja-app[bot]          (julia2)
    :claude_ghost   => :ai,        # E6  Claude session ...rhKo, ghost-writes julia3 under E1's identity
    :claude_lean    => :ai,        # E7  Claude session ...V3uR, noreply@anthropic.com (julia3)
    :ninja_new      => :ai,        # E3c? plain "SuperNinja": julia's e2 MC branch + adversarial sweep
    :observer1      => :observer,  # juliasynth1's session ...zpGue6 (Level 1 twin)
    :observer2      => :observer,  # julia-terminal's session (Level 2)
    :observer       => :observer,  # this repository (Level 1)
)

isai(i::Symbol) = i !== :kelly     # bots and observers included: all but the human

idents() = collect(keys(IDENT_KIND))

# ── §3 Access, derived from the record ──────────────────────────────────────

"writes(i; epoch) — repos where identity i authored, ghost-wrote, or merged.
epoch 1 = founding morning; epoch 2 adds the post-09:46 policy changes
(evidence: observations/EPOCH2.md)."
function writes(i::Symbol; epoch::Int=1)
    base = if i === :observer
        Set([:synth])
    elseif i === :claude_ghost
        # ghost-writes julia3 under E1's identity (trailers on 4954a3f, 48390e1, ea552d2)
        Set([:julia3])
    else
        Set(c.repo for c in EVENTS if c.ident === i)
    end
    epoch >= 2 || return base
    extra = Dict(
        :ninja_new    => Set([:julia]),     # 35aa9b4..4739ac6 (MC branch + sweep)
        :merge_bot    => Set([:julia]),     # julia PRs #1/#2 (272de2d, abdec49)
        :claude_ghost => Set([:julia2]),    # b642370, trailer ...rrhKo ("instance 3")
        :observer1    => Set([:synth1]),    # f0adad4
        :observer2    => Set([:terminal]),  # 16ec28e
    )
    union(base, get(extra, i, Set{Symbol}()))
end

"reads(i; epoch) — superset of writes. Observed behavior only: the owner's
CAPABILITY covers every repo at all times (she owns the org); this function
records reads in evidence. Epoch 2: observer2 read both Level-1 repos and
scored this repo's register; this session read synth1 and terminal."
function reads(i::Symbol; epoch::Int=1)
    i === :kelly && return Set([:julia, :julia2, :julia3])
    if i === :observer
        return epoch >= 2 ? Set(collect(REPOS)) :
                            Set([:julia, :julia2, :julia3, :synth])
    end
    epoch >= 2 || return writes(i; epoch)
    extra = Dict(
        :claude_ghost => Set([:julia2]),   # read julia2's suite to write TENSIONS.md
        :observer1    => Set([:julia, :julia2, :julia3, :synth1]),
        :observer2    => Set([:julia, :julia2, :julia3, :synth, :synth1, :terminal]),
    )
    union(writes(i; epoch), get(extra, i, Set{Symbol}()))
end

# ── §4 Identity resolution, three levels (mirrors Visibility.lean §3) ───────

"raw — git metadata at face value: all identities distinct."
resolve_raw(i::Symbol) = i
"resolved — the stranger's two git configs are one agent-thread (verified merge, medium-high)."
resolve_resolved(i::Symbol) = i === :stranger_sbx ? :stranger_ninja : i
"collapsed — additionally julia's stranger = julia2's instance 1 (the undecidable merge)."
resolve_collapsed(i::Symbol) =
    i in (:stranger_sbx, :ninja1) ? :stranger_ninja : i

const RESOLUTIONS = [
    ("raw", resolve_raw), ("resolved", resolve_resolved), ("collapsed", resolve_collapsed),
]

"entities(ρ) — canonical entity set under resolution ρ."
entities(ρ) = Set(ρ(i) for i in idents())

"flows_via(ρ; banned, epoch, only_ai) — directed repo→repo one-step flow:
some admitted entity reads the source and writes the destination."
function flows_via(ρ; banned::Union{Nothing,Symbol}=nothing, epoch::Int=1, only_ai::Bool=false)
    edges = Set{Tuple{Symbol,Symbol}}()
    for e in entities(ρ)
        (banned !== nothing && e === ρ(banned)) && continue
        group = [i for i in idents() if ρ(i) === e]
        only_ai && !all(isai, group) && continue
        er = union(Set{Symbol}(), (reads(i; epoch) for i in group)...)
        ew = union(Set{Symbol}(), (writes(i; epoch) for i in group)...)
        for r in er, w in ew
            r === w || push!(edges, (r, w))
        end
    end
    edges
end

"ai_flows(epoch) — AI-carried one-step flow edges (human excluded), raw resolution."
ai_flows(epoch::Int) = flows_via(resolve_raw; epoch, only_ai=true)

"reachable(edges, from) — transitive closure of the flow relation."
function reachable(edges, from::Symbol)
    seen = Set([from])
    frontier = [from]
    while !isempty(frontier)
        r = pop!(frontier)
        for (a, b) in edges
            a === r && !(b in seen) && (push!(seen, b); push!(frontier, b))
        end
    end
    delete!(seen, from)
    seen
end

end # module
