// Builds apps/landing/dist: copies static files and writes config.js from env.
// Reads EXPO_PUBLIC_SUPABASE_URL / EXPO_PUBLIC_SUPABASE_ANON_KEY (process env or apps/mobile/.env).
// The publishable key is designed to be public; RLS only allows INSERT on waitlist.
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dist = resolve(root, 'dist');
const env = { ...process.env };
const envFile = resolve(root, '../mobile/.env');
if (existsSync(envFile)) {
  for (const line of readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m && !env[m[1]]) env[m[1]] = m[2];
  }
}
const config = `window.MEALMATE_CONFIG = ${JSON.stringify({
  supabaseUrl: env.EXPO_PUBLIC_SUPABASE_URL ?? '',
  supabaseKey: env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? '',
})};\n`;

const devOnly = process.argv.includes('--config-only');
writeFileSync(resolve(root, 'config.js'), config);
if (!devOnly) {
  rmSync(dist, { recursive: true, force: true });
  mkdirSync(dist);
  for (const f of ['index.html', 'styles.css', 'main.js', 'favicon.svg', 'datenschutz.html', 'impressum.html', 'config.js']) cpSync(resolve(root, f), resolve(dist, f));
  console.log('landing → dist/');
} else console.log('config.js written');
