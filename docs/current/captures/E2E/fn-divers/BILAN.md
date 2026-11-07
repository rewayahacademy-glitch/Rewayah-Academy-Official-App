# Lot 13 FN-DIVERS (rang 21 de PLAN-LOTS), bilan du 06/11/2026

Branche `claude/fn-divers`. Aucune migration. Rien n'est prouvé par le directeur en production.

## Faux, ouvert ou non prouvé (en premier)

1. **FN-101 : faille ouverte, lot suivant (garde-cap, 06/11 22:46).** L'application dépose la pièce
   directement dans le seau Supabase `kyc` (`ServiceDossierSupabase.deposerPiece`) puis insère la ligne
   `kyc_documents` elle-même : aucune pièce ne passe par `piece-identite-confirme`, donc le contrôle
   serveur des 16 premiers octets ne joue pas pour l'application. Le contrôle ajouté par ce lot est
   côté client : il se contourne. Le WebP est accepté par le seau mais inconnu du contrôle serveur.
2. **FN-111 partiel.** La page « Se connecter » dit maintenant que le lien a été ouvert ailleurs, et
   quoi faire. Les réponses du questionnaire restent perdues sur l'autre appareil (il faudrait un lien
   qui marche partout, `token_hash`, ou des réponses portées par le lien : réglage Supabase, hors lot).
3. **FN-027 partiel.** Carte de l'Accueil de la famille au lot suivant, après le lot 12
   (`bloc_seance.dart` est à lui). Aucune heure réelle de fin : le serveur ne la rend pas ;
   « Séance terminée à {heure} » n'est pas fait.
4. La page du contrat (`recrutement.signature`) reste en français en arabe, sauf le bloc du nom,
   traduit par ce lot (défaut antérieur).
5. Défaut d'un composant partagé, transmis à l'agent 3 : l'aide (`explication`) de `ZoneSaisie` coupe
   les mots à 320 px en texte x2. Contourné ici par `TexteSansCoupure` sous le champ.
6. `synchro_salle.dart` (lot 11) avale encore ses erreurs (`onError` vides) : transmis au lot 11.

## Suite décidée pour FN-101 (garde-cap, 06/11 22:47 ; lancée par le pilote)

- Option B : une porte serveur (Edge « kyc-confirme » qui lit les 16 premiers octets avec la clé de
  service, ou RPC `SECURITY DEFINER` si le contenu est lisible côté base) est la seule à insérer dans
  `kyc_documents`.
- L'INSERT direct est retiré à `authenticated` (écriture de droits relue par le garde-cap et l'ancien
  garde-cap), migration au numéro suivant de la table.
- WebP retiré du sélecteur (`lib/core/dossier/selecteur_fichier.dart`), pas ajouté au serveur.
- Le filtre client `lib/core/dossier/contenu_piece.dart` reste.

## Fait (testé localement)

| Point | Ce qui change | Preuve locale |
| :--- | :--- | :--- |
| FN-111 | Bandeau en tête de « Se connecter » quand l'adresse porte un `?code=` sans clé de vérification sur cet appareil (`lib/features/connexion/lien_ailleurs.dart`) ; le code d'une invitation d'enseignant est exclu | Robot de la pile locale **vert** à 390 et 1440 (`robot/`) : vrai lien Mailpit demandé dans le navigateur A, ouvert dans B (bandeau) ; témoin : la même adresse ouvre la session dans A. Tests `test/features/connexion/lien_ailleurs_test.dart` |
| FN-101 | Un fichier dont les premiers octets ne correspondent pas à son type (texte nommé `.pdf`) est refusé avant l'envoi, avec la cause et quoi faire (`lib/core/dossier/contenu_piece.dart`) | Tests `test/core/dossier/contenu_piece_test.dart`, `test/features/dossier_test.dart` ; captures `fn101_*` |
| FN-102 | Le nom signé est celui du compte, montré en lecture seule (nouveau `PortSignatureContrat.nomDuCompte()`), `nom_compte_vide` traduit ; le serveur l'imposait déjà (20261108400000) | Tests `signature_contrat_page_test.dart`, `dossier_accords_test.dart` ; captures `fn102_*` |
| FN-027 | « Séance en direct · Reste {n} min » pendant la séance, « Temps prévu écoulé » au-delà, jamais négatif ; une seule source, `EmplacementEntree.pour` (Journée de l'enseignant, Accueil de l'adulte, Ma classe), le minuteur avance à la minute | Tests `journee_test.dart`, `emplacement_entree_test.dart` ; captures `fn027_*` |
| FN-018 | Déjà corrigé le 29/10 (`veille_supabase.dart` transmet `channelError` / `timedOut`, signalés à Sentry) | `test/core/fraicheur/veille_fraicheur_test.dart` |

Réutilisé : `BandeauAttention`, `ZoneSaisie`, `TexteSansCoupure`, `LibellesGroupe.tempsRestant`,
`EmplacementEntree`, la logique du contrôle serveur `contenu_piece.ts`, la pile `tool/e2e`.
Écarté : une ligne propre à la Journée (doublon de `EmplacementEntree`) ; une colonne d'heure de fin
réelle (pas de migration ce soir, garde-cap).

Captures : `fn111_*`, `fn101_*`, `fn102_*`, `fn027_*`, 390 et 1440, FR et AR (rendu de widgets,
`test/capture/fn_divers_capture_test.dart`) ; `robot/` (navigateur réel, pile locale).
