# Luminal contributor glossary

Terms used in this guide and the main contribution paths, grouped for lookup;
linked names lead to implementation evidence, and [answers.md](answers.md)
explains how the pieces fit together.

## Main components

- **Luminal / `luminal`**: The core Rust crate records tensor computations and provides shared compiler representations, rewrite machinery, extraction, and memory planning.
- **Frontend**: The API or translator that turns user expressions into Luminal's logical computation graph.
- **Backend**: The target-specific implementation of compilation and execution, such as the reference, CUDA Lite, or Metal backend.
- **Runtime**: The component that binds data, selects implementations, manages execution resources, and runs a compiled plan.
- **[`Graph`](../../src/graph.rs)**: The Rust object that records a computation's logical operations and symbolic dimension assignments.
- **[`GraphTensor`](../../src/frontend/tensor.rs)**: A handle to a recorded tensor value and its shape/dtype, without the actual tensor data.
- **[`luminal_reference` / `ReferenceRuntime`](../../crates/luminal_reference/src/lib.rs)**: The CPU executor and associated compiler/search implementation used as a correctness reference for other backends.
- **[`luminal_cuda_lite` / `CudaRuntime`](../../crates/luminal_cuda_lite/src/lib.rs)**: The NVIDIA backend, with CPU-testable planning machinery and GPU-dependent search and execution.
- **[`luminal_metal` / `MetalRuntime`](../../crates/luminal_metal/src/lib.rs)**: The backend that executes Luminal computations through Apple's Metal GPU API.
- **[`luminal_nn`](../../crates/luminal_nn/src/lib.rs)**: Functional neural-network building blocks that compose caller-supplied parameters and state into graphs.
- **[`model_zoo`](../../crates/model_zoo/src/lib.rs)**: Backend-neutral model architectures and small model fixtures built from Luminal operations.
- **[`luminal_pytorch_utils`](../../crates/pytorch/utils/src/lib.rs)**: Shared Rust code for parsing exported PyTorch programs and translating them into Luminal graphs.
- **PyTorch compiler adapters**: Python and Rust bindings that let `torch.compile` invoke Luminal's reference or CUDA Lite backend.
- **[`test_runtime`](../../tests/test_runtime/src/lib.rs)**: A test-only operation vocabulary and harness for checking compiler plans without executing kernels.
- **[`scalar_refs`](../../tests/scalar_refs/src/lib.rs)**: Independent, plain-Rust numeric implementations used to check runtime results.
- **[`luminal_tracing`](../../crates/luminal_tracing/src/lib.rs)**: Instrumentation that records execution and compiler activity in Perfetto-compatible traces.
- **[`luminal_training`](../../crates/luminal_training/src/autograd.rs)**: A legacy Rust autograd implementation outside the current workspace that still refers to removed core APIs.

## Graphs and compiler search

- **IR (intermediate representation)**: A structured form of a program used at a particular stage of compilation.
- **SSA (static single assignment)**: A representation where each value has one defining operation, even when its eventual storage may be reused.
- **DAG (directed acyclic graph)**: A graph of directed dependencies with no cycle, allowing operations to be ordered for execution.
- **[`LogicalGraph`](../../src/logical/ir.rs)**: The recorded mathematical computation, including tensor operations and shapes but excluding runtime storage ownership.
- **`ValueId`**: The identity of a logical value, represented here by the graph node that produces it.
- **Logical operation / primitive**: A basic mathematical operation, such as addition or reduction, used to express larger computations.
- **[`ExtractedGraph` / Layout IR](../../src/layout/ir.rs)**: One concrete graph of selected implementation operations and tensor layouts extracted from the alternatives.
- **[`BufferIrGraph` / buffer IR](../../src/buffer/bufferize.rs)**: A lowered graph that assigns values to storage and records copies, allocations, frees, and required ordering.
- **HLIR / LLIR**: High-level and low-level intermediate representation labels found in older code and discussions, whose exact meaning depends on the pipeline version.
- **ShapeTracker**: The former frontend structure for tracking tensor views and strides, removed from the current `GraphTensor` architecture.
- **Lowering**: Translating a program into a more execution-specific representation while preserving its intended result.
- **Fusion**: Implementing several logical operations together to reduce intermediate storage or execution overhead.
- **[`egglog`](../../src/egglog_core/egglog_snippet.rs)**: The declarative rule engine Luminal uses to infer facts and discover equivalent expressions and eligible implementations.
- **`.egg` file**: A source file containing egglog declarations, rules, schedules, or assertions.
- **E-graph**: A data structure that compactly stores many expressions together with their known equivalences.
- **E-class**: A group of expressions that the e-graph currently treats as equivalent.
- **E-node**: One expression node within an e-class, whose children refer to other e-classes.
- **Constructor**: A named expression form and its arguments, such as `LogicalAdd(lhs, rhs)`.
- **Rewrite rule**: A rule that introduces an equivalent expression when its pattern and preconditions match.
- **Saturation / fixpoint**: Repeatedly applying rules until they add no further information under the chosen schedule.
- **Ruleset / saturation schedule**: A named group of rules and the instructions controlling when and how often groups run.
- **Extraction**: Turning selected e-graph alternatives into one concrete implementation graph.
- **[`OpMatcher`](../../src/layout/ir.rs)**: A runtime-provided adapter that contributes egglog implementation rules and decodes their constructors into Rust operations.
- **Constructor decoder**: Code that interprets a serialized egglog expression according to its declared constructor and argument structure.
- **Operation registry / allow-list**: The runtime's catalog of available operations and the subset eligible for a particular extraction or search.
- **Producer**: An operation and output slot that can compute a requested value.
- **[`Genome`](../../src/extraction.rs)**: A mapping from tensor e-classes to chosen producers that specifies an implementation candidate.
- **Search mutation**: A change to producer choices in a genome, used to explore another implementation candidate.
- **Implementation search**: The runtime's bounded exploration of candidate plans to find one with better measured performance.
- **Profiling**: Executing a candidate to measure its cost, which means Luminal compilation itself can run kernels.
- **Plan fingerprint**: A representation used to recognize equivalent candidate plans and reuse measurements instead of timing duplicates.
- **Refusal**: A rejected candidate or unsupported request, such as a cyclic extraction, violated contract, or exceeded memory budget.
- **[`SearchOutcome`](../../crates/luminal_reference/src/search.rs)**: The search result containing the selected plan, measured cost, timings, and diagnostic counts.

## Tensors and layouts

- **Tensor**: A multidimensional collection of values with a shape and element type.
- **Shape / extent**: The ordered sizes of a tensor's axes, with each individual size called an extent.
- **Tensor rank / axis**: Rank counts a tensor's dimensions, while an axis identifies one of those dimensions.
- **Dtype**: The element representation, such as a floating-point, integer, or boolean type.
- **F32 / F16 / BF16 / FP8**: Floating-point formats with different storage sizes and precision, whose usable operations depend on the backend.
- **Cast**: An explicit operation that converts values from one dtype to another.
- **Layout**: The mapping from logical tensor coordinates to physical storage locations.
- **Stride**: The storage displacement caused by advancing one position along a tensor axis.
- **Contiguous / dense**: A layout with non-overlapping elements packed without gaps, with ordinary PyTorch contiguous tensors also following the default dimension order.
- **View**: A tensor interpretation that can share existing storage through a different shape or index mapping.
- **Materialization**: Computing or copying a tensor's values into explicit storage instead of representing them only as a view or expression.
- **Index map**: A function that maps coordinates in one tensor to coordinates in another, expressing transformations such as transpose or slicing.
- **Injective layout**: A layout where distinct valid logical coordinates map to distinct storage locations.
- **Broadcast**: Treating an input as repeated along compatible dimensions without necessarily copying its values.
- **Reduction**: Combining values along an axis, for example by summing them or taking their maximum.
- **Gather / scatter**: Reading selected locations into a result or writing updates to selected locations, respectively.
- **Matmul**: Matrix multiplication, expressed by the frontend as index mappings, elementwise multiplication, and reduction.
- **[`IntExpr`](../../src/shape/expression.rs)**: A symbolic integer expression used to describe dimensions and related geometry.
- **Dynamic dimension / symbol**: A named dimension whose concrete size is supplied when profiling or executing a program.
- **[`SymbolBounds` / domain](../../src/shape/bounds.rs)**: The permitted intervals for a program's symbolic dimensions, across which its implementation must remain valid.
- **Representative shape / `profile_dims`**: Concrete dimension values used to time a candidate within its declared domain.
- **Bucketing**: Compiling separate shape domains and letting the application dispatch an input to an appropriate compiled program.

## Memory and execution contracts

- **Buffer / `BufferId`**: A storage region and its identity in the plan, potentially shared by several tensor values.
- **Boundary / binding**: The interface connecting graph input/output values to caller-visible buffers, layouts, and access permissions.
- **Output escape**: A value becoming observable outside the compiled program, requiring its result storage to remain available to the caller.
- **[`DPS` (destination-passing style)](../../src/layout/dps.rs)**: An operation form that receives explicit destination operands specifying where its results will be written.
- **Bufferization**: Assigning tensor values to storage while preserving their required contents and ordering.
- **Aliasing**: Multiple tensor values or views referring to overlapping storage.
- **In-place operation / memory mutation**: An operation that overwrites existing storage rather than writing only to a separate result buffer.
- **[`Bufferizable`](../../src/layout/ir.rs)**: The operation interface that declares storage-sharing requirements and permissions for the planner.
- **`Sharing::Must`**: A required operand/result storage tie that the planner preserves, relocating storage when reuse would be unsafe.
- **`Sharing::May`**: An operation's unconditional permission for a specified operand and result to share storage safely.
- **Memory effects**: An operation's declarations of which operands read memory and which results write it.
- **Poison destination**: A placeholder destination with undefined contents that must be initialized before anything reads it.
- **Read-after-write conflict**: A situation where a read needing an older value could observe storage after another operation overwrites it.
- **Anti-dependency / WAR (write after read)**: An ordering constraint that delays an overwrite until readers of the previous value finish.
- **Lifetime**: The interval during which a stored value is still needed and its storage cannot safely be freed or reused.
- **Arena**: A larger allocation divided into regions for buffers whose storage can be reused as their lifetimes end.
- **Scratch / workspace memory**: Temporary storage needed internally by an operation and excluded from its persistent inputs and outputs.
- **Staging / readback**: Preparing input data for execution or retrieving output data afterward, potentially involving host/device transfers.
- **[`Access::ReadOnly` / `ReadWrite`](../../src/layout/ir.rs)**: Boundary permissions that either forbid writes or grant exclusive read/write access during the program's execution.
- **`FreedBy` / donation**: A declaration of who must free storage, with donation transferring that responsibility to the program independently of write permission.

## PyTorch integration

- **PyTorch**: The tensor and neural-network framework whose captured computations can be compiled by Luminal's adapters.
- **Eager execution**: Executing tensor operations as the Python program calls them, providing the baseline behavior used in many parity tests.
- **`torch.compile`**: The PyTorch entry point that captures computations and invokes a backend to produce executable graph callables.
- **Dynamo**: PyTorch's capture machinery that turns supported Python execution into graphs and guards describing when they can be reused.
- **FX / `GraphModule`**: PyTorch's graph representation and its executable module wrapper, used to inspect and transform recorded calls.
- **ATen / `aten.*`**: PyTorch's tensor-operation vocabulary, whose named targets the Luminal translator maps to logical operations.
- **`torch.export` / `ExportedProgram`**: PyTorch's export interface and resulting graph package, including input/output metadata and shape constraints.
- **PT2 / `.pt2`**: In this adapter, the serialized exported-program archive passed to Rust for parsing and translation.
- **AOT / JIT**: Ahead-of-time compilation prepares code before its later execution, while just-in-time compilation happens during application use.
- **AOTAutograd**: PyTorch machinery that prepares inference or forward/backward graphs for compilation, including when first triggered during application execution.
- **Autograd / gradient**: Automatic differentiation computes how outputs change with respect to inputs or parameters, producing derivatives called gradients.
- **Forward / backward pass**: Computing model outputs from inputs, then propagating derivatives through that computation for training.
- **Functionalization**: Representing mutations as explicit value transformations and writeback outputs so the exported graph has clear dataflow.
- **Decomposition**: Replacing a higher-level operation with simpler operations that a compiler can translate or optimize.
- **FakeTensor**: PyTorch tensor metadata used during tracing without requiring access to the represented tensor's real payload.
- **`SymInt`**: PyTorch's symbolic integer type, commonly used for dimensions whose sizes are not fixed during capture.
- **Guard / graph break**: A condition restricting graph reuse or a point where capture stops and execution returns to surrounding Python, respectively.
- **Region**: A contiguous part of a captured graph compiled locally, such as computation between communication operations.
- **ABI (application binary interface)**: The execution boundary contract for passing inputs, outputs, layouts, scalar metadata, and mutation results.
- **Writeback**: Copying or binding a computed mutation result back into the caller's original tensor or module buffer.
- **Private PyTorch API**: An internal PyTorch interface whose compatibility the adapter must verify through integration tests.

## GPU and distributed execution

- **CUDA**: NVIDIA's GPU programming platform, required for CUDA Lite device execution.
- **Metal**: Apple's GPU programming API used by the Metal backend.
- **Host / device**: The CPU side and accelerator side of execution, respectively.
- **Kernel / codegen**: A compute routine for a particular operation and the process of generating its implementation code.
- **NVRTC**: NVIDIA's runtime compiler for generated CUDA source.
- **cuBLASLt**: NVIDIA's matrix-multiplication library used by specialized CUDA Lite operations.
- **[`KernelOp` / `HostOp`](../../crates/luminal_cuda_lite/src/op.rs)**: CUDA interfaces for generated kernels or host-prepared GPU library calls, respectively.
- **Stream / synchronization**: An ordered queue of device work and the coordination needed to preserve dependencies across execution contexts.
- **CUDA graph / capture / replay**: A recorded GPU work graph, the process of creating it, and its subsequent launches.
- **DTensor / DeviceMesh**: PyTorch's distributed tensor abstraction and the device arrangement used to describe its distribution.
- **Sharding / replication**: Dividing tensor data across participants or keeping copies of the same data on multiple participants.
- **SPMD (single program multiple data)**: Running the same program on several participants, each operating on its own data portion.
- **Distributed rank / process group**: A participant's identifier and the set of participants that communicate together.
- **Collective**: A coordinated group communication operation, such as summing values across participants or gathering their tensor pieces.
- **Gloo**: The communication backend used by this repository's CPU distributed PyTorch tests and examples.

## Model terminology

- **Inference / training**: Computing predictions with existing parameters or adjusting parameters using a learning objective, respectively.
- **Weights / parameters / checkpoint**: Learned model values and a saved artifact containing them, often alongside other model state.
- **Optimizer**: An algorithm such as SGD or AdamW that updates parameters using gradients.
- **Attention**: A computation that uses query/key similarity to form weighted combinations of value vectors.
- **KV cache**: Stored attention key/value vectors from earlier tokens, reused during later decoding steps.
- **RoPE (rotary positional embedding)**: A position encoding that rotates query and key components according to token position.
- **MoE (mixture of experts)**: A model structure that routes inputs to selected learned sub-networks called experts.
- **MLP (multilayer perceptron)**: A stack of learned linear transformations and nonlinear activations used within many model blocks.
- **adaLN (adaptive layer normalization)**: Normalization whose modulation depends on conditioning information, used by the Flux model fixtures.

## Development and validation

- **Crate / Cargo workspace**: A Rust compilation unit and a group of related packages managed together by Cargo.
- **Cargo / feature flag**: Rust's build and package tool and an optional capability selected during compilation, such as CUDA Lite's `device` feature.
- **Clippy / rustfmt / Ruff**: The Rust linter, Rust formatter, and Python linting/formatting tools used by this repository.
- **PyO3 / maturin**: Rust–Python binding support and the build tool used to package those bindings as Python extensions.
- **`uv`**: The Python environment and package tool used by the backend build/test scripts.
- **CI / landing gate**: Automated integration checks and the validation expected before a change is committed or merged.
- **Smoke test**: A small execution check that establishes a path works without necessarily proving numeric correctness.
- **Differential / parity / fidelity test**: A comparison of results from two implementations, usually within an explicit numeric tolerance.
- **Semantic reference / oracle**: An independently trusted implementation or expected result used to decide whether behavior is correct.
- **Regression test / fixture**: A test preserving a previously required behavior and the reproducible inputs or program used to exercise it.
- **Fixed seed**: A chosen random-generator starting state that reproduces its number sequence, helping reproduce test inputs and search behavior.
- **OpInfo**: PyTorch's operation metadata and sample-input infrastructure used for broad operator compatibility testing.
- **Perfetto / DOT / Mermaid**: A trace-analysis format and viewer, a graph-description format, and a text-based diagram language used for diagnostics or documentation.
- **Modal**: The remote execution service used by this repository's CUDA CI jobs to obtain GPU workers.
