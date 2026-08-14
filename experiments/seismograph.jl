# seismograph.jl — the observatory's change-detection instrument. VERSION 2.
#
# Usage:
#   julia experiments/seismograph.jl record     # probe + fingerprint the observed repos
#   julia experiments/seismograph.jl compare    # probe + diff live state vs recording
#   julia experiments/seismograph.jl --no-fetch compare   # diff local state only (offline)
#
# The fingerprint (observations/state_fingerprint.tsv) captures, per repo:
# every branch tip, every ref the origin advertises (`refs/pull/*` and tags
# included), and every file's SHA-256. `compare` classifies drift:
# NEW-COMMIT, NEW-BRANCH, NEW-REMOTE, FILE-CHANGED, FILE-ADDED, REMOVED. The
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
    # NOTE (coverage gap confessed at the wave-21 wake, PAID the next day):
    # these clones track refs/heads only, so `refs/pull/*` was invisible —
    # ls-remote saw 20/34/13 refs where the fingerprint saw 10/16/6. Now
    # fingerprinted directly as `remote` rows, so a pull request cannot open,
    # update or close unseen. Left standing a third cycle it would have been
    # the confessed-never-repaired pattern this repo convicts others of.
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

"""
    remote_refs(root, repo) -> Vector{Tuple{String,String}}

Everything the origin advertises, `refs/pull/*` and tags included — not just
what this clone chose to fetch.

Debt paid 2026-08-13 (declared in the wave-21 wake, closed the next day). The
clones track `refs/heads` only: `ls-remote` reports 20/34/13 refs for the
three Level-0 repos where `refs()` sees 10/16/6. A pull request could open,
update and close without moving one fact in the fingerprint. Confessing that
twice and leaving it standing is the confessed-but-never-repaired pattern this
observatory has convicted the federation of since epoch 6; it does not get a
different name here.

Guard 2 again: an empty advertisement is a failed probe, never a reading.
"""
function remote_refs(root, repo)
    out = try
        gitq(root, "ls-remote", "origin")
    catch e
        throw(ProbeFailure("$repo: ls-remote failed — " * sprint(showerror, e)))
    end
    isempty(strip(out)) &&
        throw(ProbeFailure("$repo advertised zero remote refs — a failed probe, not an observation"))
    [(String(p[2]), String(p[1])) for p in (split(l) for l in split(out, '\n')) if length(p) == 2]
end

"""
    fingerprint(repos; remote = true)

`remote = false` fingerprints local state only — the offline mode behind
`--no-fetch`. It cannot see `refs/pull/*`, and is honest about that by not
pretending to have asked.
"""
function fingerprint(repos::AbstractDict = OBSERVED; remote::Bool = true)
    rows = Vector{NTuple{4,String}}()   # repo, kind, key, value
    for (r, root) in sort(collect(repos))
        for (ref, sha) in refs(root, r)
            push!(rows, (r, "ref", ref, sha))
        end
        if remote
            for (ref, sha) in remote_refs(root, r)
                push!(rows, (r, "remote", ref, sha))
            end
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
        tag = o === nothing ? (kind == "ref"    ? "NEW-BRANCH  " :
                               kind == "remote" ? "NEW-REMOTE  " : "FILE-ADDED  ") :
              n === nothing ? "REMOVED     " :
              kind == "file" ? "FILE-CHANGED" : "NEW-COMMIT  "
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
    rows = fingerprint(repos; remote = fetch)
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
        println("seismograph: --no-fetch — `remote` rows excluded from BOTH sides; refs/pull unchecked")
    end

    old = read_fprint(path)
    # Offline mode compares like for like. The baseline holds `remote` rows
    # that an offline run cannot re-measure; silently diffing against them
    # would report every advertised ref as REMOVED — a reading manufactured by
    # not having looked. Drop them from the baseline too, and say so above.
    fetch || filter!(kv -> kv.first[2] != "remote", old)
    d = drift(old, as_dict(fingerprint(repos; remote = fetch)))
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
    d2 = drift(old, as_dict(fingerprint(repos; remote = fetch)))
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
