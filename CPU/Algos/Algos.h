#pragma once

#include "CocoSketch.h"
#include "Ours_FullSet.h"
#include "Ours_Subset.h"
#include "CMHash.h"
#include "CountHash.h"
#include "USSHeap.h"
#include "USS.h"

template<class T>
Abstract<T> *newFullSketch(uint32_t MEMORY, std::string name) {
    if (name == "CocoSketch") return new CocoSketch<T>(MEMORY);
    if (name == "Ours")       return new Ours_FullSet<T>(MEMORY);
    if (name == "USSHeap")    return new USSHeap<T>(MEMORY);
    if (name == "USS")        return new USS<T>(MEMORY);
    if (name == "CMHash")     return new CMHash<T>(MEMORY, 256);
    if (name == "CountHash")  return new CountHash<T>(MEMORY, 256);
    abort();
}


template<class T>
Abstract<T> *newPartialSketch(uint32_t MEMORY, std::string name) {
    if (name == "CocoSketch") return new CocoSketch<T>(MEMORY);
    if (name == "Ours")       return new Ours_Subset<T>(MEMORY);
    if (name == "USSHeap")    return new USSHeap<T>(MEMORY);
    if (name == "USS")        return new USS<T>(MEMORY);
    abort();
}
