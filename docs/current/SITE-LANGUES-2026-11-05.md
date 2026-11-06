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

## 3 bis. Étape 1 faite le 06/11 : la base technique (rien d'une langue n'est en ligne)

- `site-public/langues.py` : adresses par langue, `lang`/`dir`, hreflang réciproques avec `x-default`, plan du site avec `xhtml:link`, sélecteur de langue. `content/langues.json` dit quelles langues sont « en cours » (aperçus seulement) et lesquelles sont « publiées » (production). Une langue n'existe que si `content/pages.<langue>.json` existe, avec **toutes** les routes et les mêmes sections que le français : sinon la construction échoue (jamais de page à moitié traduite).
- **Sélecteur de langue** : un bouton rond (globe et code de la langue) qui ouvre une carte blanche, chaque langue dans son écriture, la langue courante cochée ; dans le pied de page, les mêmes liens en pastilles. Des liens HTML, sans script de traduction ; un petit script ferme le menu au clic ailleurs et à Échap. Absent tant qu'une seule langue est publiée. Le nom « العربية » a sa police de 3 Ko (Noto Sans Arabic, OFL).
- **Adresses `/ar/`, `/en/`, `/es/`, `/pt/`** : elles menaient (307) à l'écran de connexion de l'application, en français. Elles mènent maintenant à la même page en français (`/ar/tarifs` vers `/fr/tarifs`) tant que la langue n'est pas publiée, puis à leur propre page.
- **Racine `/`** : inchangée (vers `/fr/`) tant qu'une seule langue est publiée. Dès la deuxième : page statique de choix de langue, `x-default`, sans redirection automatique (à faire avec la mise en ligne de l'arabe).
- **Reste à faire pour une langue** : le contenu des pages (`pages.<langue>.json`, 23 pages, 12 000 mots environ) ; les textes écrits dans le code (menus, pied de page, questions de l'accueil, simulateur de prix en JavaScript) ; les textes de `direction.json` et les légendes d'images (`images.json`) ; la feuille de style pour le sens de lecture inversé (`inset-inline`, `margin-inline`, flèches, illustrations de l'accueil) ; la police arabe réduite, chargée seulement sur les pages arabes.
- **Pour le pilote** : la garde du workflow ne connaît pas `fr/assets/noto-sans-arabic-langue.woff2` (3 Ko, comme les polices des citations) ; à ajouter à la liste vérifiée par `flutter-deploy.yml`.

## 4. Limite à dire honnêtement

L'application n'affiche que le français et l'arabe. Le choix de la langue dans l'application est un lot séparé (PREFERENCES-WEB). Un bouton du site en anglais mène pour l'instant à une application en français.

## 5. Règles qui valent pour chaque langue

Vocabulaire : `mots-rewayah` (le sens du français). Avis des familles : jamais modifiés, montrés dans leur langue d'origine. Prix : `tarifs-2026-10-18.json`. Aucune adresse e-mail lisible par un robot. Pas deux langues mélangées sur une page (M-29), sauf le texte original arabe des citations (exception du 03/11, articles). Aucune note personnelle ou technique sur le site (directeur, 05/11).
