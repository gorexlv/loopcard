'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const links = [
  { href: '/app', label: 'My decks', match: (path: string) => path === '/app' || path.startsWith('/app/decks') },
  { href: '/market', label: 'Discover', match: (path: string) => path.startsWith('/market') },
  { href: '/app/profile', label: 'Profile', match: (path: string) => path.startsWith('/app/profile') },
];

export function WorkspaceNavigation() {
  const pathname = usePathname();
  return <nav aria-label="Workspace navigation">{links.map((item) => <Link key={item.href} href={item.href} aria-current={item.match(pathname) ? 'page' : undefined}>{item.label}</Link>)}</nav>;
}
