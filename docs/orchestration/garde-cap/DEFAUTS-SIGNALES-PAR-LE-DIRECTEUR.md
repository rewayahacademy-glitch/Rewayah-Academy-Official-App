# Défauts signalés par le directeur : registre du garde-cap

Règle (garde-cap, 07/11/2026, après la perte de la trace du défaut photo) : tout défaut signalé par
le directeur est écrit ici **le jour même**, avec ses preuves, sa cause, son responsable et son
train. Une ligne ne se ferme que quand le directeur l'a prouvé lui-même en production.

| Signalé | Défaut | État |
| :--- | :--- | :--- |
| 07/11/2026 | Un tuteur ne peut changer ni sa photo ni celle de son deuxième enfant (production) | **OUVERT** : cause prouvée ; correction PR 326 (E, PHOTO-FOYER) jugée CONFORME le 08/11 vers 00:10 UTC, non installée |
| 07/11/2026 (23:5x) | D1. Le tuteur ne peut pas retirer son deuxième enfant (adulte du foyer) depuis son profil | **OUVERT** : cause relevée ; règle produit à trancher par le directeur |
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

## Lots sans PR à ne pas perdre (relevé du garde-cap, 08/11/2026)

- **HARMONISER-ARGENT** (dette obligatoire, `docs/current/A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) :
  branche `claude/harmoniser-argent` @ 9cf1b12f (07/11 11:51, « relevé et proposition, phase 1 »,
  docs), **aucune PR**. Le pilote lui donne un porteur après le train photo.
