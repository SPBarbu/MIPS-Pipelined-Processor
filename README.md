# ECSE425 - Winter 2021 - MIPS Pipelined Processor
Created by Stefan Barbu, Michael Frajman and Shi Tong Li

## Instructions for running the code:
- Write the desired assembly code (in binary) inside the "program.txt" file.
- To compile and run the code run the instruction: `source pipelined_processor.tcl` in modelsim. The `pipelined_processor.tcl` file contains all the commands for compilation and signal instantiation.
- The starting clock cycle needs to start on 0, not 1. The clock goes from low to high and must start from 0 to not skip a cycle.
- To reset the program you have to run it again with no `program.txt` file, the memory array defaults to "0" unless a line is read in.

## Overview of file structure:
This tree is meant to illustrate how the different `.vhd` files are used as components within each other. `pipelined_processor.vhd` is the main file.

```
pipelined_processor
    |
    |-----IF_stage
    |       |
    |       |-----instruction_memory
    |       
    |-----ID_stage
    |
    |-----EX_stage
    |
    |-----MEM_stage
    |
    |-----WB_stage   
```
