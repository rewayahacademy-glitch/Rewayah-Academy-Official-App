# Prospection v2 (27/11/2026) : lettre courte, image, envoi par la file

- `destinataires.json` : 357 adresses de la feuille, rapprochées avec la base et Gmail le 27/11
  (`nouvelle`, `relance_possible`, `exclu` à vie avec motif). Relevé en lecture seule.
- `lettres.py` : 4 variantes par langue (fr, en, ar) et 2 relances ; `plan.py` : plan d'une journée
  (paquets aléatoires, heures ouvrables du destinataire, 20 % sans image) ; `page.py` : la page de validation.
- Rien n'est parti : en attente du « vas-y » du directeur (page Artifact « Prospection, nouvelle lettre »).
- Envoi prévu par `courriel_enfiler('nouvelles', 'message_libre', ...)` (jeton de désinscription), puis
  `langue` et `prochaine_tentative` posés ligne par ligne ; les 79 lignes `direction` en attente au 31/12 seront remplacées.
- Constats : vague du 23-26/11 = 11 rebonds sur 200 (5,5 %), lettres en français traduites, sans lien de
  désinscription ; aucune relance J+3 visible dans Gmail pour la vague du 22/11.
