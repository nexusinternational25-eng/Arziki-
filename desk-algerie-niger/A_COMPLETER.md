# À compléter

Le site fonctionne déjà en ligne. Les éléments ci-dessous sont nécessaires pour que les demandes arrivent et soient stockées.

## 1. Indispensable pour recevoir les demandes

- [ ] **Resend (e-mails)** : créer un compte sur https://resend.com, ajouter et vérifier le domaine `amanexus.com` (Resend affiche 3 enregistrements DNS à créer), puis créer une clé API.
  À fournir : `RESEND_API_KEY` et l'adresse d'expédition souhaitée (`RESEND_FROM`, par exemple `desk@amanexus.com`).
  Tant que le domaine n'est pas vérifié, Resend n'envoie qu'à l'adresse du titulaire du compte.
- [ ] **Supabase (base de données)** : créer un projet sur https://supabase.com (région Europe conseillée), exécuter `supabase/migrations/001_demandes.sql` dans SQL Editor.
  À fournir : `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` (Project Settings > API).
- [ ] **Mot de passe admin** : un mot de passe provisoire a été réglé dans Vercel (`ADMIN_PASSWORD`). À remplacer par le vôtre (12 caractères au moins).

Tant que ni Resend ni Supabase ne sont branchés, le formulaire l'indique honnêtement et propose l'e-mail et le WhatsApp.

## 2. Domaine

- [ ] Choisir l'adresse définitive (`desk.amanexus.com` ou un domaine dédié) et créer l'enregistrement DNS (voir README, section « Nom de domaine »).
- [ ] Mettre à jour `NEXT_PUBLIC_SITE_URL` dans Vercel. Valeur provisoire : l'adresse `vercel.app` du projet.

## 3. Textes à confirmer

- [ ] Nom arabe du site de forage : « كفرا » pour Kafra.
- [ ] Durée de conservation des demandes sans suite : **3 ans** (valeur provisoire, page Confidentialité).
- [ ] Directeur de la publication : « le directeur de NEXUS International » (mentions légales). Préciser si un nom doit apparaître.
- [ ] Relecture de l'arabe par un locuteur algérien avant une large diffusion.

## 4. Optionnel

- [ ] Cloudflare Turnstile (anti-robots) : `TURNSTILE_SECRET_KEY` et `NEXT_PUBLIC_TURNSTILE_SITE_KEY`.
- [ ] Photos définitives (mêmes noms de fichiers, voir README). Les photos actuelles viennent des planches fournies, recadrées sans bandeaux de couleur.
- [ ] Dépôt GitHub dédié `desk-algerie-niger` : le portail est pour l'instant dans le dossier `desk-algerie-niger/` du dépôt `Arziki-`. Il peut être déplacé à l'identique dans un dépôt séparé.
- [ ] Articles : deux guides d'exemple sont en brouillon dans `content/articles/` (non publiés).
