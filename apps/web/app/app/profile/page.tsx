import type { Metadata } from 'next';
import { requireUser } from '../../../lib/auth';
import { updateProfile } from '../actions';
export const metadata: Metadata = { title: 'Profile', robots: { index: false, follow: false } };
export default async function ProfilePage({ searchParams }: { searchParams: Promise<{ saved?: string; error?: string }> }) {
  const { supabase, user } = await requireUser(); const { data: profile } = await supabase.from('profiles').select('display_name,created_at').eq('id', user.id).maybeSingle(); const query = await searchParams;
  return <main className="workspace-page narrow"><header className="workspace-header"><div><h1>Profile</h1></div></header>{query.saved && <div className="form-message">Profile updated.</div>}{query.error && <div className="form-message form-error">{query.error}</div>}<form action={updateProfile} className="account-form profile-form"><label>Display name<input name="displayName" maxLength={80} defaultValue={profile?.display_name ?? ''} /></label><label>Email<input value={user.email ?? ''} disabled /></label><button className="button button-teal" type="submit">Save profile</button></form></main>;
}
