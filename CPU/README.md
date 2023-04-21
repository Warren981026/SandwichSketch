# CPU implementation
## Repository structure

- `Common/`: the hash and mmap functions
- `Struct/`: the data structures, such as heap, sketch and hash table
- `Algos/`: our and other baseline algorithms
- `Bench/`: the benchmarks about full set frequent item estimation and subset frequent item estimation
- `results/`: the files stored intermediate results
- `datasets/`: the datasets we used, CAIDA & MAWI & WEBPAGE

## Requirements

- cmake
- g++
- python3
    - pandas

## Usage

* First you need to build our code.

```sh
mkdir build results datasets
cd bulid
cmake ..
make
```
* run `./CPU [Experimental Type] [Dataset Type] [Algortihm]` to measure the algorithm's performance.

There is a table about the parameters you can choose.

| Options | Parameter |
| ---    | --- |
| Experimental Type | `SubsetHH`, `SubsetHC`, `SubsetHHH`, `SubsetHHH2`, `FullSetHH`, `FullSetHC`, `SubsetDHH`
| Dataset Type | `CAIDA`, `MAWI`, `WEBPAGE`
| Algorithm | `CocoSketch`, `Ours`, `USSHeap`, `USS` for subset frequent item estimation, `CocoSketch`, `Ours`, `USSHeap`, `USS`, `CMHash`, `CountHash` for full set frequent item estimation

* For example, `./CPU FullSetHH CAIDA Ours` will display the full set heavy hitter detection result about Our algorithm using CAIDA dataset.

* Note that `SubsetHH`, `SubsetHC`, `SubsetDHH` are special, running the `./CPU` command would not display the result, you need to run the corresponding parser after running the `./CPU` command

    * run `python3 HHResult.py [Memory Size(KB)]` to get a summary of subset heavy hitter detection result.
    * run `python3 HCResult.py [Memory Size(KB)]` to get a summary of subset heavy change detection result.
    * run `python3 DHHResult.py [Memory Size(KB)] [Node Num] [Large Node Param] [Rate] [Is disjoint]` to get a summary of distributed subset heavy hitter detection result.
    * You can change `MultiAlgs` & `AllAlgs` in this parsers to change the algorithms you want. 
