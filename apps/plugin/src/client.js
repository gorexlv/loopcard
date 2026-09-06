import { createClient } from '@supabase/supabase-js';
import { config, readSession, writeSession } from './config.js';

export function anonymousClient(overrides = {}) {
  const current = config(overrides);
  return createClient(current.url, current.anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function authenticatedClient(overrides = {}) {
  const current = config(overrides);
  const session = await readSession(current.sessionPath);
  if (!session) {
    throw new Error('Not authenticated. Run: loopcard login --email <email>');
  }
  const client = createClient(current.url, current.anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.setSession({
    access_token: session.access_token,
    refresh_token: session.refresh_token,
  });
  if (error || !data.session) {
    throw new Error(`Session expired: ${error?.message ?? 'login again'}`);
  }
  await writeSession(current.sessionPath, data.session);
  return { client, user: data.session.user, settings: current };
}
