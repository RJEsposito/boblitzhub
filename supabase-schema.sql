-- Run this entire script in Supabase > SQL Editor > New query.
create extension if not exists pgcrypto;

create table if not exists public.anime (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 title text not null, status text not null default 'Planning' check(status in ('Planning','Watching','Completed','Paused','Dropped')),
 progress integer not null default 0 check(progress>=0), total_episodes integer check(total_episodes is null or total_episodes>=0),
 rating numeric(3,1) check(rating is null or (rating>=0 and rating<=10)), review text, cover_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.collections (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 name text not null, created_at timestamptz not null default now()
);
create table if not exists public.characters (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 name text not null, anime text, image_url text, created_at timestamptz not null default now()
);
create table if not exists public.events (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 title text not null, event_date date not null, created_at timestamptz not null default now()
);
create table if not exists public.local_files (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 title text not null, file_name text not null, location_note text, created_at timestamptz not null default now()
);

alter table public.anime enable row level security;
alter table public.collections enable row level security;
alter table public.characters enable row level security;
alter table public.events enable row level security;
alter table public.local_files enable row level security;

do $$ declare t text; begin
 foreach t in array array['anime','collections','characters','events','local_files'] loop
  execute format('drop policy if exists "Users manage own %s" on public.%I',t,t);
  execute format('create policy "Users manage own %s" on public.%I for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)',t,t);
 end loop;
end $$;

-- Authorized video embed URL for each anime entry.
alter table public.anime add column if not exists embed_url text;
