import { Logo } from '../../components/site-header';
import { WorkspaceNavigation } from '../../components/workspace-navigation';
import { requireUser } from '../../lib/auth';
import { signOut } from '../login/actions';

export default async function AccountLayout({ children }: { children: React.ReactNode }) {
  if (process.env.NEXT_PUBLIC_DESIGN_PREVIEW === '1') return children;
  const { user } = await requireUser();
  return <div className="workspace-shell"><aside className="workspace-nav"><Logo /><WorkspaceNavigation /><div className="workspace-account"><small>{user.email}</small><form action={signOut}><button type="submit">Sign out</button></form></div></aside><div className="workspace-main">{children}</div></div>;
}
