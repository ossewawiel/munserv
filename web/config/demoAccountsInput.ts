// Mirrors demo_account_group in domain/language.yaml; a test keeps the two equal.
export const DEMO_ACCOUNT_GROUPS = [
  'pod_chief',
  'pod_admin',
  'ward_chief',
  'ward_admin',
  'sector_chief',
  'sector_admin',
  'member',
  'ground_admin',
] as const;

export type DemoAccountsInputCheck =
  | { readonly ok: true }
  | { readonly ok: false; readonly reason: string };

const STRING_FIELDS = ['group', 'name', 'email', 'password'] as const;

const invalid = (reason: string): DemoAccountsInputCheck => ({ ok: false, reason });

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function parseJson(raw: string): { readonly parsed: unknown } | undefined {
  try {
    return { parsed: JSON.parse(raw) as unknown };
  } catch {
    return undefined;
  }
}

function checkEntry(entry: unknown, index: number): DemoAccountsInputCheck {
  if (!isRecord(entry)) return invalid(`entry ${index} is not an object`);
  for (const field of STRING_FIELDS) {
    if (typeof entry[field] !== 'string') {
      return invalid(`entry ${index}: ${field} is not a string`);
    }
  }
  const isGroup = DEMO_ACCOUNT_GROUPS.some((group) => group === entry.group);
  return isGroup
    ? { ok: true }
    : invalid(`entry ${index}: group is not a demo_account_group value`);
}

export function checkDemoAccountsInput(raw: string | undefined): DemoAccountsInputCheck {
  if (raw === undefined || raw.trim() === '') return { ok: true };
  const result = parseJson(raw);
  if (result === undefined) return invalid('not valid JSON');
  if (!Array.isArray(result.parsed)) return invalid('not a JSON array');
  const entries: readonly unknown[] = result.parsed;
  for (const [index, entry] of entries.entries()) {
    const check = checkEntry(entry, index);
    if (!check.ok) return check;
  }
  return { ok: true };
}
