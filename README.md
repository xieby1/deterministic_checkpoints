
# XiangShan Checkpoint Profiling

This repository contains tools and scripts for generating deterministic checkpoints of SPEC CPU2006 benchmarks using QEMU and Simpoint. These checkpoints are designed for use with XiangShan and gem5 simulators, enabling rapid architectural exploration. The project aims to support NEMU checkpoints in the future.

## Overview

The project uses Nix to manage dependencies and build the necessary components:

- QEMU: Modified version of QEMU with checkpoint and profiling capabilities
- Simpoint: Simpoint is a tool for profiling and checkpointing in XiangShan
- OpenSBI: RISC-V OpenSBI firmware
- Linux: Custom Linux kernel image
- Profiling tools: Scripts and plugins for analyzing checkpoint data

## Preparing SPEC CPU2006 Source Code

Before using this project, you need to prepare the SPEC CPU2006 program source code yourself. Please follow these steps:

1. Obtain the SPEC CPU2006 source code (we cannot provide the source code due to licensing restrictions).
2. Rename the obtained source code folder to "spec2006".

## Nix Installation and Usage

### Installing Nix

To install Nix, run the following command:

if you are using nix on linux and have sudo permission, you can install nix by running
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```
other OS, please refer to [Nix Installation Guide](https://nixos.org/download/)

### Building and Running

first, enter nix shell
```bash
nix-shell
```

then get help
```bash
h
```

it will show you some usage tips
```
   DETERMINISTIC_CHECKPOINTS USAGE TIPS                                                                               
                                                                                                                      
  • Set SPEC CPU 2006 source code: edit  spec2006/default.nix :  srcs = [...]                                         
  • Set input size: edit  spec2006/default.nix :  size = xxx  (default input is ref)                                  
  • Generate the checkpoints of all testCases into  result/ :  nom-build -A checkpoints                               
  • Generate the checkpoints of a specific  into  result/ :  nom-build -A 'checkpoints."<testCase>"'                  
    • E.g.:  nom-build -A 'checkpoints."403.gcc"'                                                                      
```


build the project
```bash
nom-build -A checkpoints -j 10
```


Please note that the build process may take a considerable amount of time:

1. First, the script will fetch and compile the RISC-V GCC toolchain, Linux kernel, QEMU, and other necessary components. This step takes approximately 1 hour.

2. Then, it will use QEMU for profiling, SimPoint sampling, and QEMU checkpoint generation. Generating spec2006 ref input checkpoint typically requires about 10 hours.

If you want to quickly test the system, you can start by setting the input size to "test":

1. Edit the `spec2006/default.nix` file
2. Change `size = xxx` to `size = "test"`

With the test input size, the entire process should complete in about 30 minutes.

Finally, it will generate a result folder, you will get all the checkpoints in the result folder