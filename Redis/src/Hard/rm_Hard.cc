#include "rm_Hard.h"

#define CALLOC(count, size) RedisModule_Calloc(count, size)
#define FREE(ptr) RedisModule_Free(ptr)

#define ERROR(x)                        \
    RedisModule_ReplyWithError(ctx, x); \
    return REDISMODULE_ERR;

typedef HardCocoSketch SKETCH;

static RedisModuleType *SKETCHType;

static int GetKey(RedisModuleCtx *ctx, RedisModuleString *keyName, SKETCH **sketch, int mode)
{
    // All using this function should call RedisModule_AutoMemory to prevent memory leak
    RedisModuleKey *key = (RedisModuleKey *)RedisModule_OpenKey(ctx, keyName, mode);
    if (RedisModule_KeyType(key) == REDISMODULE_KEYTYPE_EMPTY)
    {
        RedisModule_CloseKey(key);
        ERROR("HardCoco: key does not exist");
    }
    else if (RedisModule_ModuleTypeGetType(key) != SKETCHType)
    {
        RedisModule_CloseKey(key);
        ERROR(REDISMODULE_ERRORMSG_WRONGTYPE);
    }

    *sketch = (SKETCH *)RedisModule_ModuleTypeGetValue(key);
    RedisModule_CloseKey(key);
    return REDISMODULE_OK;
}

static int create(RedisModuleCtx *ctx, RedisModuleString **argv, int argc, SKETCH **sketch)
{
    long long MEMORY;
    long long PART1_HASH_NUM;
    long long PART2_HASH_NUM;
    if ((RedisModule_StringToLongLong(argv[2], &MEMORY) != REDISMODULE_OK) || MEMORY < 1)
    {
        ERROR("HardCoco: invalid MEMORY");
    }
    if ((RedisModule_StringToLongLong(argv[3], &PART1_HASH_NUM) != REDISMODULE_OK) || PART1_HASH_NUM < 1)
    {
        ERROR("HardCoco: invalid PART1_HASH_NUM");
    }
    if ((RedisModule_StringToLongLong(argv[4], &PART2_HASH_NUM) != REDISMODULE_OK) || PART2_HASH_NUM < 1)
    {
        ERROR("HardCoco: invalid PART2_HASH_NUM");
    }
    *sketch = (SKETCH *)CALLOC(1, sizeof(SKETCH));
    (*sketch)->Create(MEMORY, PART1_HASH_NUM, PART2_HASH_NUM);
    return REDISMODULE_OK;
}

static int Create_Cmd(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
    if (argc != 5)
    {
        return RedisModule_WrongArity(ctx);
    }

    RedisModuleKey *key = (RedisModuleKey *)RedisModule_OpenKey(ctx, argv[1], REDISMODULE_READ | REDISMODULE_WRITE);
    SKETCH *sketch = NULL;
    if (RedisModule_KeyType(key) != REDISMODULE_KEYTYPE_EMPTY)
    {
        RedisModule_ReplyWithError(ctx, "HardCoco: key already exists");
        goto final;
    }

    if (create(ctx, argv, argc, &sketch) != REDISMODULE_OK)
        goto final;

    if (RedisModule_ModuleTypeSetValue(key, SKETCHType, sketch) == REDISMODULE_ERR)
    {
        goto final;
    }

    RedisModule_ReplicateVerbatim(ctx);
    RedisModule_ReplyWithSimpleString(ctx, "OK");
final:
    RedisModule_CloseKey(key);
    return REDISMODULE_OK;
}

static int Insert_Cmd(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{

    if (argc < 3)
        return RedisModule_WrongArity(ctx);

    SKETCH *sketch;
    if (GetKey(ctx, argv[1], &sketch, REDISMODULE_READ | REDISMODULE_WRITE) != REDISMODULE_OK)
    {
        return REDISMODULE_OK;
    }

    int itemCount = argc - 2;
    RedisModule_ReplyWithArray(ctx, itemCount);

    for (int i = 0; i < itemCount; ++i)
    {
        size_t itemlen;
        const char *item = RedisModule_StringPtrLen(argv[i + 2], &itemlen);
        long long result = sketch->insert(item, itemlen, 1);
        RedisModule_ReplyWithLongLong(ctx, result);
    }
    RedisModule_ReplicateVerbatim(ctx);
    return REDISMODULE_OK;
}

static int Query_Cmd(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
    if (argc < 3)
        return RedisModule_WrongArity(ctx);

    SKETCH *sketch;
    if (GetKey(ctx, argv[1], &sketch, REDISMODULE_READ) != REDISMODULE_OK)
        return REDISMODULE_ERR;

    size_t itemlen;
    long long res;
    RedisModule_ReplyWithArray(ctx, argc - 2);
    for (int i = 2; i < argc; ++i)
    {
        const char *item = RedisModule_StringPtrLen(argv[i], &itemlen);
        res = sketch->query(item, itemlen);
        RedisModule_ReplyWithLongLong(ctx, res);
    }

    return REDISMODULE_OK;
}

static int Info_Cmd(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{

    if (argc != 2)
        return RedisModule_WrongArity(ctx);

    SKETCH *sketch = NULL;
    if (GetKey(ctx, argv[1], &sketch, REDISMODULE_READ) != REDISMODULE_OK)
    {
        return REDISMODULE_OK;
    }

    RedisModule_ReplyWithArray(ctx, 3 * 2);
    RedisModule_ReplyWithSimpleString(ctx, "TOPK_LENGTH");
    RedisModule_ReplyWithLongLong(ctx, sketch->TOPK_LENGTH);
    RedisModule_ReplyWithSimpleString(ctx, "COCO_LENGTH");
    RedisModule_ReplyWithLongLong(ctx, sketch->COCO_LENGTH);
    RedisModule_ReplyWithSimpleString(ctx, "total");
    RedisModule_ReplyWithLongLong(ctx, sketch->total_packets);

    return REDISMODULE_OK;
}

static void RdbSave(RedisModuleIO *io, void *obj)
{
    SKETCH *sketch = (SKETCH *)obj;
    RedisModule_SaveUnsigned(io, sketch->TOPK_LENGTH);
    RedisModule_SaveUnsigned(io, sketch->COCO_LENGTH);
    RedisModule_SaveStringBuffer(io, (const char *)sketch->topk_keylens, 
                                (sketch->PART1_HASH_NUM +sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH * sizeof(size_t));
    RedisModule_SaveStringBuffer(io, (const char *)sketch->topk_counters, 
                                (sketch->PART1_HASH_NUM +sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH * sizeof(uint32_t));
    RedisModule_SaveStringBuffer(io, (const char *)sketch->coco_keylens,  sketch->COCO_LENGTH * sizeof(size_t));
    RedisModule_SaveStringBuffer(io, (const char *)sketch->coco_counters, sketch->TOPK_LENGTH * sizeof(uint32_t));
    
    for (uint32_t i = 0; i < (sketch->PART1_HASH_NUM * sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH; ++i)
        if (sketch->topk_keylens[i])
            RedisModule_SaveStringBuffer(io, (const char *)sketch->topk_keys[i], sketch->topk_keylens[i] * sizeof(char));

    for (uint32_t i = 0; i < sketch->COCO_LENGTH; ++i)
        if (sketch->coco_keylens[i])
            RedisModule_SaveStringBuffer(io, (const char *)sketch->coco_keys[i], sketch->coco_keylens[i] * sizeof(char));
}

static void *RdbLoad(RedisModuleIO *io, int encver)
{
    if (encver > HARD_ENC_VER)
    {
        return NULL;
    }
    SKETCH *sketch = (SKETCH *)CALLOC(1, sizeof(SKETCH));
    sketch->TOPK_LENGTH = RedisModule_LoadUnsigned(io);
    sketch->COCO_LENGTH = RedisModule_LoadUnsigned(io);

    size_t tmp;

    sketch->topk_keylens = (size_t *)RedisModule_LoadStringBuffer(io, &tmp);
    assert(tmp == (sketch->PART1_HASH_NUM +sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH * sizeof(size_t));

    sketch->topk_counters = (uint32_t *)RedisModule_LoadStringBuffer(io, &tmp);
    assert(tmp == (sketch->PART1_HASH_NUM +sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH * sizeof(uint32_t));

    sketch->coco_keylens = (size_t *)RedisModule_LoadStringBuffer(io, &tmp);
    assert(tmp == sketch->COCO_LENGTH * sizeof(size_t));

    sketch->coco_counters = (uint32_t *)RedisModule_LoadStringBuffer(io, &tmp);
    assert(tmp == sketch->COCO_LENGTH * sizeof(uint32_t));

    sketch->topk_keys = (char **)CALLOC((sketch->PART1_HASH_NUM + sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH, sizeof(char *));

    for (uint32_t i = 0; i < (sketch->PART1_HASH_NUM * sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH; ++i)
        if (sketch->topk_keylens[i])
            sketch->topk_keys[i] = (char *)RedisModule_LoadStringBuffer(io, &tmp);

    for (uint32_t i = 0; i < sketch->COCO_LENGTH; ++i)
        if (sketch->coco_keylens[i])
            sketch->coco_keys[i] = (char *)RedisModule_LoadStringBuffer(io, &tmp);
    return sketch;
}

static void Free(void *value)
{
    SKETCH *sketch = (SKETCH *)value;
    sketch->Destroy();
    FREE(sketch);
}

static size_t MemUsage(const void *value)
{
    SKETCH *sketch = (SKETCH *)value;
    return sizeof(SKETCH) + (sketch->PART1_HASH_NUM + sketch->PART2_HASH_NUM) * sketch->TOPK_LENGTH * sizeof(uint32_t)
                          + sketch->COCO_LENGTH * sizeof(uint32_t);
}

int HardModule_onLoad(RedisModuleCtx *ctx, RedisModuleString **argv, int argc)
{
    RedisModuleTypeMethods tm = {.version = REDISMODULE_TYPE_METHOD_VERSION,
                                 .rdb_load = RdbLoad,
                                 .rdb_save = RdbSave,
                                 .aof_rewrite = RMUtil_DefaultAofRewrite,
                                 .mem_usage = MemUsage,
                                 .free = Free};

    SKETCHType = RedisModule_CreateDataType(ctx, "Hard-TYPE", HARD_ENC_VER, &tm);
    if (SKETCHType == NULL)
        return REDISMODULE_ERR;

    RMUtil_RegisterWriteDenyOOMCmd(ctx, "HardCoco.create", Create_Cmd);
    RMUtil_RegisterWriteDenyOOMCmd(ctx, "HardCoco.insert", Insert_Cmd);
    RMUtil_RegisterReadCmd(ctx, "HardCoco.query", Query_Cmd);
    RMUtil_RegisterReadCmd(ctx, "HardCoco.info", Info_Cmd);

    return REDISMODULE_OK;
}
