# Luminal contributor answers

The [questions](questions.md) and Q numbers match this document. Evidence refers
to checkout `066cc70c`; runtime behavior has not been verified locally. See the
[scope note](README.md), [diagrams](diagrams.md), and [term glossary](glossary.md).

## Q01 What are the key components and their ownership boundaries

| Component | Responsibility and starting point |
| --- | --- |
| Core `luminal` | Graph recording, logical and layout representations, egglog assembly, extraction, symbolic shapes, bufferization. Read [src/lib.rs](../../src/lib.rs). |
| Reference, CUDA Lite, Metal | Each owns its operations, bindings, implementation search, and execution. Start with [ReferenceRuntime](../../crates/luminal_reference/src/runtime.rs). |
| `luminal_nn` and `model_zoo` | Compose graphs. NN functions receive parameters/state from callers; model definitions are backend-neutral. See their [NN](../../crates/luminal_nn/src/lib.rs) and [model](../../crates/model_zoo/src/lib.rs) module docs. |
| PyTorch adapters | Python compiler entry points, Rust bindings, shared ATen-to-Luminal translation under [crates/pytorch](../../crates/pytorch/). |
| Testing and diagnostics | [test_runtime](../../tests/test_runtime/src/lib.rs) checks plans without executing kernels; [scalar_refs](../../tests/scalar_refs/src/lib.rs) supplies independent numeric references; [luminal_tracing](../../crates/luminal_tracing/src/lib.rs) emits Perfetto traces. |

The core module documentation describes the ownership rule as **“describes vs
decides”**: generic extraction is shared; choosing the fastest implementation
belongs to the runtime. See the [component diagram](diagrams.md#component-ownership).

## Q02 What happens from a Rust tensor expression to an output

Read [examples/simple.rs](../../crates/luminal_reference/examples/simple.rs).
Its complete path is:

1. `Graph::new()` and `cx.tensor(shape, dtype)` declare inputs. `a.matmul(b)`
   records operations; it does not multiply data yet.
2. `ReferenceRuntime::load(&cx)` binds inputs and graph leaves as outputs.
   Use `load_with` and explicit bindings when an intermediate must also escape,
   as in the [KV-cache smoke fixture](../../crates/luminal_reference/tests/mini_model_smoke.rs).
3. `runtime.search(bounds, profile_dims, data, options)` discovers and times
   implementations, then installs the selected plan.
4. `set_data`, `execute`, and `get_f32(c.id)` supply values, execute the plan,
   and read the result. Search's profiling data is separate from execution staging.

Following calls can reuse the installed plan with new data and valid dimensions.
The implementation is in [runtime.rs](../../crates/luminal_reference/src/runtime.rs),
particularly `load`, `search`, and `execute`.

## Q03 Why are there several intermediate representations

An IR is an intermediate representation; SSA means each value has one defining
operation. These layers answer different questions:

| Representation | What it tells you |
| --- | --- |
| [LogicalGraph](../../src/logical/ir.rs) | The computation's values, shapes, dtypes, and index transformations. No runtime storage ownership. |
| Egglog e-graph | Multiple equivalent expressions and possible implementations, grouped by equivalence. |
| [ExtractedGraph](../../src/layout/ir.rs) | One concrete, acyclic selection of operations and values with layouts. |
| [BufferIrGraph](../../src/buffer/bufferize.rs) | Values assigned to storage, with allocation, copy, free, and ordering requirements. |
| Runtime plan | Backend-specific scheduling, physical memory, and kernel execution. |

Between extraction and bufferization, [DPS lowering](../../src/layout/dps.rs)
adds explicit destination operands to operations that declare such a form.
“Destination-passing style” means the operation receives where it will write.
The [pipeline diagram](diagrams.md#compilation-and-execution) shows this sequence.

## Q04 How do egglog rewrites and implementation search cooperate

An e-graph stores alternatives believed to compute the same values. Egglog rules
add and equate alternatives until the configured saturation schedule settles.
For example, [addition's commutativity rule](../../src/logical/op/add/rewrite.egg)
equates `LogicalAdd(lhs, rhs)` with `LogicalAdd(rhs, lhs)`. Backend rules introduce
eligible physical operations.

Then the runtime searches choices of producers. A **genome** encodes those
choices; extraction makes a graph, bufferization makes a plan, and profiling
measures it. The reference search mutates choices, keeps improvements, rejects
invalid candidates, and caches duplicate measurements. This is a bounded search,
not a guarantee of the global optimum.

**Compilation executes kernels for timing.** See
[ReferenceRuntime::search](../../crates/luminal_reference/src/runtime.rs) and
[search.rs](../../crates/luminal_reference/src/search.rs), whose opening states:
“saturation discovers the implementations” and search “only SELECTS among them.”
Inspect `SearchOutcome` for timings and refusal counts.

## Q05 What are the shape layout and dtype contracts

- **Shape:** logical extents can be symbolic `IntExpr` values.
  [SymbolBounds](../../src/shape/bounds.rs) declares a program's valid intervals;
  profiling and execution supply concrete assignments separately. Timing one
  size does not justify an optimization across the entire interval.
- **Layout:** maps logical indices to physical storage. A transpose or broadcast
  records an index transformation; it need not imply a copy. See
  [movement.rs](../../src/frontend/movement.rs) and [layouts.rs](../../src/layout/layouts.rs).
- **Dtype:** declared on inputs; casts are explicit graph operations.
  [matmul.rs](../../src/frontend/matmul.rs) records broadcast/multiply/reduce in
  the operands' shared dtype and refuses mixed types. To change computation
  precision, cast the operands explicitly.

Do not equate a dtype's presence in [DType](../../src/dtype.rs) with support for
every operation on every backend. Layout, shape, and numeric preconditions belong
in the rules admitting an implementation.

## Q06 How does bufferization preserve values while reusing memory

[Bufferizable::alias_info](../../src/layout/ir.rs) declares two contracts:
`Sharing::Must` requires an operand/result storage tie; `Sharing::May` permits
sharing. Read/write effects are declared by
[BufferTensorIrOp](../../src/buffer/buffer_tensor_ir.rs).

The [bufferizer](../../src/buffer/bufferize.rs) checks writability and whether
overwriting storage would destroy a still-needed value. A rejected reuse gets
fresh storage, with a copy if old contents are required. It adds ordering edges
so writes cannot overtake readers, and emits storage lifetime events.

The subtle point: **the planner trusts operation contracts**. A `May` permission
is not a request to check layout safety later. The operation's egglog match must
already establish those preconditions. This is why aliasing bugs often belong in
a matcher or contract rather than an allocator.

## Q07 Where should a new operation or optimization be implemented

Follow one small operation end to end: [logical add](../../src/logical/op/add/mod.rs),
its [rewrite](../../src/logical/op/add/rewrite.egg), the reference
[match rule](../../crates/luminal_reference/src/ops/add/match_functional.egg),
and [Rust operation and kernel](../../crates/luminal_reference/src/ops/add/mod.rs).

| Change | Likely home |
| --- | --- |
| API convenience expressible with existing operations | `src/frontend/` |
| New primitive semantics or equivalence | Logical IR, `src/logical/op/`, and relevant egglog rules |
| Specialized or fused implementation | Backend `ops/`: egglog eligibility rule, Rust operation contract, execution implementation, and registry entry |
| Missing PyTorch operation mapping | `crates/pytorch/utils/src/translate/` and translator/parity tests |

[AGENTS.md](../../AGENTS.md) requires **“All graph pattern matching and op selection
must be expressed in egglog rewrites.”** Rust matchers decode already-selected
constructors. Generic DPS/storage lowering remains Rust machinery; adding a
Rust pass that recognizes and fuses extracted operation patterns violates the boundary.

## Q08 How does the PyTorch integration reach Luminal

The CPU public entry point is
`torch.compile(model, backend=luminal_reference.Compiler())`.
The [PyTorch diagram](diagrams.md#pytorch-reference-integration) expands this path:

1. PyTorch capture supplies an **FX GraphModule**, an inspectable graph of calls.
2. **AOTAutograd** supplies inference or forward/backward graphs. **ATen** names
   are PyTorch tensor-operation targets, such as `aten.add.Tensor`.
3. The adapter exports local computation to **PT2**, the serialized
   `torch.export` program format. Rust parses it and translates operations into
   Luminal's graph recorder.
4. Reference search installs a plan; a returned Python callable stages inputs,
   executes it, and reconstructs PyTorch outputs. Computed CPU outputs own their
   bytes, preserving saved activations across later calls.

Read [compiler.py](../../crates/pytorch/reference/python/luminal_reference/compiler.py),
[aot.py](../../crates/pytorch/reference/python/luminal_reference/aot.py),
[backend.py](../../crates/pytorch/reference/python/luminal_reference/backend.py),
[Rust binding](../../crates/pytorch/reference/src/lib.rs), then
[translate.rs](../../crates/pytorch/utils/src/translate.rs).

CUDA has a separate [Compiler](../../crates/pytorch/cuda_lite/python/luminal_cuda_lite/compiler.py)
and [adapter](../../crates/pytorch/cuda_lite/python/luminal_cuda_lite/backend.py)
that bind PyTorch device storage and manage stream ordering. CPU training behavior
should not be inferred for that separate path.

## Q09 What training and distributed execution paths actually exist

**PyTorch reference training:** AOTAutograd creates the backward graph; Luminal
compiles local computations. The [AOT tests](../../crates/pytorch/reference/tests/test_aot.py)
compare forward results, input/weight gradients, and optimizer updates against
eager PyTorch, including multiple outstanding forwards.

**Distributed CPU execution:** DTensor specifies sharding. The adapter partitions
at communication boundaries; PyTorch runs collectives and Luminal runs local
computation. The documented contract uses CPU ranks and Gloo, with fixed topology
and communication order. CUDA distributed execution and automatic sharding
selection are outside that contract. See the
[reference integration contract](../../crates/pytorch/reference/README.md) and
[SPMD tests](../../crates/pytorch/reference/tests/test_spmd.py).

**Rust training crate:** treat it as legacy pending a port. It is absent from the
[workspace members](../../Cargo.toml), and
[autograd.rs](../../crates/luminal_training/src/autograd.rs) imports
`luminal::hlir`, which current [core exports](../../src/lib.rs) do not contain.
Its incompatibility is a source-based inference, not a build result.

## Q10 Is CUDA necessary to contribute or execute a model

No. The reference runtime executes on the CPU, including small model fixtures.

| Work | Hardware requirement |
| --- | --- |
| Core, reference runtime, NN, translator, plan tests | CPU |
| CUDA Lite host-side planning/codegen tests | CPU, default `device` feature off |
| CUDA Lite implementation search and execution | NVIDIA GPU and CUDA environment, `device` feature on |
| Metal device tests and execution | macOS with usable Apple Metal GPU access |
| PyTorch reference tests | CPU; Python/native-extension environment also required |

Evidence: [CPU CI](../../.github/workflows/test-core.yml),
[CUDA feature declaration](../../crates/luminal_cuda_lite/Cargo.toml),
[CudaRuntime::search](../../crates/luminal_cuda_lite/src/runtime.rs), and
[Metal CI](../../.github/workflows/test-metal.yml).
A green CUDA run with default features does **not** establish device correctness:
[device_fidelity.rs](../../crates/luminal_cuda_lite/tests/device_fidelity.rs)
is feature-gated, and some search tests are ignored without a device.

## Q11 What is the smallest useful local run

The [manifest](../../Cargo.toml) declares Rust 1.91 and edition 2024; CI updates
the Rust toolchain. From the repository root, the smallest worked example is:

```sh
cargo run -p luminal_reference --example simple
```

It multiplies a 3×1 by a 1×4 matrix; the expected flattened result, calculated
from [its inputs](../../crates/luminal_reference/examples/simple.rs), is
`[1, 2, 3, 3, 2, 4, 6, 6, 3, 6, 9, 9]`.
For a numeric assertion through the same compiler/runtime path:

```sh
cargo test -p luminal_reference --lib differential_matmul_against_reference_runtime
```

PyTorch work additionally needs Python ≥3.10, the package's declared PyTorch
≥2.14.0, `uv`, and a maturin-built extension. The
[test script](../../crates/pytorch/reference/run_tests.sh) builds that extension:

```sh
bash crates/pytorch/reference/run_tests.sh -q -k test_forward_backward_and_optimizer_update
```

These are **future development commands**. Cargo writes build/cache artifacts;
the Python script installs/builds packages, and compilation creates temporary PT2
files. None satisfies the stdout-only constraint for this investigation. Package
availability and local toolchain compatibility remain unverified. The declarations
are in [pyproject.toml](../../crates/pytorch/reference/pyproject.toml).

## Q12 How should a contributor evaluate a diff

Follow the tiers in [AGENTS.md](../../AGENTS.md):

| Stage | Check |
| --- | --- |
| Core iteration | `cargo test -p luminal --lib` |
| Execution seam affected | Add one named reference/runtime test, such as Q11's matmul check |
| Relevant Python change | One targeted adapter or shared translator parity test |
| Landing | Broader crate suites, formatting, Clippy, and relevant hardware suites |

The contributor guide's general landing set is:

```sh
cargo test -p luminal -p luminal_reference -p luminal_cuda_lite -p test_runtime -p luminal_nn
cargo fmt --all
cargo clippy -p luminal -p luminal_reference --all-targets -- -D warnings
```

The Clippy line covers those two crates; include every changed crate. Device
validation needs additional runs on the corresponding hardware:

```sh
cargo test --release -p luminal_cuda_lite --features device -- --test-threads=1
cargo test --release -p luminal_metal -- --test-threads=1
```

[CPU CI](../../.github/workflows/test-core.yml) also includes model_zoo, tracing,
and PyTorch utilities, in release mode.
[Python CPU CI](../../.github/workflows/test-python-native.yml) excludes slow tests
and OpInfo; [CUDA CI](../../.github/workflows/test-cuda.yml) uses Modal and the
`modal-ready` PR label. [Full CUDA CI](../../.github/workflows/test-full-cuda.yml)
separately runs ignored/slow coverage with `full-modal-ready`.
[Pre-commit configuration](../../.pre-commit-config.yaml) defines formatting,
Clippy, and Python Ruff checks.

Avoid the full workspace during iteration. Mini-model tests establish execution,
not numerical parity; passing them is insufficient evidence for a compiler fix.

## Q13 How should an incorrect result be debugged

Reduce the failing graph, preserve its shapes/dtypes/layouts, and use fixed seeds.
Then inspect the earliest broken boundary:

| Symptom | Evidence to inspect and regression home |
| --- | --- |
| Wrong mathematical graph or shape | Frontend/translator output; corresponding unit or translation test |
| Equivalent alternatives disagree | Egglog rules and extracted candidates; core fixtures or runtime differential test |
| Corruption after reuse or mutation | Alias contracts, buffer plan, dependency edges; `tests/test_runtime` |
| Correct plan but wrong device values | Kernel, indexing, output layout; backend tests against reference/scalar results |

[AGENTS.md](../../AGENTS.md) requires fixing equivalence violations rather than
selecting around a bad candidate, and preserving model architecture while debugging.
Use [scalar_refs](../../tests/scalar_refs/src/lib.rs) or eager PyTorch when the
reference runtime itself may share the bug. CUDA's
[device fidelity suite](../../crates/luminal_cuda_lite/tests/device_fidelity.rs)
illustrates cross-runtime comparison.

[ToDot](../../src/visualization.rs) can expose logical, extracted, and buffer
graphs; search outcomes report phase timings and refusal reasons. For rewrite
fixtures, [corpus.rs](../../crates/luminal_reference/tests/corpus.rs) accepts
`CORPUS_ONLY` to select `.egg` scripts. Rendering/opening graphs and trace capture
can have file/UI side effects; they were not invoked here.

## Q14 What limitations and stale documentation matter most

- **Operation coverage is conditional.** Unknown ATen targets fail translation;
  the reference AOT adapter has no eager fallback for local computation. Consult
  [translate.rs](../../crates/pytorch/utils/src/translate.rs) and the relevant
  backend tests before assuming a model/dtype/layout combination works.
- **Dynamic shapes have a contract.** The reference PyTorch integration excludes
  data-dependent unbacked dimensions and changing rank. Shape-dependent branches
  can require separate guarded graphs; applications own bucketing/dispatch.
  See its [README](../../crates/pytorch/reference/README.md).
- **Some demos are blocked.** `mini_flux_runs` is ignored for an adaLN
  rejoin-divergence search issue in the
  [reference smoke suite](../../crates/luminal_reference/tests/mini_model_smoke.rs).
  The large Metal Llama example is manual-only because of a documented timeout
  in [CI](../../.github/workflows/test-metal.yml).
- **Older API descriptions can mislead.** The [main README](../../README.md)
  uses `.output()` and `cx.compile(...)`; the
  [website compiler guide](../docs/compilers.mdx) describes Rust graph-pattern
  replacement. Current [Graph](../../src/graph.rs) and
  [GraphTensor](../../src/frontend/tensor.rs) use the logical recorder, and the
  latter explicitly says “the ShapeTracker died with the HLIR pipeline.” Prefer
  Q02's example and the current rewrite boundary.

No performance or model-support claim here establishes parity across backends.
The PyTorch adapter also uses private APIs; its end-to-end tests are the practical
compatibility gate.

## Q15 What should I read first and where can I contribute

Read in this order, stopping when you can explain each transition:

1. [simple.rs](../../crates/luminal_reference/examples/simple.rs) →
   [graph.rs](../../src/graph.rs) → [matmul.rs](../../src/frontend/matmul.rs):
   understand how a familiar operation becomes recorded primitives.
2. [ReferenceRuntime::search](../../crates/luminal_reference/src/runtime.rs) →
   [search.rs](../../crates/luminal_reference/src/search.rs): locate saturation,
   extraction, DPS, bufferization, and timing.
3. [Layout IR contracts](../../src/layout/ir.rs) → the opening of
   [bufferize.rs](../../src/buffer/bufferize.rs): understand layout versus storage
   and the correctness conditions for reuse.
4. Follow the [add implementation](../../crates/luminal_reference/src/ops/add/mod.rs)
   and its `.egg` rule, then read a regression test at the layer you intend to change.

For **compiler work**, continue into [extraction.rs](../../src/extraction.rs) and
[egglog assembly](../../src/egglog_core/egglog_snippet.rs).
For **GPU work**, inspect [CUDA operation interfaces](../../crates/luminal_cuda_lite/src/op.rs)
or the [Metal registry](../../crates/luminal_metal/src/lib.rs), plus device tests.
For **PyTorch work**, follow Q08 and start with one missing mapping or boundary
case backed by eager-parity assertions. A small reproducible correctness issue
at one of these boundaries is a useful first contribution.

## Q16 Which open work is suitable for a first contribution on a Mac

The [issue map](ISSUES.md) summarizes all 18 open issues and the
[PR map](pull-requests.md) all 40 open PRs in the 2026-10-07 snapshot, with
classification, hardware needs, and discussion/source links. Proposals targeting
older APIs are distinguished from current behavior.

Start with the narrow CI reporting fix in #552 or CPU model execution coverage
in #573. The [ranked shortlist](ISSUES.md#ranked-starting-points-on-a-mac-without-cuda)
also includes scoped benchmark work (#21), equivalent-candidate testing (#20),
and an exploratory egglog debugging example (#141). The latter three need more
design or compiler familiarity; they are not five equally easy tickets.
No directly covering open PR was found for those specific scopes, but related
PRs and the limits of that check are recorded. No fixes or tests were executed.
