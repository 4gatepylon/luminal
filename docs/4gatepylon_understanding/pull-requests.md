# Open pull requests: contribution map

Snapshot: **2026-10-07**, **40 open PRs**, including **7 drafts**, in
[luminal-ai/luminal](https://github.com/luminal-ai/luminal/pulls).
See the [issue page](ISSUES.md) for category definitions and the
[Mac-friendly shortlist](ISSUES.md#ranked-starting-points-on-a-mac-without-cuda).

Entries run newest-number first. Each starts with a one-sentence plain-English
description, then identifies the kind of work, layer, hardware, and important
context. The heading links to the discussion; **Read** links to one relevant
file at the inspected PR commit, even when that file no longer exists locally.

**These are proposals, not a list of shipped capabilities.** Many older PRs
target removed APIs such as HLIR, ShapeTracker, `Graph::compile`, or the earlier
`luminal_cuda` crate. “Open” does not establish that a PR still applies, builds,
or is actively maintained. Status and scope come from GitHub descriptions,
comments/review summaries, changed-file lists, and selected diffs; performance
and test claims were not independently reproduced. Counts exclude closed and
merged PRs. Local comparison point: `066cc70c`.

A useful way to navigate: **#570/#568** show current compiler overhead work;
**#574** shows a PyTorch boundary bug; **#572/#567/#565** show small test changes;
**#577** shows search meeting runtime memory constraints. Their existence also
means those tasks already have someone proposing a solution.

<a id="pr-577"></a>

## [#577 — CUDA search respects the memory arena](https://github.com/luminal-ai/luminal/pull/577)

Rejects candidate GPU implementations that cannot fit their simultaneously live buffers into the available memory, before spending time benchmarking them.

**Category / layer / hardware:** Performance and reliability → candidate generation, buffer-lifetime planning, and CUDA profiling; NVIDIA GPU for full validation.

Also deduplicates equivalent extracted plans and improves refusal reporting; this addresses compilation/search feasibility, not a new tensor operation.

**Read:** [crates/luminal_cuda_lite/src/search.rs](https://github.com/luminal-ai/luminal/blob/76f2a23e88f0983d19a9d239bb14c845330f2275/crates/luminal_cuda_lite/src/search.rs).

<a id="pr-574"></a>

## [#574 — Keep empty PyTorch cache layers in place](https://github.com/luminal-ai/luminal/pull/574)

Preserves empty slots in a language model's attention cache so exporting and reloading it cannot accidentally move another layer's saved state into the wrong position.

**Category / layer / hardware:** Correctness → Python/PyTorch export and cache serialization; CPU tests are useful on a Mac.

Targets ordinary DynamicCache layers, not every specialized cache type; the bug is at the Python object boundary rather than in a GPU kernel.

**Read:** [crates/pytorch/reference/python/luminal_reference/export_utils.py](https://github.com/luminal-ai/luminal/blob/af25d633a44fb51dd593daf814868dd5d88ff6db/crates/pytorch/reference/python/luminal_reference/export_utils.py).

<a id="pr-572"></a>

## [#572 — Execute the actual Llama3 model on CPU](https://github.com/luminal-ai/luminal/pull/572)

Adds a small CPU execution test using the real Llama3 model path so a simplified imitation cannot hide model-integration regressions.

**Category / layer / hardware:** Test coverage → model_zoo/paged_llama3 and ReferenceRuntime; CPU.

Checks execution through the model's real normalization, projections, position encoding, and cache path; it does not cover the FP8 Llama or YOLO targets in issue #573.

**Read:** [crates/luminal_reference/tests/mini_model_smoke.rs](https://github.com/luminal-ai/luminal/blob/f073003aeacb4276ee4b8afa245b9f3b0b25bc48/crates/luminal_reference/tests/mini_model_smoke.rs).

<a id="pr-570"></a>

## [#570 — Use faster maps during extraction](https://github.com/luminal-ai/luminal/pull/570)

Reduces compiler bookkeeping overhead when turning an e-graph's selected alternatives into an executable plan.

**Category / layer / hardware:** Compilation performance → core extraction; backend-independent CPU work.

Changes internal maps to FxHashMap; the reported gain is from a small compilation benchmark, and review requests broader evidence before generalizing it.

**Read:** [src/extraction.rs](https://github.com/luminal-ai/luminal/blob/112cd193cd44143b9e3acafd9b5dfa20df0f37a2/src/extraction.rs).

<a id="pr-569"></a>

## [#569 — Mixed runtime, PyTorch, search, and CI fixes](https://github.com/luminal-ai/luminal/pull/569) · Draft

Bundles fixes that let more PyTorch operations and runtime edge cases work while improving compiler diagnostics and updating CI machines.

**Category / layer / hardware:** Mixed correctness/capability/tooling → reference runtime, shared ATen translation, PyTorch adapters, search, Metal/CUDA, and CI.

Draft, 71 changed files, based on another development branch: this is a broad stacked change, not a single beginner fix; some validation is CPU-only, but backend changes need their devices.

**Read:** [crates/luminal_reference/src/runtime.rs](https://github.com/luminal-ai/luminal/blob/10d37341d0430d681712545d1167da79de50e33c/crates/luminal_reference/src/runtime.rs).

<a id="pr-568"></a>

## [#568 — Reuse decoded layout information](https://github.com/luminal-ai/luminal/pull/568)

Avoids repeatedly decoding the same tensor-layout facts while the compiler evaluates many possible implementations.

**Category / layer / hardware:** Compilation performance → extraction-session metadata caching; backend-independent CPU work.

The cache lasts for one extraction session; this is not a persistent model cache and does not directly change tensor execution.

**Read:** [src/extraction.rs](https://github.com/luminal-ai/luminal/blob/9a8ab3f69b4bb467614591dd6aa08ddb8a8bab46/src/extraction.rs).

<a id="pr-567"></a>

## [#567 — Keep simplified test outputs visible](https://github.com/luminal-ai/luminal/pull/567)

Fixes a test helper that can lose its requested result when a supposedly unary operation simplifies to returning its input unchanged.

**Category / layer / hardware:** Test correctness → core frontend test bindings; CPU.

Explicitly binds the result for readback, including identity-like movement operations; the proposed repair is in the harness rather than the mathematical operation.

**Read:** [src/frontend/unary.rs](https://github.com/luminal-ai/luminal/blob/e53442708bef5547bb50a0e476263f0e32ac2816/src/frontend/unary.rs).

<a id="pr-565"></a>

## [#565 — Expand cumulative-operation tests](https://github.com/luminal-ai/luminal/pull/565)

Adds cases for cumulative sums and products involving small integer types, unusual strides, scalars, and non-finite values.

**Category / layer / hardware:** Test coverage/numerical semantics → ReferenceRuntime scan operations; CPU.

Tests only; the discussion raises unresolved overflow and reduction-semantics questions, so the asserted behavior should not be treated as settled policy.

**Read:** [crates/luminal_reference/tests/scan_ops.rs](https://github.com/luminal-ai/luminal/blob/4516cf4f93e9c06a0b0d6cb36717f5315e6ba648/crates/luminal_reference/tests/scan_ops.rs).

<a id="pr-561"></a>

## [#561 — Save CUDA plans and integrate serving replay](https://github.com/luminal-ai/luminal/pull/561)

Proposes saving reusable compiled GPU plans and integrating them with vLLM so model serving can avoid repeated compilation and launch overhead.

**Category / layer / hardware:** Capability and performance → artifact serialization, CUDA runtime, and PyTorch/vLLM serving; NVIDIA GPU.

The [latest discussion](https://github.com/luminal-ai/luminal/pull/561#issuecomment-6006933132) says the external CUDA-graph abstraction is unsound for dynamic dimensions and asks to narrow the PR to serialization; the serving proposal is not an established capability.

**Read:** [crates/luminal_cuda_lite/src/runtime.rs](https://github.com/luminal-ai/luminal/blob/b98b7ef2ea5ab7fb858d48c1949b325c2ef567ae/crates/luminal_cuda_lite/src/runtime.rs).

<a id="pr-539"></a>

## [#539 — Compare Metal operations with CPU results](https://github.com/luminal-ai/luminal/pull/539)

Checks a broad set of Apple GPU operations against the CPU reference implementation to catch wrong answers.

**Category / layer / hardware:** Correctness testing → Metal operation execution; compatible Mac GPU plus CPU reference.

An operation sweep, explicitly not sampling every equivalent search candidate; it is adjacent to issue #20 but does not implement that issue's remaining fuzzing request. Uses the older Metal test layout.

**Read:** [crates/luminal_metal/src/tests.rs](https://github.com/luminal-ai/luminal/blob/9a93e260bfe7916d3098f6cf725264dc2154d9bf/crates/luminal_metal/src/tests.rs).

<a id="pr-529"></a>

## [#529 — Turn repeated graph regions into loops](https://github.com/luminal-ai/luminal/pull/529)

Recognizes more repeated computation so the compiler can represent it as loops instead of expanding every repetition separately.

**Category / layer / hardware:** Compiler optimization → loop discovery, extraction, and CUDA execution support.

Generalizes repeated-region handling and nesting; the diff includes removed paths such as src/hlir.rs, so integration with today's logical/layout/buffer pipeline needs reassessment.

**Read:** [src/hlir.rs](https://github.com/luminal-ai/luminal/blob/8bc638c67f8f94657310eaa56686aac317ee50fe/src/hlir.rs).

<a id="pr-523"></a>

## [#523 — Benchmark representative CUDA workloads](https://github.com/luminal-ai/luminal/pull/523)

Makes GPU implementation selection use realistic inputs and shapes while preserving the numerical behavior of fused operations.

**Category / layer / hardware:** Correctness and execution performance → profiling, dynamic-shape buckets, CUDA fusion, and cuBLAS alternatives; NVIDIA GPU.

The body distinguishes a forced fast candidate from one search actually discovers, and reports its original performance target unmet; older compiler/kernel paths are involved.

**Read:** [crates/luminal_cuda_lite/src/runtime.rs](https://github.com/luminal-ai/luminal/blob/a3522ac10e51ff5419b33e22e775c0e9c60aae4c/crates/luminal_cuda_lite/src/runtime.rs).

<a id="pr-411"></a>

## [#411 — BF16 support for Metal](https://github.com/luminal-ai/luminal/pull/411)

Adds Apple's GPU handling for a 16-bit floating-point format commonly used to reduce model-weight memory.

**Category / layer / hardware:** Backend capability → Metal dtype plumbing, generated kernels, and runtime buffers; Metal.

Restricts fast MPS matrix multiplication to supported types and uses generic BF16 alternatives; an older proposal referenced by issue #576, not proof that current Metal BF16 works.

**Read:** [crates/luminal_metal/src/kernel/ops.rs](https://github.com/luminal-ai/luminal/blob/e5db6ad0be9412a6f2da808d4969e1e36e2f3414/crates/luminal_metal/src/kernel/ops.rs).

<a id="pr-408"></a>

## [#408 — Recognize fast weight-gradient matrix multiplies](https://github.com/luminal-ai/luminal/pull/408)

Lets Apple's optimized matrix-multiplication library handle a training gradient pattern that previously fell back to a slow generic kernel.

**Category / layer / hardware:** Execution performance → egglog lowering to MPSMatmul; Metal.

Directly fixes issue #382 with layout-constrained rewrites and positive/negative cases; targets the older autograd/compiler architecture.

**Read:** [crates/luminal_metal/src/kernel/ops.rs](https://github.com/luminal-ai/luminal/blob/4fb29203c1d4911b57ff9c15e033cd907ddd4d65/crates/luminal_metal/src/kernel/ops.rs).

<a id="pr-395"></a>

## [#395 — Do not overwrite a still-visible tensor](https://github.com/luminal-ai/luminal/pull/395)

Prevents a Metal scatter operation from reusing an input buffer when the caller also needs the original tensor as an output.

**Category / layer / hardware:** Correctness → buffer reuse, aliasing, and Metal execution; Metal.

The important invariant is that optimization must preserve all observable values; the implementation is in the older consumed-buffer/kernel path.

**Read:** [crates/luminal_metal/src/kernel/ops.rs](https://github.com/luminal-ai/luminal/blob/8ff77c70fb7407168d27d9d635511850d82b6f20/crates/luminal_metal/src/kernel/ops.rs).

<a id="pr-392"></a>

## [#392 — BERT masked-word prediction example](https://github.com/luminal-ai/luminal/pull/392)

Adds an example that loads BERT weights and predicts hidden words using Luminal's CUDA execution path.

**Category / layer / hardware:** Model capability → example architecture, checkpoint loading, and CUDA integration; NVIDIA GPU.

Advertises F32/BF16 weight modes; it is model/example coverage rather than a new general compiler backend.

**Read:** [examples/bert/src/main.rs](https://github.com/luminal-ai/luminal/blob/c0beaff20f8c2e0a46358f07be22e22197fc3e29/examples/bert/src/main.rs).

<a id="pr-383"></a>

## [#383 — Vary search jumps and visualize progress](https://github.com/luminal-ai/luminal/pull/383)

Mixes small and large changes to candidate implementations and adds a browser view of which candidates were tried and how fast they were.

**Category / layer / hardware:** Compilation/search performance plus tooling → mutation strategy and profiling visualization.

HTML visualization can be inspected on a Mac; producing representative GPU timing data needs that backend. This is not the rewrite-proof debugger requested by issue #141; the search edits target the older Graph-owned search.

**Read:** [tools/search_viz.py](https://github.com/luminal-ai/luminal/blob/6382e31aefc0d9c5db6a8370df46445b9b3f72f2/tools/search_viz.py).

<a id="pr-375"></a>

## [#375 — Local testing across CUDA versions](https://github.com/luminal-ai/luminal/pull/375)

Provides commands and containers for checking that Luminal uses the appropriate GPU APIs across NVIDIA toolkit versions.

**Category / layer / hardware:** Developer tooling → build compatibility tests and local CUDA containers.

Stacked on #371, so its full diff includes that fix; binding-selection tests give partial CPU coverage, but real toolkit/JIT execution needs NVIDIA hardware. This does not add a GitHub Actions version matrix.

**Read:** [Makefile](https://github.com/luminal-ai/luminal/blob/ecf3d7398fe0ea9bdb89294439a0f33956fe16fc/Makefile).

<a id="pr-371"></a>

## [#371 — Choose CUDA APIs for the installed toolkit](https://github.com/luminal-ai/luminal/pull/371)

Fixes compilation with newer NVIDIA toolkits by selecting the correct versions of CUDA graph driver calls.

**Category / layer / hardware:** Compatibility bug fix → build-time detection and CUDA FFI; NVIDIA toolkit/device validation.

Directly closes issue #370; CPU unit tests can cover version parsing but cannot establish that the resulting GPU calls work.

**Read:** [crates/luminal_cuda_lite/build_support/cuda_version.rs](https://github.com/luminal-ai/luminal/blob/72be5d6cd5b11e33ed8d70d277f00d5afa45b106/crates/luminal_cuda_lite/build_support/cuda_version.rs).

<a id="pr-369"></a>

## [#369 — Translate PyTorch bitwise operations](https://github.com/luminal-ai/luminal/pull/369)

Adds integer bit operations needed to import graphs that unpack compressed GPTQ model weights.

**Category / layer / hardware:** Interoperability → ATen translation, frontend primitives, and older HLIR; eventual backend execution.

The [maintainer discussion](https://github.com/luminal-ai/luminal/pull/369#issuecomment-5014233268) questions whether this is the right approach; it is not complete GPTQ model support, and the translator paths predate the current shared PyTorch layout.

**Read:** [crates/luminal_python/rust/src/translator/binary.rs](https://github.com/luminal-ai/luminal/blob/b93c0a885c57d43e9f35fe4ee01c8ea90af6b365/crates/luminal_python/rust/src/translator/binary.rs).

<a id="pr-360"></a>

## [#360 — Named arguments for egglog rules](https://github.com/luminal-ai/luminal/pull/360) · Draft

Experiments with giving compiler-rule arguments names so large rewrites are easier to write and maintain.

**Category / layer / hardware:** Compiler API/refactor → egglog authoring and rule definitions across core, CUDA, and Metal.

Draft with no explanatory body; scope is inferred from its title and 43-file diff. Related to issue #133; CPU checks cover core authoring, while backend rule validation needs appropriate runtimes.

**Read:** [src/egglog_utils/api.rs](https://github.com/luminal-ai/luminal/blob/1836da847eaa5274af762472437c609a52d3706e/src/egglog_utils/api.rs).

<a id="pr-347"></a>

## [#347 — Refresh GraphTensor documentation examples](https://github.com/luminal-ai/luminal/pull/347)

Updates documentation examples that call APIs removed from an earlier Luminal version.

**Category / layer / hardware:** Documentation → frontend and runtime onboarding; CPU review.

The replacement examples themselves use NativeRuntime and cx.compile, which are also older than this checkout's ReferenceRuntime::load/search path; this PR should not be copied as today's setup guide.

**Read:** [docs/docs/graphtensor.mdx](https://github.com/luminal-ai/luminal/blob/f762993cf352c5a9217bcfe7993c1a4ff28e2c1c/docs/docs/graphtensor.mdx).

<a id="pr-340"></a>

## [#340 — WebGPU runtime](https://github.com/luminal-ai/luminal/pull/340)

Adds a GPU backend intended to run Luminal on more operating systems and graphics devices through WebGPU.

**Category / layer / hardware:** New backend → WGSL kernels, operation lowering, buffers, dispatch, and a Llama example.

The author reports an Apple-chip comparison, but intended Android/WebAssembly/other-device reach is not evidence that every target works; a compatible Mac can investigate part of this older runtime proposal.

**Read:** [crates/luminal_webgpu/src/runtime.rs](https://github.com/luminal-ai/luminal/blob/ca594bd747b005d945cf29f9a60782a2e0b06579/crates/luminal_webgpu/src/runtime.rs).

<a id="pr-338"></a>

## [#338 — Speed up Metal Llama decoding](https://github.com/luminal-ai/luminal/pull/338)

Combines common Llama computations into fewer GPU kernels and reuses buffers to reduce the cost of generating each token on a Mac.

**Category / layer / hardware:** Execution performance → Metal fusion rules, specialized kernels, runtime allocation, and model example.

Requires Metal measurement; spans attention, normalization, position encoding, feed-forward layers, and matrix-vector operations in the older pipeline, so it is much broader than one optimization.

**Read:** [crates/luminal_metal/src/kernel/fusion/mod.rs](https://github.com/luminal-ai/luminal/blob/22ec7f896effd2ae0553f86f74d01de678b8edee/crates/luminal_metal/src/kernel/fusion/mod.rs).

<a id="pr-332"></a>

## [#332 — Persist compilation-search results](https://github.com/luminal-ai/luminal/pull/332) · Draft

Saves previously selected implementations so later runs can avoid repeating the same expensive compiler search.

**Category / layer / hardware:** Compilation performance → disk cache, e-graph serialization, and per-shape-bucket selections.

Draft; author reports testing on a Mac, but the integration targets older Graph::compile/search APIs. Related in purpose to #561, which instead proposes CUDA executable-artifact reuse.

**Read:** [src/graph.rs](https://github.com/luminal-ai/luminal/blob/61690a08cef30e373cc78127c23f4e03d462b900/src/graph.rs).

<a id="pr-283"></a>

## [#283 — Older dedicated CPU backend](https://github.com/luminal-ai/luminal/pull/283)

Introduces a CPU executor with basic tensor operations and an optimized matrix-multiplication path.

**Category / layer / hardware:** New backend → CPU operation implementations, egglog matmul matching, and runtime.

Explicitly targets issue #194, but is based on the older runtime interface; today's checkout already has a separate ReferenceRuntime. Do not treat this proposal as a prerequisite for contributing without CUDA.

**Read:** [crates/luminal_cpu/src/runtime.rs](https://github.com/luminal-ai/luminal/blob/3a5d6a71131858e2d5f6bf78c7f7e75ae38d9943/crates/luminal_cpu/src/runtime.rs).

<a id="pr-270"></a>

## [#270 — Metal block execution and memory support](https://github.com/luminal-ai/luminal/pull/270)

Adds infrastructure for executing combined GPU work on Metal, including reusable compiled pipelines and buffer management.

**Category / layer / hardware:** Backend capability and execution performance → Metal block/megakernel execution, aliases, and allocation; Metal.

Overlaps issue #217. The title mentions Gemma, but the description emphasizes infrastructure; the changed example path is Llama, so model completeness is unclear from the body.

**Read:** [crates/luminal_metal/src/kernel/block.rs](https://github.com/luminal-ai/luminal/blob/b03080e420a812b27e47e1bb1ae9c06c1eb9d045/crates/luminal_metal/src/kernel/block.rs).

<a id="pr-258"></a>

## [#258 — Empty tensors and high-rank shape handling](https://github.com/luminal-ai/luminal/pull/258)

Addresses unsafe empty-buffer reads and shape-processing panics when tensors have zero-sized or unusually many dimensions.

**Category / layer / hardware:** Correctness/safety → Metal readback and core symbolic shape storage; CPU plus Metal.

Uses a heap-spilling ShapeTracker container and changes GraphTensor ownership; ShapeTracker has since been removed locally, so this older patch requires re-evaluating each invariant rather than transplanting it.

**Read:** [src/shape/tracker.rs](https://github.com/luminal-ai/luminal/blob/a3e55f9608e9a3e0e78f659173d142b2e5ba87e3/src/shape/tracker.rs).

<a id="pr-249"></a>

## [#249 — Dedicated Metal embedding lookup](https://github.com/luminal-ai/luminal/pull/249)

Adds a GPU kernel that directly looks up token embeddings, avoiding both extra operations and a reported integer-versus-float interpretation bug.

**Category / layer / hardware:** Correctness plus execution performance → egglog fusion, integer indices, and Metal kernels; Metal.

Targets an older all-float kernel path; a fused replacement should not be mistaken for proof that every unfused integer operation is correct.

**Read:** [crates/luminal_metal/src/kernel/ops.rs](https://github.com/luminal-ai/luminal/blob/85fac984b8be60d4876013bd87394000f02bfb96/crates/luminal_metal/src/kernel/ops.rs).

<a id="pr-241"></a>

## [#241 — Core cleanup and lint documentation](https://github.com/luminal-ai/luminal/pull/241)

Cleans up Rust style and documents failure conditions across core compiler and frontend code.

**Category / layer / hardware:** Maintenance → API documentation, lint handling, and small Rust refactors; mostly CPU.

The body only says “As before”; this description is inferred from the diff, which adds panic/error docs and simpler expressions. Several touched paths belong to the removed ShapeTracker/HLIR architecture.

**Read:** [src/frontend/tensor.rs](https://github.com/luminal-ai/luminal/blob/65b74c7bb4b76b74d7805543f27b6cdc19f645ba/src/frontend/tensor.rs).

<a id="pr-236"></a>

## [#236 — GPU-specific compilation and faster approximate matmul](https://github.com/luminal-ai/luminal/pull/236)

Compiles for the detected NVIDIA GPU and tries a faster, lower-precision matrix-multiplication mode when available.

**Category / layer / hardware:** Execution performance with numerical-policy implications → NVRTC device targeting and cuBLAS/TF32; NVIDIA GPU.

The [maintainer response](https://github.com/luminal-ai/luminal/pull/236#issuecomment-3874312348) rejects silently changing precision and calls for explicit graph-level approximation choices; this targets the older luminal_cuda crate.

**Read:** [crates/luminal_cuda/src/host/cublas/mod.rs](https://github.com/luminal-ai/luminal/blob/88db91a4a92ed0a745082df2552d00a45a3f8ecf/crates/luminal_cuda/src/host/cublas/mod.rs).

<a id="pr-228"></a>

## [#228 — Fuse consecutive elementwise operations](https://github.com/luminal-ai/luminal/pull/228)

Combines chains of simple per-element calculations into one CUDA kernel to reduce intermediate storage and launch overhead.

**Category / layer / hardware:** Execution performance → egglog fusion rules and CUDA code generation; NVIDIA GPU.

Discussion calls out unary operations and layout/stride changes; the body still lists missing tests. Its old luminal_cuda/base.egg implementation is not current backend support.

**Read:** [crates/luminal_cuda/src/kernel/hlir.rs](https://github.com/luminal-ai/luminal/blob/b884d2a6cb382be2477a8ddcf366ae7186552bb2/crates/luminal_cuda/src/kernel/hlir.rs).

<a id="pr-223"></a>

## [#223 — Llama FlashAttention kernel](https://github.com/luminal-ai/luminal/pull/223)

Adds a CUDA attention kernel intended to use memory more efficiently when Llama processes longer sequences.

**Category / layer / hardware:** Execution performance → model-specific attention kernel and example integration; NVIDIA GPU.

Reported gains vary by sequence length, with some small cases slower; the body also records register-pressure work, so no universal speedup is established.

**Read:** [examples/llama/src/flash_attn_2.cu](https://github.com/luminal-ai/luminal/blob/527391c3340024e08e37edc6557d3c2c51c903b2/examples/llama/src/flash_attn_2.cu).

<a id="pr-167"></a>

## [#167 — Optimize INT8 matrix-vector multiplication](https://github.com/luminal-ai/luminal/pull/167)

Uses GPU memory access and parallel-reduction techniques to accelerate multiplication by 8-bit model weights.

**Category / layer / hardware:** Execution performance/quantization → CUDA kernels; NVIDIA GPU.

The discussion still asks for measured comparison with the existing kernel and cleanup of unrelated files; the proposed speedup is not established. Touches the older luminal_cuda crate.

**Read:** [crates/luminal_cuda/src/kernels/int_8.cu](https://github.com/luminal-ai/luminal/blob/6c54c71419ea619c8cb0889345aa3487e30eccaa/crates/luminal_cuda/src/kernels/int_8.cu).

<a id="pr-158"></a>

## [#158 — Vulkan through Blade](https://github.com/luminal-ai/luminal/pull/158)

Experiments with running generated Luminal GPU programs through the Blade graphics abstraction and Vulkan.

**Category / layer / hardware:** New backend → shader generation, pointer/index representation, and GPU execution.

The body reports a partially running demo, incomplete features, and suspect Linux output; its Metal-capable abstraction does not establish a finished Mac backend. Targets the historical luminal_2 experiment.

**Read:** [crates/luminal_2/src/codegen.rs](https://github.com/luminal-ai/luminal/blob/4834823a1649045cdad61bd708596ad633bc4d9e/crates/luminal_2/src/codegen.rs).

<a id="pr-156"></a>

## [#156 — Initial ONNX importer](https://github.com/luminal-ai/luminal/pull/156)

Loads a subset of ONNX models and translates their named inputs, weights, and operations into a Luminal tensor graph.

**Category / layer / hardware:** Interoperability → protobuf parsing and frontend graph construction; CPU translation/testing.

Addresses issue #32; supports basic arithmetic, matmul, and shape operations, but excludes many operators, control flow, and quantized/complex types. Older APIs need reconciliation.

**Read:** [crates/luminal_onnx/src/load.rs](https://github.com/luminal-ai/luminal/blob/c434b8eccddd09fdcd1d70f6b7a6fa03e687d38c/crates/luminal_onnx/src/load.rs).

<a id="pr-87"></a>

## [#87 — StableHLO importer](https://github.com/luminal-ai/luminal/pull/87) · Draft

Translates models written in StableHLO compiler text into Luminal graphs, with an image-classification example.

**Category / layer / hardware:** Interoperability → lexer/parser, operation lowering, and model import; substantial CPU work.

Draft for issue #85; later comments report SqueezeNet execution beyond the original arithmetic-only body, but its 2025 APIs are historical and broader model coverage remains uncertain.

**Read:** [crates/luminal_hlo/src/lower.rs](https://github.com/luminal-ai/luminal/blob/43322b701d0c72d7fff8fd3c487521c9561800e4/crates/luminal_hlo/src/lower.rs).

<a id="pr-72"></a>

## [#72 — Temporary CUDA training repair](https://github.com/luminal-ai/luminal/pull/72) · Draft

Tries a workaround for a reported training failure in the older Rust optimizer and training example.

**Category / layer / hardware:** Correctness investigation → optimizer state and CUDA training; NVIDIA GPU for the reported behavior.

Draft, explicitly temporary; luminal_training is outside today's workspace and targets removed APIs, so this is not a current PyTorch training fix.

**Read:** [crates/luminal_training/src/optimizer.rs](https://github.com/luminal-ai/luminal/blob/b6d8d4c38aa2291a917a10a5ab7088102edd8872/crates/luminal_training/src/optimizer.rs).

<a id="pr-69"></a>

## [#69 — Autograd dimension-removal regression](https://github.com/luminal-ai/luminal/pull/69) · Draft

Adds a failing-test/fix attempt for gradients that remove the wrong dimensions as earlier removals shift later indices.

**Category / layer / hardware:** Correctness investigation → old Rust autograd shape bookkeeping; conceptually CPU.

Draft; comments question the fix and report continued failures. This belongs to the legacy training crate, not the current PyTorch AOTAutograd path.

**Read:** [crates/luminal_training/src/autograd.rs](https://github.com/luminal-ai/luminal/blob/6913f5e9ea1953d49e32809db8c418311c3418e3/crates/luminal_training/src/autograd.rs).

<a id="pr-49"></a>

## [#49 — Early ONNX import skeleton](https://github.com/luminal-ai/luminal/pull/49) · Draft

Starts the plumbing for reading ONNX files and tracking named graph inputs, outputs, and stored weights.

**Category / layer / hardware:** Interoperability prototype → parser/build tooling and graph import; CPU.

Draft whose body explicitly says it does not compile; overlaps issue #32 and the more developed #156 proposal.

**Read:** [crates/luminal_onnx/src/onnx/graph_io.rs](https://github.com/luminal-ai/luminal/blob/dd6210a6683b83058c8ba9137dfb7cf0be6d53f4/crates/luminal_onnx/src/onnx/graph_io.rs).
