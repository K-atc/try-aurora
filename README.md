try-AURORA
====

AURORA: https://github.com/RUB-SysSec/aurora

Dependencies: 
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


TIF008
----
Run work-desk (`work-desk/shell.sc magma:aurora-based`) and then run:
1. build_libtiff.sh
2. crash_exploration.sh

