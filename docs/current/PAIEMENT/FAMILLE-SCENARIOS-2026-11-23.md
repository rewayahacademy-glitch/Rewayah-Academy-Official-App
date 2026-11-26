# Paiement d'une famille à plusieurs profils : scénarios, défauts trouvés, solution proposée (23/11/2026)

Demande du directeur (23/11/2026, captures « Top-up ») : « explique-moi ces prix […] regarde bien l'interaction
entre les profils d'une seule famille […] est-ce que quelqu'un peut bloquer l'autre qui n'est pas fautif. Quand
est-ce qu'on pénalise le tuteur sans les enfants, et quand on fait les 2 ? […] rien ne doit être laissé au hasard ».

Statut : **analyse lue dans le code de production** (fonctions lues le 23/11 : `recharge_beneficiaires`,
`rch_offres`, `fac_reste_a_payer`, `fac_mensualite`, `fac_prix_prepaiement`, `acces_paye*`, `fac_etat_paiement`,
`fac_traiter_relances`, `fac_rouvrir_si_negatif`, `com_paires`). **Rien n'est corrigé.** Chaque correction attend
le « oui » du directeur sur la ligne correspondante du §4.

## 1. Les trois prix des captures, expliqués

Famille test : Dyna (tutrice, aussi élève adulte), Hallowx (enfant), Hassanatou (enfant).

| Profil | Ce que dit la base | Pourquoi l'écran montre ça | Juste ? |
| :--- | :--- | :--- | :--- |
| Dyna, 65 $, pas de « + » | Facture de novembre 65 $, à payer. Elle est entrée le 14/11 dans une classe créée le 14/11 (3 séances en novembre). | Tant qu'une facture reste due, le serveur ne propose que « la dette » et « un mois » (`rch_offres`). Ici les deux valent 65 $, donc un seul choix et pas de « + ». Le trimestre et l'année n'apparaissent qu'une fois la dette réglée. | **Non, deux défauts.** D1 : 65 $ plein pour 3 séances. D2 : impossible de payer la dette et le mois suivant d'un coup. |
| Hallowx, 25,30 $ | 55 $ − 4,40 $ (2ᵉ inscrit, −8 %) − 25,30 $ (prorata : entré le 12/11, 4 séances sur 8). | Choix possibles : 25,30 $ (la dette) ou 55 $ (un mois plein ; le reste, 29,70 $, devient du solde). Le serveur ne propose pas l'année tant que la dette n'est pas payée. | Le prix est juste. L'écran n'explique pas d'où vient 25,30 $ (D3). |
| Hassanatou, 594 $ | Aucune classe, aucun enseignant, aucune facture. | Pas de dette, donc le serveur propose le trimestre (157 $) et l'année (594 $ = 55 × 12 − 10 %). | **Non, deux défauts.** D4 : on fait payer un an à quelqu'un qui n'a pas de classe. D5 : 594 $ oublie la remise famille (3ᵉ inscrite −17 %, plafond total 25 %), donc 495 $ attendu : la famille paierait ~99 $ de trop. |

## 2. Les défauts trouvés

- **D1, prorata faux quand la classe démarre en cours de mois** (`fac_mensualite`). Le prorata est calculé ainsi : séances après l'entrée / séances **existantes** de la classe ce mois-là. Une classe créée le 14/11 n'a pas de séance avant le 14/11, donc 3 sur 3 et mois plein. Correction : le dénominateur devient le nombre de séances que l'horaire de la classe donne sur le mois **entier**, que les séances existent ou non.
- **D2, la dette bloque toute avance.** Correction : proposer « dette + 1 mois », « dette + trimestre », « dette + année ». Le trimestre et l'année démarrent au mois suivant, comme aujourd'hui.
- **D3, l'écran ne dit pas pourquoi 25,30 $.** Correction : sous le montant suggéré, une ligne lue dans la facture, par exemple « novembre : 55 $ − 8 % (2ᵉ inscrit) − moitié du mois (entré le 12/11) ».
- **D4, payer sans classe.** Décision du directeur du 23/11 : on paie après le choix du créneau et avant l'affectation de l'enseignant. Correction : un profil sans classe et sans créneau choisi n'est pas proposé à la recharge. Un profil qui a choisi son créneau se voit proposer **un mois seulement**, jamais trimestre ni année avant son premier mois réel.
- **D5, remise famille absente du prépaiement d'un profil sans classe.** `fac_rang_attendu` rend « aucun rang », donc aucune remise. Corrigé de fait par D4 (pas de prépaiement sans classe). Sinon, calculer le rang qu'il aurait.
- **D6, un parent-élève passe grâce à son enfant** (`acces_paye_groupe_pour`, `acces_paye_seance_pour`, `acces_paye_appelant`). Un compte tuteur obtient l'accès à une classe ou une séance dès qu'**un** membre de la famille présent dans cette classe a payé. Dyna est tutrice **et** élève : si elle et son enfant sont dans la même classe, elle entre même si sa propre facture est impayée. Dans l'autre sens, un enfant qui se connecte sur le compte du parent entre grâce au paiement du parent. Correction : pour une séance, l'accès se juge sur le profil qui **assiste** (choisi à l'entrée quand le compte porte plusieurs élèves), jamais sur « quelqu'un de la famille ».
- **D7, les frais d'une contestation bancaire perdue frappent un enfant innocent** (règle FN-115b de `DECISION-TARIFS`). Les frais vont au rang 1 de la commande. Son solde devient négatif, `fac_rouvrir_si_negatif` rouvre sa facture, puis **suspend ses cours**, même si la contestation portait sur un autre enfant. Correction : les frais vont à une ligne de la famille (le tuteur, celui qui a payé). Ils bloquent les nouveaux achats de la famille, jamais les cours déjà payés d'un enfant.

## 3. Scénarios d'une famille, et ce qui se passe aujourd'hui

Règle de fond déjà dans la base, et bonne : **le solde, la facture et la suspension sont par élève**. Le
portefeuille de la famille ne sert qu'à grouper un paiement. Personne n'est suspendu pour la facture d'un autre.
Seules exceptions : D6 et D7.

| # | Situation | Aujourd'hui | Attendu (proposé) |
| :--- | :--- | :--- | :--- |
| S1 | A payé, B non | Seul B est suspendu (au jour de suspension, ou après le délai de 3 jours pour une première facture si « paiement avant cours » est allumé). A continue. | Pareil. |
| S2 | A a payé un trimestre, B est au mois | Indépendants. | Pareil. |
| S3 | A a du solde non consommé, B est en retard | Le solde de A ne couvre pas B (« pas de solde commun »). B est suspendu. | Pareil par défaut. Ajouter un geste de la direction, sur la fiche : « transférer du solde de A vers B », tracé. |
| S4 | A arrête en cours de trimestre | Remboursement du reste (mois commencés au prix normal). Le rang des autres est recalculé le mois suivant. | Pareil. À montrer à la famille : « Ibrahim passe de 2ᵉ à 1ᵉʳ inscrit, sa remise change le mois prochain ». |
| S5 | Le 1ᵉʳ inscrit part | Le 2ᵉ devient 1ᵉʳ et perd ses −8 % au mois suivant. | Pareil (règle du rang). Prévenir la famille avant la facture. |
| S6 | Parent-élève impayé, enfant payé, même classe | Le parent entre (D6). | Le parent est bloqué, l'enfant entre. |
| S7 | Parent-élève payé, enfant impayé, l'enfant se connecte sur le compte du parent | L'enfant entre (D6). | L'enfant est bloqué ; le parent entre en son nom. |
| S8 | Parent-élève suspendu | Ses cours sont coupés. Il garde l'application, la recharge, les messages à la direction et la gestion de ses enfants. | Pareil. |
| S9 | Contestation bancaire perdue sur le paiement de B | Les frais tombent sur le rang 1 (peut-être A) et peuvent suspendre A (D7). | Les frais vont à la famille. Nouveaux achats bloqués jusqu'au règlement. Cours payés intacts. |
| S10 | Paiement groupé A+B, remboursement de B | Seule la part de B est rendue. | Pareil. |
| S11 | Nouveau profil sans classe | Trimestre et année proposés (D4). | Rien proposé avant le créneau ; un mois seulement après. |
| S12 | Prix spécial ou accès offert à A | Calculé pour A seul. Il n'entre pas dans le rang des autres ? **À vérifier** (`fac_rang_attendu`). | Un profil offert ne prend pas le rang 1 au détriment des autres : à trancher. |
| S13 | Messages avec l'enseignant | Ouverts si au moins un élève concerné de la famille a payé. | Pareil, par classe. |

## 4. Quand pénaliser le tuteur, l'enfant, les deux (proposition à valider)

- **L'enfant seul** (cas normal) : sa facture est impayée. Ses cours sont suspendus, puis sa place est libérée le 16. Ses frères et sœurs et le tuteur ne sont pas touchés.
- **Le tuteur seul** : il porte une dette de **famille** (frais de contestation perdue, D7 ; ou paiement annulé par la banque). Il ne peut plus inscrire un nouvel enfant, demander une nouvelle classe ni prépayer tant que la dette reste. **Aucun cours déjà payé d'un enfant n'est coupé.** S'il est aussi élève, ses propres cours suivent la règle de l'enfant (sa facture à lui).
- **Les deux** : seulement sur décision de la direction, depuis la fiche (fraude avérée, insultes, faux compte). Jamais automatiquement.

## 5. Ordre de correction proposé (une PR par ligne, après le « oui »)

1. D6 (accès jugé sur le profil qui assiste). C'est une fuite et un risque de blocage.
2. D1 (prorata), puis correction de la facture de novembre de Dyna, par annulation et réémission avec motif.
3. D4 et D5 (rien sans créneau ; un mois seulement avant le premier mois réel).
4. D7 (frais de contestation à la famille).
5. D2 et D3 (« dette + avance », et l'explication du montant).
6. S3 (transfert de solde par la direction) et S12, si le directeur le veut.

## 6. Décisions du directeur et du pilote (23/11/2026, soir) — EN VIGUEUR

Directeur : « Je te donne le feu vert et carte blanche pour travailler cette question de paiement du début à la fin
avec tous les scénarios […] Il ne faut jamais permettre aux gens de frauder ou bien de faire des erreurs qui vont
coûter ni à la famille, ni à l'académie, ni aux enseignants. »

1. **L'interface explique toujours (directeur, règle UX).** « Il faut dire quoi, quand et pourquoi. » Pour chaque
   profil, l'écran de paiement montre la synthèse ligne par ligne, lue dans le serveur, jamais calculée par l'écran :
   prix du mois, remises **appliquées** (laquelle, combien, pourquoi), remises **non appliquées** et pourquoi
   (« pas de remise famille : 1ᵉʳ inscrit », « plafond de 25 % atteint », « prix spécial : non cumulable »), prorata
   (« entré le 12/11 : 4 séances sur 8 »), et toute dette d'abord : « vous payez d'abord 25,30 $ de novembre, puis
   2 mois d'avance (décembre, janvier) ». Un montant qui peut surprendre a toujours sa phrase.
2. **Remise du 3ᵉ inscrit et suivants : 15 % au lieu de 17 %** (directeur : « peut-être il faut revenir à 15 […]
   c'est à toi de voir » ; pilote : 15 %, marge préservée). Le 2ᵉ reste à −8 %, le plafond cumulé reste à 25 %.
   Se fait par une nouvelle version de la politique commerciale (une version publiée est immuable), puis
   `DECISION-TARIFS`, `tarifs-2026-10-18.json` et le site public le même jour. Les factures déjà émises ne changent pas.
3. **Accès offert, prix spécial, bourse (pilote, « pour le bien de l'académie et de la famille »)** : un tel profil
   **ne prend pas de rang** dans la famille. Il ne reçoit pas de remise famille (non cumulable, règle existante) et
   ne fait pas descendre les autres : les payants gardent leur rang entre eux. Ainsi la famille ne perd rien et
   l'académie ne donne pas deux fois.
4. **Pas de transfert de solde entre profils** (directeur : « l'application va risquer de devenir une wallet […] des
   questions juridiques »). Le solde reste par élève. Un paiement groupé n'est qu'un seul passage en caisse.
   S3 : refusé.
5. **Payer de 1 à 12 mois, librement** (directeur : « 1 mois, 2 mois, 3 mois, ainsi de suite »). Remise de
   prépaiement : 1 et 2 mois sans remise ; **3 à 11 mois −5 %** ; **12 mois −10 %** (valeurs de la politique en
   vigueur, jamais en dur). Le plafond cumulé de 25 % s'applique. Une dette est toujours payée d'abord et affichée
   à part. Remboursement : règle existante (mois commencés au prix normal, sans la remise de la formule, le reste
   rendu).
6. **Pas d'avance sans classe** : un profil sans classe ni créneau choisi ne se voit rien proposer. Avant son
   premier mois réel de cours : un mois seulement.
7. **Un compte = une personne** (directeur : « que personne ne puisse utiliser le compte de l'autre »). L'accès à
   une séance se juge sur le profil connecté et sa propre place dans la classe, jamais sur « quelqu'un de la
   famille ». Un tuteur assiste à la classe de son enfant seulement en accompagnant, sans compter comme élève, et
   jamais si l'enfant n'a pas payé. Une seule connexion à la fois par profil dans une séance.
8. **Frais de contestation bancaire perdue : à la famille (le payeur), jamais sur le solde d'un enfant.** Ils
   bloquent les nouveaux achats et inscriptions de la famille, jamais les cours déjà payés.
