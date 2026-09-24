# Demandes du lot A (Admission) au coordinateur

## A-1 (25/09, LA-1) : bascule du visiteur deconnecte vers `/bienvenue`

- **Fichiers** : `lib/core/router/etats_routeur.dart:31` (`PorteAcces.deconnecte => Routes.connexion`) et le commentaire `lib/core/router/app_router.dart:195-198` (COORD).
- **Constat** : l'ecran `/bienvenue` est livre (plus de STUB, `ui/tuteur-v1-a` @ fbb603d, `lib/features/bienvenue/bienvenue_page.dart`). Le commentaire du routeur annonce la bascule « suivra la livraison de l'ecran par le lot A ».
- **Besoin** : le visiteur sans session qui arrive sur la racine va a `/bienvenue` (premiere visite), et une route protegee demandee sans session continue d'aller a `/connexion` avec son chemin de retour (`redirection.dart`, inchange).
- **Signature voulue** : `PorteAcces.deconnecte => Routes.bienvenue` dans la racine seulement (pas dans la redirection des routes protegees), tests `test/router/redirection_test.dart` ajustes.
- **Contournement en place** : `/connexion` porte un lien discret « Decouvrir Rewayah Academy » vers `/bienvenue` (`connexion_page.dart`, cle `connexion-decouvrir`) ; `/bienvenue` mene a `/connexion` par « Commencer » et « J'ai deja un compte ». Aucune impasse.

## A-2 (25/09, LA-1) : rappel de B-3 pour l'inscription par etapes

- Le lot A (sous-paquet A-2) a le meme besoin que B-3 (`demandes/B.md`) : rangee d'etape sans actions de coquille, choix avec description et option desactivee. Le lot A n'importera pas `CarteChoixFoyer` (fichier du lot B, `00_OWNERSHIP.md` §3) : contournement local prive dans ses fichiers d'etape, a migrer vers le composant partage.

## A-3 (25/09, LA-3) : brancher le port des consentements et placer l'invite

- **Fichiers** : `lib/core/capacites/port_consentements.dart` (`portConsentementsProvider` rend `ConsentementsIndisponibles`, COORD) ; `lib/features/compte/compte_tuteur_page.dart` (lot E).
- **Constat** : l'adaptateur reel est livre (`ui/tuteur-v1-a` @ 9a5c3a6, `lib/core/capacites/consentements_supabase.dart`, `ConsentementsSupabase` + `consentementsLotAProvider`) ; aucun bouton hors routeur ne mene a `/tuteur/compte/consentements` (seul le routeur la connait).
- **Besoin** : (1) `portConsentementsProvider` rend `ref.watch(consentementsLotAProvider)` ; (2) le Compte tuteur (lot E) pose `InviteConsentementObservation()` (`lib/features/consentements/consentement_observation_page.dart`, s'affiche seulement si la version `2026-09-obs` n'est pas signee) et/ou une ligne « Consentements » vers `Routes.tuteurCompteConsentements`.
- **Contournement en place** : les ecrans du lot A lisent `consentementsLotAProvider` directement ; tant que (2) n'est pas fait, la page n'est atteignable que par URL (critere « fait » non rempli pour elle).
