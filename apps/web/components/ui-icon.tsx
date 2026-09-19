import type { CSSProperties } from 'react';

const paths = {
  back: 'm14 5-7 7 7 7M7 12h14',
  check: 'm5 12 4 4L19 6',
  minus: 'M5 12h14',
  repeat: 'M20 7v5h-5M4 17v-5h5M6 7a7 7 0 0 1 12-1l2 6M4 12l2 6a7 7 0 0 0 12-1',
  undo: 'M8 4 3 9l5 5M3 9h10a7 7 0 0 1 7 7v3',
  flip: 'M8 3h10a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H8M4 7l-3 3 3 3M1 10h9a4 4 0 0 1 4 4v2',
  help: 'M9.1 9a3 3 0 1 1 5 2.2c-1.3.8-2.1 1.3-2.1 2.8M12 17h.01',
  plus: 'M12 5v14M5 12h14',
  up: 'm6 14 6-6 6 6',
  down: 'm6 10 6 6 6-6',
  trash: 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 10v7M14 10v7',
} as const;

export function Icon({ name, style }: { name: keyof typeof paths; style?: CSSProperties }) {
  return <svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" style={style}>{name === 'help' && <circle cx="12" cy="12" r="9" />}<path d={paths[name]} /></svg>;
}
