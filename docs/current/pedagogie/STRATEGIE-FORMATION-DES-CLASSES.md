# Stratégie : la formation des classes

> **EN VIGUEUR par arbitrage de l'architecte pédagogique (12/11/2026), sur délégation du directeur. Le directeur peut corriger toute règle à tout moment ; une correction datée de sa part l'emporte.**
> Ce document reprend la stratégie que le directeur appelait « matching des classes », puis « classes vitrines » et « marketplace des classes ». **Il est le seul qui fait foi sur ce sujet.** Rien ici n'est encore construit au-delà de ce que dit la partie 2.
> **Révision du 13/11/2026** : relevé refait dans le code (commit `e0b3d936` et branches `claude/suivi-attente`, `claude/horloge-lieu`, `claude/priere-serveur`), par lecture seulement. Rien n'a été exécuté ; la production n'a pas été relue. Les phrases corrigées portent la mention « corrigé le 13/11 ». Ce qui est marqué PROPOSÉ n'est pas arbitré.

## 0. Décisions du directeur

Une ligne par décision. D'abord celles qui bloquent le premier lot.

| N° | Décision à prendre | Recommandation | Raison |
|---|---|---|---|
| | **Bloquent FC-1 (la vitrine)** | | |
| D1 | Classe de débutants : 4 au plus (30/09, dans le code) ou 5 comme tout groupe d'enfants (vos mots du 12/11) ? | 5 enfants, 6 adultes, sans cas débutant | Votre parole la plus récente ; une règle de moins |
| D2 | Minimum pour ouvrir une classe | 4, la valeur du code, réglable | Elle existe déjà et sert la finance |
| D3 | Les capacités ont deux sources : laquelle garder ? | `politiques_commerciales` ; le regroupement la lit | Elle est datée, versionnée, et la direction la règle déjà |
| D4 | Heures non rondes (19 h 30) | Non pour l'instant | Tout le calcul des chevauchements est à l'heure ronde |
| D5 | Nombre de vœux de rechange (F6 dit deux) | Deux | Les classes se forment plus vite ; ce chiffre n'est pas de vous |
| D6 | Créneau personnalisé visible des autres familles dès deux demandes (F8) | Oui | Ce chiffre n'est pas de vous : à confirmer |
| D7 | Alerte quand plus d'un vœu sur dix est personnalisé (F8) | Oui, réglable | Ce chiffre n'est pas de vous : à confirmer |
| D8 | Vitrine à une heure de nuit pour un enfant, dans son fuseau | La classer plus bas avec l'heure vraie, ne pas l'interdire | La famille décide |
| | **Bloquent FC-2 (la création)** | | |
| D9 | Création sans aperçu ? Vous dites « le système agit seul » ; F12 exige un aperçu avant toute création | Automatique pour le cas simple ; aperçu dès qu'il y a fratrie ou exception | Agir seul sans risque pour une famille |
| D10 | Fratrie : séparation stricte, ou choix du tuteur ? | Garder la séparation du 10/10, exception nommée par la direction | Décision déjà prise ; elle n'a aucune règle serveur aujourd'hui |
| | **Bloquent FC-3 et FC-5 (prière, enseignants)** | | |
| D11 | Lieu de référence pour « éviter le maghreb et l'ishâ » sur une vitrine sans enseignant | La Mecque, puis contrôle au lieu réel de l'enseignant à l'affectation | L'heure de l'académie est celle de La Mecque ; le second contrôle existe déjà |
| D12 | Un croisement avec une prière bloque la publication, ou avertit ? | Avertit fort, ne bloque pas | Les heures de prière bougent sur l'année |
| D13 | Publier une vitrine qu'aucun enseignant validé ne peut tenir ? F5 dit non | Oui, avec avertissement à la direction | Sinon aucune vitrine aujourd'hui : aucun enseignant n'est validé |
| D14 | Le système affecte l'enseignant seul, ou propose ? | Il propose, la direction confirme d'un geste | Aucun enseignant validé par entretien à ce jour |
| D15 | Ordre des critères du tri des enseignants | Celui de F14 bis : prière, charge, fuseau, ancienneté | Protéger la prière et répartir la charge |
| D16 | Critère « a déjà enseigné ce public » | Le reporter | La donnée n'existe pas |
| D17 | « Fuseaux visés » sur une vitrine | Information pour la direction, jamais un filtre | Ne cacher aucune classe à une famille |
| | **Argent : réservées au directeur, sans recommandation** | | |
| A1 | La famille paie au vœu, à l'ouverture de la classe, ou au premier cours ? | | |
| A2 | Que devient un paiement si la classe ne se forme pas au délai ? | | |
| A3 | L'essai : avant ou après la formation de la classe ? | | |
| A4 | La place gardée (`jours_conservation_place`) vaut-elle pour un vœu ? | | |
| A5 | Classe ouverte au minimum et non au maximum : effet sur la paie | | |
| A6 | Entrée en début de mois (30/09, non construite) : effet sur la première facture | | |
| A7 | Le créneau personnalisé a-t-il un prix différent ? | | |

## 1. La demande du directeur (12/11/2026, résumé fidèle)

La direction crée des classes vitrines, sans enseignant, représentatives de ce que l'académie offre. Les nouveaux inscrits choisissent parmi elles. Les rares qui ne trouvent pas demandent un créneau personnalisé, ouvert seulement si d'autres choisissent le même. La direction voit une liste qui découpe seule (« 100 personnes ont choisi lundi, jeudi, vendredi, 19 h à 20 h 30 ») et une action crée les classes avec tout : créneau, niveau, élèves répartis (5 au plus par classe d'enfants, 6 par classe d'adultes, hommes d'un côté, femmes de l'autre, âges proches). La direction ajuste sur un aperçu (exceptions, mixité). Une liste trie les enseignants, d'abord ceux qui correspondent au créneau. But : des classes qui se forment naturellement.

Ajouts du 12/11 : une classe d'adultes dure 1 h 30, une classe d'enfants 1 h ; les classes se créent automatiquement quand le seuil est atteint ; le système agit seul, sans IA ; l'architecture est fixe, les valeurs sont réglables par la direction ; un hub et des raccourcis, jamais de doublon.

## 2. Ce qui existe déjà (relevé du 12/11, refait dans le code le 13/11)

La stratégie n'a pas disparu : elle a été décidée par morceaux, sous d'autres noms, puis construite à moitié. Selon le relevé du 12/11, elle n'a jamais tourné en production (0 offre publiée, 0 demande, 0 classe créée par regroupement) : **ces chiffres n'ont pas été revérifiés le 13/11.**

Chemins relatifs à `supabase/migrations/` sauf mention.

| Morceau | État | Preuve |
|---|---|---|
| Vitrine sans enseignant (22/09, 09/10) | Existe : offres publiées par la direction. Ce sont des offres, pas des classes. Elles n'ont ni genre, ni tranche d'âge ; le niveau est un champ vide | `0043_offres_horaires_et_intentions.sql:319` ; `lib/features/admin_offres/` |
| Heure d'une vitrine | **Heure ronde seulement** (entier de 0 à 23), une seule heure pour tous les jours. « 19 h à 20 h 30 » passe, « 19 h 30 » non (ajouté le 13/11) | `0043…:325` ; `0005_dashboards_affectation_regles.sql:384` |
| Durées 60 minutes enfant, 90 adulte ; trois séances par semaine | Existent, réglables | `0043…:536-537` ; `0049_creneau_personnalise_ouvert_au_quota.sql:208` |
| Tranches 6-9, 10-13, 14-17, adultes | Existent | `20261017110800_af_l2_08_reglages_decisions_1410.sql:25` |
| Choix d'une vitrine par la famille | Existe, jamais utilisé | `0043…:682,825` ; `lib/core/offres/service_offres.dart:184,201` ; `lib/features/parcours_offres/` |
| Créneau personnalisé qui s'ouvre au quota | Le serveur existe ; **aucun écran ne l'appelle** | `0050_demandes_horaires_privees_admin.sql:106` |
| Regroupement automatique des demandes | Existe : par créneau exact, public, langue, genre, niveau | `20261011121958_c11bis_f74_partition_key.sql:140,178` ; `lib/features/admin_regroupements/` |
| « Créer la classe » | Existe. **Rien n'est automatique** : c'est un geste de la direction, une classe à la fois, refusé tant que le compte n'atteint pas le maximum (5 ou 6). Ni découpage, ni minimum d'ouverture, ni débutants, ni âges proches (précisé le 13/11) | `20261012100000_c11bis_gender_enum_fix.sql:4,140` ; classe sans enseignant : `0055_classes_en_attente_enseignant.sql:10` |
| Capacités | **Deux sources** : `app_config` (`groupe.capacite_*`), lue par le regroupement et la création ; `politiques_commerciales`, lue par la finance et les tarifs publics. 5 et 6 des deux côtés ; rien ne les tient égales (ajouté le 13/11) | `20261011121958…:252-253` ; `20261017170000_fac_a_01_politiques_commerciales.sql:39-45,100` |
| Aperçu ajustable, exceptions, mixité | **N'existe pas** | |
| Enseignants possibles pour une classe | **Corrigé le 13/11 : la liste est filtrée, elle n'est pas triée.** Le serveur écarte par genre, langue, plafond de classes, disponibilité sur toute la durée, chevauchement. La fonction propre à une classe (`enseignants_pour_classe`) ne trie pas et aucun écran ne l'appelle ; l'écran appelle `enseignants_pour_public`, qui rend l'ordre alphabétique. L'ancien texte disait « Liste triée d'enseignants (genre, disponibilités, charge) : existe côté serveur » | `20261023000000_classes_duree_bout_en_bout.sql:622` ; `20261120200400_enseignants_pour_public_ensemble.sql:72` ; `lib/core/capacites/enseignants_classe_supabase.dart:29` ; affectation vérifiée : `20261021210100_c11bis_affectation_verifiee.sql:86` |
| Plafond de classes par enseignant (3, réglable) | Existe | `20261022000200_classes_plafond_par_enseignant.sql:19` |
| Un rang déterministe pour le remplacement (genre puis langue) | Existe : modèle à réutiliser pour le tri, pas à copier | `20261119300000_remplacement_temps_reel.sql:217` |
| Fratries séparées (10/10) | **Décidé, mais aucune règle serveur trouvée** (ajouté le 13/11) | |
| Prières par enseignant : heures sans prière, heures où une prière se ferme pendant le cours | Présent dans le code, non livré. Le calcul part du lieu d'un enseignant : une vitrine sans enseignant n'a pas de lieu (D11) | `20261123930000_priere_serveur.sql:1765,1789` |
| Délai de formation de 14 jours, point à J7 (30/09) | **Corrigé le 13/11** : les deux réglages, l'écran de suivi et la liste des demandes en retard sont dans la branche `claude/suivi-attente`, non livrée. Aucune relance automatique | `20261123960000_suivi_attente.sql`, `20261123962000_suivi_attente_pret.sql` ; `lib/features/attente_classe/` |
| Heure chez la famille, hiver et été, sur une offre | Dans la branche `claude/horloge-lieu`, non livrée | `20261123943100_apercu_offre.sql` |
| Entrée en début de mois (30/09) | **Jamais construit** | |
| Liste d'attente visible (10/10) | **Jamais construit** | |
| Ancien « matching individuel » | Remplacé le 23/09, mais son code est encore là | `enseignants_pour`, `teacher_student_assignments` |

Décisions du directeur qui restent la base : seule la direction publie (09/10) ; pas d'enseignant sur la carte (22/09) ; aucune demande sans jour ni heure (09/10) ; classes non mixtes, mixité seulement par exception explicite (10/10, 29/10) ; 5 enfants, 6 adultes (30/09, redit le 12/11) ; 4 débutants et ouverture à 4 (30/09 : les 4 débutants sont à confirmer, D1) ; fratries séparées (10/10) ; 3 classes au plus par enseignant, réglable (22/10) ; 14 jours pour former une classe (30/09) ; 1 h enfant, 1 h 30 adulte (12/11).

## 3. La stratégie

**Un seul mécanisme pour tout placement.** Un nouvel inscrit, un élève qui change de classe (niveau réel, élève en avance, passage à 18 ans, fin des bases) et un élève qui revient passent tous par le même chemin : un vœu, un regroupement, une classe. Tout est filtre et tri : aucune IA, aucun score caché.

### 3.1 La vitrine

- F1. La direction publie des **classes vitrines**. Chacune dit : les trois jours, l'heure (heure de La Mecque, montrée à chacun dans son heure locale d'hiver et d'été), la durée, le public (6-9, 10-13, 14-17, adultes), le genre, la langue du cours, le niveau, la lecture du Coran. On enrichit la table des offres ; on ne crée pas une seconde table.
- F2. **Chacun ne voit que les vitrines qui le concernent** : le système filtre seul selon l'âge, le genre, la langue et le niveau de l'élève. Une famille voit peu de cartes, triées par ce qui convient le mieux à ses heures.
- F2 bis (PROPOSÉ). Ordre des cartes : une classe lancée qui a une place ; puis les vitrines ouvertes ; puis celles en remplissage, la plus proche du minimum d'abord ; puis les autres. À égalité : l'heure la plus proche des disponibilités de la famille, puis la plus ancienne.
- F3. La carte ne montre **ni enseignant, ni nombre d'inscrits, ni nom d'élève**. Elle montre un état vrai : « En formation », « Ouvre bientôt » (le minimum est atteint), « Complète ». Raison : un chiffre bas décourage, un chiffre inventé trompe.
- F3 bis (PROPOSÉ). Cinq états, calculés par le serveur, jamais saisis : proposée (aucun vœu), en remplissage (sous le minimum), ouverte (minimum atteint, classe créée, places restantes), pleine (maximum atteint ; un nouveau vœu ouvre une vitrine jumelle), fermée (retirée, ou éteinte au délai ; les familles sont prévenues).
- F4. **Les classes déjà lancées qui ont une place** apparaissent dans la même vitrine, si l'élève peut y entrer selon la charte (même stade, ou une étape d'écart au plus). On remplit avant de créer.
- F5. **La vitrine suit l'offre réelle d'enseignants.** Pour chaque créneau possible, la direction voit combien d'enseignants sont disponibles (par genre et par langue), les croisements avec leurs prières, et l'heure locale que cela donne aux familles des principales régions. Le système propose les créneaux à publier. Une vitrine sans enseignant possible n'est pas publiée (à revoir : D13).

### 3.2 Le vœu

- F6. L'élève (ou son tuteur) choisit **une vitrine, et peut en cocher deux autres** qui lui conviendraient aussi. Raison : c'est ce qui fait se former les classes vite ; une seule réponse possible laisse trop de monde en attente.
- F7. Un élève qui dit déjà lire passe d'abord l'entretien de lecture ; son niveau est fixé avant qu'il choisisse.
- F8. **Le créneau personnalisé reste rare.** Il n'est proposé qu'après la vitrine. Il exige les jours et l'heure. Il devient visible des autres familles comme « Créneau proposé » dès que 2 élèves le veulent, et devient une vitrine ordinaire au minimum d'ouverture. Sans cela, il s'éteint à 14 jours, et la famille reçoit les vitrines les plus proches. Un seul à la fois par élève. Si plus d'un vœu sur dix est personnalisé, le système prévient la direction : la vitrine est mal réglée.

### 3.3 Le regroupement et le découpage

- F9. Le système regroupe les vœux par : créneau, jours, public, genre, langue, niveau, lecture. La direction voit la liste découpée, avec le compte de chaque groupe.
- F10. **Le découpage est fait par le serveur.** Pour un groupe, il propose le nombre de classes qui donne des effectifs équilibrés, entre le minimum d'ouverture (4) et le maximum (5 enfants, 6 adultes ; exactement 4 pour des débutants : D1). Ce qui ne peut pas former une classe attend.
- F11. Dans chaque classe : âges proches, fratries séparées, même niveau.
- F11 bis (PROPOSÉ). Âges proches : les élèves d'un découpage sont rangés par date de naissance ; à égalité, la demande la plus ancienne d'abord. Fratrie : deux enfants d'un même foyer vont dans deux classes jumelles ; s'il n'y en a qu'une, le plus récent attend et le tuteur est prévenu. Les enfants d'un même foyer se voient proposer d'abord des créneaux qui ne se chevauchent pas.

### 3.4 L'aperçu et la création

- F12. La direction voit **un aperçu avant toute création** : les classes proposées et leurs élèves. Elle peut déplacer un élève, réunir deux tranches d'âge voisines, ou accorder une exception de mixité (motif, nom, date : règle de stabilité). **Rien n'est envoyé aux familles avant qu'elle confirme.** (Le directeur a dit le 12/11 « les classes se créent automatiquement » : D9.)
- F13. Une seule action crée toutes les classes confirmées : créneau, niveau, nom, élèves, étape de chacun.
- F14. Pour chaque classe, la liste des enseignants est triée : genre exigé, langue, disponibilité sur le créneau, charge, peu de croisements avec ses prières. Une classe peut être créée « en attente d'enseignant », dit honnêtement à la famille ; elle ne commence pas sans enseignant.
- F14 bis (PROPOSÉ). Les filtres existent (partie 2). Le tri est à construire, dans cet ordre : aucune prière qui se ferme pendant le cours sur douze mois ; le moins de séances qui croisent l'entrée d'une prière ; le moins de classes actives ; l'heure du cours dans sa journée, dans son fuseau ; la date de validation la plus ancienne ; puis l'ordre alphabétique, pour un résultat toujours identique. L'ordre des critères est un réglage. Une seule fonction de rang sert l'affectation, le changement d'enseignant et le remplacement. Chaque nom porte la raison de son rang en mots. Si personne ne convient : la classe reste en attente, la direction voit le critère qui a écarté chacun, et le besoin (créneau, genre, langue) remonte au recrutement.
- F14 ter (PROPOSÉ). Un hub « Formation des classes » pour la direction : vitrines et états, regroupements, classes sans enseignant. Les pages Offres, Regroupements et Planning y mènent par raccourci ; aucune liste n'est recopiée.

### 3.5 Les promesses tenues

- F15. Une classe se forme en 14 jours au plus, avec un point à 7 jours ; au-delà, 7 jours de plus seulement avec l'accord de la famille. L'entrée se fait en début de mois. La famille suit sa demande étape par étape et sait toujours où elle en est.
- F15 bis. Un seul écran pour la famille : le suivi de l'attente (`lib/features/attente_classe/`, branche non livrée). Le tuteur ou l'élève adulte y lit chaque étape et le délai du réglage, jamais une estimation. **Un enfant de 6 à 9 ans ne voit ni date, ni délai, ni état d'attente** (charte, arbitrages n° 99 et n° 106). **Aucune notification, aucun courriel, aucun push à un mineur** (01/11) ; jamais de prénom d'enfant dans un push. Quand le délai passe, rien n'est annulé seul : la famille adulte reçoit les vitrines proches, ou choisit d'attendre.
- F16. La direction suit quatre mesures : délai moyen de formation, part des premiers vœux satisfaits, personnes en attente depuis plus de 14 jours, part des créneaux personnalisés.

## 4. Les angles morts

1. **Le goulot n'est pas le nombre de candidats, c'est leur validation.** Correction du directeur (12/11/2026), vérifiée dans son Drive : le questionnaire « enseignement du Coran à distance » compte près de 2 000 réponses (deux onglets, environ 1 950 lignes), et le nombre monte. Aucun entretien n'a encore eu lieu ; un seul enseignant est inscrit dans l'application, le directeur lui-même. La vitrine ne peut pas promettre plus que le nombre d'enseignants VALIDÉS : F5 relie les deux, et le recrutement (les trois salles) devient le chantier qui conditionne l'ouverture des classes. Le questionnaire demande déjà la langue maternelle, les langues d'enseignement, le niveau de mémorisation, l'expérience avec les débutants, les heures par semaine et la disponibilité tard le soir « à l'heure de La Mecque » : ces réponses servent à trier les candidats à inviter en premier.
2. **L'heure de La Mecque** change la clé de regroupement et l'affichage des cartes : ce chantier vient après le lot de l'horloge.
3. **L'argent** (essai, paiement avant ou après la formation de la classe) n'est pas arbitré ici : il relève des règles que le directeur s'est réservées (A1 à A7, lot HARMONISER-ARGENT).
4. **Cinq élèves sur neuf n'ont pas de classe** en production. Ils sont les premiers à servir.
5. **En production, seuls deux élèves sont réels** ; les autres profils sont des comptes de test du directeur. Les inscriptions sont fermées jusqu'à ce que l'accueil soit prêt.
6. **Aucune preuve de charge** n'existe pour de grands nombres de demandes.
7. **Trois lots dont tout dépend ne sont pas livrés** : suivi de l'attente, horloge, prière (ajouté le 13/11).
8. **La prière d'une vitrine sans enseignant** n'a pas de lieu de calcul (D11, ajouté le 13/11).

## 5. Les lots

FC-1 à FC-4 gardent leur nom et leur contenu : d'autres documents les citent. FC-5 est ajouté le 13/11 ; il sort de FC-2 et de FC-3 ce qui touche au tri des enseignants. Le directeur colle une migration seulement si elle contient un mot d'effacement ; ce compte se fait avant chaque installation.

| Lot | Contenu | Tables et fonctions | Écrans | Dépend de | À coller | Risques |
|---|---|---|---|---|---|---|
| FC-1 Finir l'existant | Vitrine filtrée et triée, états de la carte, écran du créneau personnalisé, découpage serveur avec minimum, débutants et tranche d'âge, vœux secondaires, une seule source des capacités | `offres_horaires` (genre, tranche, niveau) ; `offres_compatibles` ; lecture de l'état ; vœux sur `demandes_horaires_famille` | `admin_offres`, `parcours_offres` | Horloge ; D1 à D8 | Probablement rien (colonnes ajoutées) | `offres_compatibles` change de sortie : l'ancien client en dépend ; la clé de regroupement change avec le fuseau |
| FC-2 Aperçu et création | Aperçu ajustable, exceptions, création de toutes les classes en une action ; fratrie, âges proches | À partir de `creer_classe_depuis_regroupement` ; journal de chaque création | `admin_regroupements` | FC-1 ; D9, D10 | Rien de prévu | Deux créations en même temps : verrou par clé (règle du 10/10) ; un mauvais découpage touche des familles réelles |
| FC-3 Offre et promesses | Créneaux proposés à la direction selon les enseignants et les prières, délai de 14 jours, entrée en début de mois, liste d'attente, mesures | Contrôle de prière d'une vitrine ; relances ; mesures | Suivi de l'attente, hub | FC-1, prière, suivi de l'attente ; D11 à D13 | Oui si un événement de notification est ajouté (comme « tout est prêt ») | Un message à un mineur : interdit, la garde serveur doit être livrée avant |
| FC-4 Placements internes | Changement de classe par le même mécanisme ; retrait du code de l'ancien matching | Retrait de `enseignants_pour` et de ce qui l'entoure, après inventaire | `suivi_demandes` | FC-2, suivi ; accord écrit du directeur pour chaque suppression | Oui : lot d'effacement | Supprimer du code encore lu par un écran |
| FC-5 Tri des enseignants (ajouté le 13/11) | Liste triée avec la raison en mots, repli « personne ne convient », besoin remonté au recrutement, hub « Formation des classes » | Une fonction de rang commune ; `enseignants_pour_classe` triée et enfin appelée | Feuille d'affectation, hub | Prière, horloge ; D14 à D17 | À compter : partager `private.remplacement_rang` peut demander un effacement | Toucher au remplacement, qui a sa décision (07/11) : sa règle ne change pas |

Le code est écrit par d'autres modèles ; l'architecte pilote, fait relire et met en ligne.
