# Backend — Supabase

Avant de modifier une migration, une policy RLS, une fonction ou un trigger, lis `docs/architecture/etape-0-1-fondations.md`. Il contient le dictionnaire de données complet, les contraintes exigées et les scénarios de test d'acceptation qui définissent quand une modification est correcte.

Si le point qui t'occupe est une décision déjà prise plutôt qu'une spécification de schéma, vérifie `docs/architecture/decisions.md` avant d'inventer une solution : la réponse y est peut-être déjà, avec sa justification.

Ne lis pas `docs/produit/parcours-utilisateurs.md` pour une tâche purement backend, sauf si tu as besoin de comprendre ce qu'un écran affiche pour construire l'API qui l'alimente.

## Rappels non négociables, valables pour tout fichier de ce dossier

- RLS activée sur toutes les tables, sans exception.
- Toute fonction `SECURITY DEFINER` fixe `search_path` et qualifie chaque objet.
- Le rôle et le foyer se lisent depuis le JWT, jamais par une sous-requête sur `profiles`.
- L'argent est un entier en unité mineure, jamais un flottant.
- `audit_logs` est append-only : aucune fonction applicative n'a le droit d'y écrire une modification ou une suppression.
