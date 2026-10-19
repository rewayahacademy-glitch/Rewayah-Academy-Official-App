# Contrat : le site public lit les tarifs dans la base (18/10/2026)

Ordre du directeur, 18/10/2026 : le site public doit lire les tarifs dans la base,
sans ouvrir de brèche. `site-public/` reste une zone gardée par le garde-fou
(`.claude/hooks/zones_apres.sh`) : ce dossier n'y est pas modifié. Ce contrat et le
module prêt `bloc_tarifs.py` servent à l'agent qui finira le site.

## La seule porte : `public.tarifs_publics()`

- Migration `supabase/migrations/20261018140000_pub_tarifs_publics.sql`, scénario
  `supabase/tests/scenarios_pub_tarifs_publics.sql`.
- Sans paramètre, STABLE, SECURITY DEFINER, `search_path` vide. Rend
  `{ "courante": {...}, "suivante": {...} | null }` : la politique en vigueur aujourd'hui
  et, si elle existe, la version déjà publiée qui prend effet plus tard (avec sa date).
- Liste blanche de clés : version, dateEffet, devise, horsTaxes, ageAdulte, prix enfant
  et adulte (unité mineure), essai, remises du foyer, prépaiement, parrainage, bourse
  (pourcentage et durée), plafond de cumul, taille des classes.
- Jamais : paie des enseignants, marges, budgets, relances, auteur, familles.
- Droits : EXECUTE à `anon` et `authenticated` sur cette seule fonction. Aucune table
  n'est ouverte. Tout ce qu'elle rend est déjà public par nature.

## Comment le site doit l'utiliser

1. **Au moment du build seulement**, jamais depuis le navigateur. Le HTML produit est
   statique et ne contient ni URL Supabase ni clé.
2. `POST {SUPABASE_URL}/rest/v1/rpc/tarifs_publics`, en-têtes `apikey` (clé publiable),
   délai court, sans suivre de redirection.
3. Valider le schéma reçu : clés exactes, types, bornes ; refuser toute clé inconnue.
   Échapper chaque valeur en HTML.
4. En cas d'absence de variables ou d'erreur : repli sur
   `docs/current/tarifs-2026-10-18.json` et message clair dans la sortie du build.
5. Avant le 1er novembre 2026, `courante` est la v1 et `suivante` la v2 (55 $ / 65 $) :
   afficher la `suivante` avec sa date d'effet.
6. Variables à fournir au build : `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`
   (ou `SUPABASE_ANON_KEY`). Le workflow de déploiement (`.github/`, zone gardée)
   n'appelle pas encore `build_site.py` : à brancher par le directeur ou sur son ordre.

## Module prêt

`docs/orchestration/site-public/bloc_tarifs.py` : appel `urllib` sans redirection,
validation stricte, repli JSON, formats en français, sections générées (grille, remises,
famille, classes), données du simulateur. À brancher dans `build_site.py`
(`render_page`, `render_section`, bloc tarifs de l'accueil, page cours, page
`/fr/tarifs` de `pages.json`), avec des tests Python dans `site-public/tests/`.
