import { renderToStaticMarkup } from 'react-dom/server';
import { describe, expect, it, vi } from 'vitest';

vi.mock('../../lib/supabase/server', () => ({
  createClient: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user: null } })) },
  })),
}));

import LoginPage from './page';

describe('login page', () => {
  it('renders Google and email sign-in choices', async () => {
    const view = await LoginPage({
      searchParams: Promise.resolve({ next: '/decks' }),
    });
    const html = renderToStaticMarkup(view);

    expect(html).toContain('Continue with Google');
    expect(html).toContain('Email');
    expect(html).toContain('Password');
  });
});
