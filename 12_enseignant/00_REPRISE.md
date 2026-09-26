# Vague Enseignant : reprise (lire ceci d'abord)

1. **Règles** : `projet/ressources:memoire/ENSEIGNANT-2026-09-26.md` (E1 à E20). Elles s'ajoutent à DESIGN-GOV, à K-42 (style CL-4) et à CLASSE-ENTREE (R1 à R21).
2. **Planches et rectifications** : `12_enseignant/V/00_MAQUETTES_ENSEIGNANT.md`. Il contient la comparaison avec l'existant, ce qu'on garde, ce qu'on prend et ce qu'on corrige.
3. **Étapes** : `12_enseignant/02_DECOUPAGE.md` (EN-0 à EN-R), avec le tableau de suivi, collection `etapes`, vague « Enseignant ».
4. **Code** : worktree `C:\RA\enseignant`, branche `ui/enseignant-v1`, créée depuis `ui/classe-v1` @ d44710a.
5. **Document source** : `projet/ressources:specs/04_enseignant/04_ENSEIGNANT.md`. Ne le lire que par section, à la demande de l'étape (§ indiqué).

**Inventaire de l'existant (26/09, lecture seule).**

| Écran | Fichier | État |
|---|---|---|
| Journée (ENS-02) | `lib/features/journee/journee_page.dart` | 840 lignes, serveur réel, garde « Élèves en attente ». |
| Créneaux (ENS-06) | `lib/features/creneaux/creneaux_page.dart` | 855 lignes, ancien matching : `prendre_eleve`. |
| Profil (ENS-05) | `lib/features/profil_enseignant/profil_enseignant_page.dart` | 644 lignes, sans photo. |
| Bienvenue (ENS-01) | `lib/features/bienvenue_enseignant/bienvenue_page.dart` | 235 lignes, prose « cinq enfants, six adultes ». |
| Cahier (ENS-04) | `lib/features/cahier/` | 1 009 lignes, prérempli, file hors ligne. |
| Fiche groupe (ENS-07) | `lib/features/fiche_groupe/` | Style CL-4.4 ; démo `/demo/classe`. |
| Revue (ENS-08) | `lib/features/revue_groupe/` | Vide côté enseignant. |
| Salle enseignant | `lib/features/salle_enseignant/` | Coran présenté, lien réseau calme ; démo `/demo/salle`. |
| Teaching Dock | `lib/features/tc_dock/` et `lib/core/tc_outils/` | Branché sur `/tc/classe` seulement. |
| File de récitation | `lib/core/tc_classe/controleur_recitation.dart` | Contrôleur seul, le bloc est à construire. |

**Ce qui manque** :
- la liste des Classes de l'enseignant (`MesGroupesPage` est refusé à l'enseignant) ;
- la fiche élève côté enseignant ;
- la photo publique ;
- l'absence et le remplacement.

**Outils de capture** :
- `test/capture/outil_capture.dart` ;
- modèle : `test/features/classe_recette/captures_cl47_test.dart`.
