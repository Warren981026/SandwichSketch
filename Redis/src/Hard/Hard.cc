#include "Hard.h"
#include <regex.h>
#include <iostream>
#include <algorithm>
#include <unordered_map>
#include <string>
#include <vector>

#define REDIS_MODULE_TARGET

#ifdef REDIS_MODULE_TARGET
#include "util/redismodule.h"
#define CALLOC(count, size) RedisModule_Calloc(count, size)
#define FREE(ptr) RedisModule_Free(ptr)
#else
#define CALLOC(count, size) calloc(count, size)
#define FREE(ptr) free(ptr)
#endif

#define HASH(key, keylen, i) MurmurHash2(key, keylen, i)

uint32_t HardCocoSketch::Query(void *o, const char *key, size_t key_len)
{
    return ((HardCocoSketch *)o)->query(key, key_len);
}

void HardCocoSketch::Create(uint32_t _MEMORY, uint32_t _PART1_HASH_NUM, uint32_t _PART2_HASH_NUM)
{
    assert(_MEMORY);

    total_packets = 0;

    PART1_HASH_NUM = _PART1_HASH_NUM;
    PART2_HASH_NUM = _PART2_HASH_NUM;
    TOPK_RATIO = 0.5;
    COCO_RATIO = 1 - TOPK_RATIO;

    TOPK_LENGTH = _MEMORY * TOPK_RATIO / (PART1_HASH_NUM + PART2_HASH_NUM) / sizeof(uint32_t);
    COCO_LENGTH = _MEMORY * COCO_RATIO / sizeof(uint32_t);

    std::cerr << PART1_HASH_NUM << ' ' << PART2_HASH_NUM << '\n';
    std::cerr << _MEMORY << ' ' << TOPK_LENGTH << ' ' << COCO_LENGTH << '\n';

    assert(TOPK_LENGTH && COCO_LENGTH);

    topk_keys     = (char **)   CALLOC((PART1_HASH_NUM + PART2_HASH_NUM) * TOPK_LENGTH, sizeof(char *));
    topk_keylens  = (size_t *)  CALLOC((PART1_HASH_NUM + PART2_HASH_NUM) * TOPK_LENGTH, sizeof(size_t));
    topk_counters = (uint32_t *)CALLOC((PART1_HASH_NUM + PART2_HASH_NUM) * TOPK_LENGTH, sizeof(uint32_t));

    coco_keys     = (char **)   CALLOC(COCO_LENGTH, sizeof(char *));
    coco_keylens  = (size_t *)  CALLOC(COCO_LENGTH, sizeof(size_t));
    coco_counters = (uint32_t *)CALLOC(COCO_LENGTH, sizeof(uint32_t));

    memset(topk_keylens , 0, (PART1_HASH_NUM + PART2_HASH_NUM) * TOPK_LENGTH * sizeof(size_t));
    memset(topk_counters, 0, (PART1_HASH_NUM + PART2_HASH_NUM) * TOPK_LENGTH * sizeof(uint32_t));

    memset(coco_keylens , 0, COCO_LENGTH * sizeof(size_t));
    memset(coco_counters, 0, COCO_LENGTH * sizeof(uint32_t));
}

void HardCocoSketch::Destroy()
{
    FREE(topk_keys);
    FREE(topk_keylens);
    FREE(topk_counters);
    FREE(coco_keys);
    FREE(coco_keylens);
    FREE(coco_counters);
}

HardCocoSketch::HardCocoSketch(uint32_t _MEMORY, uint32_t _PART1_HASH_NUM, uint32_t _PART2_HASH_NUM)
{
    Create(_MEMORY, _PART1_HASH_NUM, _PART2_HASH_NUM);
}

HardCocoSketch::~HardCocoSketch()
{
    Destroy();
}

long long HardCocoSketch::insert(const char *_key, size_t key_len, uint32_t count)
{
    assert(_key);
    assert(key_len);

    char *key = (char *) CALLOC(key_len, sizeof(char));
    memcpy(key, _key, key_len);

    total_packets += count;

    for(uint32_t i = 0; i < PART1_HASH_NUM; i++){
        uint32_t pos = i * TOPK_LENGTH + HASH(key, key_len, i) % TOPK_LENGTH;
        if(key_len == topk_keylens[pos] &&
           strncmp(key, topk_keys[pos], key_len) == 0) {
            topk_counters[pos] += count;
            return 1;
        }else if(topk_counters[pos] == 0){
            std::swap(topk_keys[pos], key);
            std::swap(topk_keylens[pos], key_len);
            std::swap(topk_counters[pos], count);
            return 1;
        }else if((rand() % (topk_counters[pos] + count)) < count){
            // w.p. f1/(f1+f2)
            std::swap(topk_keys[pos], key);
            std::swap(topk_keylens[pos], key_len);
            std::swap(topk_counters[pos], count);
        }
    }

    for(uint32_t i = PART1_HASH_NUM; i < PART1_HASH_NUM + PART2_HASH_NUM; i++){
        uint32_t pos = i * TOPK_LENGTH + HASH(key, key_len, i) % TOPK_LENGTH;
        if(key_len == topk_keylens[pos] &&
           strncmp(key, topk_keys[pos], key_len) == 0) {
            topk_counters[pos] += count;
            return 1;
        }else if(topk_counters[pos] == 0){
            std::swap(topk_keys[pos], key);
            std::swap(topk_keylens[pos], key_len);
            std::swap(topk_counters[pos], count);
            return 1;
        }else if(topk_counters[pos] < count){
            std::swap(topk_keys[pos], key);
            std::swap(topk_keylens[pos], key_len);
            std::swap(topk_counters[pos], count);
        }
    }

    uint32_t pos = HASH(key, key_len, PART1_HASH_NUM + PART2_HASH_NUM) % COCO_LENGTH;
    if(key_len == coco_keylens[pos] &&
       strncmp(key, coco_keys[pos], key_len) == 0){
        coco_counters[pos] += count;
    }else if(coco_counters[pos] == 0){
        std::swap(coco_keys[pos], key);
        std::swap(coco_keylens[pos], key_len);
        coco_counters[pos] = count;
    }else{
        coco_counters[pos] += count;
        if((rand() % (coco_counters[pos] + count)) < count){
            std::swap(coco_keys[pos], key);
            std::swap(coco_keylens[pos], key_len);
            std::swap(coco_counters[pos], count);
        }
    }

    if (key_len)
        FREE(key);

    return 1;
}

uint32_t HardCocoSketch::query(const char *key, size_t key_len)
{
    return 0;
    uint32_t result = 0;
    for(uint32_t i = 0; i < PART1_HASH_NUM + PART2_HASH_NUM; i++) {
        uint32_t pos = i * TOPK_LENGTH + HASH(key, key_len, i) % TOPK_LENGTH;
        if(key_len == topk_keylens[pos] &&
           strncmp(key, topk_keys[pos], key_len) == 0)
            result += topk_counters[pos];
    }
    uint32_t pos = HASH(key, key_len, PART1_HASH_NUM + PART2_HASH_NUM) % COCO_LENGTH;
    if(key_len == coco_keylens[pos] &&
       strncmp(key, coco_keys[pos], key_len) == 0)
        result += coco_counters[pos];
    return result;
}

int HardCocoSketch::query_total_packets() { return total_packets; }