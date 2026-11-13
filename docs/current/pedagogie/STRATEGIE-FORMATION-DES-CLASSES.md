# Stratégie : la formation des classes

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**
> Ce document reprend la stratégie que le directeur appelait « matching des classes », puis « classes vitrines ». Il existe pour qu'elle ne se perde plus. Rien ici n'est encore construit au-delà de ce que dit la partie 2.

## 1. La demande du directeur (12/11/2026, résumé fidèle)

La direction crée des classes vitrines, sans enseignant, représentatives de ce que l'académie offre. Les nouveaux inscrits choisissent parmi elles. Les rares qui ne trouvent pas demandent un créneau personnalisé, ouvert seulement si d'autres choisissent le même. La direction voit une liste qui découpe seule (« 100 personnes ont choisi lundi, jeudi, vendredi, 19 h à 20 h 30 ») et une action crée les classes avec tout : créneau, niveau, élèves répartis (5 au plus par classe d'enfants, 6 par classe d'adultes, hommes d'un côté, femmes de l'autre, âges proches). La direction ajuste sur un aperçu (exceptions, mixité). Une liste trie les enseignants, d'abord ceux qui correspondent au créneau. But : des classes qui se forment naturellement.

## 2. Ce qui existe déjà (relevé du 12/11/2026)

La stratégie n'a pas disparu : elle a été décidée par morceaux, sous d'autres noms, puis construite à moitié. **Elle n'a jamais tourné en production : 0 offre publiée, 0 demande, 0 classe créée par regroupement.**

| Morceau | État |
|---|---|
| Vitrine sans enseignant (décisions du 22/09 et du 09/10) | Existe : offres publiées par la direction, cartes pour la famille. Ce sont des offres, pas des classes |
| Choix d'une vitrine par la famille | Existe, jamais utilisé |
| Créneau personnalisé qui s'ouvre au quota | Le serveur existe ; **aucun écran ne l'appelle** |
| Regroupement automatique des demandes | Existe : par créneau exact, public, langue, genre, niveau |
| « Créer la classe » | Existe, mais **une seule classe à la fois, d'exactement 5 ou 6 élèves**. Ni découpage en plusieurs classes, ni minimum d'ouverture à 4, ni classes de débutants à 4, ni âges proches |
| Aperçu ajustable, exceptions, mixité | **N'existe pas** |
| Liste triée d'enseignants (genre, disponibilités, charge) | Existe côté serveur |
| Délai de formation de 14 jours, point à J7 (décidé le 30/09) | **Jamais construit** |
| Entrée en début de mois (décidé le 30/09) | **Jamais construit** |
| Liste d'attente visible (décidé le 10/10) | **Jamais construit** |
| Ancien « matching individuel » (un enseignant prend un élève) | Remplacé le 23/09, mais son code est encore là |

Décisions du directeur qui restent la base : seule la direction publie (09/10) ; pas d'enseignant sur la carte (22/09) ; aucune demande sans jour ni heure (09/10) ; classes non mixtes, mixité seulement par exception explicite (10/10, 29/10) ; 5 enfants, 6 adultes, 4 débutants, ouverture à 4 (30/09) ; fratries séparées (10/10) ; 3 classes au plus par enseignant, réglable (22/10) ; 14 jours pour former une classe (30/09).

## 3. La stratégie

**Un seul mécanisme pour tout placement.** Un nouvel inscrit, un élève qui change de classe (niveau réel, élève en avance, passage à 18 ans, fin des bases) et un élève qui revient passent tous par le même chemin : un vœu, un regroupement, une classe.

### 3.1 La vitrine

- F1. La direction publie des **classes vitrines**. Chacune dit : les trois jours, l'heure (heure de La Mecque, montrée à chacun dans son heure locale d'hiver et d'été), la durée, le public (6-9, 10-13, 14-17, adultes), le genre, la langue du cours, le niveau, la lecture du Coran.
- F2. **Chacun ne voit que les vitrines qui le concernent** : le système filtre seul selon l'âge, le genre, la langue et le niveau de l'élève. Une famille voit peu de cartes, triées par ce qui convient le mieux à ses heures.
- F3. La carte ne montre **ni enseignant, ni nombre d'inscrits, ni nom d'élève**. Elle montre un état vrai : « En formation », « Ouvre bientôt » (le minimum est atteint), « Complète ». Raison : un chiffre bas décourage, un chiffre inventé trompe.
- F4. **Les classes déjà lancées qui ont une place** apparaissent dans la même vitrine, si l'élève peut y entrer selon la charte (même stade, ou une étape d'écart au plus). On remplit avant de créer.
- F5. **La vitrine suit l'offre réelle d'enseignants.** Pour chaque créneau possible, la direction voit combien d'enseignants sont disponibles (par genre et par langue), les croisements avec leurs prières, et l'heure locale que cela donne aux familles des principales régions. Le système propose les créneaux à publier. Une vitrine sans enseignant possible n'est pas publiée.

### 3.2 Le vœu

- F6. L'élève (ou son tuteur) choisit **une vitrine, et peut en cocher deux autres** qui lui conviendraient aussi. Raison : c'est ce qui fait se former les classes vite ; une seule réponse possible laisse trop de monde en attente.
- F7. Un élève qui dit déjà lire passe d'abord l'entretien de lecture ; son niveau est fixé avant qu'il choisisse.
- F8. **Le créneau personnalisé reste rare.** Il n'est proposé qu'après la vitrine. Il exige les jours et l'heure. Il devient visible des autres familles comme « Créneau proposé » dès que 2 élèves le veulent, et devient une vitrine ordinaire au minimum d'ouverture. Sans cela, il s'éteint à 14 jours, et la famille reçoit les vitrines les plus proches. Un seul à la fois par élève. Si plus d'un vœu sur dix est personnalisé, le système prévient la direction : la vitrine est mal réglée.

### 3.3 Le regroupement et le découpage

- F9. Le système regroupe les vœux par : créneau, jours, public, genre, langue, niveau, lecture. La direction voit la liste découpée, avec le compte de chaque groupe.
- F10. **Le découpage est fait par le serveur.** Pour un groupe, il propose le nombre de classes qui donne des effectifs équilibrés, entre le minimum d'ouverture (4) et le maximum (5 enfants, 6 adultes ; exactement 4 pour des débutants). Ce qui ne peut pas former une classe attend.
- F11. Dans chaque classe : âges proches, fratries séparées, même niveau.

### 3.4 L'aperçu et la création

- F12. La direction voit **un aperçu avant toute création** : les classes proposées et leurs élèves. Elle peut déplacer un élève, réunir deux tranches d'âge voisines, ou accorder une exception de mixité (motif, nom, date : règle de stabilité). **Rien n'est envoyé aux familles avant qu'elle confirme.**
- F13. Une seule action crée toutes les classes confirmées : créneau, niveau, nom, élèves, étape de chacun.
- F14. Pour chaque classe, la liste des enseignants est triée : genre exigé, langue, disponibilité sur le créneau, charge, peu de croisements avec ses prières. Une classe peut être créée « en attente d'enseignant », dit honnêtement à la famille ; elle ne commence pas sans enseignant.

### 3.5 Les promesses tenues

- F15. Une classe se forme en 14 jours au plus, avec un point à 7 jours ; au-delà, 7 jours de plus seulement avec l'accord de la famille. L'entrée se fait en début de mois. La famille suit sa demande étape par étape et sait toujours où elle en est.
- F16. La direction suit quatre mesures : délai moyen de formation, part des premiers vœux satisfaits, personnes en attente depuis plus de 14 jours, part des créneaux personnalisés.

## 4. Les angles morts

1. **Le goulot n'est pas le nombre de candidats, c'est leur validation.** Correction du directeur (12/11/2026), vérifiée dans son Drive : le questionnaire « enseignement du Coran à distance » compte près de 2 000 réponses (deux onglets, environ 1 950 lignes), et le nombre monte. Aucun entretien n'a encore eu lieu ; un seul enseignant est inscrit dans l'application, le directeur lui-même. La vitrine ne peut pas promettre plus que le nombre d'enseignants VALIDÉS : F5 relie les deux, et le recrutement (les trois salles) devient le chantier qui conditionne l'ouverture des classes. Le questionnaire demande déjà la langue maternelle, les langues d'enseignement, le niveau de mémorisation, l'expérience avec les débutants, les heures par semaine et la disponibilité tard le soir « à l'heure de La Mecque » : ces réponses servent à trier les candidats à inviter en premier.
4 bis. **En production, seuls deux élèves sont réels** ; les autres profils sont des comptes de test du directeur. Les inscriptions sont fermées jusqu'à ce que l'accueil soit prêt.
2. **L'heure de La Mecque** change la clé de regroupement et l'affichage des cartes : ce chantier vient après le lot de l'horloge.
3. **L'argent** (essai, paiement avant ou après la formation de la classe) n'est pas arbitré ici : il relève des règles que le directeur s'est réservées.
4. **Cinq élèves sur neuf n'ont pas de classe** en production. Ils sont les premiers à servir.
5. **Aucune preuve de charge** n'existe pour de grands nombres de demandes.

## 5. Les lots

| Lot | Contenu | Dépend de |
|---|---|---|
| FC-1 Finir l'existant | Vitrine filtrée et triée, états de la carte, écran du créneau personnalisé, découpage serveur avec minimum, débutants et tranche d'âge, vœux secondaires | Horloge |
| FC-2 Aperçu et création | Aperçu ajustable, exceptions, création de toutes les classes en une action | FC-1 |
| FC-3 Offre et promesses | Créneaux proposés à la direction selon les enseignants et les prières, délai de 14 jours, entrée en début de mois, liste d'attente, mesures | FC-1, prière |
| FC-4 Placements internes | Changement de classe par le même mécanisme ; retrait du code de l'ancien matching | FC-2, suivi |

Le code est écrit par d'autres modèles ; l'architecte pilote, fait relire et met en ligne.
