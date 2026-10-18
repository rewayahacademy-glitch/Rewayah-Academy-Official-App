# Décision : offre et tarifs (directeur, 18/10/2026)

**Source unique des prix, remises, règles de paiement et paie des enseignants**, pour l'application, le site public et systeme.io. Une valeur qui change ici change aux trois endroits le même jour.

- Document du directeur, texte intégral : `docs/current/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md` (copie fidèle de son document « Offre et tarifs Rewayah Academy », https://claude.ai/code/artifact/bb43bdab-2d75-41c7-ad65-768eba22d5a2).
- Valeurs lisibles par un programme : `docs/current/tarifs-2026-10-18.json`. L'application lit ses prix en base (politique commerciale publiée) ; le site public lit ce fichier.
- Le directeur l'a dit : **c'est le dernier passage sur les tarifs**. Aucun agent ne change une valeur sans nouvelle décision datée.

## Dernière consigne du directeur (18/10/2026)

Part de l'enseignant pour les **enfants portée de 21 % à 22,5 %** du prix ; **adultes inchangés à 30 %**. Taux arrondi au centime : **0,95 $ par élève présent et par heure** pour un enfant (0,95 x 13 h / 55 $ = 22,45 %), **1,00 $** pour un adulte. Tous les chiffres qui en dépendent ont été recalculés dans le document (groupe plein enfant 4,75 $ de l'heure ; paie à 100 élèves 1 401 $ ; résultat net 2 519 $, 45 % ; point mort 19 élèves).

## Les valeurs (résumé)

| Règle | Enfant (6 à 17 ans) | Adulte (18 ans et plus) |
|---|---|---|
| Prix mensuel hors taxes | 55 $ | 65 $ |
| Trimestriel (-5 %), annuel (-10 %) | 157 $, 594 $ | 185 $, 702 $ |
| Séances | 3 x 60 min, pause 5 min | 3 x 90 min, pause 10 min |
| Groupe | 3 à 5 | 3 à 6 |
| Séance due à partir de | 45 min de présence | 70 min |
| Paie enseignant | 0,95 $ par élève présent et par heure | 1,00 $ |
| Part de l'enseignant | 22,5 % | 30 % |

Remises : 2e inscrit du foyer -8 %, 3e et suivants -17 %, trimestre -5 %, année -10 %, parrainage 20 $ de crédit chacun, bourse -30 % (non cumulable, 5 % des élèves au plus, revue tous les 6 mois). Foyer, prépaiement et parrainage cumulés : 25 % du prix au plus. Pas d'essai gratuit : première semaine remboursée. Renouvellement le 1er ; relances J-7, J-3, J-1 ; grâce du 1er au 3 ; suspension le 4 ; place gardée 14 jours, libérée le 18.

## Ce que cette décision remplace

Toute valeur ci-dessous est **caduque** ; ne pas la reprendre, même si elle figure encore dans un document de `docs/current/sources-directeur-2026-10/` (ces sources sont conservées telles quelles, comme archives).

| Ancienne valeur | Où on la trouve | Remplacée par |
|---|---|---|
| 50 $ enfant, 60 $ adulte (et 40 à 60 $) | Guide Finance V4 FIN4-01 ; plan V3 ; dossier maître (§13, CFO) ; politique `v1.0.0` en base ; simulation du 17/10 | 55 $ et 65 $ hors taxes |
| 2 séances d'essai gratuites | Guide Finance V4 FIN4-10 ; dossier maître ; politique `v1.0.0` | Aucun essai ; première semaine remboursée |
| Remise foyer 0 / 5 / 10 % ; ou 5 $ au 3e et 7 $ au 4e | Dossier maître (contrat CFO) ; politique `v1.0.0` ; simulation du 17/10 | -8 % au 2e, -17 % au 3e et suivants |
| Paie horaire par classe (4 $ de base, 7 $ de plafond) ; ou 20 $ par élève | Règles de rémunération en base ; politique `v1.0.0` ; dossier maître (proposition) | 0,95 $ (enfant) et 1,00 $ (adulte) par élève présent et par heure |
| Crédits prépayés qui expirent (50 $ pour 60 jours) | Specs d'origine | Abonnement mensuel renouvelé le 1er |
| Place gardée 7 jours | Guide Finance V4 §1.7 ; politique `v1.0.0` | 14 jours après la suspension du 4 |
| Groupe ouvert à 4 élèves | Politique `v1.0.0` (`minimum_ouverture`) | 3 élèves |
| Page publique `/fr/tarifs` (« les deux premiers membres gardent leur tarif ») | `site-public/content/pages.json` | Grille, remises et mentions de ce document |

## Contradictions tranchées

1. **Âge de la formule adulte.** Le document fixait l'adulte à 15 ans ; les règles du programme (29/09, confirmées le 12/10) le fixent à 18 ans. **Directeur, 18/10/2026 : 18 ans.** Enfant 6 à 17 ans (55 $, 3 x 60 min, classe enfant), adulte 18 ans et plus (65 $, 3 x 90 min, classe adulte). Cohortes du programme inchangées (6-9, 10-13, 14-17, 18+) ; aucun mineur dans une classe d'adultes. La pause enfant suit le programme (5 min) et « mode enfant » devient « Interface guidée par défaut de 6 à 9 ans » (vocabulaire et registre du 14/10). Le document du directeur est corrigé en conséquence.
2. **Essai.** Le guide Finance V4 prévoyait 2 séances d'essai ; le document du 18/10 le remplace par la première semaine remboursée. La politique publiée porte `essai_actif = false`.
3. **Cahier de transmission.** Le document le veut hebdomadaire ; l'application en tient un par séance. Ce n'est pas un tarif : la paie du mois est mise en attente tant que le cahier de la semaine manque, et le passage au cahier hebdomadaire est inscrit comme lot à part dans la passation.

## Points ouverts du document, valeurs par défaut appliquées

Le document laisse cinq points au directeur, chacun avec une valeur par défaut. Elles sont appliquées telles quelles tant qu'il ne dit pas autre chose : pause adulte 10 min et séance due à 70 min sur 90 ; observation du parent une fois par séance ; élève absent jamais payé ; taux de départ 0,95 et 1,00 $ ; groupes adultes séparés hommes et femmes (déjà la règle de l'application).

## Où chaque valeur vit

- **Application** : politique commerciale publiée en base (`politiques_commerciales`, version `v2.0.0`), lue par la facturation, la recharge et les écrans ; paie des enseignants par élève présent (règle de rémunération en base). Aucun montant dans le code Flutter.
- **Site public** : `site-public/` est une zone protégée par le garde-fou ; rien n'y a encore été changé. L'agent qui finira le site applique la consigne ci-dessous.
- **systeme.io** : produits et codes de remise listés dans le document (section « Une seule offre partout »).

## Consigne pour l'agent qui finira le site public

1. Lire les valeurs dans `docs/current/tarifs-2026-10-18.json` (copier ce fichier en `site-public/content/tarifs.json` et le faire lire par `build_site.py`) : jamais un montant tapé dans une page.
2. Page `/fr/tarifs` de `site-public/content/pages.json` : remplacer les sections actuelles (« Aucun montant n'est affiché… », « Les deux premiers membres gardent leur tarif… », caduques) par, dans cet ordre : la grille (deux formules, mensuel, trimestriel, annuel, prix par séance), `encart_remises`, le tableau « Ce que coûte une fratrie » du document (55 ; 105,60 ; 151,25 ; 196,90 $), `mentions_sous_la_grille`, puis les règles de paiement à publier (première semaine remboursée, résiliation libre, passage à la formule adulte à 18 ans, taxes, moyens de paiement).
3. Pages `/fr/cours` et `/fr/familles` : `encart_enfant` et `encart_adulte` tels quels. Page `/fr/recrutement` : `encart_enseignant` tel quel.
4. Simulateur (`site-public/styles/site.js`, « Le calcul est momentanément indisponible ») : calculer le total d'un mois complet à partir du fichier. Rang dans le foyer : le 1er inscrit paie le plein tarif, le 2e -8 %, le 3e et suivants -17 % (`remises.foyer`). Le rang suit l'ordre d'inscription : pour un foyer qui mêle enfants et adultes, afficher la fourchette entre l'ordre le plus favorable et le moins favorable. Vérifications : 2 enfants = 105,60 $ ; 3 enfants = 151,25 $ ; 2 adultes = 124,80 $. Toujours « hors taxes ».
5. Le statut des pages (`status: "blocked"`) ne change que sur décision du directeur : les conditions de vente restent à faire confirmer par un conseil (document, section « Règles de paiement »).
