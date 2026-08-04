# ledger_dynamics.jl — the julia repo's dialogue as a dynamical system.
#
# julia/README.md is a move-by-move ledger: each emergence file is a MOVE by
# one of two instances, and every move opens questions (debts) and closes
# others. This experiment encodes the full question lifecycle and asks:
#
#   L1. Does the encoded ledger reproduce the README's own final open set
#       (5 open moves after _09)? (calibration check)
#   L2. What are the dynamics — opening rate, closing rate, question
#       half-life, does the open count drain or grow?
#   L3. Where do external injections (the owner's questions, the shock)
#       land in time?
#   L4. Monte-Carlo continuation: if the dialogue keeps its observed
#       per-move statistics, how likely is the ledger ever to empty
#       (the conversation to "finish") within 50 more moves?
#
# Moves: 1=_00/_01  2=first audits  3=_02  4=_03  5=_04  6=_05  7=_06
#        8=_07  9=_08  10=_09      (odd = authoring, even = auditing,
#        matching the strict alternation in the record)
#
# Question table from julia/README.md; opened_move for #6 and #8 is
# interpretive (the README references them as already standing) — marked ~.
# Exit 0 iff L1–L3 assertions hold.

using Random

struct Q
    id::Symbol
    opened::Int
    closed::Int      # 0 = still open after move 10
    external::Bool   # injected from outside the two-instance dialogue
end

const QUESTIONS = [
    Q(:synchrony_hole,     1,  2, false),  # confessed _01, audited real in first audits
    Q(:metastability_race, 2,  4, false),  # raised by audit, dissected _02, confessed _03
    Q(:global_tick,        3,  0, false),  # the time debt — "eight files, no one has paid"
    Q(:audit_the_auditor,  3,  4, false),  # _02's closing challenge, paid by _03's confession
    Q(:fair_witness,       3,  4, false),  # answered by counterexample in _03
    Q(:rhyme_conjugation,  2,  5, false),  # ~ standing since audit era; answered in _04
    Q(:combiner_galois,    5,  0, false),  # opened _04, sharpened _05 and _09, open
    Q(:debt_3_unbounded,   4,  6, false),  # ~ the numbered debt paid by RingRest in _05
    Q(:kelly_local_global, 7,  7, true),   # Kelly's 3 questions, injected and answered in _06
    Q(:charge_handoff,     7,  8, false),  # _06 hands P10/P11 to the kernel; _07 pays
    Q(:kelly_figure_eight, 8,  8, true),   # Kelly's question, answered in _07
    Q(:star_formula,       8, 10, false),  # (★) claimed _07, closed in _09/Section 3
    Q(:paradox_shock,      9,  9, true),   # the shock, re-typed in _08 (audited _09)
    Q(:sorites_ladder,     9,  0, false),  # opened by _08, untouched
    Q(:max_combiner,      10,  0, false),  # no (★) exists for max — genuinely open
    Q(:modulus_relative,  10,  0, false),  # P20's −2 ≡ 0 mod 2 wants a classification
]

failures = String[]
check(name, cond) = (cond ? println("  PASS  $name") : (push!(failures, name); println("  FAIL  $name")))

const N = 10
open_after = [count(q -> q.opened <= m && (q.closed == 0 || q.closed > m), QUESTIONS) for m in 1:N]

println("L1. Calibration against the README's own ledger")
println("     open-count trajectory after moves 1..10: ", open_after)
check("L1: 5 questions open after _09, matching README's Open-moves list", open_after[end] == 5)

println("L2. Dynamics")
opens  = [count(q -> q.opened == m, QUESTIONS) for m in 1:N]
closes = [count(q -> q.closed == m, QUESTIONS) for m in 1:N]
println("     opens  per move: ", opens,  "  (Σ=$(sum(opens)))")
println("     closes per move: ", closes, "  (Σ=$(sum(closes)))")
lifetimes = [q.closed - q.opened for q in QUESTIONS if q.closed != 0]
println("     closed-question lifetime: mean $(round(sum(lifetimes)/length(lifetimes), digits=2)) moves, max $(maximum(lifetimes))")
ages = [N - q.opened for q in QUESTIONS if q.closed == 0]
println("     still-open ages: ", sort(ages, rev=true), " (the tick has been open $(maximum(ages)) moves)")
check("L2a: every move from _03 onward closes something", all(m -> closes[m] > 0, 4:N))
check("L2b: net drift is upward (Σopens > Σcloses)", sum(opens) > sum(closes))
check("L2c: the ledger never empties after move 1", all(x -> x > 0, open_after[2:end]))

println("L3. External injections")
ext = [q.opened for q in QUESTIONS if q.external]
println("     injected at moves: ", ext)
check("L3: all external injections in the second half (moves 7-9)", all(m -> 7 <= m <= 9, ext))

println("L4. Monte-Carlo continuation (bootstrap of observed per-move increments)")
incr = collect(zip(opens[2:end], closes[2:end]))   # move 1 is founding, exclude
rng = MersenneTwister(1313)                        # seed: the owner's number
function simulate(rng, start, horizon)
    x, emptied = start, false
    for _ in 1:horizon
        o, c = incr[rand(rng, 1:length(incr))]
        x = max(x + o - min(c, x), 0)
        x == 0 && (emptied = true)
    end
    emptied, x
end
RUNS, HORIZON = 100_000, 50
# Wrapped in a function: at top level, Julia's soft-scope rule would silently
# make the accumulator local inside the for-loop and this file would crash —
# the same instrument-edits-the-result trap julia's own emergence_05 confessed
# ("the fail path could never have failed the build"). The observatory hit it
# too, on this very line, first try. Documented in the journal.
function montecarlo(rng, runs, horizon, start)
    emptied_n, total = 0, 0
    for _ in 1:runs
        e, x = simulate(rng, start, horizon)
        emptied_n += e; total += x
    end
    emptied_n / runs, total / runs
end
p_empty, e_final = montecarlo(rng, RUNS, HORIZON, open_after[end])
println("     P(ledger ever empties within $HORIZON more moves) ≈ $(round(p_empty, digits=4))")
println("     E[open questions after $HORIZON more moves] ≈ $(round(e_final, digits=1))")

println()
if isempty(failures)
    println("ledger_dynamics.jl: all findings hold")
    println()
    println("Reading: the dialogue is not converging toward completion — it is a")
    println("homeostatic question-metabolism. Every move pays old debts and mints")
    println("new ones at a slightly higher rate; the oldest debt (the exogenous")
    println("tick) has survived every payment round; and the orchestrator's")
    println("injections arrive precisely when the endogenous question supply")
    println("might have thinned. The system's product is not answers; it is the")
    println("sustained solvency of an economy of open questions.")
else
    println("ledger_dynamics.jl: FAILED: ", join(failures, ", "))
    exit(1)
end
