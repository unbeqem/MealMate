import type { PackagePick, PackageSize } from './types.ts';

export interface PackageChoice {
  picks: PackagePick[];
  total: number;
}

/**
 * Smallest total ≥ need that can be bought from the given package sizes
 * (any count of each). Ties are broken by fewer packages.
 * Works on integer base units; need ≤ 0 buys nothing.
 */
export function choosePackages(need: number, sizes: PackageSize[]): PackageChoice | null {
  const valid = sizes.filter((s) => s.amount > 0);
  if (valid.length === 0) return null;
  if (need <= 0) return { picks: [], total: 0 };

  const target = Math.ceil(need - 1e-9);
  const amounts = valid.map((s) => Math.round(s.amount));
  const maxSize = Math.max(...amounts);
  const limit = target + maxSize;

  // dp[s] = fewest packages reaching exactly s; from[s] = index of last size used
  const dp = new Int32Array(limit + 1).fill(-1);
  const from = new Int16Array(limit + 1).fill(-1);
  dp[0] = 0;
  for (let s = 1; s <= limit; s++) {
    for (let i = 0; i < amounts.length; i++) {
      const a = amounts[i]!;
      if (a <= s && dp[s - a]! >= 0) {
        const cand = dp[s - a]! + 1;
        if (dp[s]! < 0 || cand < dp[s]!) {
          dp[s] = cand;
          from[s] = i;
        }
      }
    }
  }

  for (let s = target; s <= limit; s++) {
    if (dp[s]! >= 0) {
      const counts = new Map<number, number>();
      let cur = s;
      while (cur > 0) {
        const i = from[cur]!;
        counts.set(i, (counts.get(i) ?? 0) + 1);
        cur -= amounts[i]!;
      }
      const picks: PackagePick[] = [...counts.entries()]
        .sort((a, b) => amounts[b[0]]! - amounts[a[0]]!)
        .map(([i, count]) => ({ sizeId: valid[i]!.id, label: valid[i]!.label, amount: valid[i]!.amount, count }));
      return { picks, total: s };
    }
  }
  return null;
}

export function describePicks(picks: PackagePick[]): string {
  return picks.map((p) => `${p.count} × ${p.label}`).join(' + ');
}
