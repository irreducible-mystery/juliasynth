# structure.jl — cross-model validation, EDITION 3: the Julia state model
# must reproduce the trajectory theorems of model/Visibility.lean (3rd ed.).
# Both models share one author; agreement guards against encoding slips,
# not shared blind spots (multiplicity ≠ independence — measured fact).
#
# Edition history (scars, not deletions): ed.1 proved the observatory was an
# invisible sink — refuted when Level 2 read this repo. Ed.2 proved
# epoch-aware tower theorems — overtaken when the population exploded and
# epochs stopped stabilizing. Ed.3's headline is that instability itself.
#
# Exit 0 iff all checks pass — the observed repos' convention.

include(joinpath(@__DIR__, "..", "model", "system_state.jl"))
using .SystemState

failures = String[]
check(name, cond) = (cond ? println("  PASS  $name") : (push!(failures, name); println("  FAIL  $name")))

const L0 = (:julia, :julia2, :julia3)
const OBS = (:synth, :synth1, :terminal)

println("U1. No stable epochs — the AI flow relation differs at every consecutive snapshot pair")
check("U1", all(ai_flow_table(s) != ai_flow_table(s + 1) for s in 1:3))

println("U2. The designer only adds — write relation strictly grows at every step")
grows(a, b) = all(!writes(a, i, r) || writes(b, i, r) for i in idents(), r in REPOS) &&
              any(writes(b, i, r) && !writes(a, i, r) for i in idents(), r in REPOS)
check("U2", all(grows(s, s + 1) for s in 1:3))

println("U3. Observed blindness — across ALL snapshots, no Level-0 seat reads any observatory")
check("U3", all(!reads(s, i, o) for s in SNAPS, o in OBS,
                i in idents() if isai(i) && !(i in (:observer, :observer1, :observer2))))

println("U4. Observed non-descent — across ALL snapshots, no AI flow path observatory → Level 0")
check("U4", all(isempty(intersect(reachable(ai_flows(s), o), Set(collect(L0))))
                for s in SNAPS, o in OBS))

println("U5. Hub-and-spoke held exactly once (s1), dead ever after")
check("U5a", all(!((r, w) in ai_flows(1)) for r in L0, w in L0))
check("U5b", (:julia2, :julia3) in ai_flows(2) && (:julia, :julia3) in ai_flows(4))

println("U6. Identity is load-bearing at s1 (human deleted): julia→julia2 iff collapsed")
check("U6a", !((:julia, :julia2) in flows_res(1, resolve_raw; banned=:kelly)))
check("U6b",  (:julia, :julia2) in flows_res(1, resolve_collapsed; banned=:kelly))

println("U7. The s1 shock still forces an out-of-record channel")
e1 = flows_res(1, resolve_resolved)
check("U7a", !(:julia in reachable(e1, :julia2)))
check("U7b", !(:julia in reachable(e1, :julia3)))

println()
if isempty(failures)
    println("structure.jl: all checks pass — Julia model agrees with Visibility.lean (3rd ed.)")
else
    println("structure.jl: FAILED: ", join(failures, ", "))
    exit(1)
end
