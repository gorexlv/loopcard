import { beforeEach, describe, expect, it, vi } from 'vitest';

const redirect = vi.fn((destination: string): never => {
  throw new Error(`NEXT_REDIRECT:${destination}`);
});
const signInWithOAuth = vi.fn();
const signUp = vi.fn();

vi.mock('next/navigation', () => ({ redirect }));
vi.mock('next/headers', () => ({
  headers: vi.fn(async () => new Headers({ origin: 'https://loopcard.dev' })),
}));
vi.mock('../../lib/supabase/server', () => ({
  createClient: vi.fn(async () => ({
    auth: { signInWithOAuth, signUp },
  })),
}));

describe('login actions', () => {
  beforeEach(() => {
    redirect.mockClear();
    signInWithOAuth.mockReset();
    signUp.mockReset();
  });

  it('starts Google OAuth with a safe PKCE callback', async () => {
    const actions = await import('./actions');
    signInWithOAuth.mockResolvedValue({
      data: { url: 'https://accounts.google.com/o/oauth2/auth' },
      error: null,
    });
    const formData = new FormData();
    formData.set('next', '/decks');

    await expect(
      Reflect.get(actions, 'signInWithGoogle')(formData),
    ).rejects.toThrow('NEXT_REDIRECT:https://accounts.google.com/o/oauth2/auth');
    expect(signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: {
        redirectTo: 'https://loopcard.dev/auth/confirm?next=%2Fdecks',
      },
    });
  });

  it('sends email confirmation back through the auth callback', async () => {
    signUp.mockResolvedValue({
      data: { session: { access_token: 'test' } },
      error: null,
    });
    const { signUp: signUpAction } = await import('./actions');
    const formData = new FormData();
    formData.set('email', 'Person@Example.com');
    formData.set('password', 'password123');
    formData.set('next', '/decks');

    await expect(signUpAction(formData)).rejects.toThrow(
      'NEXT_REDIRECT:/decks',
    );
    expect(signUp).toHaveBeenCalledWith({
      email: 'person@example.com',
      password: 'password123',
      options: {
        emailRedirectTo: 'https://loopcard.dev/auth/confirm?next=%2Fdecks',
      },
    });
  });
});
