# Audit de marque et de gouvernance documentaire, 19/10/2026

Note d'audit préalable au Brand Book. Elle établit l'état réel, juge le manifeste et le brief fournis par
ChatGPT (« Manifeste de marque et cahier des charges du Brand Book », version 1.1 du 19/10/2026), et
trace la diffusion vers les agents. Les livrables qui en découlent sont dans ce dossier.

## 1. Inventaire (phase 0)

### 1.1 État Git au départ

- Dépôt : `rewayahacademy-glitch/Rewayah-Academy-Official-App`.
- `main` (`4a7aa2b`, 22/09/2026) est en retard de plus de 2 400 commits. La ligne de travail réelle est la
  chaîne de PR en brouillon : `claude/hopeful-mayer-m7p3hq` (PR #41, tête au 19/10, `dbe6b444`) →
  `claude/corrections-audit-2026-10-17` (#39) → `claude/backend-reprise` (#37) → `ccr-1b1bfa0b-m1kvkk`.
- Ce travail part de `dbe6b444` sur `claude/dazzling-edison-s8m5mf`. Aucune modification non commitée,
  aucune opération Git inachevée au départ.
- Branches non intégrées à la tête mais sans effet sur la marque : `claude/sharp-goldberg-z10a13`
  (simulation économique, PR #40), `claude/jolly-gauss-7rlt4y` (compétences de design, PR #42).
  `ui/brand-logo-2026` (`3e85c63e`, 10/10) : ses 24 SVG sont dans l'arbre, identiques octet pour octet ;
  seule différence, l'ancienne intégration par `pubspec.yaml`, remplacée par `BrandLogo` (LOGO-APP).

### 1.2 Brief ChatGPT

Fourni en pièce jointe de session (`brand_strategy.txt`), non versionné. Il n'existait dans le dépôt
aucun manifeste, aucune signature, aucun `docs/brand/`.

### 1.3 Sources de marque trouvées

| Source | Rôle | Statut |
|---|---|---|
| `assets/brand/logo/` et son `README.md` | Logo et règles d'usage | Actif, décidé 10/10 |
| `docs/current/BRAND-ORN-1.md` | Ornement, signature discrète | Actif, décidé 11/10 |
| `docs/current/UX_REVIEW_LOGO-APP.md` | Emplacements du logo dans l'app | Actif |
| `lib/core/theme/app_palette.dart`, `app_typography.dart`, `app_radius.dart`, `app_spacing.dart` | Jetons ; seuls fichiers autorisés à porter couleurs et polices (`tool/verifier_jetons.dart`) | Actif, fait foi |
| `lib/core/marque/`, `lib/core/widgets/brand_logo.dart`, `ornement_marque.dart` | Rendu du logo et de l'ornement | Actif |
| `.claude/skills/mots-rewayah`, `.claude/skills/programme-rewayah` | Ton, vocabulaire, promesse, public | Actif, décidé 13-14/10 |
| `docs/current/REGISTRE-RECONCILIATION-2026-10-14.md` | Décisions du 14/10 (promesse) | Actif |
| `docs/current/sources-directeur-2026-10/` | Référentiel académique, dossier maître, guide finance | Sources du directeur |
| `docs/current/03_DESIGN_SYSTEM_ET_UX.md`, `DESIGN-GOV-2026-09-26.md` | Langage visuel, règles gelées | Actif |
| `site-public/` (`PRODUCT.md`, `DESIGN.md`, `content/`, `styles/`, `assets/`) | Site public | **Brouillon** (M-20) |
| `docs/site-public/SITE_00` à `SITE_07` | Historique du site | Partiellement périmé |
| `docs/archive/` | Anciennes identités et palettes | Archivé, ne pas charger |

### 1.4 Points d'entrée des agents

| Emplacement | Qui le lit | Suivi Git | Synchronisation démontrée |
|---|---|---|---|
| `CLAUDE.md` racine | Toute session Claude Code dans ce dépôt | Oui | Chargé automatiquement |
| `lib/CLAUDE.md`, `supabase/CLAUDE.md` | Claude Code dans ces dossiers | Oui | Chargé automatiquement |
| `.claude/skills/*` | Claude Code (compétences de projet) | Oui | Découverte automatique |
| `AGENTS.md` | ChatGPT / Codex, et les outils qui lisent ce fichier | Oui | Aucune preuve qu'un agent le lise encore (Codex indisponible depuis le 17/10) |
| `site-public/PRODUCT.md`, `DESIGN.md` | Agents de design du site | Oui | Aucune |
| Compétences du compte claude.ai (dont `rewayah-academy-knowledge`) | claude.ai, Claude Design, sessions Claude Code du compte | Non (compte) | Lecture seule depuis ce conteneur ; une modification locale ne remonte pas |
| Mémoire `C:\Users\dell\.claude\projects\C--\memory\MEMORY.md` | Sessions Claude Code sur le poste du directeur | Non | Absente de ce conteneur, non modifiable d'ici |
| Gemini, Cursor, Copilot | Aucun fichier d'instructions dans le dépôt | - | Aucun usage constaté |

## 2. Registre des faits (phase 1)

### A. Décisions explicites et confirmées

Voir `REGISTRE-DECISIONS-MARQUE.md`, M-01 à M-20, chacune avec sa source et sa date.

### B. Décisions implémentées et vérifiables

| Fait | Preuve |
|---|---|
| Logo rendu sans redessin depuis les SVG du directeur | `tool/generer_logo.dart`, `test/core/marque/logo_traces_test.dart` |
| Ornement signature, opacité 0,4, jamais inversé | `test/core/widgets/ornement_marque_test.dart` ; captures `docs/current/captures/BRAND-ORN-1/` |
| DM Sans et Plus Jakarta Sans dans l'app | `app_typography.dart` ; `verifier_jetons.dart` refuse toute autre famille |
| Palette mesurée en contraste | `test/theme/` (commentaire d'en-tête de `app_palette.dart`) |
| Promesse d'enregistrement retirée des textes | Lot LA-01 (17/10) |

### C. Propositions non validées

| Proposition | Origine |
|---|---|
| Vision, mission, ambition, positionnement, valeurs, texte du manifeste | ChatGPT, révisées ici (P-01 à P-03) |
| Signatures française et arabe | Directeur (candidates) ; articulation proposée ici (P-04 à P-06) |
| « Renaissance » : nouvelle offre, plateforme et identité | Livre des politiques V1.1, « PROPOSÉ pour adoption » (dossier maître, annexe 17) ; seules les dates sont reprises (M-19) |

### D. Contradictions, informations périmées, questions ouvertes

| # | Constat | Sources en conflit | Traitement |
|---|---|---|---|
| D-1 | **La compétence de compte `rewayah-academy-knowledge` (mai 2026) décrit un autre projet sous le nom de Rewayah Academy** : cours préenregistrés de Tawhid, Fiqh, Sira et EVI sur systeme.io, « contenu préenregistré », mission « formation islamique ». Elle se déclenche sur « Rewayah Academy » dans toute session du compte | Compétence du compte ↔ M-01, M-12, référentiel 13/10 | Remplacement préparé : `import/rewayah-academy-knowledge/SKILL.md` ; import manuel par le directeur (section 5) |
| D-2 | « Diaspora africaine » | `site-public/PRODUCT.md` (09/10) ↔ `programme-rewayah` section 8 (14/10, « quelle que soit son origine ») | La décision la plus récente prévaut ; `PRODUCT.md` corrigé, avec renvoi |
| D-3 | PISI décrit comme « programme autonome evergreen de Rewayah » | Guide finance V4 (02/10) ↔ message du directeur du 19/10 (« un autre projet ») | M-12 prévaut ; le guide reste une source historique |
| D-4 | Fond sombre `#1A1A25` | Commentaire d'en-tête de `app_palette.dart`, `assets/brand/logo/README.md` (ligne « Thème sombre »), dossier maître (partie C « Système de design gelé », section 1.1, et section 17.1), site brouillon ↔ valeur du code `#16161E` depuis `4f0286fa` (17/10) | Le code fait foi ; commentaires et README à rafraîchir dans un lot de code (hors de ce lot) ; O-05 pour le site |
| D-5 | « Les documents fournis ne fixent pas de valeurs HEX officielles » | `03_DESIGN_SYSTEM_ET_UX.md` (22/09) ↔ palette mesurée et figée (K-37, 24-26/09) | Antérieur ; la palette du code fait foi (M-16) |
| D-6 | Flutter « utilise Instrument Sans et Bricolage Grotesque » | `docs/site-public/SITE_03` (08/10) ↔ `app_typography.dart` | Périmé ; DM Sans et Plus Jakarta Sans sont en place |
| D-7 | Nom en arabe : latin obligatoire, ou « رواية » | `CPT-DIR-2.md` ↔ `assets/i18n/ar.i18n.json` | O-08 |
| D-8 | `AGENTS.md` donne encore le backend à Codex | `AGENTS.md` ↔ `CLAUDE.md` et `PASSATION-2026-10-17` | Signalé, hors du périmètre de marque ; renvoi ajouté vers la marque seulement |
| D-9 | Anciennes identités (vert et or ; violet, rose, taupe, crème) | `docs/archive/` | Archivées ; listées comme interdites dans le cahier visuel, section 0 |
| D-10 | Crème `#F8F4EE` en `background_color` PWA | `web/manifest.json` ↔ palette | Écart connu, sans effet de marque ; à revoir dans un lot web |
| D-11 | Lignes 13 à 15 de `lib/CLAUDE.md` en double ou mêlées | `lib/CLAUDE.md` | Signalé, non corrigé (hors marque) |

## 3. Audit du manifeste et du brief ChatGPT (phase 2)

| Sujet | État antérieur (ChatGPT) | Constat | Recommandation | Statut |
|---|---|---|---|---|
| Identité | « Académie d'enseignement du Coran… enseignants, parcours structurés, environnement numérique » | Exact (M-01) ; manque la forme réelle : classes stables, en direct | Ajouter classes stables, enseignant attitré, en direct | Manifeste 1, DÉCIDÉ pour le fond |
| Origine du nom | Section demandée, « faits et interprétations » | Aucune source sur l'intention ; sens lexical vérifiable | Sens lexical seul, intention marquée non documentée | O-01 |
| Raison d'être | Mêlée à la mission | Une raison d'être n'est pas une mission | Formulation distincte (accès indépendant du lieu) | PROPOSITION |
| Vérité fondatrice | Texte en quatre paragraphes | Fond exact (M-07) ; « école coranique en présentiel » répété ; dernière phrase floue sur l'ambition | Réécrit : garde la conviction, ajoute ce qu'on ne prétend pas, termine par l'engagement | P-02 |
| Vision | « Apprentissage islamique sérieux… » | Élargit au-delà du Coran, contraire à M-01 et M-12 | Recentrée sur le Coran et les familles | PROPOSITION |
| Mission | « Rendre l'apprentissage du Coran accessible à distance… » | Juste, mais « accessible » est vague | Décrit la pratique : classes stables, résultats exigés, accompagnement | PROPOSITION |
| Ambition | « Écosystème éducatif numérique… plateformes spécialisées » | Mêle d'autres projets ; contraire à M-12 | Retirée ; ambition de référence de sérieux, jamais au présent | PROPOSITION |
| Positionnement | Accompagnement, rigueur, outils | Conforme à M-06 | Gardé, avec ce que chaque dimension ne veut pas dire | DÉCIDÉ (fond) |
| Promesse | Non formulée comme telle | La promesse est décidée : rigueur et assiduité (M-18, 14/10), absente du brief | Ajoutée, avec la table « on promet / on ne promet pas » | DÉCIDÉ + PROPOSITION |
| Public | Parents et familles de la diaspora, adultes | Conforme à M-04 ; manque la règle d'écriture (M-05) | Ajoutée | DÉCIDÉ |
| Valeurs | Six valeurs | « Accessibilité » décrit la raison d'être et peut se lire comme prix bas | Cinq valeurs, chacune avec une preuve décidée et une preuve à construire | P-03 |
| Ton | Six paires « sans être » | Cohérent avec le ton décidé « ferme et bienveillant » (M-09), qui n'était pas cité | Ton décidé posé en tête, paires gardées | DÉCIDÉ + PROPOSITION |
| Signatures | Deux candidates, trois options | Analyse demandée ; aucune n'est adoptée | Analyse linguistique et graphique, option 2 recommandée | P-04 à P-06, O-02, O-03 |
| PISI | Mention discrète possible dans une section « horizon » | Le directeur précise le 19/10 : autre projet, aucune interférence | Aucune section ; une seule règle de séparation | DÉCIDÉ M-12 |
| Direction artistique | Éditoriale, photos naturelles, références islamiques discrètes | Compatible ; mais aucune photo authentique n'existe ; le site cité comme référence est un brouillon | Gardée en proposition ; photos et site rangés en manques | P-07, O-04, M-20 |
| Identité visuelle existante | Ne rien redessiner | Conforme ; tokens à « récupérer » sans dire où | Sources exactes et copie de lecture datée | DÉCIDÉ |
| Architecture du Brand Book | 24 chapitres, 28 à 36 pages | Le chapitre « relation PISI » tombe ; « réseaux sociaux » sans actifs | À recomposer par Claude Design à partir du manifeste et du cahier | PROPOSITION |
| Livrables (PDF, Brand Book final) | Demandés | Hors de ce lot : relèvent de Claude Design après validation | Préparés : manifeste, cahier, amorçage | - |

## 4. Choix d'architecture documentaire (phase 6)

- **Dossier `docs/current/marque/`** plutôt que `docs/brand/` : le `CLAUDE.md` racine ne reconnaît comme
  actif que `docs/current/`. Un dossier hors de cet arbre serait lu comme historique.
- **Une source par sujet** : le manifeste (fond), le cahier visuel (forme), le registre (statuts), cette
  note (preuves de l'audit), `00_LIRE_D_ABORD.md` (entrée). Les instructions d'agents **renvoient** à ces
  fichiers et ne résument que les interdits critiques.
- Aucun document existant supprimé, aucun archivé. Les règles du logo et de l'ornement restent où elles
  sont ; le cahier les cite.

## 5. Diffusion aux agents (phase 7 et 8)

| Emplacement | Action | Réalité |
|---|---|---|
| `CLAUDE.md` racine | Une ligne dans la table « Tâche / Lire » | Modifié dans le dépôt |
| `lib/CLAUDE.md` | Une ligne : logo, ornement, marque | Modifié dans le dépôt |
| `.claude/skills/marque-rewayah/SKILL.md` | Nouvelle compétence de projet (interdits et renvois) | Créé dans le dépôt |
| `AGENTS.md` | Section « Marque » (renvoi) | Modifié dans le dépôt |
| `site-public/PRODUCT.md`, `site-public/DESIGN.md` | Renvoi au cahier ; correction de D-2 | Modifiés dans le dépôt |
| Compétence de compte `rewayah-academy-knowledge` | Remplacement préparé dans `import/` | **Non modifiée** : import manuel par le directeur dans claude.ai (Réglages, Compétences) |
| Claude Design | Texte d'amorçage (cahier, section G) et compétence `marque-rewayah` à téléverser | **Préparé**, pas importé |
| Mémoire du poste du directeur | Note à coller, `import/LISEZMOI.md` section 3 | **Préparée**, pas écrite |
| Gemini, Cursor, Copilot | Rien : aucun usage constaté dans le projet | - |
| CI GitHub | Aucun contrôle documentaire n'existe ; `.github/` est interdit aux agents par le garde-fou | Non modifié |

## 6. Ce que ce lot ne fait pas

Aucune migration, aucune modification backend, aucun code de l'application, aucun déploiement, aucune
retouche du logo, aucune nouvelle valeur de jeton, aucun document supprimé, aucune décision prise à la
place du directeur.
