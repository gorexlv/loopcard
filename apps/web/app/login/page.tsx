import type { Metadata } from 'next';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { Logo } from '../../components/site-header';
import { safeNext } from '../../lib/safe-next';
import { createClient } from '../../lib/supabase/server';
import { signIn, signUp } from './actions';

export const metadata: Metadata = { title: 'Sign in', robots: { index: false, follow: false } };

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ mode?: string; error?: string; message?: string; next?: string }> }) {
  const query = await searchParams;
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const next = safeNext(query.next);
  if (user) redirect(next);
  const signup = query.mode === 'signup';
  return <main className="auth-page"><section className="auth-panel"><Logo /><span className="eyebrow">Your memory, synced</span><h1>{signup ? 'Create an account' : 'Welcome back'}</h1><p>Keep private decks, save public collections, and study from any device.</p>{query.error && <div className="form-message form-error" role="alert">{query.error}</div>}{query.message && <div className="form-message">{query.message}</div>}<form action={signup ? signUp : signIn} className="account-form"><input type="hidden" name="next" value={next} /><label>Email<input name="email" type="email" autoComplete="email" required maxLength={254} /></label><label>Password<input name="password" type="password" autoComplete={signup ? 'new-password' : 'current-password'} required minLength={8} maxLength={128} /></label><button className="button button-teal" type="submit">{signup ? 'Create account' : 'Sign in'}</button></form><Link className="auth-switch" href={`/login?mode=${signup ? 'signin' : 'signup'}&next=${encodeURIComponent(next)}`}>{signup ? 'Already have an account? Sign in' : 'New to LoopCard? Create an account'}</Link><Link className="text-link" href="/">Back to LoopCard</Link></section></main>;
}
