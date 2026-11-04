# Classes simultanées et montée en charge

**Directeur, 10/10/2026.** L'application doit tenir 500, 1 000 puis 10 000 élèves. Plusieurs classes du même fuseau, du même créneau et de la même catégorie font cours en même temps, chacune avec ses élèves et son enseignant. Exemple : 30 classes de garçons débutants le lundi à 18 h, heure de Paris.

Le directeur demande aussi de trouver et de traiter les contraintes que cette règle entraîne. Elles sont décidées ici par délégation (K-65). Ce document complète `DECISION-OFFRES-GROUPES-2026-10-09.md` et ne le remplace pas.

## 1. Principe

Une classe est identifiée par son `id`, jamais par son horaire ni par sa catégorie.

La **clé de regroupement** réunit ce qui rend des élèves compatibles :
- l'instant UTC, comparé aux deux saisons : Paris 18 h et Londres 17 h vont ensemble, New York 12 h à part ;
- les jours ;
- le genre, le public, la langue et le niveau.

Cette clé désigne une **famille de classes parallèles**, de 0 à N classes, jamais une classe unique.

## 2. Contraintes et règles décidées

| # | Cas | Règle |
|---|---|---|
| R1 | Unicité | Aucune contrainte d'unicité ni aucun `ON CONFLICT` sur l'horaire, l'offre ou la clé pour les classes. L'unicité porte sur les élèves et les enseignants (R5, R6). |
| R2 | Remplissage | Une nouvelle demande compatible va d'abord dans la classe ouverte la plus proche de son plafond (`app_config`) qui a encore de la place. Si toutes sont pleines, elle alimente un nouveau regroupement sur la même clé. |
| R3 | Découpage | Avec N demandes, minimum m et maximum M (valeurs d'`app_config`), on crée ⌊N/M⌋ classes pleines. Le reste devient une classe s'il atteint m ; sinon il attend dans le regroupement. On ne crée jamais une classe sous le minimum, sauf décision explicite de l'admin, qui est tracée. |
| R4 | Fratrie (corrigé par le directeur, 10/10) | Les enfants d'un même foyer sont **séparés autant que possible** : classes différentes et, si possible, enseignants différents. On ne les met ensemble que s'il n'existe aucune autre classe compatible, et le serveur trace ce regroupement forcé. L'admin voit les fratries réunies. Raison connue du directeur, non détaillée ici. |
| R5 | Élève | Un élève n'est jamais dans deux classes dont les séances se chevauchent. Contrôle côté serveur à l'intégration, au transfert et à l'acceptation d'une demande. |
| R6 | Enseignant | Un enseignant n'a jamais deux séances qui se chevauchent, remplacements compris. On ne refuse jamais une classe parce qu'une **autre** classe existe au même horaire. |
| R7 | Pénurie d'enseignants | Aux heures de pointe, la limite vient des enseignants. Une classe créée sans enseignant libre passe à l'état « en attente d'enseignant ». La famille est prévenue sans qu'on lui donne de délai inventé. L'admin voit, par horaire, l'écart entre la demande et l'offre d'enseignants (genre compris). |
| R8 | Concurrence | Pas de verrou global. On pose un verrou par clé de regroupement (`pg_advisory_xact_lock` sur le hash de la clé) et un verrou par enseignant à l'affectation. Les opérations sont idempotentes : si deux admins cliquent ensemble, on obtient une seule classe, un élève intégré une seule fois et un enseignant affecté une seule fois. |
| R9 | Attrition et fusion | Une classe qui passe sous le minimum est signalée à l'admin. L'admin peut la fusionner avec une classe parallèle de même clé qui a de la place. La fusion est atomique : membres transférés, enseignant libéré, historique conservé et chaque famille notifiée. Jamais de fusion automatique silencieuse. |
| R10 | Transfert | Le passage d'un élève vers une classe parallèle (changement de niveau, conflit, demande de la famille) est une action de l'admin. Elle est tracée, contrôlée par R5, et la famille en est notifiée. |
| R11 | Liste d'attente | Quand toutes les classes d'une clé sont pleines et qu'aucun enseignant n'est libre, l'attente se fait dans l'ordre des dates de demande. La famille voit qu'elle attend, sans voir son rang ni les autres familles. |
| R12 | Remplacement (corrigé par le directeur, 10/10) | Le remplaçant doit être libre à l'instant exact de la séance (R6) : c'est une règle stricte. Le genre est souple : le serveur propose d'abord les enseignants compatibles, mais l'**admin peut choisir** un enseignant de l'autre genre. Ce choix est explicite et tracé. Si personne n'est libre, la séance est annulée et les familles sont prévenues. Pas de « séance commune » improvisée entre deux classes. **Amendé le 31/10/2026 pour une séance commencée : voir l'amendement sous ce tableau.** |
| R13 | Cloisonnement | RLS et projections filtrent par `groupe_id`, jamais par horaire, offre ou clé. Un élève de la classe 3 ne voit rien de la classe 4 au même horaire : test négatif obligatoire. |
| R14 | Visio | Une salle LiveKit par séance (`session_id`), jamais par horaire. Les jetons doivent pouvoir être émis en rafale : 300 élèves à 18:00. Les limites de débit se règlent par utilisateur, pas globalement. La limite de salles simultanées du forfait LiveKit est vérifiée et notée. |
| R15 | Rafales | Les rappels et notifications de la même minute partent par lots, avec une clé d'idempotence par destinataire et par événement. Le webhook LiveKit traite les événements en double sans effet de bord. |
| R16 | Lisibilité | Les écrans admin, enseignant et contrôleur nomment une classe sans ambiguïté : catégorie · jours · heure locale · numéro dans la famille de classes, ou titre de l'enseignant. La famille ne voit que sa classe et le titre de l'enseignant (C-05), jamais le nombre de classes parallèles ni les autres élèves. |
| R17 | Volume | Toutes les listes admin, enseignant et contrôleur sont paginées côté serveur, avec filtres par horaire, catégorie, enseignant, taux de remplissage et état. Il y a des index sur les colonnes filtrées : `groupe_id`, état des demandes, colonnes de la clé, début des séances, enseignant. |
| R18 | Contrôle (corrigé par le directeur, 10/10, conforme à BR-CT-03) | **Le contrôleur ne choisit jamais sa classe**, pour empêcher toute connivence ou corruption. Le serveur tire au sort une mission parmi les séances en direct, selon les règles de la direction : pondération, classes à cibler, fréquence. Le contrôleur voit zéro ou une mission. Avec N séances simultanées et plusieurs contrôleurs, le tirage est atomique (`FOR UPDATE SKIP LOCKED`) : un seul contrôle par classe (BR-CT-18), jamais la classe du contrôleur s'il enseigne aussi (BR-CT-02), aucun motif prévisible (pas le même enseignant chaque semaine à la même heure). L'enseignant ne sait pas à l'avance qu'il sera contrôlé. Une mission non contrôlée est signalée (BR-CT-15). Le tirage est audité ; la direction voit l'historique, le contrôleur ne voit que sa mission. |
| R20 | Suivi « comme une livraison » (directeur, 10/10) | Chaque famille voit, pour chaque demande et chaque enfant, une barre de progression linéaire : demande envoyée → (liste d'attente s'il y a lieu) → classe créée → enseignant affecté → élève intégré → début des cours. Les étapes franchies portent leur date et l'intervalle écoulé entre deux étapes ; l'étape en cours est mise en avant. Une date future n'apparaît que si elle est connue, comme celle de la première séance : jamais d'estimation inventée. Le serveur fournit l'horodatage de chaque étape. Ni rang ni autres familles. |
| R19 | Tableau de bord | L'admin voit, par horaire, le nombre de classes, leur taux de remplissage, les demandes en attente et les enseignants libres ou manquants. |

### Amendement de R12, décision du directeur du 31/10/2026 (relayée par le pilote)

R12 vaut pour un remplacement **prévu à l'avance** (absence déclarée avant la séance). Pour une
**séance commencée** dont le titulaire n'est pas entré dans la salle, le déroulé suivant prévaut,
et **on n'annule pas**. Toutes les minutes comptent depuis le début de la séance ; chacune est un
réglage `app_config`, jamais une valeur écrite dans le code (valeurs posées le 31/10, à confirmer
par le directeur) :

1. **T+3** (`remplacement.avertissement_minutes`) : le titulaire est prévenu que, s'il n'entre pas
   dans les 5 minutes, il perd l'accès à la séance de ce jour. En même temps, une pré-alerte part
   aux enseignants compatibles (genre, dossier validé, libres à cette heure) : « un remplacement
   se prépare ». Un enseignant peut se déclarer prêt ; le premier prêt est retenu (atomique).
2. **T+8** (`remplacement.perte_acces_minutes`) : si le titulaire n'est toujours pas entré,
   l'absence est posée automatiquement (origine `auto`). Le titulaire perd l'accès à cette séance
   et reste titulaire de la classe. L'enseignant prêt devient remplaçant ; sans enseignant prêt,
   l'offre reste ouverte et le premier qui la prend devient remplaçant. Les familles, les élèves
   et la direction sont prévenus : le professeur titulaire est en retard, l'académie cherche un
   remplaçant, restez dans la salle.
3. **T+11** au plus (`remplacement.debut_remplacant_minutes`) : c'est le but, le remplaçant est en
   séance.
4. **On n'annule pas.** L'offre reste ouverte jusqu'à la fin prévue de la séance. Dès qu'un
   remplaçant prend la séance, familles et élèves reçoivent : un remplaçant arrive, restez dans la
   salle. Si la fin arrive sans remplaçant, rien de neuf : la clôture automatique existante
   s'applique.
5. Si le titulaire entre entre T+3 et T+8, la pré-alerte se clôt et l'enseignant prêt reçoit
   « remplacement inutile ».

Mise en œuvre : `supabase/migrations/20261102500000_remplacement_auto.sql`, preuve
`supabase/tests/scenarios_remplacement_auto.sql`. Le message dans la salle d'attente elle-même
n'est pas posé (zone de la salle tenue par un autre lot) : familles et élèves le reçoivent par la
notification et l'e-mail.

## 3. Preuves exigées

**Backend (ChatGPT), scénarios SQL :**
- 2 000 demandes synthétiques sur 3 fuseaux. On vérifie le nombre de classes attendu par R3, aucune au-dessus du plafond et aucun élève en double. On mesure le temps et on le consigne.
- Deux sessions SQL concurrentes sur la même clé : une seule classe créée, aucun doublon.
- Même enseignant affecté en parallèle à deux classes simultanées : un refus.
- Élève dans deux classes qui se chevauchent : refus.
- Fusion et transfert : atomiques, et notifiés.
- Cloisonnement entre deux classes parallèles : négatif.
- Rafale de 300 jetons et de 300 rappels : idempotence vérifiée.

**Écrans (Claude) :**
- R16, R17, R18, R19 ;
- états « en attente d'enseignant » et « liste d'attente » côté famille ;
- fusion et transfert côté admin et côté famille ;
- 5 états, 320 px, texte ×2, RTL.
