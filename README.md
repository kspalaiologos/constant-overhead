# constant-overhead

Problem: many of the programming language benchmarks are generally not very representative:
- Implementations usually vary wildly from language to language because programmers of lower level languages find hacks to make their code faster.
- The tasks necessitate the use of data structures and their implementations vary from platform to platform (e.g. Java's HashMap, C++'s unordered_map and Rust's HashMap have diverging design goals in a couple of places).
- They compare languages and not particular implementations.
- ...

But there is a fundamental reason for why you'd want to compare runtimes and let this influence your language choice: boxing is not free, many runtimes can't reliably strip it off; some runtimes, particularly for dynamic languages, can not perform type inference well enough to lower FP operations to integer operations.

This benchmark aims at testing something else: we wish to determine the *constant overhead* of a programming language. Of course, the time taken by the algorithm will grow proportionally to the input size, but from a programming standpoint, solutions that have too high constant factor (e.g. compare a program that takes 20n steps vs a program that takes 2n steps for an input of size n) are sometimes not feasible. The methodology is rather simple: take an uncomplicated algorithm which can not be improved too much using standard tricks (autovectorisation, loop unrolling) and translate it to each of the languages, applying performance tweaks (like defining types, turning off the GC, localising data) if they are feasible.

This benchmark will single out runtimes that behave badly in tight (yet very uncomplicated) loops, can't use the typing information well or infer it in the runtime, don't offer rudimentary performance improvement techniques (e.g. integer division), can't inline code efficiently, don't optimise arithmetic and incur unavoidable penalties in array accesses.

## fpaq0

FPAQ0 is a very simple order-0 statistical model coupled together with a bitwise arithmetic coder due to Matt Mahoney. We slightly simplify it and use it as a benchmark. Among data compression experts, FPAQ0 and variants are used for benchmarking particular bitwise arithmetic coding strategies.
