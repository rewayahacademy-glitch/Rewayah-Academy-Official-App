# 07 — Catalogue de composants

Un composant du catalogue est le **seul point d'entrée** de sa fonction. Aucun
écran ne réimplémente son bouton, sa carte, son état vide ou son squelette.

Un composant n'entre au catalogue que s'il porte tous les états de sa colonne.
Un composant livré avec son seul état nominal n'est pas fini.

## 1. Ce qui existe déjà

Dix composants, dans `lib/core/widgets/`, plus la grille de semaine partagée.
La refonte ne les supprime pas : elle en corrige trois et en ajoute.

| Composant | Fonction | Ce que la refonte change |
| :--- | :--- | :--- |
| `Pressable` | Seul point d'entrée du retour tactile. Échelle 0,96, 120 ms, haptique | Ajouter l'état **survol** et l'anneau de **focus** clavier, absents et nécessaires au Web |
| `BentoTile` | Bloc de grille : full, half, third, quarter | Passe sur `surfaceRaised` + `elevation1` + `borderHairline`, au lieu du fond unique |
| `AvatarTile` | Photo de profil avec repli sur initiales, URL signée | Le repli prend `washFamily`, plus `borderStrong` en contour |
| `AudioLabel` | Bouton haut-parleur qui rejoue un libellé | Inchangé. Son API prend déjà une paire, correction de l'étape 4 |
| `PermanentNotice` | Bandeau « cours enregistré, visite possible » | Inchangé, et **son API ne doit jamais accepter de paramètre de visibilité** : c'est l'ADR-011 qui en dépend |
| `PinPad` | Pavé numérique géant, valeur jamais transmise | Passe l'erreur en `inkAlert`, pas en `surfaceAlert.applyTo` |
| `EmptyState` | État vide illustré | Gagne les trois registres de `02-regles-ux.md` §6 : actionnable, subi, bonne nouvelle |
| `OfflineBanner` | Dégradation réseau | Passe en registre doux : `washWarning` + `inkWarning`, au lieu d'un aplat |
| `ChoiceCardGroup` | Sélection par cartes, repli « Autre » | Contour de sélection en `borderStrong`, fond `washAccent` |
| `ActionPrincipale` | Le bouton du produit | Gagne le quatrième niveau, **destructif**, et les états survol et focus |
| `GrilleSemaine` | Grille de disponibilités partagée `TUT-04` / `ENS-06` | Cases vides en `surfaceSunken`, cases posées en `washAccent`, filet `borderStrong` au survol ou à la pression -- **pas de `surfacePrimary`** : un aplat plein sur vingt cases par semaine sature l'écran (corrigé au lot R4, imprécision relevée à la relecture) |
| `PageParcours` | Coquille d'une page de parcours : une question, une action, où l'on en est, le temps restant | Vit dans `lib/features/inscription/`. **À remonter dans `lib/core/widgets/`** au lot C : c'est un composant partagé, pas un détail de l'inscription |

## 2. Ce qui manque

Priorité P0 : nécessaire dès le lot de thème et de reprise des écrans. P1 :
nécessaire avant l'étape 5. P2 : plus tard.

| Composant | Fonction | Pri. |
| :--- | :--- | :-: |
| `PageShell` | Le gabarit de page : fond crème, gouttière du gabarit courant, largeur bornée, en-tête, zone défilante, zone d'action collée en bas. **Tout écran passe par lui** | P0 |
| `NavShell` | Barre basse, rail ou barre latérale selon la largeur, alimentés par **une seule** liste de destinations | P0 |
| `AppCard` | Surface élevée : `surfaceRaised`, `borderHairline`, `elevation1`, rayon `radiusMd`. Variante pressable | P0 |
| `SectionHeader` | Titre de section, compteur facultatif, action tertiaire à droite | P0 |
| `StatusPill` | État nommé : pastille de couleur + mot. Jamais la couleur seule | P0 |
| `Skeleton` | Bloc de chargement à la forme du contenu final. Ne s'affiche pas avant 200 ms | P0 |
| `LocalFeedback` | Le retour local de `02-regles-ux.md` §7 : court, posé près de ce qui a changé, avec annulation facultative | P0 |
| `StatTile` | Chiffre et libellé, chiffres tabulaires, zéro affiché comme les autres valeurs, tap qui mène à l'écran d'action | P0 |
| `SignalRow` | Une ligne « à traiter » : icône sémantique, phrase, ancienneté, chevron. C'est le composant du `signal → action` | P0 |
| `AppBottomSheet` | Feuille de bas d'écran : suit le doigt, seuil de vitesse, voile, ressort amorti | P0 |
| `ConfirmDestructive` | Les trois temps du destructif : question, conséquence en langage humain, deux actions asymétriques | P0 |
| `ChildCard` | La carte enfant du foyer, avec ses six états (§3). Composant fondamental du domaine famille | P0 |
| `MarquePage` | La zone de marque du tunnel d'entrée : le nom du produit en `inkAccent`, seul, faute d'asset de logo. **Produit au lot R0, absent de cette liste d'origine** ; inscrit ici parce qu'un composant hors catalogue est un composant que personne ne relit, et que c'est le test de la galerie qui l'a signalé | P0 |
| `DataCollection` | Tableau sur desktop, liste de cartes sur mobile, **à partir de la même définition de colonnes**. **Construit au lot `ADM-04`, le 12 septembre 2026** : il attendait un écran dont la forme naturelle soit un tableau, et le journal d'audit était cet écran. Le seuil est le **desktop**, pas la tablette. Il porte sa propre zone défilante, ce qui laisse l'en-tête de colonnes collée en haut : la page qui l'emploie passe donc `defilante: false` à son `PageShell` | P1 |
| `FilterPill` | Une valeur de filtre, retenue ou non, avec son compteur. **Produite au lot `ADM-04`, absente de cette liste d'origine** ; inscrite ici pour la même raison que `MarquePage` : un composant hors catalogue est un composant que personne ne relit. Ni `ActionPrincipale` (une rangée de tertiaires alignées est interdite par §4 des règles UX) ni `ChoiceCardGroup` (qui ajoute d'office une carte « Autre » en saisie libre, absurde quand les valeurs viennent de la base) | P0 |
| `TimelineRow` | Une entrée de la journée : cours, pause, prière. Même composant pour les trois, sinon la colonne de `ENS-02` se casse | P1 |
| `PageImmersive` | La coquille des écrans **sans page** : plein cadre, sans titre, sans gouttière, sans colonne bornée. Deux registres seulement, `salle` et `lecture`, et la paire du fond s'applique d'office aux textes et aux icônes posés dedans. **Produite au lot `N3`, absente de cette liste d'origine** : la refonte n'avait prévu qu'un gabarit de page, et la Bible V2 §22 (`CONTENT > CHROME`) en exigeait un second. Inscrite ici pour la même raison que `MarquePage` et `FilterPill`. Elle ne porte **pas** le bandeau hors ligne de `PageShell` : en salle, c'est le moteur temps réel qui sait si le lien tient | P0 |
| `LignePresence` | Un état de présence avec tout ce qu'il faut pour le comprendre : un nom, une `StatusPill` qui porte toujours son mot, une phrase de contexte (« en salle depuis 12 min », « sans nouvelles depuis 3 min ») et, quand une décision humaine a figé l'état, la mention « consolidé ». **Produite au lot `N4`, absente de cette liste d'origine** ; inscrite ici parce qu'elle porte à elle seule deux invariants de l'étape 5 — **J3** (un état indisponible se dit « inconnu », jamais « absent ») et **J7** (une couleur seule ne représente jamais un état critique) — et qu'écrits dans un écran, ces deux-là seraient rejoués de mémoire au suivant. Elle **ne pose aucune couleur** : elle sert la salle en registre inverse et servira le suivi élève sur fond crème, donc la hiérarchie tient par la taille et l'encre vient de la coquille. Un `Wrap`, jamais un `Row` : dans la colonne de 208 points de la salle, « Nour » suivi de « Reconnexion en cours » débordait de 26 pixels, et un `Row` aurait coupé le mot d'un état critique — c'est-à-dire J7 | P0 |
| `RosaceVerset` | Le numéro d'un verset, dans la rosace qui le porte sur un mushaf : un cercle **dessiné** et des chiffres **arabo-indiens**. **Produit au lot `N5`, absent de cette liste d'origine** ; inscrit ici pour la même raison que `MarquePage`, `FilterPill` et `PageImmersive`. Deux décisions y sont enfermées plutôt que recopiées dans l'écran : le cercle est dessiné et non tiré du glyphe U+06DD, que réserve pourtant Unicode à cet usage exact, parce que toutes les polices ne le portent pas et qu'un carré vide au milieu du texte coranique serait pire que tout ; et le composant est **muet pour les technologies d'assistance**, parce qu'un numéro de verset est un repère de mise en page, pas du texte à épeler au milieu d'une phrase. Son échelle suit celle du texte : une rosace de taille fixe dans un texte grossi deux fois casserait la ligne de base | P0 |
| `ReadingColumn` | Colonne de lecture bornée à 68 caractères, pour tout texte suivi | P1 |
| `SegmentedTabs` | Onglets d'un même écran, deux ou trois au maximum. Sur desktop, remplacés par deux colonnes quand c'est possible | P1 |
| `SharedReference` | La carte « l'enseignant vous a partagé Al-Baqarah 153 » et son ouverture animée dans le lecteur | P2, étape 5 |

## 3. `ChildCard`, en détail

Elle mérite sa fiche : c'est elle qui porte la valeur de `TUT-01`, et c'est elle
que la note de refonte donne en exemple.

| État | Ce qui s'affiche | Registre visuel |
| :--- | :--- | :--- |
| Normal | Photo, prénom, prochain cours daté, chevron | `AppCard`, `elevation1` |
| Aucun planning | Prénom, « Aucun créneau posé », bouton « Poser un horaire » | Fond `washWarning`, encre `inkWarning`, contour `borderStrong` |
| Cours imminent | Prénom, heure, minuteur | `washAccent`, filet `borderStrong` à gauche. **Pas de pulsation** : une seule zone pulse par écran, et c'est `ELV-02` |
| En cours | Pastille `surfaceSuccess`, nom de l'enseignant, minuteur écoulé, bouton « Assister » | Carte normale, **bouton** en `surfacePrimary` |
| En recherche d'enseignant | Prénom, statut, date de la demande | Carte normale, encre `inkMuted` |
| Séance annulée | Prénom, motif en une phrase, et ce qui est proposé | `washAlert`, encre `inkAlert`. Jamais un aplat rouge |
| Hors ligne | La carte reste, la donnée volatile se grise, mention « Synchronisation impossible » et « Réessayer » | Aucun message d'erreur brut |

Le bouton « Assister » est la fonction de confiance la plus forte du produit. Il
entre en observateur muet, et l'enseignant le voit arriver.

## 4. Les états obligatoires, par famille de composant

| Famille | États |
| :--- | :--- |
| Contrôle interactif | default, hover, pressed, focus, disabled, loading |
| Carte cliquable | default, hover, pressed, focus, selected, disabled |
| Zone de données | loading, content, empty, error, offline |
| Champ de saisie | default, focus, filled, error, disabled, readonly |
| Composant d'état | les états métier, plus hors ligne |

`disabled` mérite une règle propre : un contrôle désactivé **dit pourquoi** au
contact. Et quand une action n'est pas seulement indisponible mais impossible
dans ce contexte, on ne la désactive pas, on la retire. C'est déjà la règle du
bouton caméra d'`ELV-03` : quand la politique du profil l'interdit, le bouton
n'existe pas, il n'est pas grisé. Un bouton visible mais inactif invite à
appuyer dessus, son absence ne pose pas la question.

## 5. La galerie

`/_galerie`, compilée avec `--dart-define=GALERIE=true`, existe déjà. Elle
devient la preuve du catalogue, et non une page de démonstration.

Ce qu'elle doit montrer, pour chaque composant :

1. Tous ses états, côte à côte, nommés.
2. Aux trois largeurs de `05-regles-responsive.md`.
3. En français et en arabe.
4. À 100 % et à 200 % de taille de texte.
5. Avec et sans réduction du mouvement.

Un composant absent de la galerie est un composant dont personne ne peut vérifier
les états sans lancer un écran métier.

## 6. Ce qui se vérifie

- Aucun `Container` avec `decoration` dans `lib/features/` : les surfaces
  viennent de `AppCard` et de `PageShell`.
- Aucun `onTap` nu : tout passe par `Pressable`. **Déjà tenu.**
- Aucun `ElevatedButton`, `TextButton` ni `OutlinedButton` : tout passe par
  `ActionPrincipale`.
- Aucun `showDialog` de confirmation destructive hors de `ConfirmDestructive`.
- Chaque composant du catalogue a une entrée de galerie, vérifiée par un test qui
  compte les entrées et les compare à la liste.
