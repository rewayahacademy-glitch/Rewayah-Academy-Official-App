# Simulation économique — 100 élèves

> 17 octobre 2026. Couche 3 du système de test demandé par l'opérateur : le
> modèle financier, indépendant de l'application. Les couches 1 (population
> de test sur une base staging) et 2 (parcours joués dans l'app) viendront
> ensuite et réutiliseront `genererPopulation()`.

## Où est le code

| Fichier | Rôle |
| :--- | :--- |
| `tool/simulation/modele_academie.mjs` | Le modèle : paramètres, règles de tarif, population, Monte-Carlo. Sans dépendance, tourne sous Node et dans le navigateur |
| `tool/simulation/simuler.mjs` | Rapport Markdown des quatre scénarios |
| `tool/simulation/modele_academie.test.mjs` | 11 tests (remises, groupes, frais, déterminisme, centimes entiers) |
| `tool/simulation/simulateur.html` | Le tableau interactif publié (artifact), qui importe le modèle tel quel |

```
node --test tool/simulation/modele_academie.test.mjs
node tool/simulation/simuler.mjs              # 1 000 tirages × 12 mois, ~4 s
node tool/simulation/simuler.mjs --json       # résultats bruts
```

Tout montant est un entier en centimes de dollar ; les taux sont en points de
base. Une même graine redonne exactement les mêmes chiffres.

## Ce qui est fixé par l'opérateur

- Enfant 50 $ / mois, 1 h × 3 par semaine ; adulte 60 $ / mois, 1 h 30 × 3 par semaine.
- Remise famille : aucune pour la 1re et la 2e personne, 5 $ sur la 3e, 7 $ sur
  chaque personne à partir de la 4e (la 3e garde ses 5 $).
- Groupes de 5 enfants (parfois 4), de 6 adultes (parfois 5) ; un enseignant pour
  deux groupes ; administration de 4 personnes.

## Ce qui est supposé, et réglable

| Hypothèse | Valeur par défaut |
| :--- | :--- |
| Part d'enfants | 45 % |
| Tranches enfant (migration 0043) | 5-7 : 25 %, 8-10 : 30 %, 11-14 : 30 %, 15-17 : 15 % |
| Enfants inscrits par famille | 1 : 30 %, 2 : 35 %, 3 : 20 %, 4 : 10 %, 5 : 5 % |
| Profils payeurs (réaliste) | en avance 15 %, ponctuel 45 %, retard léger 20 %, retard lourd 12 %, mauvais payeur 8 % |
| Suspension | après 2 mois d'impayé, la famille part ; sa place est reprise un mois plus tard |
| Disponibilité | occupé 40 % (25 % d'absences), disponible 60 % (8 %) |
| Plaintes | jamais 50 %, parfois 35 %, souvent 15 % (1,5 par mois, départ plus probable) |
| Séances annulées | 2 % |
| Adultes | séparés hommes / femmes, enseignant du même sexe ; enfants mixtes |
| Cartes | 50 % Europe, 10 % Royaume-Uni, 40 % ailleurs ; facturation en USD sur compte EUR (+2 %) |
| Visio | 700 kbps descendants par participant (audio + vidéo simulcast basse, ADR-001) |
| Taxes, TVA, cotisations | **0 %, à renseigner** : la structure juridique n'est pas connue |
| Paie de l'administration | **0 $, à renseigner** |

Services, grilles publiques relevées le 17 octobre 2026 : Supabase Pro 25 $,
base staging 10 $, Vercel Pro 20 $ (Hobby interdit l'usage commercial),
LiveKit Ship 50 $ (150 000 minutes-participant et 250 Go inclus, puis
0,0005 $ / min et 0,12 $ / Go), domaine 1,25 $, banque 10 $, GitHub, Sentry et
email dans les quotas gratuits. Non inclus : PITR Supabase (~100 $), comptes
Apple (99 $ / an) et Google Play (25 $).

## Résultats (1 000 tirages × 12 mois, graine 20261017, mois 3 à 12)

Population générée : 100 élèves (45 enfants, 55 adultes), 67 familles payeuses,
21 groupes, 11 enseignants. Facturation pleine : 5 472 $ / mois, dont 78 $ de
remises familiales.

| Mois type (médiane) | Idéal | Optimiste | Réaliste | Pessimiste |
| :--- | ---: | ---: | ---: | ---: |
| Encaissé | 5 472 $ | 5 355 $ | 5 208 $ | 4 873 $ |
| 1 mois sur 10 sous | 5 472 $ | 5 036 $ | 4 819 $ | 4 365 $ |
| Frais de carte | 247 $ | 244 $ | 236 $ | 225 $ |
| LiveKit | 95 $ | 84 $ | 83 $ | 80 $ |
| Reste avant enseignants | 5 064 $ | 4 960 $ | 4 822 $ | 4 501 $ |

| Taux horaire max tenu 9 mois sur 10 | Idéal | Optimiste | Réaliste | Pessimiste |
| :--- | ---: | ---: | ---: | ---: |
| Marge 20 % | 11,48 $ | 10,75 $ | 10,28 $ | 9,28 $ |
| Marge 30 % | 9,89 $ | 9,26 $ | 8,85 $ | 7,99 $ |
| Marge 40 % | 8,30 $ | 7,78 $ | 7,43 $ | 6,70 $ |

À 8,85 $ / h, un enseignant à deux groupes d'adultes (39 h / mois) touche
345 $, à deux groupes d'enfants (26 h) 230 $.

## Ce que les chiffres disent

1. **Le remplissage des groupes pèse plus que les retards de paiement.** Un
   groupe d'enfants plein rapporte 19,23 $ par heure de cours, à 4 élèves
   15,38 $, à 3 élèves 11,54 $. Les heures payées à l'enseignant ne baissent
   pas. Avec 45 enfants répartis par tranche d'âge, 14 groupes sur 21 ne sont
   pas pleins.
2. **Un adulte rapporte moins par heure qu'un enfant** : 60 $ pour 19,5 h
   (3,08 $ / h) contre 50 $ pour 13 h (3,85 $ / h).
3. **Les frais de carte coûtent trois fois LiveKit** (~4,5 % de l'encaissé).
   Facturer en euros ou tenir un solde en dollars supprime les 2 % de
   conversion, soit ~110 $ / mois.
4. **Le premier mois encaisse ~18 % de moins** : les paiements en retard
   n'arrivent qu'au mois suivant. Prévoir la trésorerie d'un mois de paie.
5. **LiveKit tient dans le palier Ship** pour les minutes ; c'est la bande
   passante qui dépasse (≈ 500 Go pour 250 inclus). En audio seul, LiveKit
   revient à 50 $.

## Questions encore ouvertes

- Structure juridique, donc TVA et cotisations : elles peuvent prendre 20 % de
  l'encaissé ou plus, et changent tout le tableau.
- Rémunération de l'équipe d'administration.
- Origine réelle des élèves (cartes européennes ou non).
- Groupes d'enfants séparés par sexe à partir d'un certain âge ?
- Où créer la population de test : un second projet Supabase gratuit
  « staging » est recommandé, l'unique projet actuel tenant lieu de production.
