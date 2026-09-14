-- Tour de Repas — base partagée (Supabase / PostgreSQL)
-- À coller dans Supabase : Project → SQL Editor → New query → Run

-- 1. Les équipiers de la garde
create table if not exists public.equipiers (
  id         uuid primary key default gen_random_uuid(),
  nom        text not null,
  actif      boolean not null default true,
  created_at timestamptz not null default now()
);

-- 2. Les repas réalisés
create table if not exists public.repas (
  id          uuid primary key default gen_random_uuid(),
  equipier_id uuid references public.equipiers(id) on delete set null,
  nom         text not null,                      -- nom figé : l'historique reste lisible
  date        date not null,
  service     text not null default 'midi' check (service in ('midi', 'soir')),
  created_at  timestamptz not null default now()
);

create index if not exists repas_date_idx on public.repas (date desc);
create index if not exists repas_equipier_idx on public.repas (equipier_id);

-- 3. Sécurité : RLS activée, accès ouvert à la clé publique (anon)
--    Tout le monde qui a le lien peut lire et écrire — adapté à une équipe de garde.
alter table public.equipiers enable row level security;
alter table public.repas     enable row level security;

drop policy if exists "equipiers ouvert" on public.equipiers;
create policy "equipiers ouvert" on public.equipiers
  for all to anon using (true) with check (true);

drop policy if exists "repas ouvert" on public.repas;
create policy "repas ouvert" on public.repas
  for all to anon using (true) with check (true);

-- 4. (Optionnel) Démarrage : décommenter et adapter les noms de l'équipe
-- insert into public.equipiers (nom) values
--   ('Mauriès'), ('Marchand'), ('Bertrand'), ('Fayolle');

-- 5. Un seul équipier par nom (empêche les doublons à la saisie)
create unique index if not exists equipiers_nom_uidx on public.equipiers (nom);

-- 6. Équipiers de la garde 1 (caserne de Vienne)
insert into public.equipiers (nom) values
  ('Pierre'), ('Régis'), ('Thomas'), ('Bertrand'),
  ('Pierre-François'), ('Richard'), ('Jérémy')
on conflict (nom) do nothing;

-- Nettoyage des doublons déjà créés (garde la ligne la plus ancienne) :
-- delete from public.equipiers e using public.equipiers k
--   where e.nom = k.nom and (e.created_at, e.id) > (k.created_at, k.id);
