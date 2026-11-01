// Accès à la table « demandes » de Supabase, côté serveur uniquement.
// La clé de service ne quitte jamais le serveur (variable SUPABASE_SERVICE_ROLE_KEY).

import "server-only";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Statut } from "./formulaire";

export type LigneDemande = {
  id: string;
  cree_le: string;
  statut: Statut;
  langue: string;
  source: string | null;
  nom: string;
  entreprise: string | null;
  fonction: string | null;
  pays: string;
  profil: string;
  service: string | null;
  secteur: string | null;
  budget: string | null;
  email: string | null;
  telephone: string | null;
  message: string | null;
  langue_preferee: string;
  consentement: boolean;
  notes: string | null;
  maj_le: string | null;
};

let client: SupabaseClient | null = null;

export function baseConfiguree(): boolean {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY);
}

export function base(): SupabaseClient {
  if (!baseConfiguree()) throw new Error("Supabase n'est pas configuré");
  if (!client) {
    client = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}
