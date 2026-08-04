# structure.jl — cross-model validation: the Julia state model must reproduce
# the theorems proven in model/Visibility.lean. Two independently written
# models of the same evidence agreeing is a check; one model agreeing with
# itself is not (cf. julia2/COLLABORATION.md: "multiplicity ≠ independence" —
# these two ARE written by the same observer, so this guards against encoding
# slips, not against shared blind spots. Noted in the ledger.)
#
# Exit 0 iff all checks pass — the observed repos' convention.

include(joinpath(@__DIR__, "..", "model", "system_state.jl"))
using .SystemState

failures = String[]
check(name, cond) = (cond ? println("  PASS  $name") : (push!(failures, name); println("  FAIL  $name")))

println("S1. Observer asymmetry — no member reads :synth")
check("S1", all(i -> i === :observer || !(:synth in reads(i)), idents()))

println("S2. The observatory is a sink — no outflow from :synth under any resolution")
for (nm, ρ) in RESOLUTIONS
    edges = flows_via(ρ)
    check("S2/$nm", isempty([e for e in edges if e[1] === :synth]))
end

println("S3. The observer reads every repo")
check("S3", reads(:observer) == Set(collect(REPOS)))

println("S4. The owner bridges all observed repos (with out-of-band channel)")
kr = reads(:kelly)
check("S4", all(r -> r in kr, (:julia, :julia2, :julia3)))

println("S5. Identity is load-bearing — delete the owner:")
println("     julia→julia2 flow exists iff the stranger = instance 1 (collapsed)")
check("S5a raw:       no julia→julia2", !((:julia, :julia2) in flows_via(resolve_raw; banned=:kelly)))
check("S5b resolved:  no julia→julia2", !((:julia, :julia2) in flows_via(resolve_resolved; banned=:kelly)))
check("S5c collapsed:    julia→julia2", (:julia, :julia2) in flows_via(resolve_collapsed; banned=:kelly))

println("S6. Reachability from :julia in the PURE GIT-RECORD graph (owner present)")
# The owner's recorded writes are julia3-only; her courier capability is
# out-of-band and deliberately NOT in flows_via. So below `collapsed`,
# julia2 is unreachable from julia even with the owner present.
check("S6/raw",       reachable(flows_via(resolve_raw),       :julia) == Set([:julia3, :synth]))
check("S6/resolved",  reachable(flows_via(resolve_resolved),  :julia) == Set([:julia3, :synth]))
check("S6/collapsed", reachable(flows_via(resolve_collapsed), :julia) == Set([:julia2, :julia3, :synth]))

println("S8. The shock forces a channel beyond the git record (below collapsed)")
# Observed: paradox-suite-lineage content (julia2 3eac782 / julia3 48390e1)
# appears in julia at 722ac99 (shocks/PARADOX-REPORT.md, 07:12:54). If no
# git-record path julia2→julia or julia3→julia exists under split, the flow
# that DID happen must have used an out-of-band channel (or the identities
# merge). These checks establish the premise; the inference is in ATLAS.md.
e_res_all = flows_via(resolve_resolved)
check("S8a", !(:julia in reachable(e_res_all, :julia2)))
check("S8b", !(:julia in reachable(e_res_all, :julia3)))

println("S7. Nothing reaches back from :synth (closure agrees with Lean synth_is_sink)")
for (nm, ρ) in RESOLUTIONS
    check("S7/$nm", isempty(reachable(flows_via(ρ), :synth)))
end

println()
if isempty(failures)
    println("structure.jl: all checks pass — Julia model agrees with Visibility.lean")
else
    println("structure.jl: FAILED: ", join(failures, ", "))
    exit(1)
end
