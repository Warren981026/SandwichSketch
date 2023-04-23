#ifndef _HARD_H_
#define _HARD_H_

#include "util/MurmurHash2.h"

#include <assert.h>
#include <strings.h>
#include <string.h>
#include <ctype.h>
#include <string.h>

class SandwichSketch {
public:
    uint32_t PART1_HASH_NUM;
    uint32_t PART2_HASH_NUM;
    double TOPK_RATIO;
    double COCO_RATIO;

    int total_packets;
    uint32_t TOPK_LENGTH;
    uint32_t COCO_LENGTH;

    char **topk_keys;
    size_t *topk_keylens;
    uint32_t *topk_counters;

    char **coco_keys;
    size_t *coco_keylens;
    uint32_t *coco_counters;

    void Create(uint32_t _MEMORY, uint32_t _PART1_HASH_NUM, uint32_t _PART2_HASH_NUM);
    void Destroy();
    SandwichSketch(uint32_t _MEMORY, uint32_t _PART1_HASH_NUM, uint32_t _PART2_HASH_NUM);
    ~SandwichSketch();
    long long insert(const char *key, size_t key_len, uint32_t count);
    uint32_t query(const char *key, size_t key_len);
    static uint32_t Query(void *o, const char *key, size_t key_len);
    int query_total_packets();
};

#endif