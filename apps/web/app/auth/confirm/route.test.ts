import { beforeEach, describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';

const exchangeCodeForSession = vi.fn();
const verifyOtp = vi.fn();

vi.mock('../../../lib/supabase/server', () => ({
  createClient: vi.fn(async () => ({
    auth: { exchangeCodeForSession, verifyOtp },
  })),
}));

import { GET } from './route';

describe('auth confirmation callback', () => {
  beforeEach(() => {
    exchangeCodeForSession.mockReset();
    verifyOtp.mockReset();
  });

  it('exchanges a PKCE code and returns to the requested page', async () => {
    exchangeCodeForSession.mockResolvedValue({ error: null });
    const request = new NextRequest(
      'https://loopcard.dev/auth/confirm?code=oauth-code&next=%2Fdecks',
    );

    const response = await GET(request);

    expect(exchangeCodeForSession).toHaveBeenCalledWith('oauth-code');
    expect(response.headers.get('location')).toBe('https://loopcard.dev/decks');
  });
});
