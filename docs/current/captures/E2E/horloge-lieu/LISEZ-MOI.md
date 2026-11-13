# Captures R3 du lot HORLOGE-ET-LIEU (13/11/2026)

Générées par `test/capture/horloge_lieu_capture_test.dart` (vraies polices, vrai thème, données de
démonstration fournies par des ports en mémoire ; aucun service réel) :

```
CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu flutter test test/capture/horloge_lieu_capture_test.dart
```

40 PNG : 5 écrans × 390 et 1440 de large × clair et sombre × français et arabe (RTL).

| Écran | Fichiers | Ce qu'il montre |
| :--- | :--- | :--- |
| Page de la ville (`/ville`, tuteur) | `horloge_lieu_ville_*` | la consigne, la recherche, le crédit GeoNames, les villes proposées, « Plus tard » tant qu'il reste un report |
| Étape de la ville de la candidature d'un enseignant | `horloge_lieu_candidature_ville_*` | la même liste, à la place de l'étape du fuseau |
| Aperçu à l'inscription dans une classe | `horloge_lieu_apercu_offre_*` | « Chez vous : 19:00, puis 20:00 à partir du dimanche 28 mars 2027. » |
| Changements d'heure à venir (direction) | `horloge_lieu_changements_heure_*` | par fuseau : le jour, le nombre de familles et d'enseignants, le décalage |
| L'heure chez soi, puis « Heure de La Mecque » | `horloge_lieu_heure_double_*` | « Chez vous 19:00 Paris », puis « Heure de La Mecque 21:00 » |

Pas de capture, et pourquoi (le test de rendu de chacun existe, pas la capture) : les feuilles du
créneau et des réglages d'une classe, la fiche de la classe, le pilotage, les regroupements, la page des
Comptes (colonne des villes), la journée de l'enseignant, la page des offres : ces écrans passent par
leur harnais de test (routeur réel, `creneaux_routeur_reel_test.dart`, `villes_enseignants_test.dart`) mais
n'ont pas de capture dans ce lot. Les captures en arabe de la page de la ville montrent les noms de ville
arabes quand la liste en donne un, et le nom latin sinon (région en latin : donnée de la liste).
