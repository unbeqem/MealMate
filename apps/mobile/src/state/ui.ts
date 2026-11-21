import { create } from 'zustand';
import { toISODate, weekStart, addDays } from '@mealmate/core';

interface UiState {
  week: string;
  day: string;
  setWeek(week: string): void;
  shiftWeek(delta: number): void;
  setDay(day: string): void;
}

const today = toISODate(new Date());

export const useUi = create<UiState>((set) => ({
  week: weekStart(today),
  day: today,
  setWeek: (week) => set({ week, day: week }),
  shiftWeek: (delta) =>
    set((s) => {
      const week = addDays(s.week, delta * 7);
      const thisWeek = weekStart(today);
      return { week, day: week === thisWeek ? today : week };
    }),
  setDay: (day) => set({ day }),
}));

export const TODAY = today;
