import { defineConfig } from 'astro/config';
export default defineConfig({
  output: 'static',
  publicDir: process.env.NIGHTFALL_WEB_PUBLIC || '../dist/web-public',
  outDir: process.env.NIGHTFALL_WEB_OUTPUT || './dist',
  cacheDir: '../dist/astro-cache',
  site: 'https://survivors.dearlordylord.com',
});
