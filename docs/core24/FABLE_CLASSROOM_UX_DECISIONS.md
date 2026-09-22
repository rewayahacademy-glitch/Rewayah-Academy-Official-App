# FABLE_CLASSROOM_UX_DECISIONS — les choix du lot 2, et pourquoi

Priorité appliquée : sécurité/RLS > métier > contrats backend > Teaching Core > Bible V2 > prompt du lot.
Chaque décision nomme la règle, l'alternative écartée et la portée.

## D-L2-01 · Une seule coque : `ClasseLivePage` derrière `/salle` et `/tc/classe`
- **Règle** : Bible §3 bis (un seul système de navigation), §19 (sous-systèmes), prompt §5 (« langage visuel commun »).
- **Fait** : `/salle` (billet, ADR-005) rend `EntreeSalle` → `ClasseLivePage`. Le billet gagne trois champs facultatifs (`groupeId`, `libelleGroupe`, `enseignantPrenom`) que les quatre points d'entrée remplissent avec ce qu'ils ont déjà. `SallePage`, `salle_enseignant/` et leurs tests sont retirés : deux coques étaient le défaut, pas une redondance utile.
- **Écarté** : garder l'ancienne coque pour l'élève et n'enrichir que la nouvelle — l'élève n'aurait jamais vu le Coran (audit A5).
- **Portée** : `groupeId` et `enseignant` deviennent nullables dans `ContexteClasseLive`/`SessionLiveVM`/`SessionEnCours` : un contrôleur ou un tuteur entre par une séance, pas par un groupe. Sans groupe, pas d'outil « Révision » (il faut un groupe pour poser un travail) et la Bibliothèque ne montre pas de section « Ce groupe ».

## D-L2-02 · Le protocole partagé est `SharedContentState`, transporté par la primitive existante
- **Règle** : prompt §3 (« aucun second protocole »), §7 (« aucun second protocole de synchronisation »), doc de l'adaptateur (« seul ce fichier changera »).
- **Fait** : `AdaptateurTransportLiveKit` envoie par `moteur.publierDonnees` et lit `moteur.donneesRecues` ; canal éphémère = suffixe `-l` du sujet (convention déjà écrite dans le socle). Le transport se déclare `complet`. `portTransportDonneesProvider` dérive du `AccesSalle` de la session persistante : hors salle, `TransportIndisponible` comme avant.
- **Écarté** : faire passer le nouveau protocole par `presenterContenu` (perte silencieuse du mode, de la plage, du masquage) — nommé comme faute par F.
- **Non fait** : `ContenuPresente` (protocole du socle) n'est plus émis par aucun écran ; il reste dans le socle, non modifié.

## D-L2-03 · Late join sans persistance serveur : l'enseignant republie à l'arrivée d'un participant
- **Règle** : prompt §9 (« restauration après reconnexion »), §14 (aucun heartbeat concurrent), contrat F (`CauseRevision.restauration`).
- **Fait** : quand la liste des participants gagne une identité et qu'un support est présenté, le client qui **peut piloter** publie l'état courant tel quel (révision +1, cause `restauration`, débouncé 600 ms). Ce n'est pas un rejeu de journal ni une présence : c'est une révision complète, comme toutes les autres.
- **Écarté** : écrire `EtatPartageSupabase` maintenant — `resource_id` uuid vers `library_resource` vide ; l'écriture échouerait sur le seul support existant (le Coran). Demandé à Astra.
- **Limite dite à l'écran** : si l'enseignant n'est pas connecté quand quelqu'un arrive, l'arrivant lit « aucun support présenté » jusqu'au prochain geste, jamais un état inventé.

## D-L2-04 · Le Coran est la surface, le chrome est en dessous
- **Règle** : prompt §7, Bible §22 (`CONTENT > CHROME`), §26 (niveau 1 : page précédente/suivante, aller à, focus).
- **Fait** : `SupportCoranClasse` = le renderer C tel quel (page / verset agrandi / focus selon le mode partagé) + une ligne de repère (sourate · page · juz) + une rangée basse : précédent / aller à / suivant (pilote), mode (pilote), zoom (chacun, en mode verset/focus seulement). Rien ne flotte sur le texte ; le dock est hébergé par `HoteDuDock`, qui réserve sa place.
- **Élève** : suit automatiquement (D-21 : `fusionnerPartage`). Il peut feuilleter (le geste existe) ; s'il s'éloigne de la page présentée, une bande discrète « Revenir à la page du professeur » apparaît **seulement dans ce cas** (Bible §25), jamais en permanence (prompt §5).
- **Zoom** : personnel, jamais transmis (D-21). En mode page, la géométrie est celle du cadre : pas de zoom, et c'est dit.

## D-L2-05 · Sélection d'un verset par tap, en classe seulement
- **Règle** : prompt §10 (Focus a besoin d'un objet), §7 (ne pas redessiner le renderer).
- **Fait** : `PorteeSelectionVerset` (InheritedWidget) posé par la classe autour du support ; `ParagrapheVersets` et `BlocVerset` n'attachent un reconnaisseur de tap que sous cette portée. Le verset sélectionné se dit par un lavis **et** par la sémantique « sélectionné », jamais par la couleur seule. Hors classe, rien ne change.
- **Écarté** : sélection par `SelectionArea` (sélection de texte, pas d'ayah) ; menu contextuel.

## D-L2-06 · Le dock ne déclare que ce que l'hôte rend
- **Règle** : `lib/CLAUDE.md` (un bouton qui ne peut pas aboutir n'est pas rendu), prompt §10 (« outil actif très clair »), §17 (pas de dizaines d'icônes).
- **Fait** : l'hôte (`HoteDockClasse`) projette les capacités du jeton mais **retire** `peutPiloterSupport`/`peutAnnoter` pour le dock, parce que le Mushaf ne rend ni masquage, ni pointeur, ni traits. Il reste : Bibliothèque, Focus (sur sélection). Le pilotage réel (page, mode, support) passe par la rangée basse du support, pas par le dock.
- `ponytail:` plafond connu — le jour où le renderer rend le masquage (mode verset : verset remplacé par un bloc sémantique « verset masqué ») et le pointeur, l'hôte rendra les capacités du jeton telles quelles. Aucun autre fichier ne change.

## D-L2-07 · Commandes rondes, états de périphérique distincts
- **Règle** : prompt §12, Bible §34, invariant J7 (un mot, jamais une couleur seule).
- **Fait** : `CommandeRonde` (cercle + icône + mot court + acte lu) reprise de l'ancienne coque. `EtatPeripherique` = fonction pure : `absent` (pré-vol), `permissionRefusee` (pré-vol), `enCours` (réglage en attente), `erreur` (le moteur a levé), `ferme`/`ouvert` (liste des participants). Un périphérique absent ou refusé est **rendu inerte avec son mot**, pas caché : ce n'est pas une limite de droit (qui, elle, cache), c'est une panne locale.
- **Réseau** : seuls « instable » et « perdu » se disent en bas ; l'en-tête garde les cinq mots du lien.

## D-L2-08 · Composition par gabarit et par hauteur
- **Règle** : prompt §6, Bible §15/§20.
- Mobile portrait : support plein, vignette vidéo en **bande horizontale sous le support** (hauteur fixe `respiration × 1.5`), roster en feuille, commandes en bas.
- Mobile paysage / hauteur courte (< 500 pt) : support + bande vidéo en colonne étroite à droite, roster en feuille (`VueClasseLive.hauteurCourte`).
- Tablette : support (3) + bande (1), roster en colonne si le rôle le voit.
- Desktop : roster | support | bande | (Bibliothèque en panneau, Échap ferme). Aucune feuille mobile.
- Sans support : la scène vidéo prend la place, à tous les gabarits, aucun cadre vide.

## D-L2-09 · Sortie
- **Règle** : prompt §15, Bible §35.
- **Fait** : confirmation (existante) ; la coque rend `SortieClasse(role, aEteEnSalle)` ; la route envoie l'enseignant qui a réellement tenu le cours au cahier (`Routes.cahierPour`), tous les autres à la racine de leur rôle. `routes_tc_a` renvoie à l'Espace Groupe.

## D-L2-10 · Ce qui n'a pas été fait, et pourquoi
- Masquage/pointeur/stylet rendus sur le Mushaf : hors lot (nouveau rendu d'annotation = §24).
- Adaptateurs Supabase catalogue/groupes/état partagé : backend/intégration → contrat Astra.
- CTA d'entrée dans le pré-cours : l'écran précédent porte déjà « Rejoindre » ; ajouter un second clic serait un formulaire.
- Observation tuteur par `/tc/observation` : bascule différée sans `0037` (mémoire 21/09), inchangé.
