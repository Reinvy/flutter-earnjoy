-- Schema Database Supabase untuk EarnJoy
-- 
-- Petunjuk Penggunaan:
-- 1. Masuk ke Dashboard Supabase Anda (https://supabase.com).
-- 2. Buka menu "SQL Editor" dari sidebar kiri.
-- 3. Tempelkan seluruh kode SQL di bawah ini dan jalankan (Run).

-- ─────────────────────────────────────────────────────────────────────────────
-- EXTENSIONS & SETTINGS
-- ─────────────────────────────────────────────────────────────────────────────
-- Pastikan ekstensi UUID diaktifkan untuk generate id otomatis jika dibutuhkan.
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLES DEFINITION
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Tabel User Profil
create table if not exists public.earnjoy_users (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    name text not null,
    point_balance numeric not null default 0.0,
    streak integer not null default 0,
    xp numeric not null default 0.0,
    updated_at timestamptz not null default now(),
    
    constraint earnjoy_users_user_id_key unique (user_id)
);

-- 2. Tabel Aktivitas (Logging)
create table if not exists public.earnjoy_activities (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    title text not null,
    category_name text not null,
    duration_minutes integer not null,
    points numeric not null,
    created_at timestamptz not null,
    updated_at timestamptz not null
);

-- 3. Tabel Reward (Wishlist & Shop)
create table if not exists public.earnjoy_rewards (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    name text not null,
    point_cost numeric not null,
    status text not null, -- 'wishlist', 'redeemed'
    category text not null,
    icon_emoji text not null,
    recurrence_type text not null,
    times_redeemed integer not null default 0,
    is_archived boolean not null default false,
    updated_at timestamptz not null
);

-- 4. Tabel Quests
create table if not exists public.earnjoy_quests (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    title text not null,
    type text not null,
    is_completed boolean not null default false,
    progress numeric not null default 0.0,
    expires_at timestamptz not null,
    updated_at timestamptz not null
);

-- 5. Tabel Badges
create table if not exists public.earnjoy_badges (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    badge_key text not null,
    is_unlocked boolean not null default false,
    unlocked_at timestamptz,
    updated_at timestamptz not null
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INDICES FOR PERFORMANCE
-- ─────────────────────────────────────────────────────────────────────────────
-- Menambahkan indeks pada kolom `user_id` karena merupakan filter pencarian utama.
create index if not exists idx_earnjoy_users_user_id on public.earnjoy_users(user_id);
create index if not exists idx_earnjoy_activities_user_id on public.earnjoy_activities(user_id);
create index if not exists idx_earnjoy_rewards_user_id on public.earnjoy_rewards(user_id);
create index if not exists idx_earnjoy_quests_user_id on public.earnjoy_quests(user_id);
create index if not exists idx_earnjoy_badges_user_id on public.earnjoy_badges(user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS) & POLICIES
-- ─────────────────────────────────────────────────────────────────────────────
-- RLS memastikan setiap user hanya bisa membaca, mengubah, dan menghapus datanya sendiri.

-- Mengaktifkan RLS di semua tabel
alter table public.earnjoy_users enable row level security;
alter table public.earnjoy_activities enable row level security;
alter table public.earnjoy_rewards enable row level security;
alter table public.earnjoy_quests enable row level security;
alter table public.earnjoy_badges enable row level security;

-- Kebijakan RLS (Security Policies)

-- A. Tabel: earnjoy_users
create policy "Users can select their own user profile." on public.earnjoy_users
    for select using (auth.uid() = user_id);

create policy "Users can insert their own user profile." on public.earnjoy_users
    for insert with check (auth.uid() = user_id);

create policy "Users can update their own user profile." on public.earnjoy_users
    for update using (auth.uid() = user_id);

create policy "Users can delete their own user profile." on public.earnjoy_users
    for delete using (auth.uid() = user_id);

-- B. Tabel: earnjoy_activities
create policy "Users can select their own activities." on public.earnjoy_activities
    for select using (auth.uid() = user_id);

create policy "Users can insert their own activities." on public.earnjoy_activities
    for insert with check (auth.uid() = user_id);

create policy "Users can update their own activities." on public.earnjoy_activities
    for update using (auth.uid() = user_id);

create policy "Users can delete their own activities." on public.earnjoy_activities
    for delete using (auth.uid() = user_id);

-- C. Tabel: earnjoy_rewards
create policy "Users can select their own rewards." on public.earnjoy_rewards
    for select using (auth.uid() = user_id);

create policy "Users can insert their own rewards." on public.earnjoy_rewards
    for insert with check (auth.uid() = user_id);

create policy "Users can update their own rewards." on public.earnjoy_rewards
    for update using (auth.uid() = user_id);

create policy "Users can delete their own rewards." on public.earnjoy_rewards
    for delete using (auth.uid() = user_id);

-- D. Tabel: earnjoy_quests
create policy "Users can select their own quests." on public.earnjoy_quests
    for select using (auth.uid() = user_id);

create policy "Users can insert their own quests." on public.earnjoy_quests
    for insert with check (auth.uid() = user_id);

create policy "Users can update their own quests." on public.earnjoy_quests
    for update using (auth.uid() = user_id);

create policy "Users can delete their own quests." on public.earnjoy_quests
    for delete using (auth.uid() = user_id);

-- E. Tabel: earnjoy_badges
create policy "Users can select their own badges." on public.earnjoy_badges
    for select using (auth.uid() = user_id);

create policy "Users can insert their own badges." on public.earnjoy_badges
    for insert with check (auth.uid() = user_id);

create policy "Users can update their own badges." on public.earnjoy_badges
    for update using (auth.uid() = user_id);

create policy "Users can delete their own badges." on public.earnjoy_badges
    for delete using (auth.uid() = user_id);
