# Lot LETTRE-CANDIDATS : la lettre de vérité aux candidats enseignants (ouvert le 20/11/2026)

**Statut : À LIVRER. Rien n'est dans l'application.** Le texte français est écrit et en relecture
(`LETTRE-fr.md`) ; aucune page, aucune traduction, aucune migration n'existe.

## L'ordre du directeur (20/11/2026)

> « je veux leur écrire aujourd'hui car jusqu'à présent ils se sont inscrits mais n'ont aucune info
> sur leur salaire, le nombre de cours. » […] « en lisant ce document les candidats doivent être
> définitivement capable de savoir s'ils vont ou pas continuer avec nous. »

> « tu écris dans le dépôt nécessaire pour que ça ne soit pas oublié […] toi tu devras le créer ce
> texte en forme de site interne que les candidats verront dans l'espace d'attente, mais aussi dans
> l'espace enseignant. » Praxis animé dans la page « pour aider à détendre l'atmosphère, pointer les
> endroits pour guider ». « s'il dit que la page n'est pas prête alors tu crées d'abord le mini site
> en dehors, tu me montres sa maquette et tu attends la page pour transporter et brancher. »

## Ce qui reste à faire, dans l'ordre

1. **Validation du texte français** par le directeur (document de travail cité dans `LETTRE-fr.md`).
   Ensuite seulement, le texte entre dans `docs/current/TEXTES-VALIDES/`.
2. **Le mini-site interne** : une page longue, la page défile (`DECISION-DEFILEMENT-2026-11-01.md`),
   un sommaire qui mène à chaque partie, Praxis animé qui accueille et pointe les passages importants
   (paie, attente d'une classe, retard, pièce d'identité). Un seul Praxis : `lib/core/vivant/praxis_vivant.dart`
   et la compétence `praxis-rewayah` ; on ne le redessine pas.
3. **Où la page se branche** (interface : session « Parcours candidat enseignant ») :
   - espace d'attente du candidat : la rubrique « À savoir » de l'onglet Messages existe depuis #662
     (`lib/features/candidature/a_savoir_candidat.dart`, emplacements `paie`, `cours`, `entretiens`,
     vides et prévus pour ce contenu). Ne pas créer une seconde rubrique ;
   - espace enseignant : emplacement à choisir avec la même session.
4. **Qui la voit** (directeur, 20/11) : seulement le candidat qui a accepté les accords requis ; les
   autres voient la page, verrouillée, avec ce qui leur manque. **Le serveur décide**, jamais l'écran
   (lecture à créer ou à réutiliser : chercher d'abord ce que `etat_dossier` et les versions requises
   de `contract_required_versions` donnent déjà).
5. **Traductions** : après validation du français, l'arabe d'abord (près de 80 % des candidats sont
   arabophones, directeur, 20/11). Aucune traduction automatique des versets et invocations
   (`mots-rewayah`).

## Décisions données par le directeur le 20/11, dans les commentaires du texte

Elles sont **dans la lettre**, mais **pas encore dans les sources de vérité ni dans l'application**.
Tant que les lignes « Écart » ne sont pas fermées, la lettre promet quelque chose de faux.

| Décision du 20/11 | Écart avec l'existant |
| --- | --- |
| Part de l'enseignant : **47 % pour les adultes, environ 45 % pour les enfants** (suivi des enfants après le cours) | `DECISION-TARIFS-2026-10-18.md` (19/10) et la base disent 47 % pour tous. Nouvelle décision datée à écrire, réglage à changer en base |
| **Élève absent : l'enseignant reçoit la moitié de sa part** pour la séance (« sinon ils ne vont pas faire d'effort pour les garder ») | `absence_eleve_payee: false` dans `tarifs-2026-10-18.json` ; la paie ne paie que le présent. Décision à écrire, calcul à changer |
| **L'arabe est une langue de cours** : une classe d'élèves arabophones reçoit un enseignant arabophone (« près de 80 % des candidats sont des arabes ») | Décision du 22/10 contraire (`savoir-rewayah` §5, `langues_cours`). À écrire comme nouvelle décision, puis corriger les compétences |
| **Montants donnés aux candidats inscrits** (« avant qu'ils s'inscrivent » : pourcentages ; « aujourd'hui ils sont inscrits, ils ont le droit de savoir combien ils vont gagner ») | Amende la décision du 22/10 (pourcentages seulement) pour les candidats inscrits. À écrire dans `DECISION-TARIFS` et `savoir-rewayah` §4 |
| L'académie existe depuis **près de trois ans** ; avant, chacun enseignait de son côté | Dossier maître : lancement le 01/05/2024. Formulation retenue, pas d'écart |
| Versement : **officiellement au plus tard le 5**, en pratique avant | Conforme |
| Une classe reçue en cours de mois : **payée sur les séances restantes du mois** | Conforme au paiement à la séance, à vérifier dans le calcul |
| Le remplaçant reçoit **100 %** de la paie de la séance | À vérifier dans le calcul |
| Perdre une classe (absence déclarée non tenue) **ne fait pas perdre l'accès** : l'enseignant se déclare disponible pour d'autres classes | À vérifier dans le code |
| **Enseigner ailleurs est permis**, sauf aux mêmes heures | Nouvelle règle, à écrire |
| **Hors de la salle plus de 30 secondes pendant son cours : l'enseignant est sorti et la direction prévenue** | **Introuvable dans le dépôt le 20/11.** La règle des 30 s existe pour les élèves et a été retirée de l'entretien (registre des lots, QUALITE-VIDEO-ENTRETIEN). À vérifier avant validation |
| Visite de contrôle incognito ; **une enseignante est toujours visitée par une femme** | Visite incognito existante (`06` §, contrôleur). Le choix d'une visiteuse : à vérifier |
| Remise aux **nouveaux convertis** (jamais imputée à l'enseignant) | Absente de `tarifs-2026-10-18.json`. À écrire |
| Matricule au format **« #xxxxxx@ra »** | L'application délivre `RA-26-4817` (`DECISION-IMMATRICULATION-2026-10-12.md`). Lot à part, « pas urgent » (directeur). La lettre ne donne pas de format |
| Praxis : **en service, mis en pause** après quelques erreurs, en réglage avant relance | Conforme à l'état du 20/11 (PX-6, retrait annulé, PR #653) |
| Adresse pour se retirer : **support@rewayahacademy.com** | Conforme |

**Encore ouverts** : le montant minimum pour verser les gains d'un remplaçant ; le nombre
d'avertissements avant de perdre une classe ; une relecture juridique de la phrase sur les lois de
protection de l'enfance (partie 8) ; les chiffres « plus de 2 000 candidats » et « plus de 50
nationalités » (tableau Google, non ouvert par l'agent).

## Délais de retard écrits dans la lettre (lus dans la base, pas inventés)

Salle ouverte 20 min avant (`PARCOURS-OUVERTURE-2026-11-01.md`) ; avertissement à T+3
(`remplacement.avertissement_minutes`) ; perte de la séance et alerte à T+8
(`remplacement.perte_acces_minutes`) ; remplaçant en classe à T+11 au plus
(`remplacement.debut_remplacant_minutes`). Si un de ces réglages change, la lettre change.

## Coordination

- **Interface** : session « Parcours candidat enseignant » (accueil du candidat, #662).
- **Praxis animé** : le pilote de l'équipe (Praxis, secrétaire IA).
- Si la page n'est pas prête : maquette hors de l'application, montrée au directeur, puis transport.
