# Défauts signalés par le directeur : registre du garde-cap

Règle (garde-cap, 07/11/2026, après la perte de la trace du défaut photo) : tout défaut signalé par
le directeur est écrit ici **le jour même**, avec ses preuves, sa cause, son responsable et son
train. Une ligne ne se ferme que quand le directeur l'a prouvé lui-même en production.

| Signalé | Défaut | État |
| :--- | :--- | :--- |
| 07/11/2026 | Un tuteur ne peut changer ni sa photo ni celle de son deuxième enfant (production) | **OUVERT** : cause prouvée ; correction PR 326 (E, PHOTO-FOYER) jugée CONFORME le 08/11 vers 00:10 UTC, non installée |
| 07/11/2026 (23:5x) | D1. Le tuteur ne peut pas retirer son deuxième enfant (adulte du foyer) depuis son profil | **CLOS par décision du directeur (08/11 00:58)** : un tuteur ne peut plus créer de profil adulte (mineur_fantome refuse 18 ans et plus) ; le seul cas, supprimé ; reste l'invitation du conjoint adulte qui gère son profil seul (PR 275, en production) |
| 07/11/2026 (23:59, relayé par le pilote) | D3. « Paramètres → Préférences → Notifications NE MARCHE PAS » ; notifications actives par défaut demandées | **OUVERT** : PR 328 (H, NOTIF-DEFAUT) jugée CONFORME le 08/11 vers 00:20 UTC, train suivant ; preuve de la cause à joindre au bilan de H |
| 07/11/2026 (23:5x) | D2. Dans l'admin, un profil retiré reste affiché jusqu'à la déconnexion | **OUVERT** : cause non relevée ; responsable et train à fixer après le g4 |

## 07/11/2026 : photo du tuteur et de son deuxième enfant

Preuves (production, lecture seule, journaux du 07/11, foyer de test du directeur `972a8054`) :

- l'envoi du fichier dans le seau `avatars` réussit (200), puis l'enregistrement par
  `poser_photo_eleve` échoue (400, « enfant introuvable dans votre foyer », ligne 12) :
  07:42 (×6), 07:45, 11:50 (×3), 13:16, 22:51 ; contre-épreuve : un enfant mineur du même foyer
  passe (07:41, 200) ;
- aucun appel à `poser_ma_photo` de la journée ;
- le 401 sur `photo_adulte_moi` à 11:34:57 est un jeton expiré, pas la cause.

Causes :

1. **Deuxième enfant** (`913e7d6d`) : créé à 07:27 par `creer_profil_enfant` (`minor`), mais il a
   18 ans ou plus (cohorte `adulte_18_plus`) ; à 07:29 `profil_apprentissage_enregistre` l'a passé en
   `autonomous`. `poser_photo_eleve` exige `student_type = 'minor'`.
2. **Tuteur qui étudie** (`47c14844`, ligne `student_profiles` `autonomous` depuis PROFIL-TITULAIRE) :
   l'application envoie sa photo par `poser_photo_eleve` (refusée).
3. **Photo masquée** (vu par l'ancien garde-cap) : `private.photo_source` lit
   `student_profiles.avatar_storage_key` dès qu'une ligne `student_profiles` existe ; la photo déjà
   posée du tuteur est dans `profiles.photo_storage_key` et n'est plus lue (1 tuteur en production).

Correction confiée à E, lot PHOTO-FOYER, plage 20261120400000 à 20261120499999, train séparé après le
g4 : `poser_photo_eleve` accepte un mineur du foyer, le tuteur lui-même et un compte enfant géré par
lui (un adulte qui a son propre compte reste refusé) ; une seule clé par personne
(`student_profiles.avatar_storage_key`), reprise sans effacement depuis `profiles.photo_storage_key` ;
le client envoie la photo du tuteur par `poser_ma_photo` ; scénario rouge sans la migration.
Fichiers orphelins dans le seau : 3 sous `913e7d6d/`, 3 sous `47c14844/` (dont la photo actuelle).

## 07/11/2026 (23:5x) : D1, retrait d'un adulte du foyer par le tuteur

Relevé par le pilote en production : le deuxième enfant (`913e7d6d`, le même que pour la photo) était
`student_type = 'autonomous'` dans le foyer ; `tuteur_supprimer_profil_enfant` (20261108600000) refuse
`autonomous` par conception (`profil_hors_foyer`). Même famille que le défaut photo : un adulte créé
par le tuteur dans son foyer, sans connexion propre. Retiré par l'administration à 23:51:53
(`deleted_at` vérifié par le garde-cap). **Règle à trancher par le directeur** : un tuteur peut-il
retirer, et poser la photo de, un adulte de son foyer qu'il a créé lui-même ?

## 07/11/2026 (23:5x) : D2, liste de l'admin pas rafraîchie après un retrait

Après `direction_supprimer_comptes`, le profil retiré reste affiché jusqu'à la déconnexion du
directeur. Cause non relevée (probablement un cache ou un provider non invalidé). Responsable et
train à fixer après le g4.

## Test qui dépend de l'heure (relevé du garde-cap, 08/11/2026 00:11 UTC)

`test/features/notifications/notifs_l6_test.dart` (« trois répétitions du même jour ») place trois
notifications à 10, 11 et 12 minutes de l'heure courante : entre 00:00 et ~00:12 UTC, elles tombent sur
deux jours et le test échoue (vu sur la PR 323). Dette : fixer l'heure dans le test. Porteur à désigner.

## Migration de main jamais installée (relevé du garde-cap, 08/11/2026 00:45 UTC)

`20261110620000_cahier_c3_paie_par_seance.sql` est dans `main` mais n'a jamais été installée en
production : `private.cahier_c3_coupure` était absente, et la PR 276 en dépend. Le garde-cap avait
vérifié seulement le sens production → dépôt ; il a ensuite vérifié le sens dépôt → production
pour les 30 fichiers de `main` depuis le 01/11 sans version à leur nom : les 29 autres ont leur
effet en production (collés dans l'éditeur). Feu vert donné au pilote : installer 620 sans ses lignes
`BEGIN;` (l. 27) et `COMMIT;` (l. 132), puis 276. **Dette** : aligner le fichier de `main` (retirer ces
deux lignes) au train suivant.

## Lots sans PR à ne pas perdre (relevé du garde-cap, 08/11/2026)

- **HARMONISER-ARGENT** (dette obligatoire, `docs/current/A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) :
  branche `claude/harmoniser-argent` @ 9cf1b12f (07/11 11:51, « relevé et proposition, phase 1 »,
  docs), **aucune PR**. Le pilote lui donne un porteur après le train photo.

## Décision du directeur, 08/11/2026 00:58 UTC

« cette question ne se pose plus, parce qu'un tuteur ne peut plus créer un profil adulte, le seul cas
a été supprimé "Ibrahim", ce qui reste c'est de pouvoir inviter son conjoint qui est déjà adulte et
qui gère son profil seul. » Conséquence : PR 326, la ligne CHILD_OF est retirée, PF1 devient un refus.
« tu dois tout faire, tu ne reportes plus rien » : le report au réveil est annulé (620, 276, 316, g5).
