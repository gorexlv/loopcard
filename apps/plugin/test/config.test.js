import assert from 'node:assert/strict';
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { clearSession, readSession, writeSession } from '../src/config.js';

test('session storage writes only required auth fields', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'loopcard-cli-'));
  const path = join(directory, 'session.json');
  await writeSession(path, {
    access_token: 'access',
    refresh_token: 'refresh',
    expires_at: 123,
    user: { id: 'user', email: 'user@example.com', secret: 'discard' },
  });
  assert.deepEqual(await readSession(path), {
    access_token: 'access',
    refresh_token: 'refresh',
    expires_at: 123,
    user: { id: 'user', email: 'user@example.com' },
  });
  await clearSession(path);
  assert.equal(await readSession(path), null);
});
