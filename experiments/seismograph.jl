# seismograph.jl — the observatory's change-detection instrument.
#
# Usage:
#   julia experiments/seismograph.jl record   # fingerprint the observed repos
#   julia experiments/seismograph.jl compare  # diff live state vs recording
#
# The fingerprint (observations/state_fingerprint.tsv) captures, per repo:
# every branch tip and every file's SHA-256. `compare` classifies drift:
# NEW-COMMIT, NEW-BRANCH, FILE-CHANGED, FILE-ADDED, FILE-REMOVED. The
# observed system moved 17 commits in four hours the morning it was recorded;
# an observatory that cannot detect motion is a photograph, not an instrument.
#
# Read-only with respect to the observed repos: git commands are queries,
# hashing opens files for reading. Output lands only in this repository.

using SHA

# Epoch 2: the watch list grew from three repos to the whole known tower.
const OBSERVED = Dict(
    # Epoch 8: the watch list follows the org, not the original brief.
    # NOTE (confessed instrument gap): this instrument fingerprints KNOWN
    # repos. It cannot see a repo that does not yet exist — epoch 8 reported
    # "still" while the org grew by three. Pair it with org enumeration.
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

gitq(repo, args...) = readchomp(`git -C $(OBSERVED[repo]) $(collect(args))`)

function fingerprint()
    rows = Vector{NTuple{4,String}}()   # repo, kind, key, value
    for (r, root) in sort(collect(OBSERVED))
        for line in split(gitq(r, "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads", "refs/remotes"), '\n')
            ref, sha = split(line)
            push!(rows, (r, "ref", String(ref), String(sha)))
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

function record()
    rows = fingerprint()
    open(FPRINT, "w") do io
        println(io, "repo\tkind\tkey\tsha")
        for (a, b, c, d) in rows
            println(io, join((a, b, c, d), '\t'))
        end
    end
    println("recorded $(length(rows)) facts → $(abspath(FPRINT))")
end

function compare()
    isfile(FPRINT) || (println("no fingerprint recorded yet"); exit(2))
    old = Dict{Tuple{String,String,String},String}()
    for l in Iterators.drop(eachline(FPRINT), 1)
        a, b, c, d = split(l, '\t')
        old[(a, b, c)] = d
    end
    new = Dict((a, b, c) => d for (a, b, c, d) in fingerprint())
    quiet = true
    for k in sort(collect(union(keys(old), keys(new))))
        o, n = get(old, k, nothing), get(new, k, nothing)
        o == n && continue
        quiet = false
        repo, kind, key = k
        tag = o === nothing ? (kind == "ref" ? "NEW-BRANCH " : "FILE-ADDED ") :
              n === nothing ? "REMOVED    " :
              kind == "ref" ? "NEW-COMMIT " : "FILE-CHANGED"
        println("$tag $repo :: $key")
    end
    println(quiet ? "seismograph: still — no drift since recording" :
                    "seismograph: MOTION DETECTED (details above)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    mode = isempty(ARGS) ? "compare" : ARGS[1]
    mode == "record" ? record() : compare()
end
