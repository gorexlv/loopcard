import { redirect } from 'next/navigation';
import { createClient } from './supabase/server';
export { safeNext } from './safe-next';

export async function requireUser() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login?next=/app');
  return { supabase, user };
}
