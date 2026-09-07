# Parcours utilisateurs complets - Rewayah Academy App
## MVP-0, ce qui s'affiche pour chaque rôle

Périmètre : MVP-0 (ADR-003). Codes d'écran repris de vos specs, corrigés des décisions ADR-001 à ADR-010.

> **Depuis l'ADR-018, ce document n'est plus la seule source pour un écran.**
> Il dit **ce que l'écran contient** et pourquoi, ce qui reste vrai et fait
> autorité. Il ne dit plus **à quoi il ressemble ni comment il se comporte** :
> surfaces, couleurs, mouvement, gabarits, états et registre visuel sont dans
> `docs/design/`, et le registre des écrans avec leur présentation mobile et
> desktop est dans `docs/design/08-catalogue-ecrans.md`.
>
> Les mentions de « direction artistique » ci-dessous restent des intentions
> valides ; quand elles rencontrent une règle de `docs/design/`, c'est la règle
> qui tranche.

---

## Règles d'affichage communes à tous les écrans

Ces règles évitent d'avoir à les répéter écran par écran.

**Ce que personne ne voit jamais.** L'enseignant ne voit ni nom de famille complet, ni courriel, ni téléphone, ni adresse d'une famille. Il voit prénom plus identifiant immuable. C'est le contrôle anti-pillage qui remplace le filigrane (ADR-008).

**Un écran, une action principale.** Un seul bloc dominant par écran. Tout le reste est visiblement secondaire. Si deux blocs se disputent l'attention, l'écran est raté.

**Trois états à concevoir, pas un.** Chaque écran existe en état normal, état vide et état dégradé (hors ligne ou erreur). Un état vide est une invitation, pas une excuse : "Aucun cours aujourd'hui, ton prochain cours est jeudi", pas "Aucune donnée".

**Rien ne se ferme tout seul.** Aucun écran ne disparaît sur minuterie, aucun compte à rebours anxiogène.

**Le hors ligne ne bloque qu'une chose.** Sans réseau, tout reste consultable depuis le cache : planning, Coran, historique. Seules l'entrée en séance et la validation d'un rapport nécessitent le réseau, et le rapport se met en file d'attente au lieu d'échouer.

---

# 1. TUTEUR

C'est le rôle pivot. Rien n'existe avant qu'un tuteur ait terminé son parcours.

## Parcours de première fois

| # | Étape | Écran | Ce qui se passe |
| :-- | :--- | :--- | :--- |
| 1 | Connexion | `TUT-00` | Google ou courriel. Aucun mot de passe à retenir |
| 2 | Portail d'attente | `TUT-00b` | Compte créé mais rien n'est accessible. L'écran explique ce qui manque, pas ce qui est interdit |
| 3 | Identité | `TUT-00c` | Pièce d'identité et signature du contrat. Cartes cliquables, saisie minimale |
| 4 | Attente | `TUT-00b` | Statut visible, délai annoncé. Notification à la validation |
| 5 | Premier enfant | `TUT-02` | Prénom, âge, niveau. L'âge fixe la politique caméra et le mode d'interface |
| 6 | Disponibilités | `TUT-04` | La famille pose ses créneaux. **Sans cette étape, le matching inversé n'a rien à afficher** |
| 7 | Attente de match | `TUT-01` | Le foyer voit "En recherche d'un enseignant" avec un délai indicatif |
| 8 | Appairage | `TUT-02` | QR à scanner sur l'appareil de l'enfant, ou code à 6 caractères |
| 9 | Premier cours | `TUT-01` | Le foyer bascule en usage courant |

L'étape 6 est un écran absent de vos specs. Voir la section des manques en fin de document.

## Écrans

### `TUT-00c` Identité et contrat

Déroulé en trois temps plutôt qu'un formulaire long : identité, contrat, confirmation. Chaque étape a un seul bouton d'action.

**Direction artistique.** Avant de demander une pièce d'identité, l'écran explique en deux lignes ce que le contrat protège et pourquoi, avec les points sensibles (enregistrement, contrôle invisible) nommés en clair et non enfouis dans un texte long. Une estimation du temps restant en bas d'écran réduit l'incertitude, qui est la vraie source de friction sur ce type d'écran, plus que la longueur du formulaire lui-même.

### `TUT-00b` Portail d'attente

| État | Ce qui s'affiche |
| :--- | :--- |
| Dossier incomplet | Une liste de deux ou trois éléments à fournir, chacun avec son bouton. Pas de formulaire long |
| En attente de validation | Statut, date de dépôt, délai annoncé. Un seul bouton : contacter l'académie |
| Refusé | Le motif en une phrase, et l'action pour corriger |

L'écran ne montre jamais l'application derrière un voile. Un portail qui laisse deviner ce qu'on rate crée de la frustration.

### `TUT-01` Accueil famille

Bloc dominant en haut : l'état en direct de chaque enfant, une ligne par enfant.

| État de l'enfant | Ce qui s'affiche |
| :--- | :--- |
| En cours | Prénom, pastille verte, nom de l'enseignant, minuteur écoulé, bouton "Assister" |
| Cours à venir aujourd'hui | Prénom, heure, enseignant |
| Rien aujourd'hui | Prénom, prochain cours daté |
| En recherche d'enseignant | Prénom, statut, date de la demande |
| Séance annulée | Prénom, motif, et ce qui est proposé |

Blocs secondaires : ajouter un appareil, réglages du foyer, et en MVP-0 la date de fin d'accès de chaque enfant (`access_until`) au lieu d'un portefeuille.

Le bouton "Assister" est la fonction de confiance la plus forte du produit. Il entre en observateur muet, l'enseignant le voit arriver.

### `TUT-02` Foyer et appareils

Deux sections en liste dense, pas en grandes cartes : c'est un écran de gestion, pas de suivi affectif, le registre visuel doit le dire. Les enfants, avec pour chacun sa photo réelle, prénom, âge, et l'état de sa politique caméra visible d'un coup d'œil sans ouvrir le détail. Les appareils appairés, avec pour chacun le type, la dernière utilisation, le profil qui l'a utilisé, et un bouton de révocation.

À la limite de deux appareils, le bouton d'ajout se remplace par un message explicite plutôt que de rester actif puis d'échouer : un bouton qui échoue après le geste coûte plus cher en confiance qu'un bouton absent.

L'ajout d'un appareil affiche un QR grand format plus le code à 6 caractères en dessous, avec le délai de validité visible qui s'écoule.

Rappel de la règle ADR-010 affichée en clair : deux appareils au maximum, un seul en séance à la fois.

### `TUT-04` Disponibilités du foyer

Écran nouveau. Une grille de la semaine, par enfant, où le tuteur pose ses créneaux possibles en tapant dessus. Pas de saisie d'heures.

Sous la grille, une phrase qui dit ce que cela produit : "Un enseignant choisira parmi ces créneaux. Plus vous en proposez, plus vite le cours démarre."

### `TUT-05` Réglages par enfant

Écran nouveau, issu de l'ADR-009. Un enfant par carte, avec trois réglages.

La photo de profil, modifiable à tout moment (ADR-012). Le remplacement écrase l'ancienne version partout, y compris en cache sur les appareils appairés.

La caméra, en bascule simple : autorisée ou non, avec la valeur initiale posée selon l'âge. Le texte explique la conséquence : "Amina peut allumer sa caméra pendant le cours si elle le souhaite" ou "Le bouton caméra n'apparaîtra pas pour Ibrahim".

Le mode d'interface, enfant ou standard, modifiable si l'âge par défaut ne convient pas.

Ces trois réglages se font à distance, enfant par enfant, et s'appliquent à la séance suivante. Jamais pendant un cours.

### `TUT-06` Après le cours

Accessible depuis l'accueil. Historique par enfant des cahiers de transmission : date, enseignant, ce qui a été travaillé, les points de phonétique relevés.

Une notification part à la fin de chaque séance, avec le contenu utile dans la notification elle-même, pas seulement "un nouveau rapport est disponible". C'est ce qui justifie l'abonnement aux yeux du parent qui paie.

---

# 2. ÉLÈVE

Deux modes portés par le profil, pas par le rôle (ADR-009).

## Mode enfant, environ 6 à 8 ans

### `ELV-01` Connexion

Deux blocs massifs. Scanner le QR, ou entrer le code. Sur un appareil déjà appairé, cet écran ne réapparaît jamais : l'enfant voit directement le choix de profil.

**Choix de profil sur appareil partagé.** Les enfants du foyer sont représentés par leur photo réelle, ajoutée et modifiable par le tuteur (ADR-012), avec un repli sur les initiales tant qu'aucune photo n'est ajoutée. Composition volontairement asymétrique, en léger décalage horizontal d'une tuile à l'autre, pour que l'écran ressemble à une invitation plutôt qu'à un menu de réglages. Un tap sur sa tuile, puis le PIN à 4 chiffres sur un pavé numérique géant. Le PIN ne quitte pas l'appareil (ADR-005). La photo n'est jamais exposée à l'enseignant ni aux autres élèves, voir ADR-012.

### `ELV-02` Accueil

Deux blocs. Rien d'autre. C'est l'écran montré en maquette.

| État | Bloc principal |
| :--- | :--- |
| Cours dans plus d'une heure | Illustration, durée restante en gros, haut-parleur qui lit la phrase |
| Cours dans moins de 5 minutes | Le bloc devient violet et pulse doucement |
| Cours en direct | "Rejoindre", prénom de l'enseignant, pastille verte |
| Aucun cours aujourd'hui | Le prochain cours, exprimé en jours et non en date |
| Séance annulée | Illustration neutre, message court, et le prochain cours. Aucune explication technique |
| Hors ligne | L'écran reste identique, seul le bloc Rejoindre est grisé avec un pictogramme de réseau |

Deuxième bloc, permanent : le Coran.

Pas de bloc évaluations en MVP-0. Pas de bandeau d'annonces en mode enfant. Pas de bouton rouge de signalement, remplacé par la détection serveur (audit 1.2).

### `ELV-03` Salle de cours

Deux commandes seulement : le micro et la sortie. **À l'entrée en séance, le micro ne publie rien tant que l'élève n'a pas tapé dessus une fois** : aucune ouverture automatique, conformément à vos specs d'origine. Quand la politique caméra du profil est interdite, **le bouton caméra n'existe pas sur l'écran**, il n'est pas grisé. Un bouton visible mais inactif invite à appuyer dessus ; son absence ne pose pas la question.

Le flux de l'enseignant occupe l'écran. La vignette de l'enfant est petite, en bas, et disparaît si sa caméra est coupée.

Bandeau permanent en bas de salle, identique pour tous et à tout instant : cours enregistré, visite de contrôle possible (ADR-002 et ADR-011). Il ne change jamais, y compris pendant une visite. Un bandeau conditionnel supprimerait l'invisibilité.

Un bouton flottant unique : ouvrir le Coran. Sur téléphone, il s'ouvre en plein écran avec la visio en vignette et l'audio prioritaire. Sur tablette, il partage l'écran (audit 1.4).

Quand l'enseignant pousse une page, l'enfant la reçoit sans rien chercher.

Sortie : une confirmation en un tap, puis retour à `ELV-02` avec une animation d'encouragement de moins d'une seconde.

### `ELV-04` Coran

Lecture libre des 30 Juz', sélecteur de sourate, marque-pages. En mode enfant, le sélecteur affiche les sourates par nom et numéro en gros, sans recherche textuelle.

**Direction artistique.** Un fond légèrement plus chaud que le reste de l'application, pour signaler qu'on entre dans un espace différent du produit. Un seul liseré géométrique fin en haut de page, jamais un cadre doré complet qui verserait dans le pastiche. **Le texte n'est jamais représenté par de faux caractères arabes**, même en mockup : des blocs neutres tiennent la place, pour ne jamais donner l'impression de fabriquer un verset. Le rendu réel utilisera les pages pré-rendues du mushaf retenu (audit 1.4), pas une composition typographique à la volée. Bandeau "suivre le professeur" quand ce mode est actif, discret, jamais un chevauchement du texte.

## Mode standard, 9 ans et plus, y compris les élèves adultes autonomes

Même architecture, écran plus dense.

`ELV-02` gagne : la semaine à venir, l'historique des cahiers de transmission, le bandeau d'annonces.

`ELV-03` gagne : la liste des participants en cours de groupe, affichée en prénom plus identifiant en petits caractères (ADR-004), et le contrôle caméra si le profil l'autorise.

L'élève adulte autonome voit en plus ce qu'un tuteur voit pour lui-même : ses disponibilités, ses réglages, ses appareils. C'est le même écran, puisqu'il est son propre foyer.

---

# 3. ENSEIGNANT

## Parcours de première fois

Connexion, portail d'attente, dépôt de la pièce d'identité, signature du contrat de non-concurrence, validation admin, puis déclaration des disponibilités et accès au feed de matching.

Le contrat doit mentionner explicitement l'enregistrement audio et la possibilité d'un contrôle invisible (ADR-002 et ADR-011). Un enseignant qui découvre ces dispositifs après coup est un litige. À la première connexion, une carte courte reprend les deux points et se fait accuser une fois.

## Écrans

### `ENS-02` Journée

Bloc dominant : le prochain cours. Prénom et identifiant de l'élève, minuteur avant le début, et le bouton de lancement qui devient actif après le pre-flight.

Sous ce bloc, la journée en liste : les cours suivants avec heure, prénom, durée. Les pauses de 30 minutes et les horaires de prière apparaissent dans cette même liste, comme des entrées à part entière et non comme un bloc séparé. Un enseignant qui enchaîne 5 cours lit une seule colonne du haut vers le bas.

Bloc secondaire : le feed de matching, avec le nombre de créneaux disponibles et l'accès à `ENS-06`.

En MVP-0, pas de bloc solde ni de paie.

| État | Bloc dominant |
| :--- | :--- |
| Cours dans plus de 15 min | Minuteur, bouton pre-flight |
| Pre-flight passé | Bouton de lancement actif |
| Pre-flight échoué | Ce qui a échoué et comment le corriger, en une phrase par point |
| Élève absent à T+5 | Constat automatique affiché, avec la conséquence |
| Journée terminée | Récapitulatif, et les rapports encore à déposer |
| Rapport en retard | Rappel persistant en haut, non masquable |

### `ENS-03` Salle de cours

Flux de l'élève au centre. Vignette de l'enseignant. Même bandeau permanent que côté élève, jamais modifié par la présence d'un contrôleur. **Micro et caméra de l'enseignant démarrent également désactivés à l'entrée**, un tap sur chacun les active : la règle de clic volontaire de vos specs d'origine s'applique à tous les rôles, pas seulement à l'élève.

**"Pousser la page suivante" est un bouton de premier niveau, pas une action cachée dans un menu Coran.** C'est lui qui rend le Coran utilisable par un enfant de 6 ans : l'enseignant navigue, l'enfant reçoit. Une pastille rappelle en permanence la page actuellement montrée à l'élève, pour que l'enseignant n'ait jamais à demander "tu es à quelle page".

Commandes en bas : micro, caméra, Coran, quitter. La caméra de l'enseignant reste une commande active en permanence, contrairement à celle de l'élève qui peut ne pas exister du tout selon le profil.

Quitter mène obligatoirement à `ENS-04`. Aucun autre chemin.

### `ENS-04` Cahier de transmission

L'écran le plus contraint du produit : remplissable en moins de 45 secondes, sur un téléphone d'entrée de gamme, à une main, hors ligne.

Trois zones. Ce qui a été travaillé, en sélection de cartes. La matrice de phonétique, en puces géantes à cocher, quatre paires par défaut. Une note libre facultative.

Un bouton unique de validation. Hors ligne, il enregistre localement et affiche "sera envoyé dès le retour du réseau", sans bloquer l'enseignant sur son cours suivant.

### `ENS-06` Disponibilités et matching

Deux onglets sur un même écran. Mes disponibilités, en grille de semaine identique dans sa forme à `TUT-04`. Les créneaux libres, en liste de cartes : prénom de l'élève, identifiant, niveau, jour et heure, bouton "Prendre".

**Tri par ancienneté d'attente, pas par ordre alphabétique ni par date de créneau.** Un liseré de couleur signale les demandes en attente depuis plusieurs jours. Sans ce tri, un élève peut rester invisible en bas de liste indéfiniment, ce qui viderait le matching inversé de son intérêt.

Un créneau pris par un autre enseignant disparaît en direct. Si deux enseignants cliquent au même instant, l'un reçoit un message clair et la carte disparaît. La base tranche, pas l'écran (contrainte C2). Une phrase en bas d'écran explique ce comportement, pour qu'il ne se lise pas comme un bug.

---

# 4. CONTRÔLEUR

### `CTR-01` Planning global

Vue de toutes les séances en cours et à venir, en heure locale du contrôleur avec l'heure UTC en second. Filtres par enseignant et par état.

Chaque ligne en cours porte un bouton d'entrée invisible.

### `CTR-02` Observation invisible

Le contrôleur voit et entend, n'est pas listé, ne publie rien. Un bandeau noir permanent lui rappelle son statut, parce que c'est le genre d'écran où l'on oublie qu'on est invisible.

Sa liste de participants affiche exactement la même chose que celle de l'enseignant : deux personnes. Lui-même n'y figure pas. C'est le test visuel de la fonction.

Chaque entrée est écrite dans le journal d'audit avec son identité, la séance, l'heure et la durée. L'invisibilité s'applique aux participants, pas à la traçabilité.

Régime complet en ADR-011 : interdiction de cumuler enseignant et contrôleur, vérification d'identité au même niveau qu'un enseignant, et détection des motifs d'observation anormaux.

En MVP-0, la grille d'audit `CTR-03` est reportée. Le contrôleur observe et signale, il ne note pas encore.

---

# 5. ADMIN

### `ADM-01` Centre de commande

Cinq indicateurs en haut : dossiers en attente de validation, foyers sans enseignant, rapports de cours manquants, incidents des dernières 24 heures, et comptes provisoires arrivés à échéance (ADR-014). **Le zéro s'affiche comme les autres valeurs**, jamais masqué : un compteur qui disparaît à zéro fait douter s'il a été chargé ou s'il est réellement nul.

Sous les quatre chiffres, une liste "à traiter en premier" qui ordonne les cas concrets par ancienneté, avec un tap qui mène directement à l'écran d'action correspondant (`ADM-02` ou `ADM-05`). L'admin ne doit jamais avoir à retraverser un menu pour agir sur ce que le tableau de bord vient de signaler.

Ces quatre chiffres sont les seules choses qu'un opérateur solo doit regarder chaque matin. Tout le reste est accessible mais pas mis en avant.

### `ADM-02` Validation des dossiers

File d'attente, un dossier à la fois plutôt qu'une grille de vignettes : la vérification d'identité mérite une attention séquentielle, pas un balayage rapide.

**Séparation stricte entre le constat et le jugement.** L'aperçu du document occupe le haut de l'écran, la checklist de vérification le milieu, les deux verdicts le bas, dans cet ordre et jamais mélangés. L'aperçu du document reste volontairement abstrait dans cette maquette : aucune pièce d'identité réelle ou vraisemblable n'est représentée.

Règle d'accès appliquée par la base : un membre du personnel masculin ne voit aucun document d'un dossier féminin (audit 1.3). Chaque consultation est journalisée, rappelé en toutes lettres sous les boutons de décision.

### `ADM-05` Attribution manuelle

Écran de secours quand le matching inversé ne produit rien. Liste des foyers en attente, liste des enseignants disponibles, attribution en deux taps.

### `ADM-04` Journal d'audit

Lecture seule. Filtres par acteur, par type d'événement, par période. Aucun bouton d'action, aucune exception.

En MVP-0, le séquestre `ADM-03` et les exports sont reportés.

### `ADM-05` Attribution manuelle

Même registre que `ENS-06` : deux listes côte à côte plutôt qu'un formulaire, foyers en attente à gauche, enseignants disponibles à droite, un tap sur chaque puis un bouton de confirmation. Aucun nouvel arbitrage visuel : c'est le même geste de matching que celui de l'enseignant, vu depuis l'administration.

---

# 6. COMPTABLE

Aucun écran en MVP-0 (ADR-003). Le rôle existe dans le modèle de données et dans le contrôle d'accès, l'interface arrive en V1 avec le module finance.

---

# Modèle de navigation

Règle unique : **aucun rôle n'a plus de quatre destinations de premier niveau, et l'enfant n'en a aucune.**

| Rôle | Destinations | Forme |
| :--- | :-- | :--- |
| Élève, mode enfant | 0 | Aucune navigation. Deux blocs, retour automatique après le cours |
| Élève, mode standard | 3 | Barre basse : accueil, Coran, suivi |
| Tuteur | 4 | Barre basse : foyer, disponibilités, réglages, suivi |
| Enseignant | 3 | Barre basse : journée, créneaux, profil |
| Contrôleur | 1 | Une liste, pas de barre |
| Admin | 4 | Menu latéral : tableau de bord, dossiers, attribution, journal |

Un enfant de 6 ans ne navigue pas, il tape sur ce qu'il voit. Un contrôleur n'a qu'un travail. Un enseignant qui enchaîne cinq cours ne doit jamais chercher où il est.

**Heures affichées.** Chaque rôle voit son heure locale, avec la mention du fuseau quand deux fuseaux se croisent. La famille pose ses créneaux en heure de Paris, l'enseignant les lit en heure de Conakry, la base ne connaît que l'UTC. C'est aussi pour cela qu'une récurrence porte un fuseau IANA et non une heure absolue : sans quoi tous les cours se décalent au changement d'heure.

---

# Écrans absents de vos specs d'origine

Cinq manques identifiés en construisant les parcours.

| Écran | Pourquoi il manque | Conséquence sans lui |
| :--- | :--- | :--- |
| `TUT-04` Disponibilités du foyer | Le matching inversé suppose que les créneaux élèves existent, mais aucun écran ne les produit | Le feed de l'enseignant est vide en permanence |
| `TUT-05` Réglages par enfant | Issu de la décision caméra par enfant | Le tuteur ne peut pas appliquer sa règle |
| `ENS-06` Disponibilités enseignant | Le bloc matching de `ENS-02` est un raccourci, pas un écran | L'enseignant ne peut pas déclarer quand il travaille |
| État "séance annulée" | Les specs traitent l'absence à T+5, pas l'annulation anticipée | L'enfant ouvre l'app à 17h et ne comprend pas |
| État hors ligne | Aucune mention dans les specs | Écran blanc au premier trou réseau, en Guinée comme dans le métro |

---

# Matrice de routage mise à jour

| Écran source | Action | Écran cible | Règle |
| :--- | :--- | :--- | :--- |
| `TUT-00c` | Dossier soumis | `TUT-00b` | Aucun accès avant validation |
| `ADM-02` | Validation | `TUT-01` ou `ENS-02` | Activation immédiate, notification poussée |
| `TUT-02` | Enfant créé | `TUT-04` | Redirection volontaire : sans disponibilités, rien ne démarre |
| `TUT-04` | Créneaux posés | `ENS-06` | Le créneau apparaît dans le feed de tous les enseignants éligibles |
| `ENS-06` | Créneau pris | `ENS-02` | Association tranchée en base |
| `ELV-02` | Rejoindre | `ELV-03` | Refusé si le profil est déjà en séance ailleurs (ADR-010) |
| `ENS-02` | Lancer | `ENS-03` | Refusé sans pre-flight validé |
| `ENS-03` | Quitter | `ENS-04` | Chemin unique et obligatoire |
| `ENS-04` | Valider | `ENS-02` | Hors ligne, mise en file sans blocage |
| `CTR-01` | Observer | `CTR-02` | Entrée journalisée |
| `TUT-01` | Assister | `ELV-03` en observateur | Publication interdite par le token |

---

# Langue de l'écran élève — tranché

**Français.** Chaînes externalisées, clés en points, arabe déclaré et vide, prêt à remplir sans reprise de code.

**Pas de poular**, décision de l'opérateur du 6 septembre 2026 (ADR-015). Cette section proposait à l'origine de le préparer : ce n'est plus le cas, ni pour le texte ni pour les libellés audio.

Les libellés audio comptent plus que le texte pour les moins de 8 ans : c'est le sens du composant `AudioLabel`, qui retrouve un fichier son à partir de la même clé que le texte, pour que les deux ne puissent pas diverger. La liste des libellés parlés est dans `lib/core/i18n/cle_audio.dart` ; **les fichiers son eux-mêmes restent à enregistrer**, `assets/audio/fr/` est encore vide.
