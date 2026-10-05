# Lot 3 CORR-2 : revues adverses indépendantes (05/10, session b061fd81)

Le conteneur a redémarré pendant le lot ; à la reprise, certaines revues ont été refaites par un second relecteur indépendant. Les deux passes sont publiées, sans tri :
`-R` = première passe, `-R-bis` = seconde passe (après redémarrage), `-R2` = revue de la reprise après refus.

| Étape | Passe 1 | Passe 2 | Après reprise | Fusion |
| :--- | :--- | :--- | :--- | :--- |
| COUPE-MOTS-3 | acceptée avec réserves | — | — | fusionnée 83357cba |
| EA-HL-DOUBLE-1d | acceptée avec réserves | — | — | fusionnée b9db7195 |
| DUREE-INSECABLE-3 | **refusée** | acceptée avec réserves | — | fusionnée fdd8682d |
| PAGESHELL-200-1c | acceptée avec réserves | **refusée** | R2 (sur 4a879cbd) acceptée avec réserves | fusionnée 0d480389 |
| ALERTE-1 | acceptée avec réserves | acceptée avec réserves | — | fusionnée 6e2c91c4 |
| CARTES-PERSO-1 | acceptée avec réserves | **refusée** | R2 (sur bcb25e20) **refusée** | non fusionnée → CARTES-PERSO-1b (lot 4) |

Point de vigilance : DUREE-INSECABLE-3 a été fusionnée sur la seconde passe alors que la première l'avait refusée. Le défaut de la première passe (ancres U+200E au milieu d'un libellé) est repris dans les réserves de la seconde, et traité par DUREE-INSECABLE-4 (lot 4), relu à son tour.

Branche commune `corrections/revue-directeur-2026-10` @ 6e2c91c4 : analyze 0, verifier_revue 1550, jetons 39, suite complète 6356 réussis / 0 échec.
