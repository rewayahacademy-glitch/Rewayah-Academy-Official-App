# UX_REVIEW_SNT : « Séances reportées » et « Fixer la nouvelle date » (03/11/2026)

DESIGN-GOV-2026-09-26 §4. Ce relevé ne change ni une règle métier ni un état serveur
(§4.3) : il dit où le geste est posé et pourquoi. Captures : ce dossier, 1440 x 900 et
390 x 844, clair et sombre (robot `tool/e2e/snt.mjs`, banc local).

| Règle | Source | Date | Conclusion | Modification |
| :--- | :--- | :--- | :--- | :--- |
| Une alerte ou un geste attendu va en tête | `lib/CLAUDE.md` (règle déduite des remarques du directeur) | 03/11/2026 | La section est le premier bloc du planning, avant la navigation de semaine ; elle n'existe que s'il y a une séance à dater. | Section absente quand la liste est vide ou sans port. |
| La liste est la page (aucun cadre de hauteur fixe) | `DECISION-DEFILEMENT-2026-11-01.md` | 03/11/2026 | La section est une `CarteLignes` dans le flux de la page ; une seule barre de défilement. | Aucune. |
| K-55, contenus liés en une carte à lignes fines | `lib/CLAUDE.md` | 03/11/2026 | Une ligne `SettingRow` par séance dans une seule `CarteLignes`. | Aucune. |
| K-57, déduit > choisi > saisi | `lib/CLAUDE.md` | 03/11/2026 | Classe, enseignant et durée déduits (écrits en tête de feuille) ; jour au calendrier (`ChampDate`) et heure au menu (`MenuFiltre`, par demi-heure) ; rien n'est saisi. | Aucune. |
| K-56, un seul bouton plein | `lib/CLAUDE.md` ; `verifierUnSeulBoutonPlein` | 03/11/2026 | « Fixer cette date » en bas de feuille (`BasDeFeuille`), seul bouton plein ; testé à 320 px texte x2 et à 1440 px sombre. | Aucune. |
| K-59, un refus dit ce qui bloque et quoi faire | `lib/CLAUDE.md` | 03/11/2026 | Chevauchement (avec la classe et l'heure en conflit, DETAIL de C1), date passée, date déjà fixée, classe close, autre compte : une phrase chacun, avec la suite. | Aucune. |
| Libellé non ambigu (qui, quoi) | `lib/CLAUDE.md`, `libelle-ambigu` | 03/11/2026 | La ligne dit « Séance reportée de la classe X », la séance prévue, l'enseignant et « Fixer la nouvelle date ». | Aucune. |
| Mots | `mots-rewayah` (ligne ajoutée le 03/11), `programme-rewayah` §0 | 03/11/2026 | « Séance reportée », « Nouvelle date à venir », « Fixer la nouvelle date » ; jamais « rattrapage » ni « remboursé » à l'écran (vérifié par le robot). | Aucune. |
| Fuseau | WCAG 2.2 3.3.2 (étiquettes ou instructions) | 03/11/2026 | L'heure choisie est celle de l'appareil, et la feuille le dit (« À l'heure de cet appareil. »), comme le planning. | Aucune. |
