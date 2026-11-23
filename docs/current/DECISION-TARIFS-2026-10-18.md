# Décision : offre et tarifs (directeur, 18/10/2026 ; paie des enseignants revue le 19/10/2026)

**Source unique des prix, remises, règles de paiement et paie des enseignants**, pour l'application et le site public. Une valeur qui change ici change aux deux endroits le même jour. systeme.io n'a aucun lien avec ce projet (directeur, 19/10/2026).

- Document du directeur, texte intégral : `docs/current/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md` (copie fidèle de son document « Offre et tarifs Rewayah Academy », https://claude.ai/code/artifact/bb43bdab-2d75-41c7-ad65-768eba22d5a2).
- Valeurs lisibles par un programme : `docs/current/tarifs-2026-10-18.json`. L'application lit ses prix en base (politique commerciale publiée) ; le site public lit ce fichier.
- Le directeur l'a dit : **c'est le dernier passage sur les tarifs**. Aucun agent ne change une valeur sans nouvelle décision datée.

## Décisions du directeur et du pilote du 23/11/2026 : devise, taxes, remboursement, moment du paiement (PAIEMENT-UNIFIE)

Source : `docs/current/PAIEMENT/STRATEGIE-PAIEMENT-2026-11-23.md` (§6, décisions datées). Elles prévalent sur toute phrase contraire de ce document, du site public et de `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`.

- **Devise : dollars américains seulement.** 55 $ par mois (enfant, 6 à 17 ans), 65 $ (adulte, 18 ans et plus), hors taxes ; la paie des enseignants est aussi en dollars. Le site et l'application ne promettent plus l'euro, la livre ni le dollar canadien : « en dollars américains ; votre banque convertit si besoin ».
- **Taxes.** La société est au Royaume-Uni, pas encore enregistrée à la TVA. Stripe Tax est préparé derrière un réglage (`app_config`, `paiement.taxe_stripe_active`, **éteint par défaut**) : `automatic_tax` ne s'allume qu'une fois les enregistrements fiscaux faits dans le tableau de bord de Stripe. Le serveur accepte alors un total payé supérieur au prix (la taxe, 30 % au plus) ; le crédit de la famille reste le prix hors taxes. Textes : « taxes éventuelles calculées à l'achat selon votre pays ».
- **Remboursement : une seule règle.** Dans les **14 jours** qui suivent le **premier paiement confirmé**, la famille peut annuler et est remboursée de ce qui n'a pas été suivi (le reste du mois) ; ensuite, l'arrêt est possible à la fin du mois en cours. Le calcul reste `private.fn115c_montant_propose`. **La règle du 07/11** (« mois réservé non remboursable », `A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) **est retirée** : elle contredisait celle du 02/11 que le code applique.
- **Moment du premier paiement.** Il est demandé **après le choix des créneaux** (la famille voit ses classes) et **avant l'affectation de l'enseignant et le premier cours**. Délai de **3 jours** (`paiement.delai_jours`) avant que la place soit libérée. Plus de premier cours gratuit sans facture échue : la porte `private.acces_paye` dit « jamais payé » (réglage `paiement.premier_avant_cours`, éteint par défaut tant qu'aucun paiement Stripe réel n'a abouti).
- **Texte à la famille** (fr, en, ar, voix de l'académie) : « Nous recevons beaucoup de faux comptes, de spam et d'arnaques. Nous ne pouvons pas engager un enseignant pour un compte venu par curiosité. Payer avant le premier cours nous montre que vous êtes sérieux. Vous pouvez annuler dans les 14 jours : nous remboursons ce qui n'a pas été suivi. » Le nombre de jours est lu de la politique, jamais écrit en dur.
- **Reçu** : celui de Stripe (envoi du reçu Stripe au client à activer dans le tableau de bord) ; rien de neuf côté serveur.
- **Gestes de la direction sur la fiche de l'élève** : Prix spécial et Exonérer (feuilles de `bourses_eleves`), Reporter (« accès offert jusqu'au… »), Demander maintenant (`demander_paiement_maintenant`, sans table).

## Décision du directeur et du pilote du 23/11/2026 (soir) : prix d'une famille, N mois, remise du 3e inscrit à 15 % (PAIEMENT-FAMILLE-PRIX)

Source : `docs/current/PAIEMENT/FAMILLE-SCENARIOS-2026-11-23.md` §6. **Prévaut sur toute valeur contraire de ce document**, de `tarifs-2026-10-18.json` et du site public (23/11/2026, politique `v2.2.0`).

- **Remise du 3e inscrit et des suivants : 15 % au lieu de 17 %** (le 2e reste à -8 %, le plafond de cumul à 25 %). Une version publiée étant immuable, la base publie `v2.2.0` (copie de `v2.1.0`, remises de rang 80 et 150 pour mille), en vigueur au plus tôt le 1er décembre 2026, jamais rétroactive : les factures déjà émises ne changent pas. Une fratrie de trois enfants paie 55 + 50,60 + 46,75 = **152,35 $** par mois (quatre : 199,10 $) ; deux enfants 105,60 $ et deux adultes 124,80 $ ne changent pas. Avec 15 % et 10 % l'année du 3e inscrit tombe pile sur le plafond de 25 % (495 $).
- **Un profil à bourse, accès offert ou prix spécial ne prend aucun rang** : il ne reçoit pas de remise de famille (non cumulable) et ne fait pas descendre les autres, qui gardent leur rang entre eux.
- **Payer de 1 à 12 mois, au choix** : 1 et 2 mois sans remise de prépaiement ; 3 à 11 mois le taux trimestriel de la politique (-5 %) ; 12 mois le taux annuel (-10 %) ; remise de famille incluse, plafond de 25 % appliqué ; tous les montants sont lus de la politique (`prepaiement_trimestriel_pour_mille`, `prepaiement_annuel_pour_mille`, `cumul_max_pour_mille`), jamais écrits ailleurs. Le montant d'une offre est celui du serveur : aucun montant libre.
- **La dette d'abord et à part** : une offre = la dette (factures à financer, ou première facture du mois en cours, au prorata) **plus** N mois d'avance. Les mois d'avance commencent le mois suivant.
- **Aucune offre sans classe ni créneau choisi** ; créneau choisi sans classe, ou classe sans enseignant : **un mois seulement**.
- **Prorata du premier mois** : le dénominateur est le nombre de séances que l'horaire de la classe donne sur **tout le mois**, qu'elles existent ou non ; le numérateur, celles à partir de l'entrée du profil.
- **Remboursement d'un paiement de N mois** : règle inchangée (mois commencés au prix mensuel normal, le reste rendu), calculée sur la seule part « avance » ; la dette n'est jamais rendue. Constat laissé au directeur : le « prix mensuel normal » est le tarif plein, sans la remise de famille déjà accordée.

## Décision du directeur du 01/11/2026 : remboursements, contestations, accès sans paiement (FN-115)

Le directeur l'a dit, le 01/11/2026 :

- « normalement on paye avant de commencer les cours »
- « quelqu'un qui ne paye pas n'a pas accès aux sessions, ni aux ressources, seulement à son espace pour voir son profil, son historique et éventuellement pouvoir payer »
- « l'académie ne paye pour personne, ni les frais de remboursement, ni les taxes. on nous paye, pas l'inverse »
- pour la répartition d'un remboursement partiel et l'origine du remboursement : « à toi de jouer le rôle de comptable/avocat […] dans l'intérêt de tout le monde »
- puis, sur les sept points ci-dessous : « oui pour les 7 points » (22:24 UTC).

Ce qui est décidé :

1. **Un mois remboursé n'est plus payé.** L'accès aux séances et aux ressources de ce mois s'arrête tout de suite, sans rappels ni délai. Le compte garde son espace : profil, historique, paiement.
2. **Remboursement partiel d'un paiement qui couvrait plusieurs élèves** : la direction choisit l'élève. On ne rembourse que les séances non suivies ; les séances suivies restent dues.
3. **Trimestre ou année payés d'avance, puis remboursés** : les mois déjà suivis sont comptés au prix mensuel normal, sans la remise de la formule, et le reste est remboursé. Les mois à venir redeviennent à payer.
4. **Contestation d'un paiement auprès de la banque** : le prestataire reprend l'argent dès l'ouverture, donc l'accès des élèves concernés est suspendu comme pour un impayé. Il revient de lui-même si l'académie gagne.
5. **Contestation perdue** : remboursement total, selon le point 1. **Les frais que le prestataire facture pour la contestation sont portés au solde du foyer**, jamais à la charge de l'académie.
6. **Qui est prévenu** : la famille, par e-mail et dans l'application ; la direction, dans l'application, qui en garde la trace ; l'enseignant, jamais.
7. **D'où part un remboursement** : de l'écran Finance de l'application. Le serveur y propose le montant juste, selon les points 2 et 3 ; la direction confirme ; l'application rembourse par le prestataire. Un remboursement fait directement chez le prestataire est capté aussi.

**Décision du directeur, 02/11/2026 (remplace l'arbitrage du pilote ci-dessous)**, après comparaison avec la loi européenne (directive 2011/83/UE : 14 jours de rétractation pour un service à distance, la part déjà fournie restant due) et avec les pratiques d'Anthropic, Google et Microsoft. Réponse : « oui pour le remboursement, et cela doit être mentionné sur tout le projet » :
- **pendant le délai de rétractation** (14 jours à compter du paiement), la famille est remboursée de ce qu'elle a payé, moins les séances déjà suivies ;
- **ensuite, arrêter reste un droit, jamais un geste** : une formule payée d'avance (trimestre, année) est remboursée du reste, une fois les mois commencés comptés au prix mensuel normal, sans la remise de la formule (point 3) ;
- **rien en dur** : le délai est la valeur `remboursement_delai_jours` de la politique en vigueur, réglée par la direction (14), et les textes l'affichent depuis la politique ;
- **partout** : conditions et page « Annulation et remboursement » de l'application (fr, ar), site public, e-mails, fiche FN-115c, documents de `docs/current/`. « Première semaine » et « sauf geste de la direction » disparaissent.

~~**Arbitrage du pilote, même jour**, pour accorder ces points avec les conditions publiques (« première semaine remboursée ») :~~ (caduc depuis le 02/11/2026)
- dans la première semaine, on rembourse ce qui a été payé, moins les séances suivies (point 2) ;
- après la première semaine, une formule payée d'avance n'est remboursée que sur geste de la direction, avec le calcul du point 3.

**À qui vont les frais d'une contestation perdue** (pilote, 02/11/2026, FN-115b) : le solde se tient par profil d'élève. Les frais vont donc au **plus ancien bénéficiaire de la commande contestée** (le premier profil de la commande, rang 1), jamais à un enfant pris au hasard, jamais à l'académie. Ils apparaissent comme une ligne d'ajustement négative à son solde, que le paiement suivant du foyer couvre.

**Opposabilité des frais de contestation** : le point 5 n'est opposable à une famille que si les conditions le lui disent **avant** qu'elle paie. Les textes « Conditions » (section 4) et « Annulation et remboursement » (sections 1, 2, 4 et la nouvelle section 6 « Contester un paiement auprès de sa banque ») le disent depuis le lot FN-115a. La page de paiement y renvoie, juste sous « Payer ».

Ce qui reste à faire, par lots datés : le bouton « Rembourser » de l'écran Finance (FN-115c, **présent dans le code** depuis le 02/11/2026, voir ci-dessous ; non prouvé en production), et la règle « pas payé : ni séances ni ressources » appliquée aussi aux ressources (lot B ; aujourd'hui la suspension ne ferme que l'entrée en séance). Le site public (`site-public/content/pages.json`) porte encore l'ancien texte « remboursé en entier » : sa mise à jour revient à qui tient `site-public/`.

**FN-115c, « Rembourser » depuis l'écran Finance (pilote, 02/11/2026).** D'abord ce qui n'est pas tranché ou pas prouvé :
- **La règle de délai est tranchée** (directeur, 02/11/2026, voir plus haut) : 14 jours de rétractation, le payé moins les séances suivies ; ensuite, droit d'arrêter, mois commencés au prix mensuel normal sans la remise, le reste rendu ; jamais « sur geste de la direction ». Tout le calcul tient dans une seule fonction (`private.fn115c_montant_propose`), et le délai se lit dans la politique (`remboursement_delai_jours`). **La politique en vigueur porte 14** (version v2.1.0, publiée le 03/11/2026 ; la phrase « elle porte encore 7 », écrite avant, est corrigée le 23/11/2026) : une version publiée est immuable, le passage de 7 à 14 s'est fait par cette nouvelle version (lot REMB-14).
- **L'appel au vrai Stripe n'est pas prouvé.** Le robot le remplace par un faux Stripe local, de banc. La preuve réelle sera le premier remboursement du directeur.
- **Le webhook `charge.refunded` n'est prouvé que par le scénario SQL** : le passage aux écritures, le profil visé et la demande soldée. Sa signature n'est pas testée en local.
- **Limite connue.** Si deux remboursements de l'application sont en cours en même temps sur le même paiement, le cumul rendu par Stripe va au profil du plus récent. Il n'y a qu'une seule demande en cours par paiement et par élève, mais deux élèves d'une même commande peuvent en avoir chacun une.

Ce qui est fait (migration `20261105100000_fn115c_rembourser.sql`, sans DELETE, DROP ni TRUNCATE ; fonction Edge `remboursement-stripe`) :
- **Le prix d'une séance suivie** est tiré de la politique en vigueur le jour du paiement : prix mensuel normal, sans remise, divisé par `seances_par_mois` (13 : 5 500 / 13 = 423, 6 500 / 13 = 500, le barème du 18/10). Il n'est jamais écrit en dur.
  - Les deux colonnes nouvelles de la politique sont posées par `ADD COLUMN` avec un défaut, aussi pour v1.0.0 et v2.0.0, que l'on ne modifie pas autrement : 13 séances, 7 jours.
- **La direction seule** (admin, compte valide) lit les paiements d'un élève et les élèves remboursables, et confirme. Un tuteur, un comptable et anon sont refusés.
- **« Rembourser » n'apparaît**, dans le menu « … » de la ligne de l'élève (Finance > Paiements), **que si le serveur dit l'élève remboursable**. Il disparaît quand plus rien n'est à rendre.
- **La confirmation** est plafonnée au montant proposé et idempotente :
  - la même clé rend la même demande ;
  - une demande déjà en cours pour ce paiement et cet élève est rendue telle quelle, sans en créer une seconde ;
  - un double clic ne crée qu'un remboursement.
- **La fonction Edge** relit la demande avec le jeton de la personne, jamais un montant venu du client. Elle rembourse chez Stripe avec la clé d'idempotence `remboursement-<demande>` et note l'identifiant du remboursement. Un échec libère le paiement pour une nouvelle demande.
- **Le webhook** retrouve le profil visé par l'identifiant du remboursement, jamais par une métadonnée modifiable chez le prestataire, et passe `p_profil` à `remboursement_evenement_stripe` (FN-115b). Un remboursement fait hors de l'application reste rendu au prorata.
- **Preuves :**
  - `supabase/tests/scenarios_fn115c_rembourser.sql` : vert sur une base neuve, plus de 25 contrôles. Il n'est pas encore dans la CI : la ligne de `ci.yml` est donnée au pilote.
  - Tests Deno de `_shared/stripe_test.ts` (la CI ne les rejoue pas).
  - `test/features/admin_finance/remboursement_direction_test.dart`.
  - Robot `tool/e2e/fn115c_rembourser.mjs` : pile locale et faux Stripe, à 390 et 1440, vert. Il prouve le menu, la feuille et son montant, une seule demande et une seule requête Stripe sur un double clic (clé, payment_intent, montant, profil), l'identifiant noté, le menu disparu ensuite, et le refus de la fonction Edge pour un tuteur (403). Captures : `docs/current/captures/E2E/fn115c-rembourser/`.

## Décision du directeur du 22/10/2026 : la répartition du paiement, montrée en pourcentages

Le directeur l'a dit, en deux messages du 22/10 :

- « Il faudra penser à ajouter le salaire et comment il est déterminé […] il y a une grille qui montre tous les calculs. 47 % pour l'enseignant, 2 % pour les frais de transaction et les autres dépenses jusqu'au bénéfice de l'académie. Donc ça, il faut l'ajouter. […] je pense que ça ne doit pas être au début de la première salle […] Je pense sur la deuxième salle. […] cette grille-là et ce calcul doit être affiché sur le profil de l'enseignant. Je pense même à l'afficher sur le profil du tuteur et de l'élève adulte. C'est pour la transparence, parce que notre académie est une académie islamique. »
- « Faut pas donner les petits détails là, 1,99 ou bien 1,57 ou bien 25$ pour Superbase et ainsi de suite. Tu donnes les pourcentages […] Celui qui voudra les détails exacts devra en demander à l'administration. Et ne néglige aucune dépense. Écris tout, mentionne tout. On veut la transparence totale, mais pas les prix. Les pourcentages. […] pour l'administration, il ne faut pas dire administration, une personne, tel pourcent. Non. Il faut juste dire ce que l'administration est payée […] du paiement de l'élève, c'est tel pourcent. »

Ce qui est décidé :

- **La répartition du paiement d'un élève est montrée**, pour la transparence : à l'enseignant (profil, et dans le parcours de candidature), au tuteur et à l'élève adulte.
- **En pourcentages seulement.** Aucun montant dans cette répartition : ni taux par élève et par heure, ni charge en dollars. Qui veut les montants les demande à l'administration.
- **Toutes les dépenses y figurent**, sans exception, jusqu'au bénéfice de l'académie, et la somme fait 100 %.
- **Chaque poste se dit par sa part du paiement de l'élève** (« l'administration : tel pourcentage du paiement de l'élève »), jamais par un nombre de personnes.

Ce qui reste une proposition, à soumettre au directeur : la salle exacte où la répartition entre dans le parcours de candidature, l'écran qui la porte pour chaque rôle, la base de calcul et la façon de dire qu'il s'agit d'une estimation, le « 2 % » (le document ne porte aucune ligne de 2 % : les frais de carte et de change valent environ 5 % de l'encaissé, et les frais de virement vers l'enseignant environ 2 % de sa paie plus 1 $ par versement), et le sort des montants que l'enseignant voit déjà de sa propre paie. Proposition : `docs/current/CANDIDATURES/PROPOSITION_REPARTITION_PAIEMENT.md`.

**Langues de cours (directeur, 22/10/2026)** : l'arabe n'est pas une langue de cours ; poular, peul et fulfulde sont une seule langue. Les encarts et `regles_publiques.langues` de `tarifs-2026-10-18.json` sont corrigés le 22/10 ; la mention de l'arabe dans le document source (`OFFRE_ET_TARIFS_2026-10-18.md`, conservé tel quel) est caduque. Détail : `DECISION-CANDIDATURES-2026-10-21.md`, section 1 ter.

## Décision du directeur du 19/10/2026 : l'enseignant reçoit 47 % du prix

Le directeur l'a dit : « je confirme le nouveau tarif, il faut juste ramener le prof adulte à 47 % comme l'enfant ; tu rends le nouveau le standard partout ». Elle remplace la part de 22,5 % (enfant) et de 30 % (adulte) du 18/10, qui venait d'une erreur : le « 22,5 » visé était un montant par élève et par mois, appliqué à tort comme un pourcentage du prix.

- **Part de l'enseignant : 47 % du prix public**, pour l'enseignant des enfants comme pour celui des adultes.
- **Ramenée à l'heure, par élève présent** : 1,99 $ pour un enfant (55 $ pour 13 h), 1,57 $ pour un adulte (65 $ pour 19,5 h). Soit 25,87 $ et 30,62 $ par mois pour un élève présent à toutes les séances ; 9,95 $ et 9,42 $ de l'heure pour un groupe plein.
- **Maintenu du 18/10** : paie à l'élève présent, élève absent non payé, remises des familles sans effet sur la paie, durée due, versement avant le 5, paie en attente si le cahier de la semaine manque.
- **Abandonné** : la règle « le taux enfant reste inférieur au taux adulte » (à l'heure, l'enfant vaut désormais plus), le palier de fidélité (1,05 et 1,15 $) et le plafond (1,30 et 1,50 $) : le plafond est le taux lui-même jusqu'à une nouvelle décision.
- **Charges du mois revues** (document du directeur, onglet « Décision du 19/10 ») : visio 150 $, application 290 $, e-mails 20 $, stockage 5 $, comptable 150 $, développeur 600 $, administration 500 $. À 100 élèves : 2 497 $ d'enseignants, 919 $ de résultat net (16 %), point mort à 58 élèves.

## Consigne du directeur du 18/10/2026 (paie remplacée le 19/10)

Part de l'enseignant pour les **enfants portée de 21 % à 22,5 %** du prix ; **adultes inchangés à 30 %**. Taux arrondi au centime : **0,95 $ par élève présent et par heure** pour un enfant (0,95 x 13 h / 55 $ = 22,45 %), **1,00 $** pour un adulte. Tous les chiffres qui en dépendent ont été recalculés dans le document (groupe plein enfant 4,75 $ de l'heure ; paie à 100 élèves 1 401 $ ; résultat net 2 519 $, 45 % ; point mort 19 élèves).

## Les valeurs (résumé)

| Règle | Enfant (6 à 17 ans) | Adulte (18 ans et plus) |
|---|---|---|
| Prix mensuel hors taxes | 55 $ | 65 $ |
| Trimestriel (-5 %), annuel (-10 %) | 157 $, 594 $ | 185 $, 702 $ |
| Séances | 3 x 60 min, pause 5 min | 3 x 90 min, pause 10 min |
| Groupe | 3 à 5 | 3 à 6 |
| Séance due à partir de | 45 min de présence | 70 min |
| Paie enseignant (19/10) | 1,99 $ par élève présent et par heure | 1,57 $ |
| Part de l'enseignant (19/10) | 47 % | 47 % |

Remises : 2e inscrit du foyer -8 %, 3e et suivants -15 % (23/11/2026, `v2.2.0` ; -17 % avant), trimestre -5 %, année -10 %, parrainage 20 $ de crédit chacun, bourse -30 % (non cumulable, 5 % des élèves au plus, revue tous les 6 mois). Foyer, prépaiement et parrainage cumulés : 25 % du prix au plus. Pas d'essai gratuit : remboursement pendant 14 jours à compter du paiement, moins les séances déjà suivies (décision du 02/11, confirmée le 06/11). Renouvellement le 1er ; relances J-7, J-3, J-1 ; grâce du 1er au 3 ; suspension le 4 ; place gardée jusqu'au 15 (14 jours après le renouvellement), libérée le 16 (23/10/2026, point 4 ci-dessous).

## Ce que cette décision remplace

Toute valeur ci-dessous est **caduque** ; ne pas la reprendre, même si elle figure encore dans un document de `docs/current/sources-directeur-2026-10/` (ces sources sont conservées telles quelles, comme archives).

| Ancienne valeur | Où on la trouve | Remplacée par |
|---|---|---|
| 50 $ enfant, 60 $ adulte (et 40 à 60 $) | Guide Finance V4 FIN4-01 ; plan V3 ; dossier maître (§13, CFO) ; politique `v1.0.0` en base ; simulation du 17/10 | 55 $ et 65 $ hors taxes |
| 2 séances d'essai gratuites | Guide Finance V4 FIN4-10 ; dossier maître ; politique `v1.0.0` | Aucun essai ; remboursement dans les 14 jours suivant le paiement, moins les séances suivies (02/11) |
| Remise foyer 0 / 5 / 10 % ; ou 5 $ au 3e et 7 $ au 4e | Dossier maître (contrat CFO) ; politique `v1.0.0` ; simulation du 17/10 | -8 % au 2e, -15 % au 3e et suivants (23/11/2026 ; -17 % du 18/10 au 22/11) |
| Paie horaire par classe (4 $ de base, 7 $ de plafond) ; ou 20 $ par élève | Règles de rémunération en base ; politique `v1.0.0` ; dossier maître (proposition) | 1,99 $ (enfant) et 1,57 $ (adulte) par élève présent et par heure, 47 % du prix (19/10) |
| Crédits prépayés qui expirent (50 $ pour 60 jours) | Specs d'origine | Abonnement mensuel renouvelé le 1er |
| Place gardée 7 jours ; puis 14 jours après la suspension, libérée le 18 (version du 18/10 de ce document) | Guide Finance V4 §1.7 ; politique `v1.0.0` ; document du directeur du 18/10 | Gardée jusqu'au 15, libérée le 16 (23/10/2026) |
| Groupe ouvert à 4 élèves | Politique `v1.0.0` (`minimum_ouverture`) | 3 élèves |
| 0,95 $ (enfant) et 1,00 $ (adulte) par élève présent et par heure, parts de 22,5 % et 30 % ; palier 1,05 et 1,15 $ ; plafond 1,30 et 1,50 $ | Version du 18/10 de ce document et du document du directeur ; politique `v2.0.0` en base avant la migration `20261019130000` | 1,99 $ et 1,57 $, 47 % du prix (19/10) |
| Page publique `/fr/tarifs` (« les deux premiers membres gardent leur tarif ») | `site-public/content/pages.json` | Grille, remises et mentions de ce document |

## Contradictions tranchées

1. **Âge de la formule adulte.** Le document fixait l'adulte à 15 ans ; les règles du programme (29/09, confirmées le 12/10) le fixent à 18 ans. **Directeur, 18/10/2026 : 18 ans.** Enfant 6 à 17 ans (55 $, 3 x 60 min, classe enfant), adulte 18 ans et plus (65 $, 3 x 90 min, classe adulte). Cohortes du programme inchangées (6-9, 10-13, 14-17, 18+) ; aucun mineur dans une classe d'adultes. La pause enfant suit le programme (5 min) et « mode enfant » devient « Interface guidée par défaut de 6 à 9 ans » (vocabulaire et registre du 14/10). Le document du directeur est corrigé en conséquence.
2. **Essai.** Le guide Finance V4 prévoyait 2 séances d'essai ; le document du 18/10 le remplaçait par la première semaine remboursée, elle-même remplacée le 02/11 par le remboursement dans les 14 jours suivant le paiement, moins les séances suivies (formule « première semaine » retirée partout, directeur, 06/11). La politique publiée porte `essai_actif = false`.
3. **Cahier de transmission.** Le document le veut hebdomadaire ; l'application en tient un par séance. Ce n'est pas un tarif : la paie du mois est mise en attente tant que le cahier de la semaine manque, et le passage au cahier hebdomadaire est inscrit comme lot à part dans la passation.
4. **Place d'un impayé.** Le document du 18/10 disait : place gardée 14 jours après la suspension du 4, libérée le 18 ; la base compte les 14 jours depuis le renouvellement du 1er (`v_conservation := v_mois + jours_conservation_place`), soit une place gardée jusqu'au 15 inclus. **Directeur, 23/10/2026 (décision confiée à Claude, « dans l'intérêt de l'académie, on ne peut pas laisser les gens nous manipuler ») : la place est gardée jusqu'au 15 et libérée le 16.** C'est la règle la plus stricte des deux, la plus simple à dire (14 jours après le renouvellement) et celle que la base applique déjà : `jours_conservation_place` reste 14, aucune migration. Le site public l'affiche (`calendrier_paiement.place_liberee_jour` = 16).

## Points ouverts du document, valeurs par défaut appliquées

Le document laisse cinq points au directeur, chacun avec une valeur par défaut. Elles sont appliquées telles quelles tant qu'il ne dit pas autre chose : pause adulte 10 min et séance due à 70 min sur 90 ; observation du parent : deux visites de deux minutes au plus par séance (règle du 31/10, `08` §5 bis) ; élève absent jamais payé ; taux de 1,99 et 1,57 $ (47 %, décision du 19/10) ; groupes adultes séparés hommes et femmes (déjà la règle de l'application).

## Où chaque valeur vit

- **Application** : politique commerciale publiée en base (`politiques_commerciales`, version `v2.0.0`, paie portée à 47 % par la migration `20261019130000`), lue par la facturation, la recharge et les écrans ; paie des enseignants par élève présent (règle de rémunération en base). Aucun montant dans le code Flutter.
- **Site public** : `site-public/` est une zone protégée par le garde-fou ; rien n'y a encore été changé. L'agent qui finira le site applique la consigne ci-dessous.
- **systeme.io** : aucun lien avec ce projet (directeur, 19/10/2026). Les produits et codes de remise qui y étaient listés sont retirés du document du directeur.

## Consigne pour l'agent qui finira le site public

1. Lire les valeurs dans `docs/current/tarifs-2026-10-18.json` (copier ce fichier en `site-public/content/tarifs.json` et le faire lire par `build_site.py`) : jamais un montant tapé dans une page.
2. Page `/fr/tarifs` de `site-public/content/pages.json` : remplacer les sections actuelles (« Aucun montant n'est affiché… », « Les deux premiers membres gardent leur tarif… », caduques) par, dans cet ordre : la grille (deux formules, mensuel, trimestriel, annuel, prix par séance), `encart_remises`, le tableau « Ce que coûte une fratrie » du document (55 ; 105,60 ; 152,35 ; 199,10 $ depuis le 23/11/2026 ; 151,25 et 196,90 $ avant), `mentions_sous_la_grille`, puis les règles de paiement à publier (remboursement dans les 14 jours suivant le paiement, moins les séances suivies, résiliation libre, passage à la formule adulte à 18 ans, taxes, moyens de paiement).
3. Pages `/fr/cours` et `/fr/familles` : `encart_enfant` et `encart_adulte` tels quels. Page `/fr/recrutement` : `encart_enseignant` tel quel.
4. Simulateur (`site-public/styles/site.js`, « Le calcul est momentanément indisponible ») : calculer le total d'un mois complet à partir du fichier. Rang dans le foyer : le 1er inscrit paie le plein tarif, le 2e -8 %, le 3e et suivants -15 % (`remises.foyer`, depuis le 23/11/2026 ; -17 % avant). Le rang suit l'ordre d'inscription : pour un foyer qui mêle enfants et adultes, afficher la fourchette entre l'ordre le plus favorable et le moins favorable. Vérifications : 2 enfants = 105,60 $ ; 3 enfants = 152,35 $ (151,25 $ avant le 23/11/2026) ; 2 adultes = 124,80 $. Toujours « hors taxes ».
5. Le statut des pages (`status: "blocked"`) ne change que sur décision du directeur : les conditions de vente restent à faire confirmer par un conseil (document, section « Règles de paiement »).
