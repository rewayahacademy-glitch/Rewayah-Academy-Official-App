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

## Après COM-RC

Date : 5 octobre 2026. Captures refaites sur `ui/communications-v1` @ `1aa1ffd6` (COM-RC lots A,
B et C, plus un état ajouté au test de capture : `communaute_reponse_bloquee`, la réponse
retenue par la garde, R-01). **180 captures** dans `com-v1/`, qui remplacent les 176 de
`de2bdb64`. **Aucun débordement de rendu** n'est relevé : `com_debordements.txt` n'est plus
produit (il en comptait cinq à 320×2). Chaque PNG cité ci-dessous a été lu.

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état de
démonstration). Rien n'est branché, rien n'est testé sur staging, rien n'est déployé.

### Défauts de la revue COM-R, à l'image

| Défaut | Verdict | Capture qui le prouve |
| :--- | :--- | :--- |
| R-01 Réponse hors garde anti-promotion | corrigé : « Réponse bloquée », motif « Lien affilié », lien marqué « Lien commercial interdit » sous « Envoyer la réponse » | `com_communaute_reponse_bloquee_390_clair.png`, `..._1440_clair.png` |
| R-02 Fil à 320×2 sans message ni composer | corrigé pour Messages tuteur et enseignant : l'en-tête du fil défile, messages et champ « Message » visibles | `com_messages_fil_tuteur_320x2_clair.png`, `com_messages_fil_contexte_enseignant_320x2_clair.png` |
| R-02 (suite) Canal du Studio à 320×2 | **restant** : les messages sont visibles, mais la tête de page « Le Studio / Espace de travail de l'équipe » reste fixe et occupe ~60 % de l'écran ; le composer n'est pas visible au premier écran | `com_studio_canal_320x2_clair.png` |
| R-02 (suite) Messages admin à 320×2 | **restant, partiel** : un message est visible, le composer n'apparaît qu'en bord bas ; le titre de page et le menu d'onglets prennent la moitié de l'écran | `com_admin_messages_320x2_clair.png` |
| R-02 (suite) Liste à 390 et 320 en texte ×1 | corrigé : à 320, l'en-tête défile et le fil garde ~500 pt ; à 390, ~350 pt même avec le panneau vocal | `com_messages_fil_tuteur_320_clair.png`, `com_vocal_pre_ecoute_tuteur_390_clair.png` |
| R-03 Double bandeau hors ligne | **restant** (attend D-FUS-3) : « Pas de réseau… l'envoi attendra » et « Vous êtes hors ligne… » ensemble | `com_messages_hors_ligne_tuteur_390_clair.png`, `com_studio_hors_ligne_390_clair.png` |
| R-04 Vocal à 390, deux « Envoyer » | corrigé : en pré-écoute, le panneau vocal remplace la rangée texte, un seul « Envoyer » | `com_vocal_pre_ecoute_tuteur_390_clair.png`, `..._1440_clair.png` |
| R-04 (suite) Vocal reçu illisible en démo | corrigé : le vocal reçu porte « Écouter » (Messages et canal) | `com_messages_fil_tuteur_1440_clair.png`, `com_studio_canal_1440_clair.png` |
| R-05 Studio sans identité, cloche ni bascule | corrigé : cloche, « Mon compte », bascule clair / sombre (≥ 600) et « Administrateur » dans la navigation | `com_studio_aujourdhui_1440_clair.png`, `com_studio_aujourdhui_390_clair.png`, `com_studio_canal_768_sombre.png` |
| R-06 Notification inerte, « Action requise » sans action | corrigé : « Message de la famille de Yasmine » et « Votre planning… a changé » ont leur chevron | `com_notifications_enseignant_390_clair.png` |
| R-08 Dates en français en arabe, mal ordonnées | **restant** (attend D-FUS-1) : « Dimanche 4 octobre » dans les bulles, « oct. 4 2026 » dans les notifications | `com_messages_fil_tuteur_390_rtl_clair.png`, `com_notifications_tuteur_390_rtl_clair.png` |
| R-09 Mots coupés à 320×2 | corrigé pour les notifications (date au-dessus du titre) et les indicateurs (un par rangée) | `com_notifications_tuteur_320x2_clair.png`, `com_studio_aujourdhui_320x2_clair.png` |
| R-09 (suite) Titre de l'administration à 320×2 | **restant** : « communication/s » coupé au milieu du mot ; le repli sur l'onglet ne se déclenche pas | `com_admin_annonces_320x2_clair.png`, `com_admin_moderation_320x2_clair.png`, `com_admin_messages_320x2_clair.png` |
| R-10 Colonnes à 256 px, pas de gouttière | corrigé : liste à ~336 px à 1440 (« Rechercher une conversation » entier), file de modération ~326 px, retrait après le filet | `com_messages_liste_tuteur_1440_clair.png`, `com_messages_fil_tuteur_1440_clair.png`, `com_admin_moderation_1440_clair.png` |
| R-10 (suite) Champs de recherche | **restant, mineur** : « Rechercher une public… » (Communauté, 1440) et « Rechercher une conve… », « Rechercher dans Le St… » (768) restent tronqués | `com_communaute_flux_1440_clair.png`, `com_messages_fil_tuteur_768_clair.png`, `com_studio_canal_768_sombre.png` |
| R-11 Pièce jointe en texte | corrigé : carte PDF (nom, taille, « Envoyé ») dans la bulle | `com_messages_fil_tuteur_1440_clair.png`, `com_studio_focus_1440_clair.png` |
| R-12 Focus à 1440 mal aligné | **corrigé en partie** : le bandeau « Le Studio, Focus activé » est aligné sur le fil ; « Quitter le focus » reste centré (Center d'ActionPrincipale non touché, à valider) et la rangée du composer (« Envoyer ») dépasse encore le fil d'environ 110 px | `com_studio_focus_1440_clair.png` |
| R-12 (suite) « Mode focus » en lien centré | **restant** (même cause) | `com_studio_canal_1440_clair.png`, `com_studio_canal_320_clair.png` |
| R-13 Menu « … » collé au nom, double état vide | corrigé : menu au bord de fin ; un seul état vide (« Aucune publication ») | `com_communaute_publication_390_clair.png`, `com_communaute_vide_1440_clair.png` |
| R-14 Majuscules en milieu de phrase | corrigé : « Enseignante, Classe An-Nour · Il y a 2 h », « Échéance le mardi 6 octobre » | `com_communaute_flux_1440_clair.png`, `com_studio_aujourdhui_1440_clair.png` |
| R-15 Titre « Communications », pastille ×4 | corrigé : « Administration des communications », une seule pastille « Démonstration » | `com_admin_annonces_1440_clair.png` |
| R-16 Annonce avant la séance | **restant** (arbitrage du directeur) | `com_annonce_classe_tuteur_390_clair.png` |

Les constats R-17 à R-26 (hors R-24 pour le fil) ne se voient pas sur une capture : ils sont
couverts par les tests de contre-preuve de COM-RC, et non par cette recette.

### Défauts COM-CAPT d'origine, hors revue

- Garde à 390 : (i) et (×) restent empilés au-dessus de « Nouvelle publication » : **restant**
  (`com_communaute_garde_bloque_390_clair.png`).
- « Politique anti-/promotion » à 1440 : coupure au trait d'union, légitime : **inchangé**
  (`com_admin_moderation_1440_clair.png`).
- Vocal ouvert par un lien sous le champ, et non par un bouton micro : **restant**
  (`com_messages_fil_tuteur_1440_clair.png`).
- Navigation des coquilles en français en RTL : **restant**, hors périmètre COM
  (`com_messages_fil_tuteur_390_rtl_clair.png`).

### Défauts nouveaux

1. **Studio, Aujourd'hui à 320×2** : le titre est coupé au milieu du mot (« Aujourd'hu/i »).
   Le bouton « Mon compte », ajouté par R-05, réduit la largeur du titre
   (`com_studio_aujourdhui_320x2_clair.png`).
2. **Publication de la Communauté à 320×2** : tête de page, (i) et ligne auteur restent fixes et
   remplissent l'écran. Ni le texte de la publication ni le composer de réponse ne sont visibles
   au premier écran (`com_communaute_publication_320x2_clair.png`). À 390, le composer de
   réponse et la garde restent fixes sous la publication et ne lui laissent qu'environ 230 pt
   (`com_communaute_publication_390_clair.png`).
3. **Nom de fichier coupé dans la carte** : « Devoir_semaine_3.pd/f » à 768
   (`com_messages_fil_tuteur_768_clair.png`), « Devoir_semaine/_3.pdf » à 320. Préférer une
   ellipse au milieu du nom ou une coupure avant l'extension.
4. **Réponse bloquée à 1440** : le haut du composer de réponse sort de la vue au profit du
   verdict, et le lien « Enregistrer la publication » flotte au-dessus du champ
   (`com_communaute_reponse_bloquee_1440_clair.png`).

### Bilan

- Corrigés à l'image : R-01, R-04, R-05, R-06, R-11, R-13, R-14, R-15, R-02 (Messages tuteur et
  enseignant), R-09 (notifications et indicateurs), R-10 (colonnes et gouttière).
- Restants : R-02 (canal du Studio et Messages admin à 320×2), R-03 (D-FUS-3), R-08 (D-FUS-1),
  R-09 (titre de l'administration), R-12 (en partie), R-16 (arbitrage), recherches tronquées.
- Nouveaux : 4 (ci-dessus).

## Après COM-RC tour 2

Date : 5 octobre 2026. Captures refaites sur `ui/communications-v1` @ `e0b9f890` : COM-RC
tour 2, lots D (Studio, Messages admin, socle) et E (Communauté), à `70540698`, plus un cas
ajouté au test de capture, `communaute_publication_composer` (la publication défilée jusqu'au
composer de réponse, à 320×2, 390 clair, sombre et arabe, 1440 clair et sombre).
**186 captures** dans `com-v1/`, qui remplacent les 180 de `1aa1ffd6`. **Aucun débordement de
rendu** : `com_debordements.txt` n'est pas produit. Chaque PNG cité ci-dessous a été lu.

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état de
démonstration). Rien n'est branché, rien n'est testé sur staging, rien n'est déployé.

### Restes du tour 1, à l'image

| Reste | Verdict | Capture qui le prouve |
| :--- | :--- | :--- |
| R-02 Canal du Studio à 320×2 | corrigé : la tête « Le Studio » défile ; les deux derniers messages et le champ « Message » sont au premier écran | `com_studio_canal_320x2_clair.png` |
| R-02 Messages admin à 320×2 | corrigé : titre et onglets défilent ; fin du dernier message et champ « Message » au premier écran | `com_admin_messages_320x2_clair.png` |
| R-09 Titre de l'administration à 320×2 | corrigé : l'en-tête s'empile (retour et cloche au-dessus), « Administration des communications » sans mot coupé | `com_admin_annonces_320x2_clair.png`, `com_admin_moderation_320x2_clair.png` |
| Studio, « Aujourd'hu/i » à 320×2 | corrigé : « Aujourd'hui » entier, l'en-tête s'empile sous retour, compte et cloche | `com_studio_aujourdhui_320x2_clair.png` |
| R-01 Publication à 390 | corrigé : texte entier, catégorie « Pédagogie » et « Enregistrer la publication » au premier écran, puis « Réponses (2) » | `com_communaute_publication_390_clair.png`, `..._390_sombre.png` |
| R-01 Publication à 320×2 | corrigé en partie : titre et début du texte de la publication au premier écran ; le composer de réponse, placé après les réponses, s'atteint en défilant | `com_communaute_publication_320x2_clair.png`, `com_communaute_publication_composer_320x2_clair.png` |
| R-01 Réponse bloquée à 1440 | corrigé : champ « Votre réponse » entier avec son libellé, « Envoyer la réponse » puis le verdict ; plus de lien flottant au-dessus du champ | `com_communaute_reponse_bloquee_1440_clair.png` |
| R-11 Nom de fichier coupé | corrigé : ellipse au milieu, extension gardée (« Devoir_sema…e_3.pdf » à 768, « Devoir_semaine_3.pdf » entier à 390) | `com_messages_fil_tuteur_768_clair.png`, `com_messages_hors_ligne_tuteur_390_clair.png` |
| (i) et (×) empilés à 390 | corrigé : côte à côte dans l'en-tête « Nouvelle publication » | `com_communaute_garde_bloque_390_clair.png` |
| Recherches tronquées | corrigé : « Rechercher une publication » entier à 1440 ; à 768, libellé au-dessus du champ (« Rechercher une conversation », « Rechercher dans Le Studio ») et indication sur deux lignes | `com_communaute_flux_1440_clair.png`, `com_messages_fil_tuteur_768_clair.png`, `com_studio_canal_768_clair.png` |
| R-12 Focus à 1440 | **restant** : « Quitter le focus » reste centré, et « Envoyer » dépasse toujours le fil d'environ 110 px (bulles de 320 à 1007, bouton jusqu'à ~1120). La lecture du tour 1, « erreur de lecture », n'est pas confirmée par l'image | `com_studio_focus_1440_clair.png` |
| R-12 « Mode focus » centré | **restant** (Center d'ActionPrincipale, décision du directeur) | `com_studio_canal_768_clair.png`, `com_studio_canal_320_clair.png` |
| R-03 Double bandeau hors ligne | **restant** (attend D-FUS-3) | `com_messages_hors_ligne_tuteur_390_clair.png`, `com_studio_hors_ligne_390_clair.png` |
| R-08 Dates en français en arabe | **restant** (attend D-FUS-1) : « oct. 4 2026 » dans les notifications, « Dimanche 4 octobre » dans le Studio | `com_notifications_tuteur_390_rtl_clair.png`, `com_studio_aujourdhui_390_rtl_clair.png` |
| R-16 Annonce avant la séance | **restant** (arbitrage du directeur) | `com_annonce_classe_tuteur_390_clair.png` |
| Vocal ouvert par un lien | **restant** : « Enregistrer un message vocal » sous le champ | `com_studio_canal_320_clair.png` |
| Navigation des coquilles en français en RTL | **restant**, hors périmètre COM (« Compte, Historique, Foyer, Accueil ») ; la navigation du Studio, elle, est en arabe | `com_notifications_tuteur_390_rtl_clair.png`, `com_studio_aujourdhui_390_rtl_clair.png` |

Les constats R-17 à R-26 (dont R-22, brouillon de ComposerReponse) ne se voient pas sur une
capture : ils relèvent des tests de contre-preuve du tour 2, et non de cette recette.

### Défauts nouveaux

1. **« Envoyer » coupé au bas du premier écran à 320×2** : dans le canal du Studio et les
   Messages admin, le bouton n'est visible qu'à moitié au bord bas, et le lien vocal est hors
   vue ; dans le fil Messages du tuteur, « Envoyer » passe en partie sous la barre de
   navigation. Le défilement initial s'arrête au dernier message, pas à la fin du composer
   (`com_studio_canal_320x2_clair.png`, `com_admin_messages_320x2_clair.png`,
   `com_messages_fil_tuteur_320x2_clair.png`).
2. **Nom de fichier réduit à « …_3.pdf » à 320×2** : l'ellipse au milieu ne garde que la fin
   du nom ; le début (« Devoir ») disparaît (`com_messages_fil_tuteur_320x2_clair.png`).
   Mineur.
3. **Flux de la Communauté à 320×2** : le sous-titre « Échanges et entraide entre
   enseignants » s'étale sur quatre lignes à côté du bouton retour, et aucune publication
   n'est visible au premier écran (`com_communaute_flux_320x2_clair.png`). Plus de
   débordement, mais le premier écran ne montre que l'en-tête, la règle et le filtre.
4. **Texte français en RTL** : dans les réponses de démonstration affichées en arabe, le
   point final passe en tête de ligne (« .élèves ») ; le texte d'un auteur n'a pas sa propre
   direction (`com_communaute_publication_composer_390_rtl_clair.png`). Mineur, à voir avec
   R-08.

### Bilan

- Corrigés à l'image au tour 2 : R-02 (canal du Studio, Messages admin), R-09 (titre de
  l'administration), « Aujourd'hui » coupé, R-01 (publication à 390, réponse bloquée à 1440 ;
  à 320×2 en partie), nom de fichier à 768, (i) et (×) à 390, recherches tronquées.
- Restants : R-12 (bouton centré et dépassement d'« Envoyer » en Focus), R-03 (D-FUS-3), R-08
  (D-FUS-1), R-16 (arbitrage), vocal ouvert par un lien, navigation RTL hors périmètre.
- Nouveaux : 4 (ci-dessus).

## Après COM-RC tour 3

Date : 5 octobre 2026. Captures refaites sur `ui/communications-v1` @ `022cc31e` (COM-RC
tour 3 : saisie du fil qui défile avec les messages, `_NomFichier` à début minimal, en-tête
de la Communauté replié, ligne auteur compacte, `sensDuContenu`). Le test de capture n'a pas
changé. **186 captures** dans `com-v1/`, qui remplacent celles de `e0b9f890` (29 fichiers
diffèrent). **Aucun débordement de rendu** : `com_debordements.txt` n'est pas produit. Chaque
PNG cité ci-dessous a été lu.

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état de
démonstration). Rien n'est branché, rien n'est testé sur staging, rien n'est déployé.

### Restes du tour 2, à l'image

| Reste | Verdict | Capture qui le prouve |
| :--- | :--- | :--- |
| R-02 « Envoyer » coupé à 320×2, canal du Studio | corrigé : dernier message, champ « Message », « Envoyer » entier et lien vocal au premier écran | `com_studio_canal_320x2_clair.png` |
| R-02 « Envoyer » coupé à 320×2, Messages admin | corrigé : barre de la coquille, fin du dernier message, champ, « Envoyer » entier et lien vocal | `com_admin_messages_320x2_clair.png` |
| R-02 « Envoyer » sous la navigation, Messages tuteur à 320×2 | corrigé : « Envoyer » et le lien vocal finissent au-dessus de la barre de navigation | `com_messages_fil_tuteur_320x2_clair.png` |
| R-02 même cas, fil enseignant à 320×2 | corrigé : « Envoyer » et le lien vocal au-dessus de la navigation | `com_messages_fil_contexte_enseignant_320x2_clair.png` |
| R-01 Publication à 320×2 | **corrigé en partie** : la ligne auteur est compacte (nom sur deux lignes, « Enseignante, C… · Il y a 2 h » sur une ligne, environ 15 % de l'écran au lieu de 30 %) ; titre et quatre lignes du texte au premier écran. Le composer de réponse, placé après les réponses, s'atteint toujours en défilant | `com_communaute_publication_320x2_clair.png`, `com_communaute_publication_composer_320x2_clair.png` |
| R-11 Nom de fichier à 320 et 320×2 | corrigé à 320 : « Devoir_…e_3.pdf », le début est gardé ; à 768, « Devoir_sema…e_3.pdf ». **Non vérifiable à 320×2** : la carte défile hors du premier écran, seul « Envoyé » reste visible ; le repli sur deux lignes n'est sur aucune capture | `com_messages_fil_tuteur_320_clair.png`, `com_messages_fil_tuteur_768_clair.png`, `com_messages_fil_tuteur_320x2_clair.png` |
| Flux Communauté à 320×2 | **corrigé en partie** : le sous-titre de quatre lignes a disparu, mais la règle « Partage pédagogique uniquement » tient trois lignes et « Rechercher une publication » deux ; de la première publication, seul le nom de l'autrice (« Samira Belkacem ») est au premier écran, ni titre ni texte | `com_communaute_flux_320x2_clair.png` |
| Texte français en RTL (« .élèves ») | corrigé : la réponse garde sa direction (« …vraiment les élèves. ») | `com_communaute_publication_composer_390_rtl_clair.png`, `com_studio_canal_390_rtl_clair.png` |
| R-12 Focus à 1440 | **restant** : « Quitter le focus » centré ; « Envoyer » dépasse toujours le fil (bulles de 320 à 1007, bouton jusqu'à ~1120) | `com_studio_focus_1440_clair.png` |
| R-12 « Mode focus » centré | **restant** (Center d'ActionPrincipale, décision du directeur) | `com_studio_canal_320_clair.png` |
| R-03 Double bandeau hors ligne | **restant** (attend D-FUS-3) | `com_messages_hors_ligne_tuteur_390_clair.png`, `com_studio_hors_ligne_390_clair.png` |
| R-08 Dates en français en arabe | **restant** (attend D-FUS-1) : « Dimanche 4 octobre، 11:40 » dans le canal, « dimanche 4 octobre 2026 » dans l'annonce | `com_studio_canal_390_rtl_clair.png`, `com_annonce_classe_tuteur_390_rtl_clair.png` |
| R-16 Annonce avant la séance | **restant** (arbitrage du directeur) | `com_annonce_classe_tuteur_390_rtl_clair.png` |
| Vocal ouvert par un lien | **restant** : « Enregistrer un message vocal » sous le champ | `com_studio_canal_320_clair.png` |
| Navigation des coquilles en français en RTL | **restant**, hors périmètre COM (« Profil, Disponibilités, Classes, Aujourd'hui ») | `com_communaute_publication_390_rtl_clair.png` |

### Défauts nouveaux

1. **Ligne auteur mixte en RTL** : « منذ 2 ساعة » est coupé et réordonné (« 2 منذ · Enseignante,
   Classe An-Nour », puis « ساعة » seul à la ligne). Le moment relatif n'est pas isolé en bidi
   dans une ligne dont la fonction est en français
   (`com_communaute_publication_390_rtl_clair.png`,
   `com_communaute_publication_composer_390_rtl_clair.png`). Mineur, à voir avec R-08.
2. **Titre et texte d'une publication, alignements différents en RTL** : « Idées pour la
   mémorisation ? » est aligné à droite, le texte en dessous à gauche ; `sensDuContenu`
   s'applique au texte, pas au titre (`com_communaute_publication_390_rtl_clair.png`). Mineur.
3. **Bulle française alignée à droite en RTL** : « Merci à tous pour la semaine. » a la bonne
   direction, mais elle est collée au bord droit de la bulle, alors que le texte d'Amina
   commence à gauche (`com_studio_canal_390_rtl_clair.png`). Mineur.
4. **Premier écran sans titre à 320×2** : dans le canal du Studio et les fils Messages, la tête
   de page (« Le Studio », « Messages métier ») et l'en-tête du fil défilent hors de vue ;
   l'écran s'ouvre sur la fin d'une bulle, sans nom de canal ni d'interlocuteur
   (`com_studio_canal_320x2_clair.png`, `com_messages_fil_tuteur_320x2_clair.png`,
   `com_messages_fil_contexte_enseignant_320x2_clair.png`). C'est la contrepartie voulue de
   R-02, à arbitrer (garder au moins le nom du fil en tête fixe).

### Bilan

- Corrigés à l'image au tour 3 : R-02 (« Envoyer » entier au premier écran : Studio, admin,
  tuteur, enseignant), R-11 à 320, texte français en RTL.
- Corrigés en partie : R-01 à 320×2 (publication visible, composer en défilant), flux de la
  Communauté à 320×2 (une publication commence au bas du premier écran).
- Restants : R-12, R-03 (D-FUS-3), R-08 (D-FUS-1), R-16 (arbitrage), vocal ouvert par un lien,
  navigation RTL hors périmètre ; R-11 à 320×2 non vérifiable à l'image.
- Nouveaux : 4 (ci-dessus), tous mineurs ou à arbitrer.

### État de chaque constat R-01 à R-28

« Corrigé » renvoie à l'image de `022cc31e`. « Présent dans le code » renvoie au commit COM-RC
qui le déclare, avec ses tests locaux de contre-preuve, sans autre preuve. « Non vérifiable à
l'image » ne vaut pas `PASS`.

| Constat | État | Preuve |
| :--- | :--- | :--- |
| R-01 Réponse hors garde | corrigé ; à 320×2, composer de réponse atteint en défilant | `com_communaute_reponse_bloquee_390_clair.png`, `com_communaute_publication_320x2_clair.png` |
| R-02 Fil à 320×2 | corrigé (messages, champ et « Envoyer » au premier écran, quatre fils) ; titre hors de vue, nouveau n° 4 | `com_studio_canal_320x2_clair.png`, `com_admin_messages_320x2_clair.png`, `com_messages_fil_tuteur_320x2_clair.png` |
| R-03 Double bandeau hors ligne | restant, attend D-FUS-3 | `com_messages_hors_ligne_tuteur_390_clair.png` |
| R-04 Vocal, deux « Envoyer », vocal reçu | corrigé (tour 1) | `com_vocal_pre_ecoute_tuteur_390_clair.png`, `com_messages_fil_tuteur_768_clair.png` |
| R-05 Studio sans identité | corrigé (tour 1) | `com_studio_canal_320_clair.png` (compte, cloche) |
| R-06 Notification inerte | corrigé (tour 1) | `com_notifications_enseignant_390_clair.png` |
| R-07 Lecture de fil et recherche en double | présent dans le code (lot C : adaptateur unique ; `ChampRecherche` dans `core/widgets`) ; non vérifiable à l'image | commit `87e7c6da` |
| R-08 Dates en français en arabe | restant, attend D-FUS-1 | `com_studio_canal_390_rtl_clair.png` |
| R-09 Mots coupés à 320×2 | corrigé (tours 1 et 2) | `com_admin_annonces_320x2_clair.png`, `com_notifications_tuteur_320x2_clair.png` |
| R-10 Colonnes à 256 px, gouttière | corrigé (tours 1 et 2) | `com_messages_fil_tuteur_768_clair.png` |
| R-11 Pièce jointe en texte, nom coupé | corrigé à 320, 768 et 1440 ; 320×2 non vérifiable à l'image | `com_messages_fil_tuteur_320_clair.png` |
| R-12 Focus et actions centrées | restant (Center d'ActionPrincipale ; « Envoyer » dépasse le fil en Focus) | `com_studio_focus_1440_clair.png` |
| R-13 Menu « … », double état vide | corrigé (tour 1) | `com_communaute_publication_390_clair.png` |
| R-14 Majuscules en milieu de phrase | corrigé (tour 1) | `com_communaute_publication_390_clair.png` |
| R-15 Titre et pastilles de l'administration | corrigé (tour 1) | `com_admin_annonces_1440_clair.png` |
| R-16 Annonce avant la séance | restant, arbitrage du directeur | `com_annonce_classe_tuteur_390_clair.png` |
| R-17 Garde en panne qui laisse passer | présent dans le code (lot B) ; non vérifiable à l'image | commit `402510ba` |
| R-18 Signalement sans idempotence | présent dans le code (lot B ; contrat COM-BR encore à tenir côté serveur) ; non vérifiable à l'image | commit `402510ba` |
| R-19 Cinquième règle | non traité (hors champ), à valider par le directeur | `regles_communaute.dart`, aucune capture |
| R-20 Publieur ouvert par URL | présent dans le code (lot B) ; non vérifiable à l'image | commit `402510ba` |
| R-21 Capacités mortes | présent dans le code (lot B : `moderer` et `parametresCanal` retirées, aucune occurrence dans `lib/`) | commit `402510ba` |
| R-22 Brouillons par parcours d'arbre | présent dans le code (lot C : contrôleur et `CleBrouillon` ; tour 2 : `ComposerReponse` sans persistance propre) ; non vérifiable à l'image | commits `87e7c6da`, `0f8bf098` |
| R-23 Orchestration recopiée | présent dans le code (lot C : `VueEtatCommunication.depuisErreur`) ; non vérifiable à l'image | commit `87e7c6da` |
| R-24 États manquants | présent dans le code (lots B et C) ; non vérifiable à l'image | commits `402510ba`, `87e7c6da` |
| R-25 Raccourci clavier d'envoi | présent dans le code (lot C : Ctrl/Cmd+Entrée) ; non vérifiable à l'image | commit `87e7c6da` |
| R-26 Test « aucun rôle lu » incomplet | présent dans le code (lot C : trois chemins ajoutés) | commit `87e7c6da` |
| R-27 Raccourci Communauté en impasse | non traité (hors champ), à arbitrer | aucune capture |
| R-28 Chiffre de COM-CAPT | corrigé : « 14 défauts numérotés » et écarts reportés | section « Défauts transmis » ci-dessus |

## Après COM-RC tour 4

Date : 5 octobre 2026. Captures refaites sur `ui/communications-v1` @ `38534685` (COM-RC
tour 4 : lot F, fil de discussion, N-1, N-3, N-4, N-6, N-8, N-9 ; lot G, Communauté et
annonces, R-01 réserves, R-23, N-2, N-5, N-7, N-10), plus le test de capture modifié au commit
`27689f94` : le Focus du Studio est aussi capturé en texte ×2 à 320, et l'entrée en Focus
remonte le fil quand « Mode focus » a défilé avec l'en-tête (comme
`test/features/com_studio/support_focus.dart`). Les cas « Messages admin à 390 » et « tuteur à
320 en texte ×1 » existaient déjà (écrans principaux). **187 captures** dans `com-v1/`, qui
remplacent les 186 de `022cc31e` (56 fichiers modifiés, 1 ajouté :
`com_studio_focus_320x2_clair.png`). **Aucun débordement de rendu** : `com_debordements.txt`
n'est pas produit. Chaque PNG cité ci-dessous a été lu.

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état de
démonstration). Rien n'est branché, rien n'est testé sur staging, rien n'est déployé.

### Constats N-1 à N-10 de COM-R-2, R-01, R-21 et R-23

| Constat | Verdict | Capture ou preuve |
| :--- | :--- | :--- |
| N-1 Fil ouvert sans contexte à texte ×1 (majeur) | **corrigé** : la ligne compacte de contexte reste fixe au-dessus de la liste. Admin à 390 : « M. Rachid, Contrôleur pédagogique », « Visite de contrôle, Classe An-Nour » et (i), sous l'onglet « Messages », avec les deux derniers messages, le champ et « Envoyer » entiers. Admin à 320 : « M. Rachid, Contrôleur pédag… » et (i). Tuteur à 320 : « Mme Mariam, Enseignante d… », « Classe An-Nour · Adam » et (i) sous « Messages métier » | `com_admin_messages_390_clair.png`, `com_admin_messages_320_clair.png`, `com_messages_fil_tuteur_320_clair.png` |
| N-1 à texte ×2 | **corrigé** : la ligne de contexte (« Mme Mariam, Ense… », « Fatima, Parent de … », « Organisation géné… ») est en tête fixe, au-dessus de la fin de la dernière bulle, du champ, d'« Envoyer » et du lien vocal. Le titre de la page (« Messages métier », « Le Studio ») défile hors de vue, mais le nom du fil reste : le nouveau n° 4 du tour 3 est tenu | `com_messages_fil_tuteur_320x2_clair.png`, `com_messages_fil_contexte_enseignant_320x2_clair.png`, `com_studio_canal_320x2_clair.png` |
| N-1 enseignant à 390 | corrigé, inchangé : en-tête complet (avatar, « Fatima, Parent de Yasmine », (i)) | `com_messages_fil_contexte_enseignant_390_clair.png` |
| N-2 Ctrl/Cmd+Entrée dans le composer de réponse | présent dans le code (lot G) ; non vérifiable à l'image | commit `eb0447cc` |
| N-3 Brouillon effacé avant l'accusé | présent dans le code (lot F, test `com_rc_tour4_lot_f_test.dart`) ; non vérifiable à l'image | commit `12bf1cc7` |
| N-4 Focus à texte ×2, saisie hors écran | **corrigé** : à l'entrée du Focus, à 320 ×2, « Le Studio », « Focus activé », « Quitter le focus », « Organisation générale », puis le champ « Message », « Envoyer » entier et le lien vocal, tous au premier écran. Aucun message du canal n'y reste visible : la saisie occupe l'écran | `com_studio_focus_320x2_clair.png` (nouvelle) |
| N-5 Cas « aucune audience » non testé ; colonne vide à 1440 | **corrigé** : à 1440 sans publication, « Aucune publication », « Aucune publication pour le moment. », une seule fois, au centre. La colonne de gauche reste blanche au-dessus de « Nouvelle publication » ; le test `aucuneCibleTitre` est présent dans le code, non vérifiable à l'image | `com_communaute_vide_1440_clair.png`, commit `eb0447cc` |
| N-6 Seuils recopiés | présent dans le code (lot F : `SeuilsTexteAgrandi`) ; non vérifiable à l'image | commit `12bf1cc7` |
| N-7 Test « aucun rôle » incomplet | présent dans le code (lot G : `champ_recherche`, `surface_recherche`, `page_shell`) ; non vérifiable à l'image | commit `eb0447cc` |
| N-8 `lecteursVocauxDuMessage`, code mort | présent dans le code : aucune occurrence dans `lib/`, test de contre-preuve ; CARTE_FONCTIONS à jour (l.46) | commit `12bf1cc7`, `729cb967` |
| N-9 Panneau de pré-écoute collé au bas | **restant en partie** : à 390, un espace sépare désormais le panneau de la barre de navigation, mais le panneau est coupé en bas (bord et coins inférieurs absents sous « Supprimer » et « Envoyer ») ; à 1440, le panneau va jusqu'au bord de la page et son bord bas est coupé de même | `com_vocal_pre_ecoute_tuteur_390_clair.png`, `com_vocal_pre_ecoute_tuteur_1440_sombre.png` |
| N-10 Date sur deux lignes | **corrigé** : « 4 oct. » puis l'heure « 11:00 », sans l'année en cours | `com_notifications_enseignant_390_clair.png` |
| N-10 Pastille de motif étirée | **corrigé** : « Lien affilié » et « Vente non autorisée » à la largeur de leur texte ; « Contenu sans rapport avec la communauté » tient dans une pastille sur deux lignes, sans s'étirer | `com_admin_moderation_1440_clair.png` |
| N-10 Virgule arabe dans du français | **corrigé** : « Dimanche 4 octobre · 09:54 », séparateur neutre. La date reste en français en arabe (R-08, attend D-FUS-1) | `com_messages_fil_tuteur_390_rtl_clair.png` |
| R-01 Réponse hors garde, réserves | **corrigé** : sous la réponse, le verdict a pour en-tête le texte du §5.2 (« Les liens affiliés ne sont pas autorisés dans la Communauté enseignants. »), sans titre inventé, puis « Motif : Lien affilié », le lien marqué « Lien commercial interdit » et « Modifiez la réponse, puis envoyez-la de nouveau. » ; à 390 et à 1440. Le refus du serveur (`ContenuRefuse`) est présent dans le code, non vérifiable à l'image | `com_communaute_reponse_bloquee_390_clair.png`, `com_communaute_reponse_bloquee_1440_clair.png`, commit `eb0447cc` |
| R-01 Publication | corrigé, inchangé à 390 (texte entier, « Pédagogie », « Enregistrer la publication », « Réponses (2) ») ; à 320×2, titre et début du texte au premier écran, composer en défilant (« Votre réponse », « Envoyer la réponse », rappel des règles). La publication bloquée garde son titre « Publication bloquée » au-dessus du texte du §5.2 | `com_communaute_publication_390_clair.png`, `com_communaute_publication_320x2_clair.png`, `com_communaute_publication_composer_320x2_clair.png`, `com_communaute_garde_bloque_390_clair.png` |
| R-21 Capacités mortes, carte | **corrigé** : capacités retirées du code (lot B) ; CARTE_FONCTIONS cite `recherche_fils.dart` (fichier présent), retire `lecteursVocauxDuMessage`, ajoute `ChampRecherche`, `SurfaceRecherche`, `PersistanceBrouillon` et `SeuilsTexteAgrandi` | `CARTE_FONCTIONS.md` l.37, l.46, l.81-82, commit `729cb967` |
| R-23 Orchestration recopiée | présent dans le code : `publication_detail.dart`, `annonces_de_classe.dart` et `publier_annonce_classe_page.dart` passent par `VueEtatCommunication.depuisErreur` ; non vérifiable à l'image (aucun état d'erreur capturé). L'annonce de Classe s'affiche comme au tour 3 | commit `eb0447cc`, `com_annonce_classe_tuteur_390_clair.png` |

### Restes des tours précédents, revus

| Reste | Verdict | Capture |
| :--- | :--- | :--- |
| R-12 Focus à 1440 | **restant** : « Quitter le focus » centré ; « Envoyer » dépasse toujours le fil (bulles de 320 à 1007, bouton jusqu'à ~1120) | `com_studio_focus_1440_clair.png` |
| R-03 Double bandeau hors ligne | restant, attend D-FUS-3 | `com_messages_hors_ligne_tuteur_390_clair.png` |
| R-08 Dates en français en arabe | restant, attend D-FUS-1 (« Dimanche 4 octobre · 09:54 ») | `com_messages_fil_tuteur_390_rtl_clair.png` |
| R-16 Annonce avant la séance | restant, arbitrage du directeur | `com_annonce_classe_tuteur_390_clair.png` |
| Vocal ouvert par un lien | restant : « Enregistrer un message vocal » sous le champ | `com_admin_messages_390_clair.png` |

### Défauts nouveaux

1. **Ligne de contexte tronquée à 320** : « Mme Mariam, Enseignante d… » (×1), « Mme Mariam,
   Ense… », « Fatima, Parent de … » et « Organisation géné… » (×2). L'objet sur la seconde ligne
   reste entier ; le nom complet est derrière (i). Mineur
   (`com_messages_fil_tuteur_320_clair.png`, `com_studio_canal_320x2_clair.png`).
2. **Icône du micro à taille fixe à texte ×2** : devant « Enregistrer un message vocal », sur
   deux lignes, le micro reste petit et décalé vers le bas. Mineur
   (`com_studio_canal_320x2_clair.png`, `com_messages_fil_tuteur_320x2_clair.png`).
3. **Moment relatif coupé à 390** : « Enseignante, Classe An-Nour · Il y a » puis « 2 h » seul à
   la ligne, dans la publication. Mineur (`com_communaute_publication_390_clair.png`).
4. **Focus à 320×2 sans message visible** : l'entrée du Focus amène la saisie à l'écran, mais
   aucune bulle du canal n'y reste ; il faut remonter pour lire. Contrepartie de N-4, à arbitrer
   (`com_studio_focus_320x2_clair.png`).

### Bilan

- Corrigés à l'image au tour 4 : N-1 (majeur : admin à 390, tuteur à 320, ×1 et ×2, Studio à
  320×2), N-4, N-5, N-10 (trois points), R-01 (réserves sur le texte du verdict), R-21.
- Présents dans le code, non vérifiables à l'image : N-2, N-3, N-6, N-7, N-8, R-23, refus du
  serveur de R-01.
- Restants : N-9 en partie (panneau de pré-écoute coupé en bas), R-12, R-03 (D-FUS-3), R-08
  (D-FUS-1), R-16 (arbitrage), vocal ouvert par un lien.
- Nouveaux : 4, mineurs ou à arbitrer.
- N-1, qui bloquait le passage à `verifie` (COM-R-2, §6.4), est corrigé à l'image ; la
  contre-vérification reste à faire par la revue.

## Après COM-RC tour 6

Date : 5 octobre 2026. Captures refaites sur `ui/communications-v1` @ `145af740`, sans
modifier le test de capture (`test/capture/communications_capture_test.dart`, inchangé depuis
`27689f94`) : COM-RC tour 5 (lots H et I, décisions du 05/10 : D-FUS-1, D-FUS-3, R-08, R-12,
R-16, R-27, R-28) et tour 6 (mineurs de COM-R-4 §8.3 : `8730207a`, `9a473bd8`, `7a5b276b`,
`145af740`). `CAPTURE_DIR` = `19_communications/captures/com-v1`. **187 captures**, mêmes noms
qu'au tour 4 : **114 fichiers modifiés**, aucun ajouté, aucun retiré. **Aucun débordement de
rendu** : `com_debordements.txt` n'est pas produit. Un échantillon de onze PNG a été lu (cités
ci-dessous) ; les autres ne l'ont pas été à ce tour.

Statut de preuve : `présent dans le code` et `testé localement` (rendu d'un état de
démonstration). Rien n'est branché, rien n'est testé sur staging, rien n'est déployé.

### Ce qui a changé, à l'image

| Point | Verdict | Capture |
| :--- | :--- | :--- |
| Focus à 320×2 (R-28, Focus 320) | **corrigé** : la zone d'écriture tient sur une ligne (« Message » et le micro), sans aide ni « Envoyer » inerte ; la dernière bulle (« Samira, Merci à tous pour la semaine. ») reste visible au-dessus. Le défaut nouveau n° 4 du tour 4 est levé. « Envoyer » revient au focus ou à la saisie (code, non vérifiable à l'image) | `com_studio_focus_320x2_clair.png` |
| Bouton micro (R-28) | **présent** : un bouton icône rond à côté d'« Envoyer », à 390 (Messages métier, Studio), à 1440 et en Focus ; le lien « Enregistrer un message vocal » sous le champ a disparu (reste « Vocal ouvert par un lien » du tour 4 levé) | `com_messages_fil_tuteur_390_clair.png`, `com_studio_canal_390_clair.png`, `com_studio_focus_1440_clair.png` |
| Un seul bandeau hors ligne (D-FUS-3, R-03) | **corrigé** : un seul bandeau, celui des Communications (« Vous êtes hors ligne. Les nouveaux messages ne peuvent pas être actualisés. »), plus de bandeau générique au-dessus. Les pages d'annonces (phrase propre, COM-R-4 8.3-2) n'ont pas de capture hors ligne : vérifié par test seulement | `com_messages_hors_ligne_tuteur_390_clair.png`, `com_studio_hors_ligne_390_clair.png` |
| « Mode focus » et « Quitter le focus » au début (R-12) | **corrigé pour l'alignement** : « Mode focus » est au début de la ligne sous l'en-tête du canal à 390, à côté du titre à 1440 ; « Quitter le focus » suit « Le Studio » au début, plus centré | `com_studio_canal_390_clair.png`, `com_studio_canal_1440_clair.png`, `com_studio_focus_1440_clair.png` |
| Page Classe du tuteur (R-16) | sans séance ouverte ou proche dans la démonstration, « Annonces de la Classe 1 » reste en tête, puis « Planning » et « Avant le prochain cours » ; la règle « séance avant annonces » n'est pas visible à l'image | `com_annonce_classe_tuteur_390_clair.png` |
| Studio Aujourd'hui (UX_REVIEW_COM-STU-2 point 4) | **corrigé** : 24 entre les tuiles et « À traiter aujourd'hui » à 390, 32 à 768. Le squelette de chargement (point 14) n'est pas capturé (état transitoire) : vérifié par test | `com_studio_aujourdhui_390_clair.png`, `com_studio_aujourdhui_768_clair.png` |
| Liste des canaux (UX_REVIEW_COM-STU-1 point 6) | **corrigé** : 32 entre deux sections à 1440 (« Organisation », « Admissions & familles », « Pédagogie & qualité »…), au lieu de 20 | `com_studio_canal_1440_clair.png` |
| Dates (D-FUS-1, R-08) | « Dimanche 4 octobre, 09:52 », sans l'année en cours, virgule française | `com_messages_fil_tuteur_390_clair.png` |

### Défauts vus

1. **« Envoyer » dépasse toujours le fil** (reste de R-12) : en Focus à 1440, bulles de 320 à
   1007, bouton jusqu'à ~1120 ; dans le canal à 1440, bulles jusqu'à ~1062, bouton jusqu'à
   ~1127. Mineur (`com_studio_focus_1440_clair.png`, `com_studio_canal_1440_clair.png`).
2. **Micro petit à texte ×2** (n° 2 du tour 4, en partie) : à 320×2, le bouton micro garde une
   icône de taille fixe, nettement plus petite que « Envoyer » à côté. Mineur
   (`com_studio_canal_320x2_clair.png`).
3. **« Mode focus » en retrait** : son libellé commence ~12 après le bord du titre du canal (marge
   interne du bouton texte) ; aligné au début, pas au filet. Cosmétique
   (`com_studio_canal_390_clair.png`).
4. **Champ du Studio plus haut que ses voisins à 390** : le champ « Message » du canal fait deux
   hauteurs de ligne, le micro et « Envoyer » une seule ; dans Messages métier, le champ fait une
   ligne. Mineur (`com_studio_canal_390_clair.png`, `com_studio_hors_ligne_390_clair.png`).
5. **Démonstration incohérente sur la Classe du tuteur** : page « Classe fictive A », « Eleve
   A1 » sans accent, mais annonce « Classe An-Nour ». Données de démonstration, pas de rendu
   (`com_annonce_classe_tuteur_390_clair.png`).
6. Restent du tour 4, non revus à ce tour : ligne de contexte tronquée à 320 (n° 1), moment
   relatif coupé à 390 (n° 3). N-9 est corrigé : la pré-écoute à 390 montre le panneau entier
   (constat de COM-R-5, 05/10).

### Bilan

- Corrigés à l'image depuis le tour 4 : Focus 320×2 (une ligne, bulle visible), micro à côté
  d'« Envoyer », un seul bandeau hors ligne, alignement de « Mode focus » et « Quitter le
  focus », écarts du Studio (sections des canaux, Aujourd'hui).
- Vérifiés par test seulement : accusé tardif (8.3-1), phrase hors ligne des annonces (8.3-2),
  squelette d'Aujourd'hui (8.3-3, point 14).
- Restants : « Envoyer » hors du fil à 1440 (R-12), micro à texte ×2, et les défauts
  mineurs ci-dessus. N-9 corrigé (COM-R-5, 05/10).

## Après COM-RC tour 7 (08/10, code ui/communications-v1 @ 5c0bffa3)

Ordre du directeur du 08/10 : tout défaut vu est corrigé par la session, sans lui être soumis.
Captures régénérées par `communications_capture_test.dart` et `com_rc7_k_capture_test.dart`
(CAPTURE_DIR = ce dossier) : **200 PNG** (187 + 13 nouvelles : échanges du contrôleur 390/768/1440
clair et sombre, Planning de la Classe du tuteur 320×2/390/390 RTL, saisie du canal du Studio
390/1440 clair et sombre), 108 modifiées. Aucun débordement (`com_debordements.txt` absent).

Corrigés et vus à l'image (36 captures ouvertes par la passe M, plus celles des lots K et L) :

- « Envoyer » dans la colonne du fil à 768 et 1440 (canal, Focus, Messages) ; bulles reçues
  pleine colonne, bulles de soi à 92 % au bord d'« Envoyer » dès 600 ; téléphone inchangé (86 %).
- Micro à la hauteur d'« Envoyer » en texte ×2 (icône bornée à ×2, cible ≥ 48).
- « Mode focus » et les boutons texte de début de ligne sans retrait (bouton affleurant, RTL).
- Champ du Studio d'une ligne à 390 (aide sur une ligne, toujours lue par les lecteurs d'écran).
- Ligne de contexte et nom du canal sur 2 lignes à 320, rien de coupé ; moment relatif insécable ;
  « An‑Nour » insécable (en-tête, liste des fils) ; date « Dimanche 4 octobre » non coupée.
- Démonstration cohérente : Classe An-Nour, « Sayyida Mariam » partout (page Classe, annonce,
  Messages), accents ; une séance proche montre la séance avant les annonces (R-16).
- Arabe : 26 libellés relus (agent, pas d'arabophone humain), pluriels (« منذ ساعتين »),
  terminologie unifiée, ordre bidi de la carte de séance, guillemets tournés vers l'extérieur,
  initiales arabes séparées (« س‌م »), démonstrations Messages, Studio et Communauté entièrement
  en arabe dans l'interface arabe.

Comportements voulus, vus et laissés : Focus 320×2 sans « Envoyer » tant que le champ est vide
(décision Focus 320) ; fonction de l'auteur abrégée à 320×2 dans la Communauté pour garder le
moment entier ; extension latine d'un nom de fichier arabe rendue selon l'ordre bidi normal.

## Après COM-R-6 (08/10, code ui/communications-v1 @ 8b1240ac)

Captures régénérées (200 PNG) : 199 identiques à 0d33c946, une seule change,
`com_admin_moderation_390_rtl_clair.png`. Le tour 7 avait stocké six guillemets arabes en ordre
visuel (»…«) ; U+00AB/U+00BB étant Bidi_Mirrored, le moteur les dessinait alors **tournés vers
l'intérieur** (lu sur les pixels ; l'œil, à zoom normal, ne le voit pas). Ils sont revenus en ordre
logique («…»), le paramètre `{texte}` saisi par l'utilisateur est isolé (U+2068 … U+2069) : rendu
tourné vers l'extérieur, vérifié sur les pixels en test (six chaînes × cinq saisies) et dans
l'aperçu web réel (Chromium, interface arabe, écran Modération et recherche des Messages) ; l'arbre
d'accessibilité web contient les guillemets en ordre logique.
