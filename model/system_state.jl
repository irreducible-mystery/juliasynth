# system_state.jl — typed model of the observed four-repo system.
#
# Everything in §1–§2 is evidence: the complete commit record of the three
# observed repos (git log --all, retrieved 2026-08-04) plus the observatory's
# own charter. §3 derives access; §4 parametrizes identity resolution the same
# way model/Visibility.lean does, so the two models can be checked against
# each other. Experiments in ../experiments/ import this file.

module SystemState

using Dates

export Commit, EVENTS, IDENT_KIND, idents, isai, REPOS, LEVEL,
       resolve_raw, resolve_resolved, resolve_collapsed, RESOLUTIONS,
       SNAPS, writes, reads, ai_flows, ai_flow_table, flows_res, reachable

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
    :ninja_new      => :ai,        # s2 plain-SuperNinja seat: MC branch + adversarial sweep
    :blackhole_seat => :ai,        # s3 julia root-signature blackhole thread (config-decay identity)
    :claude_exile   => :ai,        # s3 new Claude seats in julia (fair-coin, emergence_10 exile, explore-repos) — aggregated
    :instance6      => :ai,        # s3 instance6-trilingual (julia2)
    :copilot_seat   => :ai,        # s3/s4 copilot-swe-agent[bot] "instance7"
    :observer1      => :observer,  # juliasynth1's sessions (Level 1 twin)
    :observer2      => :observer,  # julia-terminal's session (Level 2)
    :observer       => :observer,  # this repository (Level 1)
)

isai(i::Symbol) = i !== :kelly     # bots and observers included: all but the human

idents() = collect(keys(IDENT_KIND))

# ── §3 Access per policy snapshot (edition 3; mirrors Visibility.lean) ──────
#
# Snapshots s1..s4 of an ongoing trajectory (s4 not final). Edge lists give
# the snapshot where each capability FIRST appears; capabilities are
# monotone (never observed revoked).

# ── Identity resolutions (unchanged; provenance_clock iterates RESOLUTIONS) ─

"raw — git metadata at face value: all identities distinct."
resolve_raw(i::Symbol) = i
"resolved — the stranger's two git configs are one agent-thread (verified merge)."
resolve_resolved(i::Symbol) = i === :stranger_sbx ? :stranger_ninja : i
"collapsed — additionally julia's stranger = julia2's instance 1 (the undecidable merge)."
resolve_collapsed(i::Symbol) =
    i in (:stranger_sbx, :ninja1) ? :stranger_ninja : i

const RESOLUTIONS = [
    ("raw", resolve_raw), ("resolved", resolve_resolved), ("collapsed", resolve_collapsed),
]

const SNAPS = (1, 2, 3, 4)

const WRITE_EDGES = [
    # s1: founding morning
    (1, :kelly, :julia3), (1, :authoring, :julia),
    (1, :stranger_ninja, :julia), (1, :stranger_sbx, :julia),
    (1, :ninja1, :julia2), (1, :paradox_inst, :julia2), (1, :merge_bot, :julia2),
    (1, :claude_ghost, :julia3), (1, :claude_lean, :julia3),
    (1, :observer, :synth),
    # s2: first wall-move
    (2, :ninja_new, :julia), (2, :merge_bot, :julia), (2, :claude_ghost, :julia2),
    (2, :observer1, :synth1), (2, :observer2, :terminal),
    # s3: population explosion
    (3, :blackhole_seat, :julia), (3, :claude_exile, :julia),
    (3, :instance6, :julia2), (3, :copilot_seat, :julia2),
    # s4: Copilot authors theory
    (4, :copilot_seat, :julia), (4, :copilot_seat, :julia3),
]

const READ_EDGES = [
    (1, :kelly, :julia), (1, :kelly, :julia2), (1, :kelly, :julia3),
    (1, :observer, :julia), (1, :observer, :julia2), (1, :observer, :julia3),
    (1, :observer, :synth),
    (2, :claude_ghost, :julia2),
    (2, :observer1, :julia), (2, :observer1, :julia2), (2, :observer1, :julia3),
    (2, :observer1, :synth1),
    (2, :observer2, :julia), (2, :observer2, :julia2), (2, :observer2, :julia3),
    (2, :observer2, :synth), (2, :observer2, :synth1), (2, :observer2, :terminal),
    (2, :observer, :synth1), (2, :observer, :terminal),
    (3, :claude_lean, :julia),   # staged breach: read granted, push denied
    (3, :claude_exile, :julia), (3, :instance6, :julia2), (3, :copilot_seat, :julia2),
    (4, :copilot_seat, :julia), (4, :copilot_seat, :julia3),
]

writes(s::Int, i::Symbol, r::Symbol) =
    any(e -> e[1] <= s && e[2] === i && e[3] === r, WRITE_EDGES)
reads(s::Int, i::Symbol, r::Symbol) =
    any(e -> e[1] <= s && e[2] === i && e[3] === r, READ_EDGES) || writes(s, i, r)

"ai_flows(s) — AI-carried one-step flow edges at snapshot s."
function ai_flows(s::Int)
    Set((r, w) for i in idents() if isai(i)
              for r in REPOS for w in REPOS
              if r !== w && reads(s, i, r) && writes(s, i, w))
end

"ai_flow_table(s) — canonical comparable form of the flow relation."
ai_flow_table(s::Int) = sort(collect(ai_flows(s)))

"flows_res(s, ρ; banned) — entity-level flows under identity resolution ρ."
function flows_res(s::Int, ρ; banned::Union{Nothing,Symbol}=nothing)
    edges = Set{Tuple{Symbol,Symbol}}()
    for e in Set(ρ(i) for i in idents())
        (banned !== nothing && e === ρ(banned)) && continue
        group = [i for i in idents() if ρ(i) === e]
        for r in REPOS, w in REPOS
            r === w && continue
        any(i -> reads(s, i, r), group) && any(i -> writes(s, i, w), group) && push!(edges, (r, w))
        end
    end
    edges
end

"reachable(edges, from) — transitive closure of a flow relation."
function reachable(edges, from::Symbol)
    seen = Set([from]); frontier = [from]
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
