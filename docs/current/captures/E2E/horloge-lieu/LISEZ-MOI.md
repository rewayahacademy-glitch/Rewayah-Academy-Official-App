# Captures R3 du lot HORLOGE-ET-LIEU (13/11/2026)

Trois tests de capture (vraies polices, vrai thème, fixtures et ports en mémoire, jamais un service
réel ; sautés sans `CAPTURE_DIR`), un par famille d'écrans :

```
CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu flutter test test/capture/horloge_lieu_capture_test.dart
CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu flutter test test/capture/horloge_lieu_ecrans_capture_test.dart
CAPTURE_DIR=docs/current/captures/E2E/horloge-lieu flutter test test/capture/horloge_lieu_direction_capture_test.dart
```

Chaque jeu : 390 et 1440 de large × clair et sombre × français et arabe (RTL), soit 8 PNG ;
`horloge_lieu_<écran>_<largeur>_<thème>_<langue>.png`.

| Écran | Fichiers | Ce qu'il montre |
| :--- | :--- | :--- |
| Page de la ville (`/ville`, tuteur) | `horloge_lieu_ville_*` | la consigne, la recherche, le crédit GeoNames, les villes proposées, « Plus tard » |
| Étape de la ville de la candidature d'un enseignant | `horloge_lieu_candidature_ville_*` | la même liste, à la place de l'étape du fuseau |
| Aperçu à l'inscription (ligne) | `horloge_lieu_apercu_offre_*` | « Chez vous : 19:00, puis 20:00 à partir du dimanche 28 mars 2027. » |
| Page des offres horaires (écran entier) | `horloge_lieu_page_offres_*` | la ligne d'aperçu sous chaque offre |
| Changements d'heure à venir (direction, bloc) | `horloge_lieu_changements_heure_*` | par fuseau : le jour, les familles, les enseignants, le décalage |
| L'heure chez soi, puis « Heure de La Mecque » | `horloge_lieu_heure_double_*` | « Chez vous 19:00 Paris », puis « Heure de La Mecque 21:00 » |
| Centre de notifications, annonce (famille) | `horloge_lieu_notifications_annonce_*` | « À partir du dimanche 28 mars 2027, votre cours du mercredi passe de 19:00 à 20:00. Le cours reste à la même heure à La Mecque … » (texte réel de `contenuNotificationPour`) |
| Centre de notifications, refus de conversion (direction) | `horloge_lieu_notifications_refus_*` | la classe et la cause, en mots simples |
| « Ma journée » de l'enseignant, rien aujourd'hui | `horloge_lieu_journee_rien_*` | le jour et l'heure du prochain cours, au fuseau du profil |
| Feuille du créneau (direction) | `horloge_lieu_feuille_creneau_*` | la légende « Heure de Paris » et « À l'heure de La Mecque, la classe aura lieu le mercredi à 21:00. » avant l'envoi |
| Réglages d'une classe (direction) | `horloge_lieu_feuille_reglages_*` | « Mercredi 19:00 · Heure de La Mecque : 21:00 » |
| Réglages d'une classe, refus | `horloge_lieu_feuille_reglages_refus_*` | « Rechargez l'application pour modifier un horaire. » |
| Fiche de la classe | `horloge_lieu_fiche_classe_*` | « mercredi à 19:00 · Heure de La Mecque : 21:00, chaque semaine » |
| Pilotage | `horloge_lieu_pilotage_*` | « Lundi 18:00 · Heure de La Mecque : 20:00 » sur les cartes |
| Regroupements | `horloge_lieu_regroupements_*` | la liste des classes à ouvrir, avec le nom de la ville du fuseau |
| Comptes, colonne des villes | `horloge_lieu_comptes_villes_*` | la colonne Ville, « Ville à vérifier », le bandeau « Villes à vérifier », les changements d'heure à venir |
| Comptes, menu de la ligne | `horloge_lieu_comptes_verifier_ville_*` | « Vérifier la ville d'Amina Diallo » |

## Ce que ces captures ne disent pas

- **Regroupements** : le lot n'y change que le nom de la ville du fuseau (« Heure de Los Angeles »,
  « Heure de Paris ») ; il n'y a pas de double heure sur cette page.
- **Fiche de la classe** : montée en session enseignant (comme `creneaux_routeur_reel_test.dart`) ; l'accès
  de la direction à cette fiche n'a pas été vérifié par la capture.
- **Pilotage** : le haut de la page seulement, données de démonstration réduites (pas le volume de 10 000).
- **Arabe** : plusieurs textes de l'application restent en français dans les captures arabes (« Jour »,
  « Heure », « Créer la classe », « Prête », les en-têtes des regroupements) : ce sont des textes que le lot
  n'a pas touchés (`docs/current/A-FAIRE-LANGUES.md`). Les noms de ville sont arabes quand la liste en donne un.
- **Journée de l'enseignant** : le jour et l'heure au fuseau du profil sont aussi vus sur les captures d'un
  autre lot, `docs/current/captures/E2E/heures-accueil-enseignant/` ; celles-ci montrent l'état « rien
  aujourd'hui » que ce lot a changé.
- **Courriel** de refus et d'annonce : aucune capture (texte du courriel, voir `courriel_test.ts`, non exécuté).
- Relues à l'œil : environ 25 captures sur 136, au moins une par écran ; les autres suivent le même montage.
