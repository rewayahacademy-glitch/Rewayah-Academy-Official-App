# Cahier BE-2a-2 : inviter un associé (une personne sans compte), avec un rôle dédié

Écrit par le pilote le 16/11/2026, à 21 h 15 UTC. Il suit `CAHIER-BE-2A-MISSION.md` (BE-2a-1, PR #565). Arbitrage du
16/11 à 20 h 45 : le rôle `controller` est écarté, car il ouvre aux familles des lectures que l'associé ne doit pas
avoir. Plage de migrations : `202611294…` (430000 et 460000 sont libres ; au-delà, réserver une plage dans
`REGISTRE-LOTS.md`).

## 0. La phrase de recette (directeur)

« J'invite un ami par e-mail, je coche cinq gestes sur les candidatures en anglais ; il ne voit que cela ; je retire
la mission, il ne voit plus rien et son compte n'a pas changé. »

## 1. Faits relevés (production, 16/11, 21 h 10 UTC)

- **Les rôles** : `admin`, `accountant`, `controller`, `teacher`, `guardian`, `student`. Aucun compte `controller` ni
  `accountant` n'existe.
- **206 politiques RLS**, dont **aucune** n'est écrite par exclusion (`app_role() <> …`). Un rôle nouveau n'hérite donc
  d'aucune politique par défaut.
- **2 politiques SELECT** sont ouvertes à tout `authenticated` (`qual` vide ou `true`) : un associé les verrait.
- **19 migrations** contiennent des tests de rôle par exclusion (`<>`, `!=`, `NOT IN`) dans des fonctions : chacune
  doit être relue, car un rôle nouveau y passerait.
- **Le modèle d'invitation** à suivre : `20261017160200_bf1_03_invitation_comptable.sql` (`inviter_comptable`,
  `inscrire_comptable_invite`).
- **Le crochet de jeton** (`custom_access_token_hook`) ne doit jamais rendre `null` (`supabase/CLAUDE.md`) : le nouveau
  rôle doit y être traité comme les autres.

## 2. Ce que fait BE-2a-2

1. **Le rôle `associe`**, ajouté à l'énumération `app_role`. `ALTER TYPE … ADD VALUE` ne peut pas servir dans la même
   transaction que son ajout : le rôle va donc dans une migration à lui, et ce qui l'utilise dans la suivante.
2. **Le crochet de jeton** pose le rôle `associe` sans foyer. Un scénario prouve que le jeton n'est jamais `null`.
3. **L'invitation**, sur le modèle comptable :
   - `inviter_associe(courriel, nom, cle)` est réservée à la direction en double authentification (`aal2`), comme
     `creer_mission` ;
   - `inscrire_associe_invite(jeton, …)` crée le compte `associe` actif, sans aucun droit ;
   - `revoquer_invitation_associe(id, motif, cle)` annule une invitation.
   - Le courriel d'invitation passe par le circuit `courriels-envoi` existant. Le texte se demande au pilote, avec la
     compétence `mots-rewayah`.
4. **Audit, écrit dans la PR, table par table et fonction par fonction** :
   - les 2 politiques SELECT ouvertes à `authenticated` : laquelle, ce qu'elle expose, et le correctif si elle expose
     une donnée de personne (le correctif fait partie du lot) ;
   - les 19 migrations à tests de rôle par exclusion : la fonction en vigueur en production, et ce que `associe` y
     obtient. Tout accès non voulu se ferme dans le lot.
5. **Ce que voit un associé sans mission** : rien d'autre que son accueil. Un associé avec une mission voit
   exactement ce que BE-2a-1 lui ouvre.

## 3. Scénarios obligatoires (`supabase/tests/scenarios_be2a2_associe.sql`)

1. Un compte `associe` sans mission : 0 ligne lisible sur chaque table de `public` qui contient des personnes. La
   liste des tables relues est dans le scénario, en exigence positive.
2. Un associé avec une mission « lire » sur les dossiers en anglais : il ne voit que ces dossiers.
3. La mission retirée : 0 ligne, et le compte (rôle, statut) est inchangé.
4. L'invitation : seule la direction peut inviter ; une invitation est révocable ; un jeton ne sert qu'une fois.
5. Le crochet de jeton pour `associe` n'est jamais `null`.
6. `anon` n'a aucun droit sur les portes nouvelles.

## 4. L'écran

Il est hors de ce lot et vient en BE-2b : l'invitation et les missions dans l'écran « Équipe », et l'accueil de
l'associé (sa liste de dossiers).

## 5. Livraison

Une PR en brouillon, `claude/be2a2-associe`, avec deux migrations au moins (le rôle, puis le reste), les scénarios,
l'audit dans la PR et la ligne dans `REGISTRE-LOTS.md`. Le pilote relit, fusionne et installe. BE-2a-1 doit être
installé avant.
