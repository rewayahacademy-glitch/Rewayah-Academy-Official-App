# COM-CAPT : captures Communications V1

Date : 5 octobre 2026. Étape COM-CAPT (spec §27), après COM-FUS.

## Ce qui a été fait

- Test de capture : `test/capture/communications_capture_test.dart` sur `ui/communications-v1`
  (commit `de2bdb64`), sur l'outil `test/capture/outil_capture.dart`. Il est sauté sans
  `CAPTURE_DIR`, comme les autres tests de capture : la CI ne l'exécute pas.
- Chaque écran est monté sur le **vrai routeur** (`routeurProvider`), dans la **vraie coquille
  du rôle** : tuteur (`/tuteur/...`), enseignant (`/enseignant/...`), admin
  (`/admin/operations/communications/...`, démonstration admin) et Studio (`/admin/studio`, avec
  sa coquille propre). Les données viennent de la démonstration
  (`lib/features/demo/communications/`) et ne sont posées qu'à la racine du test. Aucun port
  réel n'est branché.
- Écrans principaux : 320, 390, 768 et 1440, en clair et en sombre, plus le texte ×2 à 320
  (vrai `textScaler` 2) et l'arabe (RTL) à 390. États clés : 390 et 1440, en clair et en sombre.
- **176 captures** dans `com-v1/` (nom : `com_<écran>_<variante>.png`). Les débordements de
  rendu ne font pas échouer la capture. Ils sont relevés dans `com-v1/com_debordements.txt`.
- Chaque PNG a été lu. La comparaison aux maquettes de `V/` porte **sur la composition
  seulement** : aucun écart de couleur, de police ou de rayon n'est relevé, puisque le thème
  Rewayah prime (K-37).

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état simulé). Une
capture ne prouve ni qu'un service est branché, ni qu'un parcours fonctionne.

## Écrans capturés

| Écran | Rôle, coquille | Route ou geste | Variantes |
| :--- | :--- | :--- | :--- |
| messages_liste_tuteur | tuteur | `/tuteur/messages` | 8 + ×2 + RTL |
| messages_fil_tuteur | tuteur | `/tuteur/messages/fil-adam` | 8 + ×2 + RTL |
| messages_fil_contexte_enseignant | enseignant | `/enseignant/messages/fil-yasmine` | 8 + ×2 + RTL |
| messages_hors_ligne_tuteur | tuteur | fil, hors ligne | 4 |
| messages_vide_tuteur | tuteur | liste sans fil | 4 |
| vocal_enregistrement_tuteur | tuteur | fil, « Enregistrer » touché, 0:12 | 4 |
| vocal_pre_ecoute_tuteur | tuteur | fil, enregistrement puis « Arrêter » | 4 |
| vocal_micro_refuse_tuteur | tuteur | fil, micro refusé | 4 |
| communaute_flux | enseignant | `/enseignant/communaute` | 8 + ×2 + RTL |
| communaute_publication | enseignant | `/enseignant/communaute/pub-memorisation` | 8 + ×2 + RTL |
| communaute_garde_bloque | enseignant | publication d'un lien affilié | 4 |
| communaute_garde_averti | enseignant | publication d'une publicité | 4 |
| communaute_signalement | enseignant | menu, « Signaler », motif Publicité | 4 |
| communaute_vide | enseignant | aucune publication | 4 |
| communaute_hors_ligne | enseignant | hors ligne | 4 |
| studio_aujourdhui | admin, Studio | `/admin/studio` | 8 + ×2 + RTL |
| studio_canal | admin, Studio | `/admin/studio/canaux/organisation` | 8 + ×2 + RTL |
| studio_focus | admin, Studio | canal, « Mode focus » | 4 |
| studio_hors_ligne | admin, Studio | canal, hors ligne | 4 |
| studio_aujourdhui_vide | admin, Studio | Aujourd'hui vide | 4 |
| notifications_tuteur | tuteur | `/tuteur/notifications` | 8 + ×2 + RTL |
| notifications_enseignant | enseignant | `/enseignant/notifications` | 4 |
| annonce_classe_tuteur | tuteur | `/tuteur/classes/classe-a` | 8 + ×2 + RTL |
| admin_annonces | admin | `.../communications/annonces` | 8 + ×2 + RTL |
| admin_moderation | admin | `.../communications/moderation` | 8 + ×2 + RTL |
| admin_messages | admin | `.../communications/messages/fil-mission` | 8 + ×2 + RTL |

## Contrôles transverses

- **Rôle et coquille** : aucune coquille tuteur hors du rôle tuteur. Côté enseignant, Classes
  est actif dans Messages et Aujourd'hui dans la Communauté (raccourci, Q2). Côté admin,
  Opérations est actif, avec les onglets Annonces, Modération et Messages, sans 9e domaine (Q4),
  et l'identité « Administrateur ». Le Studio a sa propre coquille (Aujourd'hui, Canaux,
  Éléments enregistrés, Brouillons) et reste réservé à l'admin (Q1). Cloches visibles pour le
  tuteur, l'enseignant et l'admin (Q5). Aucune capture d'élève mineur.
- **Navigation** : retour explicite partout. La barre basse du Studio disparaît dans un canal
  et en Focus. En Focus, la navigation, la liste et le contexte disparaissent.
- **Cartes groupées** : listes de fils, notifications, Aujourd'hui du Studio, annonces et file
  de modération sont en cartes groupées à séparateurs, conformes.
- **Débordements mesurés** (texte ×2 à 320) : fil tuteur (69 et 129 px), fil enseignant
  (21 px), fil admin (80 px), canal du Studio (72 px). Aucun ailleurs.

## Relevé écran par écran

Légende : D = débordement, T = texte coupé, C = colonne vide, R = rôle ou coquille faux,
E = écart de composition. « RAS » : rien à relever.

### Messages métier (COM-M01, COM-W01)

- **Liste (tuteur)** : coquille correcte. E : à 1440, la colonne des fils est étroite
  (~256 px). Les noms tiennent sur 3 lignes, les extraits sur 4 à 5 lignes, et le champ
  « Rechercher une conve… » est tronqué. Sans fil ouvert, la colonne du fil affiche
  « Choisissez une conversation » : ce n'est pas une colonne vide. 320×2 : RAS (la liste
  défile).
- **Fil (tuteur)** : la composition à 1440 (`Navigation | Fils | Fil | Contexte`) est conforme.
  E : aucune gouttière entre la colonne des fils et le fil à 768 et 1440 : l'avatar de l'en-tête
  et les bulles touchent le filet. E : la pièce jointe d'un message apparaît en texte dans la
  bulle (« Pièce jointe : Devoir_semaine_3.pdf »), sans carte fichier, alors que la maquette
  montre une carte PDF dans le fil. La carte n'existe que dans le panneau Contexte. E : à 390,
  l'en-tête du fil et le bouton (i), sur une ligne à part, ne laissent que ~300 pt aux
  messages, et ~100 pt à 320. **D, T : à 320×2, l'en-tête du fil occupe tout l'écran. Aucun
  message ni composer n'est visible (débordements de 69 et 129 px).**
- **Fil avec contexte (enseignant)** : l'objet inaccessible est bien signalé (« Vous n'avez plus
  accès à cet objet »). Même absence de gouttière. **D : à 320×2, le composer est coupé sous la
  barre (21 px) et aucun message n'est visible.**
- **Hors ligne** : E : **deux bandeaux** à la fois, à 390 comme à 1440 : celui de la coquille
  (« Pas de réseau… ») et celui de la page (« Vous êtes hors ligne… »). À 390, la zone des
  messages tombe à ~200 pt.
- **Vide** : RAS (carte d'état, aucune colonne vide à 1440).
- **RTL** : le miroir est correct. T : en arabe, les dates des bulles restent en français
  (« Dimanche 4 octobre, 09:52 »).

### Message vocal (COM-VOC-1)

- Les états enregistrement (0:12 sur 3:00, Arrêter, Pause), pré-écoute (Durée, Écouter,
  Supprimer, Envoyer) et micro refusé (phrase exacte, Fermer) sont présents.
- E : à 390, le panneau vocal s'empile sous le composer texte. En pré-écoute, la zone des
  messages tombe à ~10 pt (le nom de l'auteur est coupé), et deux boutons « Envoyer » sont
  visibles en même temps (texte et vocal).
- E : même en démonstration, le vocal reçu affiche « La lecture n'est pas encore disponible
  ici ».
- E (composition) : on entre dans le vocal par un lien texte sous le champ, et non par un
  bouton micro dans la barre du composer comme sur la maquette. Pas de forme d'onde (elle
  n'est pas requise, spec §24).

### Communauté enseignants (COM-M02, COM-W02)

- **Flux** : coquille enseignant, Aujourd'hui actif (Q2). La composition à 1440
  (`Navigation | Flux | Publication | Aide et règles`) est conforme. E : sans publication
  ouverte, la colonne centrale ne porte qu'une carte « Aucune publication ouverte », en haut.
  E : la colonne du flux est étroite (~240 px) et la ligne auteur passe sur 2 lignes
  (« Classe An-/Nour »). E : « Nouvelle publication » est en bas de la colonne du flux, alors
  que la maquette le place dans l'en-tête. Les catégories sont en onglets à 1440 et en menu
  déroulant à 390 et 768. 320×2 : l'en-tête, le bandeau des règles et le filtre occupent tout
  le premier écran (la page défile).
- **Publication** : RAS à 1440 (réponses, composer de réponse, règles). E : le menu « … » est
  collé au nom de l'auteur au lieu d'être au bord droit de la carte.
- **Garde bloqué / averti** : textes canoniques, motif, liens avec leurs quatre états, jamais
  « Vérifié ». E : à 1440, le verdict fait défiler le haut du composer hors de la vue (titre et
  catégorie). E : à 390, les boutons (i) et (×) sont empilés et presque jointifs au-dessus de
  « Nouvelle publication ».
- **Signalement** : feuille basse à 390, dialogue à 1440, motif choisi. RAS.
- **Vide** : E : à 1440, deux cartes d'état côte à côte, « Aucune publication » dans le flux et
  « Aucune publication ouverte » au centre : le message est redondant.
- **Hors ligne** : seul le bandeau global s'affiche, et le contenu déjà lu reste. RAS.

### Le Studio (COM-M03, COM-M04, COM-M05, COM-W00, COM-W03, COM-W03F)

- **Aujourd'hui** : les 4 indicateurs et les 3 colonnes sont conformes à COM-W00. R/E : **la
  coquille du Studio n'affiche ni identité ni rôle**, alors que la spec W03 demande l'identité
  d'un membre de l'équipe interne et que la maquette montre nom et fonction dans l'en-tête. Pas
  de cloche non plus. **T : à 320×2, un libellé d'indicateur est coupé au milieu des mots
  (« Mentio/ns et ré/ponses »).**
- **Canal** : la composition à 1440 (`Navigation | Canaux | Fil | À propos du canal`) est
  conforme. E : le titre du canal et les bulles touchent le filet de la liste (pas de
  gouttière). E : la pièce jointe apparaît en texte dans la bulle, comme dans Messages.
  E : « Mode focus » est un lien centré sous le titre, alors que la maquette en fait une action
  d'en-tête. E : à 390, l'en-tête du Studio, le bouton (i), le titre et « Mode focus » prennent
  ~40 % de l'écran. **D : à 320×2, les en-têtes du Studio et du canal remplissent l'écran.
  Aucun message ni composer n'est visible (72 px).**
- **Focus** : navigation, liste et contexte retirés, fil centré, composer et sortie présents :
  conforme (§10, §23). E : à 1440, trois alignements différents : le bandeau de sortie est calé
  à gauche (x≈152), « Quitter le focus » est centré, et le fil est centré entre x≈320 et 1008.
  La rangée du composer (« Envoyer ») dépasse la largeur du fil.
- **Hors ligne** : E : double bandeau (global et page), comme dans Messages.
- **Aujourd'hui vide** : « Rien à traiter pour le moment », Brouillons vide, Accès rapides.
  RAS.

### Notifications et annonce de Classe (COM-M06, COM-ANN-1)

- **Centre (tuteur)** : la cloche est active dans l'en-tête. À 1440, liste et détail
  (« Choisissez une notification »), avec les onglets Toutes, Non lues, Mentions et Action
  requise ; menu déroulant à 390. E : à 390, la colonne date prend ~40 % de la largeur et les
  titres passent sur 3 à 4 lignes. **T : à 320×2, des mots sont coupés au milieu (« La
  séa/nce », « annulé/e », « Change/ment »).**
- **Centre (enseignant)** : la notification « Message de la famille de Yasmine » n'a pas de
  chevron : elle ne mène pas au fil.
- **Annonce de Classe (tuteur)** : la carte est complète (À lire, titre, auteur et date,
  extrait, « Marquer comme lue », « Lire l'annonce en entier »). E : l'annonce est posée en
  tête de la page Classe, avant la carte de la Classe et la séance (salle ouverte, cours dans
  10 min). Le libellé « Classe An-Nour » dans « Classe fictive A » vient des fixtures du test :
  ce n'est pas un défaut.

### Administration des communications (COM-W04, COM-ANN-2, COM-MSG-2)

- **Annonces** : coquille admin réelle. Indicateurs, annonces publiées et planifiées, règles de
  portée (les 5 lignes de la spec §13.4, marquées Démonstration). E : la page s'intitule
  « Communications », alors que la maquette et la route disent « Administration des
  communications ». La pastille « Démonstration » est répétée 4 fois.
- **Modération** : composition à 1440 `File | Signalement | Politique anti-promotion`.
  **T : le titre du panneau est coupé en « Politique anti-/promotion ».** E : la file est
  étroite (~240 px), et la colonne centrale est vide en dehors de la carte d'invite.
- **Messages** : la composition à 1440 (`Fils | Fil | Contexte`, contrôleur et mission) est
  conforme. **D, T : à 320×2, le titre de page est coupé au milieu du mot
  (« Communicatio/ns »), l'en-tête du fil remplit l'écran et le débordement atteint 80 px.**

### Hors périmètre COM, vu en passant

- En RTL, les libellés de la navigation des coquilles tuteur et enseignant restent en
  français, de même que le champ « Rechercher un écran » de la coquille admin.

## Défauts transmis à COM-R et COM-RC

**14 défauts numérotés** (et non 15, chiffre corrigé après la revue COM-R, R-28), puis les
écarts relevés dans le corps du rapport qui n'y étaient pas reportés.

1. Texte ×2 à 320 : l'en-tête du fil ne défile pas et masque messages et composer (Messages
   tuteur, enseignant et admin, canal du Studio), avec des débordements de 21 à 129 px.
2. Texte ×2 à 320 : mots coupés au milieu (indicateurs du Studio, titre admin
   « Communications », notifications).
3. Double bandeau hors ligne (coquille et page) dans Messages et dans le Studio.
4. Pas de gouttière entre la colonne liste et le fil (Messages, Studio) à 768 et 1440.
5. Pièce jointe d'un message rendue en texte dans la bulle (Messages, Studio).
6. Vocal à 390 : le panneau empilé écrase le fil et deux « Envoyer » sont visibles. Le vocal
   reçu n'est jamais lisible en démonstration.
7. Studio : aucune identité ni rôle dans sa coquille.
8. Focus à 1440 : bandeau de sortie, bouton et fil mal alignés, composer plus large que le fil.
9. Communauté à 1440 : flux étroit, colonne centrale presque vide sans publication, double état
   vide. Menu « … » mal placé. Le verdict du garde fait défiler le haut du composer. Boutons
   (i) et (×) empilés à 390.
10. Modération : titre « Politique anti-/promotion » coupé, file étroite.
11. Notifications : colonne date trop large sur téléphone. Notification de message sans
    destination (enseignant).
12. RTL : dates des bulles non localisées.
13. Annonce de Classe placée avant la séance sur la page Classe du tuteur.
14. Titre « Communications » au lieu de « Administration des communications ».

Écarts du corps du rapport, absents de la liste d'origine (ajoutés à COM-RC, R-28) :

- Fil à 390 et 320 en texte ×1 : l'en-tête du fil et (i) ne laissent qu'environ 300 pt (390)
  et 100 pt (320) aux messages (repris en R-02).
- Messages à 1440 : colonne des fils étroite (~256 px), « Rechercher une conve… » tronqué
  (repris en R-10).
- Studio : « Mode focus » est un lien centré sous le titre, pas une action d'en-tête (repris
  en R-12).
- Vocal : on y entre par un lien texte sous le champ, et non par un bouton micro (composition,
  rattaché à R-04).
- Administration : la pastille « Démonstration » est répétée quatre fois (repris en R-15).
- RTL, hors périmètre COM : la navigation des coquilles tuteur et enseignant, et le champ
  « Rechercher un écran » de la coquille admin, restent en français.
