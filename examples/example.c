/* Quiet Hacker - C Preview */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_ENTRIES 128
#define HASH_SIZE 64
#define FNV_OFFSET 14695981039346656037UL
#define FNV_PRIME 1099511628211UL

typedef struct Entry {
    char *key;
    int value;
    struct Entry *next;
} Entry;

typedef struct {
    Entry *buckets[HASH_SIZE];
    size_t count;
} HashMap;

static unsigned long hash(const char *key) {
    unsigned long h = FNV_OFFSET;
    for (const char *p = key; *p; p++) {
        h ^= (unsigned long)*p;
        h *= FNV_PRIME;
    }
    return h % HASH_SIZE;
}

HashMap *hashmap_create(void) {
    HashMap *map = calloc(1, sizeof(HashMap));
    if (!map) {
        fprintf(stderr, "Failed to allocate hashmap\n");
        return NULL;
    }
    return map;
}

bool hashmap_set(HashMap *map, const char *key, int value) {
    if (map->count >= MAX_ENTRIES) return false;

    unsigned long idx = hash(key);
    Entry *entry = map->buckets[idx];

    while (entry) {
        if (strcmp(entry->key, key) == 0) {
            entry->value = value;
            return true;
        }
        entry = entry->next;
    }

    Entry *new_entry = malloc(sizeof(Entry));
    if (!new_entry) return false;

    new_entry->key = strdup(key);
    new_entry->value = value;
    new_entry->next = map->buckets[idx];
    map->buckets[idx] = new_entry;
    map->count++;
    return true;
}

int *hashmap_get(HashMap *map, const char *key) {
    unsigned long idx = hash(key);
    Entry *entry = map->buckets[idx];

    while (entry) {
        if (strcmp(entry->key, key) == 0) {
            return &entry->value;
        }
        entry = entry->next;
    }
    return NULL;
}

void hashmap_free(HashMap *map) {
    for (int i = 0; i < HASH_SIZE; i++) {
        Entry *entry = map->buckets[i];
        while (entry) {
            Entry *next = entry->next;
            free(entry->key);
            free(entry);
            entry = next;
        }
    }
    free(map);
}

int main(void) {
    HashMap *map = hashmap_create();
    if (!map) return 1;

    const char *keys[] = {"alpha", "beta", "gamma", "delta", "epsilon"};
    int n = sizeof(keys) / sizeof(keys[0]);

    for (int i = 0; i < n; i++) {
        hashmap_set(map, keys[i], (i + 1) * 100);
    }

    for (int i = 0; i < n; i++) {
        int *val = hashmap_get(map, keys[i]);
        if (val) {
            printf("%s = %d\n", keys[i], *val);
        }
    }

    printf("entries: %zu\n", map->count);
    hashmap_free(map);
    return 0;
}
