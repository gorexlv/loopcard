export type Locale = 'en' | 'zh';
export type Theme = 'light' | 'dark';

export function resolveLocale(value: string | null): Locale {
  return value === 'zh' ? 'zh' : 'en';
}

export function resolveTheme(value: string | null, prefersDark: boolean): Theme {
  if (value === 'light' || value === 'dark') return value;
  return prefersDark ? 'dark' : 'light';
}

