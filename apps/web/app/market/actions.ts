'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireUser } from '../../lib/auth';

export async function addMarketDeck(formData: FormData) {
  const slug = String(formData.get('slug') ?? '');
  const { supabase } = await requireUser();
  const { data, error } = await supabase.rpc('add_market_deck', { deck_slug: slug });
  if (error) redirect(`/market/${encodeURIComponent(slug)}?error=Could%20not%20add%20this%20deck`);
  revalidatePath('/app');
  const status = Array.isArray(data) && data[0]?.status === 'already_added' ? 'already' : 'added';
  redirect(`/market/${encodeURIComponent(slug)}?status=${status}`);
}
