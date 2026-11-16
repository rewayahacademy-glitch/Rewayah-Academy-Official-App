# Cahier BE-S1 : les lectures du serveur (lots BE-0b serveur et BE-1a)

Zone : `supabase/migrations` (plage `20261128100000` à `20261128100900`), `supabase/tests`
(un scénario `scenarios_be_s1.sql`), et les adaptateurs Dart `*_supabase.dart` et ports des
candidatures de la direction dans `lib/core/candidature`. Aucun écran.

À lire : `supabase/CLAUDE.md` ; `20261021200000_cand_l1_socle_candidatures.sql` (lignes 163-290
et 830-950) ; la dernière version de la fonction qui liste les candidatures de la direction
(chercher les clés `competenceDomaine` et `genre`) ; `lib/core/candidature/modele_questions.dart:124-212`
(réponses collectées) ; `modeles_candidatures_direction.dart`.

## À faire

1. **Historique lisible.** `historique_candidature` renvoie en plus, par événement : `details`
   (le contenu utile déjà stocké : contrôle, valeur avant et après, cause, pays avant et
   après) et, pour un événement « responsable », le nom affichable du responsable. Jamais de
   contact ni de pièce dans `details`. Le modèle Dart lit ces champs s'ils sont là.
2. **Nom du responsable** dans la lecture du dossier (le dossier n'en dit aujourd'hui que
   « désigné » ou « aucun »).
3. **Voisins.** Nouvelle fonction de lecture `voisins_candidature(p_reference, p_filtre, p_tri)` :
   renvoie `precedent`, `suivant` (références), `rang`, `total`, dans **exactement** le même
   filtre, le même tri et la même portée (côté, super-admin) que la liste. Port Dart et adaptateur.
4. **Filtres sur les réponses**, ajoutés à la liste : `ijaza` (présentable oui ou non),
   `langueExplication`, `riwaya`, `public`, `jours` (un ou plusieurs jours disponibles),
   `heureMin` et `heureMax` (dans le fuseau du candidat), `joursMin` (nombre de jours
   disponibles au moins). Clé inconnue : ignorée comme aujourd'hui.
5. **Filtres de file** : `pieceEnAttente` (une pièce déposée attend la direction),
   `responsable` (`moi`, `aucun`, ou un identifiant).
6. Scénario SQL : chaque filtre, les voisins au début, au milieu, à la fin, hors portée
   (l'autre côté pour une direction qui n'est pas super-admin : rien ne fuit).

## Interdit

Toucher à la machine à états (`candidature_gestes_regles`), aux gestes, aux politiques RLS
existantes. Ajouter un index sans le justifier dans l'en-tête (la base est sous charge :
`docs/current/STRATEGIE-BASE-ECONOME-2026-11-15.md` s'il est présent).

Phrase à rendre vraie : « Le serveur sait dire quel dossier vient après celui-ci dans ma
file, et trouver les personnes avec ijaza libres le soir quatre jours. »
