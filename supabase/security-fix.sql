-- Run after schema.sql. Replaces profile-table self-referencing policies with a safe admin predicate.
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and role='admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
drop policy if exists "users update own profile" on public.profiles;
drop policy if exists "admins manage categories" on public.categories;
drop policy if exists "published scripts or owner/admin read" on public.scripts;
drop policy if exists "authors or admins update scripts" on public.scripts;
drop policy if exists "authors or admins delete scripts" on public.scripts;
drop policy if exists "reporter reads own reports or admin" on public.reports;
drop policy if exists "admins update reports" on public.reports;
create policy "users update own profile" on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()) and role='user');
create policy "admins manage profiles" on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "published scripts or owner/admin read" on public.scripts for select to anon, authenticated using (status='published' or author_id=(select auth.uid()) or public.is_admin());
create policy "authors or admins update scripts" on public.scripts for update to authenticated using (author_id=(select auth.uid()) or public.is_admin()) with check (author_id=(select auth.uid()) or public.is_admin());
create policy "authors or admins delete scripts" on public.scripts for delete to authenticated using (author_id=(select auth.uid()) or public.is_admin());
create policy "reporter reads own reports or admin" on public.reports for select to authenticated using (reporter_id=(select auth.uid()) or public.is_admin());
create policy "admins update reports" on public.reports for update to authenticated using (public.is_admin()) with check (public.is_admin());
