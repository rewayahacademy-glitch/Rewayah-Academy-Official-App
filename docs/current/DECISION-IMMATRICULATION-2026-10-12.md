# Décision : immatriculation des personnes et accueil des inscrits actuels (directeur, 12/10/2026)

**Statut : validé par le directeur le 12/10/2026, dans la conversation d'orchestration.**

Ce document remplace, pour le **format** du matricule, le complément du 7 octobre
(`docs/orchestration/handoff/2026-10-09/REWAYAH_COMPLEMENT_IMMATRICULATION_IDENTITES_V0_1.md`).
Le directeur a jugé illisible et imprononçable le format `RA-XXXX-XXXX-XXXX` proposé par ce complément.
Le reste du complément s'applique tant qu'il ne contredit pas ce document : registre dédié,
attribution atomique côté serveur, immutabilité, non-réattribution, autorisations, codes propres
à chaque évaluation publiée et critères IMM-01 à IMM-14.

## 1. Format du matricule : `RA-26-4817`

| Partie | Règle |
| :--- | :--- |
| `RA` | Préfixe fixe, pour la marque. Toujours devant. |
| `26` | Les deux derniers chiffres de l'année de la première inscription (date du serveur, en UTC). |
| `4817` | Nombre **tiré au hasard** côté serveur, jamais un compteur. Il a 4 chiffres (`0000` à `9999`) tant que l'année compte moins de 4 500 matricules. Au-delà, le serveur tire sur 5 chiffres. |

- **Chiffres seulement après `RA`** : rien à épeler, aucune confusion entre O et 0 ou entre I et 1, et
  le code se lit de la même façon en français, en anglais et en arabe. Il s'affiche toujours de gauche
  à droite, y compris dans l'interface arabe.
- **Le rôle n'est pas dans le code.** Une personne garde son matricule si elle change de rôle ou en
  cumule plusieurs. Le rôle s'affiche à côté, comme une étiquette traduite dans la langue de l'app
  (Student, Guardian, Teacher…) et calculée à partir des données du serveur, jamais à partir du code.
- **Pourquoi le hasard :** un compteur révèle le nombre d'inscrits et permet de deviner les codes
  des autres. Le hasard ne change rien à la lisibilité.
- **Unicité :** une contrainte d'unicité en base, et un nouveau tirage en cas de collision
  uniquement. Si les tirages échouent trop souvent, le serveur passe à 5 chiffres. Un code est
  attribué dans la même transaction que la création du profil. Il est immuable et n'est jamais
  réattribué, même après un effacement.
- **Saisie :** majuscules et minuscules sont acceptées, avec ou sans tirets ou espaces. Le serveur
  ramène toujours le code à sa forme canonique `RA-AA-NNNN`.

## 2. Les anciens codes disparaissent

Les codes des formulaires Google (`STU/…-RA`, `TUT/…-RA`, `Stu-07-25-…/RA`) et le générateur
« rôle + initiales + compteur » du serveur (`next_immutable_id`) étaient des essais préparatoires.
**Ils ne sont ni repris, ni affichés, ni recherchables.** Le générateur par initiales est retiré. La
colonne `profiles.immutable_id` reste en place pour les vues existantes et reçoit le matricule RA :
il n'y a qu'une seule source de vérité, le registre.

## 3. Connexion par matricule (plus tard, pas en V1)

Le format est choisi pour pouvoir servir un jour d'identifiant de connexion à la place de
l'e-mail. Ce jour-là, trois conditions s'appliquent :

1. Le matricule dit **qui** se connecte. Le mot de passe, ou une autre preuve, reste obligatoire.
   Le code seul ne connecte jamais personne, car il figure sur des fiches et des attestations.
2. La récupération du compte passe par un e-mail ou un téléphone, celui du tuteur pour un enfant.
3. Le serveur limite les tentatives et répond toujours « code ou mot de passe incorrect », sans
   révéler si le code existe.

## 4. Codes des évaluations publiées

Ils restent séparés du matricule et propres à chaque évaluation (complément du 7 octobre, §5),
au format simplifié `EV-NNNN` : des chiffres tirés au hasard, uniques dans l'évaluation.
L'administration choisit d'afficher le code, le nom réel ou les deux, dans les règles du serveur.

## 5. Accueil des inscrits actuels

Les familles et les enseignants déjà inscrits par les formulaires Google ne doivent **pas tout
ressaisir**.

1. **Import préalable, automatique (précisé par le directeur le 12/10 : pas de saisie à la
   main).** Leurs inscriptions sont importées dans l'app comme des fiches « pré-inscrites » :
   foyer, personnes, ce qui est déjà connu. Le chemin des données est le suivant :
   - le directeur télécharge en CSV les onglets « Elèves (Réponses) » et « Enseignants (Réponses) »
     du classeur des formulaires Google (Fichier > Télécharger > CSV), tels quels, sans les retoucher ;
   - il dépose ces fichiers dans l'écran d'administration « Importer les inscriptions » ;
   - le **serveur** lit la disposition des formulaires Google : une ligne par envoi, jusqu'à 5 élèves
     par ligne, tuteur ou adulte. Il en tire les foyers, les tuteurs et les élèves, regroupe les
     envois d'une même adresse e-mail, ignore les lignes de test et signale les doublons ;
   - un **essai à blanc** montre d'abord ce qui sera créé : nombre de foyers, de personnes,
     doublons et lignes rejetées avec leur motif. Rien n'est écrit tant que le directeur n'a pas
     confirmé ;
   - après confirmation, l'import est **rejouable sans doublon** : la même ligne importée deux fois
     ne crée rien de plus. Il est réservé à un administrateur actif, tracé dans le journal d'audit,
     et n'utilise pas de clé `service_role`.

   L'import se développe et se teste sur des CSV inventés, avec la même disposition de colonnes.
   Aucune donnée réelle ne passe par une conversation, un ticket ou une branche Git : les fichiers
   vont directement du poste du directeur au serveur de l'app.
2. **Preuve d'abord.** À la première connexion, la personne prouve d'abord qu'elle possède
   l'adresse e-mail, par un code ou un lien envoyé à cette adresse. Avant cette preuve, l'app ne
   révèle jamais qu'une adresse est connue : l'écran est le même pour tout le monde.
3. **Accueil chaleureux.** Après la preuve, un message d'accueil explique que l'app la connaît déjà
   et la rassure. Elle peut ensuite, sans y être obligée, mettre à jour ce qui existe et ajouter
   de nouvelles personnes (un autre enfant, elle-même comme élève). Seul ce qui manque vraiment pour
   continuer est demandé.
4. **Mot personnel.** Depuis l'administration, le directeur peut joindre un mot d'accueil
   personnel à un foyer pré-inscrit ou à une adresse e-mail attendue (« invitation en attente »).
   Ce mot s'affiche une fois, à la première connexion, en tête de l'accueil, signé par son auteur.
   Il peut être long et nommer la personne et ses enfants. Aucune personne n'est jamais codée en
   dur dans l'app : c'est une fonction générale, et le texte vient de l'administration.
   **Pas de saisie une par une :** chaque foyer importé reçoit automatiquement un mot de bienvenue
   rempli avec les prénoms connus. Dans l'essai à blanc, le directeur coche « a patienté » pour les
   familles qui ont attendu l'app. Ces familles reçoivent alors le mot de patience, rempli lui
   aussi avec leurs prénoms :

   > [Prénom du tuteur], vous nous aviez demandé, il y a longtemps déjà, de vous inscrire, vous et
   > [prénoms des enfants]. Nous vous avions demandé d'attendre, et vous avez attendu, avec une
   > patience et une confiance qui nous ont profondément touchés. Vous faites partie des toutes
   > premières familles de la nouvelle Rewayah Academy. Bienvenue chez vous.
   > [Signature du directeur]

   Le directeur peut retoucher n'importe quel mot avant de confirmer l'import, sans y être obligé.
5. **Ce que voit un tuteur déjà connu (précisé par le directeur le 12/10).** Après la preuve de
   l'e-mail :
   - il est **d'emblée tuteur** de son foyer, sans rien choisir ;
   - il voit **la liste des personnes déjà inscrites** de son foyer, chacune avec son prénom et son
     état : « à jour » ou « à compléter » ;
   - une personne « à compléter » ouvre une mise à jour qui ne demande **que ce qui manque**. Ce
     qui est déjà connu est prérempli et modifiable ;
   - deux actions sous la liste : **« M'inscrire moi aussi »** (le tuteur devient aussi élève, avec
     son propre matricule) et **« Ajouter une autre personne »** (un autre enfant ou un adulte du
     foyer).
6. **Champs obligatoires lors de la mise à jour.** Ce sont ceux sans lesquels l'app ne peut pas
   fonctionner légalement ou techniquement, et que les formulaires Google ne recueillaient pas
   toujours :
   - le pays de résidence et le fuseau horaire, pour les horaires des Classes ;
   - la date de naissance de l'élève, pour la tranche d'âge et les règles applicables aux mineurs ;
   - les consentements en vigueur : conditions d'utilisation, traitement des données d'un mineur
     par son tuteur, et avis d'enregistrement et de contrôle des séances ;
   - la langue de l'interface.

   Tout le reste est **facultatif** et peut être fait plus tard : photo, téléphone, adresse,
   niveau, préférences horaires. Tant qu'une personne n'est pas à jour, elle reste visible dans la
   liste avec son état, sans blocage du reste de l'app. Seule son entrée dans une Classe attend la
   mise à jour.

## 6. Partage du travail

| Lot | Qui | Contenu |
| :--- | :--- | :--- |
| IMM-BACK-1 | Codex | Registre, générateur `RA-AA-NNNN`, attribution dans tous les parcours de création, retrait du générateur par initiales, remplissage de `immutable_id`, lecture et recherche exacte sous autorisation |
| IMM-BACK-2 | Codex | Codes `EV-NNNN` et politique de publication des évaluations |
| IMM-ACCUEIL-BACK | Codex | Fiches pré-inscrites, RPC d'import admin (lecture de la disposition des formulaires Google, essai à blanc, confirmation, rejouable sans doublon, audit), mots de bienvenue et de patience remplis automatiquement, rattachement après preuve de l'e-mail ; tout est testé sur des CSV inventés |
| IMM-FRONT-1 | Claude | Affichage du matricule (copie, gauche à droite), étiquettes de rôle, réglage de publication |
| IMM-ACCUEIL-FRONT | Claude | Écran d'accueil « on vous connaît déjà » avec le mot personnel en tête, liste du foyer avec l'état de chaque personne, mise à jour limitée à ce qui manque, « M'inscrire moi aussi » et « Ajouter une autre personne » ; dans l'administration, l'écran « Importer les inscriptions » (dépôt des CSV, essai à blanc, case « a patienté », retouche facultative des mots, confirmation) |
| RECH-BACK-3 | Codex | Recherche exacte par matricule, après IMM-BACK-1 |
