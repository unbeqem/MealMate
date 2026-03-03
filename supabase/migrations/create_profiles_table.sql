create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  household_size integer,
  dietary_preferences text[],
  onboarding_completed boolean default false,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can manage their own profile"
  on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create index profiles_id_idx on public.profiles(id);

-- Auto-create empty profile row on signup (prevents race condition)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
