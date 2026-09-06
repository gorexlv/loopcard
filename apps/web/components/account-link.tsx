'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { createClient } from '../lib/supabase/client';

export function AccountLink({ compact = false }: { compact?: boolean }) {
  const [account, setAccount] = useState<{ signedIn: boolean; initial: string }>({ signedIn: false, initial: 'P' });
  useEffect(() => {
    const supabase = createClient();
    const update = (user?: { email?: string | null; user_metadata?: Record<string, unknown> } | null) => {
      const name = typeof user?.user_metadata?.display_name === 'string' ? user.user_metadata.display_name : user?.email;
      setAccount({ signedIn: Boolean(user), initial: name?.trim().charAt(0).toUpperCase() || 'P' });
    };
    supabase.auth.getUser().then(({ data }) => update(data.user));
    const { data } = supabase.auth.onAuthStateChange((_event, session) => update(session?.user));
    return () => data.subscription.unsubscribe();
  }, []);
  const href = account.signedIn ? '/app/profile' : '/login?next=%2Fapp%2Fprofile';
  if (compact) return <Link className="mobile-profile-link" href={href}>Profile <span aria-hidden="true">{account.initial}</span></Link>;
  return <Link className="account-link header-profile" href={href} aria-label="Profile"><span className="profile-label">Profile</span><span className="profile-avatar" aria-hidden="true">{account.initial}</span></Link>;
}
