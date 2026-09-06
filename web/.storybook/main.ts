import path from 'path';
import type { StorybookConfig } from '@storybook/react-vite';

const srcDir = path.resolve(import.meta.dirname, '../src');

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.tsx'],
  staticDirs: ['../public'],
  addons: [],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
  viteFinal: async (viteConfig) => {
    viteConfig.resolve = {
      ...viteConfig.resolve,
      alias: {
        ...viteConfig.resolve?.alias,
        '@': srcDir,
      },
    };
    return viteConfig;
  },
};

export default config;
