import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

import { dataDir, projectRoot, readJson, writeJson } from './store/json.js';

const configPath = join(dataDir, 'config.json');
const envLine = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/;

export function loadEnvFile(path = join(projectRoot, '.env')) {
  if (!existsSync(path)) return;

  for (const line of readFileSync(path, 'utf8').split('\n')) {
    if (line.trimStart().startsWith('#')) continue;

    const match = line.match(envLine);
    if (!match) continue;

    const [, name, rawValue] = match;
    if (process.env[name] !== undefined) continue;

    process.env[name] = rawValue.trim().replace(/^(["'])(.*)\1$/, '$2');
  }
}

export function readConfig() {
  return readJson(configPath, { databases: {} });
}

export function writeConfig(config) {
  writeJson(configPath, config);
}

export function settings() {
  return {
    token: process.env.NOTION_TOKEN ?? '',
    parentPageId: process.env.NOTION_PARENT_PAGE_ID ?? '',
    port: Number(process.env.PORT ?? 3000),
  };
}
