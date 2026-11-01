-- Table des demandes du Desk Algérie-Niger.
-- À exécuter une fois dans Supabase (menu SQL Editor, bouton Run).

create extension if not exists pgcrypto;

create table if not exists public.demandes (
  id               uuid primary key default gen_random_uuid(),
  cree_le          timestamptz not null default now(),
  maj_le           timestamptz,
  statut           text not null default 'nouveau'
                   check (statut in ('nouveau', 'en_cours', 'devis_envoye', 'gagne', 'perdu')),
  langue           text not null check (langue in ('ar', 'fr')),
  source           text,
  nom              text not null,
  entreprise       text,
  fonction         text,
  pays             text not null check (pays in ('DZ', 'NE', 'autre')),
  profil           text not null check (profil in ('algerie', 'niger', 'autre')),
  service          text,
  secteur          text,
  budget           text,
  email            text,
  telephone        text,
  message          text,
  langue_preferee  text not null check (langue_preferee in ('ar', 'fr')),
  consentement     boolean not null,
  notes            text,
  constraint contact_obligatoire check (email is not null or telephone is not null)
);

create index if not exists demandes_cree_le_idx on public.demandes (cree_le desc);
create index if not exists demandes_statut_idx on public.demandes (statut);

-- Sécurité : aucune lecture ni écriture publique. Seul le serveur du portail,
-- avec la clé de service, accède à la table.
alter table public.demandes enable row level security;
