-- Row Level Security: every table is locked down; access is granted explicitly.

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.profiles enable row level security;
alter table public.ingredients enable row level security;
alter table public.ingredient_aliases enable row level security;
alter table public.package_sizes enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.favorites enable row level security;
alter table public.favorite_ingredients enable row level security;
alter table public.meal_plans enable row level security;
alter table public.meal_plan_entries enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.shopping_list_items enable row level security;
alter table public.pantry_items enable row level security;
alter table public.ai_generations enable row level security;
alter table public.waitlist enable row level security;

-- Stammdaten: lesbar für alle, schreibbar nur per service_role (Seed/Admin)
create policy "ingredients readable" on public.ingredients for select using (true);
create policy "aliases readable" on public.ingredient_aliases for select using (true);
create policy "packages readable" on public.package_sizes for select using (true);

-- Profile
create policy "own profile read" on public.profiles for select using (id = auth.uid());
create policy "own profile update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());

-- Haushalte
create policy "member reads household" on public.households for select using (public.is_household_member(id));
create policy "member updates household" on public.households for update using (public.is_household_member(id));
create policy "member reads members" on public.household_members for select using (public.is_household_member(household_id));

-- Rezepte: öffentliche + eigene sichtbar; eigene (nicht kuratierte) änderbar
create policy "recipes visible" on public.recipes for select
  using (is_public or created_by = auth.uid());
create policy "own recipes insert" on public.recipes for insert
  with check (created_by = auth.uid() and source <> 'curated');
create policy "own recipes update" on public.recipes for update
  using (created_by = auth.uid() and source <> 'curated') with check (created_by = auth.uid() and source <> 'curated');
create policy "own recipes delete" on public.recipes for delete
  using (created_by = auth.uid() and source <> 'curated');

create policy "recipe ingredients visible" on public.recipe_ingredients for select
  using (exists (select 1 from public.recipes r where r.id = recipe_id and (r.is_public or r.created_by = auth.uid())));
create policy "own recipe ingredients write" on public.recipe_ingredients for all
  using (exists (select 1 from public.recipes r where r.id = recipe_id and r.created_by = auth.uid() and r.source <> 'curated'))
  with check (exists (select 1 from public.recipes r where r.id = recipe_id and r.created_by = auth.uid() and r.source <> 'curated'));

-- Favoriten
create policy "own favorites" on public.favorites for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own favorite ingredients" on public.favorite_ingredients for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Planung & Einkauf: alles im eigenen Haushalt
create policy "household plans" on public.meal_plans for all
  using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
create policy "household plan entries" on public.meal_plan_entries for all
  using (exists (select 1 from public.meal_plans p where p.id = meal_plan_id and public.is_household_member(p.household_id)))
  with check (exists (select 1 from public.meal_plans p where p.id = meal_plan_id and public.is_household_member(p.household_id)));
create policy "household lists" on public.shopping_lists for all
  using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));
create policy "household list items" on public.shopping_list_items for all
  using (exists (select 1 from public.shopping_lists l where l.id = list_id and public.is_household_member(l.household_id)))
  with check (exists (select 1 from public.shopping_lists l where l.id = list_id and public.is_household_member(l.household_id)));
create policy "household pantry" on public.pantry_items for all
  using (public.is_household_member(household_id)) with check (public.is_household_member(household_id));

-- KI-Protokoll: eigene Einträge lesen (geschrieben wird von der Edge Function mit service_role)
create policy "own ai generations" on public.ai_generations for select using (user_id = auth.uid());

-- Warteliste: anonym nur eintragen, niemals lesen
create policy "anyone joins waitlist" on public.waitlist for insert to anon, authenticated with check (true);
