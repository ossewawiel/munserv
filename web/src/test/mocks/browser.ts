import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

/**
 * Browser MSW worker for Storybook. Node's setupServer (src/test/mocks/server.ts)
 * covers Vitest; this covers stories that trigger a real mutation (Storybook has
 * no backend to talk to). Started once in .storybook/preview.tsx; individual
 * stories call `worker.use(...)` to override a handler for one interaction.
 */
export const worker = setupWorker(...handlers);
