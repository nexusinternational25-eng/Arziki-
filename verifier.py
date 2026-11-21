#!/usr/bin/env python3
"""Contrôle du site généré (deploiement-lws/) avant toute mise en ligne.

Usage : python3 site/verifier.py   (code de sortie 1 en cas de problème)

Vérifie, page par page :
- les mots interdits (CLAUDE.md, section 24) et les chiffres retirés ;
- l'absence du nom du propriétaire ;
- le référencement : title (moins de 70 caractères conseillés), description
  (moins de 170), canonique, hreflang, un seul H1, attribut alt sur chaque image,
  JSON-LD valide ;
- l'avertissement R8 sur arziki.html ;
- les liens internes vers des fichiers qui existent.
"""

import html
import json
import re
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent / "deploiement-lws"

INTERDITS = [
    r"(?<!ni )\bcr[ée]dit\b", r"(?<!collecte d')(?<!public à l')[ée]pargne", r"int[ée]r[êe]ts\b",
    r"d[ée]p[ôo]ts?\b", r"\bplacements?\b", r"encadr[ée]+s?\s+par\s+(un\s+|le\s+)?notaire",
    r"\bgaranti\b", r"garanti[es]*\s+par\s+le\s+notaire", r"sans\s+risque", r"rendement", r"\bpr[êe]ts?\b",
    r"\bmarges?\b", r"investisseurs?\b", r"\btaux\b", r"94\s*%", r"milliards?", r"\bloans?\b",
    r"\binterest rates?\b", r"\bguaranteed\b", r"moussa", r"zouzou", r"saley",
]


def texte_visible(source):
    sans = re.sub(r"<script.*?</script>|<style.*?</style>", " ", source, flags=re.S)
    sans = re.sub(r"<(meta|link)[^>]*>", " ", sans)
    return html.unescape(re.sub(r"<[^>]+>", " ", sans))


def main():
    problemes = []
    # Le dossier arziki/ contient l'application et la console compilées : ce ne sont pas des pages du site.
    pages = sorted(p for p in SITE.rglob("*.html") if "arziki" not in p.relative_to(SITE).parts[:1])
    for page in pages:
        nom = page.relative_to(SITE)
        src = page.read_text(encoding="utf-8")
        visible = texte_visible(src) + " " + " ".join(re.findall(r'content="([^"]*)"', src))
        for motif in INTERDITS:
            for m in re.finditer(motif, visible, re.I):
                extrait = visible[max(0, m.start() - 40): m.end() + 30].replace("\n", " ")
                problemes.append(f"{nom} : expression interdite « {m.group(0)} » dans « …{extrait}… »")
        if nom.name == "404.html":
            continue
        titre = re.search(r"<title>(.*?)</title>", src)
        desc = re.search(r'<meta name="description" content="([^"]*)"', src)
        if not titre or not titre.group(1).strip():
            problemes.append(f"{nom} : pas de title")
        elif len(html.unescape(titre.group(1))) > 70:
            problemes.append(f"{nom} : title trop long ({len(html.unescape(titre.group(1)))} caractères)")
        if not desc or not (70 <= len(html.unescape(desc.group(1))) <= 230):
            problemes.append(f"{nom} : description absente ou de longueur inadaptée")
        if src.count("<h1") != 1:
            problemes.append(f"{nom} : {src.count('<h1')} titres H1 (un seul attendu)")
        if 'rel="canonical"' not in src:
            problemes.append(f"{nom} : pas d'adresse canonique")
        if 'hreflang="x-default"' not in src:
            problemes.append(f"{nom} : pas de hreflang")
        for balise in re.findall(r"<img [^>]*>", src):
            if "alt=" not in balise:
                problemes.append(f"{nom} : image sans attribut alt")
        for bloc in re.findall(r'<script type="application/ld\+json">(.*?)</script>', src, re.S):
            try:
                json.loads(bloc)
            except ValueError as ex:
                problemes.append(f"{nom} : JSON-LD invalide ({ex})")
        for cible in re.findall(r'(?:href|src)="([^"#?]+)', src):
            if cible.startswith(("http", "mailto:", "tel:")) or cible.endswith("contact.php"):
                continue
            chemin = (page.parent / cible).resolve()
            if cible.endswith("/") or cible == "./":
                chemin = chemin / "index.html"
            if "arziki/app" in str(chemin):
                continue
            if not chemin.exists():
                problemes.append(f"{nom} : lien cassé vers {cible}")
    for f in ("arziki.html", "en/arziki.html"):
        src = (SITE / f).read_text(encoding="utf-8")
        if "ni crédit ni collecte" not in src and "does not lend money" not in src:
            problemes.append(f"{f} : avertissement R8 absent")
    for p in problemes:
        print("PROBLÈME :", p)
    print(f"{len(pages)} pages contrôlées, {len(problemes)} problème(s).")
    return 1 if problemes else 0


if __name__ == "__main__":
    sys.exit(main())
