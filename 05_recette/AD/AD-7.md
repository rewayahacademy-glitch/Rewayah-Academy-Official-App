# AD-7 : visionneuse de pièce, corrections de revue

Branche `ui/admin-v1`. Commits : 466fdcc, 37b7430, **d932248** (« admin(AD-7): corrections de revue »), poussé (origin = d932248).
Frontière (`supabase .github vercel.json pubspec.yaml lib/core/theme` depuis 8192bf8) : vide.

## Corrigé (d932248)
- **Validation en production après lecture réussie** (majeur, P-ADM-06 pt 5) : champ `DossierPourRevue.lectureRequise` (posé par `revue_dossiers_depuis_validation.dart` quand la pièce est une image). Les cases et « Valider » restent fermées jusqu'à la première image peinte (`frameBuilder`). Elles se referment, cases décochées, sur erreur, format, accès retiré, indisponible ou aucune. Le refus reste ouvert. Raison affichée : « pasPret ». Démonstration inchangée (`lectureRequise` à faux). Aucun nouvel appel serveur.
- `InteractiveViewer.minScale: 1` : molette et pincement ne descendent plus sous 100 %.
- États de la visionneuse : `phrase: ''`, seul le texte exact de la spec s'affiche (plus de « Il a été retiré… »).
- « Fermer » au contenu (IntrinsicWidth), à la fin, sur la ligne du zoom (`OverflowBar` mesuré, qui empile seulement s'il déborde). Le focus initial va sur « Fermer » (anneau visible) : il n'y a plus de `Focus(autofocus)` nu.
- Barres de la pièce fictive alignées au début.
- Les info-bulles donnent la touche : clé `dossiers.visionneuse.infoBulle` « {action} (touche {touche}) » (+, -, 0).
- HL-A-2 n°2 : test `composants_partages_test` l.391 réécrit en test positif (rubrique nue lisible).
- `dossiers_sans_piece_test` : test périmé aligné sur AD-6 (la carte Vérifications reste, aucune case active).

## Tests (dernier passage, sous verrou)
- `flutter analyze --fatal-infos` : aucun problème.
- 13 fichiers AD-7 et liés : **171 réussis, 0 échec**. Nouveaux : `visionneuse_production_test.dart` (vraie coque RewayahApp + routeur, `surchargeRevueDossiersProduction`, faux ServiceValidation, sans démonstration : Personnes, ligne, taper « Voir la pièce », Fermer, focus rendu, cocher, valider) ; signature 404 qui garde la validation fermée et le refus ouvert ; molette et pincement ≥ 100 % ; info-bulle ; absence de phrase générique ; Fermer sur la ligne du zoom.
- Captures `ad7_visionneuse_capture_test.dart` : 12 réussis, 14 PNG refaits dans `captures/AD-7`. Ouvertes : contenu 1440 sombre, contenu 390 clair, expiré 1440 clair.

## HL-A-2
1. Fait (466fdcc), complété ci-dessus par la lecture exigée.
2. Fait : test réconcilié, sans assert (Q-AD7-9 à confirmer).
3. **Reste** : le lien « Terminez les vérifications requises. » n'est pas réaligné. Il faut la cible exacte de la maquette à 200 %.
4. **Reste, bloqué par Q-AD7-7** : adoucir le contour du tertiaire inactif modifie le composant partagé, ce qui est rétroactif (DESIGN-GOV 4 bis.8).
5. **Reste** : GroupeReglages passe encore le contrôle sous le libellé selon un seuil fixe (commentaire `ponytail:`). Le remplacer par une mesure touche un composant partagé : lot à part.

## Restes et écarts
- Captures manquantes : chargement, format, accès retiré, hors ligne, aucune pièce ; fermeture par la croix et par « Fermer » (le focus est testé, pas capturé).
- La coque de production utilise encore `PolitiqueRevueKycDemo` pour le relecteur dans le test (pas de politique de production sans serveur).
- Questions ouvertes : Q-AD7-1 (réouverture sans BR-1, sécurité), Q-AD7-2, Q-AD7-4 à Q-AD7-8 ; touches +, -, 0 à confirmer (Q25).
- Hors portée : `repere_demonstration.dart:10` garde « Démonstration » en dur ; `AppBottomSheet.ouvrir` n'applique pas la réduction de mouvement (HU-1).
