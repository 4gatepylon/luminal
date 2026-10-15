# Understanding Luminal for contribution

Luminal records tensor computations, discovers equivalent implementations with
egglog, and lets a runtime search and execute them. The most useful boundary to
learn is between **mathematical values, physical layouts, and storage**. Changes
at that boundary can affect every backend.

Start with [the answers](answers.md), especially Q02–Q07 for the compiler and
Q10–Q13 for running and evaluating changes. Use [the questions](questions.md) as
an expandable investigation list. [Three diagrams](diagrams.md) show component
ownership, compilation and execution, and the PyTorch path. Q15 gives a short
source reading sequence. Use the [glossary](glossary.md) for one-sentence
definitions of compiler terms, PyTorch vocabulary, and important components.

[E-graphs through one example](e-graphs.md) explains equivalence classes,
rewrite matching, congruence closure, extraction, and cycles using a small
algebraic optimization.

[Operating on e-graphs](e-graphs-pseudocode.md) gives succinct pseudocode for
adding nodes, merging classes, rebuilding, rewriting, and extracting a result.

For choosing work, see the [open issues](ISSUES.md) and [open PRs](pull-requests.md):
each item has a plain-English description, stack layer, backend, and relevant
overlap or uncertainty. The [ranked Mac-friendly starting points](ISSUES.md#ranked-starting-points-on-a-mac-without-cuda)
distinguish two strong starter scopes from three larger or exploratory options.
The GitHub snapshot covers 18 issues and 40 PRs on 2026-10-07.

The main findings that may save a first contributor time:

- CPU execution and substantial compiler testing are available without CUDA.
  CUDA planning tests and actual GPU search are different gates.
- Each runtime owns its operation registry and performance-based selection.
  Core supplies shared representations and lowering machinery.
- PyTorch reference training has an AOTAutograd path. The separate Rust training
  crate still targets removed APIs.
- Some README and website examples describe an older architecture; start with
  the current reference runtime example.

Source snapshot: `066cc70c`, inspected 2026-10-07. Answers link to local evidence;
inferences and unresolved compatibility are identified where they matter.
No builds, model runs, dependency installation, or repository tests were run:
they can create artifacts and would exceed the requested stdout-only check
constraint. Commands in the answers are instructions for future development,
not claims of successful execution on this machine.

Local links and matching question/answer headings were checked with a read-only
script. Mermaid diagrams are provided as source; rendered layout was not checked.
