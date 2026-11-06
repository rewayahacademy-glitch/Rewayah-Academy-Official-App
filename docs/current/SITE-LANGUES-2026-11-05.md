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

## 3 ter. Étape 2 faite le 06/11 : l'arabe, 23 pages (en aperçu seulement, pas en ligne)

- **Contenu** : `content/pages.ar.json` (les 23 pages, mêmes routes et mêmes sections que le français : la construction échoue sinon), `content/ui.ar.json` (les textes écrits dans le code : menus, pied de page, gabarits de prix, légendes d'images, questions de l'accueil), `content/textes_js.ar.json` (le simulateur de prix, par modèles `t('… {marqueur} …')` dans `styles/site.js`). Traduits par des agents de traduction, **jamais relus par une personne arabophone** : à relire par un fondateur avant la mise en ligne.
- **Versets et hadiths** : les quatre articles ne reprennent aucune traduction française. Le texte arabe original des versets (Mushaf de Médine) et des hadiths est le même, mot pour mot, que dans l'édition française (un test le garantit) ; là où le français citait une traduction, l'arabe renvoie à la référence et au bloc arabe, ou résume le sens sans guillemets. Les citations d'Ibn Khaldûn, d'al-Ghazâlî et d'Ibn al-Jazarî, que le français ne donne qu'en traduction, sont résumées au discours indirect : **le texte arabe original de ces trois auteurs est à fournir** si on veut les citer.
- **Mise en page** : sens de lecture inversé par la grille et les propriétés logiques ; police Noto Sans Arabic (OFL) de 37 Ko, réduite au bloc arabe et aux graisses 400 à 700, annoncée et chargée **seulement** par une page arabe ; espacement des lettres retiré (il casse les liaisons) ; flèches retournées ; montants isolés (`55 $` reste `55 $`) ; les illustrations ne sont jamais mises en miroir (l'accueil place le texte à gauche de la porte, aligné à droite contre elle).
- **Test de complétude** (`tests/test_langues.py`) : aucune phrase française ne subsiste dans une langue présente ; 135 tests au total.
- **Contrôles faits sur `/ar/`** (23 pages, 1440 et 390 px) : aucune erreur JavaScript, aucun débordement, aucune image cassée ; audit axe (WCAG 2.2 AA) : aucune violation ; contraste de chaque texte : aucun échec.
- **Poids mesuré** (octets, gzip entre parenthèses) : le site français change peu (`site.css` 265 852 → 273 152 (60 800 → 63 030), `motion.js` +0,6 Ko, `site.js` +1 Ko, accueil +0,8 Ko) ; une page arabe ajoute la police de 37 Ko, une fois, puis elle est en cache ; accueil arabe 39 974 (9 823), français 33 734 (8 101). Vitesse sur un vrai téléphone : non mesurée.

### Points à faire trancher par une personne arabophone (relevés par les traducteurs)

1. **Noms de personnes** en lettres arabes, translittérés : عبد الله محيي الدين سو (directeur), مامادو عليمو ديالو, أحمد ديالو.
2. **Nom de l'académie** : « أكاديمية الرواية » sur le site (décision de consigne) ; l'application écrit « أكاديمية رواية ».
3. **Chiffres** : latins (0-9) partout sur le site ; l'application utilise les chiffres arabes d'Orient dans ses textes juridiques.
4. **Vocabulaire** : parrainage = « الإحالة » ; observation d'une séance = « المراقبة » (« المتابعة » serait plus doux) ; « Comment ça marche » = « كيف نعمل » ; « Mentions légales » = « الإشعارات القانونية » (celui de l'application) ; assistance = « الدعم » ; « Classe » en capitale (terme défini des textes juridiques) devient « الفصل ».
5. **Textes juridiques** : traduction fidèle des textes français, identiques à ceux de l'application ; formules à valider par un juriste (« حق العدول » pour la rétractation, « القواعد الآمرة », « هيئة حماية البيانات »).
6. **Noms d'instituts** de la page « autres chemins » : formes arabes déduites par les traducteurs (معهد الريحان, معهد الصحابة, أكاديمية نور البيان, بيت القرآن) ; à vérifier sur leurs sites.
7. **Ajouts des traducteurs** à relire : « رضي الله عنه » après quelques compagnons, « رحمه الله » après Ibn al-Jazarî ; l'équivalent hégirien du XIe siècle.

## 3 quinquies. Étape 3 faite le 06/11 : anglais, espagnol, portugais (en aperçu seulement, pas en ligne)

- **Contenu** : `pages.en|es|pt.json` (23 pages chacune, mêmes routes et sections que le français), `ui.en|es|pt.json` (mêmes phrases que le dictionnaire arabe, plus « Accueil » et « Contact » du fil d'Ariane), `textes_js.en|es|pt.json` (simulateur). Traduits par des agents depuis le français, **jamais relus par une personne de chaque langue**.
- **Versets, hadiths, auteurs classiques** : aucune traduction citée (droits non confirmés, aucune traduction automatique). Le bloc arabe original reste ; le paragraphe résume le sens sans guillemets, avec la référence. Les sources renvoient aux traductions françaises (Hamidullah, HadeethEnc).
- **Code** : montants « $55 » et « 12.5% » en anglais, virgule décimale en espagnol et portugais (`bloc_tarifs.py`, `site.js`) ; guillemets de chaque langue ; fil d'Ariane traduit ; grande phrase de l'accueil qui passe à la ligne au lieu de déborder.
- **Contrôle de complétude** : une phrase française oubliée se reconnaît par comparaison avec les fichiers de la langue (l'écriture ne suffit plus) ; la construction de production refuse une langue tant qu'il en reste.
- **Contrôles faits** : 69 pages à 1440 et 390 px, aucun débordement, aucune erreur JavaScript ; simulateur vérifié dans les trois langues. Accessibilité (axe) et contraste : non refaits pour ces langues.

### Points à faire trancher par une personne de chaque langue

1. Anglais : orthographe britannique (enrolment, programme) ; « household » pour foyer, « bursary », « referral », « class logbook » (cahier de transmission).
2. Espagnol : « clase » pour la classe, donc « curso » pour « cours » ; « usted » ; « padrinazgo » ; « hogar ».
3. Portugais : orthographe européenne ; « turma », « recomendação » (parrainage), « Cookies e dados locais » (titre de la page cookies).
4. Paragraphe du litige bancaire : « remboursement total » rendu par « a refund of the entire payment », « un reembolso de todo el importe », « tratado como reembolsado » ; à confirmer face à la règle « jamais intégral ».
5. Erreur possible dans le français, article « apprendre seul » : an‘amti est le « tu » féminin, pas « j'ai comblé » ; à vérifier par un spécialiste avant de corriger les cinq langues.

## 3 quater. Pour mettre l'arabe en ligne (à faire, dans cet ordre)

1. Une personne arabophone relit `/ar/` sur l'aperçu et tranche les points ci-dessus.
2. Ajouter `"ar"` à `publiees` dans `content/langues.json` (le test de complétude garde la barrière).
3. La racine `/` devient une page statique de choix de langue (`x-default`), sans redirection automatique ; **pas faite**, elle accompagne la mise en ligne de la deuxième langue.
4. Le pilote ajoute `fr/assets/noto-sans-arabic-langue.woff2` et `noto-sans-arabic-site.woff2` à la garde des polices de `flutter-deploy.yml`.

## 4. Limite à dire honnêtement

L'application n'affiche que le français et l'arabe. Le choix de la langue dans l'application est un lot séparé (PREFERENCES-WEB). Un bouton du site en anglais mène pour l'instant à une application en français.

## 5. Règles qui valent pour chaque langue

Vocabulaire : `mots-rewayah` (le sens du français). Avis des familles : jamais modifiés, montrés dans leur langue d'origine. Prix : `tarifs-2026-10-18.json`. Aucune adresse e-mail lisible par un robot. Pas deux langues mélangées sur une page (M-29), sauf le texte original arabe des citations (exception du 03/11, articles). Aucune note personnelle ou technique sur le site (directeur, 05/11).
