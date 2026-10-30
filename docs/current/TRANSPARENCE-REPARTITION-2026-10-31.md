# Répartition du paiement d'un élève, en pourcentages (TRANSPARENCE, 31/10/2026)

Statut : **estimation**, calculée par Claude pour la page « Nos prix, en toute transparence »,
sur la base décidée par le pilote le 30/10. Elle vaut pour la version des prix `v2.0.0`
(55 $ enfant, 65 $ adulte, en vigueur au 1er novembre 2026). Elle doit être revue à chaque
nouvelle version des prix. Sources : `DECISION-TARIFS-2026-10-18.md` (décisions du 19/10 et
du 22/10), `tarifs-2026-10-18.json`, `DECISION-BIBLIOTHEQUE-ET-RESTES-2026-10-30.md` §2.

Règle du directeur (22/10) : **des pourcentages seulement**, sur la page. Aucun montant de
charge, aucun taux horaire. Qui veut les montants exacts les demande à l'administration.
Les montants ci-dessous servent seulement au calcul ; ils ne quittent pas ce document.

## Base de calcul (décidée par le pilote, 30/10)

- 100 élèves : 50 enfants à 55 $ et 50 adultes à 65 $, soit 6 000 $ encaissés par mois.
- Chacun paie le **plein tarif** (aucune remise par rang) et est présent à **chaque séance**.
- 11 enseignants payés chaque mois (le scénario de référence du document du directeur).

## Charges (décision du 19/10) et calcul

| Poste (clé en base) | Règle | Montant du mois | Pour mille publié |
| :--- | :--- | ---: | ---: |
| `enseignant` | 47 % du prix (19/10) | 2 820,00 $ | 470 |
| `frais_carte_change` | environ 5 % de l'encaissé | 300,00 $ | 50 |
| `frais_envoi_paie` | 2 % de la paie + 1 $ par versement × 11 | 67,40 $ | 11 |
| `visioconference` | charge du mois | 150 $ | 25 |
| `application_hebergement` | charge du mois | 290 $ | 48 |
| `emails` | charge du mois | 20 $ | 3 |
| `stockage` | charge du mois | 5 $ | 1 |
| `comptabilite` | comptable | 150 $ | 25 |
| `developpement` | développeur | 600 $ | 100 |
| `administration` | administration | 500 $ | 83 |
| `impot_societes` | 19 % du résultat avant impôt (1 097,60 $) | 208,54 $ | 35 |
| `benefice` | le reste | 889,06 $ | 149 |
| **Total** | | **6 000 $** | **1 000** |

Arrondi : chaque charge est arrondie au dixième de point le plus proche. Le bénéfice est le
reste, pour que la somme fasse exactement 100 % (148,2 ‰ calculés, 149 ‰ publiés).

## Où vivent ces données

- Table `public.repartitions_paiement` (migration `20261031100000_politique_commerciale_famille.sql`),
  une ligne par version des prix. Une contrainte refuse un poste inconnu, un poste en double
  et une somme différente de 1 000. Aucun client ne la lit ni ne l'écrit directement.
- Lue par `public.politique_commerciale_famille()`, réservée aux comptes connectés, qui ne rend
  ni paie horaire, ni marge, ni budget.
- Pour une nouvelle version des prix : une nouvelle ligne, par une migration, avec ses
  pourcentages recalculés ici. Aucun widget ne porte un pourcentage.

## Ce qui n'est pas tranché (à signaler au directeur)

1. **47 % sur la page, 44 % dans la réalité.** Le document du directeur (§ Économie) donne à
   l'enseignant 44 % de ce qui est **réellement encaissé**, avec 90 % de présence, des remises
   et des impayés. La page dit 47 % parce que sa base suppose un plein tarif et une présence à
   chaque séance. La phrase d'estimation de la page le dit.
2. **Le « 2 % de frais de transaction » du directeur (22/10)** ne correspond à aucune ligne du
   document. La page montre deux lignes : frais de carte et de change (5 %), frais d'envoi de
   la paie (1,1 %).
3. **Deux lignes ajoutées** par rapport à la liste du pilote, pour « ne négliger aucune
   dépense » : l'impôt britannique sur les sociétés (19 %) et les frais d'envoi de la paie.
4. Le résultat net du document du directeur (919 $, 16 % à 100 élèves) ne compte ni les frais
   de carte ni l'impôt. Le calcul ci-dessus les compte : 889 $, 14,9 %.
5. Jusqu'au 31/10, la version des prix en vigueur en base est `v1.0.0` (50 $ et 60 $, deux
   séances d'essai), caduque depuis le 18/10. Le foyer la lit jusqu'à cette date ; la page de
   transparence montre déjà la répartition de la `v2.0.0` et dit sa date d'effet.
