-- Ario Scripts schema. Run once in the Supabase SQL editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 username text unique not null check (char_length(username) between 3 and 24),
 display_name text,
 bio text not null default '',
 avatar_url text,
 role text not null default 'user' check (role in ('user','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.categories (
 id uuid primary key default gen_random_uuid(), name text unique not null,
 slug text unique not null, description text not null default '', created_at timestamptz not null default now()
);
create table if not exists public.scripts (
 id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade,
 category_id uuid references public.categories(id) on delete set null,
 title text not null check (char_length(title) between 3 and 120),
 slug text unique not null, description text not null default '', content text not null default '',
 tags text[] not null default '{}', cover_url text, status text not null default 'draft' check (status in ('draft','published','unpublished')),
 featured boolean not null default false, views bigint not null default 0 check (views >= 0), likes_count bigint not null default 0 check (likes_count >= 0),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.script_likes (
 user_id uuid not null references public.profiles(id) on delete cascade,
 script_id uuid not null references public.scripts(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,script_id)
);
create table if not exists public.script_saves (
 user_id uuid not null references public.profiles(id) on delete cascade,
 script_id uuid not null references public.scripts(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,script_id)
);
create table if not exists public.reports (
 id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.profiles(id) on delete cascade,
 script_id uuid not null references public.scripts(id) on delete cascade,
 reason text not null check (char_length(reason) between 5 and 1000), status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
 created_at timestamptz not null default now(), unique(reporter_id,script_id)
);
create index if not exists scripts_public_created_idx on public.scripts(status, created_at desc);
create index if not exists scripts_category_idx on public.scripts(category_id);
create index if not exists scripts_author_idx on public.scripts(author_id, created_at desc);
create index if not exists scripts_tags_idx on public.scripts using gin(tags);
create index if not exists reports_status_idx on public.reports(status, created_at desc);
create index if not exists likes_script_idx on public.script_likes(script_id);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id, username, display_name)
 values(new.id, coalesce(nullif(regexp_replace(lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1))), '[^a-z0-9_]', '', 'g'),''), 'user_' || substr(new.id::text,1,8)), coalesce(new.raw_user_meta_data->>'display_name',''))
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path = '' as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists scripts_updated_at on public.scripts;
create trigger scripts_updated_at before update on public.scripts for each row execute procedure public.set_updated_at();
create or replace function public.refresh_script_likes_count() returns trigger language plpgsql set search_path = '' as $$
begin update public.scripts set likes_count=(select count(*) from public.script_likes where script_id=coalesce(new.script_id,old.script_id)) where id=coalesce(new.script_id,old.script_id); return coalesce(new,old); end; $$;
drop trigger if exists script_likes_count on public.script_likes;
create trigger script_likes_count after insert or delete on public.script_likes for each row execute procedure public.refresh_script_likes_count();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.scripts enable row level security;
alter table public.script_likes enable row level security;
alter table public.script_saves enable row level security;
alter table public.reports enable row level security;
create policy "profiles readable" on public.profiles for select to anon, authenticated using (true);
create policy "users update own profile" on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()) and role=(select role from public.profiles where id=(select auth.uid())));
create policy "categories public read" on public.categories for select to anon, authenticated using (true);
create policy "admins manage categories" on public.categories for all to authenticated using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')) with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "published scripts or owner/admin read" on public.scripts for select to anon, authenticated using (status='published' or author_id=(select auth.uid()) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "authors create scripts" on public.scripts for insert to authenticated with check (author_id=(select auth.uid()));
create policy "authors or admins update scripts" on public.scripts for update to authenticated using (author_id=(select auth.uid()) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')) with check (author_id=(select auth.uid()) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "authors or admins delete scripts" on public.scripts for delete to authenticated using (author_id=(select auth.uid()) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "likes visible to signed in" on public.script_likes for select to authenticated using (true);
create policy "like as self" on public.script_likes for insert to authenticated with check (user_id=(select auth.uid()));
create policy "unlike as self" on public.script_likes for delete to authenticated using (user_id=(select auth.uid()));
create policy "saves visible to owner" on public.script_saves for select to authenticated using (user_id=(select auth.uid()));
create policy "save as self" on public.script_saves for insert to authenticated with check (user_id=(select auth.uid()));
create policy "unsave as self" on public.script_saves for delete to authenticated using (user_id=(select auth.uid()));
create policy "reporter reads own reports or admin" on public.reports for select to authenticated using (reporter_id=(select auth.uid()) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "authenticated users submit reports" on public.reports for insert to authenticated with check (reporter_id=(select auth.uid()));
create policy "admins update reports" on public.reports for update to authenticated using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')) with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));

insert into public.categories(name,slug,description) values
 ('Utilities','utilities','Small tools that make everyday workflows faster.'),('Development','development','Developer tooling, snippets, and experiments.'),('Automation','automation','Scripts that automate repetitive tasks.'),('Games','games','Game-related scripts and community projects.'),('Design','design','Creative workflows and design helpers.'),('Other','other','Everything that does not fit elsewhere.')
on conflict(slug) do nothing;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values ('script-covers','script-covers',true,5242880,array['image/png','image/jpeg','image/webp','image/avif']) on conflict(id) do nothing;
create policy "cover images publicly readable" on storage.objects for select to anon, authenticated using (bucket_id='script-covers');
create policy "users upload own cover images" on storage.objects for insert to authenticated with check (bucket_id='script-covers' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "users update own cover images" on storage.objects for update to authenticated using (bucket_id='script-covers' and (storage.foldername(name))[1]=(select auth.uid())::text) with check (bucket_id='script-covers' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "users delete own cover images" on storage.objects for delete to authenticated using (bucket_id='script-covers' and (storage.foldername(name))[1]=(select auth.uid())::text);

-- After creating your own account, grant admin from SQL Editor (replace with your email):
-- update public.profiles set role='admin' where id=(select id from auth.users where email='you@example.com');
-- IMPORTANT: do not expose a Supabase service-role/secret key to the browser.