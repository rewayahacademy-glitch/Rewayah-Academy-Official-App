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

## A-4 (25/09, LA-2) : test clavier de l'inscription a adapter

- **Fichier** : `test/accessibilite/clavier_test.dart:43-51` (COORD, tests transverses).
- **Constat** : l'inscription est passee en etapes routees (`ui/tuteur-v1-a` @ df8c97c) ; `/inscription` montre l'etape d'usage (deux cartes, plus de carte roleTuteur). Le test tape `t.inscription.roleTuteur` puis attend la page identite : il echoue.
- **Besoin** : monter `IdentiteEtape` (`lib/features/inscription/etapes/identite_etape.dart`) avec un brouillon dont l'usage est choisi (`brouillonInscriptionProvider`) sous `hoteRoutant`, ou taper `Key('inscription-usage-moi')` puis Continuer ; les champs portent `Key('inscription-prenom')` et `Key('inscription-nom')`.
- **Contournement** : aucun cote lot A (fichier COORD) ; le test reste rouge sur la branche du lot A.

Signature : Poste B, executant LA-2.

## A-4 precisee (25/09, apres fusion de ui/tuteur-v1 @ 1cbc760 dans ui/tuteur-v1-a @ 384211d)

- Toujours rouge : `test/accessibilite/clavier_test.dart:43-51` tape `t.inscription.roleTuteur` (texte absent). Cause dans le test COORD, pas dans le lot A.
- Les cartes d'usage passent desormais par `ChoiceCardGroup` : plus de `Key('inscription-usage-moi')`. Correction voulue : monter les routes du parcours sous `hoteRoutant` (les etapes lisent `GoRouterState.of`, `hote` seul ne suffit pas), taper `find.text(t.inscription.usage.moiTitre)` puis `find.text(t.commun.continuer)` ; champs `Key('inscription-prenom')` et `Key('inscription-nom')` inchanges (modele : `test/features/inscription_test.dart`, `_monter`).

## A-5 (25/09, migration LA-2 vers les composants partages)

- **Fichiers** : `lib/core/widgets/page_etape.dart`, `lib/core/widgets/choice_card_group.dart` (COORD).
- **Besoin 1** : `PageEtape.onRetour` facultatif (nul = pas de disque, rangee gardee). Aujourd'hui requis : sur la premiere etape et une fois le profil cree (actualisation en echec), l'inscription n'a pas d'etape precedente ; le disque sort alors du parcours par la deconnexion (`inscription_page.dart`, `CoquilleEtape`), ce qui double le lien آ« Se deconnecter آ».
- **Besoin 2** : une disposition cote a cote de `ChoiceCardGroup` (cartes centrees, icone au-dessus du titre, radio en haut a droite) pour le genre (`onboarding Mble d.png`) ; en attendant, cartes empilees dans `genre_etape.dart`.
- **Besoin 3 (confort de test)** : une cle par option (`OptionChoix.cle`) ; les tests tapent aujourd'hui le libelle.
- **Contournement** : aucun composant local ; seulement les ecarts ci-dessus.

Signature : Poste B, LA-F2.

## Reponse du coordinateur (25/09 07:50, session B-2026-09-25-coord, LA-C1) : ui/tuteur-v1-a @ cba5263

- **A-1 fait** : `deciderRedirection` envoie la racine `/` sans session vers `/bienvenue` ; une route protegee sans session va toujours a `/connexion?retour=`. `destinationAutorisee` (pages introuvable/acces refuse, action « Se connecter ») garde `/connexion`, choix explicite commente dans `etats_routeur.dart`. Tests `redirection_test.dart` ajustes.
- **A-3 (1) fait** : `portConsentementsProvider` rend `ref.watch(consentementsLotAProvider)` ; `consentement_observation_page.dart` et `accordsTitulaireProvider` lisent le port ; les tests surchargent toujours `consentementsLotAProvider`. `ports_capacites_test.dart` mesure desormais `ConsentementsIndisponibles` en direct. **A-3 (2)** (ligne « Consentements » / `InviteConsentementObservation` dans le Compte) : **a faire a l'integration du lot E** (fichier du lot E).
- **A-4 fait** : `clavier_test.dart` monte les routes inscription/usage/identite sous `hoteRoutant`, tape `usage.moiTitre` puis Continuer, vise `inscription-prenom` / `inscription-nom`. Vert.
- **A-5.1 fait** : `PageEtape.onRetour` / `RangeeEtape.onRetour` facultatifs (nul = pas de disque, rangee gardee). `CoquilleEtape` passe `onRetour` tel quel : premiere etape et profil cree sans disque, sortie par « Se deconnecter ». Test ajoute (premiere etape) ; test « profil cree » mis a jour.
- **A-5.3 fait** : `OptionChoix.cle` (Key?) posee sur la carte.
- **A-5.2** (genre cote a cote) : non traite, reste ouvert.
- Usages lots B/D de `PageEtape`/`ChoiceCardGroup` inchanges (parametres optionnels). `analyze --fatal-infos` : 0 ; tests accessibilite/router/capacites/widgets/features verts sous verrou.

## A-5.2 (LA-C2, 25/09) : icone femme
La maquette 'onboarding Mble d' montre une silhouette feminine pour Femme. Aucune icone de ce type dans lib/core/icons/app_icons.dart : les deux cartes utilisent AppIcons.profil. Ressource a fournir (glyphe Phosphor + entree AppIcons) si le directeur la veut.

