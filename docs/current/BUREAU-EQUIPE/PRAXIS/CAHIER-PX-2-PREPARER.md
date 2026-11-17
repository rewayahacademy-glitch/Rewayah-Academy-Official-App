# Cahier PX-2 : Praxis lit les dossiers et prépare (niveau B)

Écrit par le pilote le 17/11/2026, à 01 h 40 UTC. Agent : BE-PIECE. À lire d'abord : `SECURITE-PRAXIS.md` (R1 à R15,
§3, §7 jusqu'à AR-11), `ACCES-PRAXIS.md` §2 et §3 (domaines 4.2 et 4.13), `../CARTE-GESTES-DIRECTION.md`.

## 0. La phrase de recette

« Je demande à Praxis : “Qui attend un complément depuis plus de trois jours ?” Il me répond avec la liste, sans un
seul contact. Je lui dis : “Prépare les relances.” Il prépare, je vois les propositions dans l'application, je valide
d'un geste celles que je veux, et rien ne part sans mon geste. »

## 1. Ce que PX-2 ajoute

1. **Un réglage `donnees_reelles` dans `private.praxis_reglages`.**
   - Il est faux à l'installation. Seule `direction_praxis_regler`, en `aal2`, l'écrit.
   - Le directeur ne l'allume qu'après avoir publié la politique de confidentialité (AR-11).
   - Tant qu'il est faux, **tous les outils de PX-2 refusent** (cause `donnees_reelles_fermees`), et les outils de
     PX-1 restent limités au mode essai.
   - Scénario : faux, alors refus ; vrai, alors accès.
2. **`praxis_lire(cle, vue, filtre, limite)`, une vue prise dans une liste fermée côté serveur.**
   - `candidatures` : la file vue par la direction, avec par ligne : référence, prénom, côté, langue, étape, état,
     attente en jours, complément en cours, et les gestes servis (`gestes`, #573). Jamais de courriel, de téléphone,
     de pièce, de photo, de note d'entretien, de motif de refus ni de montant (R5). Le prénom est rendu dans
     `contenu_tiers`.
   - `demandes` : les demandes d'admission en attente, en compteurs et en étapes, sans contact.
   - Filtres fermés : étape, état, langue, attente minimale en jours. Pages de 50 au plus.
   - Côtés : ceux de la personne qui a émis la clé (AR-7 I2).
   - Les fonctions internes existantes sont lues avec un auteur explicite. Aucune copie de logique ; à défaut, une
     extraction par ancrage, comme dans 610000.
3. **`praxis_preparer(cle, geste, candidature, parametres, texte, cle_idempotence)`, au niveau B.**
   - Gestes permis, en liste fermée : `demander_complement` (pièces nommées dans la liste fermée du moteur), relance
     d'un complément, `planifier_entretien` (créneau proposé), `admettre_verifications`.
   - Il n'écrit qu'une **proposition** dans `private.praxis_propositions` : geste, dossier, paramètres, texte destiné
     à l'humain qui valide, statut (`proposee`, `validee`, `ecartee`, `expiree`), clé, émetteur, horodatages.
   - Il n'exécute **jamais** le geste. Le geste doit être servi pour cette ligne (`gestes` de #573), sinon le refus
     est `geste_non_servi`.
   - Plafond : 50 propositions ouvertes au plus, expiration au bout de 72 heures, clé d'idempotence.
4. **Les portes de la direction :**
   - `direction_praxis_propositions(filtre)` : lecture, direction valide ;
   - `direction_praxis_valider(proposition, version, cle)` : exécute le geste par la **porte publique existante**,
     sous l'identité de la personne qui valide, jamais sous celle de Praxis ; le moteur décide comme pour un geste
     fait à la main ;
   - `direction_praxis_ecarter(proposition, motif, cle)`.
   - Une validation en lot reprend le mécanisme existant (`gestesGroupables`).
5. **L'écran**, une PR à part : « Propositions de Praxis » dans le dossier et dans la liste (une pastille), avec
   « Valider », « Écarter » et la validation en lot.

## 2. Règles dures (en plus de SECURITE-PRAXIS)

- Aucun outil de PX-2 n'écrit dans une table de candidature. Seule la porte de la direction le fait, au moment de la
  validation, par la porte existante.
- R2 : la liste blanche exacte des fonctions `praxis_*` est mise à jour. R4 : la liste des couples (fonction, table
  écrite) aussi, avec un test qui couvre les appels indirects (AR-10).
- Les mineurs : les candidatures d'enseignants sont adultes. Les demandes d'admission d'enfants ne rendent que des
  compteurs (§3.6).
- Un essai à blanc reste interdit sur les données réelles tant que `donnees_reelles` est faux.

## 3. Scénarios obligatoires (rouges avant, verts après)

1. `donnees_reelles` faux : `praxis_lire` et `praxis_preparer` refusés.
2. Aucune réponse de `praxis_lire` ne contient un courriel, un téléphone, une pièce ou un montant (recherche des
   motifs).
3. Une clé d'une direction d'un côté ne lit que ce côté.
4. `praxis_preparer` n'écrit qu'une ligne dans `praxis_propositions` : 0 ligne écrite dans `candidatures` ni dans
   ses tables liées.
5. Un geste non servi pour la ligne est refusé (`geste_non_servi`).
6. La validation par une direction exécute le geste par la porte publique ; l'événement porte l'identité de cette
   direction.
7. Écarter une proposition, ou la laisser expirer, ne fait rien sur le dossier.
8. Le plafond et l'idempotence tiennent.
9. Une proposition sur un dossier qui a changé d'état depuis : la validation est refusée par le moteur, avec la
   phrase vraie.

## 4. Livraison

- **Migration 20261129660000 :** le serveur, avec ses scénarios et les listes AR-10 et R2 à jour.
- **Une PR serveur, puis une PR écran.** Le pilote relit contre SECURITE-PRAXIS ; une relecture indépendante est
  faite avant la fusion (R15).
