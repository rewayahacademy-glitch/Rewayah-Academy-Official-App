# CAP-29 · Pack canonique unique · Révision 1.1

**Référence active unique :** `REWAYAH_CAP29_BIBLIOTHEQUE_HANDOFF_CANONIQUE_V1.md` (révisée en place). Aucune spécification CAP-29 concurrente.

## Contenu

- Document canonique, règles métier, IA, droits, R2, frontend/backend, 20 scénarios de recette, prompt pour Claude §10.
- 4 PNG **high-fi candidats à validation** : M01 Catalogue Admin desktop, M02 fiche/version desktop, M03 revue/publication desktop, M04 import mobile.
- Les 4 mêmes rendus en HTML autonome et la feuille CSS comme références pour inspection ; **aucun code HTML à intégrer à Flutter**.
- Planche `APERÇU_HIGH_FI.png` et `MANIFEST.json` (dimensions et SHA-256).

## Priorité et règles de transmission

La hiérarchie et les états sont spécifiés ; le directeur conserve la validation visuelle finale des quatre maquettes. Les captures sont **statiques, basées sur des données synthétiques, non issues de Flutter**. Les high-fi/tokens et composants déjà validés du produit priment sur tout conflit.

**Décision de stockage : Cloudflare R2 exclusivement pour les nouveaux supports et preuves**, domaine existant `priveApplicatif` sur le système Supabase ; secrets déjà configurés en Supabase **PRODUCTION**. Ne jamais demander/afficher leurs valeurs, créer un seau, modifier la production sans feu vert. STAGING doit être vérifié indépendamment.

Claude exécute directement le §10 du canonique, réalise son éventuelle vérification interne courte et poursuit l'implémentation, sans demander un rapport d'audit au directeur.

**Aucune publication ni modification du dépôt, du backend ou des buckets n'a été effectuée par la création de ce pack.**
