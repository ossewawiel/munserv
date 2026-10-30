import { describe, it, expect } from 'vitest';

import { parseDemoAccounts, DEMO_ACCOUNT_GROUP_ORDER } from './demoAccount';

const valid = { group: 'sector_admin', name: '', email: 'a@example.test', password: 'pw' };

describe('parseDemoAccounts', () => {
  it('should return no accounts when the value is undefined', () => {
    expect(parseDemoAccounts(undefined)).toEqual([]);
  });

  it('should return no accounts when the value is blank', () => {
    expect(parseDemoAccounts('  ')).toEqual([]);
  });

  it('should return no accounts when the value is not json', () => {
    expect(parseDemoAccounts('{nope')).toEqual([]);
  });

  it('should return no accounts when the value is not an array', () => {
    expect(parseDemoAccounts(JSON.stringify(valid))).toEqual([]);
  });

  it('should drop an entry whose group is not an admin role', () => {
    const raw = JSON.stringify([{ ...valid, group: 'member' }, valid]);
    expect(parseDemoAccounts(raw)).toEqual([valid]);
  });

  it('should keep valid entries in order', () => {
    const second = { ...valid, group: 'pod_chief', email: 'b@example.test' };
    expect(parseDemoAccounts(JSON.stringify([valid, second]))).toEqual([valid, second]);
  });

  it('should order groups highest first', () => {
    expect(DEMO_ACCOUNT_GROUP_ORDER[0]).toBe('pod_chief');
    expect(DEMO_ACCOUNT_GROUP_ORDER[5]).toBe('sector_admin');
  });
});
