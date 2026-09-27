# Vague Élèves adultes : reprise (lire ceci d'abord)

1. **Règles** : `projet/ressources:memoire/ELEVES-ADULTES-2026-09-27.md` (F1 à F24). Elles s'ajoutent à DESIGN-GOV, à K-42 (style CL-4), à CLASSE-ENTREE (R1 à R21) et aux règles E5, E6, E7, E12, E13, E17, E20 du rôle enseignant.
2. **Planches et rectifications** : `16_eleves_adultes/V/00_MAQUETTES_ELEVES_ADULTES.md`. Il contient la comparaison avec l'existant, ce qu'on garde, ce qu'on prend et ce qu'on corrige.
3. **Étapes** : `16_eleves_adultes/02_DECOUPAGE.md` (EA-0 à EA-RC), avec le tableau de suivi, collection `etapes`, vague « Élèves adultes ».
4. **Code** : branche proposée `ui/eleves-adultes-v1`, depuis `ui/classe-v1` @ d44710a, worktree proposé `C:\RA\adultes`. **Pas encore créés** : c'est à l'orchestrateur de le faire.
5. **Document source** : `projet/ressources:specs/07_eleves_adultes/REWAYAH_DECISIONS_FOYER_FAMILLE_V1.md`. Ne le lire que par section, à la demande de l'étape (§ indiqué).

**Périmètre.** Démonstration seulement (K-28, doc §17). Paiements, soldes, séparations, délais et reprise du foyer ne sont jamais branchés : chaque besoin serveur devient une ligne de `EA-BR.md` (BR-1). Le questionnaire d'accueil est réservé à sa vague (doc §3) ; on n'y touche pas.

**Inventaire de l'existant (27/09, lecture seule, `ui/enseignant-v1` @ 1108a4a, qui contient `ui/classe-v1`).**

| Écran ou brique | Fichier | État |
|---|---|---|
| Accueil élève (ELV-02) | `lib/features/accueil_eleve/accueil_eleve_page.dart` | 695 lignes, six états du bloc principal. Coquille élève : Accueil, Coran, Suivi, Compte. |
| Classe (CL-4) | `lib/features/classe_tuteur/`, `lib/features/fiche_groupe/` | Style de référence ; `EmplacementEntree` dans `lib/core/tc_horloge/`. |
| Foyer du tuteur | `lib/features/foyer/foyer_page.dart`, `ligne_membre.dart`, `fiche_eleve_page.dart` | Membres en un groupe, appareils, « Créer mon profil élève » indisponible (DB-FOY-01). Place réservée au solde par élève. |
| Ajouter un profil élève | `lib/features/foyer/formulaire_profil_eleve.dart`, `lib/core/foyer/profil_eleve_brouillon.dart` | Serveur réel pour un mineur. Choix « pour qui » avec `procheAdulte` (DB-FOY-02), à retirer (F2). Âge en années, pas de date de naissance. |
| Photo de l'élève | `lib/features/foyer/photo_eleve.dart` | `PhotoEleve`, initiales en repli. |
| Sélecteur de profils | `lib/core/widgets/selecteur_profils.dart` | Point de statut doublé d'un mot. |
| Compte du tuteur | `lib/features/compte/compte_tuteur_page.dart`, `compte_page.dart`, `carte_rubriques.dart` | Rubriques groupées, déconnexion à part. |
| Paiements | `lib/features/compte/paiements_page.dart`, `lib/core/capacites/port_paiements_foyer.dart` | Indisponibles et dits comme tels (DB-CPT-03). Historique seulement, aucun solde, aucune recharge. |
| Notifications du tuteur | `lib/features/notifications/notifications_page.dart` | Ouvertes par la cloche. Rien côté élève adulte. |
| Inscription | `lib/features/inscription/` | « Moi uniquement » et « Moi et ma famille », étape genre. Réservée à la vague du questionnaire. |
| Rôles | `lib/core/domain/enums.dart` | `guardian` : « un élève adulte autonome est son propre tuteur » (ADR-009). Mode `standard` pour les adultes. |
| Démonstration | `lib/features/demo/` | `racine_demonstrable.dart`, `mode_demonstration.dart`, `classe_demo.dart`, `demo_classe_page.dart`. |

**Ce qui manque** :
- l'espace de l'élève adulte à 4 destinations, avec « Ma classe » et « Mon espace » ;
- la place adulte du foyer : invitation, acceptation, dix états, sortie, délai, validation administrative ;
- l'espace du second adulte (« Forfait famille », « Quitter », « Demande de reprise du foyer ») ;
- le solde par profil, les paiements du foyer et la recharge ;
- le centre de notifications de l'élève adulte ;
- la reprise du foyer (succession) ;
- l'émancipation : le document dit qu'elle existe, aucune trace dans le code ni dans les dossiers (signalé au directeur) ;
- côté Admin, les deux dossiers : réservés à la vague Admin.

**Contradictions relevées (doc §22.7, signalées, pas résolues en silence).**
- `fr.i18n.json`, `inscription.usage.familleDescription` dit encore « vos enfants ou vos proches » : relève du questionnaire d'accueil, noté pour sa vague.
- `PourQui.procheAdulte` dans le formulaire du Foyer : retiré de l'écran en EA-5.
- Émancipation introuvable (voir plus haut).

**Outils de capture** :
- `test/capture/outil_capture.dart` ;
- modèle : `test/features/classe_recette/captures_cl47_test.dart`.
