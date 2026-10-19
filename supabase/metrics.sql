-- Optional safe view-count RPC. Run after schema.sql.
create or replace function public.increment_script_view(script_id_input uuid) returns void language sql security definer set search_path = '' as $$
 update public.scripts set views=views+1 where id=script_id_input and status='published';
$$;
revoke all on function public.increment_script_view(uuid) from public;
grant execute on function public.increment_script_view(uuid) to anon, authenticated;
