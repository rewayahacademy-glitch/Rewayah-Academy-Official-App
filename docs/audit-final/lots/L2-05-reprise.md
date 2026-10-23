# L2-05-reprise - Le formulaire d'offre se ferme après une création réussie ; nombres insécables ; actions de carte en trailing

Reprise issue de L2-V (défaut D-3).

## 1. But et pourquoi

1. Dans l'application web (construction locale du commit `42f513b1`, `?demo=admin`), après « Créer l'offre » avec trois jours valides, l'offre est créée par le port (elle apparaît, en brouillon, dès que la liste est relue) mais le formulaire reste ouvert et la liste n'est pas relue. Un second clic reçoit le refus « doublon » de l'index `offres_horaires_motif_unique` : l'administrateur croit à un échec. Reproduit 6 fois (390 et 1440, souris et clavier, release et profile), sans erreur en console ; le même parcours en test widget sur le vrai routeur (VM et `--platform chrome`) ferme le formulaire. Captures : `L2-V_L2-05-apres-creer-reste-ouvert_1440_light.png`, `L2-V_L2-05-offre-creee-retrait_1440_light.png`.
2. `test/accessibilite/duree_insecable_3_test.dart` est rouge : `nouvelle_offre_page.dart:82` (`manqueNombre`) et `:256` (`joursAide`) passent un nombre sans `insecable` ni `valeurSeule`.
3. DESIGN-GOV contrat B : l'action d'une carte (« Retirer », « Publier ») est au bord leading ; elle doit être au bord trailing, à 16 sous le contenu.

## 2. Critère de réussite

1. Dans le navigateur, une création réussie ferme le formulaire et montre la liste relue avec la phrase « offre créée » ; preuve par capture Playwright sur construction locale (méthode `scratchpad/L2-V/capture.js`).
2. `duree_insecable_3_test.dart` vert.
3. Actions de carte au bord trailing, en LTR et en RTL (captures 390 clair, 390 arabe).
4. Les 31 tests d'écran restent verts.

## 3. Ce qu'il faut lire

- `lib/features/admin_offres/admin_offres_page.dart` (`_creer`, lignes 60 à 80), `nouvelle_offre_page.dart` (`_envoyer`, lignes 66 à 118), `carte_offre.dart`.
- `lib/core/widgets/page_parcours.dart` (pied d'action, retour).
- `test/accessibilite/duree_insecable_3_test.dart` et la fonction `insecable` qu'il cite.
- `docs/current/DESIGN-GOV-2026-09-26.md` contrat B.

## 4. Fichiers autorisés et interdits

Autorisés : `lib/features/admin_offres/**`, `test/features/admin_offres/**`. Interdits : `lib/core/**` (sauf démonstration si la cause y est, à dire), `supabase/**`.

## 5. Étapes

1. Reproduire dans le navigateur (construction locale, `?demo=admin`, routes en `/#/...`). Instrumenter provisoirement (`journalDev`) après `port.creer`, avant et après `mounted` et `pop`, construction profile : nommer la ligne qui ne s'exécute pas.
2. Corriger à la racine. Piste : ne pas dépendre du `pop(true)` d'une route poussée sur le navigateur racine au-dessus de la coquille ; par exemple relire la liste (`ref.invalidate(offresAdminProvider)`) et revenir par `GoRouter` ou par un `pop` du navigateur qui a poussé (`Navigator.of(context, rootNavigator: ...)` cohérent des deux côtés), puis vérifier dans le navigateur.
3. Envelopper les deux nombres par `insecable`.
4. Aligner les actions de carte en trailing.

## 6. Vérifications

Les six commandes ; `flutter test test/features/admin_offres test/accessibilite/duree_insecable_3_test.dart` ; capture de la liste après création.

## 7. Pièges connus

- Les tests widget passent déjà : ils ne prouvent pas le défaut. La preuve est dans le navigateur.
- Le serveur refuse une offre vivante identique (`offres_horaires_motif_unique`) : un essai répété doit changer d'heure ou de jours.

## 8. Quand s'arrêter et demander

- Si la cause est dans `PageParcours` ou le routeur (fichiers partagés) : s'arrêter, nommer la ligne, proposer le correctif.

## 9. Commit

- Branche : `lots/L2-05R-offre-creee`, partie de `lots/V2-candidate`.
- Message : `fix(admin): le formulaire d offre se ferme apres creation, nombres insecables, actions en trailing (L2-05-reprise)`.

## 10. Modèle conseillé

Sonnet (cause non isolée, preuve dans le navigateur).
