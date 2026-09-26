# T-S3 : écrans de secours, reconnexion impossible et hors ligne (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `a48ad9a`. Plan : `10_classe/07_SECOURS.md` §3 T-S3. Aucune maquette (feu vert du directeur) ; références : `UX_REVIEW_CL-7.md` U3, U10, U11 ; contrats A à E appliqués (lot nouveau).

## Correctifs T-S2 (demandés avant T-S3)

- (a) Contrat A : le bandeau suit désormais les marges de page (gouttière 16 / 32 du gabarit) au lieu d'aller d'un bord à l'autre. Extension additive `OfflineBanner.message(encadre: true)` : filet sur les quatre côtés, rayon `AppRadius.arrondiSm` ; `const OfflineBanner()` inchangé.
- (b) Élève desktop : `BandeauSecours(espaceApres: AppSpacing.lg)`, 16 entre l'état (bandeau, retour bref, bloc) et le support, comme en mobile. Enseignant desktop : 12 (`AppSpacing.md`) avant la rangée d'outils, qui n'a pas d'écart en tête.
- Captures `10_classe/captures/TS2/` régénérées (54 PNG, mêmes noms). Relues : `cl7_04_reconnexion_390x844@3_light`, `cl7_04_retablie_1440x900@1_light`.

## Fait (T-S3)

- `salle_seance.dart` : `BandeauSecours` reçoit `actions` ; en `echec` / `horsLigne`, `EtatSysteme(portee: bloc)` à la place du bandeau (clé `bloc-echec-connexion`), titre exact par rôle (`vue.titreEchec`), sans phrase, `Réessayer` → `onReessayerConnexion`, sortie (`Quitter la séance` ; `Quitter` en guidée) → `confirmerQuitterSeance` existante (cahier pour l'enseignant). Hors ligne ES/EN : `Réessayer` seul. Salle et support restent montés. Largeur bornée à `AppPage.largeurFormulaire`, alignée start (contrat D) ; hauteur bornée (1/3 de l'écran, 1/5 au-delà de 150 % de texte) avec défilement interne (W2 1.4.10).
- `etat_systeme.dart` : extension additive `actionsContratB` (défaut faux, écrans existants inchangés) : 16 sous l'objet, groupe au bord trailing, sortie puis poursuite en LTR, 8 entre les deux, boutons à la largeur du libellé. Une phrase vide n'est plus rendue.

## Preuves

- `flutter analyze --fatal-infos` : 0 problème. `verifier_jetons` : aucun signalement sur les fichiers touchés.
- `test/features/salle_seance/salle_secours_test.dart` (nouveau, 39 + 36 captures) : textes exacts par rôle et par état, aucun bandeau avec le bloc, `zone-support` présent ; **taper Réessayer** appelle `onReessayerConnexion` (3 rôles x 2 états) ; ordre et écart 8 des actions ; **taper la sortie** ouvre `Quitter la séance ?` (ES : Annuler garde la salle, puis Quitter appelle `onQuitter` ; IG : Quitter ; EN : `Quitter et ouvrir le cahier`) ; hors ligne ES/EN sans sortie ; aucun débordement 390, 768, 1440 et zoom 2,0 à 390.
- `flutter test test/features/salle_seance/ test/features/demo/` : 364 réussis, 265 sautés (captures sans `CAPTURE_DIR`), 0 échec. Avec `test/core/widgets/` et `test/widgets/` : 526 réussis, 0 échec.
- Captures : `10_classe/captures/TS3/`, 36 PNG `cl7_{04,05,06}_{echec,hors_ligne}_{390x844@3,768x1024@1,1440x900@1}_{light,dark}`. Relues : `cl7_05_echec_390x844@3_light`, `cl7_06_hors_ligne_1440x900@1_dark`.

## Écarts

- Confirmation élève : le plan citait « Rester », la confirmation existante dit « Annuler » (seul l'enseignant a « Rester ») ; confirmation existante conservée, non modifiée.
- `actionEnCours` de `Réessayer` non branché : la vue ne porte pas d'état de tentative (moteur, BR-1).
- Disposition historique du bloc `EtatSysteme` (poursuite en tête, 12 sous l'objet, bouton étiré dans le `Wrap`) laissée telle quelle pour les écrans déjà livrés : à harmoniser en HU-1.
- Reste du lot : T-S4 (micro bloqué), T-S5 (caméra interdite, prolongée, accès retiré), T-S6 (page démo et recette).
