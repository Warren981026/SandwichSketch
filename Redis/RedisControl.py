from base64 import decode
from calendar import day_abbr
from pickle import FALSE
import string
from time import time
from redis import Redis
from math import log2
import csv
import argparse


def read_data_caida16():
    data = []
    with open("./datasets/CAIDA.dat", "rb") as file_in:
        while True:
            time = file_in.read(8)
            if not time:
                break
            _ = file_in.read(8)

            id = _.hex()
            id = int(id, 16)
            data.append(str(id))
            # data.append(str(_))
    # print(type(_))
    # print(data[:10])
    # data1 = ['7351735596318907619','7495401414670953371','8098596509523683178','4107829575238621661','3142382553768490378'] * 100000
    # print(data1[:10])
    return data[:500000]
    # return data1


def test_throughput(name, memory, p1d, p2d, data):
    rd = Redis(decode_responses=True)
    rd.delete("test")
    pp = rd.execute_command(f"{name}.create", "test", memory, p1d, p2d)
   
    time_start = time()
    res = rd.execute_command(f"{name}.insert", "test", *data)
    time_end = time()
    throughput_insert = len(data)/(time_end - time_start)
    return throughput_insert

def runtest(name, memory, p1d, p2d, epoches):
    print("memory: " + str(memory))
    print("part1 hash num: " + str(p1d))
    print("part2 hash num: " + str(p2d))

    data = read_data_caida16()
    
    ls = [test_throughput(name, memory, p1d, p2d, data) for i in range(epoches)]
    print(ls)

    print("Insert throughput is: ", sum(ls) / epoches)
    

if __name__ == "__main__":
    print("start")
    res = []

    parser = argparse.ArgumentParser()
    parser.add_argument("-name", type=str, required=True, help="Software version or hardware version")
    parser.add_argument("-memory", type=int, required=True, help="the memory")
    parser.add_argument("-p1d", type=int, required=True, help="the part1 hash num")
    parser.add_argument("-p2d", type=int, required=True, help="the part2 hash num")
    args = parser.parse_args()
    
    runtest(args.name, args.memory * 1000, args.p1d, args.p2d, 3)
