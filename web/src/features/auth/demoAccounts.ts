import { parseDemoAccounts } from '@/shared/types/demoAccount';

export const DEMO_ACCOUNTS = parseDemoAccounts(import.meta.env.VITE_DEMO_ACCOUNTS);
