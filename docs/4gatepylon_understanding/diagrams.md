# Luminal architecture diagrams

These diagrams summarize the current source relationships. Arrows show computation
flow or use of shared machinery, not an exhaustive Cargo dependency graph.

## Component ownership

```mermaid
flowchart TD
    App[Application] --> Models[model_zoo and luminal_nn]
    App --> Torch[PyTorch compiler adapters]
    Models --> Record[Core Graph and GraphTensor recorder]
    Torch --> Translate[Shared ATen translator]
    Translate --> Record
    Record --> Logical[LogicalGraph]
    Logical --> Runtimes[Reference or CUDA Lite or Metal runtime]
    Runtimes --> Registry[Runtime operation registry and egglog match rules]
    Runtimes --> Shared[Core egglog assembly, extraction, DPS and bufferization]
    Registry --> Shared
    Shared --> Plans[Candidate buffer plans]
    Plans --> Choose[Runtime profiling and selection]
    Choose --> Execute[Runtime execution]
    Test[test_runtime fixtures] -.-> Shared
```

The runtime drives compilation using core machinery and its own operation set.
`test_runtime` exercises plan properties and has no kernel executor.
Evidence: [core modules](../../src/lib.rs),
[reference modules](../../crates/luminal_reference/src/lib.rs), and
[test_runtime](../../tests/test_runtime/src/lib.rs).

## Compilation and execution

```mermaid
flowchart TD
    Record[Tensor expressions record logical values] --> Bind[Runtime binds inputs and outputs]
    Bind --> Egg[Assemble logical rules, backend rules and shape bounds]
    Egg --> Saturate[Saturate egglog once]
    Saturate --> Space[E-graph of alternatives]
    Space --> Extract[Extract using producer choices]
    Extract --> Dps[Add declared destination operands]
    Dps --> Buffer[Bufferize with alias and lifetime contracts]
    Buffer --> Profile[Runtime executes and times candidate]
    Profile --> Select[Update best candidate]
    Select -->|More search budget| Mutate[Mutate producer choices]
    Mutate --> Extract
    Select -->|Search complete| Install[Install selected plan]
    Inputs[New input data and valid dimensions] --> Run[Execute installed plan]
    Install --> Run
    Run --> Outputs[Read bound outputs]
```

Invalid candidates can be rejected during extraction, planning, or runtime
validation; those exits are omitted. Profiling belongs to compilation, so search
requires a working executor. Subsequent execution reuses the selected plan.
Evidence: [reference search](../../crates/luminal_reference/src/search.rs),
[runtime lifecycle](../../crates/luminal_reference/src/runtime.rs), and
[DPS lowering](../../src/layout/dps.rs).

## PyTorch reference integration

```mermaid
flowchart TD
    Python[PyTorch model and torch.compile] --> FX[Captured FX GraphModule]
    FX --> AOT[AOTAutograd inference or forward and backward graphs]
    AOT --> Partition[Split local compute and communication regions]
    Partition --> Local[Local ATen computation]
    Partition --> Comm[PyTorch collectives and waits]
    Local --> PT2[Export and serialize PT2 program]
    PT2 --> Parse[Rust PT2 parser and shared translator]
    Parse --> Logical[Luminal logical graph]
    Logical --> Compile[Reference search and buffer plan]
    Compile --> Callable[Compiled local callable]
    Tensors[Caller tensors on each invocation] --> Callable
    Callable --> Runtime[Stage bytes and execute ReferenceRuntime]
    Runtime --> Result[Owned PyTorch outputs and mutation writebacks]
    Result --> Order[Adapter preserves original region order]
    Comm --> Order
```

Single-process graphs may have no communication regions. PyTorch owns
differentiation and communication; Luminal compiles local compute regions.
The CUDA adapter has a different compilation and storage-binding path.
Evidence: [AOT adapter](../../crates/pytorch/reference/python/luminal_reference/aot.py),
[local backend](../../crates/pytorch/reference/python/luminal_reference/backend.py),
[native binding](../../crates/pytorch/reference/src/lib.rs), and
[translator](../../crates/pytorch/utils/src/translate.rs).
