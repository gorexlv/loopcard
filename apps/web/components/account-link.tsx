'use client';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { createClient } from '../lib/supabase/client';

export function AccountLink({ compact = false, chinese = false }: { compact?: boolean; chinese?: boolean }) {
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
  const label = account.signedIn ? (chinese ? '我的卡包' : 'My decks') : (chinese ? '登录' : 'Sign in');
  const target = account.signedIn ? '/app' : '/login?next=%2Fapp';
  if (compact) return <Link className="mobile-profile-link" href={target}>{label}</Link>;
  return <Link className="account-link" href={target}>{label}{account.signedIn && <span className="account-initial" aria-hidden="true">{account.initial}</span>}</Link>;
}
