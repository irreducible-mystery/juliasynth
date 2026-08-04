# provenance_clock.jl — timeline forensics on the complete commit record.
#
# Questions this experiment answers from timestamps alone:
#   C1. How long did the whole observed system take to produce its record?
#   C2. What is the repo interleaving pattern — sequential sessions or
#       concurrent ones?
#   C3. Concurrency lower bound: how many (entity, repo) working contexts
#       must have been open SIMULTANEOUSLY, under each identity resolution?
#       (A context = interval from an entity's first to last commit in one
#       repo. Overlapping contexts cannot be one sequential session.)
#   C4. The paradox-suite chronology: which copy is first in git? (This
#       kills the naive lineage julia3claude → julia2.)
#
# Exit 0 iff all asserted findings hold.

include(joinpath(@__DIR__, "..", "model", "system_state.jl"))
using .SystemState
using Dates

failures = String[]
check(name, cond) = (cond ? println("  PASS  $name") : (push!(failures, name); println("  FAIL  $name")))

evs = sort(EVENTS; by = c -> c.t)

println("C1. Window")
span = evs[end].t - evs[1].t
println("     first $(evs[1].t)  last $(evs[end].t)  span $(canonicalize(Dates.CompoundPeriod(span)))")
check("C1: everything within one 4-hour window", span <= Hour(4))

println("C2. Interleaving")
switches = count(i -> evs[i].repo !== evs[i+1].repo, 1:length(evs)-1)
println("     $(length(evs)) commits, $switches repo switches in time order")
runs = [evs[1].repo]
for c in evs[2:end]; c.repo !== runs[end] && push!(runs, c.repo); end
println("     repo run sequence: ", join(string.(runs), " → "))
check("C2: heavily interleaved (≥8 switches)", switches >= 8)

println("C3. Session-concurrency lower bound")
for (nm, ρ) in RESOLUTIONS
    ctx = Dict{Tuple{Symbol,Symbol},Tuple{DateTime,DateTime}}()
    for c in evs
        k = (ρ(c.ident), c.repo)
        ctx[k] = haskey(ctx, k) ? (min(ctx[k][1], c.t), max(ctx[k][2], c.t)) : (c.t, c.t)
    end
    # max overlap over event boundaries
    bounds = sort(vcat([v[1] for v in values(ctx)], [v[2] for v in values(ctx)]))
    conc = maximum(t -> count(v -> v[1] <= t <= v[2], values(ctx)), bounds)
    println("     $nm: $(length(ctx)) contexts, max simultaneous = $conc")
    check("C3/$nm: ≥4 contexts open at once", conc >= 4)
end

println("C4. Paradox-suite chronology (git-recorded copies)")
t_j2 = only(c for c in evs if c.hash == "3eac782").t   # julia2 suite lands
t_j3 = only(c for c in evs if c.hash == "48390e1").t   # julia3claude suite lands
t_sh = only(c for c in evs if c.hash == "722ac99").t   # shock lands in julia
println("     julia2 copy  $t_j2")
println("     julia3 copy  $t_j3   (+$(canonicalize(Dates.CompoundPeriod(t_j3 - t_j2))) after julia2)")
println("     julia shock  $t_sh   (+$(canonicalize(Dates.CompoundPeriod(t_sh - t_j3))) after julia3)")
check("C4a: julia2's copy PRECEDES julia3claude's", t_j2 < t_j3)
check("C4b: the julia shock lands minutes after julia3's copy", Minute(0) < (t_sh - t_j3) < Minute(30))

println()
if isempty(failures)
    println("provenance_clock.jl: all findings hold")
    println()
    println("Reading: the record is one dense morning. Under either resolution at")
    println("least four working contexts were open at once — this was an actively")
    println("orchestrated multi-session system, not relay-passing. And the paradox")
    println("suite reached julia2 BEFORE the julia3claude commit that looks like its")
    println("origin: both copies descend from a common out-of-band source (a session")
    println("whose content the owner carried into each repo separately).")
else
    println("provenance_clock.jl: FAILED: ", join(failures, ", "))
    exit(1)
end
