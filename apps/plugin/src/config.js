import { mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';

export const DEFAULT_URL = 'http://127.0.0.1:8000';
export const DEFAULT_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

export function config(overrides = {}) {
  return {
    url: overrides.url ?? process.env.LOOPCARD_SUPABASE_URL ?? DEFAULT_URL,
    anonKey:
      overrides.anonKey ??
      process.env.LOOPCARD_SUPABASE_ANON_KEY ??
      DEFAULT_ANON_KEY,
    sessionPath:
      overrides.sessionPath ??
      process.env.LOOPCARD_SESSION_PATH ??
      join(homedir(), '.config', 'loopcard', 'session.json'),
  };
}

export async function readSession(path) {
  try {
    return JSON.parse(await readFile(path, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw error;
  }
}

export async function writeSession(path, session) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(
    path,
    `${JSON.stringify(
      {
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        expires_at: session.expires_at,
        user: { id: session.user.id, email: session.user.email },
      },
      null,
      2,
    )}\n`,
    { mode: 0o600 },
  );
}

export async function clearSession(path) {
  await rm(path, { force: true });
}
