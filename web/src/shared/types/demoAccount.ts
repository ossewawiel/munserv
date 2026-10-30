import { ADMIN_ROLES, type AdminRole } from './admin';

export interface DemoAccount {
  readonly group: AdminRole;
  readonly name: string;
  readonly email: string;
  readonly password: string;
}

/** Highest role first, the order the quick login menu lists groups. */
export const DEMO_ACCOUNT_GROUP_ORDER: readonly AdminRole[] = [...ADMIN_ROLES].reverse();

function isDemoAccount(value: unknown): value is DemoAccount {
  if (typeof value !== 'object' || value === null) return false;
  const { group, name, email, password } = value as Record<string, unknown>;
  return (
    typeof group === 'string' &&
    (ADMIN_ROLES as readonly string[]).includes(group) &&
    typeof name === 'string' &&
    typeof email === 'string' &&
    typeof password === 'string'
  );
}

export function parseDemoAccounts(raw: string | undefined): readonly DemoAccount[] {
  if (raw === undefined || raw.trim() === '') return [];
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }
  return Array.isArray(parsed) ? parsed.filter(isDemoAccount) : [];
}
