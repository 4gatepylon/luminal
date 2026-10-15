# Operating on e-graphs: succinct pseudocode

Think of an e-graph as **classes of alternative expressions**, plus three
operations:

```text
add(operator, argument_classes):
    canonicalize argument IDs using union-find
    if this operator + arguments already exists:
        return its class
    return a new class containing this node

merge(class1, class2):
    union their classes                 # assert known equality

rebuild():
    update arguments to their current merged class IDs
    merge classes containing identical operator + arguments
    repeat until stable                # propagate equality to parents
```

Variables and constants are nodes with no arguments: `add("a", [])`,
`add(1, [])`.

Optimization then looks like:

```text
root = build(input_expression)          # recursively calls add()

repeat:
    matches = match_all(rules, egraph)  # look through class alternatives

    for (matched_class, rule, bindings) in matches:
        replacement = build(rule.rhs, bindings)
        merge(matched_class, replacement)

    rebuild()

until nothing changes, or a resource limit is reached

return extract_cheapest_finite_expression(root)
```

For example, using exact integer arithmetic:

```text
Input:  (a * 1) + (b * 0)

Rules:
    x * 1  → x
    x * 0  → 0
    x + 0  → x
```

The iterations establish:

```text
class(a * 1) merges with class(a)
class(b * 0) merges with class(0)

The original Add now references class(a) and class(0).
The third rule merges its result with class(a).

Extraction returns: a
```

**Nothing replaces or deletes the original expressions.** After merging
`a*1` with `a`, that class contains both:

```text
A = { a, Mul(A, One) }
```

That explains the cycle directly: merging classes made an existing argument
reference point back to its own class. It represents alternatives `a`,
`a*1`, `(a*1)*1`, …; extraction can simply choose `a`.

This is conceptual e-graph pseudocode, not Luminal's exact implementation.
For the larger algebraic example, see [E-graphs through one example](e-graphs.md).
