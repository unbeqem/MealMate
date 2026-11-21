import AsyncStorage from '@react-native-async-storage/async-storage';
import { DEFAULT_PREFERENCES, INGREDIENTS, RECIPES, type PlanEntry, type ShoppingList } from '@mealmate/core';
import { RepoError, type Repo, type StoredPreferences } from './repo';

const K = {
  prefs: 'mm.guest.prefs',
  plan: (w: string) => `mm.guest.plan.${w}`,
  list: (w: string) => `mm.guest.list.${w}`,
};

async function read<T>(key: string, fallback: T): Promise<T> {
  try {
    const raw = await AsyncStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

/** Guest mode: everything stays on this device; catalog comes from the bundled seed. */
export const localRepo: Repo = {
  mode: 'guest',
  async getCatalog() {
    return { ingredients: INGREDIENTS, recipes: RECIPES };
  },
  async getPreferences() {
    return read<StoredPreferences>(K.prefs, { ...DEFAULT_PREFERENCES, onboarded: false });
  },
  async savePreferences(prefs) {
    await AsyncStorage.setItem(K.prefs, JSON.stringify(prefs));
  },
  async getPlan(week) {
    return read<PlanEntry[]>(K.plan(week), []);
  },
  async savePlan(week, entries) {
    await AsyncStorage.setItem(K.plan(week), JSON.stringify(entries));
  },
  async getShoppingList(week) {
    return read<ShoppingList | null>(K.list(week), null);
  },
  async saveShoppingList(week, list) {
    await AsyncStorage.setItem(K.list(week), JSON.stringify(list));
  },
  async generateRecipe() {
    throw new RepoError('Die KI-Rezepte brauchen ein Konto, weil sie auf dem Server laufen. Melde dich an, um sie zu nutzen.');
  },
};

export async function clearGuestData(): Promise<void> {
  const keys = await AsyncStorage.getAllKeys();
  await AsyncStorage.multiRemove(keys.filter((k) => k.startsWith('mm.guest.')));
}
