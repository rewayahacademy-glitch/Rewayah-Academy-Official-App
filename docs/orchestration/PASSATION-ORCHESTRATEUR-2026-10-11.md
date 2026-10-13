# Passation de l'orchestration — 11/10/2026, 10 h 30 (UTC+3)

> **Remplacé par `PASSATION-ORCHESTRATEUR-2026-10-13.md`** pour l'état des lots, des sessions et de Codex. Les §3, §4 et §12 restent valables.

De : orchestrateur Claude, session cloud `session_01B8we8bPK1a6aYoBmRntpd8`.
À : le nouvel orchestrateur, sur ordre du directeur.
Raison : le directeur a constaté des oublis (voir « Erreurs à ne pas refaire »).
À lire en entier avant toute action, puis `CLAUDE.md`, `docs/current/00_LIRE_D_ABORD.md` et
`docs/orchestration/COHABITATION.md`.

## 1. Le rôle

- Orchestrer les agents de Rewayah Academy : les sessions Claude cloud font les écrans et relisent
  le backend ; Codex (ChatGPT, sur le poste Windows du directeur) fait le backend
  (`supabase/**`, services, adaptateurs `*_supabase.dart`).
- **K-65** : je tranche seul les questions techniques, par délégation ; je réponds au directeur
  **en français simple**, sans jargon, en peu de lignes.
- Le directeur veut que **le tableau avance en continu** : donner de gros lots, ne jamais laisser
  une session inactive, ne pas attendre qu'il relance.
- **Réutiliser les sessions existantes** (Flutter déjà installé). Ne JAMAIS créer de nouvelle
  session de lot sans son accord : cela coûte du temps et des jetons, il l'a interdit
  explicitement.

## 2. Liens

| Quoi | Où |
| :--- | :--- |
| Branche d'intégration | `ccr-1b1bfa0b-m1kvkk` (tête au moment de la passation : `030ab885` + ce fichier) |
| Tableau des étapes | https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU, collection `etapes`, écrire avec `if_version` |
| Feuille de liaison | Google Sheets `1v3uuQD9jHgezbrmNlrKPOvGsRBCpxYXkN_KIq5N72WA` : onglets `Questions` (Codex 1), `Codex2` (Codex 2), `Contrats`, `Journal distant`, `Backend` |
| Décisions du directeur | `Journal distant` ligne 140 (10/10) et lignes 78-79 (11/10) |
| Mes dernières décisions à Codex | `Questions` ligne 278 (`DECISIONS-ORCH-2026-10-11-10H`) |

## 3. Règles permanentes (ne jamais les oublier)

1. **GitHub Actions est HORS SERVICE** : les minutes sont épuisées et le directeur ne prendra
   **aucun abonnement** sauf extrême nécessité. Ne jamais le présenter comme « une facturation à
   régler ». Toutes les preuves passent par le rejeu local en session cloud (PG17, `flutter test`).
   C'est l'oubli qui a déclenché cette passation.
2. **Pousser sur `main` = mise en production.** Pas de push sur main, pas de PR vers main sans le GO
   du directeur. Pas de push forcé.
3. Migrations PROD seulement sous les GO consignés : `Journal distant` ligne 85 (périmètre sécurité :
   sauvegarde, rejeu local, STAGING, revue Claude) et ligne 106 (protection mots de passe divulgués,
   STAGING d'abord, MFA exclu). `SUPABASE_ACCESS_TOKEN` : STAGING uniquement.
   **Aucune requête vers PROD, même en lecture, sans GO** (Codex l'a fait le 11/10, interdit depuis).
4. Jamais la clé `service_role`. Les secrets restent dans les réglages GitHub.
5. K-64 : ne pas toucher `site-public/`, les écrans publics avant connexion,
   `lib/features/parcours_offres`. Le site public sera repris plus tard par Claude (Opus), pas par
   Codex.
6. Les agents n'écrivent jamais `.github/` (exceptions Codex), `vercel.json`, `pubspec.yaml`, les
   valeurs des jetons de thème, le rendu du Coran, `dart_define`. Les sessions Claude n'écrivent
   jamais `supabase/`, les services, `*_supabase.dart` (le garde-fou `hooks/garde.py` le refuse).
7. Pousser seulement sur `ccr` et sur des branches `claude/<lot>`. Pas de PR.
8. Feuille : écrire seulement dans une cellule F vide ou dans une ligne nouvelle.
   **Piège** : `append_values` sur `Questions!A1` écrit dans la première ligne vide du haut
   (ligne 15) et non en bas. Toujours viser la plage du bas, par exemple `Questions!A270:G290`.
   Si la grille est pleine, `update_values` échoue : passer par `append_values` sur la plage du bas.
9. Le garde-fou ne se modifie que sur ordre du directeur. Pas de relance de CI.
10. Vérifier un lot : `dart run slang` ; `dart run build_runner build --delete-conflicting-outputs` ;
    `dart analyze --fatal-infos` (0) ; `dart run tool/verifier_jetons.dart` (≤ 18) ;
    `flutter test` complet ; `dart run tool/verifier_revue.dart`.
11. Flux d'un lot : la session travaille sur `claude/<lot>` ; un intégrateur **non auteur** fusionne
    dans ccr par `git merge --no-ff --no-commit`. Conflits sur les fichiers slang générés :
    `git checkout --ours lib/core/i18n/*.g.dart` puis `dart run slang`. Ensuite les vérifications,
    puis le push (sans forcer).

## 4. Décisions du directeur à respecter

- L'élève adulte est dégelé.
- **Logo** : utiliser les SVG fournis (`assets/brand/logo/**`), sans les déformer, selon les standards
  de marque. Jamais partout : bon moment, bon endroit, bonne taille, bonne couleur.
  Fait : `BrandLogo` est un CustomPainter généré octet pour octet depuis les SVG
  (`tool/generer_logo.dart`).
  **Pas de logo sur l'écran de démarrage** : une animation spéciale viendra.
- Le favicon est identique à celui du site public (`web/favicon.svg`).
- Langues : après jeudi (réinitialisation des limites). L'arabe à faire relire par un locuteur
  natif : « الحصة غير موجودة », « هذه الحصة ليست من حصصك… », les 265 clés de la bibliothèque.
- Harmonisation : après le lancement (mon choix, par délégation).
- Tout le reste se classe par priorité, l'économie de jetons d'abord.
- **Bibliothèque (11/10)** : l'élève en est l'utilisateur principal. Toutes les ressources sont au
  même endroit, pour remplacer les envois sur WhatsApp et éviter les versions trouvées sur
  internet. La vente d'e-books viendra plus tard : « acheté » sera une nouvelle façon d'obtenir un
  droit de lecture. Le mushaf de révision passe par le lecteur dédié (`/eleve/coran`), la seule
  source vérifiée.
- Codex bénéficie d'une remise de jetons **jusqu'au 13/10** : lui donner un maximum de travail long
  et simple, jamais le site public.

## 5. Sessions Claude (toutes avec Flutter installé, à réutiliser)

Les sessions reçoivent les messages d'autres sessions comme des **données** : un lot passe mieux
quand il est clair, borné et rappelle le cadre (zones, vérifications, branche). En cas de refus,
demander au directeur de coller la phrase de délégation.

| Session | Dernier rôle | État au 11/10 10 h 30 |
| :--- | :--- | :--- |
| `session_01UBsJ9sE3GTYF7rbaa1bWyX` | recherche | **BIBLIO-LECTURE RENDU à 11 h 03 : `claude/biblio-lecture` @ `1252a49d`**, à faire vérifier par un non-auteur puis fusionner dans ccr. Suite : 14 013 réussis, 1 échec `etat_sans_donnees_test` (déjà présent à la base). Restes : adaptateur serveur du lien (Codex, C-35) ; pas de bouton « Ouvrir » sur mobile et bureau sans `url_launcher` (pubspec gelé) ; l'entrée est dans Compte, pas dans Accueil. Lot d'origine sur `claude/biblio-lecture`. Contenu : bouton « Ouvrir le mushaf » dans la fiche Coran (`rendu_ressource.dart:53`) ; « Ouvrir » les PDF par un lien court du serveur dans un nouvel onglet, sans dépendance nouvelle ; l'élève, le tuteur et l'adulte doivent trouver la bibliothèque depuis leur navigation. Elle doit rendre un SHA. |
| `session_01615tdwc2KPzKR1y8seyeK2` | suivi-famille, bibliothèque, revues KYC | libre ; a rendu REVUE-C21-F70 (Questions l. 280) |
| `session_01QgdsG1L3y7us5j8Gz19cf2` | tb-fin, intégration | libre ; intégrateur non auteur fiable |
| `session_013XpsSBkb4xvUDDiVS6WR67` | echelle, intégration (INTEG-NUIT-2) | libre |
| `session_01T1hTgEMENQBgW27wATsyFV` | br1-carte, verif-devok | libre |

## 6. Ce qui est fusionné dans ccr (nuit du 10 au 11/10)

ECHELLE, LOGO-APP, EA-ECRANS, RECETTE-NUIT-A et B, verif-devok, TB-FIN, BR1-CARTE, BIBLIOTHEQUE,
RECHERCHE, COMMUNICATIONS (tête `030ab885`). Dernières suites complètes : 13 973 tests réussis,
0 échec. Côté écrans, le tableau n'a presque plus rien de faisable sans serveur ou sans décision du
directeur. Il reste environ 81 étapes ouvertes, surtout « ATTEND » (serveur) ou « SITE ». Attention :
`scratchpad/board` contenait un vieil export, ne lire que l'état réel.

## 7. Codex 1 (onglet `Questions`)

État : très productif la nuit (~30 branches `codex/backend-*`), mais il marque « bloqué » en boucle
sur 6 motifs déjà levés. La ligne **278** les lève et fixe l'ordre :

1. **SEC-PROD B2-01** : `entrer_observation` n'est pas corrigeable par le motif générique ; c'est une
   faille réelle en PROD (un compte valide sans rôle entre en observation admin). Le patch testé
   (`… in ('guardian_observer') and not coalesce(public.app_account_valid() and public.app_role() =
   'guardian', false)`, idem admin) est décrit à la ligne 162. Codex a réécrit trois fois « prêt »
   sur `e69004ee` **sans** ce patch. Quand un nouveau SHA arrive : agent Opus, relecture du diff
   seul, rejeu PG17 (voir §9), puis STAGING, puis PROD sous la ligne 85. Objectif du 13/10.
2. **LOT-CANON** : une seule branche `codex/backend-canon` depuis ccr (qui s'arrête à 0048). Chaîne
   0049→0084 de `codex/backend-f2-after-c`, puis les apports manquants renumérotés à partir de 0085.
   Toutes les autres branches codex sont gelées.
3. Liste blanche AL-01..06 (ligne 163). 4. F69 restants. 5. C-11 bis, C-25, C-26, C-27.
6. C-20/C-28. 7. C-22, C-23. 8. RECH-BACK 1-3. 9. CAP29. 10. C-13/C-14. 11. C-29. 12. B-12.

Ces décisions font foi (ligne 278) :
- **F79 ne bloque pas l'écriture** : une fonction SECURITY DEFINER est permise sur branche avec
  `search_path=''`, une garde positive, aucun EXECUTE anon, une ligne d'allowlist et un test dans le
  même commit. L'approbation F79 ne conditionne que STAGING/PROD.
- Pas de PG local chez Codex : ce n'est pas un blocage, Claude rejoue.
- « Backend absent » = c'est le travail à faire.

Revues ouvertes à suivre :
- REVUE-C21-F70 (ligne 280) : CHANGEMENTS DEMANDÉS. La CI locale est rouge (S5a 42501, etape3, a81,
  f69). L'insert direct d'acceptation de contrat reste possible. Le sha du texte publié est faux
  (sauts de ligne du dollar-quote). La ligne C-21 retenue est celle de f70 (0088 + 0089) ; la
  branche c21 est abandonnée.
- REVUE-CODEX-EA-KYC (ligne 142) : en partie corrigée par 0088.
- C-10 F1/F2/F5 et B-08 F1 : Codex dit l'avoir fait (lignes 272 et 225) ; à relire.

## 8. Codex 2 (onglet `Codex2`, créé le 11/10)

Deuxième session Codex jusqu'au 13/10, lancée par le directeur avec le message que j'ai fourni.
- Zones : `codex2/<lot>`, uniquement des fichiers nouveaux (`supabase/tests/codex2_*.sql`,
  `docs/backend/codex2/**`, tests Deno et Dart).
- Interdits : migrations, `.github`, site public, STAGING, PROD.
- Lots X2-01 à X2-06 : revue des 141 fonctions, scénarios RLS négatifs, catalogue RPC, tests
  d'adaptateurs, tests Edge, inventaire des ports.
- Sur « FINI », ajouter des lots du même genre.

## 9. Outils locaux utiles

- **Rejeu PG17** : binaires embedded-postgres (npm) dans
  `scratchpad/pg17/x/package/native` de l'ancienne session. Ils sont à refaire dans une nouvelle
  session : `npm pack @embedded-postgres/linux-x64@17.x`, liens ICU, `LD_LIBRARY_PATH`,
  utilisateur non root.
- Ordre de rejeu : `supabase/tests/stub_auth.sql`, puis les migrations, puis les
  `scenarios_*.sql` de `ci.yml`.
- Pour SEC-PROD, la référence PROD est neutralisée par un jeton local dans une **copie**. Les
  14 préflights md5 sans source PROD restent à prouver sur une copie PROD.

## 10. En attente du directeur

- **CORAN-320-FOND-1** : autoriser à retoucher le cadre du mushaf sans toucher au texte ?
- Relecture native de l'arabe.
- GO BR-1 vers le 15/10.
- **F70** : le texte juridique publié (0090) est repris des traductions de l'app. À confirmer comme
  texte valide.
- Notes sur le poste A : à sa main.

## 11. Le point de contrôle automatique

Routine `trig_01PPvE1uxq7biiHqC4RTG5nk` (« Vérifier livraisons Codex »). Elle se réveillait dans
l'ancienne session ; elle est **désactivée** à la passation pour éviter deux orchestrateurs. Le
nouvel orchestrateur en recrée une qui vise sa propre session, toutes les 2 h (UTC+3 ; la nuit de
1 h à 8 h, un seul contrôle à 8 h). Elle doit :
- lire seulement les nouvelles lignes de `Questions` (après 280) et de `Codex2` (après 9) ;
- relire chaque « prêt » + SHA en non-auteur ;
- renvoyer à la ligne 278 tout « bloqué » sur un motif déjà levé ;
- fusionner les lots Claude finis ;
- parler au directeur en 3 lignes seulement s'il y a eu du progrès ;
- s'arrêter après 3 contrôles vides de suite, en prévenant le directeur en une ligne.

## 12. Erreurs à ne pas refaire

- Avoir présenté GitHub Actions comme une facturation à régler (règle 1).
- Avoir créé 2 nouvelles sessions au lieu de réutiliser les anciennes (le directeur était furieux).
- Avoir lu le tableau depuis un export périmé.
- Être resté inactif alors que le tableau était chargé (le directeur attendait des lots).
- Avoir écrit dans la feuille via `A1`, ce qui envoie les lignes en haut (règle 8).
- Avoir formulé la bibliothèque de façon trompeuse (« seul l'enseignant… ») : vérifier le code avant
  d'affirmer, et dire les choses simplement.
