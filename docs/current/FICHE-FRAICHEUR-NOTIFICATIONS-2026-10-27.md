# Fiche « Fraîcheur et notifications » (27/10/2026)

Autorité : décision du directeur du 27/10/2026, carte blanche au pilote. Cette fiche
suit `docs/orchestration/CONTRAT-ECRAN-2026-10-26.md` : une ligne = un fait = un test.
Elle prévaut sur tout écran qu'elle touche. La salle (`/salle`) n'est pas touchée.

## Pourquoi

Dans la salle, la page du Coran partagée par l'enseignante apparaît chez l'élève
sans geste, parce que le serveur pousse le changement (canal de données LiveKit et
abonnement Realtime sur le support actif). Partout ailleurs, l'application demande
une fois à l'ouverture de l'écran et garde la réponse en mémoire : une classe créée
par l'administration n'apparaît chez l'élève qu'après déconnexion et effacement de
l'historique. Constat du directeur, vérifié dans le code le 27/10 :

- un seul abonnement Realtime dans l'application (support actif de la séance) ;
  trois tables publiées en base, aucune de celles des classes ;
- aucun écran ne se rafraîchit en tirant vers le bas ; les rafraîchissements du
  code ne jouent qu'après une action de la même personne, sur le même appareil ;
- une base locale (profils du foyer, séances à sept jours, ressources, préférences)
  et la mémoire ne sont jamais vidées à la déconnexion ;
- la table `notifications` existe (migration 63), le serveur y écrit pour une
  classe créée depuis un regroupement, un enseignant affecté, une classe changée,
  un remplacement ; un courriel part pour chaque ligne (23/10). En production au
  27/10 : 11 classes, 7 inscriptions, 48 séances, **0 notification**. Les classes
  ont été créées par un chemin qui ne notifie pas ;
- la cloche et la page Notifications existent, posées sur le seul accueil adulte,
  lues une fois à l'ouverture.

## Règle unique

Quand quelque chose change pour moi sur le serveur, je suis prévenu dans
l'application et par courriel, et ce que je vois est à jour en moins de 3 secondes,
sans rien faire.

## Lignes

### A. Fraîcheur

1. Toute donnée affichée sur un écran de classe, d'accueil, de planning ou de
   notifications qui change sur le serveur se met à jour sur tout appareil connecté
   en moins de 3 secondes, sans geste de la personne.
2. Un appareil sans réseau au moment du changement se met à jour dans les 3 secondes
   qui suivent le retour du réseau.
3. Aucun écran n'exige de se déconnecter, de recharger la page ou d'effacer
   l'historique pour voir une donnée à jour.

### B. Classes, inscriptions, séances

4. L'administration crée une classe avec un élève : l'accueil de l'élève et celui du
   tuteur du foyer montrent la classe dans les 3 secondes.
5. L'administration ajoute ou retire un élève d'une classe : la classe apparaît ou
   disparaît chez l'élève et le tuteur dans les 3 secondes.
6. L'administration change le créneau d'une classe : l'horaire change dans les
   3 secondes partout où il est affiché (accueil, planning, classe, enseignant).
7. L'administration supprime une classe : elle disparaît partout dans les
   3 secondes ; si la personne avait l'écran de cette classe ouvert, elle lit
   « Cette classe n'existe plus. » et revient à son accueil.
8. L'administration affecte ou change l'enseignant : la nouvelle enseignante voit la
   classe dans ses classes, l'ancienne ne la voit plus, dans les 3 secondes.
9. Une séance créée, annulée ou déplacée par l'administration ou par la cloche se
   reflète dans les 3 secondes sur le planning de l'élève, du tuteur et de
   l'enseignante.

### C. Notifications dans l'application

10. Chaque changement des lignes 4 à 9 crée une notification pour chaque personne
    concernée (élève, tuteur du foyer, enseignante), quel que soit le chemin par
    lequel l'administration a agi : écran des groupes, regroupement, ou cloche.
11. Événements couverts : classe créée, enseignant affecté ou changé, élève inscrit
    ou retiré, créneau changé, séance annulée, séance déplacée, enseignante absente
    ou remplacée, classe supprimée. Les événements déjà présents sont conservés, les
    manquants sont ajoutés.
12. La cloche avec son point de non-lus est présente sur l'accueil de l'élève adulte,
    du tuteur et de l'enseignante. Le point apparaît dans les 3 secondes après
    l'événement, sans geste. L'élève mineur n'a pas de cloche (réponse Q5 du
    directeur du 04/10, maintenue le 27/10) : le tuteur de son foyer est prévenu.
13. Chaque notification dit le fait en une phrase du vocabulaire de l'académie
    (compétence `mots-rewayah`), en français et en arabe, et son ouverture mène à
    l'écran concerné.
14. Ouvrir la page Notifications marque les notifications lues ; le point disparaît
    sur tous les appareils de la personne dans les 3 secondes.
15. Un courriel part pour chaque notification, une fois, à l'adresse du destinataire
    quand elle est connue. Le mécanisme du 23/10 est conservé, pas dupliqué.

### D. Déconnexion

16. « Se déconnecter » ferme la session en moins de 2 secondes, même sans réseau :
    la session locale est fermée d'abord, le serveur est prévenu ensuite si le
    réseau le permet.
17. La déconnexion vide la base locale et la mémoire de l'application ; l'écran
    d'entrée ne montre rien de la personne précédente.
18. Se connecter ensuite avec un autre compte montre les données de ce compte
    seulement.

### E. Preuve

19. Chaque ligne est un test à deux appareils : l'administration sur l'ordinateur,
    l'élève ou l'enseignante sur le téléphone. Le directeur fait la preuve sur
    l'aperçu Vercel, puis en production après fusion et après collage des
    migrations.

### F. Limites de cette fiche

20. Pas de notification sur l'appareil lui-même (push) : clés Apple et Google,
    autorisation de la personne, lot à part, sur la liste d'attente.
21. Le poids du démarrage n'est pas changé par cette fiche : il est mesuré d'abord
    (liste d'attente, mesure sur téléphone et iPad), décidé ensuite.
22. Les migrations de cette fiche s'appliquent en production par le directeur, par
    une page privée faite avec `tool/page_migrations/generer.py`, avec celles qui
    attendent déjà (`docs/orchestration/PASSATION-PILOTE-2026-10-26.md`).

## Arbitrages du pilote (27/10)

- Mécanisme : Supabase Realtime (changements Postgres sous RLS) sur les tables des
  classes, inscriptions, créneaux, séances et notifications, un seul service de
  veille ouvert après connexion, qui invalide les lectures concernées. On étend ce
  qui existe dans la salle, on n'invente rien.
- Granularité : un changement sur une table invalide toutes les lectures de cette
  famille pour la personne. Simple et juste ; l'optimisation attendra une mesure.
- Les notifications sont écrites par le serveur (déclencheurs sur les tables), jamais
  par l'application, pour couvrir tous les chemins (ligne 10).
- Déconnexion locale d'abord (ligne 16) : standard des applications grand public ;
  l'attente du serveur ne doit jamais bloquer la sortie.

## État (27/10/2026)

| Lignes | Spécifié | Présent dans le code | Prouvé par le directeur |
| :--- | :--- | :--- | :--- |
| 1 | 27/10 | partiel : veille Realtime (classes, séances) montée avec la session, lectures du tuteur, de l'élève et de l'enseignante invalidées ; écrans de l'administration hors de la veille (lot suivant) | non |
| 2 | 27/10 | fait : au retour du réseau, nouvelle écoute et relecture de tout ; canal rejoint = relecture de tout | non |
| 3 | 27/10 | fait par construction (aucun geste requis) | non |
| 4, 5, 6, 8 | 27/10 | fait : `groupes`, `groupe_membres`, `groupe_creneaux` publiés (migration 20261027100000) ; tout changement fait relire les classes | non |
| 7 | 27/10 | fait : « Cette classe n'existe plus. » (FR, AR) et retour à l'accueil du rôle ; testé chez le tuteur, codé sans test widget chez l'enseignante | non |
| 9 | 27/10 | fait : `sessions` publiée ; tout changement fait relire suivi, planning, prochaine et dernière séance, journée, roster, cahiers | non |
| 10, 11 | 27/10 | fait, testé localement : migration 20261027120000 (douze événements, `private.notifier_classe`, déclencheurs différés à la validation sur `groupes`, `groupe_membres`, `groupe_creneaux`, `sessions`, `remplacements_seance` ; une notification par personne et par fait, jamais deux dans la même transaction, y compris face à 0066, 0078, 0085, c11bis, fusion, b09) ; scénario `scenarios_notifications_classes.sql` vert sur Postgres 16 local après toutes les migrations (la CI a Postgres 17 ; ligne à ajouter dans `ci.yml` par le directeur) ; 0 ligne en production tant que la migration n'est pas collée | non |
| 12 | 27/10 | fait, testé localement : cloche de la coquille du tuteur, de l'enseignante et du contrôleur, point de non-lus d'un seul provider (`nonLuesProvider`) dérivé de la liste, relu par la veille Realtime quand la table `notifications` change (publiée par 20261027120000) ; tests widget sur l'accueil du tuteur et la journée de l'enseignante (point présent, absent) ; l'élève mineur n'a pas de cloche (Q5 du 04/10 maintenue) ; **l'élève adulte n'a pas encore de cloche posée** (sa page d'accueil en prévoit une, aucun chemin ne la branche : à décider) | non |
| 13 | 27/10 | fait, testé localement : phrase FR et AR par événement, selon la portée (élève, tuteur, enseignante) et l'heure locale de la séance ; destination par rôle (accueil de l'élève, classe ou planning du tuteur, classes ou journée de l'enseignante) ; événement inconnu rendu par une phrase de repli, jamais perdu | non |
| 14 | 27/10 | fait, testé localement : ouvrir la page marque tout lu (UPDATE `lu_le`, politique 0063) et relit la liste ; la disparition du point sur l'autre appareil passe par la veille (`notifications` publiée), testée avec un canal simulé seulement | non |
| 15 | 27/10 | oui (déclencheur du 23/10, conservé) : le scénario vérifie une ligne `courriels_sortants` par notification, aucune pour un compte enfant ; jamais déclenché en production | non |
| 16 | 27/10 | fait : session locale fermée d'abord (`signOut` portée locale, serveur prévenu sans être attendu) ; avant, 3 s pour envoyer les cahiers en file, puis choix « Annuler » ou « Se déconnecter quand même » s'il en reste | non |
| 17 | 27/10 | fait : profils, séances, ressources et rapports retirés de la base locale (les réglages de l'appareil restent), portée des providers renouvelée | non |
| 18 | 27/10 | fait par construction (providers neufs), non prouvé à deux comptes | non |

## Journal

- 27/10 : fiche écrite après le constat du directeur (classe créée invisible chez
  l'élève sans effacer l'historique ; notifications attendues pour classe, créneau,
  absence de l'enseignant) et l'inventaire du code et de la production.
- 27/10 : lot 1 (lignes 1 à 9, 16 à 18) poussé sur la branche du pilote ; migration
  rejouée sur un Postgres jetable avec et sans publication, chaîne verte.
- 27/10 : choix sans `replica identity full` : avec lui, une suppression enverrait la
  ligne entière à tous les abonnés hors RLS ; la clé primaire seule suffit à relire.
- 27/10 : limites admises : administration hors de la veille, ligne 7 enseignante sans
  test widget, scénario SQL à lister dans la CI par le directeur, double base locale le
  temps d'une frame en debug, rien de prouvé sur un appareil.
- 27/10 : revue de la PR 63 : vidage de la base locale avant la fermeture de session ;
  une file de cahiers illisible refuse la déconnexion au lieu de la laisser passer.
- 27/10 : Q5 du 04/10 maintenue par le pilote : l'élève mineur n'a pas de cloche ; le foyer
  est prévenu. La ligne 12 se lit « accueil de l'élève adulte ».
- 27/10 : lot 2 (lignes 10 à 15), un seul agent, non poussé tant que le pilote ne l'a pas
  écrit. Choix : déclencheurs **différés à la validation** (constraint triggers), qui lisent
  l'état final de la transaction ; c'est ce qui donne une seule notification « classe créée »
  par personne quand l'administration crée la classe avec ses élèves et ses créneaux, et qui
  évite une seconde ligne quand un chemin plus ancien (classe_validee, enseignant_affecte de
  c11bis, classe_changee de la fusion) a déjà prévenu la même personne du même fait dans la
  même transaction. L'absence de l'enseignante ne passe par aucune des quatre tables de la
  fiche : un déclencheur sur `remplacements_seance` prévient les familles (b09 garde les
  enseignants). La migration contient deux DROP CONSTRAINT (les deux CHECK se remplacent,
  comme c29 et FAC-F ; une contrainte CHECK ne se modifie pas autrement) ; les déclencheurs
  se créent sous garde, sans DROP : la page de collage marquera le fichier, rien n'est effacé. `20261027100000` reçoit BEGIN;/COMMIT;
  pour la page de collage, sans autre changement.
- 27/10 : limites admises du lot 2 : rien de prouvé sur un appareil ni en production ; la
  disparition du point « sur l'autre appareil » n'est testée qu'avec un canal simulé ; la
  liste des notifications n'a plus de relance automatique Riverpod (elle se relit par la
  veille, par « Réessayer » et après une lecture) ; l'élève adulte n'a toujours pas de cloche
  branchée (aucune route de notifications sous `/eleve`) ; un événement inconnu est affiché par une phrase de repli au lieu d'être
  ignoré (le test « skips unknown events » de l'adaptateur change de sens) ; Postgres 16 en
  local, 17 en CI.
