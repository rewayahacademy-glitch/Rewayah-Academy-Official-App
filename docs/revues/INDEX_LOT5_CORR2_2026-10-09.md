# Lot 5 CORR-2 : revues adverses indépendantes (09/10, session b061fd81)

Le conteneur a redémarré une fois pendant le lot. La reprise a rejoué les résultats déjà obtenus, sans refaire les relectures : chaque relecture n'a eu qu'une seule passe.

`-R` = première relecture, `-R2` = relecture après la première reprise, `-R3` = relecture après la deuxième reprise.

| Étape | R | R2 | R3 | Fusion |
| :--- | :--- | :--- | :--- | :--- |
| DUREE-INSECABLE-5 | **refusée** | **refusée** | **refusée** | non fusionnée → DUREE-INSECABLE-6 |
| JONCTION-4 | acceptée avec réserves | — | — | fusionnée adfaea41 |
| PAGESHELL-200-1e | **refusée** | acceptée avec réserves | — | fusionnée 2ae375e8 |
| FILTRES-1b | **refusée** | acceptée avec réserves | — | fusionnée 93b8d1d2 |
| CORAN-320-1b | acceptée avec réserves | — | — | fusionnée f977c8a5 |
| RTL-ISOL-1 | **refusée** | acceptée avec réserves | — | fusionnée b0ba2ef2 |
| COUPE-MOTS-4 | **refusée** | acceptée avec réserves | — | fusionnée 0cf5a1b7 |
| EA-HL-DOUBLE-1f | **refusée** | acceptée avec réserves | — | fusionnée 85a408c5 |
| SUPERPOS-1b | acceptée avec réserves | — | — | fusionnée d3d352e5 |
| PUB-1b | acceptée avec réserves | — | — | fusionnée 5f5c7521 |
| CARTES-PERSO-1c | acceptée | — | — | fusionnée 4fb69553 |

**Intégration.** `corrections/revue-directeur-2026-10` passe de 5a52ff30 à **4fb69553**, poussée. Aucun commit de jonction n'a été nécessaire. Les deux commits de jonction du lot 4 (282bc950 et 5a52ff30) ont été relus par le relecteur de JONCTION-4 (voir REVUE_JONCTION-4-R.md).

**Résultats sur 4fb69553 :**
- analyze : 0 problème ;
- verifier_revue : 1407 (plafond 1533) ;
- verifier_jetons : 37 ;
- suite par dossiers : 0 échec (features +3287, core +791, router +300, widgets +451, accessibilite +362, autres +1888).

Statut : testé localement seulement.

**DUREE-INSECABLE-5.** La correction de `lib/` est acceptée à chaque relecture. C'est la garde statique, qui lit le code source, qui reste refusée : chaque relecture trouve une nouvelle forme de code qu'elle ne voit pas (littéraux collés, `this.`, record, destructuration). L'étape passe à DUREE-INSECABLE-6, avec un changement de méthode décidé par délégation le 09/10 : une garde à l'exécution sur les textes réellement rendus.
