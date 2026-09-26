# Vague Enseignant : découpage en étapes (EN-0 à EN-R)

## Où et comment

- **Branche** `ui/enseignant-v1`, créée depuis `ui/classe-v1` @ d44710a, déjà poussée.
- **Worktree** `C:\RA\enseignant`.
- **Un seul agent qui committe à la fois** dans ce worktree (K-30), avec des tâches de moins de 35 minutes (K-16).
- **Modèles.** Opus pour le design et le code d'écran. Sonnet pour les tests, captures, preuves et la revue de lecture. Haiku pour les écritures du tableau.
- **Démonstration d'abord** (K-35), sans serveur (K-28) :
  - les fournisseurs réels restent en place ;
  - la démonstration les surcharge par `/demo/enseignant?ecran=…&etat=…`, gardée par `environnementAutoriseDemo`.
- **Écrans déjà faits retouchés ici** (Journée, Créneaux, Profil, Bienvenue, Cahier, Fiche groupe). Le directeur l'a demandé le 26/09 : « perfectionner ce qui existe ». Ce n'est donc pas une réouverture interdite, et HU-1 n'aura plus à y revenir.
- **Définition de « fait »** (K-7) :
  - l'écran est atteint depuis la vraie coquille, et un test tape le vrai bouton ;
  - `analyze` est à 0 ;
  - la suite complète est relancée après la dernière correction (K-29) ;
  - les captures existent en 390, 768 et 1440, clair et sombre ;
  - elles ont été relues par l'orchestrateur avant l'état `verifie`.
- **Interdits** :
  - main, PR, supabase/, .github/, vercel.json, pubspec.yaml ;
  - thème et couleurs (K-37) ;
  - le rendu du Coran, les secrets ;
  - `dart format` sur un dossier (K-23) ;
  - toute traduction avant LG-1 (K-41).

## Les étapes

| Étape | Contenu | Réutiliser, sans fork | Modèle, durée |
|---|---|---|---|
| **EN-0** | Préparation : classement des planches, comparaison, rectifications, règles E1 à E20, découpage. | — | fait (poste B) |
| **EN-1a** | `UX_REVIEW_04_ENSEIGNANT.md` (DESIGN-GOV §4 et doc §36) : sources officielles datées et décision par écran. Document seulement. | modèle `10_classe/UX_REVIEW_CL-4.md` | Opus, 30 min |
| **EN-1b** | Socle, en quatre parties (détail sous le tableau) : coquille, données de démonstration, route de démonstration, squelette de capture. | `nav_shell.dart`, `classe_demo.dart`, `demo_classe_page.dart`, `outil_capture.dart` | Opus, 35 min |
| **EN-2** | ENS-02 Aujourd'hui (00_MAQUETTES §2, planche 1) : carte « Prochaine séance » avec `EmplacementEntree` (E11), « Ma journée », « À terminer » (3 au plus), « Alertes utiles » si non vide ; deux colonnes sur bureau. Retrait de « Élèves en attente » et de « Cours individuel ». | `JourneePage`, `TimelineRow`, carte de séance CL-4, `EmplacementEntree` | Opus, 35 min, puis Sonnet pour les tests et captures |
| **EN-3** | ENS-09 Mes Classes (nouvelle page, lignes groupées, tri §12.2) et ENS-07 perfectionné (détail sous le tableau). | `FicheGroupePage`, `IdentiteGroupe`, `BlocBibliotheque`, cartes de `MesGroupesPage` | Opus, 35 min |
| **EN-4** | ENS-11 fiche élève hors séance (feuille sur mobile, panneau sur bureau, une colonne, E5 et E14) et ENS-12 « Signaler un besoin » (catégories §22.1, « Détails internes » et « Résumé partageable » séparés, notice). | `AppBottomSheet`, `GroupeReglages`, `PhotoEleve` (photo, initiales en repli) | Opus, 35 min |
| **EN-5** | ENS-06 Disponibilités (détail sous le tableau) et ENS-06B détail, confirmation et succès honnête (E7). | `CreneauxPage`, `GrilleSemaine` | Opus, 35 min, puis Sonnet |
| **EN-6** | ENS-01 Premiers pas (« À compléter », le bouton porte le premier manque, retrait de la prose 5/6), ENS-05 Profil (photo en tête, E18 et R de la planche 4) et ENS-05A photo publique (textes §24, démonstration sans envoi réel). | `BienvenueEnseignantPage`, `ProfilEnseignantPage`, `PhotoEnseignant` | Opus, 35 min |
| **EN-7** | ENS-04 Cahier perfectionné : ordre de la planche 4 (résumé, pastilles de statut, travail, reprise, « Valider le cahier »), deux colonnes sur bureau. Retraits : IA, « Justifiée », « Ajouter un document », brouillon. Textes §20.7 et §20.8. | `CahierPage`, `vue_cahier.dart` | Opus, 35 min |
| **EN-8** | ENS-13 absence sur une séance (feuille, notice « Votre affectation… », états serveur de démonstration) et ENS-13B offre de remplacement : Alerte utile, puis « Assurer ce remplacement ? », puis la carte « Remplacement » dans Aujourd'hui. | `AppBottomSheet`, `StatusPill`, les Alertes utiles d'EN-2 | Opus, 35 min |
| **EN-9** | Salle A, détail sous le tableau : panneau Élèves et file de récitation, fiche élève en séance, notice du parent. | `panneau_enseignant.dart`, `ControleurRecitation`, `roster_classe.dart`, la fiche d'EN-4 | Opus, 35 min |
| **EN-10** | Salle B : Teaching Dock compact raccordé à `/salle` (Supports, Micro, Caméra, Partager, « Ouvrir les outils d'enseignement ») et sélecteur de ressources (Récents, Cette Classe, Tous les supports, recherche ; feuille sur mobile, panneau sur bureau). Choisir une ressource ne coupe pas la salle. | `lib/features/tc_dock/`, `lib/core/tc_outils/`, `BlocBibliotheque` | Opus, 35 min, puis une seconde passe si besoin |
| **EN-11** | ENS-08 Revue de Classe au style K-42 (une anomalie par ligne, « Vous signalez, l'académie tranche »), puis nettoyage du lexique enseignant dans `fr.i18n.json` (E17 : groupe, Session, Cours en cours, matching, dans les seuls textes visibles de l'enseignant). | `RevueGroupePage` | Sonnet, 30 min |
| **EN-12** | Recette, détail sous le tableau. | `captures_cl47_test.dart` | Sonnet, 35 min, en deux agents si besoin |
| **EN-R** | Revue croisée par une autre session : contre les règles E1 à E20, R1 à R21, K-42 et les 14 questions anti-cauchemar (doc §33). | modèle `05_recette/CL/REVUE_CL-4.md` | Opus, 30 min |
| **EN-RC** | Corrections de la revue, puis la planche web du directeur (format CL-4), publiée par l'orchestrateur. | — | Opus, 35 min |
| **EN-KB** | Plus tard, sur décision du directeur : raccourcis clavier de la salle sur bureau (00_MAQUETTES §4 point 3). | — | — |

**Détail d'EN-1b, le socle.**
1. Coquille enseignant à 4 destinations (E10) : Aujourd'hui, Classes, Disponibilités, Profil.
   - Nouvelle route `Routes.enseignantClasses = '/enseignant/classes'`, sur une page provisoire ; EN-3 la remplit.
   - Note dans le code : ADR-027 est remplacé par la décision du directeur du 26/09.
2. Données de démonstration `lib/features/demo/enseignant_demo.dart` : 4 Classes, élèves, séances, cahiers, disponibilités, offres, remplacement, conformes à 00_MAQUETTES §3.
3. Route `/demo/enseignant`, gardée.
4. Squelette `test/features/enseignant_recette/captures_en_test.dart`.

**Détail d'EN-3.**
- ENS-09 Mes Classes : nouvelle page, lignes groupées, tri du doc §12.2, pastille « Remplacement ».
- ENS-07 perfectionné :
  - « Ressources récentes », 3 au plus ;
  - « Progression de la classe » en une ligne ;
  - un indicateur par élève, doublé d'un mot ;
  - la photo de chaque élève (`PhotoEleve`) à la place des seules initiales posées en CL-4.4 (E5, décision du directeur du 26/09) ;
  - toute la ligne d'un élève ouvre ENS-11 ;
  - deux colonnes sur bureau.

**Détail d'EN-5.**
- ENS-06 : l'onglet « Élèves en attente » et « Prendre… » sont retirés de l'écran, sans toucher au serveur.
- Les disponibilités sont hebdomadaires, sans date (E15).
- « Classes disponibles » avec leurs états : Disponible, En attente de validation, Limite de charge atteinte.

**Détail d'EN-9, la salle A.**
- Sur `/salle` côté enseignant, sans barre de navigation :
  - panneau droit Élèves et File de récitation sur bureau (élève en cours, puis « À suivre ») ;
  - sur mobile, le résumé « 4/4 » qui ouvre une feuille.
- Fiche élève en séance, avec « Faire réciter », « Appeler discrètement », « Noter » et « Signaler un besoin ».
- Côté élève : « Sayyid Ibrahim vous appelle ».
- Notice discrète « Un parent observe cette séance », sans popup.
- Ni minuteur par élève ni évaluation automatique (E8, E9).

**Détail d'EN-12, la recette.**
1. Tests partant de la vraie coquille pour chaque bouton.
2. Captures en 390, 768 et 1440, clair et sombre, plus le texte à 200 % et le test arabe simulé, pour chaque écran et ses cas particuliers.
3. Rapport `05_recette/EN/EN_RAPPORT.md` en français simple.
4. Besoins serveur `12_enseignant/EN-BR.md`, qui reprend le doc §26 et §27.

## Ordre et dépendances

L'ordre est le suivant :
1. EN-1a et EN-1b. EN-1a ne fait que de la documentation, il peut donc tourner en parallèle.
2. EN-2 à EN-8, dans l'ordre. EN-4 doit précéder EN-9.
3. EN-9 et EN-10.
4. EN-11, puis EN-12.
5. EN-R, puis EN-RC.

Chaque étape passe par trois états :
- `fait` avec une preuve (commit, tests, captures) ;
- l'orchestrateur relit les captures ;
- puis `verifie`.
