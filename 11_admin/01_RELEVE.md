# AD-1 : relevé du code existant pour ADM-02

- Date : 26/09/2026.
- Session : A-2026-09-26-service.
- Base : `ui/admin-v1` @ `73f12c8` (worktree `D:\RA_TUTEUR\admin`, lecture seule).
- Méthode : 6 relevés (A route-coque, B vérifications et décision, C genre et Super Admin, D pièce et sécurité, E portail /attente, F composants), chacun contre-vérifié citation par citation. Seuls les relevés contre-vérifiés font foi.
- Convention : chemins relatifs au worktree. « Déduit, non mesuré » = conclusion tirée du code, sans exécution.
- Réserve spec : docs/current ne contient que DESIGN-GOV §0, §1, §4, §4 bis (`docs/current/DESIGN-GOV-2026-09-26.md:3`). La spec V1.2 est hors dépôt (`D:\RA_TUTEUR\ressources-git\specs\03_admin_validation_dossiers\03_ADMIN_VALIDATION_DOSSIERS_V1_2.md`, lue par le sujet B seulement). Les renvois aux autres sections de la spec ne sont pas vérifiables dans le dépôt.

## 1. Checklist §24 de la spec

| Point | Réponse courte | Preuve |
|---|---|---|
| Route réelle | `/admin/personnes/dossiers`, dans `_CoquilleAdmin(domaine: personnes, child: DossiersPage())`. | `lib/core/router/routes.dart:366` ; `lib/core/router/app_router.dart:839-843` |
| Bouton Personnes | Aucun bouton dédié. Seule entrée : l'élément « Personnes » de la barre latérale, `/admin/personnes`, qui redirige vers ADM-02. | `lib/core/admin/admin_domaine.dart:95` ; `lib/core/router/app_router.dart:834-837` |
| Bouton compteur Accueil | StatTile « Dossiers à valider » : `go(Routes.adminPersonnesDossiers)`. | `lib/features/admin_tableau/tableau_de_bord_page.dart:259-262` ; `assets/i18n/fr.i18n.json:928` |
| Trois libellés exacts | « La pièce est lisible », « Le nom correspond à celui du compte », « La pièce n'est pas expirée ». | `assets/i18n/fr.i18n.json:913-915` |
| Source | Constante client `_points = ['lisible','nom','validite']`, état local `Set _verifie`. Rien côté serveur. | `lib/features/admin_dossiers/dossiers_page.dart:49` (`_points`), `:42` (`Set _verifie`) |
| can_validate | Introuvable sous ce nom. Équivalent client : `jugeable` puis `tousVerifies`. Côté serveur : rôle, motif, visibilité de la pièce. | `lib/core/dossier/service_validation.dart:151-152` ; `dossiers_page.dart:142` ; `supabase/migrations/0004_inscription_kyc_appairage.sql:533-548` |
| Mécanisme de décision | RPC `decider_dossier(p_document_id, p_approuve, p_motif)`, returns void, security definer. | `0004:523-574` ; `service_validation.dart:230-237` |
| Atomicité | Oui : une seule fonction plpgsql (document, profil, teacher_profiles, audit). Activation silencieuse si le compte n'est pas `pending_kyc`. | `0004:550-570` |
| Règle de genre activée | Oui, inconditionnelle, codée en dur dans `read_kyc_documents()`. | `0004:202-213` |
| Politique Super Admin | Introuvable. Aucun rôle ni réglage Super Admin. | grep `kyc_review_policy|super_?admin` : 0 fichier |
| Stockage de la pièce | Seau Supabase privé `kyc`. R2 préparé (0034), non branché. | `0004:997-998` ; `lib/core/dossier/service_dossier.dart:142` ; `supabase/migrations/0034_r2_stockage.sql:104` |
| Lecture sécurisée | Non utilisée. Le client signe l'URL (`createSignedUrl`, 60 s). La porte serveur `autoriser_lecture_piece_identite` et l'Edge `piece-identite-acces` existent sans appel dans lib/. | `service_validation.dart:221-223` ; `0034:141` ; `supabase/functions/piece-identite-acces/index.ts:84` |
| RLS | `kyc_admin_all` FOR ALL admin, sans genre. Storage `kyc_lecture_admin` : admin et controller, sans genre. | `supabase/migrations/0001_fondations.sql:735-736` ; `0004:1014-1016` |
| Audit | `kyc_decision` à la décision. `kyc_read` par lecture de liste, row_id nul. Aucune trace par pièce ouverte depuis ADM-02. | `0004:568-569` ; `0004:208` |
| Concurrence | Aucune garde : UPDATE par id seul, ni statut, ni révision, ni verrou, ni idempotence. | `0004:550-556` |
| Portail après refus | « Votre dossier n'a pas été validé. », motif brut, bouton « Reprendre mon dossier » vers `/attente/piece`. | `lib/features/dossier/attente_page.dart:121-124`, `:205-221` |
| Absence de notification | Aucune notification. Mais le portail promet « Vous recevrez une notification ». | `lib/core/capacites/port_notifications.dart:42-66` ; `fr.i18n.json:236` |
| Photo publique vs pièce KYC | Seaux distincts, tous `public = false` : `photos_enseignants` (clé `teacher_profiles.photo_storage_key`, commentaire « Distincte des pièces KYC »), `kyc`, `avatars`. Photo lisible par l'enseignant, l'admin et les membres de ses groupes ; pièce KYC par admin et controller seulement. | `supabase/migrations/0030_tc_socle.sql:181`, `:185-189`, `:207-208` ; `supabase/migrations/0032_tc_catalogue.sql:642-652` ; `0004:997-998`, `:1013-1017` |
| Composants réutilisables | Voir §7. | §7 |
| Skeleton | `Skeleton.liste(lignes: 4)`. Aucune forme ligne de file ni carte de détail. | `dossiers_page.dart:149` ; `lib/core/widgets/skeleton.dart:27-71` |
| Tests politique genre actif / désactivé | Non préparés : aucune politique à basculer. Seuls existent des tests du filtre inconditionnel (S4a, S4d, S5). | `supabase/tests/scenarios_etape3.sql:124`, `:146`, `:190` |
| Conformité 2026 dans `UX_REVIEW_03_ADMIN_DOSSIERS.md` | Fichier introuvable sous `D:\RA_TUTEUR` (glob `**/UX_REVIEW_03*` : 0). Hors code. | glob : 0 |
| DESIGN-GOV dans la mémoire canonique et le document UX actif | Présent dans `docs/current` : texte intégral, et renvoi en tête du document UX actif. | `docs/current/DESIGN-GOV-2026-09-26.md:3` ; `docs/current/03_DESIGN_SYSTEM_ET_UX.md:4-6` |
| Décision déposée dans Suivi Rewayah ; aucun lot terminé rouvert | Hors code, non vérifiable depuis le worktree. À confirmer par l'orchestrateur. | - |

## 2. Route, coque et entrées

- Route ADM-02 : `/admin/personnes/dossiers` (`routes.dart:366`).
- `/admin/personnes` n'est qu'une redirection vers ADM-02 (`app_router.dart:834-837`).
- L'ancienne route `/admin/dossiers` redirige aussi vers ADM-02 (`app_router.dart:969-972`).
- Aucune page d'index Personnes. Aucune sous-navigation Personnes : seuls `ongletsPedagogie`, `ongletsConfiguration`, `ongletsSecurite` existent (`admin_domaine.dart:152`, `:169`, `:190`).
- ADM-08 Comptes : `/admin/personnes/comptes`, atteint seulement depuis l'Accueil (`tableau_de_bord_page.dart:221-225`).
- Entrée 1 vers ADM-02 : élément « Personnes » de la barre latérale (`admin_domaine.dart:95`).
- Entrée 2 : StatTile « Dossiers à valider » de l'Accueil (`tableau_de_bord_page.dart:259-262`).
- Entrée 3 : lignes « Dossier d'identité de {prenom} » de « À traiter en premier » (`tableau_de_bord_page.dart:65-69`, `:186`). Sans identifiant : la page ouvre toujours le premier de la file (`dossiers_page.dart:122`).
- Coque : `AdminShell` (`lib/core/widgets/admin_shell.dart:43`), 8 domaines au plus (`:82`).
- Gabarits : tiroir sous 600, rail 80 de 600 à 1199, barre latérale 288 dès 1200 (`app_gabarit.dart:28-34` ; `admin_shell.dart:100`). Jamais de barre basse.
- Barre latérale, dans l'ordre (`admin_domaine.dart:118-127` ; `fr.i18n.json:1723-1730`) :
  1. Accueil, `/admin`.
  2. Opérations, `/admin/operations` (redirige vers groupes).
  3. Personnes, `/admin/personnes` (redirige vers dossiers).
  4. Pédagogie, `/admin/pedagogie` (redirige vers diagnostics).
  5. Finance, chemin null : visible, inerte, atténuée en inkFaint (`admin_domaine.dart:99` ; `admin_shell.dart:191-213`).
  6. Configuration, `/admin/configuration` (redirige vers règles).
  7. Sécurité et audit, `/admin/securite-audit` (redirige vers journal).
  8. Direction, seulement si `voitDirection`, fixé à false (`session_state.dart:140`).
- Écart avec les 7 entrées de la maquette : aucun sur l'ordre ni les libellés. Direction est une 8e entrée masquée. Finance doit apparaître inerte sur la maquette.
- En-tête : recherche de navigation, cloche (feuille « Aucune notification »), bouton compte, plus « Menu » sur mobile (`admin_shell.dart:459-528`, `:492`).
- Absents de l'en-tête et de la barre : titre, sous-titre, bouton thème, pied utilisateur (`admin_shell.dart:216-385`, `:412-535`).
- Titre de page porté par `PageShell(titre: t.dossiers.titre)`, sans `EntetePage` ni `DisqueRetour` (`dossiers_page.dart:107-108`).
- Garde client : `deciderRedirection`, préfixe `/admin`. Commentaire : « ceci n'est pas une barrière de sécurité » (`redirection.dart:14-15`, `:196-200`). Aucune garde par capacité ou domaine.
- Page actuelle : un seul dossier à la fois, `file.requireValue.first`. Ni liste, ni filtre, ni pagination (`dossiers_page.dart:121-123`).

## 3. Les trois vérifications

- La condition d'arrêt de la spec §3 ne s'applique pas : les trois vérifications existent dans le code courant.
- Libellés exacts, dans l'ordre (`dossiers_page.dart:49`, `:188-192`) :
  - `lisible` : « La pièce est lisible », clé `dossiers.pointLisible` (`fr.i18n.json:913`).
  - `nom` : « Le nom correspond à celui du compte », clé `dossiers.pointNom` (`fr.i18n.json:914`).
  - `validite` : « La pièce n'est pas expirée », clé `dossiers.pointValidite` (`fr.i18n.json:915`).
- Nœud i18n racine `dossiers` (`fr.i18n.json:895`), pas `admin.dossiers`. Titre de section : « Vérifications » (`fr.i18n.json:912`).
- Code inconnu : retombe sur `pointValidite` (`dossiers_page.dart:188-192`).
- Source : constante codée en dur, état coché en `Set<String>` local, vidé après décision (`dossiers_page.dart:49` pour la constante, `:42` pour le `Set`, `:57-62` pour la remise à zéro).
- Nature : cases manuelles `_Case` (Pressable, icône). Rien de calculé (`dossiers_page.dart:389-429`).
- Obligatoire : pour Valider seulement, côté client. `onPress: tousVerifies ? onApprouver : null` (`dossiers_page.dart:142`, `:311-321`). Refuser reste toujours actif.
- Test widget : Valider avant les trois coches ne produit aucun verdict (`test/features/dossiers_admin_test.dart:139-163`).
- **Effet serveur : aucun.** `decider()` n'envoie que `p_document_id`, `p_approuve`, `p_motif` (`service_validation.dart:225-237` ; `0004:523-527`).
- Persistance serveur : introuvable (`review_checks`, `kyc_checks`, `save_review`, `can_validate`, `expected_revision` : 0 résultat hors .md).

## 4. Genre et politique Super Admin

- Champ lu : `profiles.gender`, enum `male`/`female` (`0001:40`), colonne nullable ajoutée par `0004:26-31`.
- Raison historique (spec §3) : le cloisonnement vient des « scénarios 11 et 12 » de 0001 (« un personnel masculin ne lit aucun dossier féminin ») ; le genre du lecteur était lu sur SON propre dossier KYC, avec repli silencieux sur la branche masculine (`0001:744-775`). 0004 l'a déplacé sur le profil et fait d'un genre absent un refus (invariant I9), seul usage déclaré : « cloisonnement de lecture des dossiers KYC (audit 1.3) » (`0004:22-31`, `:195-196`). Le document « audit 1.3 » n'a pas été lu.
- Lu seulement côté serveur, par `read_kyc_documents()` via `auth.uid()` (`0004:191-193`). Le client ne lit jamais le genre de l'admin (`source_session.dart:82-85`).
- Genre d'une pièce : écrasé par celui du titulaire au BEFORE INSERT ; dépôt refusé si inconnu (`0004:145-146`).
- Genre du lecteur nul : exception « genre du lecteur inconnu » (`0004:202-204`).
- Ce blocage ne se produit que s'il existe au moins une pièce `pending`. Sinon la file est rendue sans `read_kyc_documents()`, sans contrôle de genre ni `kyc_read` (`0029_fermeture_dossiers_en_attente_anon.sql:105-121`).
- Client : exception convertie en `GenreLecteurInconnu` (`service_validation.dart:212-216`).
- Écran : EmptyState « Renseignez votre genre dans votre profil avant de consulter un dossier. », sans action ni lien (`dossiers_page.dart:443-449` ; `fr.i18n.json:922`).
- Impasse : `/compte/profil` n'a aucun champ genre (`lib/features/compte/compte_page.dart:120-191`).
- Filtre : `k.gender = reader_gender`, inconditionnel (`0004:213`). Partagé par la file, la décision et la lecture de pièce (`0029:125` ; `0004:545` ; `0034:170-172`).
- Pièce d'un autre genre : `etat_piece = 'non_visible'`, profil listé sans document ni clé ; pastille « Pièce hors de votre portée » (`0029:124-145` ; `dossiers_page.dart:251-256`).
- Politique Super Admin : introuvable (grep `super_?admin|superAdmin|genre_reviewer|kyc_review_policy|gender_enforced|reviewer_enforced|kyc_gender` : 0 fichier).
- Rôle : enum plat `app_role` lu dans le JWT, sans `super_admin` ni table de capabilities (`0001:26-27`, `:391-396`).
- Capacités client : `peutEcrire`, `peutVoirDirection => false` (`session_state.dart:128-140`).
- Seul mécanisme de réglage : `app_config` + `app_config_history`, modifiable par tout admin via RLS (`0001:326-340`, `:968-977`). Aucune clé liée au genre.
- Auto-modification du genre : possible côté serveur. `profiles_self_update` + grant UPDATE global ; `guard_profile_privileged_columns` ne couvre pas `gender` (`0001:713-715`, `:1201`, `:541-560`). Tout admin peut aussi modifier le genre d'un profil (`0001:704-705`).
- Aucun parcours ni RPC ne pose le genre d'un membre du personnel (`0004:370-372`).
- ADM-08 : `comptes_admin()` calcule l'état de pièce sans genre, jamais `non_visible` (`0015_administration_voit_les_personnes.sql:160-174`).
- Tests existants : S5a-S5c, S4d (`supabase/tests/scenarios_etape3.sql:142-253`) ; R4 (`supabase/tests/scenarios_r2.sql:271-304`).
- Commentaire obsolète : `0034:130-132` décrit encore la lecture du genre « sur SON propre dossier » (version 0001).

## 5. Pièce, stockage, sécurité, contrats §17 existants

### Dépôt
- Types : Carte d'identité, Passeport, Titre de séjour, plus « Autre » générique de `ChoiceCardGroup` (`depot_piece_page.dart:160-185` ; `choice_card_group.dart:208-210`).
- Texte « Précisez » perdu : seul `reponse.valeurs.first` est lu ; insertion de `profile_id`, `doc_type`, `object_key` seulement (`depot_piece_page.dart:176` ; `service_dossier.dart:151`).
- Contrainte SQL : `id_card`, `passport`, `residence_permit`, `other` (`0001:115`).
- Plafond 8 Mo : client seulement (`service_dossier.dart:76` ; `depot_piece_page.dart:55`). Seau `kyc` sans `file_size_limit` ni `allowed_mime_types` (`0004:997-998`).
- Formats : client jpg, jpeg, png, webp, heic, pdf (`selecteur_fichier.dart:27-33`). R2 : jpeg, png, heic, pdf, sans webp (`supabase/functions/_shared/r2/signature.ts:74`).
- Chemin : `<uid>/<epoch_ms>.<ext>` dans le seau `kyc` (`service_dossier.dart:139-142`).
- `purge_at` posé par trigger, `kyc_retention_days` 90 par défaut (`0004:117`, `:137`).

### Stockage R2 (préparé, non branché)
- Colonne `storage_backend` (`supabase` par défaut), coffre `rewayah-identity-vault`, clé `identity/<profile_id>/<document_id>` (`0034:104`, `:346` ; `domaines.ts:56`).
- Flux : `preparer_depot_piece_identite` (ligne invisible), PUT présigné 120 s, confirmation par l'Edge `piece-identite-confirme` (`0034:350`, `:381`, `:430`).
- Aucun appel depuis lib/ (grep `piece-identite|piece_identite` : 0).

### Lecture
- ADM-02 : `storage.from('kyc').createSignedUrl(cleObjet, 60)` côté client, `Image.network` en ligne (`service_validation.dart:200`, `:221-223` ; `dossiers_page.dart:374`).
- `object_key` renvoyé au client par la file (`0029:85`, `:131`).
- PDF : non affichable par `Image.network`, retombe sur « Aperçu indisponible ». Déduit, non mesuré.
- Porte serveur existante : `autoriser_lecture_piece_identite(p_document_id)`, rôle admin ou controller en exigence positive, `app_account_valid`, filtre de genre, audit `kyc_document_open` par pièce (`0034:141-200`).
- Edge `piece-identite-acces` : l'appelle et signe 60 s (`index.ts:84`). Non appelée par lib/.
- `0034:26-29` reconnaît que l'aperçu client contredit la génération serveur annoncée.

### RLS et gardes
- `kyc_admin_all` : FOR ALL admin, sans genre, malgré le commentaire « (filtre genre) » (`0001:733-736`). Grant général à authenticated (`0001:1201`).
- Conséquence : lecture et écriture directes de `kyc_documents` par PostgREST, hors genre et hors audit, y compris réécriture de `gender`. Déduit, non mesuré.
- Storage `kyc_lecture_admin` : SELECT sur tout le seau pour admin et controller, sans genre (`0004:1013-1017`).
- `decider_dossier` : garde négative `app_role() <> 'admin'` (`0004:533`). `NULL <> 'admin'` ne lève pas (`0029:29-38`). Contournement par un authenticated sans claim : déduit, non mesuré.
- `read_kyc_documents` : même forme négative `not in ('admin','controller')` (`0004:187`).
- `decider_dossier` n'appelle pas `app_account_valid()` (`0004:530-548`), contrairement à `0034:159`.
- Périmètre incohérent : file et décision admin seul (`0029:100` ; `0004:533`) ; lecture admin et controller (`0004:187` ; `0034:152`).

### Audit
- Table `audit_logs` chaînée SHA-256, append-only (`0001:594-625`, `:566-584`).
- `kyc_decision` : payload `{approuve, motif}` seulement (`0004:568-569`).
- `kyc_read` : row_id nul, par lecture de liste (`0004:208`).
- Aucun trigger d'audit sur `kyc_documents` (seul `kyc_documents_completer`, before insert, `0004:154-155`).
- Journal admin : traduit `kyc_read` et `kyc_decision` ; les autres types s'affichent en brut (`journal_page.dart:593-599`).
- Texte à l'écran « Chaque consultation de pièce est inscrite au journal d'audit, avec votre nom. » : vrai pour la liste, faux par pièce (`fr.i18n.json:921`).

### Contrats §17 : équivalents existants

| Contrat spec | Existant | Preuve |
|---|---|---|
| `list_reviewable_dossiers` | `dossiers_en_attente()` : sans argument, sans pagination ni filtre ni révision, tri par ancienneté, exigence positive admin. Une ligne par pièce pending, pas par personne. | `0029:73`, `:100`, `:142`, `:145` |
| `get_dossier_for_review` | Absent. Détail construit depuis la ligne de file. | `service_validation.dart:43` |
| `request_kyc_document_view` | Nom absent. Équivalent : `autoriser_lecture_piece_identite` + Edge `piece-identite-acces`, non branchés. | `0034:141` ; `index.ts:84` |
| `decide_dossier` | `decider_dossier(p_document_id, p_approuve, p_motif)` : décide sur un document, void, sans révision ni idempotence. | `0004:523-574` |
| `get/set_kyc_review_policy` | Absents. | grep : 0 |
| `save_review_checks`, `get_decision_result` | Absents. | grep : 0 |

## 6. Portail /attente, profil admin, notifications, mode démonstration

### Portail
- `AttentePage` sur `/attente`, avec `/attente/accuse`, `/attente/contrat`, `/attente/piece` (`routes.dart:58-70` ; `app_router.dart:236-251`).
- Partagé tuteur et enseignant ; seul le contrat attendu change (`redirection.dart:112-116` ; `0004:459-464`).
- Quatre états : suspendu, refusé, incomplet, en vérification, dans cet ordre de priorité (`etat_dossier.dart:80-91`).
- Calcul en Dart depuis des champs bruts de `etat_dossier()`, alors que les commentaires disent « calculé en base » (`etat_dossier.dart:7-9`, `:80-107` ; `0004:472-482`).
- Incomplet : « Il manque encore des pièces à votre dossier. », liste « À fournir », bouton « Lire » / « Lire et signer » / « Déposer ma pièce » (`attente_page.dart:116-194`).
- En vérification : « Votre dossier est en cours de vérification », « Nous vérifions votre dossier. Vous recevrez une notification dès qu'il est validé. », « La vérification prend en général moins de 48 heures. ». Aucune action pleine (`attente_page.dart:195-204` ; `fr.i18n.json:234-252`).
- Refusé : « Votre dossier n'a pas été validé. », motif brut en inkAlert, « Déposez une nouvelle pièce pour relancer la vérification. » (`attente_page.dart:205-221`).
- Correction : « Reprendre mon dossier », sans condition, toujours vers `/attente/piece` (`attente_page.dart:121-124` ; `fr.i18n.json:250`).
- Nouveau dépôt : nouvelle ligne `pending` ; le portail repasse en vérification (`0004:453-457`).
- Suspendu : « Votre compte est suspendu. », « Contacter l'académie » en simple texte, pas en bouton (`attente_page.dart:222-228`, `:267-270`).
- États techniques : `Skeleton.liste(lignes: 3)`, messages hors ligne ou illisible, « Réessayer » (`attente_page.dart:276-305`).
- Retour après validation : sortie vers `/tuteur` ou `/enseignant/journee` (`redirection.dart:118-145` ; `routes.dart:535-542`).
- ENS-01 `/enseignant/bienvenue` : aucune redirection n'y mène (`routes.dart:304` ; `app_router.dart:755`).
- Relecture : seulement au démarrage, sur `onAuthStateChange`, ou par « Réessayer » après erreur. Ni cycle de vie, ni sondage, ni Realtime (`source_session.dart:36-50` ; `attente_page.dart:54-58`).
- Aucune dispense de pièce par rôle (`etat_dossier.dart:102-107`).
- Un admin peut activer un compte par UPDATE direct de `profiles.account_status`, hors `decider_dossier` (`0001:704-705`, `:546-553`). Aucun écran ne le fait.
- `decider_dossier` active sans vérifier accusé ni contrat (`0004:558-562`).

### Profil admin
- `ProfilPersonnelPage` sur `/compte/profil`, dans `_CoquilleSecondaire` (`routes.dart:470` ; `app_router.dart:266-270`).
- Tout en lecture (`SettingRow enabled:false`) : rôle, statut, identifiant, contact et fuseau non disponibles, langue, habilitations (`compte_page.dart:120-191`, `:510-531`).
- Ni genre, ni nom, ni formulaire.

### Notifications
- Aucune : `decider_dossier` ne fait qu'UPDATE et audit (`0004:550-569`).
- Aucune Edge Function de courriel de décision ; pubspec sans firebase, onesignal ni push (grep `firebase|onesignal|push|notification` sur `pubspec.yaml` : 0).
- `PortNotifications` câblé sur `NotificationsIndisponibles` (`CapaciteIndisponible('DB-CPT-04')`) (`port_notifications.dart:42-66`).
- Cloche admin : feuille « Aucune notification » (`admin_shell.dart:459-471` ; `fr.i18n.json:1553`).

### Mode démonstration
- Playground : `Env.playgroundActif` (drapeau `PLAYGROUND`, faux par défaut) (`env.dart:33` ; `main.dart:76-99`).
- Persona Administrateur : deux dossiers (Amina Benali, Omar Haddad), `FauxServiceValidation` avec URL `https://exemple.test/{cle}` (`persona.dart:613-655` ; `faux.dart:323-356`).
- Fixtures aux noms réalistes, sans mention « Document fictif » (`persona.dart:632-655`).
- Persona « compte suspendu » : `etatDossier` par défaut `sansProfil`, afficherait probablement « incomplet ». Déduit, non mesuré (`persona.dart:51`, `:284-288`).
- Démo à l'exécution : tuteur seulement (`?demo=tuteur`), interdite en production (`mode_demonstration.dart:42-116`).
- `?demo=admin` : introuvable.

## 7. Composants réutilisables

| Composant | Fichier:ligne | Usage ADM-02 |
|---|---|---|
| AdminShell | `lib/core/widgets/admin_shell.dart:43` | Coque de navigation. Pas de panneau de détail (réservé en commentaire, `:171-175`). |
| PageShell | `lib/core/widgets/page_shell.dart:41-54` | Page, gouttières 16/24/32, `OfflineBanner` intégré, zone `actions` collée (`:262-298`). Déjà utilisé (`dossiers_page.dart:107`). |
| EntetePage | `lib/core/widgets/entete_page.dart:25-33` | Titre, sous-titre, retour, actions. |
| DisqueRetour | `lib/core/widgets/entete_page.dart:94-96` | Retour 48, libellé fixe « Retour ». |
| GroupeReglages / LigneRubrique | `lib/core/widgets/groupe_reglages.dart:13-26`, `:65-67` | Liste de lignes cle/valeur ou cases (slot `controle`). Pas d'état sélectionné. |
| ActionPrincipale | `lib/core/widgets/action_principale.dart:16-60` | Valider (principale), Refuser (secondaire, destructive). Hauteur 52. `pleineLargeur` vrai par défaut. |
| StatusPill | `lib/core/widgets/status_pill.dart:60` | États de pièce ; 5 tons. Déjà utilisé (`dossiers_page.dart:251-256`). |
| SectionHeader | `lib/core/widgets/section_header.dart:19-27` | En-tête de file avec compteur. |
| LigneCleValeur | `lib/core/widgets/ligne_cle_valeur.dart:19-27` | Métadonnées du dossier. |
| EtatSysteme | `lib/core/widgets/etat_systeme.dart:79-93` | États système, 12 natures. |
| EcranResultat | `lib/core/widgets/ecran_resultat.dart:31-45` | Résultat plein écran, largeur 400. |
| EmptyState | `lib/core/widgets/empty_state.dart:46-56` | File vide ; registre `bonneNouvelle` disponible mais non passé aujourd'hui (`dossiers_page.dart:116-120`). |
| BlocAsynchrone | `lib/core/widgets/bloc_asynchrone.dart:41-51` | Chargement 8 s / échec 20 s, 3 essais. Non utilisé par ADM-02. |
| Skeleton | `lib/core/widgets/skeleton.dart:27-71` | Chargement ; déjà `Skeleton.liste(lignes: 4)`. |
| OfflineBanner | `lib/core/widgets/offline_banner.dart:32-43` | Texte fixe « Pas de réseau. Tout reste consultable, l'envoi attendra. ». |
| LocalFeedback | `lib/core/widgets/local_feedback.dart:27-35` | Retour après décision, 3 s, liveRegion. |
| ConfirmDestructive | `lib/core/widgets/confirm_destructive.dart:27-40` | Confirmation de refus ; sans slot de champ. |
| AppBottomSheet | `lib/core/widgets/app_bottom_sheet.dart:45-51`, `:114-182` | Feuille ou dialogue borné à 560 ; Échap testé en forme feuille seulement. |
| AppCard | `lib/core/widgets/app_card.dart:28-42` | Carte sélectionnable visuellement, sans sémantique `selected`. |
| DataCollection | `lib/core/widgets/data_collection.dart:96-105` | Tableau sur bureau, cartes ailleurs, `onSelectionner` sans état sélectionné. |
| BentoTile | `dossiers_page.dart:216` | Déjà utilisé. |
| Outil de capture | `test/capture/outil_capture.dart:31-252` ; `test/capture/LISEZ-MOI.md:14-39` | Captures clair/sombre, `CAPTURE_DIR`. |

Composants réellement manquants :
- Visionneuse avec zoom : aucune (`InteractiveViewer`, `PhotoView` : 0). Un seul `showDialog`, dans AppBottomSheet (`app_bottom_sheet.dart:124`).
- Composant maître-détail : aucun (`MaitreDetail` : 0).
- Dialogue avec champ multiligne : aucun. Seul le TextField en ligne existe (`dossiers_page.dart:293-299`).
- Forme de dialogue plein écran ou large (800) : aucune ; AppBottomSheet borne à 560 (`app_bottom_sheet.dart:165-167`, `:270-272`).
- Libellé de retour personnalisable (« Fermer la pièce ») : non couvert par DisqueRetour.
- Skeleton ligne de file ou carte de détail : absent.
- Jetons `relatedAction` et `actionGroup` : absents de lib/ (`DESIGN-GOV-2026-09-26.md:136` seulement).
- Textes i18n absents : « Fermer la pièce », « Aucune décision ne peut être envoyée », « Actualisation des dossiers », « Dossier validé. », « Dossier refusé. », « Dossier suivant ».
- Helper `test/support/pressable_de.dart` : absent de HEAD ; créé par `7727511`, non ancêtre de HEAD (présent sur `ui/tuteur-v1-t` et `reserve/theme-monochrome-k36`).
- Test de retour de focus après fermeture d'AppBottomSheet : absent.

## 8. Divergences avec la spec §2 et avec les maquettes

1. Barre latérale : conforme aux 7 entrées ; Direction 8e masquée ; Finance visible mais inerte (`admin_domaine.dart:99`, `:118-127`).
2. En-tête maquette vs code : pas de titre, sous-titre, bouton thème ni pied utilisateur ; recherche et cloche vide en plus (`admin_shell.dart:216-535`).
3. Entrée Personnes : pas d'index ni d'onglets Dossiers / Comptes, seulement une redirection (`app_router.dart:834-837`).
4. Lignes « À traiter en premier » : n'ouvrent pas le dossier cliqué (`tableau_de_bord_page.dart:69` ; `dossiers_page.dart:122`).
5. Un seul dossier à la fois : pas de file maître-détail ni d'écrans ADM-02A à 02E (`dossiers_page.dart:121-123`).
6. ADM-02 sans EntetePage ni DisqueRetour (`dossiers_page.dart:107-108`).
7. §2 « trois vérifications existent » : confirmé, mais locales, sans effet ni trace serveur (`service_validation.dart:232-236`).
8. §3 « libellés exacts inconnus » : levé par le code (`fr.i18n.json:913-915`).
9. §2 « Valider le dossier et Refuser, avec motif » : confirmé (`fr.i18n.json:917-919` ; `0004:539-541`).
10. §2 « l'écran ne montre que les pièces déposées » : contredit, la file rend aussi des personnes sans pièce ou hors de portée (`0029:109-145`).
11. §2 « l'écran se bloque si le genre manque » : vrai seulement s'il existe une pièce `pending` (`0029:105-121`).
12. §15.3 « Profil à compléter » : EmptyState sans titre ni action ; le profil n'a pas de champ genre (`dossiers_page.dart:443-449` ; `compte_page.dart:120-191`).
13. §2 « profil en lecture seule » : vrai en UI, faux côté serveur pour `gender` (`0001:713-715`, `:1201`).
14. §3.6 et §15.3 « un reviewer ne modifie jamais son genre » : non tenu côté serveur (`0001:541-560`).
15. D-ADM-KYC-GENRE-01 et §17.5 : filtre de genre codé en dur, sans interrupteur (`0004:202-213`).
16. §16.2 : `kyc_admin_all` et le grant général ouvrent `kyc_documents` hors RPC (`0001:735-736`, `:1201`).
17. §16.2 « compte autorisé » : `decider_dossier` sans `app_account_valid` (`0004:530-548`).
18. §16.3 : audit de décision sans version ni résultat (`0004:568-569`).
19. §16.4 et §17.4 : pas de `stale_dossier` ni `already_decided` ; décision écrasable (`0004:550-556`).
20. Refus après validation : le compte reste `active` (`0004:558-562`).
21. §17.4 : retour void, activation possiblement silencieuse (`0004:527`, `:559-561`).
22. §17.3 et §11.6 : lecture de pièce signée côté client, sans contrôle ni audit par pièce (`service_validation.dart:220-223`).
23. Texte « Chaque consultation de pièce est inscrite au journal d'audit » : inexact par pièce (`fr.i18n.json:921`).
24. « Stockage privé R2 » : le chemin actif est le seau Supabase `kyc` (`service_dossier.dart:142`).
25. « Plafond de 8 Mo » : côté client seulement (`0004:997-998`).
26. « Autre » : texte libre perdu (`depot_piece_page.dart:176`).
27. Formats : webp accepté côté client, refusé par R2 ; PDF non affichable dans l'aperçu (`selecteur_fichier.dart:31-33` ; `signature.ts:74`).
28. Nommage : `decider_dossier` décide un document ; `decide_dossier` décide un dossier (spec:1364-1374).
29. `motifRequis` parle de « la famille », alors que la file contient des enseignants (`fr.i18n.json:920`).
30. Mode refus sans bouton Annuler ; validation sans confirmation (`dossiers_page.dart:292-309`).
31. Date « Déposé le dd/MM/yyyy » sans heure ni fuseau (`dossiers_page.dart:453-455`).
32. Portail : promesse de notification sans notification (`fr.i18n.json:236`).
33. Libellés portail « Votre dossier n'a pas été validé. » et « Reprendre mon dossier » vs « Dossier refusé » et « Corriger » (P-ADM-09.1, 09.2, non vérifiable dans le dépôt).
34. P-ADM-09.2 : correction sans condition ; texte « Ce dossier ne peut pas être modifié pour le moment. » absent.
35. P-ADM-11.1 : aucune relecture au retour dans l'application.
36. AC-12 : aucune dispense de pièce ; UPDATE direct d'`account_status` possible (`0001:704-705`).
37. ADM-08 : état de pièce visible sans cloisonnement de genre (`0015:160-174`).
38. §26 quater : démo admin absente ; fixtures sans mention « Document fictif ».
39. §4 bis.2 : CTA pleine largeur par défaut ; correctif `7727511` absent de HEAD (`action_principale.dart:56`).
40. §4 bis.2 : ConfirmDestructive empile destructif au-dessus d'Annuler (`confirm_destructive.dart:152-175`).
41. §4 bis.2 : pied collé réservé aux tâches longues ; son usage pour la décision est à justifier (`DESIGN-GOV:158`).
42. §4 bis.4 : aucun composant maître-détail 336 / 24 / 728 ; dialogue borné à 560.
43. §4 bis.5 : second jeu de durées `Mouvement` utilisé par AppCard (`mouvement.dart:8-35`).
44. Commentaires de durées et gouttières périmés (PageShell, AppBottomSheet, LocalFeedback, BlocAsynchrone, Skeleton).
45. Règle du dépôt : SectionHeader compare la largeur à 600 en dur (`section_header.dart:49` ; `app_gabarit.dart:51-52`).

## 9. Besoins serveur pour AD-BR

1. RPC de file paginée et filtrable (équivalent `list_reviewable_dossiers`), une ligne par personne, sans `object_key`.
2. RPC de détail avec révision, `can_validate`, `can_view_document` (équivalent `get_dossier_for_review`).
3. Brancher la lecture sur `autoriser_lecture_piece_identite` / `piece-identite-acces`, à la place de `createSignedUrl` client.
4. Restreindre la policy Storage `kyc_lecture_admin`.
5. Persister les trois contrôles avec la décision et les recontrôler côté serveur (`missing_required_check`).
6. Garde d'état ou révision dans la décision (`already_decided`, `stale_dossier`).
7. Idempotence (`command_id`) et lecture du résultat (`get_decision_result`).
8. Retour typé (statut final, état d'accès, `decided_at`) et `cannot_activate`.
9. Décision au niveau du dossier, avec contrôle des accords (`contract_acceptances`).
10. Gardes en exigence positive `coalesce(..., false)` : `decider_dossier`, `read_kyc_documents`, `guard_profile_privileged_columns`.
11. `app_account_valid()` dans la décision.
12. Harmoniser le périmètre admin / controller du reviewer KYC.
13. Fermer ou restreindre `kyc_admin_all` et le grant direct sur `kyc_documents`.
14. Encadrer l'UPDATE direct de `profiles.account_status` par un admin.
15. Enrichir le payload `kyc_decision` (version, résultat, activation effective).
16. Politique de genre versionnée (`genre_reviewer_enforced`, valeur initiale true), lue par `read_kyc_documents`.
17. RPC `get_kyc_review_policy` et `set_kyc_review_policy` (Super Admin, concurrence, audit).
18. Fondation Super Admin : claim ou table de capabilities, miroir client dans `SessionState`.
19. Soustraire la politique à l'écriture directe sur `app_config`.
20. Protéger `profiles.gender` contre l'auto-modification ; RPC administrative auditée pour poser le genre du personnel.
21. Aligner `comptes_admin()` sur la politique de genre (`non_visible`).
22. Plafond de taille et MIME imposés côté serveur, ou bascule vers le dépôt R2.
23. Aligner les formats acceptés (webp).
24. Décider du sort du texte libre « Autre ».
25. Longueur maximale du motif de refus.
26. Signal de changement d'état pour `/attente` (Realtime ou équivalent).
27. Notifications de décision, ou retrait de la promesse du portail.
28. Indicateur « correction autorisée » et éléments à corriger dans `etat_dossier()`.
29. Politique de dispense de pièce par rôle, si le directeur la confirme.
30. Trancher entre les voies Storage `kyc` et R2.
31. Tests SQL : 8 cas du §15.4, plus accès direct via `kyc_admin_all` et via le seau `kyc`.

## 10. Points introuvables

1. Bouton dédié « Dossiers à valider » dans le domaine Personnes.
2. Sous-navigation Personnes.
3. Titre, sous-titre, bouton thème et pied utilisateur dans AdminShell.
4. Écrans ADM-02A à 02E.
5. Persistance serveur des trois vérifications.
6. Révision, idempotence ou verrou dans `decider_dossier`.
7. `list_reviewable_dossiers`, `get_dossier_for_review`, `request_kyc_document_view`, `decide_dossier`, `save_review_checks`, `get_decision_result`.
8. `get/set_kyc_review_policy`, `genre_reviewer`, rôle `super_admin`, capability Super Admin.
9. Trigger d'audit de décision sur `kyc_documents`.
10. Contrôle des accords avant validation.
11. `app_account_valid` dans `decider_dossier`.
12. Journal par pièce ouverte depuis ADM-02.
13. Parcours ou RPC posant le genre d'un administrateur.
14. Mention du genre ou du Super Admin dans docs/current.
15. Test d'inaccessibilité via `kyc_admin_all` ou le seau `kyc`.
16. Plafond de 8 Mo côté serveur sur le chemin actif.
17. Visionneuse séparée avec zoom.
18. Règle de dispense de pièce.
19. Notification après décision.
20. Relecture automatique sur `/attente`.
21. Redirection vers `/enseignant/bienvenue`.
22. Mode démonstration admin (`?demo=admin`).
23. Composant maître-détail et dialogue avec champ multiligne.
24. Jetons `relatedAction` et `actionGroup`.
25. Helper `test/support/pressable_de.dart` sur HEAD.
26. Test du retour de focus et test Échap de la forme dialogue bureau.
27. Textes « Fermer la pièce », « Aucune décision ne peut être envoyée », « Actualisation des dossiers », « Dossier validé. », « Dossier suivant ».
28. Longueur maximale du motif de refus.
29. Sections de spec §2, §6, §6.1, §6.2, §17.x, §26 ter, P-ADM-09.x, P-ADM-11.x, AC-12 à AC-18 dans le dépôt : non vérifiables (spec hors dépôt).
