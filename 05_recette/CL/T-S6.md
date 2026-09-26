# T-S6 : page démo et recette des écrans de secours (lot CL-7)

Date : 26/09/2026. Branche `ui/classe-v1`, commit `56541ce`. Plan : `10_classe/07_SECOURS.md` §3 T-S6. Règles gelées appliquées au lot (nouveau) ; rien renvoyé à HU-1 pour CL-7.

## Corrections des écarts de T-S5

- **(a) Caméra désactivée pour ce profil.** La `StatusPill` (prévue pour 2 mots) passait sur deux lignes à 768. Présentation retenue : le **texte d'état discret** déjà employé pour « La séance se poursuit. » (encre atténuée, `bodyMedium`), posé au-dessus du dock, aligné start, écart 8, **à toutes les tailles** (plus rien dans la barre). Aucun fork : `StatutCameraInterdite` compose un `Text` du thème ; `LocalFeedback` écarté (retour bref qui disparaît, `liveRegion` : inadapté à un statut permanent). Une ligne à 390 / 768 / 1440 (captures relues), reflue à 320 et à 200 %.
- **(b) Accès retiré** : focus clavier explicite posé sur l'action principale « Retour à la Classe » à l'ouverture ; le titre reste l'en-tête lu en premier. Extension additive, sans copie : `ActionPrincipale.autofocus` (transmis à `Pressable`), `EcranResultat.focusAction`, activé par `ResultatSeance` pour `IssueSeance.accesRetire`.
- Captures TS5 mises à jour : `TS5/cl7_04_camera_interdite_*` (6). Les captures d'accès retiré ne changent pas (l'anneau de focus n'apparaît qu'en navigation clavier).

## T-S6 fait

- `/demo/salle` : pour chaque rôle, deux groupes titrés « Déroulé de la séance » (6 états) puis « Situations de secours » (9 ; 8 pour l'enseignant, sans « Caméra interdite », sans objet). Titre de rôle en en-tête sémantique. Clés `salle.seance.demo.groupes.*` (fr ; ar par repli, comme les autres libellés de démo).
- Démo sans serveur : « Réessayer » (reconnexion impossible) simule le retour de la connexion (« Connexion rétablie. ») ; « Continuer sans micro » laisse le micro coupé. « Ouvrir les réglages » reste non rendu (BR-1).
- Libellés des liens repliables (`Flexible`) : aucun débordement à 320 ni à 200 %.

## Preuves

- `flutter analyze --fatal-infos` : 0 problème.
- `dart run tool/verifier_jetons.dart` : 2 écarts **antérieurs et hors lot** (`repere_demonstration.dart:37`, `scanner_page.dart:467`), aucun dans les fichiers touchés.
- `flutter test test/features/salle_seance/ test/features/demo/ test/core/ test/widgets/` : **619 réussis, 331 sautés (captures sans `CAPTURE_DIR`), 0 échec.**
- `test/features/demo/demo_salle_page_test.dart` (nouveau, 34 tests + 6 captures) : 9/9/8 situations ; chaque lien de secours tapé ouvre la bonne salle (`role`, `etat` dans l'adresse, salle montée) ; liste sans débordement 320 (100 %), 390/768/1440 (200 %) ; clavier : Tab atteint un lien, il reste visible (focus jamais masqué), Entrée l'ouvre ; Réessayer → « Connexion rétablie. ».
- `salle_secours_t_s5_test.dart` mis à jour : statut hors du dock, au-dessus, aligné sur le début du dock à 1440 ; zoom 200 % à 390/768/1440 et 320x1400 ; 320x640 à 100 % ; focus clavier sur l'action de l'accès retiré aux 3 tailles, Entrée sort.
- Captures `10_classe/captures/TS6/` : `cl7_demo_liste_{390x844,768x1024,1440x900}_{light,dark}` (6). Relues : `cl7_demo_liste_390x844_light`, `TS5/cl7_04_camera_interdite_768x1024@1_light`, `_1440x900@1_dark`.
- Relecture M3 / Apple HIG : faite (WebFetch + WebSearch), colonne « Consultation » de `UX_REVIEW_CL-7.md` mise à jour ; aucune conclusion ne change. Checklist U1 à U11 cochée (§4 du même fichier).

## Reste / à trancher par le directeur

- Q-S1 (statut caméra visible ou seulement lu), Q-S2 (textes PROPOSITION), boutons guidés inactifs sans couleur pendant la reconnexion (T-S2) : voir `RAPPORT.md`.
- Branchement réel (détection réseau, permissions, révocation) : BR-1.
