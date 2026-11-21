-- MealMate M1 schema (+ prepared M2/M3 tables)
-- Auth: Supabase Auth → user ids are uuid (auth.users.id)
-- Curated ingredients/recipes use readable text ids (slugs); user/AI recipes get uuid text ids.

create extension if not exists pgcrypto;

-- ───────────────────────── Haushalt & Profil ─────────────────────────
create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Mein Haushalt',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'member')),
  primary key (household_id, user_id)
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  household_id uuid references public.households (id) on delete set null,
  household_size int not null default 2 check (household_size between 1 and 12),
  diet text not null default 'omnivore' check (diet in ('omnivore', 'flexitarian', 'pescetarian', 'vegetarian', 'vegan')),
  allergens text[] not null default '{}',
  dislikes text[] not null default '{}',
  max_cook_minutes int check (max_cook_minutes is null or max_cook_minutes > 0),
  include_breakfast boolean not null default false,
  cook_for_leftovers boolean not null default true,
  onboarded_at timestamptz,
  created_at timestamptz not null default now()
);

-- membership check used by RLS (security definer avoids recursive policies)
create or replace function public.is_household_member(hid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.household_members m where m.household_id = hid and m.user_id = auth.uid());
$$;

-- every new user gets a profile and their own household
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare hid uuid;
begin
  insert into public.households (name, created_by) values ('Mein Haushalt', new.id) returning id into hid;
  insert into public.household_members (household_id, user_id, role) values (hid, new.id, 'owner');
  insert into public.profiles (id, display_name, household_id)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)), hid);
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────── Zutaten (Herzstück) ─────────────────────────
create table public.ingredients (
  id text primary key,
  name_de text not null,
  base_unit text not null check (base_unit in ('g', 'ml', 'pcs')),
  grams_per_piece numeric,
  density_g_per_ml numeric,
  unit_weights jsonb not null default '{}',
  aisle text not null,
  shelf_life_days int,
  allergens text[] not null default '{}',
  diet_class text not null check (diet_class in ('vegan', 'vegetarian', 'pescetarian', 'meat')),
  is_staple boolean not null default false,
  off_barcode text
);

create table public.ingredient_aliases (
  ingredient_id text not null references public.ingredients (id) on delete cascade,
  alias text not null,
  primary key (ingredient_id, alias)
);
create index ingredient_aliases_alias_idx on public.ingredient_aliases (lower(alias));

create table public.package_sizes (
  id text primary key,
  ingredient_id text not null references public.ingredients (id) on delete cascade,
  amount numeric not null check (amount > 0),
  unit text not null check (unit in ('g', 'ml', 'pcs')),
  label text not null
);
create index package_sizes_ingredient_idx on public.package_sizes (ingredient_id);

-- ───────────────────────── Rezepte ─────────────────────────
create table public.recipes (
  id text primary key default gen_random_uuid()::text,
  title text not null,
  description text not null default '',
  servings int not null check (servings > 0),
  prep_minutes int not null check (prep_minutes > 0),
  category text not null check (category in ('breakfast', 'lunch', 'dinner', 'snack')),
  tags text[] not null default '{}',
  instructions jsonb not null default '[]',
  image_url text,
  source text not null default 'user' check (source in ('curated', 'ai', 'import', 'user')),
  created_by uuid references auth.users (id) on delete set null,
  is_public boolean not null default false,
  needs_review boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.recipe_ingredients (
  recipe_id text not null references public.recipes (id) on delete cascade,
  ingredient_id text not null references public.ingredients (id),
  position int not null default 0,
  amount_base numeric not null check (amount_base >= 0),
  display_amount numeric not null,
  display_unit text not null,
  optional boolean not null default false,
  primary key (recipe_id, ingredient_id)
);
create index recipe_ingredients_ingredient_idx on public.recipe_ingredients (ingredient_id);

create table public.favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  recipe_id text not null references public.recipes (id) on delete cascade,
  primary key (user_id, recipe_id)
);

create table public.favorite_ingredients (
  user_id uuid not null references auth.users (id) on delete cascade,
  ingredient_id text not null references public.ingredients (id) on delete cascade,
  primary key (user_id, ingredient_id)
);

-- ───────────────────────── Planung ─────────────────────────
create table public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  week_start date not null,
  updated_at timestamptz not null default now(),
  unique (household_id, week_start)
);

create table public.meal_plan_entries (
  id text primary key,
  meal_plan_id uuid not null references public.meal_plans (id) on delete cascade,
  date date not null,
  slot text not null check (slot in ('breakfast', 'lunch', 'dinner')),
  recipe_id text not null references public.recipes (id),
  servings int not null check (servings > 0),
  is_leftover_of text references public.meal_plan_entries (id) on delete cascade,
  unique (meal_plan_id, date, slot)
);

-- ───────────────────────── Einkauf ─────────────────────────
create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  meal_plan_id uuid not null unique references public.meal_plans (id) on delete cascade,
  generated_at timestamptz not null default now()
);

create table public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.shopping_lists (id) on delete cascade,
  key text not null,
  ingredient_id text references public.ingredients (id),
  custom_name text,
  label text not null,
  aisle text not null,
  unit text not null,
  required_base numeric not null default 0,
  packages jsonb not null default '[]',
  purchase_base numeric not null default 0,
  leftover_base numeric not null default 0,
  source text not null check (source in ('auto', 'manual')),
  manual_override numeric,
  checked boolean not null default false,
  checked_at timestamptz,
  assumed_stock boolean not null default false,
  orphaned boolean not null default false,
  used_by text[] not null default '{}',
  leftover_suggestion jsonb not null default '[]',
  unique (list_id, key),
  check (ingredient_id is not null or custom_name is not null)
);

-- ───────────────────────── M2: Vorrat (vorbereitet) ─────────────────────────
create table public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  ingredient_id text not null references public.ingredients (id),
  amount_base numeric not null check (amount_base >= 0),
  expires_at date,
  added_from text not null default 'manual' check (added_from in ('manual', 'shopping', 'barcode')),
  created_at timestamptz not null default now()
);

-- ───────────────────────── KI-Protokoll (Datengrundlage eigenes Modell) ─────────────────────────
create table public.ai_generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  provider text not null,
  model text not null,
  prompt text not null,
  constraints jsonb not null default '{}',
  raw_output jsonb,
  unmapped_ingredients text[] not null default '{}',
  recipe_id text references public.recipes (id) on delete set null,
  status text not null check (status in ('saved', 'rejected', 'error')),
  error text,
  created_at timestamptz not null default now()
);

-- ───────────────────────── Warteliste (Landingpage) ─────────────────────────
create table public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null unique check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and length(email) <= 254),
  source text not null default 'landing',
  created_at timestamptz not null default now()
);
