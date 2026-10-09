# REWAYAH ACADEMY - CAP-55 / PUB-1
## Pages de présentation de l'application avant connexion

**Version :** V1.0 - 8 octobre 2026  
**Destinataire :** Claude Code, coordinateur frontend Flutter  
**Statut :** spécification produit et mandat de production des visuels, à contrôler sur le dépôt avant intégration  
**Périmètre :** frontend Flutter Android, iOS, Web/PWA, téléphone, tablette et ordinateur. Aucun backend, aucune migration, aucun paiement ni changement LiveKit.  
**Dépendance :** CAP-54, route publique existante `/bienvenue` et ses sorties `/connexion` et vers le flux d'inscription existant.  
**Règle de méthode :** audit du réel → catalogue d'écrans → captures internes → compositions high-fi → revue → validation visuelle → intégration isolée → recette.

---

## 0. ORDRE DU DIRECTEUR - PRIORITÉ ABSOLUE

**Nos précédentes compositions ont échoué parce qu'elles montraient beaucoup trop de l'application.** Les nouvelles pages doivent expliquer **une seule fonctionnalité essentielle à la fois**, avec **une seule portion principale d'un écran réellement existant**. L'objectif n'est **ni un catalogue d'écrans, ni une visite miniature de tous les menus**.

**Claude possède le code. Il doit réaliser lui-même les captures des interfaces Flutter internes dans un environnement de démonstration isolé, puis en extraire un détail intelligible par page.** Ne pas attendre que ChatGPT invente des captures. Ne pas reproduire les anciennes planches ratées.

Interdictions visuelles immédiates :

1. **Pas de capture intégrale d'une page** affichant l'en-tête, le menu, toutes les sections et la barre basse. Recadrer une **zone fonctionnelle dominante**, avec son contexte minimal.
2. **Pas de mosaïque, pas de deux ou trois fenêtres Flutter différentes, pas d'empilement de cinq cartes hétérogènes.** Une page de présentation = **un seul extrait d'un seul écran produit**.
3. Pas d'illustration dessinée à la main, de personnage ajouté, de maquette d'application inventée, ni de capture générée par IA. Les éléments visuels de l'app doivent provenir **de l'app exécutée**.
4. Pas de visio simulant une réunion familiale : **chaque élève a sa propre classe**. Le tuteur peut accompagner à distance depuis son propre appareil. Ne pas suggérer que toute la famille suit le même cours sur un seul appareil.
5. Pas de chiffre, note, score, horaire, capacité, enseignant, paiement, vidéo ou état « réel » inventé. Les données de démonstration doivent être explicitement synthétiques dans l'environnement de capture, et leur présentation ne doit pas promettre une fonction indisponible.
6. Ne pas retoucher la capture pour fabriquer de nouveaux boutons, cacher un défaut produit bloquant, changer des données métier ou transformer une capacité fictive en fonction livrée.

**Critère visuel décisif : en 3 secondes, un lecteur doit identifier la fonction mise en avant sans examiner une autre capture ni lire les petits libellés.** Si ce critère échoue, le visuel doit être refait.

---

## 1. Sources et décisions à préserver

### 1.1 Sources à inspecter AVANT le premier changement

- Le catalogue `docs/design/08-catalogue-ecrans.md`, et la fiche PUB-1 du cockpit / suivi Rewayah.
- `Fermeture Frontend Rewayah.md` et `Contre-revue Frontend Rewayah.md`, sections CAP-54 / CAP-55.
- `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`, `03_DESIGN_SYSTEM_ET_UX.md`, `design-tokens.md` réel et thème Flutter actuel.
- `DOSSIER_POUR_CHATGPT.md` pour les règles de composition, high-fi, duplication des fonctions et polices.
- Les routes et composants réels de `/bienvenue`, `/connexion` et de l'inscription ; rechercher `bienvenue_page.dart` et le routeur effectif sans présumer leur emplacement courant.
- Les vrais écrans sources que Claude trouve dans le code : Coran/lecteur, Foyer, Espace Classe et Suivi/Progression, en respectant le statut réel de chacun.

**Ne pas créer un second système de bienvenue, une nouvelle architecture de navigation ni un nouveau thème.** Si le code diverge de cette fiche, écrire le chemin, le commit et la divergence avant de choisir une modification.

### 1.2 Décisions confirmées et propositions de cette fiche

| Sujet | Traitement |
| --- | --- |
| Présentation AVANT connexion | Décision existante PUB-1 |
| 3 à 5 pages, UNE idée par page | Décision existante, **4 pages retenues** |
| Défilement automatique, ligne de progression et glissement manuel | Décision existante |
| Croix en haut pour tout passer | Décision existante |
| `/bienvenue` et ses deux sorties | Existant à préserver ; ne pas ajouter un écran identique |
| « Le Coran en famille » et son texte | Formulation retenue au cours de l'échange du 5 octobre |
| Captures internes inclinées / immersion, à la place des dessins | Directive récente du directeur, confirmée et **précisée ici par le recadrage fonctionnel** |
| Délai automatique de 8 secondes | Valeur du brouillon précédent : **paramètre de départ de cette fiche**, soumis à la recette d'usage et au mouvement réduit |
| Accroches exactes des pages 1, 3 et 4 | **Copy proposée dans cette fiche**, sans les faire passer pour des textes précédemment validés |

---

## 2. Objectif et organisation des quatre pages

Un visiteur comprend, en moins d'une minute, **ce que Rewayah apporte**, sans rencontrer un formulaire ni étudier l'interface complète. Chaque page suit le même principe :

1. **Un bénéfice utilisateur** expliqué en une phrase courte.
2. **Une zone centrale mise en scène**, tirée d'une capture Flutter réelle, limitée à une fonction.
3. **Un appui textuel minimal**, distinct du bénéfice principal.
4. Des commandes de progression, de passage et d'accès au produit immédiatement compréhensibles.

### PAGE PUB-55-01 - Le parcours coranique

- **Titre proposé :** « Le Coran, pas à pas ».
- **Texte proposé :** « Progressez en lecture et en récitation avec un parcours adapté à votre niveau. »
- **Promesse unique :** apprentissage progressif du Coran, pas une liste exhaustive des programmes.
- **Source de capture prioritaire :** lecteur du Coran dans Flutter, **uniquement le passage lisible ou la zone pédagogique active**, après vérification du rendu de la source coranique.
- **Recadrage :** une portion centrale nette du Muṣḥaf ou du support de lecture ; aucune sidebar, tableau de bord, formulaire, grille de bibliothèque ou liste de sourates entière.
- **Contrôle obligatoire :** ne pas utiliser une capture montrant un Coran dans le mauvais ordre, avec une pagination infidèle ou un rendu religieux trompeur. Si cette source n'est pas suffisamment fiable, marquer la capture **BLOQUÉE : lecteur non validé**, rechercher un support pédagogique déjà fiable dans le code et soumettre le remplacement avant composition finale.
- **Message visuel attendu :** « Ici, on lit et on progresse », et non « regardez tout notre lecteur ».

### PAGE PUB-55-02 - Le foyer et les parcours individuels

- **Titre retenu :** « Le Coran en famille ».
- **Texte retenu :** « Apprenez, transmettez et encouragez-vous en famille. Chacun à son rythme, ensemble autour du Coran. »
- **Promesse unique :** plusieurs parcours individuels peuvent être accompagnés au sein d'un même foyer.
- **Source de capture :** `Foyer` Flutter, avec **un seul bloc pertinent** : profils élèves ou résumé d'un élève accompagné. Choisir le bloc le plus clair et le plus fidèle à la version effective.
- **Recadrage :** une zone des profils du foyer ou une seule fiche synthétique, **pas** l'Accueil + le Foyer + le Détail de classe assemblés, **pas** une famille photographiée en train de suivre un même cours.
- **Sens à préserver :** un enfant utilise son appareil pour sa classe ; son tuteur peut consulter le suivi et, selon la politique d'observation, observer à distance. **Le visuel du Foyer ne doit pas laisser croire à une observation illimitée ni à un cours collectif familial.**
- **Message visuel attendu :** « Plusieurs parcours, un accompagnement familial ».

### PAGE PUB-55-03 - La classe et l'enseignant

- **Titre proposé :** « Un enseignant, des repères ».
- **Texte proposé :** « Retrouvez votre enseignant attitré et votre classe lors de séances en direct. »
- **Promesse unique :** une classe identifiable avec un enseignant attitré, pas un catalogue de fonctions LiveKit.
- **Source de capture :** une **seule zone pertinente** de l'Espace Classe ou de la salle de démonstration : identité/photo professionnelle autorisée de l'enseignant et contexte de la séance **dans la même zone native**. Choisir une zone qui existe réellement ; privilégier l'enseignant et le support plutôt que la barre des commandes de visio.
- **Recadrage :** pas de roster intégral, pas de barre de menus complète, pas d'empilement de participants et d'outils. Ne pas produire un faux appel vidéo à partir de photos ou d'une capture publique.
- **Préservation métier :** intitulés Sayyid/Sayyida dans l'espace Classe ; photo publique professionnelle distincte du KYC ; aucune promesse que le cours est accessible sans droit ni hors créneau.
- **Message visuel attendu :** « Mon enseignant et ma classe sont clairement identifiables ».

### PAGE PUB-55-04 - Le suivi des apprentissages

- **Titre proposé :** « Gardez le fil des progrès ».
- **Texte proposé :** « Retrouvez les acquis et les objectifs de chaque élève, séance après séance. »
- **Promesse unique :** savoir où en est l'apprentissage, sans se perdre dans des rapports.
- **Source de capture :** **une seule carte réelle** de progression ou d'objectif / travail à préparer si la carte de progression n'est pas encore accessible en démonstration.
- **Recadrage :** état ou objectif dominant dans une seule carte ; pas de trois graphiques, de dashboard complet, de statistiques artificielles ni de classement d'élèves.
- **Contrôle :** ne pas inventer un score « 92 % », une certification obtenue, un niveau validé ni un état « payé ». Les contenus peuvent provenir des fixtures explicites de démonstration, jamais de données de vrais élèves.
- **Message visuel attendu :** « Je sais ce qui est acquis et ce qui reste à travailler ».

**Important :** la page 04 sert aussi de point de sortie vers l'inscription et la connexion. Cela ne justifie pas de créer une cinquième page répétant `/bienvenue`.

---

## 3. Direction artistique : capture réelle, détail immersif

### 3.1 Production que Claude doit réaliser lui-même

Pour **chacune des 4 pages**, suivre ce pipeline, et conserver les fichiers sources :

1. Identifier dans le dépôt l'écran Flutter **déjà codé** dont la fonction correspond au bénéfice.
2. Exécuter l'application dans un **mode de démonstration isolé**, avec données synthétiques et sans demander l'accès à de vraies identités. Ne pas déclencher d'appel externe sensible pour produire une capture.
3. Choisir le thème Rewayah existant, l'état pédagogique le plus intelligible et le viewport mobile de référence.
4. Réaliser une **capture brute** de l'app effectivement rendue sur simulateur, navigateur ou test de capture Flutter. Garder intacte cette preuve.
5. Sélectionner **une zone rectangulaire fonctionnelle unique** dans la capture, avec le minimum de contexte utile. Vérifier que la découpe n'isole pas une donnée de sa légende ni ne change son sens.
6. Sur la composition CAP-55, placer ce seul extrait dans un **cadre de surface native** qui peut être légèrement incliné, décalé et recadré. L'immersion vient de la perspective et de la profondeur subtile, **pas de la multiplication des écrans**.
7. Vérifier sur téléphone à taille réelle que l'élément principal de l'extrait reste perceptible. S'il faut zoomer pour lire une commande secondaire, retirer cette commande du cadrage plutôt que rétrécir toute l'image.
8. Soumettre pour chaque page la **capture brute**, le **recadrage isolé** et le **rendu intégré**. Toute retouche qui altère le contenu produit est interdite ; le recadrage, la perspective, le masque et l'ombre sont permis.

### 3.2 Garde-fous de composition

- **Un seul extrait fonctionnel par page**. Il peut contenir plusieurs éléments imbriqués **s'ils appartiennent à la même carte/zone native et servent la même idée**.
- L'extrait est suffisamment grand pour être compris **sans devoir afficher son écran parent entier**.
- Rotation discrète, jamais une perspective si forte qu'elle rend le texte illisible.
- Marges et fond calmes, sans éléments décoratifs qui imitent des commandes Flutter.
- Légère profondeur autorisée, sans gradient violent, surbrillance artificielle, bordure téléphone géante ou mockup rempli de nombreux écrans.
- Ne jamais ajouter une deuxième image de soutien « pour remplir le vide ».
- Conserver les caractères arabes intacts, sens RTL et voyelles, et ne pas utiliser de génération de texte arabe.
- Le visuel doit s'adapter au thème clair et sombre par les tokens déjà existants. **Aucune couleur, fonte, rayon ou espacement arbitraire dans les widgets métiers.**
- Titre en **DM Sans**, autres textes en **Plus Jakarta Sans**, police arabe existante inchangée.
- Ne pas utiliser d'illustrations destinées au site public : le site est un chantier distinct.

### 3.3 Sources de vérité et blocages

Si l'écran nécessaire est absent, non monté hors démo ou matériellement incorrect :

- Ne pas dessiner une fonctionnalité imaginaire.
- Signaler : `CAPTURE NON VALIDABLE`, écran/route/code source concerné, problème, solution minimale proposée.
- Continuer les trois autres visuels indépendants.
- Ne pas modifier Coran, LiveKit, finance ou intégration serveur pour régler un problème de marketing d'accueil sans mandat distinct.
- Ne pas utiliser la capture d'un rôle plus privilégié pour prétendre qu'une personne ordinaire voit cette information.

### 3.4 Nommage et traçabilité

```text
captures/CAP55/01_source_brute.png
captures/CAP55/01_focus.png
captures/CAP55/01_mobile_clair.png
captures/CAP55/01_mobile_sombre.png
captures/CAP55/02_source_brute.png
captures/CAP55/02_focus.png
...
captures/CAP55/04_mobile_clair.png
captures/CAP55/04_mobile_sombre.png
captures/CAP55/desktop_reference.png
captures/CAP55/tablette_reference.png
captures/CAP55/MANIFESTE_CAPTURES.md
```

Le manifeste indique pour chaque extrait : route et écran source, composant exact, branche/SHA, statut de la fonctionnalité (réel ou démonstration), dimensions source, rectangle de recadrage, état et thème, contrôle de confidentialité. Les chemins définitifs suivent l'organisation du dépôt après inspection ; ne pas créer un deuxième répertoire de captures canonique.

---

## 4. Structure UI canonique

### 4.1 Mobile, référence 390 × 844 dp

Ordre vertical :

1. **Entête sobre :** marque texte ou logo officiel s'il existe déjà, et contrôle `Passer` clairement accessible (croix avec libellé accessible « Passer la présentation »). Ne pas créer de faux logo officiel.
2. **Titre principal** et microcopie de la page. Au besoin, déplacer le texte sous le visuel selon le rendu réel, mais garder l'ordre de lecture accessible : titre → description → visuel → actions.
3. **Surface visuelle centrale dominante : un seul extrait de l'app**. La hauteur s'ajuste à l'espace disponible ; le visuel ne doit jamais masquer le titre, le bouton ou le geste de changement.
4. **Indicateur de progression** : quatre segments, segment actif qui se remplit dans la durée courante ; progression déterminable sans seule couleur, avec texte sémantique « Page 2 sur 4 ».
5. **Pied d'action accessible au pouce** : action principale `Créer un compte` utilisant la route réelle d'inscription, action secondaire `Se connecter` vers `/connexion`. Ne pas forcer l'utilisateur à regarder toutes les pages. Un seul bouton rempli ; la connexion peut être textuelle ou à contour selon les composants existants.

Ne pas ajouter de barre de navigation privée à ce flux public. Respecter SafeArea, clavier éventuel, retour et scroll sur petit écran. À 320 dp ou texte agrandi 200 %, permettre le défilement du contenu sans superposition ni troncature.

### 4.2 Tablette et vrai desktop Web/PWA

- **Tablette :** surface centrée et contrainte en largeur, texte et visuel organisés pour profiter de l'espace sans agrandir la capture jusqu'à montrer davantage de l'interface interne.
- **Desktop ≥ largeur du layout adapté par le design system :** composition en **deux zones claires** : d'un côté titre, explication, progression et actions ; de l'autre **le même unique extrait focalisé** dans un cadre immersif. Ne pas montrer une capture Flutter desktop entière sous prétexte que l'écran est large.
- La zone visuelle garde un cadrage métier identique sur mobile, tablette et web. Les variantes sont des **compositions adaptées**, non de nouvelles fonctionnalités.
- Clavier : Tab, Enter, focus visible, flèches gauche/droite si compatibles avec les contrôles actifs et avec RTL ; Esc ne doit pas entraîner une sortie accidentelle.
- PWA : pas de reload entre les pages, comportement sain du bouton Retour et absence de boucle à la reprise.

### 4.3 Light, dark et animation

- Reprendre exclusivement les `ColorScheme`/tokens existants, avec contraste mesuré.
- Chaque page fonctionne en clair et en sombre et reste intelligible sans les effets de perspective.
- Transition douce entre pages, sans effet 3D continu, rotation brusque, défilement vertical de faux contenus ni parallax qui gêne la lecture.
- Si `MediaQuery.disableAnimations` ou préférence système de mouvement réduit : **aucun défilement automatique**, aucun remplissage animé nécessaire, transitions instantanées ; progression et commandes toujours présentes.

---

## 5. Machine d'état et navigation

### 5.1 Première visite

- Si aucune visite de présentation n'est enregistrée localement, ouvrir la première page au point d'entrée public **après vérification des règles de redirection des comptes déjà authentifiés**.
- **Durée de référence : 8 s par page** en mode mouvement normal. Ce délai reste une constante/configuration du composant, non quatre timers indépendants. Pas de course entre animation et navigation.
- Glissement manuel ou activation d'un indicateur de page : changer immédiatement de page et réinitialiser sa progression. Gestes horizontaux adaptés à la direction linguistique et ne capturant pas le scroll vertical.
- Maintenir la page si l'utilisateur interagit avec des contrôles qui demandent une attention prolongée. En arrière-plan, onglet caché, focus perdu ou image non prête : **mettre la progression en pause** ; ne pas sauter trois pages à la reprise.
- À la page 4 : **arrêter l'autoplay**, rester sur la sortie jusqu'à action de l'utilisateur. Ne jamais rediriger automatiquement vers inscription ou connexion.
- `Passer` sur les pages 1 à 3 : atteindre la page 4, où les deux sorties sont explicites. Sur page 4, masquer `Passer` ou le remplacer par un libellé neutre non redondant ; la connexion et l'inscription restent accessibles.
- Action `Créer un compte` ou `Se connecter` : navigation vers les routes réelles ; conserver l'absence de création de compte artificielle et ne pas lier la présentation à un consentement juridique.
- L'utilisateur peut revenir à l'écran public sans se retrouver bloqué ni enfermé dans un carousel obligatoire.

### 5.2 Visites suivantes

- **Ne pas imposer à chaque ouverture les 4 pages avec autoplay.** Lorsqu'un utilisateur non connecté revient, la route `/bienvenue` peut présenter immédiatement l'état final avec ses deux sorties, ou l'accueil léger existant si celui-ci est conservé au même endroit ; pas de nouvel écran identique ni de remplacement silencieux du routeur.
- Prévoir un accès discret `Revoir la présentation` **dans ce même espace public**, réutilisant le même carousel et non un second flux. Lors de cette action explicite, la présentation redémarre à la première page ; l'autoplay peut repartir sauf mouvement réduit.
- Enregistrer localement seulement le fait que la présentation a déjà été parcourue/passée, **pas** de profil, de données de foyer ni de session Auth. Ne pas considérer cet indicateur comme une autorisation.
- Retour arrière : conserver le comportement plateforme éprouvé, revenir à l'espace public précédent ou fermer le sous-flux selon le routeur ; ne pas piéger l'utilisateur. Après lancement de l'inscription/connexion, ne pas perdre leurs éventuelles étapes validées à cause du carousel.

### 5.3 États obligatoires

| État | Traitement UI / accessibilité |
| --- | --- |
| Première ouverture | Page 1, texte et contrôles immédiatement accessibles ; image chargée sans layout shift important |
| Image non encore chargée | Espace de taille préservée, fond de surface/token ; progression en pause ; pas de faux contenu |
| Capture indisponible | Texte et CTA utilisables, illustration omise avec dégradation propre ; erreur technique non montrée publiquement |
| Autoplay actif | Une seule page active, barre de progression accessible |
| Glissement/contrôle manuel | Position mise à jour, délai réinitialisé, aucune animation double |
| App en arrière-plan / onglet masqué | Progression suspendue jusqu'au retour |
| Mouvement réduit | Pas d'autoplay ; progression fixe avec page courante textuelle |
| Première visite passée | Accueil public final sans obligation répétée |
| Dernière page | Aucune avance forcée, deux sorties accessibles |
| Mode hors ligne | Captures intégrées/locales et textes visibles, destinations de connexion/inscription gèrent leurs états réseau normaux |
| Session déjà authentifiée | Redirection normale selon droits existants, aucun écran marketing forcé |

---

## 6. Contenus exacts à encoder

### 6.1 Texte des pages

| Réf. | Titre | Description |
| --- | --- | --- |
| PUB-55-01 | Le Coran, pas à pas | Progressez en lecture et en récitation avec un parcours adapté à votre niveau. |
| PUB-55-02 | Le Coran en famille | Apprenez, transmettez et encouragez-vous en famille. Chacun à son rythme, ensemble autour du Coran. |
| PUB-55-03 | Un enseignant, des repères | Retrouvez votre enseignant attitré et votre classe lors de séances en direct. |
| PUB-55-04 | Gardez le fil des progrès | Retrouvez les acquis et les objectifs de chaque élève, séance après séance. |

Les textes 01, 03 et 04 constituent les copies **proposées ici**. Le 02 reprend la formulation retenue précédemment. Ne pas remplacer les accroches par un slogan marketing inventé, ne pas ajouter de promesses de diplôme, gratuité, disponibilité permanente, taille de groupe ou bénéfice garanti.

### 6.2 Contrôles et messages

- Action primaire : `Créer un compte` (ou libellé actuel de l'inscription s'il existe une convention publique immuable ; consigner l'écart).
- Action secondaire : `Se connecter`.
- Passage : `Passer`, avec nom sémantique `Passer la présentation`.
- Relecture de la présentation : `Revoir la présentation`.
- Indicateur accessible : `Page {n} sur 4`.
- Contenus et états de chargement utilisent les composants et les chaînes i18n déjà existants ; nouvelles clés seulement dans l'espace public CAP-55.
- Ne jamais utiliser `Cours en cours`, `mode enfant`, `Session`, codes internes ni faux noms d'enseignants au niveau de la copie marketing.

---

## 7. Architecture frontend et isolation du chantier

1. Inspecter le routeur et **réutiliser `/bienvenue`** comme espace public unique. Conserver CAP-54 et ses routes de sortie ; éviter la juxtaposition de deux écrans d'accueil quasi identiques.
2. Rechercher dans le dépôt les composants `Pressable`, surface groupée, typographie, système de thème, indicateurs et conventions d'accessibilité avant de créer un composant.
3. Isolation du carousel et de ses assets dans le domaine public existant, sans import direct de composants métier nécessitant des données privées. **Les images utilisées à l'exécution sont des captures intégrées comme assets locales**, pas l'UI live des familles derrière un écran de présentation.
4. Pas de permission ajoutée, de chargement de données réelles, de KYC, d'appel Supabase/LiveKit/R2, de nouveau service public ni de tracking nominatif pour CAP-55.
5. L'état « déjà vu » est purement local et non sensible, sans interaction avec les guards Auth autrement que les redirections actuelles.
6. Les captures doivent être **compressées et adaptées aux densités** sans dégrader lisibilité ou allonger le démarrage. Évaluer format moderne compatible Flutter/platformes, dimensions, poids total, temps de premier rendu et absence de scintillement au passage. Ne pas enregistrer dans Git de captures brutes contenant des données réelles.
7. Vérifier explicitement les branches/worktrees d'agents actifs ; modifier uniquement le périmètre attribué, sans pousser, fusionner ou déployer sans autorisation existante spécifique.
8. La fonction `Revoir la présentation` réutilise exactement le même carousel ; aucun duplicata de routes ou de pages marketing.

---

## 8. Ordre d'exécution obligatoire pour Claude

### PHASE A - Audit préalable (sans écrire dans le code)

- Confirmer routes, composants, thème, règles de première visite, démo, écrans disponibles et agents actifs.
- Établir la table : page CAP-55 → bénéfice → écran source exact → composant/crop candidat → statut réel → risque → disponibilité de capture.
- Signaler tout écran/capture impossible au lieu de le substituer sans explication.

### PHASE B - Catalogue et direction visuelle

- Inscrire la fiche **PUB-1 / CAP-55** dans `docs/design/08-catalogue-ecrans.md` **avant le code**, selon la règle du cockpit.
- Définir les quatre pages, leurs textes et leurs cinq familles d'états ; référencer cette spécification.
- Capturer soi-même les quatre zones Flutter internes et produire le manifeste des sources.
- Composer les **quatre high-fi mobile**, versions clair et sombre, puis une référence tablette et une vraie référence desktop. Les high-fi doivent utiliser exactement les zones capturées et les textes ci-dessus.
- **Point d'arrêt pour revue de direction avant l'intégration visuelle** : montrer les 4 compositions et la capture brute de chaque image. Ne pas faire valider uniquement des captures d'écrans entiers.

### PHASE C - Revue critique spécialisée

Revue contradictoire explicite, courte mais vérifiable, menée sous quatre angles :

| Revue | Questions de validation |
| --- | --- |
| Direction produit | Les 4 promesses sont-elles vraies ? Une idée par page ? Aucune confusion entre parcours familiaux et cours partagé ? |
| UX/UI senior | Le cadrage attire-t-il l'œil au bon endroit ? Une seule portion intelligible ? Densité et hiérarchie lisibles à 390 × 844 et 320 dp ? Desktop réellement adapté ? |
| Accessibilité | 200 % text scale, contrastes WCAG 2.2 AA pertinents, lecteur d'écran, Focus, RTL, swipe et mouvement réduit fonctionnent-ils ? |
| Confidentialité / QA | Zéro donnée réelle, zéro état trompeur, images traçables à un écran/code, première visite/retour/skip/panne couverts ? |

La revue produit et la revue visuelle doivent être indépendantes : une belle maquette qui vend une fonctionnalité non prête est rejetée.

### PHASE D - Implémentation et recette (après validation du handoff visuel)

- Implémenter dans les fichiers publics existants, le plus petit diff cohérent possible.
- Ajouter tests de carousel, navigation, accessibilité, breakpoints, états, première visite, retour, interaction/autoplay et mouvement réduit.
- Fournir captures du Flutter **réel après intégration**, pas seulement le design préparatoire.
- Comparer pixel et placement des high-fi à l'implémentation, documenter les écarts et corriger.
- Ne pas confondre « maquettes produites », « codé » et « test sur PWA réelle ».

---

## 9. Critères d'acceptation vérifiables

| ID | Scénario d'acceptation |
| --- | --- |
| CAP55-01 | Chaque page affiche un bénéfice principal et **un seul extrait fonctionnel d'un seul écran** ; aucune page entière ni mosaïque. |
| CAP55-02 | Les quatre captures brutes proviennent de l'app Flutter exécutée ; manifeste des routes, SHA, crops et états fourni. |
| CAP55-03 | La page Foyer ne suggère ni un cours familial partagé ni une observation parentale illimitée. |
| CAP55-04 | La page Classe reflète enseignant attitré, sans inventer un appel vidéo réel. |
| CAP55-05 | La page Coran ne montre aucun texte source incorrect, dans le mauvais sens ou inventé. |
| CAP55-06 | Avant première connexion, première visite : 4 pages, glissement manuel, progression visible, autoplay paramétré ; fin reste stable. |
| CAP55-07 | `Passer` amène directement à la page finale ; `Créer un compte` et `Se connecter` suivent les routes existantes. |
| CAP55-08 | Visite suivante : pas de carousel imposé ; possibilité de revoir la présentation dans le flux public existant. |
| CAP55-09 | Mouvement réduit : pas de défilement automatique ; focus et lecture d'écran cohérents. |
| CAP55-10 | Écran 320 dp, mobile 390, tablette 768, desktop 1440, clair/sombre et texte 200 % : aucune action inaccessible et aucun overflow. |
| CAP55-11 | Mode hors ligne : contenu public présent et actions de connexion/inscription affichent leur état réel. |
| CAP55-12 | Aucun appel à une donnée privée, aucune identité réelle dans les assets, aucun nouveau backend ni route parallèle. |
| CAP55-13 | Capture high-fi finale et capture Flutter intégrée comparées sur les quatre pages ; écarts tracés. |
| CAP55-14 | Fiche catalogue validée, revue critique consignée, diff limité, tests documentés ; pas d'annonce de livraison sans preuves. |

### Test humain obligatoire « 3 secondes »

Présenter chaque page seule, sur un téléphone à taille normale, à une personne qui ne connaît pas l'app. Après 3 secondes, demander ce qu'elle pense pouvoir faire avec cette fonction. Si elle décrit « plusieurs fenêtres », « un site web », « une famille dans le même cours », « une plateforme administrative » ou ne peut nommer l'action centrale, revoir la **découpe** avant le style.

---

## 10. Format de retour demandé à Claude

Fournir dans cet ordre :

1. **Inventaire de départ :** commit, routes réelles, écrans disponibles, thème, éventuels conflits avec les agents actifs.
2. **Table des quatre captures :** source Flutter, portion retenue, justification du cadrage, preuve de données synthétiques.
3. **Huit high-fi mobiles :** quatre pages en clair + quatre en sombre ; une adaptation tablette et une desktop ; sources brutes consultables.
4. **Audit contradictoire des quatre revues**, chacun en conclusions PASS / À CORRIGER / BLOQUÉ avec raisons vérifiables.
5. **Après validation :** diff, tests, captures de l'implémentation Flutter, problèmes éventuels, statut exact et prochaine action.

**Message final de la mission :** « Ne me montre pas toutes les fonctionnalités de Rewayah. Montre-moi, page par page, un seul détail réel de l'application qui rend immédiatement compréhensible la promesse. Tu captures toi-même l'app Flutter et tu fournis les preuves. Si un détail est illisible ou mensonger, tu recommences le cadrage, pas la décoration. »

---

## 11. Hors périmètre strict

- Site public, landing page, SEO, mentions légales publiques : chantier distinct.
- Nouvelle identité graphique ou logo CAP-56 ; utiliser la marque existante.
- Refonte des écrans internes servant aux captures.
- Backend, Supabase, RLS, migrations, LiveKit, enregistrement média, paiements.
- Nouvelle logique pédagogique, curriculum, capacités de classe ou promesses commerciales.
- Galerie de démonstration, nouvelle navigation d'inscription, seconde route de bienvenue.

**Fin de la spécification CAP-55 / PUB-1.**
