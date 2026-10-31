# UX_REVIEW_REMPL-1 : écran « Remplacements » commun aux enseignants

Date : 09/10/2026. Lot : REMPL-1 (demande du directeur du 01/10, précisée le 09/10).
Liens : ALERTE-1 (alerte urgente en tête), LIB-ABS-1 (« Signaler mon absence à cette
séance », côté enseignant absent), DISPO-1.

## Demande du directeur (source des libellés)

- Écran dédié, commun à tous les enseignants, premier arrivé, premier servi. C'est la
  destination de « Voir tout : les N remplacements confirmés » de la Journée
  (`/enseignant/journee/remplacements`).
- L'alerte est une urgence, en haut, visuel distinct.
- Titre explicite : « Remplacement urgent : {jour} {heure} », puis la ligne
  « Un enseignant est absent. Assurez cette séance à sa place : elle vous sera payée après validation en fin de mois. »
- Offres visibles seulement aux enseignants du bon genre (décision du 02/10 : classe
  d'hommes vers un enseignant, de femmes vers une enseignante, indéterminée vers tous).
  Le filtre est **côté serveur** ; l'écran ne lit aucun genre.
- Le premier qui accepte prend la séance ; les autres voient l'offre prise.

## Libellés ajoutés (`enseignant.remplacements`)

Délégation du 02/10 (« le reste tu te débrouilles pour le bien de l'académie ») pour les
libellés qui ne sont pas mot pour mot dans la demande :

- Titre : « Remplacements »
- Contexte (K-58) : « Ouverts à tous les enseignants : le premier qui accepte assure la séance. »
- Titre d'alerte : « Remplacement urgent : {jour} {heure} »
- Ligne d'alerte : « Un enseignant est absent. Assurez cette séance à sa place : elle vous sera payée après validation en fin de mois. »
- Section : « Vos remplacements »
- Section : « Déjà pris par un collègue »
- Pastille : « Pris par un collègue »
- Refus de la seconde acceptation (K-59) : « Un collègue a accepté cette séance juste avant vous. Rien n'a changé dans votre planning. »
- Confirmation : « C'est confirmé : vous assurez cette séance. Elle s'ajoute à vos remplacements. »
- Échec serveur (K-59) : « Les remplacements à assurer n'ont pas pu être chargés : le serveur n'a pas répondu. Réessayez dans un instant. »
- Hors ligne sans données (EA-HL-DOUBLE-1, dit ce qui manque) : « Les remplacements à assurer n'ont pas pu être chargés »

Repris sans changement : « Assurer ce remplacement », « La demande n'a pas abouti.
Réessayez dans un instant. », « Aucun cours d'un collègue à assurer pour le moment. ».

## Contrôle UX

| Proposition | Règle et source | Conclusion | Conséquence dans l'écran |
| :--- | :--- | :--- | :--- |
| Alerte urgente en tête | `lib/CLAUDE.md` « une alerte urgente va toujours en tête » (ALERTE-1) ; Nielsen n° 1, visibilité de l'état | conforme | Les offres ouvertes sont le premier bloc, la plus proche d'abord |
| Visuel distinct | WCAG 2.2 SC 1.4.1 (jamais la couleur seule) ; Material 3, rôles de couleur d'erreur atténués | ajustée | Trois signaux : surface `washAlert` à contour fort, icône d'avertissement, mot « urgent » dans le titre ; jamais d'aplat saturé |
| Un seul bouton plein | K-56 ; DESIGN-GOV §4 bis.2 règle 1 | ajustée | Bouton plein sur l'offre la plus proche, secondaire sur les suivantes ; il passe à la suivante quand la première est prise |
| Détails avant l'engagement | UX_REVIEW_04 ligne 15 a ; Baymard (prévention d'erreur) ; Nielsen n° 5 | conforme | Classe, date, heure locale, durée, élèves (`lignesRemplacement`) avant le bouton ; pas de feuille de confirmation en plus, la carte est déjà la relecture |
| Premier arrivé, premier servi | Règle métier (le serveur tranche) ; DESIGN-GOV §4.3 | conforme | Pendant l'envoi le bouton porte son chargement (jamais grisé) ; refus : phrase en zone annoncée, offre déplacée dans « Déjà pris », sans bouton |
| Sans réponse | E7 ; K-59 | conforme | Rien n'est supposé, la phrase d'échec s'affiche, le bouton reste |
| États | 03 §États ; DESIGN-GOV §4 bis.6 | conforme | `Skeleton` dans `BlocAsynchrone`, contenu, `EmptyState`, `EtatSysteme` avec « Réessayer », hors ligne par le bandeau de `PageShell` seul (bloc `EtatSansDonnees` seulement sans données) ; les remplacements confirmés restent sous un échec (D11) |
| 320 px, texte ×2 | WCAG 2.2 SC 1.4.4 et 1.4.10 ; COUPE-MOTS-1 | conforme | Titres en `TexteSansCoupure`, pastille sous le nom quand la ligne manque (`OverflowBar`) ; test LTR et RTL |
| Capacité, pas rôle | invariant `CLAUDE.md` | conforme | Le bouton n'existe que si le port est présent et que le serveur dit l'offre `ouverte` |

## Besoin serveur (ligne Backend proposée)

Port `lib/core/enseignant/port_remplacements.dart` : flux des offres visibles par
l'enseignant connecté, **filtrées par genre côté serveur** (genre de la Classe et genre
de l'enseignant lus en base, jamais transmis au client), avec l'état `ouverte` /
`priseParMoi` / `priseParUnCollegue` (sans le nom du collègue, sans motif d'absence) ;
RPC d'acceptation **atomique** (premier arrivé : verrou ou `update ... where
remplacant is null returning`), qui rend `acceptee` ou `dejaPrise` et refuse une offre
invisible pour l'appelant comme `dejaPrise` ; diffusion temps réel de la prise aux autres
enseignants ; la séance assurée entre dans la paie après validation de fin de mois (calcul
serveur).

## Côté direction (31/10/2026, finir REMPL-1)

Demande du directeur relayée par le pilote le 31/10 : raccorder `designer_remplacant_admin`
là où la direction voit déjà les séances, et montrer les remplacements par enseignant. Aucun
nouvel écran : tout vit dans le **Planning** de la direction (`features/admin_planning`).
Serveur : `20261102400000_remplacements_direction.sql`.

| Proposition | Règle et source | Conclusion | Conséquence dans l'écran |
| :--- | :--- | :--- | :--- |
| Le geste part de la ligne de la séance | LISTES-1 (`DECISION-LISTES-2026-10-23.md`) : actions d'une ligne par `MenuActions` ; Fitts (l'action près de l'objet) | conforme | Menu « … » de la ligne, une entrée « Désigner un remplaçant pour cette séance de … » ; absent sur une séance passée, annulée ou déjà remplacée (jamais grisé) |
| R12, libre à l'heure exacte | `DECISION-CLASSES-SIMULTANEES-2026-10-10.md` R12 (règle stricte) | conforme | La feuille ne liste que ce que rend `remplacants_possibles_seance` ; le serveur rejuge à l'envoi (`RemplacantOccupe` : phrase, liste relue) |
| R12, genre souple sur choix explicite | R12 ; K-58 (la conséquence se dit avant le choix) | ajustée | L'enseignant de l'autre genre reste visible, après les autres, avec sa mention ; une fois choisi, une phrase le dit et le bouton devient « Désigner ce remplaçant malgré le genre » ; le serveur trace `choix_hors_genre` |
| Un seul bouton plein | K-56 | conforme | `BasDeFeuille` seul ; hors ligne, une phrase à sa place |
| Bilan sans seuil | consigne du pilote (« la décision reste à la direction ») ; Nielsen n° 1 | conforme | Section « Remplacements de la semaine » sous les jours, une ligne par titulaire et par classe, trois nombres ; aucune couleur d'alerte, aucun classement de « mauvais » enseignant |
| Échec | K-59 | conforme | Échec du bilan : `EtatSysteme` avec « Réessayer » ; échec de la liste : celui de `SelecteurPersonne` |

Limite à signaler : confier une classe qui a déjà un enseignant à un autre enseignant n'a
**aucune RPC** (`affecter_enseignant_classe_c11bis` rend `deja_affecte`). Le bilan mène à la
page Classes (« Voir les classes »), sans geste de réaffectation : décision du directeur à
prendre avant de l'écrire.
