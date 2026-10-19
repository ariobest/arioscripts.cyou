# Ario Scripts

A dark-first script sharing platform built with Next.js, TypeScript, Tailwind CSS and Supabase.

## Quick start
1. Copy `.env.example` to `.env.local` and set your Supabase project URL and publishable/anon key.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. In Supabase Authentication > URL Configuration, set your local and production Site URLs and redirect URLs.
4. Install and run: `npm install && npm run dev`.
5. To grant admin access, use the SQL instructions at the bottom of `supabase/schema.sql` after creating your account. Never expose a service-role key in the browser.

## Included
Home/explore/search, categories, script reader, email/password auth, dashboard, create/edit scripts, likes/saves, cover uploads, reports, profiles and role-protected moderation dashboard. RLS policies are included in the schema.

## Deployment
Deploy on Vercel or any Next.js-compatible host. Add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (or publishable key) as environment variables. Run the schema once in the correct Supabase project.

This repository contains application source; authentication, database, and storage become live only after you configure your own Supabase project and run the schema. Verify auth provider settings and policies in your project before production launch.