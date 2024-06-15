# constant-overhead

A project aimed at measuring the constant overhead of various programming languages and their individual runtimes.

## Do we have a problem?

Many of the programming language benchmarks are generally not very representative:
- Task implementations usually vary wildly from language to language because programmers of lower level languages find hacks to make their code faster.
- The tasks necessitate the use of data structures and their implementations vary from platform to platform (e.g. Java's HashMap, C++'s unordered_map and Rust's HashMap have diverging design goals in a couple of places).
- They compare languages and not particular implementations.
- We don't know much about their testing rig.
- All the 'X beating C' proofs are egregious.
- ...

But there is a fundamental reason for why you'd want to compare runtimes and let this influence your language choice: boxing is not free, many runtimes can't reliably strip it off; some runtimes, particularly for dynamic languages, can not perform type inference well enough to lower FP operations to integer operations.

## Is there a solution?

This benchmark aims at testing something else: we wish to determine the *constant overhead* of a programming language. Of course, the time taken by the algorithm will grow proportionally to the input size, but from a programming standpoint, solutions that have too high constant factor (e.g. compare a program that takes 20n steps vs a program that takes 2n steps for an input of size n) are sometimes not feasible. The methodology is rather simple: take an uncomplicated algorithm which can not be improved too much using standard tricks (autovectorisation, loop unrolling) and translate it to each of the languages, applying performance tweaks (like defining types, turning off the GC, localising data) if they are feasible.

This benchmark will single out runtimes that behave badly in tight (yet very uncomplicated) loops, can't use the typing information well or infer it in the runtime, don't offer rudimentary performance improvement techniques (e.g. integer division), can't inline code efficiently, don't optimise arithmetic, use an inefficient numerical tower, and incur unavoidable penalties in array accesses.

To make this benchmark fair for runtimes that take an excessively long amount of time in warmup, we will use small and large workloads designed to amortise this. Memory usage is not measured. Only publicly available, free runtimes are tested.

FPAQ0, the test program, is a very simple order-0 statistical model coupled together with a bitwise arithmetic coder due to Matt Mahoney. We slightly simplify it and use it as a benchmark. Among data compression experts, FPAQ0 and variants are used for benchmarking particular bitwise arithmetic coding strategies.

# Benchmarks

Notes on the benchmark results below:
- PUC-RIO Lua was not tested, because it is not worth testing.
- LuaJIT lacks a way to issue `idiv` and likely pays for it, but according to `luajit -lp` most of the time is spent in the arithmetic coder anyway.
- WASI-SDK clang's standard library might use (too) small I/O buffers, worsening its performance.
- In line with the C implementation, try to not use object-oriented programming: in metatable/prototype-oriented languages, looking up a method in an object is somewhat costly. The code does, however, use any feature of the language feasible to represent the arithmetic encoder state structure that can be passed around. This often amounts to having a class with just a constructor and a few public fields.

Interesting findings:
- Turn-the-GC-off snake oil doesn't work (e.g. through enabling EpsilonGC for Java). For major runtimes this makes no difference because the program does not allocate enough to warrant a GC cycle. This is at least a bit surprising, because in programmer folklore, GC is always responsible for all the plagues of the world.

## Legendre

Notebook 20Y7003XPB (LENOVO_MT_20Y7_BU_Think_FM_ThinkPad E14 Gen 3). Specifications:
- Memory: 40GB.
  - Bank 0: SODIMM DDR4 Synchronous Unbuffered (Unregistered). Product CT32G4SFD832A.16FB2. Slot DIMM 0. Size: 32GiB. Width: 64 bits. Clock: 3200MHz (0.3ns).
  - Bank 1: SODIMM DDR4 Synchronous Unbuffered (Unregistered). Product 4ATF1G64HZ-3G2E1. Slot DIMM 0. Size: 8GiB. Width: 64 bits. Clock: 3200MHz (0.3ns).
- Cache:
  - L1: 512KiB. Clock: 1GHz (1.0ns). Capabilities: pipeline-burst internal write-back unified.
  - L2: 4MiB. Clock: 1GHz (1.0ns). Capabilities: pipeline-burst internal write-back unified.
  - L3: 8MiB. Clock: 1GHz (1.0ns). Capabilities: pipeline-burst internal write-back unified.
- CPU: AMD Ryzen 7 5700U with Radeon Graphics. Use Google to find the specification.

Results (book1):

| Benchmark | Time |
|-----------|------|
| Debian clang version 16.0.6 (27) `-O2` | 35.1 ms ± 0.7 ms [User: 33.2 ms, System: 1.5 ms] |
| gcc version 13.2.0 (Debian 13.2.0-25) `-O3 -march=native -mtune=native` | 35.6 ms ± 0.7 ms [User: 33.7 ms, System: 1.6 ms] |
| gcc version 13.2.0 (Debian 13.2.0-25) `-O2` | 35.7 ms ± 1.3 ms [User: 33.1 ms, System: 2.2 ms] |
| Debian clang version 16.0.6 (27) `-O3 -march=native -mtune=native` | 35.7 ms ± 1.6 ms [User: 33.7 ms, System: 1.8 ms] |
| wasmtime-cli 21.0.1 (cedf9aa0f 2024-05-22), wasi-sdk clang version 18.1.2 | 49.4 ms ± 1.3 ms [User: 38.1 ms, System: 12.3 ms] |
| `native-image` OpenJDK 64-Bit Server VM GraalVM CE 22.2.0 (build 17.0.4+8-jvmci-22.2-b06, mixed mode, sharing) | 87.6 ms ± 2.7 ms [User: 82.8 ms, System: 4.5 ms] |
| OpenJDK 64-Bit Server VM (build 17.0.11+9-Debian-1, mixed mode, sharing) | 97.5 ms ± 3.3 ms [User: 98.2 ms, System: 31.7 ms] |
| OpenJDK 64-Bit Server VM GraalVM CE 22.2.0 (build 17.0.4+8-jvmci-22.2-b06, mixed mode, sharing) | 123.8 ms ± 2.0 ms [User: 151.4 ms, System: 55.9 ms] |
| luajit/unstable,now 2.1.0+openresty20240314-1 `-O3` | 150.7 ms ± 4.4 ms [User: 148.0 ms, System: 2.5 ms] |
| Node.js v20.14.0 | 177.5 ms ± 2.3 ms [User: 172.4 ms, System: 32.7 ms] |
| PyPy 7.3.16 with GCC 13.2.0 | 251.2 ms ± 6.7 ms [User: 222.7 ms, System: 28.3 ms] |

Results (enwik8):
| Benchmark | Time |
|-----------|------|
| Debian clang version 16.0.6 (27) `-O2` | 4.468 s ± 0.014 s [User: 4.343 s, System: 0.124 s] |
| Debian clang version 16.0.6 (27) `-O3 -march=native -mtune=native` | 4.516 s ± 0.012 s [User: 4.386 s, System: 0.130 s] |
| gcc version 13.2.0 (Debian 13.2.0-25) `-O2` | 4.605 s ± 0.017 s [User: 4.479 s, System: 0.125 s] |
| gcc version 13.2.0 (Debian 13.2.0-25) `-O3 -march=native -mtune=native` | 4.621 s ± 0.010 s [User: 4.488 s, System: 0.132 s] |
| wasmtime-cli 21.0.1 (cedf9aa0f 2024-05-22), wasi-sdk clang version 18.1.2 | 5.333 s ± 0.058 s [User: 4.732 s, System: 0.601 s] |
| OpenJDK 64-Bit Server VM GraalVM CE 22.2.0 (build 17.0.4+8-jvmci-22.2-b06, mixed mode, sharing) | 5.608 s ± 0.046 s [User: 5.550 s, System: 0.176 s] |
| OpenJDK 64-Bit Server VM (build 17.0.11+9-Debian-1, mixed mode, sharing) | 5.996 s ± 0.085 s [User: 5.889 s, System: 0.150 s] |
| Node.js v20.14.0 | 9.412 s ± 0.096 s [User: 9.312 s, System: 0.128 s] |
| `native-image` OpenJDK 64-Bit Server VM GraalVM CE 22.2.0 (build 17.0.4+8-jvmci-22.2-b06, mixed mode, sharing) | 11.254 s ± 0.114 s [User: 11.146 s, System: 0.108 s] |
| luajit/unstable,now 2.1.0+openresty20240314-1 `-O3` | 19.610 s ± 0.152 s [User: 19.437 s, System: 0.170 s] |
| PyPy 7.3.16 with GCC 13.2.0 | 24.717 s ± 0.504 s [User: 24.101 s, System: 0.613 s] |