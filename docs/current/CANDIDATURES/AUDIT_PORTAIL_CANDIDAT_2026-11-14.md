# Audit du portail candidat : chaque obligation, à chaque état (14/11/2026)

Lot AUDIT-PORTAIL-CANDIDAT. Demande du directeur (14/11/2026) : « je t'ai expressément dit
de scanner tout globalement pour ne rien rater ». Deux trous du même type avaient été
trouvés un par un : R2 (pièce non déposable après l'envoi, #485) et R3 (contrat et avis non
signables après l'envoi, #491). Cet audit vérifie toutes les autres cases.

**Ce qui n'est pas prouvé, en premier** : les corrections ci-dessous sont testées localement
(tests Flutter, scénarios SQL sur un Postgres 16 neuf), pas en production. La migration
`20261126700000_audit_portail_candidat.sql` est à coller par le directeur ; tant qu'elle
n'est pas installée, la direction voit toujours « Disponible au branchement serveur » à la
place des contrôles du dossier.

Méthode : les règles sont lues dans les définitions **en production**
(`pg_get_functiondef`, `pg_policies`, projet `gggmtelinlpseweouyav`, lecture seule) et dans
le code du portail ; les nombres sont lus en production le 14/11/2026 vers 22 h 30 (UTC),
sur les candidatures enseignant `issue = en_cours`.

## 1. Les obligations, lues dans le serveur

| # | Obligation | Où le serveur l'accepte (fichier : ligne) | Quand elle est exigée |
| :-- | :-- | :-- | :-- |
| O1 | Cadre religieux et pédagogique, version requise | policy `contract_acceptances_cadre_religieux_candidat`, `20261022000000_cand_l2a1_moteur_salle_examen.sql:899` (à toute étape, si `cadre_religieux_acceptable(version)`) | à l'envoi (`envoiBloque` : `cadre_non_accepte`) ; en salle 2 si une version neuve est publiée (`aCompleter` : `cadre_religieux`, même fichier :1859) ; en salle 3 (`accords_signes`) |
| O2 | Contrat d'enseignant (`teacher_nda`) | policy `contract_acceptances_self_insert`, `20261011072525_f70_review_insert_acl_and_hash.sql:51`, redite `20261017100800_af_l1_08_policies_compte_valide.sql:234` (compte `pending_kyc`, texte courant), sans condition d'étape | salle 3 : `candidature_controles_salle3`, `accords_signes` (version courante **et** empreinte) |
| O3 | « Ce que vous devez savoir » (`recording_and_control_notice`) | même policy `self_insert`, sans condition d'étape | salle 3 (version requise, `contract_required_versions`) |
| O4 | Code de conduite (`teacher_conduct_code`) | policy `contract_acceptances_code_conduite_enseignant`, `20261018160000_pe_protection_enfants.sql:363`, redite `20261021210400_pe_code_conduite_avant_activation.sql:54` (version requise, compte `pending_kyc` ou actif) | salle 3 ; garde d'activation |
| O5 | Pièce d'identité, premier dépôt | `private.candidature_accepte_depot_piece`, `20261126300000_piece_salle1_apres_envoi.sql:55` (salle 1 en cours quel que soit l'état, salle 2, salle 3) ; policy `kyc_staff_self_insert` | salle 3 (`valider_piece_candidat`) |
| O6 | Pièce refusée, à déposer de nouveau | même règle que O5 (un nouveau dépôt est une nouvelle ligne) | idem |
| O7 | Photo | `public.poser_photo_candidat`, `20261110330000_cand_photo.sql:118` | à l'envoi (refus `photo_requise`) ; ensuite facultative |
| O8 | Accord de publication | `public.accepter_accord_publication`, `20261110330000_cand_photo.sql:280` | à l'envoi (refus `accord_publication_requis`) ; ensuite **facultatif** et retirable (CAND-PHOTO, 06/11) |
| O9 | Conditions de rémunération (`teacher_pay_conditions`) | **jamais par le client** : policy `contract_acceptances_conditions_remuneration_serveur` (`20261022000000…:909`) ; posées par le serveur à l'envoi (`…:2153`) | à l'envoi seulement |
| O10 | Réponses du questionnaire et envoi | `soumettre`/`envoyer` de la salle d'examen, état `a_completer` hors pause | à l'envoi ; rouvert par la direction (complément, transition 7) |
| O11 | Moyen de paiement (versement) | dans le questionnaire (O10) | à l'envoi ; `paiement_non_disponible` = attendre la direction |
| O12 | Créneau d'entretien | `public.reserver_creneau_entretien`, `20261109200000_v1b_creneaux_entretien.sql:349` | état `entretien_a_planifier` |
| O13 | Nouvelle version du contrat ou de l'avis | même policy que O2/O3 | salle 3 (`accords_signes`) |

## 2. Le tableau obligation × état

Légende : **OK** = le serveur l'accepte et le portail montre où le faire ; **—** = rien à
faire à cet état (le serveur ne l'exige pas ou c'est la direction qui agit) ; **TROU** = le
serveur l'accepte (ou l'exige) et le portail ne montrait pas le chemin ; **Pause** = rien
n'est demandé pendant une pause (choix du lot RECRUTEMENT-SANS-SORTIE, la pause affiche le
texte de la direction).

États de la salle 1 : `a_completer` (A), `en_examen` (E), `paiement_non_disponible` (P),
pause (Z). Salle 2 : `entretien_a_planifier` (EP), `entretien_planifie` (EF), `en_examen` ou
`decision_en_attente` (S2). Salle 3 : `confirmee` (C). État nul hors salle : `recue`, `invitee` (N).

| Obligation | A | E | P | Z | EP | EF | S2 | C | N |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| O1 cadre | OK ¹ | — ² | — ² | Pause | **TROU T2** → corrigé | **TROU T2** → corrigé | **TROU T2** → corrigé | — ³ | — ⁴ |
| O2 contrat | OK ⁵ | OK ⁶ (R3, #491) | OK ⁶ (R3, #491) | Pause | OK ⁷ | OK ⁷ | OK ⁷ | — ³ | — ⁴ |
| O3 avis | OK ⁵ | OK ⁶ | OK ⁶ | Pause | OK ⁷ | OK ⁷ | OK ⁷ | — ³ | — ⁴ |
| O4 code de conduite | OK ⁵ | OK ⁶ | OK ⁶ | Pause | OK ⁷ | OK ⁷ | OK ⁷ | — ³ | — ⁴ |
| O5 pièce | OK ⁸ | OK ⁸ (R2, #485) | OK ⁸ (R2, #485) | Pause | OK ⁷ | OK ⁷ | OK ⁷ | — ³ | — ⁴ |
| O6 pièce refusée | **TROU T1** → corrigé | **TROU T1** → corrigé | **TROU T1** → corrigé | Pause | OK ⁹ | OK ⁹ | OK ⁹ | — ³ | — ⁴ |
| O7 photo | OK ¹⁰ | — | — | Pause | — | — | — | — | — |
| O8 accord de publication | OK ¹⁰ | — ¹¹ | — ¹¹ | Pause | — ¹¹ | — ¹¹ | — ¹¹ | — ¹¹ | — |
| O9 conditions de rémunération | OK ¹⁰ | — ¹² | — ¹² | — | — ¹² | — ¹² | — ¹² | — | — |
| O10 réponses | OK ¹³ | — ¹⁴ | — ¹⁴ | Pause | — | — | — | — | — |
| O11 moyen de paiement | OK ¹³ | — | — ¹⁵ | — | — | — | — | — | — |
| O12 créneau d'entretien | — | — | — | — | OK ¹⁶ | OK ¹⁶ | — | — | — |
| O13 nouvelle version contrat / avis | **TROU T3** (latent) → corrigé, toutes étapes | | | | | | | | |

13 obligations × 9 états = **117 cases vérifiées**, plus 5 contrôles du côté de la direction
(section 4) : **122 cases**.

Renvois (fichier : ligne, branche `claude/audit-portail-candidat`) :

1. `prochaineCandidature`, `lib/features/candidature/portail_candidature.dart:155` (« Lire et
   accepter » → `/attente/cadre`), et la ligne « Cadre » de la liste, `:352`.
2. L'envoi a exigé le cadre (`envoiBloque`, `cadre_non_accepte`) ; une version neuve publiée
   pendant l'examen n'est pas redemandée en salle 1 par le serveur (`aCompleter` ne la porte
   qu'en `a_completer` ou en salle 2).
3. Salle 3 : le compte est actif, `/attente` le rend à l'espace enseignant
   (`attente_page.dart`, SALLE-3-ACCUEIL) ; les re-signatures d'un enseignant actif passent
   par `/tuteur/compte/consentements` (hors de cet audit).
4. État nul : `candidatures_etat_coherent` impose `etat` nul aux étapes `recue`, `invitee`,
   `confirmee` ; une candidature `recue` n'a pas encore de parcours (section 5).
5. `prochaineCandidature`, `portail_candidature.dart:158` ; ligne « Nos accords » `:366`.
6. `portail_candidature.dart:138` (SIGNER-APRES-ENVOI, PR #491, fusionnée).
7. Salle 2 : `vueCandidature` est faux, le portail montre les états du dossier ;
   `_prochaine` de `lib/features/dossier/attente_page.dart:376` mène aux accords puis à la
   pièce, sous l'en-tête de la salle (`attente_page.dart:231`).
8. `portail_candidature.dart:161` (a compléter) et `:138` (après l'envoi).
9. Salle 2 : `EtapeDossier.refuse` → « Corriger » (`attente_page.dart:385`).
10. Au récapitulatif des réponses (`recapitulatif_etape.dart`), qui pose photo, accord de
    publication et conditions avant l'envoi ; la ligne « Votre photo » du portail,
    `portail_candidature.dart:389`.
11. Facultatif après l'envoi (CAND-PHOTO) : aucun contrôle de passage ne le lit ; il se
    donne ou se retire au Profil de l'enseignant (`profil_enseignant/accord_publication_profil.dart`).
    Une version neuve publiée pendant la candidature ne bloque rien : ce n'est pas un trou.
    0 accord à une autre version que la publiée en production.
12. Le client ne peut pas les accepter (policy `…_serveur`) ; le serveur les pose à l'envoi
    et aucun contrôle ultérieur ne les relit. Rien à montrer.
13. `prochaineCandidature` → « Compléter ma candidature », `portail_candidature.dart:165`.
14. Les réponses envoyées se relisent (`reponsesRelisibles`, lien « Relire »,
    `attente_page.dart`) et restent figées (L2 du registre) ; la direction rouvre par un
    complément (le portail repasse en `a_completer`, où tout est proposé).
15. Rien à faire : la direction n'examine plus rien tant qu'aucun moyen n'est possible
    (`portail_candidature.dart:420`, texte « versement pas encore possible »).
16. `EnteteSalle`, lien « Choisir le moment de notre entretien » / « Voir », 
    `portail_candidature.dart:249` → `/attente/entretien`.

## 3. Les personnes concernées en production (14/11/2026)

Candidatures enseignant en cours : 74. Par état, ce qui manque (lecture seule) :

| Étape / état | Nombre | Sans contrat | Sans avis | Sans code de conduite | Sans cadre | Sans pièce | Pièce refusée | Sans photo | Sans accord de publication |
| :-- | --: | --: | --: | --: | --: | --: | --: | --: | --: |
| salle 1, `a_completer` | 17 | 13 | 13 | 13 | 5 | 16 | 0 | 16 | 16 |
| salle 1, `en_examen` | 42 | 29 | 29 | 29 | 0 | 26 | 0 | 0 | 0 |
| salle 1, `paiement_non_disponible` | 12 | 7 | 7 | 7 | 0 | 5 | 0 | 0 | 0 |
| salle 2, `entretien_a_planifier` | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| salle 3, `confirmee` | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

- 36 candidatures envoyées sans contrat (29 + 7 ; R3 comptait 37 avec une candidature
  retirée) : elles ont désormais « Lire et accepter » (#491).
- 31 candidatures envoyées sans pièce (26 + 5) : « Déposer ma pièce » (#485), une fois les
  accords faits.
- Aucune candidature en pause ; aucune pièce refusée ; aucun contrat, avis ou accord de
  publication à une version périmée (vérifié par le pilote, même jour).
- Les 16 candidatures `a_completer` sans photo, accord de publication ni conditions les poseront
  au récapitulatif ; le portail les y mène.

## 4. Du côté de la direction (consigne 19 : ne pas faire sortir d'un dossier)

| Contrôle | Avant | Après ce lot |
| :-- | :-- | :-- |
| D1. Le dossier dit-il ce qui manque (contrat, avis, code, cadre, pièce) ? | **TROU T4** : `lire_candidature` rendait `'controles', NULL` (production, 14/11) ; les blocs « Ce qui bloque » et « Contrôles » affichaient « Disponible au branchement serveur » (`blocs_candidature.dart:246` et `:655`). 36 dossiers envoyés sans contrat étaient muets. | Migration `20261126900000` : `private.candidature_controles_dossier` rend `cadre_religieux`, `accords_signes` (premier accord manquant en cause, la règle de la salle 3), `piece_validee` (absente, à vérifier, à déposer de nouveau) et, après l'envoi, `questionnaire_complet` et `paiement_compatible`. Les causes sont dites en mots (`libelles_candidature.dart`, 8 libellés en fr, ar, en). |
| D2. La pièce se voit et se décide sur place ? | OK : `PieceSurPlace` (SALLE2-FICHE). | inchangé |
| D3. Relancer la personne sans sortir ? | OK : la conversation se déplie dans le dossier (`EntreeMessagesContexte`, R1, #485). | inchangé |
| D4. Demander un complément sans sortir ? | OK : geste « Demander un complément » du dossier (salle 1 : cartes du questionnaire et cadre ; salle 2 : pièce, cadre, contrat, avis). | inchangé |
| D5. Les causes de la salle 3 se lisent ? | **Partiel** : `accords_signes` rendait `teacher_nda`… que l'écran affichait « Cause non précisée ». | Causes nommées (même correctif que D1). |

## 5. Les 4 candidatures en cours dont l'état est nul

Ce n'est pas une anomalie : la contrainte `candidatures_etat_coherent` impose `etat` nul aux
étapes `recue`, `invitee` et `confirmee`.

- 3 candidatures de type `famille` ou `eleve_adulte` (source `lien_public`) : une `confirmee`
  (compte tuteur actif), une `confirmee` (compte tuteur désactivé), une `recue` (compte tuteur
  `pending_kyc`, reçue le 14/11). Elles sont **sans contrat d'enseignant** parce que ce ne sont
  pas des enseignants : leurs conditions (`guardian_terms`) et l'avis sont signés. Ce sont les
  « 3 sans contrat ».
- 1 candidature enseignant `confirmee` (compte enseignant actif, contrat signé).

## 6. Les trous trouvés et corrigés

| # | Trou | Personnes touchées le 14/11 | Correctif |
| :-- | :-- | :-- | :-- |
| T1 | Salle 1 : une pièce **refusée** comptait comme « déposée » ; la ligne disait « Fait / Votre pièce est bien reçue » et aucun dépôt n'était proposé, alors que le serveur en accepte un nouveau. | 0 (aucune pièce refusée aujourd'hui) | `pieceADeposer` compte la pièce refusée ; « Déposer ma pièce » est proposé ; la carte et la ligne disent « Élément à reprendre : Votre pièce d'identité. » (`portail_candidature.dart:96-110`, `:389`, `:443`). |
| T2 | Salle 2 : une **nouvelle version du cadre** à accepter (`aCompleter` : `cadre_religieux`) n'avait aucun chemin ; le portail de la salle 2 ne connaissait que les accords et la pièce. | 0 (cadre accepté par les 2 candidats de salle 2) | `cadreAAccepterEnSalle2` ; « Lire et accepter » → `/attente/cadre` avant tout le reste (`attente_page.dart:155`). |
| T3 | `etat_dossier` disait « contrat signé » pour **toute** version du contrat et de l'avis, alors que la salle 3 exige le contrat courant (version et empreinte) et l'avis requis : le jour d'une nouvelle version, le portail aurait dit « Fait » et la confirmation aurait été refusée sans chemin pour signer. | 0 (aucune signature périmée) : latent | Migration `20261126900000`, partie 3 : pour l'enseignant, la règle de la salle 3 ; la page des accords propose alors la nouvelle version. Le tuteur garde la règle d'avant. |
| T4 | La direction ne voyait pas dans le dossier ce qui manque (contrôles nuls). | la direction, sur les 74 dossiers en cours (dont 36 envoyés sans contrat) | Migration `20261126900000`, parties 1 et 2, et les 8 causes nommées. |

## 7. Ce qui n'a pas été vérifié

- **Créneaux d'entretien ouverts** : les 2 candidats `entretien_a_planifier` ont le lien ;
  qu'il y ait des créneaux à réserver dépend de la direction. Requête à exécuter par le pilote :

  ```sql
  -- Créneaux réservables par chaque candidat à planifier (même filtre que
  -- creneaux_entretien_disponibles, sans la vérification de tenue).
  select c.reference, count(e.id) as creneaux_possibles
    from public.candidatures c
    left join public.entretien_creneaux e
      on e.cote = c.genre and e.session_id is null and e.annule_le is null
     and e.debut > now() + interval '30 minutes'
     and e.langues && private.candidature_langues(c.id)
   where c.etat = 'entretien_a_planifier' and c.issue = 'en_cours'
   group by c.reference;
  ```

  Une ligne à 0 veut dire : le lien est là, mais la page n'a aucun créneau à proposer.
- Le cas d'une candidature `recue` ou `invitee` qui a déjà un compte (1 aujourd'hui, de type
  `eleve_adulte`) relève du parcours des familles, pas de ce portail.
- `scenarios_cadre_publication.sql` échoue déjà sur `main` (« aucun contrat teacher_nda hors du
  français » : la migration `20261125400000_contrat_nda_traductions` a ajouté l'arabe et
  l'anglais) ; il n'est pas joué par la CI et n'est pas touché par ce lot.

## 8. Preuves locales

- `flutter test test/features/candidature test/features/admin_candidature test/features/admin_candidatures test/widgets` : vert.
- `dart analyze --fatal-infos` : aucune remarque. `verifier_jetons` : aucune violation.
  `verifier_revue` : 1091, le même nombre que `main` (aucune nouvelle).
- Postgres 16 neuf : `stub_auth.sql`, toutes les migrations (la nouvelle comprise), puis les
  scénarios qui touchent `etat_dossier`, `lire_candidature` ou `contract_acceptances` : verts,
  sauf `scenarios_cadre_publication.sql` (voir §7). `scenarios_cand_l1_socle.sql` est mis à
  jour (le dossier rend désormais ses contrôles ; l'assertion vérifie leurs noms et causes).
  Nouveau : `scenarios_audit_portail_candidat.sql` (versions du contrat et de l'avis,
  contrôles du dossier, droits).
- Captures R3 : `docs/current/captures/E2E/audit-portail-candidat/` (pièce refusée en
  salle 1, cadre neuf en salle 2 ; 390 et 1440, fr et ar).
