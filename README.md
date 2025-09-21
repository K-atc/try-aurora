try-AURORA
====

Evaluation of AURORA (Root Cause Analysis Automation Approach) against reproduced bugs using Magma.

AURORA: https://github.com/RUB-SysSec/aurora (original version)
Magma: https://github.com/K-atc/magma (Forked/modified version)


Dependencies
----
- Scala CLI
- https://github.com/K-atc/work-desk
    - invokes docker container


Installation
----
```shell
### After cloning this repository
git submodule update --init --recursive

work-desk/setup.sc aurora
```


Run
----
### TIF008, SSL020
Run work-desk (`work-desk/shell.sc magma:aurora-based`) and then run:
1. build_libtiff.sh
2. crash_exploration.sh
3. tracing.sh
4. rca.sh
