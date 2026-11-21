#!/usr/bin/env bash
# Prépare le dossier complet à déposer chez LWS, et son ZIP.
#
# Utilisation : site/paquet_lws.sh <dossier application web> <dossier console web> <fichier ZIP>
# Les deux dossiers sont des compilations Flutter web avec <base href="./">,
# pour fonctionner dans n'importe quel sous-dossier.
#
# Résultat dans le ZIP :
#   public_html/   tout le contenu à déposer à la racine du site amanexus.com
#   guides/        les guides pour le propriétaire (non publiés en ligne)
set -euo pipefail

APP_WEB="$1"
CONSOLE_WEB="$2"
ZIP="$3"
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
SORTIE="$RACINE/deploiement-lws"

# 1. Application et console dans deploiement-lws/arziki/
rm -rf "$SORTIE/arziki"
mkdir -p "$SORTIE/arziki"
cp -r "$APP_WEB" "$SORTIE/arziki/app"
cp -r "$CONSOLE_WEB" "$SORTIE/arziki/console"
find "$SORTIE/arziki" -name '*.symbols' -delete
for d in app console; do
  sed -i 's#<base href="[^"]*">#<base href="./">#' "$SORTIE/arziki/$d/index.html"
  # Hors index Google, et pas de cache sur index.html (mises à jour visibles tout de suite).
  cat > "$SORTIE/arziki/$d/.htaccess" <<'HT'
<IfModule mod_headers.c>
Header set X-Robots-Tag "noindex, nofollow"
<FilesMatch "^(index\.html|flutter_bootstrap\.js|version\.json)$">
Header set Cache-Control "no-cache"
</FilesMatch>
</IfModule>
AddType application/wasm .wasm
HT
done

# 2. Pages du site (le dossier arziki/ est conservé), puis contrôle automatique.
python3 "$RACINE/site/construire.py"
python3 "$RACINE/site/verifier.py"

# 3. ZIP : public_html/ et guides/
TMP="$(mktemp -d)"
cp -r "$SORTIE" "$TMP/public_html"
mkdir -p "$TMP/guides"
cp "$RACINE"/docs/lws/*.md "$TMP/guides/"
cp "$RACINE/docs/REFERENCEMENT_GOOGLE.md" "$TMP/guides/"
rm -f "$ZIP"
(cd "$TMP" && zip -qr -9 "$ZIP" public_html guides)
rm -rf "$TMP"
echo "Dossier LWS prêt : $ZIP ($(du -h "$ZIP" | cut -f1))"
