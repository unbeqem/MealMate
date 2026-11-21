// Copies packages/core/src into supabase/functions/_shared/core so Edge Functions
// deploy without importing from outside the functions folder (ADR-002: one logic, two places).
import { cpSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const src = resolve(root, 'packages/core/src');
const dest = resolve(root, 'supabase/functions/_shared/core');
rmSync(dest, { recursive: true, force: true });
cpSync(src, dest, { recursive: true, filter: (p) => !p.endsWith('.test.ts') });
console.log('core → supabase/functions/_shared/core');
