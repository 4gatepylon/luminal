# Luminal contributor questions

These questions focus on making and evaluating a first contribution. Keep the
Q numbers stable as the set grows; add new questions at the end and use follow-up
questions to deepen a topic. The matching explanations live in [answers.md](answers.md).

## Q01 What are the key components and their ownership boundaries

Which parts describe computation, choose implementations, and execute them?

## Q02 What happens from a Rust tensor expression to an output

Where are inputs supplied, compilation performed, and outputs selected?

## Q03 Why are there several intermediate representations

What does each representation add, and which one should a contributor inspect?

## Q04 How do egglog rewrites and implementation search cooperate

What is an e-graph, what gets searched, and does compilation execute kernels?

## Q05 What are the shape layout and dtype contracts

How do dynamic dimensions, tensor views, and numeric precision affect correctness?

## Q06 How does bufferization preserve values while reusing memory

Where are aliasing, mutation, copies, and lifetimes decided?

## Q07 Where should a new operation or optimization be implemented

Which changes belong in the frontend, egglog, or a runtime?

## Q08 How does the PyTorch integration reach Luminal

What do FX, ATen, AOTAutograd, and PT2 mean along this path?

## Q09 What training and distributed execution paths actually exist

Which capabilities belong to PyTorch, and is the Rust training crate current?

## Q10 Is CUDA necessary to contribute or execute a model

Which checks run on a CPU, and which require NVIDIA or Apple hardware?

## Q11 What is the smallest useful local run

What tools and commands establish a working CPU path, and what do they write?

## Q12 How should a contributor evaluate a diff

Which tests belong in the iteration loop, which belong before landing, and what
does CI cover?

## Q13 How should an incorrect result be debugged

Where should a regression test live, and what makes a useful correctness oracle?

## Q14 What limitations and stale documentation matter most

Which apparent capabilities should not be assumed from names or examples alone?

## Q15 What should I read first and where can I contribute

What short reading sequence explains the system, with branches for different
contribution areas?

## Q16 Which open work is suitable for a first contribution on a Mac

What are the open issues and PRs about, where do they sit in the stack, and which
bounded tasks can be validated without CUDA and have no directly covering PR?
