# Redis Integration

## Requirements

- cmake
- g++
- python3
- Redis

## Usage

* suppose the curernt working directory is `$REDIS_COCO`
* `mkdir datasets` and download the dataset to this fold
* `make`
* start redis server by `redis-server`, and load module by start a redis client and run `module load $REDIS_COCO/UltraCoco.so`
* run `python RedisControl.py -name HardCoco -memory {memory} -p1d {depth} -p2d {depth}` to measure the throughput
