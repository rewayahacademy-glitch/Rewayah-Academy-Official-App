# T-S2 : écrans de secours, bandeau et retour bref (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `b7ab510`. Plan : `10_classe/07_SECOURS.md` §3 T-S2. Aucune maquette (feu vert du directeur) ; références : `UX_REVIEW_CL-7.md` U1, U2, U4, U10, U11.

## Fait

- `lib/core/widgets/offline_banner.dart` : constructeur additif `OfflineBanner.message({message, sousTexte, icone})`, qui ne lit pas `horsLigneProvider` ; rendu commun extrait dans un `_Bandeau` privé (même registre doux `washWarning`, filet fort, `Semantics(liveRegion: true)`). `const OfflineBanner()` inchangé (texte et fournisseur).
- `salle_seance.dart` : widget `BandeauSecours(vue, gouttiere)` posé sous chaque `ChromeSeance` (élève standard, guidée, les 5 dispositions enseignant) et, en mode agrandi, à la place de l'en-tête. Bandeau pour `reseauFaible` / `reconnexion` (icône réseau en réseau faible, jamais l'icône hors ligne : P06.5), sous-texte guidée ; `LocalFeedback` « Connexion rétablie. » (3 s, puis disparition seule). `AnimatedSize` en `AppMouvement.apparition`, 0 en réduction de mouvement.
- `dock_seance.dart` : `BoutonAppel.actif` (même composant). Inerte : disque `surfaceRaised` + filet `borderResting`, icône et libellé `inkMuted`, aucune transparence, `Pressable(actif: false)`. Micro (Parler en guidée) et Caméra : `actif = vue.commandesPublicationActives`, libellé d'accessibilité `{Micro}. Indisponible pendant la reconnexion.`.

## Preuves

- `flutter analyze --fatal-infos` : 0 problème. `verifier_jetons` : aucun signalement sur les fichiers touchés.
- Nouveaux tests : `test/core/widgets/offline_banner_test.dart` (4) et `test/features/salle_seance/salle_secours_bandeau_test.dart` (63 + 54 captures) : texte exact par rôle et par état, aucun bandeau en repos ni en rétablie, jamais « hors ligne » en réseau faible ; retour bref affiché puis disparu ; en reconnexion **taper Micro/Parler et Caméra n'appelle pas** `onMicro`/`onCamera`, libellé d'accessibilité présent ; **taper Quitter puis confirmer appelle** `onQuitter` (ES, IG : « Quitter » ; EN : « Quitter et ouvrir le cahier ») ; témoin réseau faible où Micro et Caméra répondent ; mode agrandi garde le bandeau ; aucun débordement 390, 768, 1440 et zoom 2,0 à 390 (3 rôles x 3 états).
- `flutter test test/features/salle_seance/ test/features/demo/` : 325 réussis, 229 sautés (captures sans `CAPTURE_DIR`), 0 échec. Avec `test/core/widgets/` et `test/widgets/` : 487 réussis, 0 échec.
- Captures : `10_classe/captures/TS2/`, 54 PNG `cl7_{04,05,06}_{reseau_faible,reconnexion,retablie}_{390x844@3,768x1024@1,1440x900@1}_{light,dark}`. Relues : `cl7_04_reconnexion_390x844@3_light`, `cl7_05_reseau_faible_768x1024@1_light`, `cl7_06_reseau_faible_1440x900@1_dark`, `cl7_04_retablie_1440x900@1_light`.

## Écarts

- Tests dans un nouveau fichier `salle_secours_bandeau_test.dart` au lieu de `salle_seance_widget_test.dart` (même dossier ; le fichier existant est propre à l'élève), et `test/core/widgets/` créé comme prévu.
- Bandeau bord à bord de la colonne salle (convention bannière M3), texte à 16 dans le bandeau ; seul le retour bref suit la gouttière 16 / 32. À harmoniser en HU-1 si le directeur veut le bandeau dans la gouttière.
- Élève desktop, rétablie : le retour bref touche le haut du support (le gabarit desktop ne met pas d'écart sous l'en-tête). Consigné pour HU-1, non corrigé ici.
- Enseignant : pas de mode agrandi dans le code actuel, donc rien à couvrir de ce côté.
- Guidée en reconnexion : Parler et Caméra désactivés passent au fond neutre (plus de disques pleins) : lecture voulue de l'état `disabled` (contrat E), à confirmer par le directeur.
- Reste pour la suite du lot : bloc d'erreur (T-S3), feuille micro bloqué (T-S4), caméra interdite / prolongée / accès retiré (T-S5), page démo et recette (T-S6).
