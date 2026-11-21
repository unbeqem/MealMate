import type { BaseUnit, Ingredient } from './types.ts';

/** Generic kitchen units expressed in ml (volume) or g (mass). */
const VOLUME_ML: Record<string, number> = { ml: 1, l: 1000, EL: 15, TL: 5, Tasse: 240, cl: 10 };
const MASS_G: Record<string, number> = { g: 1, kg: 1000, Prise: 0.5, Msp: 0.3 };
const PIECE_UNITS = new Set(['Stk', 'Stück', 'pcs']);

export class UnitError extends Error {}

/**
 * Converts a display quantity ("2 EL", "1 Bund") into the ingredient's base unit.
 * Ingredient-specific unitWeights win over generic conversions.
 */
export function toBase(ing: Ingredient, amount: number, unit: string): number {
  const specific = ing.unitWeights?.[unit];
  if (specific !== undefined) return amount * specific;

  const density = ing.densityGPerMl ?? 1;
  if (unit in VOLUME_ML) {
    const ml = amount * VOLUME_ML[unit]!;
    if (ing.baseUnit === 'ml') return ml;
    if (ing.baseUnit === 'g') return ml * density;
    if (ing.gramsPerPiece) return (ml * density) / ing.gramsPerPiece;
  }
  if (unit in MASS_G) {
    const g = amount * MASS_G[unit]!;
    if (ing.baseUnit === 'g') return g;
    if (ing.baseUnit === 'ml') return g / density;
    if (ing.gramsPerPiece) return g / ing.gramsPerPiece;
  }
  if (PIECE_UNITS.has(unit)) {
    if (ing.baseUnit === 'pcs') return amount;
    if (ing.gramsPerPiece) {
      const g = amount * ing.gramsPerPiece;
      return ing.baseUnit === 'g' ? g : g / density;
    }
  }
  throw new UnitError(`Keine Umrechnung von "${unit}" für ${ing.name} (${ing.baseUnit})`);
}

const nf0 = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 0 });
const nf1 = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 1 });
const nf2 = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 });

export function formatNumber(n: number): string {
  if (Math.abs(n) >= 100) return nf0.format(Math.round(n));
  if (Math.abs(n) >= 10) return nf1.format(n);
  return nf2.format(n);
}

/** Formats a base amount for humans: 1250 g → "1,25 kg", 3 pcs → "3 Stk". */
export function formatBase(amount: number, unit: BaseUnit): string {
  if (unit === 'pcs') return `${formatNumber(roundPieces(amount))} Stk`;
  if (amount >= 1000) return `${nf2.format(amount / 1000)} ${unit === 'g' ? 'kg' : 'l'}`;
  return `${nf0.format(Math.round(amount))} ${unit}`;
}

function roundPieces(n: number): number {
  return Math.round(n * 2) / 2;
}

/** Scales a display amount for a different number of servings with kitchen-friendly rounding. */
export function scaleDisplay(amount: number, unit: string, factor: number): number {
  const v = amount * factor;
  if (unit === 'g' || unit === 'ml') {
    if (v >= 100) return Math.round(v / 5) * 5;
    return Math.round(v);
  }
  if (unit === 'kg' || unit === 'l') return Math.round(v * 100) / 100;
  // EL, TL, Stk, Zehe, Bund, Dose …: halves are the finest a kitchen uses
  return Math.max(0.5, Math.round(v * 2) / 2);
}

export function baseUnitLabel(unit: BaseUnit): string {
  return unit === 'pcs' ? 'Stk' : unit;
}

const PLURAL: Record<string, string> = { Zehe: 'Zehen', Stange: 'Stangen', Topf: 'Töpfe', Kopf: 'Köpfe', Scheibe: 'Scheiben', Dose: 'Dosen', Prise: 'Prisen' };

/** "Zehe" → "Zehen" for amounts above one; units without a plural stay as they are. */
export function unitLabel(unit: string, amount: number): string {
  return amount > 1 ? (PLURAL[unit] ?? unit) : unit;
}

/** Like formatBase, but pieces get the ingredient's natural unit: "15 Zehen", "0,5 Bund", "1 Topf". */
export function formatAmount(ing: Pick<Ingredient, 'baseUnit' | 'unitWeights'>, amount: number): string {
  if (ing.baseUnit !== 'pcs') return formatBase(amount, ing.baseUnit);
  const unit = Object.entries(ing.unitWeights ?? {}).find(([, w]) => w === 1)?.[0];
  if (!unit) return formatBase(amount, 'pcs');
  const n = roundPieces(amount);
  return `${formatNumber(n)} ${n > 1 ? (PLURAL[unit] ?? unit) : unit}`;
}

/** Compact receipt quantity: "3 × 450 g", "2 × 10 Zehen", single pieces as "2 Stk". */
export function formatPicks(ing: Pick<Ingredient, 'baseUnit' | 'unitWeights'>, picks: { count: number; amount: number }[]): string {
  return picks.map((p) => (p.amount === 1 ? formatAmount(ing, p.count) : `${p.count} × ${formatAmount(ing, p.amount)}`)).join(' + ');
}
