# Répartition du paiement d'un élève : où la montrer, et comment

22/10/2026. **Proposition au directeur, non validée.** Une réponse ne devient décision
qu'une fois versée et datée dans `docs/current/`.

**Déjà décidé** (directeur, 22/10/2026 ; `docs/current/DECISION-TARIFS-2026-10-18.md`,
section du 22/10 ; journal `08`). La répartition du paiement d'un élève est montrée à
l'enseignant (profil et parcours de candidature), au tuteur et à l'élève adulte, **en
pourcentages seulement** ; toutes les dépenses y figurent jusqu'au bénéfice de
l'académie, et la somme fait 100 % ; chaque poste se dit par sa part du paiement de
l'élève, jamais par un nombre de personnes ; qui veut les montants les demande à
l'administration.

Ce document ne rouvre aucun de ces points. Il propose ce que la décision laisse ouvert :
la salle, l'écran de chaque rôle, la base de calcul, la façon de dire l'estimation, le
« 2 % », et les montants de la paie propre de l'enseignant. Les questions sont en
section 7 (`CAND-R01` à `CAND-R12`), reprises dans la page d'arbitrage.

Abréviations : `TARIFS` = `docs/current/DECISION-TARIFS-2026-10-18.md` ; `OFFRE` =
`docs/current/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md` ; `DOC19` = onglet
« Décision du 19/10 : enseignants et charges » du document du directeur « Offre et tarifs
Rewayah Academy » ; `CAT` = `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md` ; `SPEC_V1` =
`REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md` ; `SC` =
`SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md`.

## 1. Est-ce pertinent ?

Oui, pour trois raisons.

- La spécification l'exige déjà en partie : « Le candidat doit connaître les conditions
  de paiement et le cadre religieux avant d'avancer dans le processus » (`SPEC_V1:699-700`,
  décision « à ne pas rouvrir sans nouvelle information »).
- La répartition montre ce qu'on ne voit pas : la part de l'enseignant est de loin la plus
  grosse ; l'académie porte seule les remises, les bourses, les impayés, les frais de
  carte et les frais de virement ; ce qui lui reste est modeste.
- Une seule page sert à tous les rôles.

À trois conditions, écrites sur la page elle-même :

1. **C'est une estimation datée, pas un compte.** Aucun élève ne paie encore la nouvelle
   offre, qui prend effet le 01/11/2026 (`supabase/migrations/20261018120000_fac_e_01_tarifs_v2.sql:66`),
   et « les chiffres de scénario ne deviennent jamais des vérités de production »
   (`docs/current/00_LIRE_D_ABORD.md:29`).
2. **La base est dite en tête** : un pourcentage ne se lit pas sans elle (`CAND-R01`).
3. **Le 47 % se dit exactement** : 47 % du prix public, pour chaque heure où l'élève est
   présent (section 6).

La page n'est jamais montrée à un élève mineur : « À l'enfant, on ne parle jamais
d'argent » (`.claude/skills/mots-rewayah/SKILL.md:18`).

## 2. Dans le parcours de candidature

Le directeur pensait à la salle 2, pas au début de la salle 1. La proposition coupe en
deux : les **conditions** courtes (la règle que le candidat accepte) et la **répartition**
détaillée (où va le paiement).

| Salle | Ce que voit le candidat | Pourquoi là |
|---|---|---|
| 1, Salle d'examen | À la **fin**, juste au-dessus de « Envoyer ma candidature » : les conditions de rémunération (2.1), en pourcentages, et la case « J'ai lu ces conditions de rémunération et je les accepte. » Pas de répartition. | Pas au début, comme le voulait le directeur ; mais avant l'envoi, comme le veut `SPEC_V1:699-700`, puisque l'envoi (transition 6) exige l'accord (`SC:412`). Le « d'abord » de `SC:212` et l'ordre des cartes de `CAND-01` ne sont que des propositions (`CAT`, statut « proposée ») : ils suivent ce tableau. |
| 2, Salle de vérification et d'entretien | Sur le portail du candidat, une tuile « À lire avant votre entretien » qui ouvre la page « Où va le paiement d'un élève » (section 3). | Le candidat a déjà accepté la règle ; il est sérieux ; l'entretien lui permet de poser ses questions. La page n'entre pas dans la page d'accords : elle n'a pas de case à cocher, et c'est une estimation, pas un engagement. |
| 3, Prêts à être affectés | Rien de nouveau. | La page passe au profil de l'enseignant (3.2). |

Le contrat `teacher_nda` ne cite jamais la répartition, qui est une estimation. S'il cite
quelque chose, c'est la règle et sa version.

### 2.1 La carte des conditions, en salle 1

Aucun montant (décision du 22/10). Chaque ligne n'est rendue que si le serveur la renvoie ;
aucune n'est écrite en dur (`SC:212`).

| # | Texte proposé | Source au serveur | Aujourd'hui |
|---|---|---|---|
| 1 | « Votre part : {part} du prix public mensuel de chaque élève, répartie sur les heures de cours du mois. » | part par public (`politique_part_enseignant`) | rendue par L2A1 |
| 2 | « Vous la recevez pour chaque élève présent, à chaque séance que vous donnez. Vous n'êtes pas payé pour un élève absent. » | règle de l'élève absent | codée dans `private.pai_due_seance`, pas lisible |
| 3 | « Les remises et les bourses accordées aux familles ne changent pas votre paie. » | règle des remises | pas en base |
| 4 | « Une séance est payée en entier si vous la tenez au moins {min} minutes sur {duree}. Une séance où vous êtes absent n'est pas payée. » | durée due de la politique ; absence de l'enseignant | durée due en base ; le reste non |
| 5 | « Si le cahier de la semaine manque, votre paie du mois attend qu'il soit déposé. Elle n'est jamais annulée. » | règle du cahier | pas en base |
| 6 | « Le versement a lieu entre le {du} et le {au} du mois suivant. Les frais de virement sont à la charge de l'académie. » | période, frais | pas en base |
| 7 | « Le taux est revu tous les six mois. » | révision | pas en base |
| 8 | « Vos coordonnées financières ne vous seront demandées qu'avant votre premier versement. » | texte existant (`CAT`, `CAND-01`) | rendu |
| 9 | « Pour le détail des montants, écrivez à l'administration. » (lien vers la conversation de la candidature) | aucune | |
| 10 | « À l'étape suivante, vous verrez où va le paiement d'un élève. » Rendue seulement si une répartition est publiée. | version publiée | absente |

Les lignes 2 à 7 attendent le lot « règles de paie » (section 5, lot A). Ce sont des
conditions de l'accord : ce lot devrait précéder l'ouverture réelle de la salle 1.

### 2.2 Ce que cela change dans L2A1 (en cours, non versé)

1. **Retirer les montants.** `private.conditions_remuneration_applicables()` rend
   aujourd'hui `parElevePresentEtParHeure` (le taux en dollars) et `devise` au candidat.
   La décision du 22/10 les retire : la fonction garde `version`, `dateEffet`,
   `enVigueur` et la part par public. Un montant que le serveur renvoie peut s'afficher
   par erreur, et se lit dans la réponse : le retirer côté serveur est la seule garantie.
   À faire dès que la reprise de L2A est versée, avec son scénario.
2. **La part et le taux sont deux valeurs indépendantes.** La part affichée vient de
   `politique_part_enseignant`, le taux payé de `politiques_commerciales`, et rien ne
   vérifie qu'ils concordent. Sans montant à l'écran, un écart ne se verrait plus.
   Proposition, dans le lot A : la fonction rend « conditions indisponibles » (envoi
   refusé) quand le taux, ramené aux heures moyennes du mois et au prix, s'écarte de la
   part de plus que l'arrondi au centime.
3. **Deux cases au lieu d'une.** La seule case reliée à l'accord dit aujourd'hui
   « J'accepte de recevoir ma rémunération par au moins un moyen validé par Rewayah »
   (`CAT`, `CAND-01`) : elle porte sur le moyen de versement, pas sur la règle. Proposition :
   une case des conditions (ci-dessus), qui écrit l'accord `teacher_pay_conditions` à la
   version lue, et la case du moyen, qui reste dans la carte « Pays et versement ». Le nom
   des deux valeurs se règle avec L6, qui lit `accordRemuneration` dans les réponses.

## 3. La page « Où va le paiement d'un élève »

Une seule page, un seul nom partout. Aucune fiche n'existe : elle est à créer au
catalogue avant tout écran.

### 3.1 Contenu

**Bloc 1, la règle.** Les lignes de 2.1 que le serveur rend, sans case. Le candidat et
l'enseignant lisent « Votre part : … » ; le tuteur et l'élève adulte, « La part de
l'enseignant : … ».

**Bloc 2, la répartition** (base recommandée, `CAND-R01`). En-tête :

« Ce que deviennent 100 % du paiement d'un mois, au plein tarif, pour un élève présent à
toutes les séances. Estimation du {date}, au niveau d'activité que l'académie vise : ce
n'est pas encore un compte. »

| Où va le paiement d'un élève | Classe d'enfants | Classe d'adultes |
|---|---|---|
| L'enseignant | 47,0 % | 47,0 % |
| Les frais de virement vers l'enseignant | 1,1 % | 1,1 % |
| Les remises et les bourses accordées aux familles, et les paiements non reçus | 5,5 % | 5,5 % |
| Les frais de carte bancaire et de change, quand la famille paie | 4,7 % | 4,7 % |
| La visioconférence des séances | 2,7 % | 2,3 % |
| L'application et ses services : outils d'intelligence artificielle, base de données, hébergement, nom de domaine, frais bancaires, envoi des e-mails, stockage des fichiers | 5,7 % | 4,9 % |
| Le développement et la maintenance de l'application | 10,9 % | 9,2 % |
| L'administration | 9,1 % | 7,7 % |
| La comptabilité | 2,7 % | 2,3 % |
| Faire connaître l'académie (dépense de lancement, répartie sur douze mois) | 0,8 % | 0,6 % |
| L'impôt sur les sociétés | 1,9 % | 2,8 % |
| La réserve de trésorerie, puis le bénéfice de l'académie | 7,9 % | 11,9 % |
| **Total** | **100 %** | **100 %** |

Sous le tableau :

- « L'enseignant reçoit 47 % du prix public pour chaque heure où l'élève est présent.
  Il n'est pas payé pour un élève absent. »
- Au tuteur et à l'élève adulte : « Si vous avez une remise ou une bourse, l'enseignant
  reçoit la même somme : votre remise est prise sur la part de l'académie. » À
  l'enseignant et au candidat : « Les remises et les bourses ne changent pas votre paie. »
- « Quand l'académie grandit, la part de l'application, du développement et de la
  comptabilité baisse. Celle de l'enseignant ne change pas. »
- « La taxe de votre pays s'ajoute au prix. L'académie ne la garde pas. »
- « Pas encore comptées, faute d'estimation : {liste} » (`CAND-R07`), rendue seulement si
  la liste n'est pas vide.
- « Pour le détail des montants, écrivez à l'administration. »

Les parts sont données au dixième, pour que la somme fasse 100 % sans qu'une ligne paraisse
fausse ; l'écart d'arrondi va aux plus grands restes. Le nombre d'élèves et d'enseignants
du scénario ne s'affiche pas.

### 3.2 Où chaque rôle la trouve

| Qui | Où | Remarque |
|---|---|---|
| Enseignant | Profil > « Rémunération », sous « Revenus estimés » (`lib/features/profil_enseignant/profil_enseignant_page.dart:724-743`) | Après la correction de « Revenus estimés » (section 5). |
| Candidat, salle 2 | Tuile du portail (section 2) | |
| Tuteur | Foyer > fiche de l'élève > Finances, un lien sous la mensualité (`lib/features/foyer/fiche/finances_page.dart:49-77`) | Le tuteur n'a pas de « profil » mais un « Compte » (`mots-rewayah`) ; sa rubrique « Paiements » affiche aujourd'hui « Non disponible ». La page va là où il voit ce qu'il paie. |
| Élève adulte | « Mon espace » > ses finances (`/eleve/finances`, `lib/features/mon_espace_adulte/mes_finances_page.dart`), sous la mensualité | `mots-rewayah` nomme cette entrée « Profil », la barre affiche « Mon espace » : écart à régler à part. |
| Élève mineur | Jamais | |
| Site public | Pas de grille (`CAND-R11`) | Le site est un brouillon ; la décision du 22/10 ne le nomme pas. |

Le lien « écrivez à l'administration » ouvre le moyen d'écrire déjà prévu pour chaque
rôle : la conversation de la candidature pour le candidat ; pour les autres rôles, la
fiche le précisera.

### 3.3 États et capacité

- `loading` : squelette des deux blocs ; `content` ; `empty` : « La répartition n'est pas
  encore publiée. » (la ligne 10 de 2.1 n'est alors pas rendue) ; `error` : « La
  répartition n'a pas pu être chargée. Vérifiez votre connexion, puis réessayez. » avec
  « Réessayer » ; `offline` : la dernière version lue, avec sa date.
- Un poste sans libellé dans la langue lue met la page en erreur : on n'affiche jamais une
  ligne tue, sinon la somme ne ferait plus 100 %.
- Capacité `voirRepartitionPaiement`, rendue par le serveur : vraie pour l'enseignant
  actif, le candidat en salle 2 ou au-delà, le tuteur titulaire et l'élève adulte ;
  fausse pour tout profil d'élève mineur, même en Interface guidée.

## 4. Les chiffres

### 4.1 Comment la grille est calculée

Base : le prix d'un mois au plein tarif, hors taxes, pour un élève présent à toutes les
séances ; c'est la base du tableau « Ce que deviennent 55 $ et 65 $ payés par une
famille » de `DOC19`. Charges du mois du 19/10 (`TARIFS`, section du 19/10), ramenées par
élève au scénario de référence de `OFFRE` (100 élèves, 11 enseignants). Trois corrections
par rapport à `DOC19` :

- les frais de virement vers l'enseignant ont leur ligne (dans `DOC19`, ils sont cachés
  dans le « reste ») et suivent la règle de `OFFRE:148`, environ 2 % de la paie plus un
  forfait par versement ;
- la dépense de lancement pour faire connaître l'académie (`OFFRE:177`, hors du tableau
  mensuel) est répartie sur douze mois (`CAND-R09`) ;
- l'impôt est 19 % de ce qui reste du paiement de cet élève, et non une moyenne commune
  aux deux formules.

L'enseignant y est compté à la part décidée, 47 % du prix ; le taux payé, arrondi au
centime, en diffère de moins d'un dixième de point. Calcul refait le 22/10 ; chaque
colonne fait 100,0 %, et aucune ligne ne s'écarte de sa valeur exacte de plus de
0,06 point.

**Autre base possible** (`CAND-R01`) : ce que l'académie reçoit en moyenne, après remises,
impayés et absences, en une seule colonne. L'enseignant y pèse 44 % et non 47 % : il
n'est pas payé pour les absents, et les remises réduisent ce que l'académie reçoit sans
réduire la paie. Les autres lignes : virement 1 %, carte et change 5 %, visio 3 %,
application 5 %, développement 11 %, administration 9 %, comptabilité 3 %, faire connaître
1 %, impôt 3 %, réserve puis bénéfice 15 %. Plus juste en moyenne, mais il faut expliquer
pourquoi 44 et non 47.

### 4.2 Réserves avant tout affichage

- Les prix des prestataires ont été relevés par recherche le 19/10, « pages officielles
  non ouvertes » ; « le développeur, la banque et l'IA sont des estimations sans source »
  (`DOC19`, Sources). Pour la visioconférence, la formule détaillée de `DOC19` donne moins
  que la ligne retenue, sans explication. À vérifier avant la première publication.
- Les 5 % de frais de carte et de change sont une enveloppe que le dossier maître dit
  « non vérifiée, à stresser à 8 % »
  (`docs/current/sources-directeur-2026-10/REWAYAH_DOSSIER_MAITRE_SPECS_PRODUIT_COMPLET_2026-10-14.md:7802`).
- Les remises du scénario (3 %, `OFFRE:163`) contredisent `OFFRE:59`, où les remises
  « ramènent le prix effectif moyen » à 8 ou 9 % sous le prix public (`CAND-R12`).
- La ligne du développement suppose un développeur payé ; aujourd'hui c'est Claude qui
  développe, et aucune fonction du dépôt n'appelle un modèle d'intelligence artificielle :
  la ligne « IA » paie sans doute l'outil de développement (`CAND-R08`).

## 5. Lots, dans l'ordre

Aucun n'est écrit. Ils sortent du module des candidatures, le seul que couvre l'accord du
21/10 sur la base de test : chacun attend l'ordre du directeur, et chaque écran attend son
lot serveur.

1. **Retrait des montants de L2A1** (2.2, point 1), dans la reprise en cours.
2. **Lot A, règles de paie lisibles.** Chaque règle a une seule source, que le calcul et
   l'affichage lisent tous deux : l'élève absent non payé (aujourd'hui codé dans
   `private.pai_due_seance`) ; la séance de l'enseignant absent ; le cahier ; la période de
   versement ; les frais de virement à la charge de l'académie ; la révision tous les six
   mois ; les heures moyennes du mois. Colonnes versionnées de la politique, ou table liée
   à sa version, en ajout seul. Un changement de sens crée une version neuve et redemande
   l'accord du candidat.
3. **Lot B, répartition publiée.** Une table de versions et de lignes en ajout seul,
   publiée par migration seulement, comme `politique_part_enseignant` : poste, part pour
   mille par formule, ordre, libellés `fr` et `ar`, date de calcul, « estimation », lien à
   la politique ; publication refusée si une colonne ne fait pas 1000. Source :
   `docs/current/tarifs-2026-10-18.json`, qui gagne un bloc de répartition en pour mille.
   Une RPC authentifiée, `repartition_paiement()`, rend la version et ses lignes à qui
   porte la capacité, refuse les autres, et n'a aucun droit `anon` ; `tarifs_publics()`
   garde sa liste blanche.
4. **Correction de « Revenus estimés »**, serveur puis écran. **Défaut existant, branché
   en production** : la page explique l'ancien modèle (« Un élève financé absent compte :
   une absence ne vous fait rien perdre », `assets/i18n/fr.i18n.json:6255-6261`), contraire
   à la règle du 19/10 ; et `mes_revenus_enseignant` rend encore une « base garantie » et
   un « plafond » tirés de la taille des Classes
   (`supabase/migrations/20261018130000_fac_e_02_paie_par_eleve_present.sql:175-215`). Elle
   passe avant l'ajout de la répartition sur le profil.
5. **Fiche** de la page « Où va le paiement d'un élève » au catalogue.
6. **Puis un écran à la fois, sur ordre du directeur** : la carte de la salle 1
   (`CAND-01`), le profil de l'enseignant, le portail en salle 2, Foyer > Finances, et
   les finances de l'élève adulte.

## 6. Les subtilités qui changent le texte

- **47 % de quoi ?** La règle du 19/10 dit « du prix public », remises sans effet sur la
  paie (`TARIFS`, section du 19/10). Le 22/10, le directeur a écrit « 47 % de ce que paye
  l'élève ». Les deux ne coïncident que pour un élève au plein tarif, hors taxes, présent
  à tout, en moyenne sur l'année. Avec la règle du 19/10, la part de l'enseignant dans ce
  que la famille paie vraiment monte à environ 51 % pour un 2e inscrit, 57 % pour un 3e
  enfant, 67 % avec la bourse ; elle baisse avec les absences ; et comme un mois compte 12
  à 15 séances, elle va de 43 à 54 % selon le mois. D'où la formule « 47 % du prix public,
  pour chaque heure où l'élève est présent » (`CAND-R05`).
- **Le « 2 % ».** Aucune ligne de la grille ne vaut 2 %. Il y a deux frais : la carte et
  le change, quand la famille paie (environ 4,7 % du paiement) ; le virement vers
  l'enseignant, environ 2 % de sa paie plus un forfait par versement (`OFFRE:148`), soit
  environ 1,1 % du paiement. Le « 2 % » du directeur est sans doute le second, rapporté à
  la paie (`CAND-R04`). Le tableau « Où va chaque dollar encaissé » compte ce virement à sa
  valeur d'avant le 19/10 : il n'a pas été recalculé quand la paie est passée à 47 %
  (`OFFRE:164`). Le corriger touche `OFFRE`, `TARIFS`, `docs/current/tarifs-2026-10-18.json`
  et le document du directeur.
- **Une part redonne un montant.** Avec le prix public, connu de tous, une part par élève
  redonne une somme par élève. La décision du 22/10 l'accepte : elle interdit d'écrire les
  montants et de compter les personnes, pas de faire le calcul. Le nombre d'élèves n'est
  pas affiché, si bien qu'aucune rémunération mensuelle ne se lit.
- **« Salaire ».** Le statut de prestataire indépendant des enseignants reste à sécuriser
  dans le contrat (`OFFRE:153`) ; « salaire » désigne un emploi salarié et le fragiliserait.
  L'application dit « Rémunération » et n'emploie nulle part « salaire » (`CAND-R10`).
- **Versions.** Chaque changement crée une version datée ; l'ancienne reste lisible. Un
  changement de la part ou d'une règle redemande l'accord ; un changement des charges, non.
- **Encart de recrutement du site.** Il dit « 47 % de ce que paie chaque élève présent »,
  inexact dès qu'il y a une remise, et il porte des montants d'exemple
  (`docs/current/tarifs-2026-10-18.json`, `encart_enseignant`) (`CAND-R11`).
- **Contrat `teacher_nda`.** Il ne contient aucune règle de paie et annonce encore un
  enregistrement audio de 30 jours (`supabase/migrations/0092_publish_teacher_contract_2026_10_jur.sql`),
  supprimé depuis le 18/10. Si l'on rouvre le contrat pour y inscrire les règles de paie
  (`OFFRE:142`), les deux points se corrigent ensemble.

## 7. Questions au directeur

Dire non à l'une ne change pas les autres, sauf `CAND-R01`, qui change la base et donc
tous les chiffres.

| # | Question | Recommandation | Par défaut |
|---|---|---|---|
| `CAND-R01` | Base de la grille : le paiement d'un mois au plein tarif, élève présent à tout (enseignant à 47 %, une colonne enfants, une colonne adultes) ; ou ce que l'académie reçoit en moyenne (enseignant à 44 %, une colonne) ? | La première : c'est la forme du tableau du 19/10 et elle garde le 47 % | La première |
| `CAND-R02` | Conditions courtes, en pourcentages, à la fin de la salle 1 juste avant l'envoi ; répartition en salle 2, par une tuile « À lire avant votre entretien » ; puis sur le profil ? | Oui | Ainsi |
| `CAND-R03` | Écrans : enseignant, Profil > Rémunération ; tuteur, Foyer > fiche de l'élève > Finances ; élève adulte, ses finances dans « Mon espace » ; jamais l'élève mineur ? | Oui | Ainsi |
| `CAND-R04` | Deux lignes de frais : la carte et le change (environ 4,7 %) et le virement vers l'enseignant (environ 1,1 %) ? Le « 2 % » du directeur est-il bien le virement, rapporté à la paie ? Et corriger le virement dans son tableau, resté à sa valeur d'avant le 19/10 ? | Oui | Deux lignes, virement corrigé |
| `CAND-R05` | 47 % du prix public (règle du 19/10, remises et bourses à la charge de l'académie) ou 47 % de ce que la famille paie vraiment (l'enseignant porterait alors une part des remises, et le calcul de la paie change) ? | Prix public | Règle du 19/10 |
| `CAND-R06` | L'enseignant garde les sommes de sa propre paie (« Revenus estimés », « Recevoir mes paiements »), sans taux par élève et par heure ; le tuteur et l'élève adulte gardent le prix qu'ils paient ? | Oui : c'est leur argent, pas le détail des charges | Ainsi |
| `CAND-R07` | Dépenses citées mais pas chiffrées : remboursements de la première semaine, conseil juridique (conditions de vente, statut de prestataire), contrôleur qualité s'il est payé, change vers la monnaie de l'enseignant. Une part chacune, ou listées sous la grille « pas encore comptées » ? | Listées jusqu'à leur chiffrage | Listées |
| `CAND-R08` | Développement : garder la ligne tant que Claude développe ? Que paie la ligne « intelligence artificielle » ? | Garder la ligne ; nommer l'IA d'après son usage réel | Ligne gardée |
| `CAND-R09` | La dépense de lancement pour faire connaître l'académie : répartie sur douze mois, ou nommée à part ? | Répartie | Répartie |
| `CAND-R10` | « Rémunération », jamais « salaire », dans tous les textes ? | Oui | « Rémunération » |
| `CAND-R11` | Site public : pas de grille ; et l'encart de recrutement passe à « 47 % du prix public de chaque élève présent », sans ses montants d'exemple ? | Oui | Encart inchangé tant que le directeur n'a pas répondu (zone protégée) |
| `CAND-R12` | Remises du scénario : 3 % ou 8 à 9 % ? Les bourses et les crédits de parrainage y sont-ils compris ? Et quelle phrase sur l'usage du bénéfice (réserve, bourses, fondateurs) ? | À trancher par le directeur | 3 %, sans phrase d'usage |
