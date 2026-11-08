# Défauts signalés par le directeur : registre du garde-cap

Règle (garde-cap, 07/11/2026, après la perte de la trace du défaut photo) : tout défaut signalé par
le directeur est écrit ici **le jour même**, avec ses preuves, sa cause, son responsable et son
train. Une ligne ne se ferme que quand le directeur l'a prouvé lui-même en production.

| Signalé | Défaut | État |
| :--- | :--- | :--- |
| 07/11/2026 | Un tuteur ne peut changer ni sa photo ni celle de son deuxième enfant (production) | **OUVERT** : cause prouvée, correction confiée à E (PHOTO-FOYER) |

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
