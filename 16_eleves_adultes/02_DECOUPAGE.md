# Vague Élèves adultes : découpage en étapes (EA-0 à EA-RC)

## Où et comment

- **Branche proposée** `ui/eleves-adultes-v1`, à créer par l'orchestrateur depuis `ui/classe-v1` @ d44710a, la même base que `ui/enseignant-v1`.
  - Pourquoi : `ui/classe-v1` contient déjà tout ce que la vague réutilise (style de référence CL-4, `EmplacementEntree`, page Classe, `FoyerPage`, `PhotoEleve`, `SelecteurProfils`, `racine_demonstrable.dart`, `repere_demonstration.dart`). Elle est figée et vérifiée.
  - Partir de `ui/enseignant-v1` lierait la vague à un chantier en cours (EN-7b), avec un seul agent qui committe par worktree (K-30).
  - Les deux branches ayant la même base, la future fusion reste à trois voies simples, comme le plan `13_fusion`.
  - Le commit de documentation 73f12c8 de `ui/tuteur-v1` (CLAUDE.md) n'est pas dans cette base : il ne touche aucun code.
- **Worktree proposé** `C:\RA\adultes`.
- **Un seul agent qui committe à la fois** (K-30), des tâches de moins de 35 minutes (K-16).
- **Modèles.** Opus pour le design et le code d'écran. Sonnet pour les tests, captures, preuves et la revue de lecture. Haiku pour les écritures du tableau.
- **Démonstration d'abord** (K-35), sans serveur (K-28, F24) :
  - les fournisseurs réels restent en place ;
  - la démonstration les surcharge par `/demo/adulte?ecran=…&etat=…&titulaire=homme|femme&vue=titulaire|conjoint`, gardée par `environnementAutoriseDemo` ;
  - paiements, soldes, séparations, délais, reprise du foyer : démonstration seulement, et chaque besoin serveur devient une ligne de `EA-BR.md` (BR-1).
- **Écrans existants retouchés ici** (Foyer, formulaire de profil, Compte, Paiements, Accueil élève). Le document du directeur le demande (§22.4 : « prévoir les surfaces et états dans les maquettes Élève adulte et Tuteur »). Ce n'est donc pas une réouverture interdite.
- **Composants partagés** (`lib/core/widgets/`) : réutilisés sans fork et sans modification. Si un changement semble nécessaire, il est noté pour HU-1 : `ui/enseignant-v1` a déjà modifié 4 de ces fichiers, et un second changement parallèle créerait un conflit.
- **Définition de « fait »** (K-7) :
  - l'écran est atteint depuis la vraie coquille, et un test tape le vrai bouton ;
  - `analyze` est à 0 ;
  - la suite complète est relancée après la dernière correction (K-29) ;
  - les captures existent en 390, 768 et 1440, clair et sombre ;
  - elles ont été relues par l'orchestrateur avant l'état `verifie`.
- **Interdits** :
  - main, PR, supabase/ (lecture seule), .github/, vercel.json, pubspec.yaml ;
  - thème et couleurs (K-37 ; une ligne TH-2 si besoin) ;
  - le rendu du Coran, les secrets ;
  - `dart format` sur un dossier (K-23) ;
  - toute traduction avant LG-1 (K-41) ;
  - le questionnaire d'accueil (réservé à sa vague) ;
  - tout prix, pourcentage, pack, taux, seuil, délai ou remise en dur (F12, F17).

## Les étapes

| Étape | Contenu | Réutiliser, sans fork | Modèle, durée |
|---|---|---|---|
| **EA-0** | Préparation : copie du document et des planches, classement, comparaison, rectifications, règles F1 à F24, découpage. | — | fait (27/09) |
| **EA-1a** | `UX_REVIEW_07_ELEVES_ADULTES.md` (DESIGN-GOV §4) : sources officielles datées et décision par écran, plus la vérification des textes du doc §19 et des textes d'information (charte 09). Document seulement. **Obligatoire avant tout écran** (EA-2 et suivants). | modèle `12_enseignant/UX_REVIEW_04_ENSEIGNANT.md` | Opus, 30 min |
| **EA-1b** | Socle, en quatre parties (détail sous le tableau) : coquille, données de démonstration, route de démonstration, squelette de captures. | `nav_shell.dart`, `racine_demonstrable.dart`, `classe_demo.dart`, `outil_capture.dart` | Opus, 35 min |
| **EA-2** | Accueil de l'élève adulte (planches 1.1 et 5) : carte « Prochaine séance » avec `EmplacementEntree`, « Avant la prochaine séance » (3 au plus, seulement ce que les données demandent), « Mon parcours » en une ligne, « Dernières séances » (3) et « Ressources de la classe » (3) ; deux colonnes sur bureau. | `AccueilElevePage`, carte de séance CL-4, `EmplacementEntree`, `TimelineRow`, `BlocBibliotheque` | Opus, 35 min, puis Sonnet pour les tests et captures |
| **EA-3** | Ma classe côté élève adulte (planche 1.2) : la page Classe de CL-4 en sections, participants avec photo (E5), ressources (3), progression en une ligne. | page Classe CL-4 (`classe_tuteur/`, `IdentiteGroupe`), `PhotoEleve` | Opus, 30 min |
| **EA-4** | Mon espace (planche 1.3) : rubriques groupées, « Mes accords », « Paiements » personnels, la ligne unique « Ajouter ma famille » ou « Ma famille » ; variante second adulte avec la ligne « Forfait famille ». | `ComptePage`, `carte_rubriques.dart`, `GroupeReglages`, `PaiementsComptePage` | Opus, 35 min |
| **EA-5** | Ma famille du titulaire (planches 2.1 et 3.1, colonne gauche de 6) : carte du titulaire, ligne de la place adulte avec son état (F21), enfants, « Ajouter un profil élève », « Paiements du foyer » ; retrait du choix « Un proche adulte » du formulaire (F2). | `FoyerPage`, `ligne_membre.dart`, `FormulaireProfilEleve`, `PhotoEleve` | Opus, 35 min |
| **EA-6** | Inviter la conjointe ou le conjoint (planche 2.2) : deux étapes (coordonnées, puis « Vérifier et envoyer »), libellés selon le genre (F3), envoi neutre (F4), annulation, et les états du doc §5.2 côté titulaire : envoyée, expirée, annulée, erreur réseau, double envoi, réponse tardive après annulation. | `PageEtape`, `ActionPrincipale`, `EtatSysteme`, `ConfirmDestructive` | Opus, 35 min, puis Sonnet |
| **EA-7** | Côté second adulte : recevoir et accepter l'invitation depuis son propre compte, avec le texte d'information (ce que le titulaire voit et ne voit pas) ; états inéligible, déjà dans un autre foyer (F4), acceptée, « En attente de validation administrative » pour un remplacement. Sans compte : renvoi vers l'inscription existante, sans la modifier. | `EtatSysteme`, `PageEtape`, `NotificationsPage` | Opus, 35 min |
| **EA-8** | Sortie et délai (planches 3.2 et 3.3) : « Retirer ma conjointe » / « Retirer mon conjoint » et « Quitter le forfait famille » avec confirmation destructive et résultat sans « succès » ; notifications des deux côtés, visibles dans le centre de l'application (F16) ; délai à la date rendue (F17), validation administrative en attente ou refusée. | `ConfirmDestructive`, `EcranResultat`, `NotificationsPage`, `PermanentNotice` | Opus, 35 min |
| **EA-9** | Paiements du foyer (planche 4.1, colonne droite de 6) : une ligne par bénéficiaire autorisé avec son solde tel que rendu, pastilles d'exception seulement, un seul bouton « Recharger », l'historique ; récapitulatif du foyer discret (F9, F10). | `PaiementsComptePage`, `PortPaiementsFoyer`, `GroupeReglages`, `StatusPill` | Opus, 35 min |
| **EA-10** | Recharge (planches 4.2 et 4.3) : un, plusieurs ou tous les bénéficiaires, une offre par bénéficiaire lue dans les données, récapitulatif séparé (F11), remise seulement si rendue, paiement qui s'arrête sur un état honnête (F13) ; hors ligne, erreur, double envoi. | `PageEtape`, `ActionPrincipale`, `GroupeReglages`, `LigneCleValeur` | Opus, 35 min, puis Sonnet |
| **EA-11** | Reprise du foyer (doc §12, sans planche) : la demande du second adulte (explication du doc §19, une seule demande active), la notification au titulaire avec « Refuser la demande », puis les états : déposée, refusée par le titulaire, 30 jours sans réponse et attente de l'administration, validée, refusée (F18). | `ConfirmDestructive`, `EtatSysteme`, `NotificationsPage` | Opus, 35 min |
| **EA-12** | Recette, détail sous le tableau. | `captures_cl47_test.dart`, `outil_capture.dart` | Sonnet, 35 min, en deux agents si besoin |
| **EA-R** | Revue croisée par une autre session : contre F1 à F24, R1 à R21, K-42, DESIGN-GOV (contrats A à E), la matrice du doc §16, la recette du doc §21 et le contrat de sécurité du doc §17. | modèle `05_recette/CL/REVUE_CL-4.md` | Opus, 30 min |
| **EA-RC** | Corrections de la revue, puis la planche web du directeur (format CL-4 : Téléphone, Tablette, Ordinateur ; Clair, Sombre), publiée par l'orchestrateur. | — | Opus, 35 min |

**Détail d'EA-1b, le socle.**
1. Coquille de l'élève adulte à 4 destinations, choix provisoire : Accueil, Ma classe, Coran, Mon espace (planche 1).
   - L'espace Foyer reste la coquille du tuteur existante (Accueil, Foyer, Historique, Compte), atteinte depuis Mon espace, ligne « Ma famille » (F20).
   - Aucun rôle serveur n'est changé : la démonstration choisit la coquille, le rôle réel reste lu du jeton.
2. Données de démonstration `lib/features/demo/eleve_adulte_demo.dart` : le foyer Diallo de 00_MAQUETTES §3, ses variantes (titulaire femme, vue du conjoint), et un état nommé pour chacun des 25 cas du doc §18.
3. Route `/demo/adulte`, gardée par `environnementAutoriseDemo`.
4. Squelette `test/features/adulte_recette/captures_ea_test.dart`.

**Détail d'EA-12, la recette.**
1. Tests partant de la vraie coquille pour chaque bouton.
2. Les points du doc §21, un test chacun quand c'est possible en démonstration. En particulier :
   - l'enseignant ne voit aucun détail familial (F8) ;
   - le second adulte n'a aucune action d'ajout d'enfant ;
   - aucun prix, taux ni remise n'est calculé dans Flutter (recherche dans le code) ;
   - la réponse tardive après annulation ne rattache personne.
3. Captures en 390, 768 et 1440, clair et sombre, plus le texte à 200 % et le test arabe simulé, pour chaque écran et les 25 cas du doc §18.
4. Rapport `05_recette/EA/EA_RAPPORT.md` en français simple.
5. Besoins serveur `16_eleves_adultes/EA-BR.md` : foyer, place adulte, invitation, genre, délais 60 et 120 jours, validation administrative, solde par profil, offres et devis, paiement, remise, notifications, reprise du foyer, émancipation, date de naissance. Chaque ligne cite le doc §17 (idempotence, audit, tests d'accès horizontal, revue sécurité séparée).

## Ce qui n'est pas dans cette vague

- **Administration** : les deux dossiers (remplacement du second adulte, reprise du foyer), distincts d'ADM-02. Ils deviennent une ligne au tableau pour la vague Admin, « À appliquer lors de la passe correspondante » (R21).
- **Questionnaire d'accueil** : réservé à sa vague (doc §3).
- **Finance** : prix, remise, seuils, crédits, remboursement, prestataire (doc §15.5, §20).
- **Émancipation** : rien n'est réinventé (F19) ; son absence dans le code est signalée au directeur.

## Ordre et dépendances

1. EA-1a et EA-1b. EA-1b ne propose aucune disposition, il peut donc tourner en parallèle. Aucun écran (EA-2 et suivants) avant EA-1a.
2. EA-2, EA-3, EA-4 (espace élève).
3. EA-5, puis EA-6, puis EA-7, puis EA-8 (famille).
4. EA-9, puis EA-10 (paiements). EA-9 dépend d'EA-5.
5. EA-11, qui dépend d'EA-4 et d'EA-8.
6. EA-12, puis EA-R, puis EA-RC.

Chaque étape passe par trois états :
- `fait` avec une preuve (commit, tests, captures) ;
- l'orchestrateur relit les captures ;
- puis `verifie`.
