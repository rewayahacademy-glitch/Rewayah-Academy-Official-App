# UX_REVIEW ILE-SALLE : la pilule de la salle devient une île

Demande du directeur (11/11/2026) : « Il faut faire bon usage de la pilule. Pense à la Dynamic
Island de Apple pour que la pilule donne les meilleures informations lorsqu'on est en classe ou
bien lorsqu'on réduit la classe et qu'on sort, mais que la session continue. [...] l'animation du
ressort liquide [...] de la navbar [...] il faut voir si c'est adapté et tu l'ajoutes, mais en le
réadaptant à la situation. » Ajout du même jour, sur une capture d'élève au téléphone où la pilule
recouvrait le texte du Coran : « la phrase [...] elle reste ouverte ou bien ça se cache après pour
afficher seulement le chrono et le cercle qui se remplit ? ». Décision du pilote, proposition D-007
déjà approuvée par le directeur : l'île se replie.

Disposition `PROPOSITION` confrontée aux référentiels (DESIGN-GOV §4). **Aucune règle métier,
aucun droit, aucun état serveur n'est modifié** : l'île hors de la salle garde exactement les
capacités de l'ancienne barre (micro seulement si le jeton permet de parler, `peutPublier` ; ce
qui « conduit la séance » se lit sur `peutModerer`, la capacité de l'enseignant effectif).

## Ce qui est livré

1. **`IleLiquide`** (`lib/core/widgets/ile_liquide.dart`) : une capsule dont la forme suit son
   contenu. La dimension qui change le plus part sur le ressort raide de la barre de navigation
   (`AppMouvement.ressortGoutteTete`), l'autre suit sur le souple (`ressortGoutteQueue`) : la
   capsule s'étire puis se reforme. Amortissement critique et chaque bord borné entre son départ et
   sa cible : jamais de dépassement. `FonduLiquide` fond un contenu dans le suivant.
2. **L'île de la salle** (`PiluleEtatSalle`) : repliée au repos (le cercle qui se remplit, le temps
   restant, un point d'état, un signe court tant qu'une situation dure, le point neutre de la
   mention) ; dépliée quand une phrase arrive, puis repliée seule.
3. **L'île hors de la salle** (`BarreSeanceEnDirect`) : compacte (« En direct », temps restant,
   micro, chevron) ; dépliée (nom de la Classe, l'état qui se dit, le mot du micro, « Retourner
   dans la salle »).
4. **Le pouls du chrono** (`ChronoVivant`) : le ressort à rebond (`ressortVif`, exception du 10/11)
   est supprimé ; le pouls suit l'effet liquide, sans rebond.

## Délais retenus (et où ils se règlent)

| Délai | Valeur | Jeton |
| :--- | :--- | :--- |
| Une phrase (mot d'état qui change, situation de réseau, cinq dernières minutes, fin prévue) reste dépliée | **6 s** | `AppMouvement.ilePassage` (`lib/core/theme/app_mouvement.dart`) |
| La mention « Visite de contrôle possible. » à l'entrée dans la salle | **10 s** | `AppMouvement.ileMention` |
| Un appui sur l'île repliée la redéplie | 6 s | `AppMouvement.ilePassage` |
| Ce qui empêche d'entendre (lien perdu, reconnexion, échec, hors ligne) | tant que ça dure | `!ConnexionSeance.etablie` |

## Règles et conclusions

| Règle | Source (consultée le 11/11/2026) | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Une activité en cours se montre en trois tailles : minimale, compacte, dépliée ; la compacte ne garde que l'essentiel | Apple HIG, « Live Activities » et « Dynamic Island » (présentations *compact*, *minimal*, *expanded*) | Dans la salle : repliée = cercle + temps restant + point. Hors de la salle : compacte = « En direct » + temps restant + micro ; dépliée = le reste | `PiluleEtatSalle`, `BarreSeanceEnDirect` |
| Une île dépliée ne reste pas ouverte : elle se replie d'elle-même ; une alerte qui exige d'agir reste | Apple HIG, « Live Activities » (la présentation dépliée apparaît sur une mise à jour importante puis revient à la compacte) ; D-007 (passages de 4 à 6 s, appels jusqu'au geste) | 6 s pour une phrase, 10 s pour la mention à l'entrée ; la reconnexion reste dépliée | `ilePassage`, `ileMention` |
| Rien ne recouvre un contenu à lire | Règle du dépôt (`verifierSansChevauchement`) ; capture du directeur du 11/11 (la pilule sur le Coran) | Repliée, l'île de la salle ne prend plus que la largeur du chrono et de deux points ; hors de la salle, l'île est au-dessus de la page, jamais dessus | test `barre_seance_en_direct_test.dart` |
| Un contenu qui change de lui-même doit pouvoir être relu | WCAG 2.2, 2.2.1 (réglage du temps) et 2.2.2 | L'île repliée se redéplie d'un appui (cible de 48, au clavier) ; le lecteur d'écran lit toujours l'état et la mention entiers | `Semantics` sur les signes, `Pressable` |
| Le mouvement déclenché par une interaction se désactive | WCAG 2.2, 2.3.3 ; réglage « réduire les animations » | Même comportement (déplier, replier, délais), sans mouvement : la forme change d'un coup, pas de fondu | `AppMouvement.mouvementReduit`, `AppMouvement.duree` |
| Cible tactile | WCAG 2.2, 2.5.8 (24 au minimum) ; règle du dépôt (48) | L'île repliée fait 36 de haut, sa cible 48 (marge invisible) ; chevron et micro de l'île hors salle : 48 | `ConstrainedBox(minHeight: 48)` autour de l'île |
| Le mouvement exprime un changement d'état, il ne décore pas | Material 3, « Motion » (le mouvement est informatif, centré, expressif) ; Apple HIG, « Motion » (« n'ajoutez pas de mouvement pour le plaisir ») | L'île ne bouge que si son contenu change ; aucune boucle ; au repos, rien ne bouge | aucune respiration au repos |
| Une forme qui change de taille se déforme, puis se pose ; pas de rebond | Décision du directeur du 10/11 (barre de navigation : liquide, sans rebond) ; Material 3 (ressorts amortis) | Deux ressorts critiques, bornés : la capsule s'étire, puis se reforme, jamais au-delà de sa cible | `IleLiquide`, test « sans la dépasser » |
| Le contenu sortant et l'entrant se fondent | SwiftUI `contentTransition` (Dynamic Island) ; Material 3 (« fade through ») | **Fondu et léger glissement, pas de flou** : un flou se recalcule à chaque image, coûte cher sur un téléphone d'entrée de gamme et dans le navigateur, et brouille un texte qu'on doit pouvoir lire jusqu'au bout | `FonduLiquide` |
| Les voisins ne tremblent pas | Nielsen 4 (cohérence) ; Material 3 (pas de saut de mise en page) | La taille de l'île suit sa forme dans un seul sens, sans aller-retour ; le contenu est peint à sa taille finale et découpé par la capsule | test « un seul sens » |
| Un état ne se dit pas par la couleur seule | WCAG 2.2, 1.4.1 ; règle du dépôt | Repliée : disque quand tout va bien, icône d'avertissement sinon, caméra barrée pour l'image coupée ; micro : icône barrée, libellé, et le mot dans l'île dépliée | `PiluleEtatSalle`, `_MicroDeLaBarre` |
| Pas de pression sur l'élève | Children's Code (conception adaptée à l'âge) ; D-003 | Hors de la salle, l'île de l'élève reste sobre et muette ; seule la personne qui conduit la séance voit les teintes, la phrase des cinq dernières minutes et entend le signal | `sobre: !peutModerer`, `sonne: peutModerer` |
| Miroir en arabe | Material 3, « Bidirectionality » ; WCAG 1.3.2 | L'alignement est directionnel ; les chiffres restent de gauche à droite | capture `*_ar.png` |

## L'effet liquide de la barre de navigation est-il adapté à la salle ?

**En partie.** Dans la barre de navigation, la goutte se *déplace* d'un onglet à l'autre ; dans la
salle, rien ne se déplace. Ce qui en est repris, c'est la **mécanique** : deux bords sur deux
ressorts, le premier part, le second suit, la forme s'étire puis se reforme, sans rebond.

- **Où il l'est** : quand l'île change de taille parce que son contenu change (une phrase arrive,
  l'île se replie, la reconnexion commence, l'île hors salle se déplie au chevron). Le mouvement y
  porte un sens : « quelque chose vient de changer ici ».
- **Où il ne l'est pas** : pendant qu'un élève récite, rien ne doit bouger sans raison. Aucune
  respiration, aucune boucle, aucune goutte qui se promène au repos ; les chiffres qui roulent
  restent discrets (une case de chiffre, une fois par seconde, déjà décidé par CHRONO-ETAT). Le
  pont métaballe (pilule vers cercle) n'a pas d'équivalent dans la salle : il n'y a pas deux formes
  à relier, il n'est donc pas repris.
- **Une animation meilleure pour la salle ?** Le fondu entre deux contenus (au lieu d'un
  remplacement sec) est plus utile que tout effet ajouté : il dit qu'une phrase a remplacé une
  autre sans attirer l'œil. Le flou a été écarté (coût, lisibilité).

## Écarts et limites, dits franchement

1. **Le ressort à rebond du chrono est retiré** (`AppMouvement.ressortVif` supprimé). L'exception
   datée du 10/11 dans `docs/current/UX_REVIEW_CHRONO-ETAT.md` (ligne « Un petit élément peut
   dépasser sa cible ») n'est plus vraie ; ce document est hors de ma zone : le pilote doit la
   corriger.
2. **Le nom de la Classe et le temps restant hors de la salle** : `salle_page.dart` confie l'appel
   avec `libelleGroupe: ''` et sans horloge, et `rafraichirHorloge` n'est appelé nulle part. L'île
   lit donc le temps restant dans `bornesSalleProvider` (les mêmes séances que la salle) et le nom
   dans les séances de l'enseignant (`SeanceEnseignant.groupeLibelle`). **Chez l'élève, aucun nom
   de Classe n'est disponible** dans ce que les providers exposent : l'île dépliée dit alors
   « Séance toujours en direct » sans nom. Je n'ai pas touché à `session_persistante.dart`.
3. **Clavier hors de la salle** : le chevron et le micro s'activent au clavier une fois focalisés,
   mais la touche Tab de la page ne sort pas de la portée de focus de sa route, et l'île est posée
   au-dessus du Navigator (structure d'avant ce lot, déjà vraie pour l'ancienne barre). À traiter
   avec un raccourci ou un groupe de parcours commun : décision du pilote.
4. **« Plus de son »** : aucune donnée de la vue ne dit que le son reçu est coupé ; seule la
   connexion (`ConnexionSeance.etablie`) garde l'île dépliée.
5. **La forme courte de la mention** n'existe pas encore comme texte : repliée, la mention se
   réduit à son point neutre (la phrase revient à l'appui) ; aucun nouveau texte de mention n'est
   inventé.
6. **Deux points côte à côte dans l'île repliée** (l'état, vert ; la mention, gris) : la mention
   est un témoin permanent, pas un état ; sa forme reste celle de la mention (point neutre, lu en
   entier au lecteur d'écran). Si le directeur trouve les deux points ambigus, la mention peut
   prendre une forme d'anneau.
7. La page sous l'île, dans les captures, est un texte du Coran composé dans la police du Mushaf,
   pas l'image de la page de Médine (servie par le réseau en séance).

## Ce qui reste à prouver

Essai sur le banc à 6 élèves (téléphone d'entrée de gamme : la forme qui change de taille relance
une mise en page à chaque image pendant environ 300 ms) ; puis le directeur, en production.

Captures : `docs/current/captures/E2E/ile-salle/` (île de la salle dépliée, repliée, image
coupée ; île hors de la salle compacte, dépliée, reconnexion ; 390 et 1440, clair et sombre ; deux
en arabe).
