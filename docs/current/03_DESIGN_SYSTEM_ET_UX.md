# Rewayah - charte UX/UI canonique
Version : 22 septembre 2026. Condensé opérationnel de la Bible V2 ; inspection du thème Flutter existant obligatoire avant migration des tokens.

## 🧊 Règles gelées du directeur, DESIGN-GOV-2026-09-26 (obligatoires avant tout nouveau lot visuel)

Texte intégral et seul faisant foi : `docs/current/DESIGN-GOV-2026-09-26.md` (copie de `projet/ressources:memoire/DESIGN-GOV-2026-09-26.md`). **Règle gelée jusqu'à nouvelle décision datée du directeur** : ne pas la modifier, ne pas la réinterpréter.

- Autorité (§1) : dernière demande explicite du directeur, puis décisions canoniques, puis contrats serveur vérifiés, puis la spec du lot, puis le système de design gelé. Une maquette n'élargit jamais une permission ; aucune donnée absente du contrat n'est inventée.
- Validation UX 2026 (§4) : avant d'implémenter une disposition `PROPOSITION`, la confronter aux référentiels officiels (Flutter adaptive, Material 3, Apple HIG, WCAG 2.2 AA, Nielsen, Fitts / Hick / Gestalt, Baymard ; GOV.UK exclu) et livrer `UX_REVIEW_<lot>.md` (règle, source, date, conclusion, modification). Jamais « conforme » sans règle ni conséquence.
- Contrats A à E (§4 bis) : échelle d'espacement 4 à 64, **objet vers le CTA qui agit dessus : 16**, CTA au bord *trailing* (`start/end`, jamais `left/right`), pas de bouton pleine largeur sur bureau, `ActionPrincipale` / `AppCard` / `GroupeReglages` / `Skeleton` / `AppBottomSheet` jamais forkés, bureau 1440 réel, durées de mouvement gelées, `Skeleton` + `BlocAsynchrone` obligatoires pour tout chargement substantiel.
- Progression (§4 bis.8) : s'applique aux nouveaux lots seulement. **Aucune étape faite n'est rouverte** ; l'harmonisation des écrans déjà faits se fera en une passe (HU-1) après les visuels de tous les rôles.
## Langage visuel
Material Design 3 comme système de composants et comportements ; adaptation iOS pertinente et cohérente. Style calme, contemporain, aéré, profondeur discrète, ombres légères, animation courte qui sert la compréhension. Palette douce et presque monochrome ; violet fortement atténué, jamais primaire par défaut. Les documents fournis ne fixent pas de valeurs HEX officielles : ne pas inventer de palette chiffrée « approuvée ». Auditer les tokens et les dernières maquettes approuvées, proposer au directeur les tokens précis s'ils manquent, puis les centraliser. Des touches pédagogiques de couleur sont possibles dans l'Interface guidée et les groupes, sans coder l'information par la seule couleur. Mode clair et sombre complets, contraste vérifié.

Interdire dans les widgets métiers `Color(0x...)`, HEX et dimensions arbitraires répétées. Utiliser `ThemeData`, `ColorScheme`, tokens sémantiques de typographie, espace, rayon, élévation et états. Reprendre et améliorer les composants existants (`Pressable`, `BentoTile`, `ChoiceCardGroup`, `AudioLabel`, `PermanentNotice`, `AvatarTile`) au lieu de multiplier les copies. Une grande carte ne doit pas devenir une collection de petites boîtes.

## Structure par écran
Un titre compréhensible, une tâche dominante, un CTA principal proche de l'usage du pouce sur mobile, puis les détails secondaires accessibles par divulgation progressive. Les préférences vont dans Paramètres ; les filtres à côté du contenu ; les actions irréversibles près de leur objet avec confirmation adaptée. Mobile : barre basse avec peu de destinations, retour visible dans la zone accessible au pouce lorsque le flux le demande, grandes zones tactiles. Tablette : deux panneaux si utiles. Desktop : navigation latérale et contenu centré ; ne pas agrandir le mobile uniformément.

Rôle élève : prochain cours immédiatement, classe et travail ; enseignant : journée, prochaine classe, accès au support et roster ; tuteur : foyer, inscription et échéances ; admin : recherche, opérations et exceptions, densité progressive. Aucun code interne tel que `F1-PHO-01` ou `CORE24` dans les textes visibles. `Sayyid` et `Sayyida` en salle ; `Interface guidée` accessible aussi aux adultes. Photos publiques d'enseignants distinctes des pièces d'identité.

## Salle pédagogique
Sur petit écran le document/Coran est le contenu principal ; vidéo secondaire ajustable, roster en panneau temporaire, dock des outils compact et atteignable. En paysage et sur tablette, utiliser la largeur pour document, participants et contexte sans réduire le texte du Coran. Afficher état micro/caméra, enregistrement réel, réseau, reconnexion et présence sans alarme visuelle permanente. Commandes enseignant au bon niveau : suivre, pointer, marquer, masquer, stylet, devoir ; paramétrage rare ailleurs. Le contenu en cours survit aux changements d'écran.

Lecteur Coran : source vérifiée, fidélité Mushaf en mode page quand disponible, mode verset agrandi, zoom, RTL, contrôles sobres, aucune génération trompeuse d'un « Mushaf fidèle » par simple retour à la ligne. Une annotation reste dans sa couche, pas dans le texte canonique.

## Accessibilité et QA
Cibles tactiles d'au moins 48 dp, agrandissement du texte sans écrêtage, libellés sémantiques, focus clavier et lecteur d'écran, ordre de lecture, RTL arabe, locales et fuseaux, contrastes WCAG 2.2 pertinents, mode mouvement réduit. Vérifier écran étroit, tablette, desktop web, clair/sombre, chargement, vide, erreur, hors ligne et permissions refusées. Captures comparatives et test sur appareil réel ou simulateur pour tout écran livré. Animations légères ; retour haptique facultatif, sans dépendance fonctionnelle. Mesurer le temps et le nombre d'actions pour rejoindre une séance et reprendre le support.
