# Recette finale du 07/11/2026 : carnet du directeur, version 2

Le directeur, le 06/11 vers 22:00 UTC : « demain dans la journée on va commencer les tests finaux et le
marketing ». Ce carnet remplace pour ces tests `PARCOURS-OUVERTURE-2026-11-01.md` (version 1). Il garde
seulement ce qu'aucun robot ne peut prouver : de vrais comptes, un vrai téléphone, un vrai paiement,
de vrais e-mails. Tout le reste a déjà été prouvé par le robot de la pile locale (captures dans
`docs/current/captures/E2E/<lot>/`).

État de chaque parcours : **marche** (déjà fait en production, preuve en base), **à essayer** (en
ligne, jamais joué en vrai), **bloqué** (ne peut pas marcher aujourd'hui, avec la raison).

Adresse : https://app.rewayahacademy.com. Relevés de l'ancien garde-cap, base de production en lecture
seule : 06/11 vers 22:15 UTC, puis **07/11 à 07:45 UTC**, après les trois trains de la nuit (train 1
fusionné 00:05, train B 02:34, train C 03:36 UTC ; application publiée sur Vercel).

## État au 07/11, 07:45 UTC

- **En ligne et installé** : tous les lots des trains 1, B et C, et leurs migrations : couleurs de
  profil, confidentialité des candidats, autres revenus (primes et missions), pays de virement (Nigeria,
  Côte d'Ivoire, Sénégal ouverts ; Yémen fermé), photo et accord de publication du candidat, contrôle du
  contenu des pièces d'identité, programme en données (C2), observations du cahier (C3), notes de
  versement de la paie.
- **Incident de la nuit, réparé** : de 03:38 à 07:21 UTC, le dépôt de pièce d'identité a échoué pour
  tous (l'application appelait un contrôle dont la partie serveur n'était pas installée). Réparé côté
  serveur à 07:21 ; **non prouvé par un vrai dépôt** (aucun dépôt depuis).
- **En ligne mais volontairement pas branché** :
  - l'export Wise des coordonnées bancaires (migration 20261110700000 non installée, décision du
    garde-cap) : l'écran d'export échoue s'il est ouvert ;
  - la paie par séance (20261110620000) : la paie reste couverte par le cahier de la semaine, jusqu'à
    la mise en ligne de l'écran de confirmation par séance.
- **Paiements** : toujours aucun paiement abouti (13 expirés, 1 en préparation). E-mails : 686 envoyés,
  aucun en échec. Séances : 13 terminées, 12 prévues.

## Ce qui est faux, bloqué ou non prouvé, d'abord

- **Aucun paiement réel n'a jamais abouti.** Entre le 02/11 et le 06/11, 13 paiements ont été ouverts
  en mode réel (12 de 55 $, un de 175 $). Les 13 ont expiré sans paiement ; aucun remboursement. Le
  chemin jusqu'à la page Stripe marche (13 pages ouvertes) et les messages de Stripe arrivent à l'application ; le paiement lui-même n'est pas prouvé.
  La raison de ces abandons n'est pas lisible d'ici (l'accès Stripe de cette session ne voit que le
  mode test). C'est le premier test à faire, avant tout message de marketing qui invite à payer.
- **Le choix entre Link et la carte** (lot 6, 22 o) : en ligne depuis le train C ; jamais essayé en vrai.
- **Les coordonnées bancaires de l'enseignant** (lot 9, 22 h) : la saisie est en ligne ; l'export Wise
  ne l'est pas (voir plus haut).
- **Aucune invitation de foyer n'a encore été utilisée** (0 en base) et une seule invitation
  d'enseignant existe.

## Ce que la production prouve déjà (06/11, 22:15 UTC)

| Fait | Preuve en base |
|---|---|
| Les e-mails partent | 685 envoyés, aucun en échec : 656 messages d'attente aux candidats (25-29/10), 10 « élève inscrit », 3 « classe créée », 3 « enseignant affecté », 2 « demande reçue », 2 « demande acceptée », 3 avertissements de remplacement |
| Les classes se créent | 18 classes actives |
| Les séances se tiennent | 13 séances terminées (la dernière le 06/11 à 18:00 UTC), 11 prévues jusqu'au 03/12 |
| Une famille et un élève adulte ont fait une demande | 2 demandes (une famille, un élève adulte), 2 acceptées par e-mail |
| Les comptes | 1 direction, 1 enseignant, 4 tuteurs, 6 élèves, tous actifs |

## Gestes du directeur en attente (tenus à jour par le garde-cap)

Ces gestes ne peuvent être faits que par vous, dans un outil où Claude n'écrit pas.

- **Le premier paiement réel de 55 $** (parcours 1), juste après le train qui porte LINK-CHOIX.
- (a) **Turnstile** : après l'installation de la migration 20261110400000 et le contrôle du widget par
  le pilote, poser la Secret Key dans Supabase (Authentication, Attack Protection).
- (d) **Fermer les deux formulaires Google** des candidats, une fois le lien candidat en production.
- (e) **Wise** : télécharger le modèle CSV « Send to bank accounts » en USD (les en-têtes seulement)
  et le donner au lot 9, pour que le fichier exporté suive exactement ce modèle.

Sans urgence, dans la journée du 07/11 :

- (i) **Jetons de connexion** : dans Supabase, Project Settings, JWT Keys, lire si la clé **en usage**
  est ES256 (ou RS256) ou l'ancienne HS256. Relevé de l'ancien garde-cap (06/11, 23:20 UTC) : la liste
  publique des clés du projet contient une clé ES256 ; il reste à voir si elle est la clé en usage ou
  seulement en attente. Cela décide si le gain de vitesse prévu pour `recharge-payer` existe.
- (j) **Police arabe** : coller la page fournie pour `pubspec.yaml` (retrait de NotoSansArabic, lot 4).
- (k) **Deux profils d'enfant fantômes** (9efb8124, encore membre actif de la classe 3302506a, et
  35671199) : décider leur sort sur la page privée fournie.
- (l) **Vidéo anglaise pour les enseignants** : écrans en français avec une voix anglaise, ou attendre
  l'anglais dans l'application.

Déjà tranché le 06/11, plus rien à faire de votre part : les frais Wise sont payés par l'académie
(votre décision) ; sur votre délégation, le garde-cap a décidé : aucun réglage de Link dans Stripe,
l'ancien rail de séance supprimé avec l'ancienne navigation, les objectifs des bases restent une
proposition modifiable, les taux de paie restent 1,99 $ (enfant) et 1,57 $ (adulte).

## Comptes et appareils

Comme la version 1 : un ordinateur (direction, puis enseignant) et un téléphone (famille, élève ou
élève adulte). La salle demande deux appareils en même temps. Une fenêtre privée sur l'ordinateur
ouvre un second compte sans fermer le premier. Pour un nouveau compte, il faut une adresse e-mail
neuve.

## Les parcours

### 1. Payer pour de vrai : bloqué tant qu'il n'est pas fait (priorité 1)

Quand : **le premier geste, juste après le train qui porte LINK-CHOIX** (lot 6). Qui : un tuteur
(téléphone). Une carte réelle, **un vrai paiement de 55 $**.

Déjà prouvé : la page Stripe s'ouvre, et les messages de Stripe arrivent bien à l'application et se
rattachent à leur paiement (13 avis d'expiration reçus et classés). Jamais prouvé : un paiement abouti.

1. Foyer, « Recharger », choisir le mois, « Payer ».
2. La page propose la carte **et** Link, au choix ; aucun code n'arrive sans l'avoir demandé.
3. Payer jusqu'au bout.
4. Retour dans l'application : le **solde est crédité**, le paiement apparaît dans « Paiements » du
   foyer avec son **reçu** ; la direction le voit dans Finance.
5. Puis la direction rembourse ce paiement selon la politique des 14 jours (ce qui a été payé, moins
   les séances suivies). Le remboursement apparaît chez la famille.

Preuve attendue en base : une commande à l'état payé, un événement Stripe « réussi », une ligne de
remboursement.

### 2. Une famille s'inscrit sur un téléphone neuf : à essayer

Qui : famille (téléphone neuf ou fenêtre privée). Une adresse e-mail neuve.

1. Le questionnaire vient **avant** l'adresse e-mail (ENTREE-ORDRE, en ligne depuis le 06/11).
2. Puis l'e-mail, le lien reçu, nom et genre, « Envoyer ma demande », les conditions.
3. Deux enfants : le second s'ajoute ensuite depuis Foyer, « Ajouter un profil élève ».
4. Direction : Personnes, « Demandes », « Accepter la demande ». La famille reçoit l'e-mail
   « demande acceptée ».

### 3. La direction place l'enfant, la famille voit son horaire : à essayer

1. Opérations, « Classes », la classe, « Ajouter un élève ».
2. Famille : l'Accueil montre l'enfant, sa classe, la prochaine séance.
3. Enfant sans classe : la carte « Horaire à choisir », « Me prévenir », puis « Demande enregistrée »
   (ACCUEIL-HORAIRE, train 1).

### 4. La séance : salle, vidéo, page du Coran, reprise de page : marche, sauf la reprise

1. Enseignant et élève rejoignent (la salle ouvre 20 minutes avant).
2. Enseignant : « Outils », « Page », une page ; l'élève la voit.
3. **À essayer** (CAHIER-C1, train 1) : à la séance suivante de la même classe, la préparation dit
   « On reprend page N » avec la dernière page montrée.

### 5. Après la séance : objectifs à renforcer et programme : à essayer

Qui : enseignant, puis direction. Lot 8 : C2 (programme en données) et C3 (observations) en ligne.

1. Direction : Programmes, créer une **version neuve** (la version brouillon n° 1 contient déjà une
   étape), puis « proposition des bases » ; relire les objectifs et les durées, publier.
2. Enseignant, après une séance : dans le cahier, cocher pour un élève un objectif à renforcer, ou
   « prêt pour le petit bilan ».
3. Fiche de la Classe : l'étape de chaque élève, sa date limite, et les observations.

La paie reste au cahier de la semaine (la confirmation par séance n'est pas encore branchée).

### 6. L'enseignant voit ce qu'il gagne : à essayer

Qui : enseignant. REVENUS-VERITE (train 1), plus le point 5 (primes et missions), en ligne au train B.

1. Profil, « Revenus » : le total des heures du mois, avec un titre clair.
2. Chaque séance : ce qu'a rapporté chaque élève présent (1,99 $ enfant, 1,57 $ adulte, par heure) ;
   un élève absent ne rapporte rien ; aucun montant fixe minimum.
3. Le jour de paie, réglé par la direction dans Configuration, « Règles ».
4. Train 2 : « Autres revenus » (primes et missions données par la direction, payables en fin de
   mois).

### 7. L'enseignant renseigne où être payé : à essayer (export Wise non branché)

Lot 9 (FINANCE-ENSEIGNANT). Moyen choisi par le directeur le 06/11 : **Wise**, par un fichier de
paiement groupé (CSV) ; pawaPay et Verto après le lancement. La saisie est en ligne ; l'export Wise attend la migration 20261110700000.

1. Enseignant : renseigne ses coordonnées bancaires. Relues ensuite, elles sont masquées (seuls
   quelques derniers chiffres).
2. Direction (ou comptable) : exporte le fichier de paiement du mois.
3. **Dans Wise : importer ce fichier, vérifier qu'il est accepté, sans valider le paiement.**

### 8. Les candidats enseignants reçoivent leur invitation : à essayer

Qui : direction (ordinateur). CANDIDATS-FLUX, en ligne (partie A le 06/11, partie B au train B).

1. Personnes, candidatures : l'import des formulaires, « Prévenir par e-mail » : l'aperçu dit combien
   recevront le message.
2. Envoyer un petit lot d'abord. La file étale l'envoi par jour.

### 9. L'application garde vos choix : à essayer

Lot 4 (PREFERENCES-WEB) : le thème clair ou sombre et la langue restent après un rechargement de la
page. Lot 5 (COULEUR-PROFIL) : la couleur choisie pour un profil se voit partout.

### 10. Une vraie page d'ordinateur : à essayer

Lot 3 (WEB-BUREAU) : à 1440, plus de téléphone étiré. Page de preuve séparée, première version le 08/11.

### 11. Le site public : marche

Les cinq langues, la racine vers le choix de la langue, les avis en direct (mis en production le 06/11).

## Journal du directeur

| Date | Parcours | Marche / ne marche pas | Capture ou phrase affichée |
|---|---|---|---|
| | | | |
