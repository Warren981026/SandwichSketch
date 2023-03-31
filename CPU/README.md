## Repository structure

- `Common/`: the hash and mmap functions
- `Struct/`: the data structures, such as heap, sketch and hash table
- `Algos/`: our and other baseline algorithms
- `Bench/`: the benchmarks about full key query and arbitrary partial key query
- `results/`: the files stored intermediate results
- `datasets/`: the datasets we used, CAIDA & MAWI

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
| Experimental Type | `PartialKeyHH`, `PartialKeyHC`, `PartialKeyHHH`, `PartialKeyHHH2`, `FullKeyHH`, `FullKeyHC`, `PartialKeyDHH`
| Dataset Type | `CAIDA`, `MAWI`
| Algorithm | `CocoSketch`, `Ours`, `USSHeap` for Partial Key Experiment, `CocoSketch`, `Ours`, `USSHeap`, `CMHash`, `CountHash` for Full Key Experiment

* For example, `./CPU FullKeyHH CAIDA Ours` will display the Full Key Heavy Hitters experiment result about Our algorithm using CAIDA dataset.

* Note that `PartialKeyHH`, `PartialKeyHC`, `PartialKeyDHH` are special, running the `./CPU` command would not display the result, you need to run the corresponding parser after running the `./CPU` command

    * run `python3 HHResult.py [Memory Size(KB)]` to get a summary of Partial Key Heavy Hitters result.
    * run `python3 HCResult.py [Memory Size(KB)]` to get a summary of Partial Key Heavy Changes result.
    * run `python3 DHHResult.py [Memory Size(KB)] [Node Num] [Large Node Param] [Rate] [Is disjoint]` to get a summary of Distributed Partial Key Heavy Hitters result.
    * You can change `MultiAlgs` & `AllAlgs` in this parsers to change the algorithms you want. 
