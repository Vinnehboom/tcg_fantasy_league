import { join } from 'node:path';

import { dataDir, readJson, writeJson } from './json.js';

const cachePath = join(dataDir, 'cache.json');
const emptyCache = { syncedAt: null, recipes: [], pantry: [], weeks: [] };

export function readCache() {
  return { ...emptyCache, ...readJson(cachePath, emptyCache) };
}

export function writeCache(changes) {
  const next = { ...readCache(), ...changes, syncedAt: new Date().toISOString() };

  writeJson(cachePath, next);

  return next;
}

export function cacheAgeMinutes(cache) {
  if (!cache.syncedAt) return null;

  return Math.round((Date.now() - Date.parse(cache.syncedAt)) / 60000);
}
