# AD-9 : politique de genre pour la revue KYC (recette)

Branche `ui/admin-v1`, dépôt `D:\RA_TUTEUR\admin`. Commits : 15c6cd7 (écran), c691a34 (captures RTL et 200 %), puis « admin(AD-9): corrections de revue ».
Démonstration seulement (`?demo=admin`). Hors démonstration, le port reste `PolitiqueRevueKycIndisponible` : aucun appel réseau, pas d'onglet, et la route affiche « Pas encore disponible ». Le besoin serveur est dans `11_admin/AD-BR.md` (AD-BR-16 à 18 et 20).

## Corrections de revue
- Majeur « conflit = échec générique » : le code est gardé, et le choix est inscrit dans la Q39 (`11_admin/V/00_MAQUETTES.md`). Un texte de conflit propre attend une validation du directeur (E3).
- Majeur « Compléter mon profil » absent : l'écart est inscrit en Q41, à trancher par le directeur (E4). Le bouton n'est pas rebranché tant que la RPC auditée d'AD-BR-20 n'existe pas (§3.6).
- G2 est prolongé : politique désactivée, dossier 06 (Adam), le test ferme la visionneuse, coche les 3 points, tape « Valider le dossier », confirme, et vérifie que `nombreDecisions == 1`.
- G13 est nouveau : coque de production sans surchargesDemoAdmin (session admin seule simulée), avec le port par défaut `PolitiqueRevueKycIndisponible`. Le test vérifie qu'il n'y a pas de 4e onglet et que la route affiche « Pas encore disponible ».
- Nouvelles captures, aux 3 tailles, en clair et en sombre :
  - `ad9_6_chargement` (la capture 6 qui manquait) ;
  - `ad9_12_decision` (02E sur Adam, politique désactivée) ;
  - `ad9_13_valide` ;
  - `ad9_14_indisponible`.
- Ligne entièrement pressable : l'écart est inscrit en Q32 (E2). Il demande de faire évoluer GroupeReglages, qui compte une douzaine d'appelants, et ce n'est pas fait sans décision.
- Capture RTL : elle force un miroir `Directionality` sur un texte français. Le point final de l'aide apparaît donc en tête (« .genre »). C'est un artefact bidi, pas un défaut de mise en page. Il faut une vraie capture en arabe une fois `ar.i18n.json` complété (E7).

## Chiffres (dernier passage)
- `flutter analyze --fatal-infos` : aucun problème.
- `politique_revue_kyc_test.dart` : 12 sur 12.
- Captures AD-9 : 50 sur 50.
- Relance liée (admin_configuration, admin_dossiers, widgets, router, captures ad8 et ad9) : 495 réussis, 120 sautés (captures sans CAPTURE_DIR), 0 échec.
- Frontière (`supabase`, `.github`, `vercel.json`, `pubspec.yaml`, `lib/core/theme` depuis 73f12c8) : vide.

## HL-A-4
Fait dans 3dd89f4, dans le composant partagé `app_bottom_sheet.dart`, sans fork :
- un glisser vers le bas passe par `maybePop`, donc par PopScope (la question « Abandonner le motif saisi ? » s'affiche) ;
- les `viewInsets` du clavier sont retirés.

Les tests partent de la vraie coque (`decisions_coque_test.dart`) et sont verts au dernier passage. Captures AD-8 « HL-A-4 » : hors ligne au clic, validation inconnue ou plus prête, 200 %.

Reste : aucune capture clavier ouvert (c'est testé seulement), et le rendu à 200 % n'a pas été comparé à une maquette.

## Restes (décisions du directeur)
- E1 : emplacement et nom de la route.
- E2 : ligne pressable.
- E3 : texte de conflit.
- E4 : issue de « Profil à compléter ».
- E5 et E6 : « indisponible », « accès refusé » ou « introuvable ».
- E7 : traductions arabes.
- E8 : « KYC » dans les libellés.
- E9 : trous serveur AD-BR-20 et kyc_admin_all.
- E10 : actualisation des autres sessions.

Non commités dans pilotage-git (la règle interdit à l'agent de committer le pilotage) : les PNG AD-8 et AD-9, `AD-BR.md`, `00_MAQUETTES.md` et ce fichier.
