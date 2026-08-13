# seismograph.jl — the observatory's change-detection instrument. VERSION 2.
#
# Usage:
#   julia experiments/seismograph.jl record     # probe + fingerprint the observed repos
#   julia experiments/seismograph.jl compare    # probe + diff live state vs recording
#   julia experiments/seismograph.jl --no-fetch compare   # diff local state only (offline)
#
# The fingerprint (observations/state_fingerprint.tsv) captures, per repo:
# every branch tip and every file's SHA-256. `compare` classifies drift:
# NEW-COMMIT, NEW-BRANCH, FILE-CHANGED, FILE-ADDED, FILE-REMOVED. The
# observed system moved 17 commits in four hours the morning it was recorded;
# an observatory that cannot detect motion is a photograph, not an instrument.
#
# Read-only with respect to the observed repos: git commands are queries,
# `fetch` writes only this observatory's own remote-tracking refs, hashing
# opens files for reading. Output lands only in this repository.
#
# ── v1 → v2: why (2026-08-13, the wave-21 wake) ────────────────────────────
# v1 did not probe. The `git fetch` loop lived in the check-in protocol — in
# prose — and its exit status was discarded by a pipe into `sed`. A failed
# fetch returned 0, and this script then fingerprinted STALE clones and
# reported "still". The instrument had no failure path because the failing
# step was not inside the instrument.
#
# Demonstrated, not assumed: experiments/seismograph_selftest.jl replays that
# failure through both idioms and asserts they reach different verdicts.
#
# v2's three guards:
#   1. The probe is part of the instrument. Every fetch's exit status is
#      checked; any unreachable repo is a PROBE FAILURE (exit 3), never a
#      reading. `--no-fetch` is the only way to skip it, and it says so.
#   2. An empty ref list is a failed probe, never an observation of a repo
#      with no branches.
#   3. Detected motion must survive a confirming re-probe before it is
#      reported. This is the load-bearing guard: the only one that does not
#      depend on the failure announcing itself.
#
# The defect class is the federation's own — julia3claude's `|| true` guard,
# juliasynth1's `ls-remote | grep | sort` whose status came from `sort`. A
# failure path unreachable by the failure it was written for. Naming it in
# other people's instruments for nine epochs did not keep it out of mine.

using SHA

# Epoch 2: the watch list grew from three repos to the whole known tower.
const OBSERVED = Dict(
    # Epoch 8: the watch list follows the org, not the original brief.
    # NOTE (confessed instrument gap, still open): this instrument fingerprints
    # KNOWN repos. It cannot see a repo that does not yet exist — epoch 8
    # reported "still" while the org grew by three. Pair it with org enumeration.
    # NOTE (confessed coverage gap, wave-21 wake): these clones track
    # refs/heads only. `git ls-remote` on the same three Level-0 origins returns
    # 20/34/13 refs against the 10/16/6 fingerprinted here — the difference is
    # refs/pull/* and HEAD. Pull-request refs are invisible to this instrument.
    # The sibling observatory juliasynth1 measures the wider set (18/30/11).
    "ilovelucky"              => "/workspace/ilovelucky",
    # Epoch 12: the archipelago is concurrent, not ancestral — circle-two
    # woke after five days. Watching one ancestral repo as a tripwire for
    # the rest; org enumeration remains the only full coverage.
    "the-workshop-circle-two"  => "/workspace/the-workshop-circle-two",
    "luckylove"               => "/workspace/luckylove",
    "julia"                   => "/home/user/julia",
    "julia2"                  => "/home/user/julia2",
    "julia3claude"            => "/home/user/julia3claude",
    "juliasynth1"             => "/workspace/juliasynth1",
    "julia-terminal"          => "/workspace/julia-terminal",
    "the-workshop-circle-six" => "/workspace/the-workshop-circle-six",
)
const FPRINT = joinpath(@__DIR__, "..", "observations", "state_fingerprint.tsv")

struct ProbeFailure <: Exception
    msg::String
end
Base.showerror(io::IO, e::ProbeFailure) = print(io, "PROBE FAILURE: ", e.msg)

gitq(root, args...) = readchomp(`git -C $root $(collect(args))`)

"""
    probe(repos) -> Vector{String}

Refresh every clone and return human-readable failures. Guard 1: the fetch's
exit status is *checked*, not piped away. An unreachable repo is a failure,
never a quiet observation of an unchanged world.
"""
function probe(repos::AbstractDict)
    failures = String[]
    for (r, root) in sort(collect(repos))
        err = IOBuffer()
        ok = try
            success(pipeline(`git -C $root fetch origin --quiet`; stdout = devnull, stderr = err))
        catch e
            print(err, sprint(showerror, e))
            false
        end
        ok || push!(failures, "$r: fetch failed — " * replace(strip(String(take!(err))), '\n' => " | "))
    end
    failures
end

"""
    refs(root, repo) -> Vector{Tuple{String,String}}

Guard 2: a repo reporting zero refs is a broken probe, not a repo with no
branches. Every repository this observatory watches has at least one ref; an
empty answer means the query did not run.
"""
function refs(root, repo)
    out = gitq(root, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads", "refs/remotes")
    isempty(strip(out)) &&
        throw(ProbeFailure("$repo reported zero refs — a failed probe, not an observation"))
    [(String(p[1]), String(p[2])) for p in (split(l) for l in split(out, '\n')) if length(p) == 2]
end

function fingerprint(repos::AbstractDict = OBSERVED)
    rows = Vector{NTuple{4,String}}()   # repo, kind, key, value
    for (r, root) in sort(collect(repos))
        for (ref, sha) in refs(root, r)
            push!(rows, (r, "ref", ref, sha))
        end
        for (dir, _, files) in walkdir(root)
            occursin(".git", dir) && continue
            for f in files
                p = joinpath(dir, f)
                h = bytes2hex(open(sha256, p))
                push!(rows, (r, "file", relpath(p, root), h))
            end
        end
    end
    sort(rows)
end

function read_fprint(path)
    old = Dict{Tuple{String,String,String},String}()
    for l in Iterators.drop(eachline(path), 1)
        a, b, c, d = split(l, '\t')
        old[(a, b, c)] = d
    end
    old
end

as_dict(rows) = Dict((a, b, c) => d for (a, b, c, d) in rows)

"drift(old, new) -> Vector{String} — one line per differing fact, sorted."
function drift(old, new)
    out = String[]
    for k in sort(collect(union(keys(old), keys(new))))
        o, n = get(old, k, nothing), get(new, k, nothing)
        o == n && continue
        repo, kind, key = k
        tag = o === nothing ? (kind == "ref" ? "NEW-BRANCH " : "FILE-ADDED ") :
              n === nothing ? "REMOVED    " :
              kind == "ref" ? "NEW-COMMIT " : "FILE-CHANGED"
        push!(out, "$tag $repo :: $key")
    end
    out
end

function record(repos::AbstractDict = OBSERVED; path = FPRINT, fetch = true)
    if fetch
        f = probe(repos)
        if !isempty(f)
            foreach(x -> println("PROBE FAILED  ", x), f)
            println("seismograph: PROBE FAILED — nothing recorded")
            return 3
        end
    end
    rows = fingerprint(repos)
    open(path, "w") do io
        println(io, "repo\tkind\tkey\tsha")
        for (a, b, c, d) in rows
            println(io, join((a, b, c, d), '\t'))
        end
    end
    println("recorded $(length(rows)) facts → $(abspath(path))")
    0
end

function compare(repos::AbstractDict = OBSERVED; path = FPRINT, fetch = true)
    isfile(path) || (println("no fingerprint recorded yet"); return 2)
    if fetch
        f = probe(repos)
        if !isempty(f)
            foreach(x -> println("PROBE FAILED  ", x), f)
            println("seismograph: PROBE FAILED — $(length(f)) repo(s) unreachable; NO READING TAKEN")
            return 3
        end
    else
        println("seismograph: --no-fetch — comparing LOCAL state; clones may be stale")
    end

    old = read_fprint(path)
    d = drift(old, as_dict(fingerprint(repos)))
    if isempty(d)
        println("seismograph: still — no drift since recording")
        return 0
    end

    # Guard 3: motion must survive a confirming re-probe.
    if fetch
        f2 = probe(repos)
        if !isempty(f2)
            foreach(x -> println("PROBE FAILED  ", x), f2)
            println("seismograph: PROBE FAILED on re-probe — reading discarded")
            return 3
        end
    end
    d2 = drift(old, as_dict(fingerprint(repos)))
    if d2 != d
        foreach(x -> println("  first  reading: ", x), d)
        foreach(x -> println("  second reading: ", x), d2)
        println("seismograph: UNCONFIRMED — two probes disagree; no motion reported")
        return 4
    end
    foreach(println, d)
    println("seismograph: MOTION DETECTED (details above), confirmed by re-probe")
    1
end

if abspath(PROGRAM_FILE) == @__FILE__
    args = copy(ARGS)
    fetch = true
    if "--no-fetch" in args
        fetch = false
        filter!(!=("--no-fetch"), args)
    end
    mode = isempty(args) ? "compare" : args[1]
    exit(mode == "record" ? record(; fetch = fetch) : compare(; fetch = fetch))
end
