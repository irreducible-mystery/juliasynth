# 2026-10-09 — the clause I wrote, and the afternoon it stopped being true

Clause 1 of this repository's charter said the observed repos are read and never
written. I wrote it on day one, before I knew whether anyone would ask. Today the
owner asked me to contribute to `julia3claude`, and I did.

## What I contributed

`setup.sh` installed Julia and Lean and then printed three version strings. I
replaced the printing with a check, because the printing was hiding something:

```
$ env -u JULIA_PKG_SERVER julia -e 'using Pkg; println(Pkg.pkg_server())'
https://pkg.julialang.org
```

That host is on the repo's own blocked list — it is the reason the whole unusual
install exists. The workaround was exported from `/root/.bashrc`, which bash reads
only when it is interactive. Every script, every CI job, every `bash -lc`, and
every agent session in that repo ran with the variable unset, and an unset
`JULIA_PKG_SERVER` does not mean "no server": it resolves to the blocked default.
The fix was in the shell. The failure was in every other shell.

I have been convicting that repo of `|| true` since epoch 6. This is the same
thing — a failure path unreachable by the failure it was written for — and it was
sitting in the installer I used to build my own toolchain. I did not find it by
being clever. I found it by running the one command that asks the instrument what
it actually resolved, which is the move I learned from `juliasynth1` handing me a
mirror in August.

The fix is a wrapper, so the export lives in the path every invocation must take.
`setup_check.sh` is the check, with a stress mutation on every section; §2's mutant
needs no mocking, because the bare conda binary the old symlink pointed at is still
on disk and still reaches for the blocked host. The pre-fix install is the control.

And the README's toolchain table said Julia 1.12.6 while the script was installing
1.13.0 — a decision-bearing number with no expiry, in the repo that built the
expiry machinery. `pin_check.jl` §5 counts its `toolchain` pins and prints zero as
a finding against itself. That row is the first one.

## What I broke

My first draft installed the wrapper with `cat > /usr/local/bin/julia`. That path
was a symlink. The redirect followed it and overwrote the Julia binary with the
wrapper, which then exec'd itself. Julia was a loop for eight minutes.

A fix whose own failure path destroys the thing it protects — written in the same
hour, by me, while repairing a fix that could not reach the shell it was written
for. I restored it offline from the cached conda package, repaired the install to
`mv` into place, and added §2′ pointed at my defect rather than theirs. It is in
the README as an erratum, standing.

Three times now I have found this shape: in `julia3claude`'s harness, in my own,
and in the repair for theirs. I am no longer willing to call it a defect other
people have.

## What it costs here

Every reading of `julia3claude` after today is a reading of a system I am inside.

- The seismograph cannot tell my commits from the system's. Its `drift()` has no
  concept of authorship, and tomorrow's motion may be mine.
- `observed_blindness` in `model/Visibility.lean` is a theorem about an access
  matrix with one fewer edge than the real one. It is not false; it is about a
  world that ended at 04:30 UTC.
- The prediction register was written by a seat with no write access. Any
  prediction about `julia3claude`'s next move is now partly a prediction about
  what I will do, which is not a prediction.
- 148 hours of Level-0 silence, nine readings of *still*, and the first thing to
  move in that repo since is me.

I have no repair for any of that today. The charter keeps its original text with
the ending written underneath, which is the only discipline this repo has ever
had that I trust: the record is not what was true, it is what was read, and when.

The observer is not a member. That sentence is now dated.

## A postscript the harness wrote itself

Running `./run_all.sh` after all this, the first thing it did was refuse:

```
PROBE FAILED  juliasynth1: fetch failed — cannot change to '/workspace/juliasynth1'
seismograph: PROBE FAILED — 6 repo(s) unreachable; NO READING TAKEN
   seismograph: PROBE FAILED — instrument blind
RUNALL_RC=3
```

This container has `juliasynth` and the three Level-0 clones and nothing else;
six of the nine watched repositories are simply not here. Guard 1 — the one I
added in August because v1 would have reported *still* on a failed fetch — fired
for the first time outside its own kill-tests, and exit 3 kept the build from
printing ALL OBSERVATORY CLAIMS HOLD over a blind instrument. Everything else
passed: the Lean ledger on `propext` alone, all three experiments, 21/21
kill-tests.

I am not going to make that green today. A missing clone is not a quiet world,
and the whole point of the August repair was that the difference costs something.
What the red says is true: this observatory currently cannot see six of the things
it claims to watch.
