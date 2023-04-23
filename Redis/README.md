# Redis implementation
## Requirements

- cmake
- g++
- python3
- Redis

## Usage

* suppose the curernt working directory is `$REDIS_SANDWICH`
* `mkdir datasets` and download the dataset to this folder
* `make`
* start redis server by `redis-server`, and load module by start a redis client and run `module load $REDIS_SANDWICH/SandwichSketch.so`
* run `python RedisControl.py -name SandwichSketch -memory {memory} -p1d {depth} -p2d {depth}` to measure the throughput
