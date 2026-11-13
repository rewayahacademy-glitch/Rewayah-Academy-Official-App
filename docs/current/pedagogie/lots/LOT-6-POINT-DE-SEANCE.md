# Lot 6 · POINT-DE-SEANCE

> Branche `claude/point-de-seance`, ouverte le 13/11/2026 sur `claude/socle-programme` (lot 1) + `main`.
> Plan : `PLAN-DE-CONSTRUCTION.md`, section « Lot 6 ». Charte, partie 5 ; moteur, règle 35 ; arbitrages n° 96, 97, 101, 104, 105, 107.
> Statut : **présent dans le code, testé localement, NON installé, NON prouvé en production.**

## D'abord : ce qui est faux, bloqué ou non prouvé

1. **La paie attend toujours le cahier.** En production depuis le 12/11 (coupure C3), la paie d'une séance attend un `lesson_reports` de cette séance (`private.cahier_semaine_couvert`). Ce lot n'écrit rien dans `lesson_reports` et ne touche aucune fonction de paie : tant que le raccord n'est pas décidé, l'enseignant fait le point **et** le cahier. Le raccord proposé (non codé) est décrit plus bas.
2. **Le lot 5 (PLAN-DE-CLASSE) n'existe pas.** Donc : pas de « séance prévue », pas de « Vu comme prévu / On a vu moins / On a vu plus », pas de glissement du plan, pas d'objectif principal, pas de passage tiré dans les données (la page dit seulement « un passage déjà vu, hors de la leçon du jour » ; l'enseignant le choisit). L'observation est rattachée à la séance et à **l'étape** de l'élève, pas à un objectif.
3. **La sortie de la salle mène encore au cahier** (son bouton dit « Ouvrir le cahier », et la paie l'attend). Le point s'ouvre depuis la liste « À terminer » de l'enseignant. Tant que ce n'est pas changé, l'application ne « pose » pas la question à la fin de la séance : elle la garde dans « À terminer ».
4. **Aucun message.** Ni notification, ni push, ni courriel (règle 35 : lot 11). Le tuteur voit « À renforcer » et le travail en ouvrant l'Historique.
5. **Le travail ciblé n'est pas écrit dans `learning_assignment`** (la table exige un document) : il est déduit par le serveur et lu dans le hub. « Stable » n'est pas calculé (lot 8). Règles 14, 18, 24, la revue des « Pas eu le temps » répétés et la consolidation commune : lot 13.
6. **La direction n'a pas d'écran pour changer les trois réglages** : ils se changent dans `app_config` (SQL).
7. **Arabe de contenu** : ce lot n'affiche aucune lettre, mot, sourate ni verset ; le critère de police (UthmanicHafs) est sans objet ici. Le mot arabe du point, « ملخّص نهاية الحصة », est une proposition.
8. Chez le tuteur et l'élève, la liste des séances existante reste dessous ; le bloc n'y montre que les séances qui ont une réponse, pour ne pas redire la présence.

## Ce que le lot crée

- **Tables** (RLS activée, aucun droit direct, écrites par fonction seule) : `point_seance` (une ligne par séance : qui, quand, élève tiré, note), `point_seance_eleves` (une ligne par élève **présent** : réponse, tiré ou non, étape du moment), `point_seance_journal` (chaque envoi).
- **Fonctions** : `point_seance_lire`, `point_seance_envoyer`, `points_seance_a_faire` (enseignant de la séance, titulaire ou remplaçant ; la direction lit) ; `historique_seances_eleve` (le hub).
- **Réglages** (`app_config`) : `point_seance.modifiable_heures` (24, **proposé** : la charte ne donne pas de valeur), `point_seance.a_suivi_par_semaine` (1, `REGLAGES.md`), `point_seance.debut` (l'instant de l'installation : les séances d'avant n'attendent aucun point).
- **Écran neuf** : la page « Point de fin de séance » (`/enseignant/seance/:id/point`).
- **Un composant** : `BlocHistoriqueSeances`, posé en raccourci dans la fiche de l'élève chez l'enseignant, l'onglet Historique du tuteur, le Suivi de l'élève, et le menu d'un élève dans la fiche de classe de la direction.

## Les règles appliquées

- Présents = présence mesurée (`private.presence_temps_reel` = `presente`). Un absent ou un présent en partie n'a pas de ligne : jamais un « A suivi » ni un « À renforcer » pour lui.
- Tous les présents sont « A suivi » par défaut ; un toucher pour « À renforcer ».
- Un élève tiré par séance, à tour de rôle (le premier présent, dans l'ordre d'entrée dans la classe, qui a attendu le plus longtemps) ; il n'a pas de défaut : « Acquis », « À renforcer », ou « Pas eu le temps de l'écouter » (qui envoie le point, n'écrit aucune observation et le garde en tête). Sans réponse pour lui, le serveur refuse l'envoi. Pas de tirage à la toute première séance tenue de la classe (approximation de « la première séance de l'étape 1 », faute de plan).
- Rattrapage : la séance reste dans « À terminer » tant que le point manque. Correction possible pendant le délai réglable ; l'élève tiré et la liste des élèves ne changent pas à la correction.
- Ce que le serveur déduit, par étape : « Acquis » (chaque toucher compte ; un « A suivi » par défaut compte au plus N fois par semaine) ; « À renforcer » (le dernier point de l'élève) ; « deux de suite » (enseignant et direction seulement) ; le travail (« relire » ou « ciblé »).
- Qui lit quoi : enseignant de la classe, remplaçant dans sa fenêtre, direction : tout, note comprise. Tuteur, adulte, élève de 10 ans et plus : « A suivi » ou « À renforcer » et le travail, jamais la note, le tirage ni « deux de suite ». Le compte d'un enfant de 6 à 9 ans : refusé par le serveur.
- Aucune colonne de motif, de santé, de religion ni d'argent.

## Le cahier : ce qui est retiré, ce qui reste

Rien n'est retiré (lot 9). Restent : la saisie du cahier, la position de reprise, la coche des sourates, la liste « Cahiers à remplir ». Aucun écran neuf ne lit le cahier.

## La paie : effet exact et proposition (NON codée)

Aujourd'hui : la paie d'une séance commencée depuis le 12/11 est « en attente du cahier » tant qu'aucun `lesson_reports` n'existe pour cette séance.

Proposition : à l'envoi du point, le serveur insère un `lesson_reports` minimal pour la séance (`content = {"point_seance": true, "eleves": [{"student_id": …}]}`), sans toucher aucune fonction de paie. Effets : (a) la paie de la séance est libérée par le point, plus par le cahier ; (b) la séance sort de « Cahiers à remplir » ; (c) le déclencheur `seance_terminee_avis_cahier` envoie l'avis « séance terminée » aux familles à ce moment-là, sans travail à la maison ; (d) les déclencheurs des observations C3, des exceptions de présence et des sourates ne font rien (le contenu n'a pas ces champs). Dans le même geste : la sortie de la salle et le bouton de la carte de séance mènent au point.

## Preuves

- SQL : `supabase/tests/scenarios_point_de_seance.sql`, 71 contrôles (droits par rôle, mineurs, rejouabilité, mutations rouges, paie intacte), sur Postgres 16 nu après toutes les migrations ; la migration est rejouée deux fois sans erreur ; le scénario échoue sans la migration.
- Flutter : `test/features/point_seance/point_seance_test.dart`, 23 tests par le vrai routeur.
- Captures : `docs/current/captures/E2E/point-de-seance/` (français et arabe, 390 et 1440, clair et sombre).

## Ordre d'installation

Migration `20261125000000_point_de_seance.sql` **avant** la fusion (elle ne change rien de visible : tables et fonctions neuves). Entre la migration et la fusion : rien ne change pour personne. Si la fusion passe avant la migration : la page du point dit qu'elle n'a pas pu être lue, « À terminer » affiche une ligne « n'ont pas pu être lus », et les blocs d'historique affichent une ligne d'échec ; rien n'est perdu.
