# SITE 06 | Reprise du 9 octobre

Statut : prototype local corrigé dans le worktree `codex/site-public-2026-10-08`. Aucune publication, fusion, migration ni vérification de politique Finance en production.

## Inventaire des médias retenus

| Section | Source fournie | Destination | Statut |
|---|---|---|---|
| Header | `RA logo SVG/RA symbole full color.svg` | `site-public/assets/symbole-white.svg` | Tracés SVG officiels conservés ; seuls les `fill` violets passent en blanc sur fond sombre. |
| Footer | `RA logo SVG/RA logo horizontal.svg` | `site-public/assets/logo-horizontal-white.svg` | Tracés SVG officiels conservés ; variante blanche. |
| Accueil | `REWAYAH_ASSETS_PERSONNES_2026-10-09/hero-enfant-cours.png` | `site-public/assets/hero-enfant-cours.png` | Scène autonome transparente. |
| Cours | `REWAYAH_ASSETS_PERSONNES_2026-10-09/enseignant-portrait.png` | `site-public/assets/enseignant-portrait.png` | Portrait autonome transparent. |
| Suivi | `REWAYAH_ASSETS_PERSONNES_2026-10-09/suivi-parent-tablette.png` | `site-public/assets/suivi-parent-tablette.png` | Scène autonome transparente. |

Les PNG `exec-...` sont des références de composition seulement. Aucun texte, tarif, logo ou élément interactif n'est prélevé dans ces images. Les anciennes captures et les essais historiques ne sont pas utilisés comme médias de page.

## Résultat local

- La landing utilise un fond continu `#1A1A25`, le symbole seul dans le header, le logo complet dans le footer et un petit nom « Rewayah Academy » dans le hero.
- Les sections suivent le storyboard ; textes, actions, étapes et fragments illustratifs sont en HTML. Les personnes proviennent du pack transparent autonome.
- La date de constitution est retirée des textes publics et des mentions en préparation. Seule l'ancienneté d'enseignement depuis le 1er mai 2024 est affichée.
- Un bouton « Simuler mon tarif » ouvre un dialog avec validation de la composition. Le résultat reste indisponible : aucun moteur canonique de simulation, endpoint public ou publication tarifaire effective n'a été trouvé dans le checkout. Aucun montant n'est calculé ou codé en dur côté site.
- Les 17 routes de l'aperçu restent `noindex`. Les pages contractuelles bloquées restent des documents de préparation, sans publication autorisée.

## Preuves et limites

- `python -m unittest site-public/tests/test_build_site_qa.py` : 9 tests OK le 9 octobre.
- Navigateur Chrome local via DevTools : captures `captures/site-final-390.png` et `captures/site-final-1440.png`. À 390 px, `innerWidth=390` et `scrollWidth=390` ; à 1440 px, `innerWidth=1440` et `scrollWidth=1425` (barre de défilement). Cela vérifie le premier écran, pas chaque section ni l'accessibilité complète.
- La simulation complète de la section 6.1, les tarifs et exemples mis à jour depuis l'admin, les tests d'effet différé et de changement de remise restent **BLOQUÉS** par l'absence du service Finance public et de la politique publiée. Le checkout du site n'a pas de module de calcul Finance. Dans le worktree séparé `D:\RA_TUTEUR\finance`, `lib/core/capacites/port_paiements_foyer.dart` annonce une source de paiement encore provisoire et `lib/features/foyer/recharge_foyer.dart` lit des montants arrêtés par le serveur ; ce ne sont ni une API publique de simulation ni une politique administrée prête à publier. Le modal local ne doit pas être présenté comme un calcul fonctionnel.
- Captures anonymisées réelles de Flutter, projection publique des horaires, disponibilité des contacts, droit au siège et textes contractuels finaux restent à vérifier avant publication. Aucun test de déploiement ou de fournisseur n'a été effectué.
