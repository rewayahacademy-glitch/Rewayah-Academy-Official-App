# Supports et tableau : questions vraiment bloquantes

Relu contre `DECISIONS_DELEGUEES_2026-10-02.md`, K-53 et K-61 : rien de déjà tranché n'est reposé. Le reste (textes, contradictions mineures des planches) est réglé dans `00_REPRISE.md` §5 et §6 selon le plan et les décisions récentes.

## Q1 (directeur) — Le panneau « Commandes » : deux onglets ou une liste ?

- **Question** : vos images montrent deux onglets « Support » et « Outils », votre plan écrit une seule liste avec la Bibliothèque en premier et un bouton « Écrire » qui ouvre les outils : lequel gardez-vous ?
- **Choix recommandé** : les deux onglets de vos images (« Support » puis « Outils »), avec la Bibliothèque en tête de l'onglet Support, « Pointeur » en tête de l'onglet Outils et « Terminer » dans la petite palette du téléphone.
- **Bloque** : TB-4 (et la structure de TB-7b). TB-1a, TB-F, TB-1b, TB-2 et TB-3 avancent sans attendre.

## Q2 (orchestrateur) — Réunir `ui/accessibilite-v1` dans la branche du chantier ?

- **Question** : peut-on fusionner `ui/accessibilite-v1` dans `ui/supports-tableau-v1` dès sa création, pour réutiliser les commandes qui se masquent et reviennent au toucher (MA-CMD-1) ?
- **Choix recommandé** : oui, en étape TB-F, sur la seule branche du chantier (~~12 conflits connus~~ sans objet depuis INTEG-RC-1, compte corrigé : 14 ; jamais dans `main`) ; sinon TB-2 devrait recopier ce composant, ce que K-10 interdit.
- **Bloque** : TB-F, donc TB-1b et toutes les étapes d'écran.
