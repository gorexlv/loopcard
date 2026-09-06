export function safeNext(value: FormDataEntryValue | string | null | undefined) {
  const path = typeof value === 'string' ? value : '/app';
  return path.startsWith('/') && !path.startsWith('//') ? path : '/app';
}
