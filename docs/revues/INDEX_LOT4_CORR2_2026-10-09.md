# Lot 4 CORR-2 : revues adverses indépendantes (09/10, session b061fd81)

`-R` = première relecture, `-R2` = relecture après la première reprise, `-R3` = relecture après la deuxième reprise. Chaque étape n'a eu qu'une seule passe par relecture : aucun doublon cette fois.

| Étape | R | R2 | R3 | Fusion |
| :--- | :--- | :--- | :--- | :--- |
| CARTES-PERSO-1b | acceptée avec réserves | — | — | fusionnée b787f12c |
| PAGESHELL-200-1d | acceptée avec réserves | — | — | fusionnée 65160f89 |
| COUPE-MOTS-3b | acceptée avec réserves | — | — | fusionnée ec1e6f45 |
| EA-HL-DOUBLE-1e | **refusée** | acceptée avec réserves | — | fusionnée e1d8fa56 |
| ALERTE-1b | acceptée avec réserves | — | — | fusionnée 15ba5afb |
| FILTRES-1 | acceptée avec réserves | — | — | fusionnée 38f555d8 |
| SUPERPOS-1 | **refusée** | acceptée avec réserves | — | fusionnée 2e7d79d2 |
| PUB-1 | **refusée** | acceptée avec réserves | — | fusionnée 254a0d8f |
| CORAN-320-1 | acceptée avec réserves | — | — | fusionnée 5396485b |
| DUREE-INSECABLE-4 | **refusée** | **refusée** | **refusée** | non fusionnée → DUREE-INSECABLE-5 |

Intégration : `corrections/revue-directeur-2026-10` passe de 6e2c91c4 à **5a52ff30**, poussée. Deux commits de jonction ont été écrits par l'intégrateur :
- 282bc950 : la feuille des cartes passe par ZoneSaisie (garde SUPERPOS-1), et deux libellés n'évoquent plus la connexion (garde EA-HL-DOUBLE-1e) ;
- 5a52ff30 : une exception de test pour l'adresse d'une carte à 320 px x2.

Ces deux commits sont soumis à une relecture indépendante dans le lot 5.

Résultats sur 5a52ff30 :
- analyze : 0 problème ;
- verifier_revue : 1533 (plafond 1550) ;
- verifier_jetons : 37 ;
- suite par dossiers : 0 échec (test/features : +3037).

Statut : testé localement seulement, ni sur staging, ni déployé.

DUREE-INSECABLE-4 a été refusée trois fois sur le même point : une ancre U+200E reste au milieu d'un libellé, dans un composant partagé, et la garde de test ne la détecte pas. L'étape n'est pas fusionnée et passe à DUREE-INSECABLE-5.
