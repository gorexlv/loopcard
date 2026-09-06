'use server';
import { redirect } from 'next/navigation';
import { safeNext } from '../../lib/safe-next';
import { createClient } from '../../lib/supabase/server';

function credentials(formData: FormData) {
  return {
    email: String(formData.get('email') ?? '').trim().toLowerCase(),
    password: String(formData.get('password') ?? ''),
  };
}

export async function signIn(formData: FormData) {
  const next = safeNext(formData.get('next'));
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword(credentials(formData));
  if (error) redirect(`/login?error=${encodeURIComponent('Email or password is incorrect')}&next=${encodeURIComponent(next)}`);
  redirect(next);
}

export async function signUp(formData: FormData) {
  const next = safeNext(formData.get('next'));
  const { email, password } = credentials(formData);
  if (!email.includes('@') || password.length < 8) redirect(`/login?mode=signup&error=${encodeURIComponent('Use a valid email and at least 8 password characters')}&next=${encodeURIComponent(next)}`);
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({ email, password });
  if (error) redirect(`/login?mode=signup&error=${encodeURIComponent(error.message)}&next=${encodeURIComponent(next)}`);
  if (!data.session) redirect(`/login?message=${encodeURIComponent('Check your email to confirm the account')}`);
  redirect(next);
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}
