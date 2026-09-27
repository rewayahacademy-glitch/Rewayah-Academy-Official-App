# Vague Élèves adultes : planches du directeur, comparaison avec l'existant, rectifications

**Date.** 27/09/2026, étape EA-0 (document seulement).

**Sources.**
- `PLANCHE-1..6.png` (dans ce dossier, dans l'ordre des fichiers du directeur du 27/09, 01 h 03 à 01 h 04).
- Document `projet/ressources:specs/07_eleves_adultes/REWAYAH_DECISIONS_FOYER_FAMILLE_V1.md`.
- Règles réutilisables `memoire/ELEVES-ADULTES-2026-09-27.md` (F1 à F24).
- Existant lu sur `ui/enseignant-v1` @ 1108a4a (le plus récent, qui contient `ui/classe-v1` @ d44710a), en lecture seule.

**Règle de la vague** (comme pour l'enseignant) : ne rien jeter sans comparer.
- On garde ce que les planches apportent de mieux.
- On perfectionne l'existant sans le recommencer.
- On construit ce qui manque.
- Tout suit le style de l'entrée en classe (K-42, CL-4).

## 1. Classement

| Planche | Contenu | Format | Rôle principal |
|---|---|---|---|
| 1 | Accueil, Ma classe, Mon espace | 3 téléphones | Élève adulte (ici titulaire homme, Mamadou) |
| 2 | Ma famille (entrée), Ajouter une conjointe (1/2), Ajouter un profil élève (1/2) | 3 téléphones | Titulaire |
| 3 | Ma famille (membres), Départ de la conjointe, Nouvelle invitation indisponible | 3 téléphones | Titulaire |
| 4 | Paiements du foyer, Nouvelle recharge (bénéficiaires), Vérifier la recharge | 3 téléphones | Titulaire |
| 5 | Accueil élève adulte | Ordinateur | Élève adulte |
| 6 | Famille et paiements (membres et soldes) | Ordinateur | Titulaire |

**Rôles touchés.**

| Rôle | Ce qui change | Règle |
|---|---|---|
| Élève adulte seul | Nouvel espace : Accueil, Ma classe, Coran, Mon espace ; entrée « Ajouter ma famille » dans Mon espace. | F20 |
| Titulaire (tuteur existant) | Foyer perfectionné : place adulte, invitation, sortie, délai ; Paiements du foyer et recharge ; retrait du choix « Un proche adulte ». | F2, F5, F9 à F17 |
| Second adulte | Son propre espace élève ; ligne « Forfait famille » dans Mon espace avec « Quitter le forfait famille » et « Demande de reprise du foyer ». Aucune planche : écrans à composer. | F6, F14, F18 |
| Élève enfant | Rien de visible. L'émancipation n'est pas réinventée (F19). | F19 |
| Enseignant | Rien de visible, et la recette le vérifie. | F8 |
| Administration | Deux futurs dossiers distincts (remplacement du second adulte, reprise du foyer), hors ADM-02. Réservés à la vague Admin (R21). | doc §15.4 |
| Questionnaire d'accueil | Réservé à sa vague dédiée (doc §3). Rien ici. | F24 |

## 2. Comparaison planche par planche

Légende :
- **G** = garder de l'existant ;
- **P** = prendre de la planche ;
- **C** = corriger (erreur de la planche ou contradiction avec une règle).

Pour toutes les planches :
- la barre d'état « 9:41 » et les dates de 2024 ne sont pas reproduites (E20) ;
- les pastilles « Actif » ou « Active » sont retirées : c'est l'état normal (E12) ;
- les illustrations décoratives (famille dessinée, horloge à cadenas, grand pictogramme de réussite) sont retirées : on ne remplit pas un vide (K-42 point 1).

### Planche 1, élève adulte

**1.1 Accueil.** Existant : `AccueilElevePage` (695 lignes, fiche ELV-02, six états du bloc principal), carte de séance CL-4 et `EmplacementEntree`.
- G : les six états du bloc principal, la carte de séance partagée, la photo publique de l'enseignant (R18).
- P :
  - la carte « Prochaine séance » dominante, avec la photo de l'enseignant ;
  - « Avant la prochaine séance », 3 actions au plus (R17) ;
  - « Mon parcours » avec « Voir mon historique ».
- C :
  1. « Prochain cours » devient « Prochaine séance », et « Rejoindre le cours » laisse la place au bouton unique d'`EmplacementEntree` : « Préparer l'entrée », puis « Entrer dans la classe » (R4, E11).
  2. « Salle ouverte 15 min avant » est retiré : la fenêtre est rendue par le serveur (E6).
  3. Les trois tuiles de chiffres de « Mon parcours » (12 séances, 3 mois, Niveau 2) deviennent une ligne (K-42 point 4).
  4. Les cases à cocher « Réviser les pages 24 à 26 », « Écouter la récitation (10 min) » et « Préparer vos questions » ne sont pas des tâches permises : la liste ne contient que ce que le serveur demande, et rien ne se coche localement.
  5. Les tuiles du bas « Coran & ressources » et « Ajouter ma famille » sont retirées : l'une double la navigation, l'autre vit dans Mon espace (F20, doc §4).
  6. La salutation tient en une ligne sous le prénom. La cloche reste : le doc §9.3 exige un centre de notifications dans l'application.

**1.2 Ma classe.** Existant : la page Classe de CL-4 côté élève et famille (`classe_tuteur/`, `FicheGroupePage`, `IdentiteGroupe`, `BlocBibliotheque`).
- G : l'en-tête d'identité de la Classe, la carte de séance partagée, la bibliothèque unique (R14).
- P : « À propos de cette classe » en une ligne, « Ressources de la classe » (3 au plus), la liste des participants avec leur photo (E5).
- C :
  1. Pas d'onglets Aperçu, Participants, Ressources : des sections (R3, E13).
  2. La pastille « En cours » n'apparaît que pendant la séance en direct.
  3. « 75 %, Vous progressez bien » est retiré : aucune évaluation qui juge (E8). La progression tient en une ligne rendue par le serveur.
  4. « 8 élèves, Classe en petit groupe » : l'effectif vient des données, jamais une constante (E6).
  5. Le bouton de séance est le même `EmplacementEntree` qu'à l'accueil, sans fork.

**1.3 Mon espace.** Existant : `ComptePage` (élève) et `CompteTuteurPage`, `carte_rubriques.dart`, `PaiementsComptePage` (indisponible, DB-CPT-03), `AccesPage`.
- G : la carte d'identité, les rubriques groupées, la déconnexion à part.
- P : Mes informations, Cours et accès, Paiements, Sécurité, Préférences, Aide et support, À propos ; la ligne « Ajouter ma famille ».
- C :
  1. Le texte de la ligne « Ajouter ma famille » reprend le doc §19 (« Inscrivez vos enfants et invitez un conjoint ou une conjointe… »). La planche dit « votre conjoint » à un titulaire homme : erreur de genre (F3).
  2. La pastille « Nouveau » est retirée (E12).
  3. L'engrenage et la ligne « Préférences » ouvrent la même page : on garde une seule place (E3), comme dans le compte du tuteur.
  4. « Paiements : Abonnements et historique » devient « Paiements » : il n'y a pas d'abonnement au modèle (F9).
  5. Une ligne « Mes accords » est ajoutée (charte 09 §3).
  6. Si le foyer existe, la ligne devient « Ma famille ». Pour le second adulte, elle devient « Forfait famille », avec « Quitter le forfait famille » et « Demande de reprise du foyer » (F14, F18).

### Planche 2, construire la famille

**2.1 Ma famille, entrée.** Existant : `FoyerPage` (`/tuteur/foyer`), titre, « Ajouter un profil élève », membres en un groupe, appareils, « Créer mon profil élève » (indisponible, DB-FOY-01).
- G : toute la page existante et sa composition K-42.
- P : la ligne de la place adulte (« Ajouter une conjointe », « Invitez votre conjointe à rejoindre Rewayah avec son propre compte ») et « À propos du forfait famille » en lien.
- C :
  1. L'illustration de famille est retirée.
  2. « Plan famille » devient « forfait famille », le terme du document.
  3. La barre montre « Foyer » à la place de « Ma classe » : les deux espaces sont séparés (F20). Voir la question sur la navigation (§4).

**2.2 Ajouter une conjointe (1/2).** Existant : rien.
- P : l'en-tête « Un compte personnel pour elle », les champs prénom, nom et adresse e-mail, « Envoyer l'invitation ».
- C :
  1. Le texte d'en-tête reprend le doc §19 : « Votre conjointe utilisera son propre compte. Elle ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés. »
  2. La notice de l'e-mail est accordée au genre de la place (F3) ; « Une seule conjointe peut être lié(e) » est supprimé : la règle d'une seule place se dit par la ligne d'état, pas par une notice (F21).
  3. L'étape 2 est « Vérifier et envoyer » : c'est l'état « Invitation en préparation » du doc §5.2.
  4. Après l'envoi, le message suit seulement la réponse (E7) : « Invitation envoyée », jamais « Mariama a rejoint votre foyer ».
  5. Aucune erreur ne dit que l'adresse existe déjà ou quel genre elle porte (F4).
  6. Variante titulaire femme : « Ajouter un conjoint », « Un compte personnel pour lui » (F3).

**2.3 Ajouter un profil élève (1/2).** Existant : `FormulaireProfilEleve` (choix « pour qui », prénom, nom, âge), serveur réel pour un mineur.
- G : le formulaire existant et sa création réelle ; « Créer mon profil élève » pour le titulaire.
- P : l'en-tête « Un profil sous votre responsabilité ».
- C :
  1. Le choix « Un proche adulte » (`PourQui.procheAdulte`, DB-FOY-02) est retiré de l'écran : un adulte n'est jamais un profil géré (F2, doc §22.9).
  2. La planche demande une date de naissance, l'existant un âge : on garde l'âge (serveur réel) et la date de naissance devient une ligne BR-1 (question au directeur).

### Planche 3, vivre la famille

**3.1 Ma famille, membres.** Existant : `FoyerPage` et `ligne_membre.dart`.
- G : les lignes groupées, la fiche élève de chaque enfant, les appareils.
- P : la carte du titulaire avec la pastille « Titulaire », la ligne de la conjointe, « Ajouter un profil élève », « Paiements du foyer ».
- C :
  1. « Membres du foyer · 2 enfants » alors que trois membres sont listés : le compteur est retiré (aucun compteur décoratif, déjà la règle de `FoyerPage`).
  2. La ligne de la conjointe ne montre ni Classe ni niveau (F6). Elle montre son nom et l'état de la place (F21).
  3. L'âge des enfants n'est pas affiché : il n'est pas enregistré (DB-ADM-05, déjà la règle de `FicheElevePage`).
  4. « Voir les paiements : Abonnements et historique » devient « Paiements du foyer ».
  5. « Paramètres du foyer : accès et appareils » reste la ligne Appareils existante.
  6. La barre Accueil, Foyer, Historique, Compte est celle du tuteur existant : G.

**3.2 Départ de la conjointe.** Existant : rien. `ConfirmDestructive` et `EcranResultat` existent.
- P : le résultat qui rassure (compte, cours, historique, solde restent).
- C :
  1. Une confirmation destructive « Retirer ma conjointe ? » précède toujours l'action (F14), avec le texte du doc §19.
  2. « Le foyer a été mis à jour avec succès » et la coche verte sont retirés : le résultat se lit sur la réponse, sans « succès » (E2, E7).
  3. Le titre ne dit pas « Le compte de votre conjointe a été retiré » (faux : le compte reste). Il dit que le rattachement au forfait famille a pris fin.
  4. Les quatre cartes deviennent une phrase ou un groupe de lignes, puis « Compris » (K-42).
  5. Le côté conjointe reçoit la notification du doc §9.3 ; le côté titulaire, si c'est elle qui quitte (F16).

**3.3 Nouvelle invitation indisponible.** Existant : rien.
- P : la date en évidence, la mention de la validation administrative, « Retour au foyer ».
- C :
  1. Le texte reprend le doc §19 : « Nouvelle invitation indisponible. Une nouvelle demande pourra être déposée à partir du {date}. Elle devra ensuite être validée par l'administration. »
  2. « Dans 6 mois et 12 jours » est retiré. C'est faux (le délai ne dépasse jamais 120 jours) et c'est un calcul local (F17).
  3. « avant l'activation du compte » et « de l'établissement » sont faux : c'est le rattachement qui est validé, par l'académie.
  4. « Pourquoi cette attente ? » tient en une ligne ou un lien.
  5. L'état vit d'abord sur la ligne de la place dans Ma famille (F21) ; cette page n'est que son détail. Aucun bouton « Inviter » actif pendant le délai.

### Planche 4, payer pour le foyer

**4.1 Paiements du foyer.** Existant : `PaiementsComptePage` (indisponible, DB-CPT-03), `PortPaiementsFoyer` (historique seulement), place réservée au « futur solde par élève » dans `FicheElevePage` et `AccesPage`.
- G : le port et la page d'historique, sans calcul ; la place réservée au solde par élève.
- P : une ligne par bénéficiaire (photo ou initiale, prénom, solde), le bouton « Recharger », l'historique.
- C :
  1. « Budget du foyer, 82,50 € dépensés sur 150,00 €, 67,50 € restants, Ce mois » est retiré : aucun budget ni portefeuille familial (F9).
  2. « Recharger le foyer » devient « Recharger » : on recharge des bénéficiaires, pas le foyer.
  3. « 120 unités » et « 10,00 € » côte à côte : l'unité du solde n'est pas fixée (doc §20.3). Le solde s'affiche tel que les données le rendent (question au directeur).
  4. La ligne de la conjointe ne montre pas sa Classe (F6, F10).
  5. « Bientôt épuisé » et « Inactif » sont des exceptions et gardent une pastille, si le serveur les rend (F12). « Actif » est retiré.

**4.2 Nouvelle recharge, bénéficiaires.** Existant : rien.
- P : la sélection par case, « Tout sélectionner », un choix par bénéficiaire, « Continuer ».
- C :
  1. Les « Packs rapides » 5, 10, 20 et 50 €, avec leurs « + 50 unités » à « + 700 unités », sont retirés : prix et bonus en dur (F12). Les offres viennent des données.
  2. « 1,00 € = 12 unités » est retiré : c'est un taux.
  3. Chaque bénéficiaire choisit son offre ; rien n'est réparti également (F11).

**4.3 Vérifier la recharge.** Existant : rien.
- P : « Récapitulatif par bénéficiaire », le total, un seul bouton de paiement.
- C :
  1. « Remise foyer −2,50 € » (10 % calculés) ne s'affiche que si le serveur la rend, avec son libellé à lui (F12).
  2. Chaque ligne montre aussi le statut de l'attribution (F11).
  3. « Visa •••• 4242 » est retiré : le prestataire n'est pas choisi (doc §20.8), et aucun moyen de paiement n'est montré (F13).
  4. « Payer 22,50 € » mène en démonstration à un état honnête, jamais à « Paiement réussi » (F13).

### Planche 5, accueil de l'élève adulte sur ordinateur

Existant : même `AccueilElevePage`, coquille `NavShell` (barre latérale sur ordinateur).
- P : la carte de séance à gauche, « Avant la prochaine séance » à côté, « Mon parcours », « Dernières séances » (3), « Ressources de la classe » (3).
- C :
  1. La barre latérale compte 7 entrées (Accueil, Ma classe, Coran, Suivi, Ressources, Ma famille, Paramètres) : on garde les 4 destinations (F20).
  2. La barre de recherche est retirée : elle n'est pas au contrat.
  3. La citation d'Al-Boukhari et le « Verset du jour » sont retirés : ils ne sont pas au contrat, et le rendu du Coran est une zone interdite (question au directeur, choix provisoire : retirés).
  4. « Accès rapides » (4 tuiles) est retiré : il double la navigation (E3).
  5. « Présente » sur chaque séance passée est retiré : c'est l'état normal. Seule une absence porte une pastille.
  6. « Ressources recommandées » devient « Ressources de la classe » : pas de recommandation (Children's Code, pas de profilage).
  7. Trois colonnes deviennent deux au plus, à partir de 840 de largeur utile (K-42 point 6).

### Planche 6, famille et paiements sur ordinateur

Existant : `FoyerPage` en deux colonnes à partir de 1200, `CompteTuteurPage` en deux colonnes.
- P : deux colonnes, les membres à gauche et les soldes à droite ; la carte du titulaire en tête.
- C :
  1. Le titre « Famille & paiements » et l'entrée de barre du même nom : la destination reste « Foyer » (tuteur existant), et « Paiements du foyer » en est une section (question au directeur).
  2. Un seul bouton dominant (K-42 point 2) : « Ajouter un enfant », « Effectuer un paiement », quatre « Recharger », « Gérer la conjointe » et un second « Ajouter un enfant » deviennent un bouton « Recharger » et des liens.
  3. « Gérer la conjointe : Modifier les accès et informations de votre épouse » est faux : le titulaire ne modifie pas le compte de sa conjointe (F6). Il reste « Ma conjointe », puis « Retirer ma conjointe ».
  4. Le bandeau jaune « Remplacement de la conjointe » (60 jours, 120 jours) n'apparaît que pendant un délai, avec la date rendue (F17).
  5. « 120,00 € rechargés ce mois-ci », « 4 paiements », « 4 membres » : tuiles de chiffres retirées (K-42 point 4). « Solde total disponible » devient un récapitulatif discret, jamais un montant à dépenser (F9).
  6. Les noms changent d'une planche à l'autre (la conjointe s'appelle Mariama, puis Aïcha) : la démonstration fixe un seul foyer (§3).
  7. Le bandeau « Vous gérez votre foyer » tient en une ligne sous le titre.

## 3. Données de démonstration communes (K-35, E20)

- **Foyer Diallo** : titulaire **Mamadou** (homme, élève de la Classe An-Nour), conjointe **Mariama** (élève d'une autre Classe, dont le titulaire ne voit pas le nom), enfants **Aïcha** et **Oumar**. Les prénoms viennent des exemples du document du directeur (§9.3, §12.4), pas des planches.
- Variante `&titulaire=femme` : titulaire femme, place « conjoint ».
- Variante `&vue=conjoint` : l'espace du second adulte.
- L'enseignant est **Sayyid Ibrahim**, comme dans la démonstration enseignant ; la Classe An-Nour est la même.
- Dates en septembre à décembre 2026. La date de fin de délai est une donnée (« 18 décembre 2026 », l'exemple du doc §10.4), jamais un calcul.
- Soldes, offres et remises : des valeurs de démonstration, marquées comme telles, sans taux ni formule (F12).

## 4. Mon avis sur le document (droit de regard du directeur)

1. **§14 émancipation.** Le document dit qu'elle « existe déjà dans le produit ». Je n'en trouve aucune trace dans le code (`lib/`, `supabase/` de `ui/enseignant-v1`), ni dans pilotage ni dans ressources. Je le signale (doc §22.7) au lieu de le construire : ligne BR-1.
2. **§3 et i18n.** Le texte d'inscription actuel dit encore « Inscrivez vos enfants ou vos proches » (`fr.i18n.json`, `inscription.usage.familleDescription`). Il relève du questionnaire d'accueil, réservé à sa vague : je ne le change pas ici, je le note pour elle.
3. **§4 point d'entrée.** Les planches 1 et 5 mettent « Ajouter ma famille » à trois endroits. Le document n'en donne qu'un, Mon espace. Je garde le document (E3).
4. **§5 invitation.** Le document ne dit pas par quel moyen l'invitation part. La planche prend l'e-mail ; je garde l'e-mail seul en démonstration (question).
5. **§7.3 vue minimale.** Les planches 4 et 6 montrent la Classe de la conjointe au titulaire. La matrice §16 l'interdit. Je la retire.
6. **§16 matrice.** « Ne pas l'implémenter par masquage de boutons seulement » : en démonstration, chaque vue ne reçoit que les données de son rôle (F7).
7. **Nouvel écran sans planche.** L'acceptation de l'invitation par le second adulte doit lui dire ce que le titulaire verra (son solde, la recharge) et ce qu'il ne verra pas. C'est un texte d'information au sens de la charte 09, à valider en français par le directeur.
