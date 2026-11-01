# Desk Algérie-Niger

Portail web bilingue (arabe et français) animé par NEXUS International : la passerelle d'affaires entre l'Algérie et le Niger.
Les visiteurs s'informent et déposent des demandes, qui arrivent chez NEXUS International (e-mail et base de données).

Initiative privée de NEXUS International. Ce portail n'est pas un site officiel des gouvernements algérien ou nigérien.

## Contenu du dossier

| Dossier | Rôle |
|---|---|
| `app/[locale]/` | Pages publiques, en arabe (`/ar`, langue par défaut) et en français (`/fr`) |
| `app/admin/` | Espace d'administration (liste, détail, statuts, notes, export CSV) |
| `app/api/demande/` | Réception des demandes : validation, anti-spam, base, e-mails |
| `components/` | En-tête, pied de page, carte de la route, formulaire, bouton WhatsApp |
| `lib/contenu.ts` | Tous les textes des services, secteurs, contexte et publics (fr et ar) |
| `lib/legal.ts` | Textes des mentions légales et de la politique de confidentialité |
| `messages/ar.json`, `messages/fr.json` | Textes de l'interface (menus, boutons, formulaire) |
| `content/articles/<langue>/` | Articles de la page Ressources (fichiers MDX) |
| `public/images/` | Photos du site |
| `public/og/` | Images de partage sur les réseaux sociaux |
| `supabase/migrations/` | Création de la table `demandes` |

Technique : Next.js 16 (App Router), TypeScript, Tailwind CSS 4, next-intl, React Hook Form et Zod, Resend, Supabase.

## Installation locale

```bash
cd desk-algerie-niger
npm install
cp .env.example .env.local   # puis remplir les valeurs
npm run dev                  # http://localhost:3000
```

Vérifications : `npm run lint`, `npx tsc --noEmit`, `npm run build`.

## Variables d'environnement

| Nom | Rôle |
|---|---|
| `RESEND_API_KEY` | Clé Resend pour envoyer les e-mails |
| `RESEND_FROM` | Expéditeur, sur un domaine vérifié dans Resend (ex. `Desk Algérie-Niger <desk@amanexus.com>`) |
| `CONTACT_TO_EMAIL` | Adresse qui reçoit les demandes (`operation@amanexus.com`) |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Base de données des demandes |
| `NEXT_PUBLIC_SITE_URL` | Adresse publique du site, sans barre finale |
| `ADMIN_PASSWORD` | Mot de passe de `/admin` (12 caractères au moins) |
| `TURNSTILE_SECRET_KEY`, `NEXT_PUBLIC_TURNSTILE_SITE_KEY` | Optionnel : Cloudflare Turnstile |

Une demande est considérée comme reçue si elle est enregistrée en base **ou** envoyée par e-mail à NEXUS. Si aucun des deux ne fonctionne, le visiteur ne voit jamais « reçue » : il voit l'e-mail et le WhatsApp à contacter directement.

## Base de données

Dans Supabase : menu **SQL Editor**, coller le contenu de `supabase/migrations/001_demandes.sql`, cliquer **Run**.
La table est protégée (RLS activé, aucune règle publique) : seul le serveur du portail y accède avec la clé de service.

## Déploiement

Le projet Vercel `desk-algerie-niger` est relié au dépôt GitHub, avec `desk-algerie-niger` comme dossier racine.
Chaque push déclenche un déploiement (aperçu pour les branches, production pour `main`).
Les variables d'environnement se règlent dans Vercel : **Settings > Environment Variables**, puis **Redeploy**.

L'action GitHub `.github/workflows/desk-algerie-niger.yml` lance lint, vérification des types et build à chaque push qui touche ce dossier.

## Ajouter un article

1. Créer `content/articles/fr/mon-article.mdx` (et `content/articles/ar/mon-article.mdx` pour l'arabe, même nom de fichier).
2. En haut du fichier :
   ```
   ---
   titre: "Titre de l'article"
   resume: "Une ou deux phrases."
   date: "2026-11-15"
   brouillon: false
   ---
   ```
3. Écrire le texte en Markdown (titres `##`, listes `-`).
4. `brouillon: true` garde l'article caché. Pour relire les brouillons en local : `AFFICHER_BROUILLONS=1 npm run dev`.

## Changer une image

Remplacer le fichier dans `public/images/` en gardant **exactement le même nom** (format JPG, 1600 px de large conseillé).
Noms utilisés : `hero-route-sahara.jpg`, `convoi-transsaharien.jpg`, `agadez-ville.jpg`, `port-lome-conteneurs.jpg`, `port-oran.jpg`, `entrepot-agroalimentaire.jpg`, `reunion-affaires.jpg`, `hoggar-tamanrasset.jpg`, `marche-niamey.jpg`, `energie-centrale.jpg`, `formation-equipe.jpg`, `banque-financement.jpg`, `partenariat-marche.jpg`, `poignee-de-main.jpg`, `logistique-port.jpg`.
Aucune image ne doit montrer de drapeau, d'armoiries ni de logo officiel.

## Nom de domaine

Pour `desk.amanexus.com` : dans Vercel, **Settings > Domains > Add**, saisir `desk.amanexus.com`.
Chez l'hébergeur DNS de `amanexus.com`, créer l'enregistrement que Vercel affiche, en général :

| Type | Nom | Valeur |
|---|---|---|
| CNAME | `desk` | `cname.vercel-dns.com` |

Puis mettre `NEXT_PUBLIC_SITE_URL=https://desk.amanexus.com` dans Vercel et redéployer.
Pour un domaine dédié (ex. `desk-algerie-niger.com`) : enregistrement `A` sur `@` vers `76.76.21.21` et `CNAME` `www` vers `cname.vercel-dns.com`.
