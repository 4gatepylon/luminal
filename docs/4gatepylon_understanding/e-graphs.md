# E-graphs through one example

The connected-components intuition captures **grouping known equalities**.
The extra ingredient is **composition**: a node's arguments point to whole
equivalence classes, allowing one node to represent many expressions. Graph
edges describe arguments; equality is represented by membership in the same
class. [E-graph definitions](https://docs.rs/egg/latest/egg/struct.EGraph.html)

Consider optimizing this expression, assuming exact integer arithmetic:

```text
(a + b)*c - b*c
       ↓ distributivity
(a*c + b*c) - b*c
       ↓ cancellation
a*c
```

The compiler retains all these alternatives. Distributivity exposes a
cancellation that wasn't initially visible. This is an illustrative algebra
example; these identities require the appropriate numerical semantics and
are not automatically valid for floating-point operations.

After those rewrites, the e-graph can be represented like this:

```text
A = { a }
B = { b }
C = { c }

S = { Add(A, B) }
R = { Mul(B, C) }

P = { Mul(S, C),  Add(Q, R) }
Q = { Sub(P, R),  Mul(A, C) }   ← result class
```

Each `{…}` is an **e-class**: a collection of equivalent alternatives. Each
entry such as `Mul(S,C)` is an **e-node**: an operator plus references to
argument classes.

Here, `P` contains both `(a+b)*c` and its distributed form. `Q` contains both
the original result and `a*c`.

Three mechanisms make this useful:

1. **Rules match through alternatives.** The cancellation rule
   `(u+v)-v → u` matches `Sub(P,R)` because `P` contains `Add(Q,R)`.
   It doesn't matter that `P` also contains a multiplication. Applying the
   rule merges the result with the class for `a*c`.

2. **Equivalence propagates through composition.** Once two expressions
   share a class, every parent referencing that class can use either
   expression. If merging child classes makes two parent applications
   identical, their classes merge too. This is **congruence closure**, the
   additional machinery beyond ordinary connected components.
   [Mechanism](https://egraphs-good.github.io/egg/egg/tutorials/_01_background/index.html#invariants-and-rebuilding)

3. **Extraction chooses a concrete expression.** With arithmetic-operation
   count as the cost, extraction chooses `Mul(A,C)`: one multiplication
   instead of the original four operations. This is the compiler use case:
   explore transformations without committing early to a particular rewrite
   path. [Equality-saturation paper](https://arxiv.org/abs/2004.03082)

Infinite growth is also relevant. Notice the cycle **`Q → P → Q`**. It
compactly represents:

```text
a*c
(a*c + b*c) - b*c
((a*c + b*c) - b*c + b*c) - b*c
...
```

That cycle represents infinitely many **finite expressions**, not a runtime
loop. An extracted program selects a finite expression.

Humans define the operators and rewrite patterns; actual nodes are generated
from the input program. Sharing can compress enormous expression families,
but the e-graph itself can still grow excessively. Optimizers therefore impose
time, size, or iteration limits; they do not necessarily discover every
equivalent expression.
[Background](https://egraphs-good.github.io/egg/egg/tutorials/_01_background/index.html)

For how Luminal uses this machinery, see [Q04 in the contributor answers](answers.md#q04-how-do-egglog-rewrites-and-implementation-search-cooperate).
