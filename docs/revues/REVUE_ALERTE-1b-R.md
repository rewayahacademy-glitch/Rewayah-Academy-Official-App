<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse de ALERTE-1b (branche corrections/c2-alerte-b, commit e012538f)

## Verdict : **ACCEPTÉE AVEC RÉSERVES**

Les trois points demandés sont remplis et prouvés. Le principal reste le point (3) : l'alerte urgente reste désormais en vue pendant le défilement, sans recouvrir la page. En revanche, la tête de page (titre, onglets et actions à partir de 600 px) défile encore tant qu'une alerte est ouverte. C'est consigné dans non_fait, décidé par délégation le 05/10, et la consigne interdisait de toucher `page_shell.dart`. Aucun défaut majeur prouvé.

Relecture faite en lecture seule, sur un worktree détaché, retiré à la fin. Rien n'a été poussé. Les fichiers interdits n'ont pas été touchés : le diff ne contient ni `page_shell.dart`, ni `supabase/`, ni `.github/`, ni `pubspec.yaml`, ni thème ou couleurs, ni rendu du Coran.

## Ce que fait le diff
- **`lib/core/widgets/admin_shell.dart`**
  - Un nouveau widget, `_ZoneBandeau`, pose le bandeau au-dessus de la page, hors de la zone qui défile. En dessous de 600 px, il est sous la barre mobile ; sur rail et barre latérale, il prend la gouttière et la largeur de la colonne de page.
  - La hauteur du bandeau est limitée à 50 % de la vue ; au-delà, il défile dans sa propre zone.
  - PageShell reçoit un `SizedBox.shrink()` à la place du vrai bandeau. Ses propres règles de tête restent donc actives.
  - Dans la barre mobile, le champ de recherche cède la place au bouton Recherche quand il n'a plus la largeur du mot le plus long de son indication.
- **`lib/features/alertes/bandeau_alerte_urgente.dart`** : une forme courte apparaît quand la hauteur de la vue divisée par l'échelle du texte est inférieure à 480.
- **Libellés et documentation** : deux libellés ajoutés, slang régénéré (les blocs `switch` du fichier généré sont seulement redistribués) ; mises à jour de `DASH_STRATEGIE.md` et `REVUE-DIRECTEUR-2026-10.md`.

## Vérifications faites (preuves)

| Contrôle | Résultat |
|---|---|
| `dart analyze --fatal-infos` | aucun problème |
| `tool/verifier_jetons.dart` | 44 lignes avant (base `corrections/revue-directeur-2026-10`) et après, diff vide une fois les numéros de ligne retirés |
| `tool/verifier_revue.dart` | 1550 violations avant et après, diff vide une fois les numéros de ligne retirés |
| `flutter test --concurrency=2 test/features/alertes` | +45, 0 échec |
| 17 fichiers de test liés (AdminShell, SignalRow, BandeauAlerteUrgente, surchargesDemoAdmin, recherche) | +278, 0 échec |
| `test/router` | +300 (~7 sautés), 0 échec |
| `test/accessibilite` | +362, 0 échec |
| `test/widgets` | +298, 0 échec |
| `test/core` | +681, 0 échec |

### Mutations (contre-épreuves refaites par moi)
1. **`SignalRow` remis en `Text`** : 10 échecs (les rendus en galerie et ceux du bandeau, en LTR et en RTL). Le point (1) est donc bien protégé.
2. **Ancienne coque**, avec le bandeau rendu par PageShell et sans `_ZoneBandeau` : les 10 cas de position échouent.
3. **Sans le bandeau vide passé à PageShell** : seul « 390x844 Interface guidée, Journal » échoue (débordement), comme annoncé.
4. **Forme courte désactivée** : les deux cas 320x640 à texte x2 (LTR et RTL) échouent.
5. **Ancienne recherche de la barre mobile** : les 3 tests de recherche échouent.

Le relevé des appelants de `SignalRow` (regex sur `lib/`) n'en trouve que deux, le bandeau et la galerie, et les deux sont mesurés.

### Cas supplémentaires ajoutés temporairement puis retirés
Gabarit rail et vues extrêmes : 800x500, 800x600 en RTL et Interface guidée sur le Journal, 1280x1024 à texte x4, 640x360 couché.
- **Résultat :** bandeau fixe après défilement, page sous le bandeau, au plus la moitié de la vue, tap vers `/admin/alertes`. Tout passe.
- **Exception, hors périmètre :** à 1024x768 texte x2, les libellés du rail (« Accueil », « Opérations », etc.) sont signalés tronqués. Cela relève du rail et non de ce lot ; je ne l'ai pas comparé à la base.

### Captures ouvertes
- 390x844 clair, en haut de page ;
- 390x844 sombre RTL, après défilement ;
- 320x640 texte x2, sombre et clair RTL, en forme courte ;
- 390x844 Interface guidée clair, en haut de page ;
- 1440x700 sombre, en haut de page ;
- 1440x500 sombre, après défilement.

Dans toutes ces captures :
- le bandeau est en haut et ne recouvre rien ;
- l'icône et le chevron sont miroités en RTL ;
- la cloche porte son point ;
- aucun mot n'est coupé, et l'indication de recherche passe sur 2 lignes à 390.

La série couvre 320 x2, 390 et 1440, LTR et RTL, clair et sombre, ainsi que l'Interface guidée.

## Réserves
1. **Moyenne : la tête de page défile tant qu'une alerte est ouverte.** C'est consigné dans non_fait.
   - À 1440, après défilement, la Recherche, le thème, la cloche et le compte sortent eux aussi de la vue (capture 1440x500 défilée).
   - Ce comportement existait déjà avec ALERTE-1. Il reste à traiter dans PAGESHELL-200-1d : une tête fixe sous le bandeau figé, avec le seuil de hauteur calculé sur la place qui reste.
2. **Mineure : grand vide entre le bandeau et le titre en Interface guidée**, environ 70 px (capture 390x844 guidée, en haut de page).
3. **Mineure : pas de test rail dans la suite livrée.** Je l'ai vérifié à la main et il passe ; il serait utile de l'ajouter à `alerte1b_test.dart`.
4. **Mineure : deux libellés à faire valider par le directeur** (`alertes.bandeauCourtUne` et `alertes.bandeauCourtPlusieurs`), ce qui est bien déclaré dans `tool/libelles_sources.json`.

## Statuts de preuve
- **Spécifié :** oui (fiche ADM-BANDEAU-URGENT).
- **Présent dans le code :** oui.
- **Testé localement :** oui, ci-dessus.
- **Testé sur staging, déployé :** non.
