# SITE-LANGUES : fiche du 05/11/2026 (site public)

Mission confiée par le garde-cap à la demande du directeur, confirmée par lui le 05/11 : traduire le site public dans les langues décidées (K-41) :
arabe d'abord, puis anglais, espagnol, portugais. Aucune langue de plus. Une langue n'est mise en ligne que lorsque **toutes** ses pages sont faites.
Zone : `site-public/**`. Branche `claude/site-langues`.

## 1. Bonnes pratiques retenues, avec leurs sources

| Sujet | Règle retenue | Source |
| :--- | :--- | :--- |
| Adresses | Une adresse par langue : `/fr/`, `/ar/`, `/en/`, `/es/`, `/pt/` | https://developers.google.com/search/docs/specialty/international/localized-versions |
| hreflang | Réciproques : chaque page liste toutes ses versions, elle-même comprise, avec un `x-default` ; sinon Google les ignore | même page |
| Plan du site | `<xhtml:link rel="alternate" hreflang=…>` dans chaque `<url>`, espace de noms `xmlns:xhtml`, généré par `build_site.py` | même page |
| Pas de redirection forcée | Google déconseille de rediriger selon la langue supposée ou l'adresse IP, et son robot n'envoie pas `Accept-Language` : liens visibles seulement | https://developers.google.com/search/docs/specialty/international/managing-multi-regional-sites |
| Racine `/` | Quand une deuxième langue est en ligne : page statique de choix de langue, marquée `x-default`, sans redirection automatique. D'ici là, `/` reste ce qu'elle est (vers `/fr/`) | pratique tirée des deux pages ci-dessus ; la page « versions localisées » ne détaille pas la racine |
| Arabe | `lang="ar"` et `dir="rtl"` sur `<html>` (`lang` ne fixe pas la direction) ; propriétés CSS logiques (`margin-inline-start`, `padding-inline`, `text-align: start`) | https://www.w3.org/International/questions/qa-html-dir |
| Ce qui ne se retourne pas seul | Flèches directionnelles (`scaleX(-1)`), `translate` des animations, dégradés, ombres décalées : feuille d'exceptions RTL, vérifiée à l'œil | https://rtlstyling.com/posts/rtl-styling (source non officielle) |
| Sélecteur de langue | Cinq liens HTML `<a href hreflang lang>`, chaque langue dans son écriture (Français, العربية, English, Español, Português), sans JavaScript ni liste déroulante ; `lang` sur le lien | https://www.w3.org/International/questions/qa-navigation-select ; https://www.w3.org/International/questions/qa-html-language-declarations ; WCAG 3.1.2 https://www.w3.org/WAI/WCAG22/Understanding/language-of-parts.html |
| Police arabe | Auto-hébergée, en woff2, sous-ensemble par `pyftsubset` (`--layout-features=*` pour garder les liaisons des lettres), chargée seulement sur les pages arabes ; Noto Sans Arabic (OFL 1.1) | https://fonttools.readthedocs.io/en/latest/subset/index.html ; https://fonts.google.com/noto/specimen/Noto+Sans+Arabic/about |
| Outil | Garder `build_site.py` : un fichier de contenu par langue, un seul gabarit, la construction échoue si une clé manque. Aucun widget ni proxy de traduction dans le navigateur | jugement de l'agent, sans source ; aucun outil externe n'apporte de gain pour un script maison |

## 2. Non vérifié, à dire tel quel

- Chiffres latins ou arabo-indiens dans un site arabe : aucune source W3C trouvée. **Choix de l'agent : chiffres latins** (prix, dates, nombres), un seul système par page ; modifiable en un point.
- Taille d'un sous-ensemble de police arabe : à mesurer sur nos pages, pas encore mesurée.
- Traductions du Coran en anglais, espagnol, portugais : Tanzil (https://tanzil.net/trans/) les publie, mais pour un usage non commercial. Une académie payante n'est probablement pas dans ce cadre. **Droits à confirmer avant l'anglais.** L'arabe n'est pas concerné : les versets sont déjà en arabe dans les articles.
- Aucune traduction automatique des versets ni des invocations.

## 3. Plan par étapes (rien n'est en ligne tant qu'une langue n'est pas complète)

1. **Base technique** : routes par langue, `lang`/`dir`, `hreflang`, plan du site, sélecteur de langue, propriétés logiques et exceptions RTL, police arabe, textes de `build_site.py` sortis dans un fichier par langue.
2. **Arabe** : accueil, pages principales, articles, pages légales. Relecture de l'arabe par un fondateur avant la mise en ligne.
3. **Anglais**, puis **espagnol** et **portugais**.
4. **Correction** : `rewayahacademy.com/ar|en|es|pt/` renvoient aujourd'hui (307) vers `app.rewayahacademy.com/<langue>/`, l'écran de connexion de l'application en français. Mener chacune à sa page du site dès que la langue est en ligne ; d'ici là, vers `/fr/`.

## 4. Limite à dire honnêtement

L'application n'affiche que le français et l'arabe. Le choix de la langue dans l'application est un lot séparé (PREFERENCES-WEB). Un bouton du site en anglais mène pour l'instant à une application en français.

## 5. Règles qui valent pour chaque langue

Vocabulaire : `mots-rewayah` (le sens du français). Avis des familles : jamais modifiés, montrés dans leur langue d'origine. Prix : `tarifs-2026-10-18.json`. Aucune adresse e-mail lisible par un robot. Pas deux langues mélangées sur une page (M-29), sauf le texte original arabe des citations (exception du 03/11, articles). Aucune note personnelle ou technique sur le site (directeur, 05/11).
