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
       entities, flows_via, reachable, REPOS, idents

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

const REPOS = (:julia, :julia2, :julia3, :synth)

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
    :observer       => :observer,  # this repository only
)

idents() = collect(keys(IDENT_KIND))

# ── §3 Access, derived from the record ──────────────────────────────────────

"writes(i) — repos in which identity i has authored, ghost-written, or merged commits."
function writes(i::Symbol)
    i === :observer && return Set([:synth])
    # E6 ghost-writes julia3claude's content commits under E1's git identity
    # (Co-Authored-By + Claude-Session trailers on 4954a3f, 48390e1, ea552d2)
    i === :claude_ghost && return Set([:julia3])
    Set(c.repo for c in EVENTS if c.ident === i)
end

"reads(i) — superset of writes: the owner reads all observed repos; the
observer reads everything; members read what they write."
function reads(i::Symbol)
    i === :kelly    && return Set([:julia, :julia2, :julia3])
    i === :observer && return Set(collect(REPOS))
    writes(i)
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

"flows_via(ρ; banned) — directed repo→repo one-step flow relation: some
non-banned entity reads the source and writes the destination."
function flows_via(ρ; banned::Union{Nothing,Symbol}=nothing)
    edges = Set{Tuple{Symbol,Symbol}}()
    for e in entities(ρ)
        (banned !== nothing && e === ρ(banned)) && continue
        group = [i for i in idents() if ρ(i) === e]
        er = union(Set{Symbol}(), (reads(i) for i in group)...)
        ew = union(Set{Symbol}(), (writes(i) for i in group)...)
        for r in er, w in ew
            r === w || push!(edges, (r, w))
        end
    end
    edges
end

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
