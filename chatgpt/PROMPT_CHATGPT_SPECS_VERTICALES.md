# Prompt pour ChatGPT : spécifications verticales de tous les rôles de Rewayah Academy

Mode d'emploi pour le directeur :
1. Ouvre une nouvelle conversation ChatGPT (le modèle le plus puissant disponible, avec génération d'images).
2. Joins le fichier `DOSSIER_POUR_CHATGPT.md` (même dossier que ce prompt) et, pour le rôle Tuteur, les maquettes existantes du dossier `lancement/tutuor image/`.
3. Colle tout le texte du bloc ci-dessous.
4. Quand ChatGPT s'arrête avec « SUITE AU PROCHAIN MESSAGE », réponds seulement : `continue`.
5. Télécharge chaque fichier Markdown et chaque image livrés, et range-les sur le poste A dans `D:\RA _APP\specs chatgpt\<numéro>_<rôle>\`. Préviens Claude : il les publie pour tous les agents et les transforme en étapes du tableau de suivi.

```text
# MISSION

Tu es à la fois directeur produit, designer UX/UI senior et rédacteur UX (copywriter) de Rewayah Academy : une application Flutter (Android, iOS, web) de cours de Coran en visio par classes stables (un groupe, un horaire récurrent, un enseignant attitré). Tu écris les SPÉCIFICATIONS VERTICALES de chaque rôle, puis tu dessines les maquettes qui manquent.

Tes documents seront exécutés à la lettre par des agents de développement (Claude Code) qui n'ont PAS d'autre source que toi et le dossier joint. Tout ce que tu omets ne sera pas construit. Tout ce qui est vague sera inventé par l'agent, ce qui a déjà causé plusieurs refontes complètes de l'application. Ton travail est donc la dernière barrière contre une nouvelle refonte.

# CONSIGNE D'AUTORITÉ (priorité absolue, relis-la avant chaque document)

1. EXHAUSTIVITÉ OBLIGATOIRE. Tu traites chaque rôle, chaque écran, chaque état, chaque bouton, chaque texte visible, ponctuation comprise. Interdits : « etc. », « et ainsi de suite », « similaire à l'écran X », « à définir », « par exemple » à la place d'un contenu réel, les résumés, les listes tronquées. Si un écran ressemble à un autre, tu le réécris en entier.
2. PAS DE COMPRESSION. Si tu approches la limite de longueur d'une réponse, tu t'arrêtes à la fin d'un écran complet et tu écris exactement : « SUITE AU PROCHAIN MESSAGE : <identifiant de l'écran suivant> ». Quand je réponds « continue », tu reprends à cet écran, avec le même niveau de détail que le premier écran. Le dernier écran d'un rôle est aussi détaillé que le premier.
3. AUTO-CONTRÔLE. Chaque document se termine par une section « Auto-contrôle » : nombre d'écrans, d'états, de textes, de maquettes, et la liste des règles de ce prompt cochées une à une. Une règle non respectée se corrige avant de livrer, elle ne se déclare pas.
4. HONNÊTETÉ. Tu ne connais pas le code. Tout fait sur l'existant vient du dossier joint, cité par sa section. Ce que tu proposes de nouveau est marqué « PROPOSITION ». Ce qui contredit une décision du dossier est marqué « CONFLIT : <décision> » avec ta justification, et n'est jamais appliqué en silence.
5. PLAN FERMÉ. Tes documents définissent la fin du travail pour chaque rôle. Toute idée hors périmètre va dans une section « Hors périmètre, pour plus tard », jamais dans les écrans.

# SOURCES ET ORDRE D'AUTORITÉ

1. Mes messages dans cette conversation.
2. Les décisions du directeur du dossier joint (sections « Décisions »).
3. Les spécifications canoniques résumées dans le dossier.
4. L'inventaire des écrans, des routes et de l'état du code du dossier.
5. Les référentiels reconnus de la communauté (liste plus bas).
6. Ton expertise.

Les maquettes existantes montrent la DISPOSITION (où se trouve chaque élément, chaque action, chaque route). Leurs couleurs ne font pas foi : la palette vient uniquement du système de design gelé. Leurs erreurs listées dans le dossier ne doivent jamais être reproduites.

# ORDRE DE TRAVAIL (un document par rôle, dans cet ordre)

0. Deux guides transverses, AVANT tout rôle : `00_GUIDE_UX_UI.md` et `00_GUIDE_COPYWRITING.md`.
1. `01_TUTEUR_COMPLEMENTS.md` : les écrans et états du tuteur qui n'ont pas encore de maquette (liste dans le dossier), les fonctions annoncées (recharge de solde, solde par enfant, ajout d'enfant revu), la planche « États particuliers et notices de présence ». Les écrans du tuteur déjà spécifiés sont EN COURS DE CONSTRUCTION : tu ne les réécris pas. Tu signales seulement leurs manques sous forme « PROPOSITION ».
2. `02_CLASSE_ET_VISIO.md` : priorité n° 1 du directeur. Un élève et un enseignant se rencontrent et se voient : entrée depuis la classe, salle unique, visio, présence, reconnexion, fin de séance, côté élève, côté enseignant, notices d'observation côté enseignant et côté enfant.
3. `03_ADMIN_VALIDATION_DOSSIERS.md` : l'administration revoit et valide les dossiers d'inscription (enseignants et familles), ce qui débloque le rôle enseignant.
4. `04_ENSEIGNANT.md`
5. `05_ELEVE_ADULTE.md`
6. `06_ELEVE_ENFANT.md` : Interface guidée, lecture limitée, gros éléments, libellés parlés.
7. `07_ADMINISTRATION.md` : tous les domaines du dossier.
8. `08_CONTROLEUR_ET_INVITE.md`
9. `09_FINANCE_ET_COMPTABLE.md`
10. `10_BIBLIOTHEQUE_ET_RESSOURCES.md`
11. `11_LECTEUR_DU_CORAN.md` : fidélité au Mushaf du complexe du roi Fahd (604 pages, 15 lignes, marques hizb, juz', rub', sajda, en-têtes de sourate, numéros de verset ornés), harakat toujours visibles, lecture de droite à gauche et de haut en bas, commandes de lecture, suivi de la classe. Le texte canonique n'est jamais modifié ni recopié par toi : tu décris l'interface, pas le texte sacré.
12. `12_PUBLIC_ET_LANDING.md` : pages publiques, landing web, référencement.
13. `13_PUBLICATION.md` : App Store, Play Store, web, Windows (voir la section Publication).

# MÉTHODE VERTICALE : STRUCTURE OBLIGATOIRE DE CHAQUE DOCUMENT DE RÔLE

## 1. Fiche du rôle
Qui il est (âge, situation, aisance numérique, langue, appareil), ce qu'il vient accomplir (les 3 à 5 tâches principales, classées), ce qu'il ne doit jamais voir, ses capacités (ce qu'il PEUT faire, jamais « parce qu'il a tel rôle »).

## 2. Navigation
Les destinations principales (4 au plus), identiques en nombre et en ordre sur mobile (barre basse), tablette (rail) et ordinateur (barre latérale). Chaque destination est justifiée par une tâche récurrente. Tout le reste est atteint depuis une destination, et le chemin est écrit.

## 3. Carte des fonctions (anti-doublon)
Un tableau : fonction | écran unique | route | emplacement exact dans l'écran | point d'entrée. Une fonction apparaît UNE fois. Les seuls raccourcis admis sont listés à part, avec le flux unique qu'ils ouvrent.

## 4. Parcours de bout en bout
Chaque parcours numéroté pas à pas : point de départ, action, écran suivant, retour possible, cas d'échec, sortie. Les parcours qui traversent plusieurs rôles (exemple : l'admin valide le dossier d'un enseignant, qui peut alors rejoindre sa classe) sont décrits des deux côtés.

## 5. Fiche écran (une par écran, SANS EXCEPTION, gabarit ci-dessous)
- **Identifiant** stable (`ROLE-NN`, exemple `ENS-04`), nom, route, écran parent, destination active dans la navigation.
- **Entrées** : quels boutons de quels écrans mènent ici. **Sorties** : où mène chaque action, y compris le retour.
- **Objectif unique** en une phrase ; **action principale** (libellé exact) ; actions secondaires.
- **Disposition mobile (390 x 844)** : liste ordonnée des blocs de haut en bas ; pour chaque bloc : composant du catalogue du dossier (jamais un composant inventé si un existant convient), contenu, alignement, espacement en jetons, position de chaque bouton.
- **Disposition tablette (768) et ordinateur (1440)** : colonnes, largeurs maximales, ce qui change. Jamais une version mobile étirée.
- **Textes** : TOUS les textes visibles, exacts, ponctuation comprise : titre, sous-titre, libellés, aides, placeholders, erreurs sous les champs, confirmations, textes d'accessibilité (lecteur d'écran).
- **États**, chacun avec ses textes exacts et son action : chargement, contenu, vide, erreur du bloc, erreur de la page, hors ligne, capacité serveur indisponible (jamais de faux succès), permission refusée, succès, et les états métier propres à l'écran.
- **Données** : chaque donnée affichée, sa source (contrat serveur nommé dans le dossier, ou « CONTRAT À CRÉER : entrée, sortie, erreurs »), son format (date, heure avec fuseau, durée, monnaie, nombre).
- **Règles** : ce que le serveur décide, ce que l'écran ne doit jamais afficher (données d'un autre foyer, d'un autre élève, notes internes, secrets).
- **Accessibilité** : ordre de lecture, cibles d'au moins 48 dp, texte agrandi à 200 % sans coupure, contraste AA, statut jamais porté par la couleur seule, contenu arabe de droite à gauche, mouvement réduit.
- **Critères d'acceptation** vérifiables sur capture, au format « Étant donné / Quand / Alors », dont au moins un qui part de la navigation et TOUCHE le bouton d'entrée.
- **Référence visuelle** : nom du fichier de maquette existant, ou identifiant de la nouvelle maquette (section 7).

## 6. Copywriting du rôle
Registre et ton (voir le plan imposé plus bas), lexique imposé et interdit propre au rôle, 10 exemples « avant / après » tirés du rôle, modèles de messages (erreur, confirmation, vide, attente, indisponible).

## 7. Maquettes
- Liste des maquettes EXISTANTES réutilisées (ne pas les redessiner).
- Liste des NOUVELLES maquettes, chacune avec : identifiant (`IMG-ROLE-NN`), écran et état, format (390 x 844 ou 1440 x 900), thème (clair, sombre), puis une DESCRIPTION TEXTUELLE complète (grille, blocs dans l'ordre, textes exacts, composants, états), puis l'image générée.
- Règles de dessin : uniquement les couleurs, polices (DM Sans pour les titres, Plus Jakarta Sans pour tout le reste), rayons et espacements du système gelé ; textes réels de la spec, jamais de faux texte ; jamais de texte arabe sauf s'il est fourni tel quel dans le dossier ; aucune donnée illustrative présentée comme une règle (noms, dates, prix, compteurs) ; respect des règles d'éthique visuelle du dossier ; aucune barre d'état ni décor de planche sur l'écran lui-même.
- Si tu ne peux pas générer une image avec exactitude (textes lisibles, bonne police), livre sa description textuelle complète et marque « IMAGE À PRODUIRE » : une description exacte vaut mieux qu'une image fausse.

## 8. Dépendances serveur
Chaque capacité serveur nécessaire au rôle : nom proposé, entrée, sortie, erreurs, règle d'accès, écran concerné.

## 9. Recette du rôle
La liste des vérifications de bout en bout qui prouvent que le rôle est terminé.

## 10. Hors périmètre, pour plus tard

## 11. Auto-contrôle

# LOGIQUES UX/UI À APPLIQUER ET À CITER

Appuie chaque choix de disposition sur un référentiel reconnu, cité par son nom dans la fiche écran quand il décide quelque chose : Material Design 3 (Android, web), Apple Human Interface Guidelines (iOS), WCAG 2.2 niveau AA, les 10 heuristiques de Nielsen, les lois de l'UX (Fitts, Hick, Jakob, proximité, Miller), les recherches Baymard sur les formulaires, le GOV.UK Design System (langage simple, une question par page quand c'est utile, messages d'erreur), les bonnes pratiques Nielsen Norman Group pour les états vides et les messages d'erreur. `00_GUIDE_UX_UI.md` rassemble ces règles une fois pour toutes, avec la règle appliquée à Rewayah pour chacune.

Règles du directeur, non négociables :
- un titre, une tâche et une seule action pleine par écran ;
- une carte qui regroupe plusieurs éléments est UN seul rectangle, séparé en lignes par de fins filets ; jamais un rectangle par ligne, jamais des rectangles collés ;
- navigation, retour et déconnexion toujours accessibles, aucune impasse ;
- le web est une vraie version ordinateur ;
- rien n'est affiché comme fait, réussi ou disponible sans que le serveur le garantisse ;
- une fonction a un seul endroit.

# PLAN DE COPYWRITING IMPOSÉ (écrit en détail dans `00_GUIDE_COPYWRITING.md`)

Langue : français, niveau de lecture simple (phrases de 20 mots au plus, un message = une idée), typographie française (espace fine insécable avant « ? ! : ; », guillemets « », apostrophe ’). Aucun emoji. Aucun tiret cadratin : utilise la virgule, les deux-points ou une nouvelle phrase. Aucun code interne visible.

Registres par rôle (à respecter, et à signaler en « CONFLIT » si tu penses devoir les changer) :
| Rôle | Registre | Ton |
|---|---|---|
| Tuteur, famille | vouvoiement | chaleureux, rassurant, concret, jamais culpabilisant |
| Élève adulte | vouvoiement | encourageant, respectueux, orienté progrès |
| Élève enfant (Interface guidée) | tutoiement bienveillant | phrases de 10 mots au plus, verbes d'action, pictogramme et libellé ensemble, libellé parlé disponible |
| Enseignant | vouvoiement | professionnel, précis, orienté action, vocabulaire pédagogique autorisé |
| Administration, contrôle, finance | vouvoiement | neutre, factuel, dense, termes métier exacts, conséquences des actions explicites |

Lexique imposé : « Classe » (jamais « groupe » à l'écran), « Séance », « Sayyid » / « Sayyida » pour les enseignants dans l'espace de cours, « Interface guidée », « Ajouter un profil élève », « Séance en direct ». Lexique interdit : « Session », « Cours en cours », « Ajouter enfant », « mode enfant », « matching », les codes internes. Un bouton dit exactement ce qu'il fait. Une erreur dit ce qui s'est passé et comment reprendre, sans excuse vague. Aucune promesse de date (« bientôt »). Formules religieuses : proposer, marquer « PROPOSITION », jamais imposer.

# PUBLICATION (`13_PUBLICATION.md`)

Tout ce qu'il faut pour publier : fiches App Store et Play Store (textes, captures à produire par format, mots-clés), catégorie et classement d'âge, règles spécifiques aux applications utilisées par des enfants (Apple Kids Category, programme Google Families, RGPD pour les mineurs et consentement parental, COPPA si des familles américaines sont visées), étiquettes de confidentialité (App Privacy, Data safety), suppression de compte depuis l'application (exigée par les deux stores), notes pour les relecteurs des stores (compte de démonstration, visio), mentions légales et politique de confidentialité à écrire, e-mails et notifications transactionnels (textes exacts), page web publique et référencement, publication Windows. Chaque exigence cite la règle du store ou du texte qui l'impose, et marque « À VÉRIFIER » ce qui peut avoir changé depuis ta date de connaissance.

# FORMAT DE LIVRAISON

- Un fichier Markdown téléchargeable par document, nommé comme dans l'ordre de travail, avec un en-tête : titre, version (V1), date, statut « PROPOSITION À VALIDER PAR LE DIRECTEUR ».
- Titres Markdown, tableaux, listes numérotées ; pas de HTML.
- Identifiants stables (`ROLE-NN`, `IMG-ROLE-NN`) réutilisés partout pour que les agents puissent cocher chaque élément.
- Les images générées sont livrées à part, nommées par leur identifiant (`IMG-ENS-04_mobile_clair.png`).
- Commence maintenant par `00_GUIDE_UX_UI.md`, puis `00_GUIDE_COPYWRITING.md`, puis `01_TUTEUR_COMPLEMENTS.md`. Avant d'écrire, résume en 10 lignes ce que tu as compris du dossier joint et liste les documents joints que tu n'arrives pas à lire.
```
