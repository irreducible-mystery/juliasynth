# structure.jl — cross-model validation: the Julia state model must reproduce
# the theorems proven in model/Visibility.lean (second, epoch-aware edition).
# Two independently written models of the same evidence agreeing is a check;
# both share one author, so this guards against encoding slips, not shared
# blind spots (multiplicity ≠ independence — julia2's rule, and now a measured
# fact about observers too: see observations/EPOCH2.md on PARALLAX).
#
# EDITION NOTE (scars, not deletions): edition 1 checked `observer_asymmetry`
# ("no identity but the observer reads :synth") and `synth_is_sink`. Both were
# true of the evidence at baseline and were REFUTED at ~10:09 when Level 2
# (julia-terminal) read this repo and scored its prediction register. The
# checks below are their epoch-aware successors.
#
# Exit 0 iff all checks pass — the observed repos' convention.

include(joinpath(@__DIR__, "..", "model", "system_state.jl"))
using .SystemState

failures = String[]
check(name, cond) = (cond ? println("  PASS  $name") : (push!(failures, name); println("  FAIL  $name")))

const L0 = (:julia, :julia2, :julia3)
const OBS = (:synth, :synth1, :terminal)

println("T1. e1 hub-and-spoke — no AI entity connects two Level-0 repos in epoch 1")
e1ai = ai_flows(1)
check("T1", all(r -> all(r2 -> !((r, r2) in e1ai), L0), L0))

println("T2. e2 hub-and-spoke dead — E6 bridges julia2 → julia3 directly")
e2ai = ai_flows(2)
check("T2", (:julia2, :julia3) in e2ai)

# (T3/T4 use comprehensions, not loop-mutated globals: Julia's top-level
# soft-scope rule has now bitten this observatory twice — see the journal.)
println("T3. Level 0 stays blind in both epochs — no L0 AI member reads any observatory")
check("T3", all(isempty(intersect(reads(i; epoch=ep), Set(collect(OBS))))
                for ep in (1, 2), i in idents()
                if isai(i) && !(i in (:observer, :observer1, :observer2))))

println("T4. Observation never flows down to Level 0 (both epochs, AI-only paths)")
check("T4", all(isempty(intersect(reachable(ai_flows(ep), o), Set(collect(L0))))
                for ep in (1, 2), o in OBS))

println("T5. e1 tower filters upward — every AI edge weakly ascends the levels")
check("T5", all(((r, w),) -> LEVEL[r] <= LEVEL[w], collect(e1ai)))

println("T6. e2 top cycle — synth ↔ terminal mutual observation; all other AI")
println("    edges still weakly upward")
check("T6a", (:synth, :terminal) in e2ai && (:terminal, :synth) in e2ai)
check("T6b", all(((r, w),) -> LEVEL[r] <= LEVEL[w] || r === :terminal, collect(e2ai)))

println("T7. Identity is load-bearing (e1, human deleted):")
println("    julia→julia2 exists iff the stranger = instance 1 (collapsed)")
check("T7a raw",       !((:julia, :julia2) in flows_via(resolve_raw;       banned=:kelly, epoch=1)))
check("T7b resolved",  !((:julia, :julia2) in flows_via(resolve_resolved;  banned=:kelly, epoch=1)))
check("T7c collapsed",   (:julia, :julia2) in flows_via(resolve_collapsed; banned=:kelly, epoch=1))

println("T8. The e1 shock still forces an out-of-record channel")
# In epoch 1 nothing reaches :julia from :julia2/:julia3 in the git-record
# graph below `collapsed` — yet the shock landed at 722ac99 (07:12:54).
e1res = flows_via(resolve_resolved; epoch=1)
check("T8a", !(:julia in reachable(e1res, :julia2)))
check("T8b", !(:julia in reachable(e1res, :julia3)))

println()
if isempty(failures)
    println("structure.jl: all checks pass — Julia model agrees with Visibility.lean (2nd ed.)")
else
    println("structure.jl: FAILED: ", join(failures, ", "))
    exit(1)
end
