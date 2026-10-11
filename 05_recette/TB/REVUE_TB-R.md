# REVUE_TB-R : revue croisée adversariale du chantier « Supports et tableau »

Rédigée le 10/10/2026 par la session cloud 01KZyXbi, qui n'a écrit aucun code des étapes TB-1b à TB-11b ; ses
propres corrections du 10/10 (35fd3490..a5393f82) sont relues ici par des agents indépendants mais restent à
relire par une autre session (K-60.4).

- **Code** : dépôt `Rewayah-Academy-Official-App`, branche `claude/wizardly-babbage-lmhkog`, tête `7cea9cf1`.
- **Diff du lot** : `git diff 9cb57f17 35fd3490 -- lib test` (TB-1b à TB-11b, AR-SALLE-1, AR-TC-1, écrits par
  d'autres sessions).
- **Corrections du 10/10** : `git diff 35fd3490 a5393f82` (vérification et recette TB-12). Chaque constat qui
  les vise porte la mention **[10/10]**.
- **Références** :
  - plan `REWAYAH_PLAN_SUPPORTS_TABLEAU_V2.md` (§1 à §23, §22 en particulier) et ses maquettes ;
  - `18_supports_tableau/00_REPRISE.md` (§9, règles TB1 à TB30), `02_DECOUPAGE.md`, `UX_REVIEW_TB.md` ;
  - `consignes_revue.md` (K-40 = R1 à R21, K-42, K-43 = E1 à E20, K-54 à K-59), `LECONS_DES_ROLES.md` ;
  - `docs/current/DESIGN-GOV-2026-09-26.md` (§4 bis), `lib/CLAUDE.md` ;
  - `05_recette/TB/TB_RAPPORT.md` et `TB-BR.md` (les 23 défauts de la classe 3 ne sont pas recopiés ici) ;
  - fiches `db/etapes/TB-*.json` (écarts voulus et reste) ;
  - captures `docs/current/captures/TB-*/`.
- **Méthode** : huit axes (produit, responsive, accessibilité, géométrie, temps réel, règles, code, tests).
  Chaque constat a été repassé à un sceptique qui a tenté de le réfuter et a ajusté sa gravité. Les tests
  temporaires ont été créés sous `test/_revue_tmp/` puis supprimés ; `git status` est propre.

Rien n'a été corrigé par cette revue. Ce fichier est le seul écrit.

## Verrou

Suite complète sur `a5393f82` : +6941 ~3884, 0 échec ; analyze 0 ; jetons 39 ; revue 1609.

## Bilan

**7 majeurs, 36 mineurs, 16 notes.** 5 constats écartés.

Recommandation : le chantier ne passe pas à « vérifié » et rien n'est fusionné dans `main` avant TB-RC.

- Trois majeurs sont des défauts visibles aujourd'hui en démonstration : M2 (téléphone couché), M3 (bureau
  à ×2) et M4 (ordre de tabulation).
- M1 et M7 violent des textes ou des règles obligatoires (§12, K-58).
- M5 et M6 sont des défauts de fiabilité de l'encre. M6 est latent tant que BR-1 n'est pas branché, mais il
  doit être corrigé avant, car rien ne le détecte.
- Les mineurs ne bloquent personne. Plusieurs (m21 surtout) deviennent majeurs au branchement d'un dépôt réel
  et doivent être des conditions de BR-1.

## Majeurs

### M1. Les deux états de l'élève du §12 n'existent pas, et la démonstration fait croire qu'ils existent

Ce que le code fait :
- `lib/features/demo/seance_demo.dart:155-161` déclare `SituationTb.supportArrive` et
  `SituationTb.ressourceIndisponible` comme « États du §12 ». `demo_salle_page.dart:253-255` les met dans la
  liste de `/demo/salle`.
- `vueTb` (`seance_demo.dart:637-750`) et `etatBaseTb` (`:756-761`, branche `_ => EtatDemoSalle.repos`) ne les
  lisent jamais : ces deux situations rendent la salle au repos.
- `assets/i18n/fr.i18n.json` ne contient ni « Le support arrive… » ni « Le support ne s'affiche pas. ». On n'y
  trouve que les étiquettes de liste « Le support arrive » et « Ressource indisponible » (l. 501-502).
- `VueSeance` n'a aucun état de chargement ou d'indisponibilité du support présenté côté destinataire.
- `test/features/tb_recette/situations_tb_test.dart:210` ne vérifie que le filtrage par rôle.
- Aucun écart écrit : ni les fiches TB-*.json, ni TB_RAPPORT, ni TB-BR. `02_DECOUPAGE` ne confie le côté élève
  à aucune étape (TB-8 ne prend que le côté enseignant). `UX_REVIEW_TB.md:274` marque LIB-03 « conforme » sans
  distinguer l'élève.

Conséquence : quand l'enseignant présente un nouveau support, l'élève garde l'ancienne page sans marque
d'attente. Si le fichier ne se charge pas, rien ne le lui dit et rien ne propose Réessayer. En recette, le
directeur ouvre `tb=supportArrive` et `tb=ressourceIndisponible` et voit la salle ordinaire, sans que rien le
signale (TB23, 00_REPRISE §8). Le chargement réel n'existe pas avant BR-1, mais le texte obligatoire du §12
(« Ressource indisponible » côté élève, Réessayer sans quitter la séance) manque.

Attendu : un état du support présenté chez le destinataire (prêt, en chargement, indisponible) dans
`VueSeance`, avec les textes exacts du §12 sourcés dans `libelles_sources.json` et traduits, le dernier contenu
marqué « en attente », Réessayer sans couper l'audio ; les deux situations branchées dessus et un test qui lit
la phrase. À défaut, retirer les deux situations de la liste et écrire l'écart daté plus une ligne TB-BR.

Fusion : produit-1, regles-1.

### M2. Téléphone couché (844 × 390) : la page devient un timbre à ×1 et disparaît à ×2

Ce que le code fait :
- `lib/features/salle_seance/composition_salle.dart:58-62` : `gaucheTient = !telephone && largeur/facteurTexte
  >= 840`. La hauteur n'entre jamais dans la décision. `salle_seance.dart:906` : `_telephone = Gabarit.mobile`,
  donc la largeur seule. Rien n'emploie `shortestSide` ni l'orientation.
- À 844 de large, l'écran est traité en tablette : colonne Participants, tête bornée jusqu'à 55 % de la hauteur
  (`salle_seance.dart:1896-1905`, `TeteSalleBornee.part = 0.55`, l. 2267), rangée Élèves, surface,
  déclencheur, marge de la barre d'appel.
- Mesures (PED-03, vraies polices) : enseignant ×1, page 34 × 48 dp ; élève ×1, 20 × 28 ; enseignant ×2, page
  0 × 0 et « A RenderFlex overflowed by 62 pixels on the bottom » ; élève ×2, 0 × 0. Rendus :
  `scratchpad/revue_resp/revue_enseignant_844x390_x1.png` et `revue_enseignant_844x390_x2.png`.
- `composition_salle.dart` est nouveau dans le lot. Aucun écart écrit sur le téléphone en paysage (l'écart 12
  de TB-11a porte sur une tablette 1024 × 768).

Conséquence : un élève ou un enseignant qui tourne son téléphone pour mieux voir la page, geste courant avec un
mushaf, ne voit plus rien et ne peut plus annoter. En production, le débordement est rogné sans message. Cela
contredit le plan V2 l. 154 (« basculer les panneaux plutôt que comprimer ») et `03_DESIGN_SYSTEM_ET_UX.md:23`
(en paysage, utiliser la largeur sans réduire le texte du Coran).

Attendu : décider avec `shortestSide` (moins de 600 = téléphone) et un seuil de hauteur utile divisée par le
facteur de texte ; sous ce seuil, la tête compacte du focus (`_teteFocus`). Ajouter 844 × 390 ×1 et ×2 à la
matrice de captures, avec une assertion de taille minimale de la page (voir m5).

### M3. Bureau à texte ×2 : tête non bornée et bandes empilées, la page tombe à 61 × 86 dp à 1280 × 720

Ce constat confirme majeur le défaut grave n° 4 de TB_RAPPORT §d, l'étend à 1280 × 720 et en donne la cause.

Ce que le code fait :
- `salle_seance.dart:1894-1902` : sur `Gabarit.desktop`, `ChromeSeance` est rendu sans `TeteSalleBornee`, alors
  que la branche tablette (l. 1903-1913) est bornée. Même chose chez l'élève (`:261-273`).
- S'y ajoutent la rangée « Élèves 2/4 » pleine largeur (l. 1791, retirée seulement si un panneau recouvre ; au
  téléphone elle disparaît quand la capsule est là, l. 1663-1667), le déclencheur sous la surface
  (`_sousSupport`, l. 1959-1974), la barre de support de l'élève et la marge de la barre d'appel.
- Mesures : 1440 × 900 ×2, page 255 × 360 (enseignant), 219 × 310 (élève) ; 1280 × 720 ×2, 74 × 104 et 61 × 86.
  Rendu : `revue_eleve_1280x720_x2.png`. Captures : `tb12_enseignant_notes_1440_x2_clair`,
  `tb6_eleve_ped02_1440_x2_clair`.
- Aucun écart écrit (TB-5, TB-6, TB-10, TB-11b).

Conséquence : une enseignante qui agrandit le texte à 200 % sur un portable ne voit plus ce qu'elle présente ni
ce qu'elle annote ; l'élève voit un timbre.

Attendu : borner la tête aussi au bureau, ou passer en tête compacte quand la hauteur divisée par le facteur de
texte est faible ; retirer la rangée Élèves quand la capsule est visible ; monter le déclencheur dans la tête
hors focus comme `00548b28` le fait en focus ; chez l'élève, une seule rangée pour barre de support et
déclencheur. Test de part minimale de la page à 1280 × 720 ×2 et 1440 × 900 ×2.

### M4. L'ordre de tabulation saute d'une colonne à l'autre et n'est pas stable

Ce que le code fait :
- Aucun `FocusTraversalGroup` ni `FocusTraversalOrder` dans `lib/features/salle_seance`. La composition en
  colonnes de TB-4 et TB-5 garde la politique par défaut sur toute la salle.
- Mesure reproduite par deux sessions (enseignant, PED-03, 1440 × 900, Commandes ouvertes) : zoom −, zoom + et
  « Ajuster à l'écran » reviennent après chaque carte d'élève ; « Commandes de l'appel » revient 6 fois ;
  « Focus » n'arrive qu'au 46e ou 47e appui ; « Retour » et la capsule passent après la barre de l'appel.
  Le second tour ne suit pas l'ordre du premier.
- Les tests de recette (`recette_acces_test.dart`, `_tabVers`) vérifient seulement qu'une cible est atteinte en
  120 appuis, pas l'ordre. Aucun écart écrit.

Conséquence : un enseignant au clavier ne peut pas prévoir où va le focus pour atteindre « Focus » ou « Ajuster
à l'écran ». Règle violée : plan V2 §18.3 (« l'ordre reste stable »), WCAG 2.4.3 niveau A.

Attendu : un `FocusTraversalGroup` par région (tête, colonne Participants, surface, panneau de droite, barre de
l'appel), ordre fixé par `OrderedTraversalPolicy` ou `NumericFocusOrder`, et un test qui parcourt les Commandes
au Tab sans en sortir avant leur dernière commande.

### M5. Deux détecteurs de stylet qui ne se parlent pas : après un stylet vu en lecture, le doigt écrit en Écrire

Ce que le code fait :
- `lib/features/tc_dock/couche_annotation.dart:171` : `_styletDetecte` vit dans l'état de la couche et n'est
  appris que par son Listener (`_guetter`, l. 469-485).
- `surface_page_fixe.dart:482-484` : `IgnorePointer(ignoring: !saisie)`. Hors Écrire, la couche ne voit aucun
  pointeur, donc jamais le stylet.
- Le second détecteur, `_styletVu` de `SurfacePageFixe` (l. 156, 189-195), le voit. En Écrire, `_quiDeplacent`
  rend alors les doigts (l. 210) : le doigt déplace la page. Mais `PolitiqueSaisie.appareilsDeDessin` reçoit
  `styletDetecte: false` (l. 294-298) et accepte aussi le toucher : le même doigt pose de l'encre.
- Test temporaire : zoom 200 %, glisser au stylet en lecture, Écrire, glisser d'un doigt : un trait. Contre-cas
  juste : stylet utilisé pendant Écrire, puis doigt : aucun trait. Le test existant
  (`ecriture_test.dart:546`) n'enchaîne jamais stylet puis doigt. Aucun écart écrit.

Conséquence : sur iPad, l'enseignant agrandit et déplace la page au stylet, puis touche Écrire et pose la
paume : un trait parasite part à toute la classe. Règle violée : plan V2 §7 (stylet pour l'encre, doigt pour
déplacer), TB21, contrat de `PolitiqueSaisie` (l. 36-37). Annuler le rattrape, mais le rejet de paume est cassé
sur le parcours nominal.

Attendu : un seul « stylet détecté », appris par le Listener passif de `SurfacePageFixe` (l. 311) et passé à la
couche ; test « stylet en lecture, puis Écrire, puis un doigt : aucun trait ».

### M6. Le bouton visible « Annuler » (panneau et palette courte) n'émet aucun retrait

Ce que le code fait :
- `lib/features/salle_seance/ecriture_seance.dart:54-68` : `annulerSurLaSurface` appelle seulement
  `historiquePersonnelProvider.annuler(...)` et jette l'opération défaite. Aucun `EvenementTraitRetire` ni
  `EvenementTraitTermine` n'est émis. Ce chemin sert aux deux boutons visibles (l. 157 et 262).
- La voie clavier, `CoucheAnnotation._annuler` (`couche_annotation.dart:351-377`), émet bien par
  `widget.onEvenement`, le point que la recette relie à `DiffusionOutils`
  (`recette_synchro_test.dart:411-412`). Son commentaire dit « le même Annuler que la barre », ce qui est faux.
- Test temporaire (ERR-01) : trait puis Annuler de la palette ; le dépôt est vide mais
  `traitsNonPartagesProvider` garde l'identifiant, preuve que `onEvenement` n'a rien reçu. Aucun écart écrit
  (TB-7b, TB-9, TB-10 ; TB-BR-04 parle du canal serveur, pas de l'émission client).

Conséquence au branchement BR-1 : l'enseignant annule un cercle, il disparaît chez lui et reste chez tous les
élèves ; annuler un coup de gomme fait revenir le trait chez lui seul. Il croit la classe sur la même page.
Aucun élève n'est trompé aujourd'hui (pas de transport), mais c'est le contrat que BR-1 branchera, et aucun
test ne le détecte. Règle : plan V2 §10 (retirer, annuler, effacer par le canal fiable), §22.

Attendu : une seule voie pour Annuler, qui émet l'opération défaite par le même rappel que la couche ; test
« Annuler depuis la palette émet exactement un `tc.outils.trait_retire` ». Voir aussi m32 (cible de
l'annulation).

### M7. Les trois affichages partagés ne disent pas ce que voit la classe (K-58)

Ce que le code fait : `lib/features/salle_seance/commandes_pedagogiques.dart:492-517`, un
`ControleSegmente<AffichagePartage>` à trois segments « Support », « Avec notes », « Tableau », sans phrase de
contexte ni ligne de conséquence. La ligne voisine `texteConservation` (l. 484-491) parle du sort des notes,
pas de ce que voit la classe. Couleur et Épaisseur ont leur aide (`ecriture_seance.dart:168`, `:195`). Aucun
renvoi K-58 dans TB-4, TB-6, TB-7a ni UX_REVIEW_TB (n° 10 et 27 traitent la forme).

Conséquence : un enseignant qui découvre la salle touche « Support » pour aérer la page et retire ses notes de
l'écran de toute la classe, sans le savoir. Rien n'est perdu et un clic rétablit, mais K-58 est une règle
obligatoire du directeur, « aucune exception », qui vise nommément le sélecteur segmenté.

Attendu : sous le contrôle, une ligne courte qui dit ce que voit la classe pour l'affichage choisi (par exemple
« La classe voit la page sans les notes. »), en clés sourcées et traduites ; libellés du §20 inchangés.

## Mineurs

Origine « lot » sauf mention **[10/10]**.

| N° | Constat | Preuve | Attendu |
|---|---|---|---|
| m1 | La sortie du focus s'appelle « Réduire » dans la barre (comme la fermeture d'un panneau), « Agrandir » chez l'élève, et « Focus » / « Quitter le focus » dans les Commandes ; « Agrandir » est lu deux fois. Le point ouvert TB-5 reste (a) n'a été repris ni en TB-12 ni dans TB_RAPPORT. | `dock_seance.dart:194-204`, `barre_support.dart:189-199` (sans `libelleSemantique`), `commandes_pedagogiques.dart:637-652` ; plan §20 l. 534 et 547 ; capture `TB-5/tb5_enseignant_focus_1440_x1_clair.png` ; arbre relevé « Agrandir \| Agrandir » | Une clé propre « Focus » / « Quitter le focus » (visible et lue) aux deux endroits ; reporter TB-5 (a) dans TB-RC. (produit-3, accessibilite-10) |
| m2 | Interface guidée : les Commandes disent « Ajuster à l'écran » et « Focus », mots seuls, au lieu de « Voir toute la page » et « Agrandir » avec pictogramme. Renvoyé par TB-7b à TB-10, qui ne l'a ni fait ni noté. | `commandes_pedagogiques.dart:600-653` (mêmes clés pour tous) ; plan §5 l. 124, §4.2 l. 107 ; capture `TB-12/tb12_guidee_commandes_390_x1_clair.png` | Clés guidées et icône des tuiles en mode enfant, assertion dans le test guidé de TB-10. |
| m3 | Largeur du volet fixée à 320 dp quel que soit le facteur de texte : à 1440 ×2, « Commandes » et « Réduire » passent sur deux lignes et les segments sortent de la vue alors que la moitié de l'écran est libre. Contribue aux défauts n° 10 (et en partie n° 9) de TB_RAPPORT §d. | `panneau_seance.dart:26` ; `salle_seance.dart:1849-1852`, `:507-513`, `:634` ; captures `tb5_enseignant_developpe_1440_x2_clair`, `tb12_guidee_commandes_1440_x2_clair` | Largeur qui suit le facteur de texte, bornée (par exemple jusqu'au bord de la page), calculée une fois dans `PanneauSeance`. |
| m4 | Le chevron « suite en bas » d'un volet est toujours affiché, même quand tout tient. Confirme le n° 21 de TB_RAPPORT §d, gravité mineure, et en donne la cause (code antérieur, exposé par TB-10). | `panneau_seance.dart:180-191` ; capture `tb12_eleve_commandes_1440_x1_clair` (environ 280 px vides sous Focus) | Chevron seulement si `extentAfter` > padding, ou le retirer au profit du fondu. |
| m5 | Aucun test ne mesure la hauteur de la page dans la salle en paysage court ni au bureau ×2 hors focus : M2 et M3 passent toutes les suites. | `recette_synchro_test.dart:770-779` (rotation sans géométrie), `visio_revelee_test.dart:351-352`, `calque_page_test.dart:299` (surface seule), `composition_test.dart:281-297` (largeur seulement) | Test paramétré 844 × 390, 700 × 320, 1280 × 720, 1440 × 900, ×1 et ×2, enseignant et élève : part minimale de hauteur, `takeException` nul. |
| m6 | Stylo, Surligner et Gomme : l'outil retenu n'est pas annoncé au lecteur d'écran (dette antérieure, conservée). | `bouton_outil.dart:161-166` (pas de `selectionne`) ; `barre_stylet.dart:196-203` ; mesure isSelected : none sur les trois | `selectionne: retenu` dans `BoutonOutil` ; test isSelected. |
| m7 | Chez l'élève et la guidée, la page se fond dans le nœud de tout l'écran, rôle image ; chez la guidée, dans le seul titre. | `surface_page_fixe.dart:547-553`, `barre_support.dart:33`, `vignette_video.dart:99-102` sans `container: true` ; arbre reproduit : nœud 390 × 844 [header, image] « Ma séance \| … \| page 1 sur 12 » | `container: true` aux trois ; test d'arbre élève et guidée, 390 et 1440. |
| m8 **[10/10]** | Le fondu bas des Commandes rend transparents les 32 px inférieurs du bouton atteint au Tab, et ne disparaît jamais, même sur le dernier bouton (padding interne de 12 compté dans `extentAfter`). | `commandes_pedagogiques.dart` vers l. 806 (`extentAfter > 0.5`), l. 820-843 (`ShaderMask`), l. 850 (padding) ; `app_spacing.dart:21, 33` | Seuil de `_suite` au-dessus du padding ou padding hors du défilement ; marge de défilement au focus égale au fondu. |
| m9 | Après « Ranger dans la bibliothèque » au clavier, le focus retombe hors du panneau (le menu qui l'avait disparaît). | `commandes_pedagogiques.dart:311-322` (aucun `requestFocus`) ; mesure : `primaryFocus` sous la racine de la salle | Poser le focus sur l'entrée Bibliothèque (`PorteeRangement.bibliotheque`) au cadre suivant ; même chose après « Effacer les notes ». |
| m10 | Couleur d'écriture (`FilterPill`) : l'état « choisi » est sur un nœud sans nom, et le nom est lu deux fois. Composant modifié par le lot (TB-7b). | `filter_pill.dart:59-64`, `:105-110` ; arbre « bouton, sélectionné » sans label puis « À revoir \| À revoir » | `selectionne` passé au `Pressable`, Semantics extérieur retiré, contenu en `ExcludeSemantics` ; relancer les tests des autres pages. |
| m11 | Le changement de page, le passage à « Tableau » ou un nouveau support ne sont pas annoncés à l'élève non-voyant. | `surface_page_fixe.dart:547-553`, `:634-638` sans `liveRegion` | Région vivante discrète côté élève, guidée et observateurs seulement. |
| m12 | Noms en double et ordre de lecture faussé : titre et page lus trois fois chez l'observateur, tuile seule lue « Outils d'enseignement, Écrire », aide « Mariam pourra écrire… » lue avant le nom. | `salle_page.dart:1564-1570`, `surface_page_fixe.dart:549` ; `outils_enseignement.dart:236-238` ; `panneau_eleves.dart:671-675` | Exclure le doublon ; pas de label de groupe pour un outil seul ; aide en nœud propre juste avant le bouton. |
| m13 | « Non sélectionné » annoncé sur Commandes et Bibliothèque, qui ouvrent un panneau (l'état ne peut jamais être vrai) ; dans la palette, l'entrée « Commandes » perd le nom lu du §20. | `commandes_pedagogiques.dart:105-106`, `:119-120`, `:457-463` ; `salle_seance.dart:1457-1461` ; `barre_stylet.dart:229-236` | Retirer `selected` de ces déclencheurs ; nom lu `declencheurSemantique` dans la palette. |
| m14 | Le déplacement de la page agrandie est perdu dès qu'on ouvre ou ferme les Commandes ou qu'on arme Écrire (prouvé chez l'enseignant ; le code dit le contraire chez l'élève, non testé). | `surface_page_fixe.dart:150` (`_deplacement` dans le State) ; mesures 1440 : top -17 puis -97 après Commandes | Ranger le déplacement avec le zoom dans `local`, normalisé ; test déplacer, Commandes, Écrire. |
| m15 | Une gomme commencée « à vide » avant un changement de page gomme sur la nouvelle page. | `couche_annotation.dart:223-233` (blocage seulement si `_gommesDuGeste` non vide), `:550-553` ; contrat l. 211-213, plan §13 | Drapeau « geste de gomme en cours » qui force l'arrêt ; ajouter le cas au test `ecriture_test.dart:846`. |
| m16 | La gomme ignore la page et la zone visible : glissée hors de la part visible d'une page agrandie, elle retire des traits cachés. | `couche_annotation.dart:504-507`, `:551-554` (pas de `_dansLaPage`) ; contrat de `zoneVisible` l. 152-156 ; plan §9.4 | Même filtre que le stylo dans les branches gomme ; test. |
| m17 | Deux doigts déplacent mais ne zooment pas ; le plan §7 prévoit le pincement et aucun écart n'est écrit (TB21 et le « Fait » de TB-7b ne demandaient que le déplacement). | `surface_page_fixe.dart:199-226` ; aucun `onScale` dans `salle_seance` | Écrire l'écart dans TB-7b et TB_RAPPORT, ou ajouter l'échelle à deux doigts dans les bornes existantes. |
| m18 | La pression du stylet n'est jamais capturée (§9.6 « conserver pression ») ; défaut antérieur repris sans écart écrit. | `couche_annotation.dart:545`, `:571`, `:962` ; `compaction_trait.dart:136-145` | Lire `PointerEvent.pressure` quand le matériel la donne, ou écrire l'écart dans TB-7a et TB-BR. |
| m19 | Au retour à « partagé », la marque des traits non partagés est effacée sans renvoi ni accusé ; un test fige ce comportement avec un commentaire faux (« le trait reçu »). | `surface_page_fixe.dart:171-183` ; `notes_deposees.dart:83-88` ; `synchronisation_test.dart:779-814` ; plan §10 l. 249 | Lever la marque seulement sur accusé par trait (TB-BR-42) ; d'ici là, écrire l'écart et corriger le test. |
| m20 | Une coupure de la room (reconnexion, hors ligne, échec) ne suspend pas l'écriture et ne marque pas l'encre non partagée : la vue ne lit que `synchroTableau`. | `vue_seance.dart:820-837` ; `depuis_salle.dart:139-149` ; défaut `partage` l. 508 | Getter `synchroEffective` qui tient compte de `connexion`, lu par les trois états ; un test par phase ; relier à TB-BR-06. |
| m21 | L'outil Écrire et l'historique Annuler sont des providers racine : une nouvelle salle s'ouvre avec Écrire armé, le premier doigt écrit, et Annuler peut rejouer une opération d'une autre salle. Limité à `/demo/salle` aujourd'hui (aucun dépôt réel), **majeur au branchement de BR-1**. | `etat_outils.dart:204-205`, `operations_personnelles.dart:112-116` ; `demo_salle_page.dart:902-929` ne limite que `traitsNonPartagesProvider` ; test temporaire : salle B neuve, `styletArme=true`, un doigt crée un trait | Surcharger les deux providers par salle (démo, `SallePage`, `ClasseLivePage`) ; filtre `sessionId` dans `derniere()` ; test « nouvelle salle ». Condition de BR-1. (temps_reel-4, code-1) |
| m22 | « Cours enregistré » et son point rouge restent dans l'en-tête quand la vue sait l'enregistrement inactif ; la capsule du même écran dit le contraire. Voir « Contrôle des points du §22 » et classe 2 de TB_RAPPORT. Imputable au lot : le test UX-12 ne cherche le point que dans la capsule. | `vue_seance.dart:932-937` (`texteMention` ignore `enregistrement`) ; `mention_seance.dart:30` ; `permanent_notice.dart:46-51` ; `capsule_contexte_test.dart:421, 441, 478` | Arbitrage du directeur (ADR-011 impose que « visite de contrôle possible » reste) : séparer les deux informations ou changer le texte gelé ; étendre le test UX-12 à tout l'écran. |
| m23 | Un widget du lot lit un rôle au lieu d'une capacité ; la fiche TB-6 l'attribue à tort à un état antérieur. | `zone_support.dart:278` (`vue.role == RoleSeance.enseignant`, ajouté par 4adb8a82) | Getter de capacité sur `VueSeance`, lu à l. 74 et 278 ; corriger l'inventaire de TB-6. |
| m24 | Les 17 libellés `salle.seance.commandes.*` (TB-4) ne sont pas dans `tool/libelles_sources.json` ; la sémantique de Focus s'écarte du §20 sans écart écrit. | `verifier_revue --detail` (libelle-sans-source, `fr.i18n.json:365, 379, 380`) | Déclarer les clés (plan §20, TB-4) ; écrire l'écart de `focusSemantique` (WCAG 2.5.3) pour validation. |
| m25 | Les onglets Support et Outils utilisent `ControleSegmente` directement au lieu de `SelecteurSection` (ONGLETS-1). Rendu probablement identique aujourd'hui. | `commandes_pedagogiques.dart:377-390` ; `lib/CLAUDE.md:81` | Remplacer par `SelecteurSection`, à comportement égal. |
| m26 | Le bouton « Réduire » du panneau est recomposé dans l'écran (`Pressable`, `Row`, `Text`, icône), hors de la garde du core. | `panneau_seance.dart:354-387` ; aucun test dans `garde_interface_test.dart` | Variante au core (chevron de fin) ; ajouter à la garde, 320 et 1440, ×1 et ×2. |
| m27 | L'œil et l'avatar de la capsule sont des icônes seules sans infobulle, recomposées avec `Pressable`. | `capsule_seance.dart:84-91`, `:134-141` ; `lib/CLAUDE.md:59` ; 00_REPRISE l. 130 | Forme nue de `BoutonIcone` au core pour l'œil ; au minimum un `Tooltip`. |
| m28 | Le détail de l'échec d'ouverture d'un support ne donne pas de cause probable (K-59). Le titre « Fichier non ouvert. » est un écart écrit (TB-8), non repris ici. | `fr.i18n.json:390` | Ajouter une cause probable (fichier indisponible pour le moment) en français et en arabe. |
| m29 **[10/10]** | L'indice de défilement des Commandes est une copie du fondu de `TeteSalleBornee`, et les deux copies divergent déjà (borne à un huitième de hauteur dans l'une seulement). | `commandes_pedagogiques.dart:788-880` ; `salle_seance.dart:2309-2389` ; ajouté par b28136ec | Un seul widget de défilement à fondu, paramétré, utilisé aux deux endroits. |
| m30 | L'aperçu du trait en cours n'a pas sa frontière de repeint : chaque point repeint la page, la tête et la palette ; la liste des points est recopiée à chaque point. TB-7b affirme « repaint ciblé ». Non mesuré sur appareil (R-14). | `couche_annotation.dart:417` (seul calque borné), `:432`, `:572` ; frontière relevée : `RepaintBoundary` de la route, 293 objets | `RepaintBoundary` autour de l'aperçu, liste qui grandit sans copie ; assertion de test. (code-2, geometrie-8) |
| m31 | « Effacer les notes » : si le panneau est démonté pendant la confirmation, l'effacement a lieu mais l'historique n'est pas vidé ; Annuler peut remettre des notes effacées. | `commandes_pedagogiques.dart:327-350` (`if (!mounted) return` avant `oublierSurface`) | Lire le contrôleur et la surface avant l'`await`, appeler `oublierSurface` sans dépendre de `mounted`. |
| m32 | « Annuler » de la palette et du panneau est proposé même quand sa cible a disparu (trait de l'élève gommé par l'enseignant) : le premier appui ne fait rien de visible et consomme l'opération. La voie clavier (`_annulable`) ne le propose pas. | `ecriture_seance.dart:141-146`, `:250-255` ; `couche_annotation.dart:329-344` | Même règle que `_annulable` pour les deux voies (à faire avec M6) ; purge de l'historique des autres appareils à noter dans TB-BR. |
| m33 **[10/10]** | R-18 : « aucun signe coupé » et « titre lu entier » ne peuvent pas échouer (mutation : titre rogné de 55 px, tests verts). Le §g de TB_RAPPORT le dit « non bloquant » ; la partie « signes lisibles » de R-18 n'a en fait aucune preuve. | `recette_coquille_test.dart:527-529`, `:606-609` ; `surface_page_fixe.dart:568-589` (pas de `maxLines`, `FittedBox`) | Mesure de largeur intrinsèque et du facteur d'échelle, polices du dépôt chargées ; préciser dans la matrice que « signes lisibles » reste à prouver. |
| m34 **[10/10]** | R-12 : la coupure de l'enseignant ne joue aucun rôle dans le test (mutation sans la coupure : vert). Il prouve seulement qu'un élève sans droit signé n'a pas de droit. | `recette_synchro_test.dart:597-649`, `:82-87` ; `service_realtime_pedagogique.dart:164-170` ; cité par `TB_RAPPORT.md:49` | Renommer, ou relever les capacités avant et après la coupure ; citer ce test comme borne, pas comme preuve d'ERR-01. |
| m35 | Observateurs : « titre non rogné » vérifie `didExceedMaxLines` sur un `Text` sans `maxLines`. | `observateurs_test.dart:396-410` ; `salle_page.dart:1564-1569` | `verifierAucunMotCoupe` avec les polices du dépôt. |
| m36 | « 200 %, 320 px : rien ne déborde » ne teste que l'enseignant, monté seul, et les bords horizontaux après défilement : il ne peut pas voir le défaut grave n° 2 de TB_RAPPORT (gravité confirmée). La visibilité du fondu n'est testée nulle part. | `commandes_test.dart:643-692` ; captures `tb12_enseignant_commandes_320_x1_clair`, `tb12_eleve_commandes_320_x1_clair` | Cas élève et guidée depuis la coquille, 320 ×1 et 390 ×2 ; dernière entrée entière ou fondu visible (opacité ou hauteur écrite) ; renommer le groupe. |

## Notes

| N° | Observation | Preuve | Suite proposée |
|---|---|---|---|
| n1 | Deux contrôles voisins s'appellent « Support » (onglet et affichage partagé) ; au lecteur d'écran on entend deux fois le même mot. | `commandes_pedagogiques.dart:379-386`, `:499-503` ; `controle_segmente.dart:140-142` | Nom lu distinct, mots visibles inchangés. |
| n2 **[10/10]** | Correction 00548b28 : tient hors téléphone ; au téléphone en focus, la rangée Commandes (environ 73 dp) reste sous la page. | `salle_seance.dart:1608`, `:1885-1887` ; `tb5_enseignant_focus_telephone_320_x2_clair` | Facultatif : déclencheur en icône seule près de la capsule. |
| n3 | Réponse à la question de TB_RAPPORT §g : la rangée de la barre d'appel devient compacte dès que le texte dépasse ×1, même quand la place existe (768 ×2) ; perte seulement visuelle. Code antérieur. | `dock_seance.dart:363-371` ; `commande_salle.dart:60-61` ; `tb12_enseignant_libre_768_x2_clair` | À arbitrer par le directeur : compacter seulement si `serre` ou Mode Accessibilité. |
| n4 | La flèche d'Annuler n'est pas miroitée en arabe (défaut antérieur exposé). | `app_icons.dart:700-704` sans `matchTextDirection` ; employée aussi pour un statut (`carte_session.dart:492`) | `matchTextDirection: true`. |
| n5 | La gomme et l'indication du Pointeur grossissent avec le zoom (rayon 24 pt à 200 % ; disque du Pointeur 40 pt). Le commentaire « points d'écran » est faux. | `couche_annotation.dart:169` ; `surface_page_fixe.dart:303`, `:321-324` | Diviser le rayon par le zoom, ou corriger le commentaire. |
| n6 | Annuler après la gomme réémet le même identifiant, en conflit avec les pierres tombales demandées par TB-BR-39. Aucun récepteur n'existe encore. | `couche_annotation.dart:369-377`, `:737` | Écrire le contrat dans TB-BR-39 avant BR-1 (nouvel id ou révision). |
| n7 | L'aperçu de trait ne porte pas l'épaisseur que le trait final porte. Aucun récepteur d'aperçu aujourd'hui (R-10 « limite écrite »). | `evenements_outils.dart:36-75` ; `couche_annotation.dart:580-586` | Ajouter `epaisseur` avec le récepteur de BR-1. |
| n8 | Le droit d'écrire de l'élève est retrouvé par son prénom ; limite écrite (démonstration, TB-BR-10), `peutEcrire` reste faux en production. | `vue_seance.dart:1349-1354` ; `demo_salle_page.dart:733`, `:831` | Au branchement, porter le droit sur l'identité. |
| n9 **[10/10]** | L'auto-contrôle du §g de TB_RAPPORT est inexact : `repere_demonstration.dart`, modifié par TB-12, garde 2 violations antérieures (l. 55 et 59) ; `verifier_revue` compte 1609, pas 1611. | `TB_RAPPORT.md:321-322` ; `dart run tool/verifier_jetons.dart` | Écrire « aucune violation nouvelle » et le compte mesuré. |
| n10 | `CommandeSalle` (core) : hors rangée compacte et au-delà de 130 %, la case d'une bascule suit son mot ; voulu (70cf7561) pour ne plus couper le mot, mais les voisines peuvent bouger et ce n'est pas testé. | `commande_salle.dart:307-312` | Largeur du plus long mot d'état, ou écart écrit ; test de mesure. |
| n11 **[10/10]** | Bibliothèque : `_montrerEtat()` appelé pendant l'ouverture alors que le bloc n'est plus rendu ; commentaires l. 108 et 159 périmés. | `bibliotheque_seance.dart:138`, `:269` | Supprimer l'appel, corriger les commentaires. |
| n12 **[10/10]** | En focus et en écriture, la tête garde un écart de 12 avant la capsule pour un déclencheur vide. | `salle_seance.dart:1459-1464`, `:1885-1886`, `:1941` | Rendre `null` quand rien n'est à montrer. |
| n13 **[10/10]** | UX-22 / R-16 : « Commandes sans glissement » passe aussi sans mouvement réduit, car le panneau n'a aucune animation. La partie rangement est saine (mutation M4). | `recette_acces_test.dart:535-546` | Renommer en garde de non-régression. |
| n14 **[10/10]** | UX-24 : le compteur de remontage n'est jamais lu (déjà au §g de TB_RAPPORT, gravité confirmée). | `recette_synchro_test.dart:166`, `:179`, `:739-746` | Le lire dans `inchange()` ou le supprimer. |
| n15 | Décision TB-R « Pointeur en tête d'Outils » prouvée en LTR seulement ; le code est directionnel, le risque est théorique. | `commandes_test.dart:345-352` ; aucun test RTL ne cite `outil-pointeur` | Test RTL : Pointeur a le plus grand `dx` à droite. |
| n16 **[10/10]** | UX-09 : le `SemanticsHandle` n'est libéré qu'en fin de test ; `startsWith` tolère la double lecture connue (n° 22). | `recette_acces_test.dart:408`, `:517`, `:521` | `addTearDown(semantique.dispose)`, puis `equals` une fois le doublon corrigé. |

## Contrôle des points du §22

| Point du §22 | Verdict | Preuve |
|---|---|---|
| Unreliable / reliable ne veut pas dire UDP / TCP | **Tenu** | Aucune mention TCP, UDP, lossy ou reliable ajoutée ; `EvenementTraitTermine` par `CanalFiabilite.fiable`, aperçu par le canal éphémère ; limites écrites (TB-BR-39, TB-BR-40) ; doublons écartés par empreinte (R-07, R-10). |
| Coordonnées sur le conteneur extérieur | **Tenu**, deux réserves | `applyBoxFit(contain)` puis `Alignment.inscribe` (`surface_page_fixe.dart:54-61`) ; page et calque dans un seul `Transform` (`:320-335`) ; `ReperePage.versPage` et `versSurface` (`repere_page.dart:76-96`) ; rejet hors page sans rabattre (`couche_annotation.dart:510-513`, `:560-568`). Réserves : la gomme ignore la page (m16) et sa taille suit le zoom (n5). |
| Cache Web attribué à `cached_network_image` seul | **Tenu** | Aucun emploi ajouté par le lot ; TB-BR-21 écrit que ce paquet seul ne suffit pas sur le Web et demande la preuve au serveur. |
| Trait final fiable absent, reconnexion sans snapshot, paquet d'ancienne page appliqué | **Divergence** | Trait final fiable présent ; paquet d'ancienne page tenu (`didUpdateWidget`, `couche_annotation.dart:211-238`) sauf la gomme « à vide » (m15). Mais Annuler visible n'émet rien (M6), la coupure de room ne suspend rien (m20) et le retour à « partagé » efface la marque sans réconciliation (m19). |
| Sauvegarde annoncée sur simple émission | **Tenu** | `ConservationNotes` n'a pas de valeur « sauvegardée » (`vue_seance.dart:247-256`) ; garde de code et d'écran contre « Sauvegardé » (`synchronisation_test`) ; trait refusé retiré (`_oublier`). |
| Point rouge sans état réel, œil supposé actif, permission par bouton caché | **Divergence** sur le point rouge, le reste tenu | Capsule juste (`voitPointEnregistrement`, `capsule_seance.dart:113-116`) ; œil seulement si `controle != null`. Mais l'en-tête affiche toujours `PermanentNotice` avec son point (m22, classe 2 de TB_RAPPORT). Position de la revue : divergence §22 confirmée ; elle est antérieure au lot et relève d'un arbitrage du directeur, car ADR-011 interdit à la vue de retirer « visite de contrôle possible ». Le lot n'en porte que le test incomplet (mineur). Permission : la saisie dépend de la vue (`saisie = vue.ecritPossible && styletArme`, avec `IgnorePointer`, `ExcludeFocus`, `ExcludeSemantics`), pas d'un bouton caché ; limite serveur écrite (TB-BR-34, TB-BR-51). |
| Quitter caché dans Commandes, masqué au focus clavier ou bloqué par un scrim | **Tenu** | Quitter reste dans la barre de l'appel, hors des Commandes (TB7) ; la barre passe par-dessus les panneaux et Quitter reste tapable (`visio_revelee_test.dart:345-380`) ; `CommandesMasquables` ne masque jamais la barre avec un lecteur d'écran, le clavier ou une commande qui a le focus. Le chemin modal de Classe Live qui pourrait couvrir Quitter est inatteignable aujourd'hui (constat écarté ci-dessous). |
| Page zoomée sans calque, tableau masqué déformé, image non canonique | **Tenu** pour le calque, **régression pédagogique** sur la taille | Calque dans le même `Transform`, épaisseur relative à la page (`couche_annotation.dart:751`, `:780-782`), capture `tb7a_trait_pose_zoom200_390_x1_clair`. Mais la page devient un timbre en paysage (M2) et au bureau ×2 (M3) ; le déplacement est perdu (m14). |
| Deux clients ou salles LiveKit, nouveau CRDT, nouveau backend, seconde bibliothèque | **Tenu** | `git diff 9cb57f17 a5393f82 -- supabase` vide ; aucun nouvel import `livekit_client` ou `supabase` ; `lib/core/tc_realtime` intact ; démonstration derrière des ports surchargés. Une seule Bibliothèque dans la coquille TB (`BibliothequeSeance`). Réserve documentaire : l'écart n° 6 de TB-8 (« Classe Live garde SelecteurRessources ») est inexact. |

## Décision TB-R du 09/10 (onglets Support / Outils) : tenue

- Deux onglets Support et Outils : `commandes_pedagogiques.dart:372-391` (et `:377-390`), capture
  `TB-12/tb12_enseignant_commandes_390_x1_clair.png`, `tb5_enseignant_developpe_1024_x2_clair`.
- Bibliothèque en première ligne de Support : `:452-464` ; test `commandes_test.dart:157-171` (ordre en `dy`).
- Pointeur en tête d'Outils : `enum OutilEnseignement { pointeur, ecrire, marquer, masquer }`
  (`actions_seance.dart:17`) ; test `commandes_test.dart:329-370`. Mutation (ordre inversé dans
  `outils_enseignement.dart:124`) : le test échoue, il protège vraiment la décision.
- Pas d'onglet quand aucun outil n'est possible ; le panneau rouvre sur Outils quand un outil est retenu.
- Réserves sans rouvrir la décision : composant `ControleSegmente` au lieu de `SelecteurSection` (m25), mot
  « Support » en double au lecteur d'écran (n1), ordre prouvé en LTR seulement (n15).

## Gravité des défauts déjà au TB_RAPPORT

Les défauts ne sont pas recopiés ; la revue confirme ou ajuste.

- §d n° 1 (320 ×2, tête à 55 %) : majeur confirmé (WCAG 1.4.10). L'ajout « feuille Élèves sans nom » a été
  écarté.
- §d n° 2 (feuille Commandes coupée) : grave confirmé ; aucun test ne le couvre (m36) ; le fondu ajouté le 10/10
  masque aussi le focus (m8).
- §d n° 4 (×2 au bureau) : majeur confirmé et étendu, voir M3.
- §d n° 5 et 6 (observateurs à ×2) : majeurs confirmés (WCAG 1.4.4) ; la sémantique garde la phrase entière.
- §d n° 9 et 10 : cause partielle trouvée, voir m3.
- §d n° 21 (chevron) : mineur confirmé, cause trouvée, voir m4.
- §d n° 22 (carte du catalogue lue deux fois) : mineur confirmé.
- Classe 2 (point rouge) : voir m22 et le §22 ci-dessus.
- §g, faiblesses de tests : R-18 n'est pas « non bloquant » pour la matrice (m33) ; UX-24 et UX-17 confirmés
  comme écrits.

## Constats écartés

| Constat | Raison |
|---|---|
| Classe Live : « Bibliothèque » ouvre une feuille modale qui remplace le support sans aperçu et couvre Quitter | Chemin inatteignable : `ContexteClasseLive` (`routes_tc_a.dart:93-104`) ne passe jamais `bibliotheque`, donc aucune entrée ; `ClassLibraryPicker` n'est instancié nulle part ; le passage par feuille existait avant le lot. Reste une dette documentaire (écart n° 6 de TB-8 inexact) à noter pour BR-1. |
| 320 ×2 : « Retirer l'autorisation d'écrire » sans le nom de l'élève | Le bouton est dans la carte de l'élève, n'apparaît qu'une fois la fiche dépliée, et son nom lu porte le prénom (`panneau_eleves.dart:186-220`, `:683-686`). La tête à 55 % est déjà le défaut n° 1. |
| Le verrou d'Annuler du 10/10 n'a ni délai ni phrase | Aucun dépôt réseau n'existe (`portAnnotationsProvider` lève, seule `AnnotationsMemoire` répond) ; sans le verrou, l'écran serait le même. Remarque pour le futur adaptateur. |
| `CommandesEleve` programme un rappel d'après-cadre à chaque reconstruction | Déjà écrit et relevé dans la fiche TB-10 (choix et contre-vérification) ; sans effet. |
| UX-17 : l'aperçu est une lecture écrite par le test | Déjà au §g de TB_RAPPORT et UX-17 déjà « partiel » (TB-BR-48). Au plus, renommer le test. |

## Corrections du 10/10 relues

Les corrections `35fd3490..a5393f82` ont été relues sur les huit axes par des agents indépendants. Elles restent
à relire par une autre session (K-60.4).

Ce qui tient :
- l'état d'ouverture passe dans le bouton du pied (« Ouverture du support… », annonce vive), « Revenir aux
  supports » reste atteignable ;
- le retrait du droit n'a plus d'icône crayon ;
- la tuile Écrire seule garde son mot au texte agrandi ; Annuler compte dans la palette courte ;
- un seul zoom chez l'élève au bureau ; le volet de l'élève reste dans la gouttière (b28136ec) ;
- verrou `_annulationEnCours` juste, partagé par la palette et la couche (test « deux appuis rapides ») ;
- `sensDuDocument` ne touche que le texte de la page ; les traits restent géométriques en RTL ;
- focus hors téléphone : la tête porte le déclencheur et la page grandit (00548b28) ;
- `_ColonneDefilante` : `setState` seulement après mise en page ou défilement, position gardée ;
- UX-22 élève (recherche en descendant) et R-12, UX-12 en « partiel » : statuts honnêtes.

Ce qui ne tient pas ou reste à reprendre (marqués **[10/10]** plus haut) : m8 (fondu qui masque le focus), m29
(copie du fondu), m33 et m34 (tests de recette qui ne peuvent pas échouer ou ne prouvent pas ce qu'ils disent),
et les notes n2, n9, n11, n12, n13, n14, n16. Aucun majeur n'est imputable aux corrections du 10/10.

Cette revue n'autorise aucun déploiement. Pousser sur `main` met en production.
