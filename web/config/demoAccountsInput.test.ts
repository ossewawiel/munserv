// @vitest-environment node
import { readFileSync } from 'node:fs';
import { describe, it, expect } from 'vitest';
import { DEMO_ACCOUNT_GROUPS, checkDemoAccountsInput } from './demoAccountsInput';

const entry = (group: string): Record<string, string> => ({
  group,
  name: 'Name',
  email: 'a@example.test',
  password: 'pw',
});

describe('checkDemoAccountsInput', () => {
  it('should accept an unset value', () => {
    expect(checkDemoAccountsInput(undefined)).toEqual({ ok: true });
  });

  it('should accept a blank value', () => {
    expect(checkDemoAccountsInput('  ')).toEqual({ ok: true });
  });

  it('should accept an empty array', () => {
    expect(checkDemoAccountsInput('[]')).toEqual({ ok: true });
  });

  it('should accept one valid entry of every group', () => {
    const raw = JSON.stringify(DEMO_ACCOUNT_GROUPS.map(entry));
    expect(checkDemoAccountsInput(raw)).toEqual({ ok: true });
  });

  it('should reject a value that is not JSON', () => {
    expect(checkDemoAccountsInput('{nope')).toEqual({ ok: false, reason: 'not valid JSON' });
  });

  it('should reject a JSON object', () => {
    expect(checkDemoAccountsInput('{"group":"pod_chief"}')).toEqual({
      ok: false,
      reason: 'not a JSON array',
    });
  });

  it('should reject an entry without a password', () => {
    const withoutPassword = { group: 'pod_chief', name: 'Name', email: 'a@example.test' };
    expect(checkDemoAccountsInput(JSON.stringify([withoutPassword]))).toEqual({
      ok: false,
      reason: 'entry 0: password is not a string',
    });
  });

  it('should reject a group outside demo_account_group', () => {
    expect(checkDemoAccountsInput(JSON.stringify([entry('super_user')]))).toEqual({
      ok: false,
      reason: 'entry 0: group is not a demo_account_group value',
    });
  });

  it('should never put the value in the reason', () => {
    const raw = JSON.stringify([
      { group: 'super_user', name: '', email: 'x@example.test', password: 'pw-secret' },
    ]);
    const check = checkDemoAccountsInput(raw);
    expect(check.ok).toBe(false);
    const reason = check.ok ? '' : check.reason;
    expect(reason).not.toContain('pw-secret');
    expect(reason).not.toContain('x@example.test');
  });

  it('should list the same groups as domain/language.yaml', () => {
    const yaml = readFileSync(new URL('../../domain/language.yaml', import.meta.url), 'utf8');
    const match = /demo_account_group: \[([^\]]*)\]/.exec(yaml);
    expect(match).not.toBeNull();
    const fromYaml = (match?.[1] ?? '').split(',').map((value) => value.trim());
    expect(new Set(DEMO_ACCOUNT_GROUPS)).toEqual(new Set(fromYaml));
  });
});
