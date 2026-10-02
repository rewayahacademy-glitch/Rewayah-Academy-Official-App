# VERIF-AD-DOC (K-03) : Admin, documents

- Date : 03/10/2026. Session de vérification lancée par l'orchestrateur (lecture seule).
- Fiche : `yaaden-cache/lecture-0112/verif/etapes/VERIF-AD-DOC.json` (couvre AD-G0, AD-G1, AD-1, AD-2, AD-3, AD-3R, AD-BR).
- Lignes du tableau lues dans `yaaden-cache/tableau/etapes/*.json` (cache du 02/10 22:49).
- Bases lues : pilotage `pilotage/tuteur-v1` @ `7ea7971` ; ressources `projet/ressources` @ `8e62d1b` ; code `ui/admin-v1` lu par `git show 73f12c8:` (base d'AD-1) et `git show a8dfcb34:` (base d'AD-BR) dans `D:\RA_TUTEUR\admin` ; charte et `lib/CLAUDE.md` lus dans `D:\RA_TUTEUR\corrections` @ `98e3f9d` et par `git show 73f12c8:`.
- Aucune commande Flutter, aucune modification de fichier suivi, aucun commit, aucune écriture au tableau.

## Verdicts

| Étape | Verdict | Résumé |
|---|---|---|
| AD-G0 | **défaut** | Copies intégrales conformes. Mais les résumés signalés par AD-G1 ne sont **pas** corrigés (note posée). |
| AD-G1 | vérifié | Rapport présent ; ses constats et ses citations se confirment. |
| AD-1 | vérifié (défaut mineur) | 3 citations et plus, toutes justes ; une inversion `:42` / `:49` ; la preuve annonce 318 lignes, le fichier en compte 349. |
| AD-2 | vérifié | 67 lignes : 25 conformes et 42 ajustées. Colonnes demandées présentes, GOV.UK exclu, 28 modifications. |
| AD-3 | vérifié | Les 6 écrans sont présents dans 4 fichiers, avec 3 images de coque et l'index ; images ouvertes. |
| AD-3R | vérifié (défaut connu non levé) | 3 citations et plus, toutes justes ; l'incohérence Q31 / Q40 reste dans le fichier. |
| AD-BR | vérifié | BR-AD-01 à 18 citent toutes §15, §16, §17 ou §28 ; les sections existent dans la spec ; les ports cités sont justes. |

## AD-G0 : règles gelées publiées

Contrôlé :
- Copie intégrale ressources : `ressources-git/memoire/DESIGN-GOV-2026-09-26.md` (283 lignes).
- Copie dans le code : `corrections/docs/current/DESIGN-GOV-2026-09-26.md` (283 lignes). `Compare-Object` ne trouve aucune différence. La copie est présente dans `73f12c8`, ancêtre de `98e3f9d`.
- Résumés, comparés aux lignes de spec citées par AD-G1 : `03_ADMIN_VALIDATION_DOSSIERS_V1_2.md:208` (échelle 4…64), `:255` (« sans justification »), `:370` (« uniquement parce que »), `:379` (exception du directeur).
  - `corrections/docs/current/03_DESIGN_SYSTEM_ET_UX.md:8-11` : sans §4.3, sans « sans justification », sans l'exception du directeur. `:10` donne toujours « échelle d'espacement 4 à 64 ».
  - `corrections/lib/CLAUDE.md:20-23` : même bloc (il était en `:18-21` à `73f12c8`), mêmes absences.
  - Grep `4\.3|sans justification|sauf demande explicite` : 0 résultat dans ces deux fichiers, dans le worktree `integration` et dans `ressources-git/LISEZ-MOI.md`.
  - `ressources-git/LISEZ-MOI.md:10` : « ne pas rouvrir une étape terminée », sans l'exception du directeur.
  - Consigne K-38 (`yaaden-cache/tableau/consignes/K-38.json`) : « pas de pleine largeur sur ordinateur », « Aucune marche arrière », « jusqu'à la fin du projet ». Elle n'a pas changé.

Verdict : **défaut**. La fiche demande que les résumés signalés par AD-G1 soient corrigés, sinon une note : ils ne le sont pas, d'où cette note. Les copies intégrales, elles, sont conformes. Nouvelle étape proposée : rétablir dans les résumés la limite du §4.3 et les deux nuances (charte 03, `lib/CLAUDE.md`, K-38, LISEZ-MOI), selon la proposition de `11_admin/AD-G1_CONTROLE.md:32`.

## AD-G1 : contrôle par une seconde session

- `pilotage-git/11_admin/AD-G1_CONTROLE.md` est présent (commit `db9238c` présent).
- Ses citations se vérifient :
  - spec `:24` (phrase garde-fou), `:208`, `:255`, `:370` et `:379` : texte conforme à ce que le rapport décrit ;
  - `73f12c8:lib/CLAUDE.md:18-21` et `73f12c8:docs/current/03_DESIGN_SYSTEM_ET_UX.md:8-11` : c'est bien le bloc résumé.
- Son constat (résumés non identiques, AD-G0 laissé « fait ») est confirmé ci-dessus.

Verdict : **vérifié**.

## AD-1 : relevé du code (`11_admin/01_RELEVE.md`)

Citations ouvertes (`git show 73f12c8:`, la base déclarée en `01_RELEVE.md:5`) :
1. `assets/i18n/fr.i18n.json:913-915` (`01_RELEVE.md:17`) donne « La pièce est lisible », « Le nom correspond à celui du compte », « La pièce n'est pas expirée ». **Juste.** De plus, `:912` vaut « Vérifications » (`01_RELEVE.md:74`), juste.
2. `supabase/migrations/0004_inscription_kyc_appairage.sql:202-213` (`01_RELEVE.md:22`) : `where k.deleted_at is null and k.gender = reader_gender;` en `:213`, inconditionnel. **Juste.** Autres citations du même fichier, justes aussi :
   - `:208` : `log_sensitive_access('kyc_read', … null::text …)` ;
   - `:523-527` : signature de `decider_dossier(p_document_id, p_approuve, p_motif) returns void` ;
   - `:550-556` : UPDATE par `id` seul.
3. `lib/core/router/routes.dart:366` (`01_RELEVE.md:14`) : `adminPersonnesDossiers = '/admin/personnes/dossiers'`. **Juste.**
4. `fr.i18n.json:236` (`01_RELEVE.md:30`) : « Vous recevrez une notification dès qu'il est validé. » **Juste.**
5. `lib/features/admin_dossiers/dossiers_page.dart:42` / `:49` (`01_RELEVE.md:18` et `:76`) : **mapping inversé**. La ligne 42 est `final Set<String> _verifie`, la ligne 49 est `static const List<String> _points`.
   - `01_RELEVE.md:18` cite « `_points` … `Set _verifie` » avec « `:42`, `:49` » : l'ordre des citations est inverse de celui du texte.
   - `01_RELEVE.md:76` cite « constante codée en dur » en `:42`, alors qu'elle est en `:49`.

   Le fait relevé est juste, seule la ligne est mal attribuée. `:57-62` (`_reinitialiser` vide `_verifie`) est juste.

Autre écart : la preuve du tableau dit « 318 lignes », mais `git show cba7724:11_admin/01_RELEVE.md` en compte **349**, comme le fichier actuel.

Verdict : **vérifié**, avec un défaut mineur de citation (ligne de défauts).

## AD-2 : revue UX 2026 (`11_admin/UX_REVIEW_03_ADMIN_DOSSIERS.md`)

- 240 lignes, commit `c6b8a77` présent (puis `479c90f`, l'accord du directeur).
- Colonnes, `:18` : Proposition, Source consultée, Date, Règle utile, Conclusion, Modification, Dérogation. La note demande règle, source, date, conclusion et modification : c'est couvert.
- Lignes de tableau datées 26/09/2026 : 67. « Conforme » : 25. « Ajust… » : 42. Ces chiffres correspondent à la preuve.
- Les 9 groupes (`:16` à `:118`) sont présents. Section « Modifications » à `:128` : 28 items numérotés. Section « Dérogations » à `:159`, « Référentiels » à `:175`.
- GOV.UK est exclu (`:7`). La limite du §4.3 est rappelée (`:8`).

Verdict : **vérifié**.

## AD-3 : maquettes (`11_admin/V/`)

Images ouvertes :
- `IMG-ADM-02A_desktop_sombre.png` : 02A et 02B en maître-détail, bureau sombre ;
- `IMG-ADM-02A-02B-02E_mobile.png` : 02A mobile clair, 02B mobile sombre, 02E mobile clair ;
- `IMG-ADM-02C_desktop_sombre.png` : visionneuse ;
- `IMG-ADM-02D_desktop_sombre.png` : refus.

Les 6 écrans du titre sont donc présents, dans 4 fichiers. La coque est présente (`coque/ADMIN-SHELL-01..03`, non ouvertes), ainsi que l'index `V/00_MAQUETTES.md:9-16`. Commit `8d5c81a` présent.

Les rectifications 1, 2 et 4 (`00_MAQUETTES.md:53-62`) correspondent bien aux images :
- dates coupées « 25 sept. / 2026 » ;
- « Dossier de Aïcha Benali » ;
- « Refuser le dossier » coupé au bord gauche sur 02B mobile.

Verdict : **vérifié**.

## AD-3R : relevé des maquettes (`V/00_MAQUETTES.md`, section depuis `:77`)

Citations ouvertes :
1. `00_MAQUETTES.md:91` cite `fr.i18n.json:1738` ; `73f12c8` donne `"motSymbole": "Rewayah"`. **Juste.** Les citations `:1723` (Accueil), `:1727` (Finance), `:1824` (Enseignant), `:1825` (Tuteur), `:1478` (roleEnseignant) et `:421` (Carte d'identité) sont justes aussi.
2. `00_MAQUETTES.md:114` cite `dossiers_page.dart:453-455`, qui contient `_jour` au format `dd/MM/yyyy` sans heure. **Juste.**
3. Citations de la spec, toutes justes :
   - `:1030` : focus de retour sur `Voir la pièce` (rectif. 5, `:65`) ;
   - `:1056` : « Indiquez le motif du refus. » (`:70`) ;
   - `:1106` : « Valider ce dossier ? » (`:71`) ;
   - `:1197` : aide de la politique de genre ;
   - `:1929` : format `dd/MM/yyyy à HH:mm (zone IANA)` (`:83`).
- Les lignes 1 à 75 sont intactes. Le fichier comptait 432 lignes à `eb62751`, comme l'annonce la preuve, et 433 aujourd'hui (`68ecbad` a ajouté Q39-Q41 : 41 questions numérotées).
- L'incohérence déjà déclarée par la preuve est toujours là :
  - `00_MAQUETTES.md:423` (Q31) : « Défaut : aucune surface créée avant BR-1 » ;
  - `00_MAQUETTES.md:432` (Q40) : « AD-9 se livre en démonstration (K-35) ».

Verdict : **vérifié**. L'incohérence Q31 / Q40, connue, reste ouverte (ligne de défauts).

## AD-BR : besoins serveur (`11_admin/AD-BR.md`, section `:109`)

- `AD-BR.md:117-134` : 18 lignes, de BR-AD-01 à BR-AD-18. La dernière colonne de chaque ligne cite §15, §16, §17 ou §28 :

  | Ligne | Sections citées |
  |---|---|
  | BR-AD-01 | §17.1, §17.6, §16.2 |
  | BR-AD-02 | §17.2 |
  | BR-AD-03 | §17.3, §17.6, §16.2, §16.3, §28.3 |
  | BR-AD-04 | §28.4 |
  | BR-AD-05 | §28.5 à 28.9 |
  | BR-AD-09 | §17.5, §15.1 |
  | BR-AD-11 | §28.11 |
  | BR-AD-13 | §16.2, §28.10 |
  | BR-AD-16 | §16.1, §16.2 |
  | BR-AD-17 | §16.5 |
  | BR-AD-18 | §15.4, §28.11, §28.16 |

  Les lignes non détaillées dans ce tableau citent aussi §15 à §17.
- Ces sections existent dans la spec `03_ADMIN_VALIDATION_DOSSIERS_V1_2.md` : §15 en `:1178` (15.1 à 15.4), §16 en `:1238` (16.1 à 16.5), §17 en `:1293` (17.1 à 17.6), §28 en `:2142` (16 points, `:2146-2161`). Les points de §28 cités correspondent :
  - 3 : pièce lue sur autorisation serveur ;
  - 4 : trois vérifications ;
  - 10 : aucun accès hors capacité ;
  - 11 : politique de genre ;
  - 16 : tests.
- Les ports cités en `AD-BR.md:113` et dans les lignes ont été lus par `git show a8dfcb34:`. Toutes les citations sont justes :
  - PPK : `:34` (`lire()`), `:58`, `:65`, `:74` ;
  - PRD : `:403` ;
  - DEMO : `:650` (`PolitiqueRevueKycDemo`) ;
  - `decision_dossier.dart:241` ;
  - `file_dossiers.dart:33` (`ref.invalidate(dossiersEnAttenteProvider)`) ;
  - `etat_file_dossiers.dart:128` ;
  - `service_validation.dart:258`.
- 11 points ouverts (`:136-148`). Commit `c76b3f25` présent.

Verdict : **vérifié**.

## Non vu

- Captures de la coque `V/coque/*.png` et des explorations : non ouvertes.
- Journaux des runs d'agents cités dans les preuves : non ouverts.
- Comptage exact des 128 lignes de tableau d'AD-3R : non refait au caractère près.
