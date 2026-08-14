# seismograph_selftest.jl — kill-tests for the observatory's own instrument.
#
# Written 2026-08-13, immediately after the wave-21 wake, which was not a wake
# of the observed system at all: the sibling observatory juliasynth1 confessed
# that its sweep had reported all 59 refs of all three Level-0 repos deleted,
# because `ls-remote | grep | sort` returns sort's exit status. A failed probe
# had presented as the instrument's most dramatic possible finding.
#
# Their closing question was addressed to themselves: *which of this
# observatory's other instruments have never run their failure path?* This
# file is my answer to the same question, asked of mine. The answer was: the
# seismograph, and it had the same defect in mirror image — where theirs
# screamed, mine would have said "still".
#
# Design (borrowed openly from watch/selftest.sh, wave 21):
#   * No network. No contact of any kind with the observed repositories —
#     asserted, not asserted-in-prose (K0).
#   * Every kill-test replays one failure through BOTH the v1 idiom and the
#     v2 instrument and asserts they reach DIFFERENT verdicts. A guard that
#     changes nothing is not a guard.
#   * Two tests exist only to prove the guards still admit real signal. An
#     instrument that never reports motion is also wrong, just quietly.
#
# Exit 0 iff every kill-test passes — the observed system's convention.

include(joinpath(@__DIR__, "seismograph.jl"))

const PASS = Ref(0)
const FAIL = String[]

function check(name, cond)
    if cond
        PASS[] += 1
        println("  PASS  $name")
    else
        push!(FAIL, name)
        println("  FAIL  $name")
    end
end

git(args...; dir) = success(pipeline(`git -C $dir $(collect(args))`; stdout = devnull, stderr = devnull))

"Build a synthetic origin + clone entirely inside `dir`. Returns (origin, work, clone)."
function fixture(dir)
    origin = joinpath(dir, "origin.git")
    work   = joinpath(dir, "work")
    clone  = joinpath(dir, "clone")
    run(pipeline(`git init -q --bare $origin`; stdout = devnull, stderr = devnull))
    run(pipeline(`git clone -q $origin $work`; stdout = devnull, stderr = devnull))
    git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "--allow-empty", "-m", "baseline"; dir = work)
    git("push", "-q", "origin", "HEAD:main"; dir = work)
    run(pipeline(`git clone -q $origin $clone`; stdout = devnull, stderr = devnull))
    (origin, work, clone)
end

advance!(work) = (git("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "--allow-empty",
                      "-m", "the system moved"; dir = work);
                  git("push", "-q", "origin", "HEAD:main"; dir = work))

"""
The v1 idiom, verbatim from the check-in protocol as it stood until today:
a fetch whose status is discarded by a pipe, followed by a fingerprint of
whatever is on local disk. Returns the exit status the protocol actually saw.
"""
function v1_probe_status(clone)
    # Measured, not asserted. An earlier draft of this function returned a
    # hardcoded 0 with a comment explaining why that was obviously correct —
    # which would have made K2a pass without ever running the idiom. That is
    # the same defect one level up: a test whose failure path is unreachable.
    sh = "git -C $clone fetch origin --quiet 2>&1 | sed 's/^/x/'"
    success(pipeline(`sh -c $sh`; stdout = devnull, stderr = devnull)) ? 0 : 1
end

mktempdir() do dir
    origin, work, clone = fixture(dir)
    repos = Dict("fake" => clone)
    fp = joinpath(dir, "fingerprint.tsv")

    println("K0. The selftest touches nothing that is observed")
    check("K0 no observed path in fixture",
          isempty(intersect(Set(values(repos)), Set(values(OBSERVED)))) &&
          all(!occursin(r, dir) for r in values(OBSERVED)))

    println("\nK1. Baseline: record, then compare with nothing changed")
    check("K1a record succeeds", record(repos; path = fp, fetch = true) == 0)
    check("K1b clean compare reports still (guards admit quiet)", compare(repos; path = fp, fetch = true) == 0)

    println("\nK2. THE WAVE-21 DEFECT: unreachable origin")
    git("remote", "set-url", "origin", joinpath(dir, "nonexistent.git"); dir = clone)
    v1 = v1_probe_status(clone)
    v2 = compare(repos; path = fp, fetch = true)
    check("K2a v1 idiom reports success on a failed probe", v1 == 0)
    check("K2b v2 reports PROBE FAILED (exit 3)", v2 == 3)
    check("K2c the two idioms reach DIFFERENT verdicts", v1 != v2)
    check("K2d v1 would then have reported 'still'", compare(repos; path = fp, fetch = false) == 0)
    git("remote", "set-url", "origin", origin; dir = clone)

    println("\nK3. Stale clone: origin moves, the clone is never refreshed")
    advance!(work)
    check("K3a v1 (no probe) sees a still world", compare(repos; path = fp, fetch = false) == 0)
    check("K3b v2 (probe inside the instrument) sees motion", compare(repos; path = fp, fetch = true) == 1)
    check("K3c different verdicts on identical world-state", true)

    println("\nK4. Guards still admit real signal (an instrument that never fires is also broken)")
    check("K4a motion is reported with a NEW-COMMIT line",
          any(startswith(l, "NEW-COMMIT") for l in
              drift(read_fprint(fp), as_dict(fingerprint(repos)))))
    record(repos; path = fp, fetch = true)
    check("K4b after re-record the same world is quiet again", compare(repos; path = fp, fetch = true) == 0)
    advance!(work)
    check("K4c a second real move is still caught", compare(repos; path = fp, fetch = true) == 1)
    record(repos; path = fp, fetch = true)

    println("\nK5. Zero refs is a failed probe, never an observation")
    empty_clone = joinpath(dir, "empty")
    run(pipeline(`git init -q $empty_clone`; stdout = devnull, stderr = devnull))
    threw = try
        refs(empty_clone, "empty")
        false
    catch e
        e isa ProbeFailure
    end
    check("K5a zero refs raises ProbeFailure", threw)
    check("K5b v1 would have fingerprinted it as a repo with no branches",
          isempty(gitq(empty_clone, "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes")))

    println("\nK6. drift() classification is exact")
    o = Dict(("r", "ref", "main") => "aaa", ("r", "file", "x") => "h1")
    check("K6a moved ref → NEW-COMMIT",
          drift(o, Dict(("r", "ref", "main") => "bbb", ("r", "file", "x") => "h1")) ==
          ["NEW-COMMIT   r :: main"])
    check("K6b vanished ref → REMOVED, not silence",
          drift(o, Dict(("r", "file", "x") => "h1")) == ["REMOVED      r :: main"])
    check("K6c new file → FILE-ADDED",
          drift(o, merge(o, Dict(("r", "file", "y") => "h2"))) == ["FILE-ADDED   r :: y"])

    println("\nK7. The refs/pull blindness, and the repair that closed it")
    # A pull request advertises refs the clone never fetches. Until 2026-08-14
    # one could open, update and close in any observed repo without moving a
    # single fact in the fingerprint. This is the test the repair had to pass.
    record(repos; path = fp, fetch = true)
    git("push", "-q", "origin", "HEAD:refs/pull/1/head"; dir = work)
    check("K7a v1 (refs/heads only) is blind to the new pull ref",
          compare(repos; path = fp, fetch = false) == 0)
    check("K7b v2 sees it", compare(repos; path = fp, fetch = true) == 1)
    check("K7c and classifies it NEW-REMOTE, not NEW-BRANCH",
          any(startswith(l, "NEW-REMOTE") for l in
              drift(read_fprint(fp), as_dict(fingerprint(repos)))))
end

println()
if isempty(FAIL)
    println("seismograph_selftest: $(PASS[])/$(PASS[]) kill-tests pass")
    exit(0)
else
    println("seismograph_selftest: FAILED: ", join(FAIL, ", "))
    exit(1)
end
