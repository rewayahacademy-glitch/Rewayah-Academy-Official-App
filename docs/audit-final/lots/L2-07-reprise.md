# L2-07-reprise - Le matricule visible en démonstration, et les captures de la fiche

Reprise issue de L2-V (défaut D-5). Petit lot.

## 1. But et pourquoi

`portMatriculeProvider` vaut `MatriculeIndisponible` par défaut et aucune surcharge de démonstration ne le remplace : dans `?demo=tuteur`, « Mon compte » n'affiche aucune ligne de matricule (capture `L2-V_L2-07_390_light.png`). La recette de la préversion, qui ne se fait qu'en démonstration, ne peut donc rien montrer. Les captures demandées par la fiche L2-07 n'ont pas été faites.

## 2. Critère de réussite

1. Les démonstrations tuteur (et adulte si elle a Mon espace) surchargent `portMatriculeProvider` par `MatriculeDemo` avec des matricules fictifs de la forme `RA-26-nnnn`, rôle à côté, pour le tuteur et chaque enfant de démonstration.
2. Captures `L2-07_compte_390_light.png`, `L2-07_compte_390ar_light.png`, `L2-07_foyer_390_light.png` dans `docs/audit-final/captures/lots/`.
3. Production inchangée (`main.dart` garde `MatriculeSupabase`).

## 3. Ce qu'il faut lire

- `lib/features/demo/mode_demonstration.dart` (`surchargesDemoTuteur`), `lib/core/identite/matricule_demo.dart`, `DonneesDemo` (identifiants des profils).

## 4. Fichiers autorisés et interdits

Autorisés : `lib/features/demo/mode_demonstration.dart` (une surcharge), `lib/core/identite/matricule_demo.dart`, `test/features/demo/`, les trois captures. Interdits : `supabase/**`, `lib/main.dart`.

## 5. Étapes

1. Ajouter la surcharge avec trois matricules (tuteur, Aïcha, Yusuf).
2. Test : la démonstration rend la ligne sur Mon compte.
3. Captures sur construction web locale.

## 6. Vérifications

Les six commandes ; `flutter test test/features/demo test/features/compte`.

## 7. Pièges connus

- Ne pas réutiliser les anciens codes (`RA-CD0034`) de la démonstration : la décision du 12/10 les abandonne.

## 8. Quand s'arrêter et demander

- Si la démonstration ne connaît pas l'identifiant de profil du tuteur : s'arrêter et le dire.

## 9. Commit

- Branche : `lots/L2-07R-matricule-demo`, partie de `lots/V2-candidate`.
- Message : `feat(demo): matricule visible dans la demonstration (L2-07-reprise)`.

## 10. Modèle conseillé

Haiku suffit.
