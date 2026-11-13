# Lot SUIVI-ATTENTE : le suivi de l'attente de la classe, « comme une livraison »

> Lot demandé par le directeur le 12/11/2026, arbitré par l'architecte pédagogique (arbitrages S1 à S9). Branche `claude/suivi-attente`. Cette fiche est écrite avant le code et mise à jour à la fin. Elle dit d'abord ce qui est faux, bloqué ou non prouvé.

## 0. Ce qui est faux, bloqué ou non prouvé (à lire en premier)

1. **Rien n'est prouvé en production.** Il n'y a aucune demande réelle. L'écran est prouvé par des tests et des captures sur des données de test (S9), pas par le directeur.
2. **« Tout est prêt » prévient la famille, mais seulement une fois `20261123961000` collée.** Elle remplace la contrainte `notifications_evenement_check` (un `DROP CONSTRAINT` : un seul mot d'effacement, aucune donnée supprimée) ; **le directeur la colle dans l'éditeur SQL**, après `20261123960000`, comme le lot « calendrier et pauses » le fait pour `pause_repondue`. Les deux fichiers lisent la liste dans la contrainte en place et y ajoutent leur valeur : aucun des deux n'écrase l'autre, dans n'importe quel ordre (prouvé en rejouant `20261123911000` du lot 2 après le mien). **Tant que `961000` n'est pas collée, rien ne part** (avertissement dans le journal du serveur, jamais d'échec d'une séance ou d'un élève). `20261123962000` pose la notification (tuteur d'un mineur, ou élève adulte lui-même ; jamais l'enfant), le courriel (cinq langues) et le push (sans prénom).
3. **« Entrée en début de mois » n'est pas construite** (`STRATEGIE-FORMATION-DES-CLASSES.md`, tableau de la partie 2). L'écran ne la promet donc pas. Il ne promet que le délai de 14 jours et le point à 7 jours, lus dans `app_config` (clés posées par ce lot, valeurs décidées le 30/09).
4. **Pays d'origine et pays de résidence de l'enseignant n'existaient pas** dans le compte d'un enseignant (`teacher_profiles.country` seul, sens ambigu ; `pays_residence` n'existe que sur la candidature). Ce lot ajoute deux colonnes, que l'enseignant remplit dans son profil. **Tant qu'il ne l'a pas fait, la carte ne montre ni l'un ni l'autre** (jamais « inconnu »).
5. **La photo n'est pas masquée par le réglage** (revue du 13/11, I2/I3). Le réglage de l'enseignant s'intitule « Montrer mon pays et mon mot aux familles avant le premier cours » : il gouverne le pays d'origine, le pays de résidence et le mot, et seulement ce qu'il a saisi. Les familles de sa classe voient sa photo par `private.photo_visible_par`, comme sur les autres écrans ; ce lot ne la change pas, et aucun texte ne promet un masquage que le serveur ne fait pas. Défaut : visible pour **tous** les enseignants (pays et mot sont vides tant qu'ils ne les ont pas saisis).
6. **Âge de l'enfant** : aucune date de naissance n'est en base. « Sans délai chiffré avant 10 ans » s'appuie sur `student_profiles.cohorte = 'enfant_6_9'` (la tranche 6-9 ans, lue en production comme dans `libelleTranche`) : exact tant que la tranche est tenue à jour.
7. **Heures** : le serveur rend l'heure murale du foyer (`AT TIME ZONE households.timezone`, même expression que `suivi_demandes_horaires_foyer`), et l'écran la dit par les fonctions d'affichage existantes (`libelleJalon`, `deFuseau`). Aucune conversion de fuseau nouvelle ; le lot HORLOGE n'est pas touché.
8. **Un seul écran de suivi, quand le suivi est branché** (S6). L'adresse historique d'une demande (`/tuteur/demandes/:id`, `/eleve/adulte/demandes/:id`) ouvre l'écran à cinq étapes (`DetailDemandeEntree`) ; sans port (production avant branchement), l'ancienne frise à six étapes (`lib/features/suivi_famille`, `suivi_demandes`, zone `suivi_*` : **aucun fichier modifié**) reste le détail. **Les notifications et courriels qui pointent vers `/tuteur/demandes`** (destination figée par une contrainte `CHECK`) ouvrent **directement le suivi quand le foyer n'a qu'un suivi en cours, visible et non clos** (`EntreeDemandesAttente`) ; avec plusieurs suivis la liste reste la liste de raccourcis, parce que la notification ne porte pas l'identifiant de la demande. Les notifications de l'élève adulte (`/eleve`) tombent sur son accueil, où la carte du suivi est en tête.
9. **Le délai dépassé dit une phrase vraie, sans promettre d'action** (arbitrage du 13/11) : « La formation de votre classe prend plus de temps que prévu. L'académie vous écrit. » Ce que le système tient : `public.demandes_formation_depassees()` (direction seule) liste les demandes envoyées depuis plus de `formation_delai_jours` sans classe. **Ce qu'il ne tient pas : aucun écran ne montre encore cette liste à la direction** (les écrans de regroupement et de création de classe sont la zone du lot FC-1, interdite à ce lot), et aucune relance n'est automatique (lot FC-3). « L'académie vous écrit » ne devient donc vrai que si la direction lit la liste : à brancher par l'architecte.
10. **Une classe créée déjà pourvue d'un enseignant** (`INSERT` avec `teacher_id`) n'envoie à l'enseignant que `classe_creee`, pas `enseignant_affecte` : le déclencheur de ce lot suit celui de `notifier_classe` (passage de nul à un enseignant). « Me présenter » reste atteignable depuis Mes classes pour toute classe de moins de 30 jours.
11. **Les mots selon qui lit** (arbitrage du 13/11). Le tuteur lit toujours avec les mots des adultes, même pour un enfant de 6 à 9 ans (le lot lui faisait lire le tutoiement : défaut corrigé, `SuiviAttente.pourEspace`). Dans son propre espace, l'enfant de 6 à 9 ans lit **ni date ni durée** (étapes sans date, aucun créneau, aucun fuseau, « Ton premier cours arrive. Ton tuteur te dit quand. ») ; le mineur de 10 à 17 ans a ses mots à lui (tutoiement, dates et délais, rien sur l'argent ni sur les gestes du tuteur). **La tranche de 10 à 17 ans se déduit de `type_public = 'enfant'` quand la tranche 6-9 ne s'applique pas** ; l'espace de l'élève mineur n'est atteint aujourd'hui que par l'Interface guidée.
12. **L'export « mes données » porte les colonnes de ce lot** (pays, mot, visibilité, date de confirmation), par une retouche ancrée de `mes_donnees_export` dans `20261123962000` (empreinte F86 recalculée) ; l'effacement du compte efface pays et mot (déclencheur sur la marque d'anonymisation, comme PHOTOS-1).

13. **Aucun courriel n'est mis en file pour un profil mineur** (revue du 13/11, B1). La ligne `('enseignant_affecte', 'soi', true)` partait vers l'enfant (prouvé par la revue) : retirée. Et la porte est fermée pour de bon, côté serveur : `public.courriel_enfiler` (la seule fonction qui met un courriel en file) refuse tout profil dont `student_profiles.student_type = 'minor'`, quel que soit le modèle (retouche ancrée dans `20261123962000`, même signature, mêmes droits, empreinte F86 recalculée). Cela couvre aussi la dette de `main` (`classe_creee`, `classe_validee`, `eleve_inscrit` en portée « soi »). **Le tuteur reçoit bien son propre courriel par la portée « foyer »** pour chacun de ces événements (lignes `notification_courriel` lues, et courriels `enseignant_affecte` et `tout_est_pret` constatés dans le flux réel du scénario). **Effet de bord à connaître** : l'élève adulte ne reçoit plus de courriel « Enseignant affecté » (il lit l'avancement dans l'application) ; il reçoit « Tout est prêt » (ligne `('tout_est_pret', 'soi')`, portée propre aux adultes). L'adresse d'un profil sans `student_profiles` ne peut pas être reconnue comme mineure : la garde lit le profil élève, pas l'adresse.
14. **La carte de l'enseignant n'est rendue qu'à un foyer dont la demande vit et dont l'enfant est membre actif de la classe** (revue du 13/11, B2) : `AND NOT close_ AND t_membre IS NOT NULL`. Les deux sondes du relecteur (demande retirée ; enfant sorti de la classe avec remplaçant) sont des scénarios. Civilité et prénom seulement : `last_name` n'est plus rendu (I1).
15. **Délai : une phrase vraie** (I4). « Une classe se forme en 14 jours au plus », la date limite, le point d'étape et « la direction ne prolonge l'attente qu'avec votre accord » sont retirés : rien ne les tient. Reste la phrase du dépassement (voir 9).
16. **Un enseignant retiré après l'affectation** (I8) : l'étape 4 n'est plus « faite », la classe « attend son enseignant » (« Votre classe attend son enseignant. », « Ta classe… »), aucune carte. La lecture exige que la classe ait encore son enseignant.
17. **Une notification et un courriel par (enseignant, classe, affectation)** (I7) : déduplication côté serveur ; un remplacement direct A vers B prévient B par `enseignant_affecte` (notification enrichie et courriel) et non, en plus, par `enseignant_change` (retouche ancrée de `private.notifier_classe`, `enseignant_affecte` valant `enseignant_change`). **Non prouvé** : que A et les familles gardent `enseignant_change` dans ce cas (c'est ce que fait `notifier_classe` déjà ; le scénario tient dans une seule transaction, où la déduplication par instant et l'effacement du compte de l'ancien enseignant plus haut le masquent).
18. **« Me présenter » ne peut jamais avoir un mineur pour destinataire** (vérifié côté serveur) : `com_appelant()` exclut les mineurs, `com_paires` ne pose que le foyer (tuteur) pour un mineur ; le scénario prouve que l'enseignant joint le foyer, jamais l'enfant (contrôle positif et deux refus).

## Ordre d'installation (I5)

À respecter, dans cet ordre : **1. fusion de la branche et déploiement des fonctions Edge** (gabarits de courriel `enseignant_affecte` pour l'enseignant, `tout_est_pret`, textes de push) ; **2. migrations** `20261123960000`, puis `20261123961000` (collée par le directeur : un seul mot d'effacement), puis `20261123962000`.

- *Fonctions Edge d'abord, migration ensuite* (l'ordre retenu) : jusqu'à la migration, aucune ligne de courriel n'existe pour l'enseignant ni pour « tout est prêt » ; **rien ne part, donc aucun message faux**. Après la migration, chaque courriel part avec le bon gabarit.
- *Migration d'abord, fonctions Edge ensuite* (à éviter) : l'enseignant recevrait son courriel d'affectation avec l'ancien gabarit, écrit pour la famille (« Voir la classe », `/tuteur/demandes`) : un message faux ; « tout est prêt » n'aurait pas de gabarit connu. Aucune des deux migrations ne peut le savoir : elles ne rendent pas ce cas tolérant, l'ordre est la protection.
- Les trois migrations entre elles sont tolérantes : sans `961000`, `962000` n'échoue jamais (la notification « tout est prêt » est refusée par la contrainte, un avertissement est écrit, la séance ou l'élève ajoutés ne sont pas bloqués).

## 1. Ce qui est réutilisé (rien n'est refait)

| Existant | Usage |
|---|---|
| `demandes_horaires_famille`, `demande_evenements` (C-20) | Source unique des faits : `envoyee`, `classe_creee`, `en_attente`, `enseignant_affecte`, `eleve_integre`, `premiere_seance_prevue`, `close` |
| `suivi_demandes_horaires_foyer()` (garde, jointures, `peut_decrire_apprenant`) | Même garde et mêmes jointures dans la nouvelle lecture |
| Notifications `classe_validee`, `enseignant_affecte`, `private.notifier_classe`, `private.notification_courriel` | Aucun événement créé ; la table des courriels est complétée |
| `libelles_suivi_demandes.dart` (`libelleJalon`, `jourDateDemande`, `deFuseau`, `hhmmDemande`) | Dates et heures affichées |
| `BlocAsynchrone`, `Skeleton`, `EmptyState`, `EtatSysteme`, `EtatSansDonnees`, `PageShell`, `AppCard`, `LienFleche`, `ActionPrincipale`, `PileCartes`, `PaysEnseignant.parCode`, `AvatarNom`, `PhotoEnseignant` | Composants |
| `AppMouvement` (durées et courbes), `AppIcons` (Phosphor) | Animation au franchissement d'une étape |
| Messages métier (`com_ouvrir_conversation`, `com_envoyer_message`, `PortMessagesMetier`) | « Me présenter » : un message par foyer ou par élève adulte de la classe, par le fil existant (paire autorisée par le serveur) ; aucune messagerie nouvelle |
| Accueils `accueil_famille` (carte `CarteSuiviDemandes`), `accueil_adulte`, `accueil_eleve` | Emplacement de la carte compacte |

## 2. Ce qui est créé

**Serveur** (`20261123960000_suivi_attente.sql`, aucun `DROP`, `DELETE`, `TRUNCATE`) :
- `suivi_attente_foyer()` : une ligne par demande du foyer, avec les cinq étapes, le délai, le cas particulier, la carte de l'enseignant selon S4 (seulement à l'étape 4, seulement si l'enseignant l'autorise).
- `teacher_profiles` : `montre_aux_familles` (vrai par défaut pour tous), `montre_aux_familles_confirme_le`, `pays_origine`, `pays_residence`, `mot_presentation`.
- `regler_presentation_aux_familles(...)` : l'enseignant règle sa visibilité, ses pays et son mot ; lui seul.
- Notification de l'enseignant à l'affectation enrichie (classe, nombre d'élèves, tranche, premier cours) et courriel activé pour `enseignant_affecte` (portées `classe`, `soi`, `foyer`) : c'est une trace, S5 et S8. Cela **amende** la décision du 01/11/2026 (« application seulement ») ; le directeur l'a demandé le 12/11.
- Gabarit de courriel de l'enseignant (fr, ar, en, es, pt).
- `20261123961000` : l'événement `tout_est_pret` dans la contrainte (mot d'effacement, collée par le directeur). `20261123962000` : notification et courriel « Tout est prêt » (déclencheurs différés, une notification par élève et par classe, verrou par classe), gabarits fr, en, ar, es, pt et push, `demandes_formation_depassees()`, colonnes de l'export.
- `app_config` : `formation_delai_jours` = 14, `formation_point_jours` = 7 (si absentes).
- Scénario `supabase/tests/scenarios_suivi_attente.sql`.

**Application** :
- `lib/core/attente_classe/` : modèle, port, adaptateur Supabase.
- `lib/features/attente_classe/` : l'écran (cinq états), la frise verticale, la carte de l'enseignant, la carte compacte d'accueil, la version simple de l'élève mineur, « Me présenter ».
- Routes ajoutées : `/tuteur/attente/:demandeId`, `/eleve/adulte/attente/:demandeId`, `/eleve/attente/:demandeId`.
- Textes fr et ar, préfixe `suiviAttente`.

## 3. Les cinq étapes et ce qui les franchit

| Étape | Mot | Franchie quand (fait serveur) |
|---|---|---|
| 1 | Demande reçue | événement `envoyee` |
| 2 | Classe en formation | en cours dès l'étape 1 ; franchie à l'étape 3 (pas de date propre : l'écran n'en invente pas) |
| 3 | Classe confirmée | événement `classe_creee` |
| 4 | Enseignant affecté | événement `enseignant_affecte` |
| 5 | Tout est prêt | étapes 3 et 4 franchies, l'élève membre actif de la classe et son enseignant en place (adhésion, **pas** l'événement `eleve_integre`, que la création d'une classe depuis un regroupement n'écrit pas : les membres entrent avant que la demande porte son groupe) et première séance connue. Pas de date propre : l'écran dit « Votre premier cours : le X » |

À l'étape 5, le tuteur (mineur) ou l'élève adulte reçoit « Tout est prêt » : application et courriel, jamais l'enfant (faits qui la rapprochent : classe active avec enseignant, adhésion de l'élève, première séance, demande affectée ; la fonction est idempotente).

Cas hors du chemin droit, chacun avec son état et son geste : demande refusée (motif et suite), demande retirée, classe en attente d'enseignant (`en_attente`), liste d'attente, changement de créneau (`creneau_change` récent).

## 4. Choix pris seul

- Le délai affiché est une date limite calculée à partir de la date de la demande et de `formation_delai_jours`. Dépassé, l'écran le dit et dit ce que fait l'académie ; il ne dit jamais « bientôt » quand une date est connue.
- Le réglage de l'enseignant vaut vrai pour tous (revue du 13/11) : seuls les pays et le mot qu'il a saisis apparaissent ; il ne masque pas la photo.
- Le mot de présentation est limité à 500 caractères, texte libre de l'enseignant, affiché sans modification.
- « Tout est prêt » : la notification part quand la première séance de l'élève, après son arrivée dans la classe, est à venir ; sans séance à venir (cours déjà passé), rien ne part. Un tuteur de plusieurs enfants dans la même classe reçoit une notification par enfant (le prénom de l'enfant n'est que dans le courriel, jamais dans le push).
- Le tuteur est redirigé de `/tuteur/demandes` vers le suivi seulement s'il n'a qu'un suivi en cours, visible et non clos : avec une demande ancienne terminée il garde sa liste.
- Les textes à la deuxième personne du singulier (`suiviAttente.tu`) servent l'enfant de 6 à 9 ans et le mineur de 10 à 17 ans ; l'arabe, déjà au singulier, reprend les mêmes mots.

## 5. Angles morts découverts

- Le gabarit de courriel `enseignant_affecte` n'avait pas de branche pour l'enseignant : s'il était parti, l'enseignant aurait lu le texte écrit pour la famille (« Voir la classe », `/tuteur/demandes`).
- La migration `0043` pose des tranches (`enfant_5_7`, `enfant_8_10`...) que des migrations ultérieures ont remplacées (`enfant_6_9`, `enfant_10_13`, `ado_14_17`) : lire la base rejouée, pas `0043`.
- L'accord de publication existant (CAND-PHOTO) vise le site public ; il n'est pas le réglage de ce lot et n'a pas été réutilisé.

## 6. Preuves (état au 13/11/2026, après fusion de `origin/main` 25f3ed78)

Rien ici n'est une preuve du directeur : ce sont des mesures locales (S9).

| Contrôle | Résultat |
|---|---|
| Rejeu SQL sur Postgres nu (utilisateur `postgres`, 437 migrations, tous les scénarios, une copie neuve chacun) | 278 verts, 0 rouge ; `scenarios_suivi_attente.sql` vert ; `scenarios_courriels_ux` et `scenarios_af_liste_blanche_volatiles` amendés (voulu) |
| `dart run slang` | généré, sans erreur |
| `dart run build_runner build --delete-conflicting-outputs` | terminé, sans erreur, aucun diff laissé |
| `dart analyze --fatal-infos` | No issues found |
| `flutter test` (suite complète) | 20805 réussis, 8280 ignorés (déjà ignorés sur `main`), 0 échec |
| `dart run tool/verifier_jetons.dart` | 1513 fichiers, aucune violation |
| `dart run tool/verifier_branchement.dart` | 2 fichiers non atteints, tous tolérés, aucun nouveau |
| `dart run tool/verifier_revue.dart` | 1066 violations antérieures au lot, 0 dans `suiviAttente` |
| Captures | 128 PNG, `docs/current/captures/E2E/suivi-attente/` (390 et 1440, clair et sombre, fr et ar), régénérées après les dernières corrections de texte |

Gardes du dépôt attrapées par la suite complète, corrigées : « Sauvegarde » de succès (arabe « تم الحفظ »), espaces insécables du français, « hors ligne » redit dans un texte, URL de photo passée à un portrait (désormais `PhotoEnseignant`), paramètres arabes isolés (U+2068/2069), domaine arabe déclaré.

Piège de rejeu : `tool/rejouer_scenarios.sh` échoue en arrière-plan (`nohup`) sur la migration `20261011121039_c29` (contrôle de propriétaire) et passe en premier plan, sous `postgres` ; cause non élucidée, étrangère au lot. À lancer en premier plan.

`.github/workflows/ci.yml` doit recevoir `scenarios_suivi_attente.sql` : zone interdite à ce lot, à faire par l'architecte.
