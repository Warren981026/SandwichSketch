#include <iostream>
#include "hash.h"
#include "Abstract.h"

const uint8_t salsaH[] = {0x80,0xe0,0x20,0x00,0x08,0x0e,0x02};
const uint8_t salsaL[] = {0xa0,0xf0,0x30,0x00,0x0a,0x0f,0x03};

template<typename DATA_TYPE>
class SalsaCM : public Abstract<DATA_TYPE>{
public:

	typedef std::unordered_map<DATA_TYPE, COUNT_TYPE> HashMap;

	SalsaCM(uint32_t _MEMORY, std::string _name = "Salsa") {
		this->name = _name;

		d = 4;
		w = _MEMORY / d / 9 * 8;
		w = w - w % 8;
		counters = new uint8_t*[d];
		mask_16 = new uint16_t*[d];
		mask_32 = new uint32_t*[d];
		flags = new uint8_t*[d];
		for (uint32_t i = 0; i < d; i++)
		{
			counters[i] = new uint8_t[w];
			memset(counters[i], 0, sizeof(uint8_t) * w);
			flags[i] = new uint8_t[w / 8];
			memset(flags[i], 0, sizeof(uint8_t) * w / 8);
			mask_16[i] = (uint16_t*)counters[i];
			mask_32[i] = (uint32_t*)counters[i];
		}
	}

	~SalsaCM(){
		for (uint32_t i = 0; i < d; i++) {
			delete [] counters[i];
			delete [] flags[i];
		}
		delete [] counters;
		delete [] flags;
		delete [] mask_16;
		delete [] mask_32;
	}

	void Insert(const DATA_TYPE& key) {
		for (uint32_t i = 0; i < d; i++) {
			uint32_t pos = hash(key, i) % w;
			uint8_t c = flags[i][pos >> 3];
			if (!((c & salsaL[pos & 2]) ^ salsaH[pos & 2])) {
				if (counters[i][pos] ^ 0xff) {
					counters[i][pos]++;
				}
				else {
					//update 8->16
					uint32_t pos1 = pos + 1 - 2 * (pos % 2);
					mask_16[i][pos >> 1] = (uint16_t)counters[i][pos] + (uint16_t)counters[i][pos1] + 1;
					flags[i][pos >> 3] |= salsaH[pos & 2];
				}
				continue;
			}
			if (!((c & salsaL[pos & 4 + 1]) ^ salsaH[pos & 4 + 1])) {
				if (mask_16[i][pos >> 1] ^ 0xffff) {
					mask_16[i][pos >> 1]++;
				}
				else {
					//update16->32
					uint32_t pos0 = pos >> 1;
					uint32_t pos1 = pos0 + 1 - 2 * (pos0 % 2);
					if (!((c & salsaL[2 * (pos1 & 4)]) ^ salsaH[2 * (pos1 & 4)])) {
						mask_32[i][pos >> 2] = (uint32_t)mask_16[i][pos0] + (uint32_t)counters[i][pos1 * 2] + (uint32_t)counters[i][pos1 * 2 + 1] + 1;
					}
					else {
						mask_32[i][pos >> 2] = (uint32_t)mask_16[i][pos0] + (uint32_t)mask_16[i][pos1] + 1;
					}
					flags[i][pos >> 3] |= salsaH[pos & 4 + 1];
				}
				continue;
			}
			mask_32[i][pos >> 2]++;
		}
	}

	COUNT_TYPE Query(const DATA_TYPE& key) {
		COUNT_TYPE res = INT_MAX;
		for (uint32_t i = 0; i < d; i++) {
			uint32_t pos = hash(key, i) % w;
			uint8_t c = flags[i][pos >> 3];
			if (!((c & salsaL[pos & 2]) ^ salsaH[pos & 2])) {
				res = std::min(res, (COUNT_TYPE)counters[i][pos]);
				continue;
			}
			if (!((c & salsaL[pos & 4 + 1]) ^ salsaH[pos & 4 + 1])) {
				res = std::min(res, (COUNT_TYPE)mask_16[i][pos >> 1]);
				continue;
			}
			res = std::min(res, (COUNT_TYPE)mask_32[i][pos >> 2]);
		}
		return res;
	}

	HashMap AllQuery(DATA_TYPE *dataset = NULL, int length = 0){
        HashMap ret;

        for (int i = 0; i < length; i++)
            if (ret.count(dataset[i]) == 0)
                ret[dataset[i]] = Query(dataset[i]);
        
        return ret;
    }

private:
	uint8_t **counters;
	uint8_t **flags;
	uint16_t **mask_16;
	uint32_t **mask_32;
	uint32_t w, d;
};
