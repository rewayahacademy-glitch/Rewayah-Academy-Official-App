# T-S4 : écrans de secours, micro bloqué (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `3a8e6ac`. Plan : `10_classe/07_SECOURS.md` §2.3 et §3 T-S4. Aucune maquette (feu vert du directeur) ; références : `UX_REVIEW_CL-7.md` U5, U10 ; contrats A à E appliqués (lot nouveau).

## Fait

- `vue_seance.dart` : champ `microBloque` (signal du moteur, BR-1 ; défaut faux) et `copyWith`. Démo : `EtatDemoSalle.microBloque` le pose.
- `feuille_micro_bloque.dart` (nouveau, contenu seulement) : `ouvrirFeuilleMicroBloque` passe par `AppBottomSheet.ouvrir` (feuille du bas < 600, feuille bornée en tablette, dialogue centré en desktop). Titre `Micro` (libellé existant), corps exact par rôle (ES/EN `Le micro est bloqué dans les réglages de cet appareil.`, IG `Le micro est bloqué sur cet appareil.`). Actions contrat B au bord trailing : `Continuer sans micro` (leading), `Ouvrir les réglages` (trailing, principal) **seulement si `onOuvrirReglages` ≠ null** ; seul, `Continuer sans micro` devient principal (un CTA dominant). Les rappels sont appelés après la fermeture.
- `dock_seance.dart` : le bouton Micro devient `_BoutonMicro` (clé `bouton-micro`) ; micro bloqué → le geste ouvre la feuille au lieu de basculer, le micro reste montré coupé (P09.6) ; à la fermeture (action, voile, Échap), le focus revient au bouton Micro. Extension additive `BoutonAppel.focusNode` (aucune copie).

## Preuves

- `flutter analyze --fatal-infos` : 0 problème. `verifier_jetons` : 10 signalements préexistants, aucun sur les fichiers touchés.
- `test/features/salle_seance/salle_micro_bloque_test.dart` (nouveau, 27 tests + 24 captures) : par rôle, taper Micro ouvre la feuille avec le texte exact, `onMicro` non appelé, pas de réglages sans rappel ; taper `Continuer sans micro` ferme, appelle `onContinuerSansMicro`, focus sur `bouton-micro`, icône « micro coupé » conservée ; avec rappel, `Ouvrir les réglages` présent, trailing, écart 8, tapé → appelé ; Échap ferme sans rappel et rend le focus ; micro autorisé → bascule sans feuille ; aucun débordement 390, 768, 1440 et zoom 2,0 à 390.
- `flutter test test/features/salle_seance/ test/features/demo/` : 391 réussis, 289 sautés (captures sans `CAPTURE_DIR`), 0 échec.
- Captures `10_classe/captures/TS4/` : 24 PNG, `cl7_{04,05,06}_micro_bloque_{390x844@3,768x1024@1,1440x900@1}_{light,dark}` + `cl7_{04,05,06}_micro_bloque_reglages_390x844@3_{light,dark}`. Relues : `cl7_05_micro_bloque_reglages_390x844@3_light`, `cl7_06_micro_bloque_1440x900@1_dark`.

## Écarts

- Le plan citait un rappel `onMicroBloque` ; retenu à la place : le signal `VueSeance.microBloque` (le moteur dit « refusé », la salle ouvre la feuille et garde le focus). Même effet, sans contexte ni focus à gérer côté moteur.
- IG à 390 : cibles 72 dp, les deux actions passent sur deux lignes (retour à la ligne du groupe, trailing conservé).
- Ouverture réelle des réglages système et détection du refus : BR-1 (aucun paquet de permission).
- Reste du lot : T-S5 (caméra interdite, prolongée, accès retiré), T-S6 (page démo et recette).
