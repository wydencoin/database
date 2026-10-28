-- Só para o CI: imita o schema auth do Supabase num Postgres puro.
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select null::uuid $$;
