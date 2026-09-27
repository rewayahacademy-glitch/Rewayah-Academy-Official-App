# Élèves adultes : besoins serveur (BR-1)

Chaque ligne est un besoin repéré pendant la vague. Rien n'est branché avant BR-1 (K-28). Chaque ligne suit le doc §17 : idempotence, audit, tests d'accès horizontal, revue sécurité séparée.

| Réf. | Étape | Besoin | Aujourd'hui en démonstration |
|---|---|---|---|
| EA-BR-01 | EA-1b | Coquille de l'élève adulte : savoir, depuis le serveur, si le compte est un élève adulte, titulaire d'un foyer ou second adulte (sans changer de rôle serveur : le rôle reste lu du jeton). | La démonstration `/demo/adulte` choisit la coquille et la vue (`vue=conjoint`, `titulaire=femme`). |
| EA-BR-02 | EA-1b | Situation du foyer rendue par le serveur (les 25 cas du doc §18), dont la date de fin de délai rendue telle quelle (F17). | `adulte_demo.dart` : états nommés, date fixe du 18 décembre 2026. |
| EA-BR-03 | EA-1b | Enfants du foyer d'un titulaire adulte lus par la même source que le Foyer du tuteur. | `surchargesDemoTuteur(eleves: …)` avec Aïcha et Oumar Diallo. |
