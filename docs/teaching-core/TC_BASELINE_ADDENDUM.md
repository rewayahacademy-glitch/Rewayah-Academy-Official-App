# ADDENDUM DE BASELINE — lis ceci AVANT les six documents de `D:\RA_TC\shared\`

**Daté du 20/09/2026, 05:45. Il prévaut sur toute mention de `550e605` dans les documents d'Agent 0.**

## Ce qui a changé

Les six documents de `D:\RA_TC\shared\` ont été rédigés contre la baseline `550e605`, pendant que le
**chantier enseignant** travaillait encore, non commité, dans le dépôt principal.

Ce chantier est maintenant **terminé, intégré et commité**.

| | Avant | Maintenant |
|---|---|---|
| `TEACHING_BASELINE_SHA` | `550e605` | **`0071557`** |
| Chantier enseignant | en cours, 74 fichiers non commités | **livré** : 8 écrans `ENS-01`…`ENS-08`, 82 fichiers |
| Dépôt principal | dirty, zone de collision | **propre** |
| Statut d'Agent Z | bloqué, `TARGET_SHA` inconnu | `TARGET_SHA` = `0071557` |

Ton worktree est déjà positionné sur `0071557`. Le code enseignant y est **visible et lisible**.

## Ce que cela change pour toi, concrètement

1. **Tu lis désormais le vrai code enseignant.** Les répertoires que les documents d'Agent 0 décrivaient
   comme « invisibles depuis la baseline » existent maintenant sur disque :
   `lib/core/enseignant/`, `lib/features/fiche_groupe/`, `revue_groupe/`, `salle_enseignant/`,
   `cahier/`, `bienvenue_enseignant/`. **Lis-les. Réutilise-les. Ne les modifie jamais.**
   L'interdiction de les recréer devient une interdiction de les toucher : ils sont livrés et testés.

2. **La phase de réconciliation d'Agent Z disparaît.** Tu construis directement au-dessus du code final.
   Il n'y aura pas de « rebase surprise » : ce que tu vois est ce qui sera intégré.

3. **Les migrations `0025` à `0029` existent.** La prochaine libre est `0030`.
   L'interdiction de créer une migration en phase parallèle **reste entière** : toute demande SQL passe
   par la section « DEMANDE SQL » de ton `TC_CONTRACT_REQUEST_<X>.md`.

4. **Le reste des six documents reste valide.** L'ownership, les 28 préfixes `tc_*`, la preuve de
   disjonction, les contrats et le mécanisme de stub de port sont inchangés — ils ont été revérifiés
   contre `0071557` : aucun répertoire `tc_*`, aucun `docs/teaching-core/`, aucun `test/teaching_core/`
   n'existe dans le dépôt. Tes préfixes sont libres.

## Deux défauts connus de la baseline — ne les aggrave pas, ne les corrige pas

Ils sont hors de ta mission. Signale-les dans ton rapport si tu les croises, n'y touche pas.

- **`supabase/migrations/0029` est écrite mais PAS appliquée en base.** En l'état, `dossiers_en_attente()`
  livre nom et prénom de toute personne en attente de KYC à un appelant **anonyme**.
- **`test/.../catalogue_galerie_test` est rouge.** Conséquence directe pour toi : **aucun composant
  nouveau ne peut entrer dans `lib/core/widgets/`**. Ce répertoire t'est de toute façon interdit ;
  place tes composants dans ton propre répertoire possédé.

## Rappel de la règle qui n'a pas changé

Tu ne travailles **que** dans ton worktree `D:\RA_TC\<lettre>`.
Tu ne poses jamais le cwd, ni n'écris, dans `D:\RA _APP\RA -OFFICIAL-APP`.
