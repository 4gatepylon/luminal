# Open issues: contribution map

Snapshot: **2026-10-07**, **18 open issues** in
[luminal-ai/luminal](https://github.com/luminal-ai/luminal/issues).
Companion: [40 open PRs](pull-requests.md). The
[Mac-friendly shortlist is at the bottom](#ranked-starting-points-on-a-mac-without-cuda).

Each heading links to the original report. Descriptions summarize the report,
not a newly reproduced failure. Categories and difficulty ratings are my
assessment. I checked issue discussions/cross-references, every open PR's
description and changed paths, and selected diffs against local `066cc70c`.
No repository tests or models were run. Closed items appear only when needed
to explain overlap; private branches and unlinked work cannot be ruled out.

## How the categories map to the system

| Category | What changes | Typical layer |
| --- | --- | --- |
| Correctness / compatibility | Wrong results, crashes, or rejected valid inputs | Graph semantics, storage, kernels, or external APIs |
| Performance | Time or memory needed to compile or execute; these are separate costs | Rewrite rules, extraction/search, allocation, GPU kernels |
| Capability / integration | A new backend, model format, precision, or distributed path | Frontend/importer or runtime |
| Tests / CI / benchmarks | Evidence that behavior is correct, runnable, or fast | Contributor tooling and automated checks |
| Compiler tooling / design | How developers author or explain transformations | Egglog and diagnostics |

**CPU** means useful local work without a GPU; **Metal** requires a compatible
Mac GPU for execution; **CUDA** requires NVIDIA hardware for meaningful device
validation. A CPU test of CUDA planning does not establish GPU correctness.
For unfamiliar terms, use the [glossary](glossary.md).

## Correctness, compatibility, and missing test coverage

### [#576 — Metal BF16 and low-precision accumulation](https://github.com/luminal-ai/luminal/issues/576)

Metal cannot yet handle the proposed BF16 weight path completely, and sums of
16-bit values may lose accuracy because they also accumulate in 16 bits.

**Category:** backend capability plus numerical correctness; Metal host buffers,
shader types, and reduction/scan kernels. **Local validation:** Metal.
The report separates missing BF16 plumbing from an unresolved precision policy.
[#411](pull-requests.md#pr-411) is an older BF16 proposal, and the reporter says
they already have patches; this is not clearly unclaimed work.

### [#573 — FP8 Llama and YOLO lack CPU execution tests](https://github.com/luminal-ai/luminal/issues/573)

Two model definitions can change without a GPU-free test noticing that their
graphs no longer execute.

**Category:** test coverage; model construction → reference runtime, **CPU**.
YOLO's existing tests only build graphs; the generic mini convolution model
does not cover YOLO's actual structure.
[#572](pull-requests.md#pr-572) tests ordinary Llama3, not these two targets.
The current [smoke helper](../../crates/luminal_reference/tests/mini_model_smoke.rs)
still lacks FP8 input filling; FP8 scale inputs also need deliberate nonzero
values. Strong candidate when scoped to one small model path.

### [#555 — Metal cannot lower ReLU](https://github.com/luminal-ai/luminal/issues/555)

A basic neural-network activation reportedly fails because Metal lacked the
conditional-selection operation used to implement it.

**Category:** missing operation implementation; lowering and Metal kernels.
**Local validation:** Metal.
**Likely stale:** this checkout now has a
[Select implementation](../../crates/luminal_metal/src/ops/select/mod.rs) and
[device tests](../../crates/luminal_metal/tests/select.rs).
Reproduce on current main before proposing code; source presence alone does
not prove every reported case is fixed.

### [#552 — Metal failures are hidden by early CI exit](https://github.com/luminal-ai/luminal/issues/552)

The Metal test job stops after one failing test target, hiding other failures
that contributors need to see.

**Category:** CI observability plus several separate Metal test failures.
**Local validation:** workflow review on CPU; full reproduction on Metal.
The [workflow](../../.github/workflows/test-metal.yml) still lacks
`--no-fail-fast`.
[#553](https://github.com/luminal-ai/luminal/pull/553) and
[#554](https://github.com/luminal-ai/luminal/pull/554) were closed unmerged and
addressed individual failures, not this flag; #555 may have been fixed separately.
[#569](pull-requests.md#pr-569) changes this workflow's runner version but does
not add the flag. The reporting fix is a small, distinct starting scope.

### [#551 — Metal Llama search times out on an M1 Pro](https://github.com/luminal-ai/luminal/issues/551)

Compiling the Llama example reportedly rejects every candidate after timeouts,
so the model never reaches usable execution.

**Category:** performance/reliability; implementation search and Metal profiling.
**Local validation:** Metal, with potentially substantial memory and runtime.
The [CI workflow](../../.github/workflows/test-metal.yml) still quarantines a
related Llama timeout. Older example paths have moved, so the exact failure
needs reconfirmation. #338 optimizes Metal Llama and #569 changes search
diagnostics; neither is evidence that this report is fixed. Too broad for a
first compiler repair.

### [#382 — Weight-gradient matrix multiplies miss Apple's fast library](https://github.com/luminal-ai/luminal/issues/382)

Training generates an equivalent matrix multiplication in a different shape
that the compiler fails to recognize as eligible for Apple's optimized kernel.

**Category:** execution performance; egglog operation selection for Metal/MPS.
**Local validation:** Metal.
Directly addressed by [#408](pull-requests.md#pr-408); both refer to the older
training/compiler path, so this is neither unclaimed nor a current-API starter.

### [#370 — CUDA 13 breaks compilation](https://github.com/luminal-ai/luminal/issues/370)

Building against newer NVIDIA tooling fails because Luminal calls GPU graph
APIs whose available names changed.

**Category:** build compatibility; CUDA driver bindings and toolkit detection.
**Local validation:** CPU parsing checks are partial; toolkit/GPU checks need
the appropriate NVIDIA environment.
[#371](pull-requests.md#pr-371) is the direct fix, with
[#375](pull-requests.md#pr-375) supplying related local testing tools.

### [#194 — The older CPU Llama example hits an unsupported operation](https://github.com/luminal-ai/luminal/issues/194)

The older CPU execution path cannot run the advertised Llama example because
it encounters a position-encoding operation it does not implement.

**Category:** backend/model coverage; CPU runtime.
[#283](pull-requests.md#pr-283) explicitly targets this issue, but proposes an
older CPU backend. Current code instead has `ReferenceRuntime`, and
[#572](pull-requests.md#pr-572) proposes actual Llama3 CPU smoke coverage.
Do not infer that today's repository has no CPU execution from this report.

## Backend and model-import capabilities

### [#337 — AMD ROCm/HIP backend](https://github.com/luminal-ai/luminal/issues/337)

The request is to run Luminal on AMD GPUs using AMD's counterpart to CUDA.

**Category:** new backend; operation implementations, GPU runtime, and tooling.
**Local validation:** AMD/ROCm hardware, not a Mac-only target.
The linked prototype [#336](https://github.com/luminal-ai/luminal/pull/336)
is closed unmerged; implementing a backend remains substantial work.

### [#217 — Metal megakernel tracker](https://github.com/luminal-ai/luminal/issues/217)

This tracks running more work inside a combined Apple GPU kernel to reduce
the overhead of launching many small operations.

**Category:** execution performance and backend coverage; Metal scheduling,
kernels, and memory management. **Local validation:** Metal.
[#270](pull-requests.md#pr-270) overlaps directly; #338 is related model-level
optimization. This is an ongoing backend project, not one small missing kernel.

### [#85 — StableHLO model importer](https://github.com/luminal-ai/luminal/issues/85)

An importer would let models expressed in a shared compiler format enter
Luminal without being rewritten through its Rust API.

**Category:** interoperability; model import and translation to tensor graphs.
**Local validation:** parser/translation work on CPU, then a chosen runtime.
Already covered by draft [#87](pull-requests.md#pr-87); ONNX is a separate
format, though #156 is linked as related work.

### [#48 — Multiple GPUs and machines](https://github.com/luminal-ai/luminal/issues/48)

The request is to split model computation across devices and eventually
machines so larger workloads can run.

**Category:** distributed capability; graph partitioning, communication, and
runtime coordination. **Local validation:** a Mac alone cannot validate the
requested GPU execution.
No directly covering open PR was found, but the scope is architectural.
The current PyTorch CPU distributed integration described in
[Q09](answers.md#q09-what-training-and-distributed-execution-paths-actually-exist)
is not evidence of general multi-GPU support.

### [#32 — ONNX model importer](https://github.com/luminal-ai/luminal/issues/32)

An ONNX importer would load models saved by other machine-learning tools and
translate their operations into Luminal graphs.

**Category:** interoperability; parsing and frontend translation.
**Local validation:** substantial CPU work.
Despite its `good first issue` label, draft [#49](pull-requests.md#pr-49) and
[#156](pull-requests.md#pr-156) already tackle it. Extending someone else's
importer could be useful, but it fails the requested “no PR tackling it” filter.

### [#18 — Lower-bit quantization](https://github.com/luminal-ai/luminal/issues/18)

Using fewer bits for model weights should save memory and speed inference,
provided model quality remains acceptable.

**Category:** numerical capability and execution performance; dtype semantics,
quantized kernels, and model-quality evaluation.
**Local validation:** some CPU work, but backend performance needs its device.
The checklist marks 8-bit work done, with 4-/2-bit work remaining;
[#167](pull-requests.md#pr-167) and [#369](pull-requests.md#pr-369) overlap with
quantized execution/import. This is not an untouched, narrowly specified task.

## Compiler tooling and contributor infrastructure

### [#141 — Explain egglog transformations](https://github.com/luminal-ai/luminal/issues/141)

Compiler developers want to see the sequence of rewrite rules that makes two
expressions equivalent when debugging an optimization.

**Category:** compiler debugging; egglog explanations and diagnostics.
**Local validation:** CPU.
No directly covering open PR was found. #383 visualizes performance search,
which is different from proving rewrite equivalence; #360 changes rule authoring.
Current [visualization](../../src/visualization.rs) displays graph structure,
but that alone does not explain a derivation. A small diagnostic example is
approachable; a general proof/trajectory engine is advanced work.

### [#133 — Better Rust APIs for authoring egglog](https://github.com/luminal-ai/luminal/issues/133)

The discussion proposes writing compiler rules through structured Rust helpers
instead of manually assembling long egglog strings.

**Category:** compiler API/design; rewrite authoring and upstream integration.
**Local validation:** CPU for core behavior.
Draft [#360](pull-requests.md#pr-360) is related authoring work.
The current tree already contains a
[typed egglog API](../../src/egglog_core/egglog_utils/api.rs), so the original
replacement proposal needs reassessment. It is a design discussion rather than
a ready implementation ticket.

### [#21 — Automated performance comparisons](https://github.com/luminal-ai/luminal/issues/21)

Contributors want CI benchmarks that compare Luminal with PyTorch and reveal
when a change makes execution slower.

**Category:** benchmark infrastructure; measurement and CI reporting.
**Local validation:** a CPU subset is Mac-friendly; GPU results require GPUs.
No directly covering open PR was found. Linked
[#335](https://github.com/luminal-ai/luminal/pull/335) is closed unmerged;
#568 adds a local extraction measurement, not the requested comparison workflow.
Agree on a small workload and separate compilation from execution timing.

### [#20 — Test many equivalent implementations](https://github.com/luminal-ai/luminal/issues/20)

Tests should check that different implementations selected for the same tensor
program all produce the same answer.

**Category:** correctness testing; rewrites → extraction → runtime execution.
**Local validation:** a reference-runtime subset needs only CPU.
The [latest maintainer clarification](https://github.com/luminal-ai/luminal/issues/20#issuecomment-3829261512)
asks for sampled search-space equivalence, beyond generated input cases.
[#539](pull-requests.md#pr-539) is an adjacent Metal operation sweep, explicitly
not this fuzzing task; #565 adds specific scan cases.
Current [harness helpers](../../crates/luminal_reference/src/harness.rs) expose
genome-based extraction, but a general multi-candidate correctness harness is
more than an ordinary unit test.

## Ranked starting points on a Mac without CUDA

**There are two strong starter scopes, two larger candidates, and one exploratory
stretch—not five ready-made beginner bugs.** For each scope below, I found no
open PR implementing that specific work in this snapshot. Related PRs are
identified above; an absent closing link by itself was not treated as proof.

| Rank | Issue and bounded first contribution | Difficulty / hardware | What would make the contribution reviewable |
| --- | --- | --- | --- |
| **1** | **#552: add `--no-fail-fast` to the Metal CI test command.** Keep repairs of individual failing tests separate. | Small; edit/review on CPU, verify the test command on a compatible Metal Mac. | The flag appears before `--`; CI attempts later test targets after an earlier failure and still reports failure. #569 only changes runner versions here. |
| **2** | **#573: cover the FP8 Llama path first.** Add FP8 input support to the shared smoke helper and execute a tiny instance of the actual model path with positive scale overrides. | Small-to-medium Rust/test work; CPU. YOLO is a separate, larger follow-up. | Search, staging, execution, and output readback work with finite data; the test reaches actual model code. Keep numerical parity tests at the operation/runtime layer, per AGENTS.md. #572 does not cover FP8. |
| **3** | **#21: one reproducible CPU Luminal/PyTorch benchmark and a CI report.** Start with a tiny fixed-shape workload, reporting compile/search and warmed execution separately. | Medium; CPU plus Python/PyTorch. | Equal outputs, fixed inputs, recorded environment and repeated timings; initially report results rather than add a noisy performance-failure threshold. This is a first slice of the issue, not GPU parity. |
| **4** | **#20: a fixed-seed equivalence test for one small graph family.** Extract and execute several distinct valid candidates and compare each with an independent scalar result. | Medium; CPU; learn extraction and bufferization first. | Assert that multiple distinct plans were exercised, preserve the seed on failure, and compare every candidate rather than only the fastest winner. This targets a gap different from #539. |
| **5** | **#141: a minimal, reproducible rewrite-debugging example.** Show two expressions, the relevant rules, and a checked explanation of their equivalence before attempting a general tool. | Exploratory stretch; CPU; scope should be agreed with maintainers. | A small runnable fixture and a documented path from input expressions to the observed equality; clearly distinguish an illustrated derivation from an automatically reconstructed proof. A general trajectory engine is not a beginner task. |

Useful starting files: [Metal CI](../../.github/workflows/test-metal.yml) for #552;
[smoke harness](../../crates/luminal_reference/tests/mini_model_smoke.rs) and
[FP8 model](../../crates/model_zoo/src/llama3_1_fp8/model.rs) for #573;
[CPU example](../../crates/luminal_reference/examples/simple.rs) and
[CPU CI](../../.github/workflows/test-core.yml) for #21;
[reference harness](../../crates/luminal_reference/src/harness.rs) and
[search](../../crates/luminal_reference/src/search.rs) for #20;
[egglog fixtures](../../src/egglog_core/test_scripts) and
[corpus runner](../../crates/luminal_reference/tests/corpus.rs) for #141.

For future validation, target only the changed test, e.g.
`cargo test --release -p luminal_reference --test mini_model_smoke <new_test_name>`;
use `cargo test -p luminal --lib` for core changes. These commands **write build
artifacts** and were not run during this read-only investigation. See
[Q11–Q12](answers.md#q11-what-is-the-smallest-useful-local-run) for setup and checks.

