# 02 — Règles UX

Ces règles s'appliquent à tous les écrans, tous les rôles, les deux modes
d'interface. Elles complètent les « règles d'affichage communes » de
`docs/produit/parcours-utilisateurs.md`, qu'elles ne remplacent pas.

## 1. Un écran, une fonction

Un écran répond à **une** question. Le tableau de bord n'est pas un entrepôt.

| Écran | La question à laquelle il répond |
| :--- | :--- |
| `ADM-01` | Qu'est-ce qui nécessite mon intervention maintenant ? |
| `CTR-01` | Qu'est-ce qui nécessite une vérification ? |
| `ENS-02` | Qu'est-ce que j'ai à faire aujourd'hui ? |
| `ELV-02` | Quand est mon prochain cours, et comment j'y entre ? |
| `TUT-01` | Comment vont mes enfants, et qu'est-ce que je dois confirmer ? |
| `TUT-02` | Qui a accès, depuis quel appareil ? |
| `ENS-06` | Qui attend un enseignant, et quand suis-je libre ? |
| `ADM-06` | Quelle règle s'applique à cet élève, et qui l'a demandée ? |

Si un écran ne peut pas s'écrire en une question, il en contient deux et doit
être coupé.

**Un seul bloc dominant.** Tout le reste est visiblement secondaire : plus
petit, moins contrasté, plus bas. Si deux blocs se disputent l'attention,
l'écran est raté.

## 2. Ce qui nécessite une action passe avant ce qui informe

C'est la règle qui distingue un tableau de bord d'un rapport.

```
1. Ce que je dois traiter          ← en premier, toujours
2. L'état d'ensemble               ← les chiffres
3. Les tendances                   ← les graphiques
4. L'activité récente              ← le journal
```

Un signal mène **directement** à son écran d'action, jamais à un menu. Le
parcours attendu est `signal → décision → action`, pas
`tableau de bord → statistiques → menu → recherche → action`.

« 17 foyers sans enseignant » se tape, ouvre les 17, triés par ancienneté, avec
le bouton d'attribution sur chaque ligne.

**Le zéro s'affiche comme les autres valeurs**, jamais masqué : un compteur qui
disparaît à zéro fait douter s'il a été chargé ou s'il est réellement nul. Règle
déjà posée pour `ADM-01`, généralisée ici à tous les compteurs du produit.

## 3. Dévoilement progressif

Montrer ce dont l'utilisateur a besoin maintenant. Le reste existe, derrière un
geste.

| Toujours visible | Derrière un geste |
| :--- | :--- |
| Fréquent | Rare |
| Important | Avancé |
| Nécessaire au contexte présent | Destructif |
| L'action principale | Secondaire ou administratif |

Exemple, un enseignant qui ouvre un élève :

```
Aicha · ID-24
Prochain cours · Progression · Présence · Dernière transmission
                    [ Voir plus ]
                          ↓
   historique, transmissions précédentes, notes, documents
```

Corollaire : **pas sept boutons sur une ligne**. Une action principale, une
secondaire au plus, le reste dans un menu « Plus ».

## 4. Hiérarchie des actions

Quatre niveaux, pas cinq. Le composant `ActionPrincipale` porte déjà les trois
premiers ; le quatrième s'ajoute au lot C.

| Niveau | Forme | Combien par écran |
| :--- | :--- | :--- |
| Principale | Fond plein `surfacePrimary` | **Une seule.** Zéro si l'écran est en lecture |
| Secondaire | Contour `borderStrong`, fond `surfaceRaised` | Deux au plus |
| Tertiaire | Texte `inkAccent`, sans contour | Autant que nécessaire, mais jamais alignées comme des boutons |
| Destructive | Texte `inkAlert`, jamais un fond rouge plein | Jamais dans la zone principale |

Toute action a un état pressé visible. La cible tactile minimale est celle du
mode courant, 44 en standard et 72 en mode enfant, déjà portée par
`AppMetriques`.

## 5. Le destructif, en trois temps

Jamais `clic → suppression`. Le motif est :

```
geste          →  confirmation  →  conséquence expliquée  →  action
```

La conséquence est écrite en langage humain, jamais technique :

> **Retirer Aicha du foyer ?**
> Son accès à l'académie sera désactivé et ses cahiers de transmission ne
> seront plus consultables depuis ce foyer.
>
> [ Annuler ]   [ Retirer ]

Puis la disparition est **animée**, jamais instantanée : `04-systeme-mouvement.md`
motif « suppression ». Et un retour local, court, à la place de la ligne
disparue.

Règles :

- Le bouton destructif n'est jamais le premier atteint au doigt ni le premier au
  clavier.
- Le libellé nomme l'objet et l'acte : « Retirer Aicha », jamais « Supprimer ».
- **Ce qui n'est pas réversible le dit.** Ce qui l'est propose l'annulation
  pendant quelques secondes, dans le retour local, plutôt qu'une confirmation.

## 6. Les états, partout

Ce n'est pas une recommandation. Un composant interactif qui ne les prévoit pas
n'entre pas dans le catalogue.

**Composant interactif** : `default`, `hover` (web et desktop), `pressed`,
`focus` (clavier), `disabled`, `loading`.

**Écran ou zone de données** : `loading`, `content`, `empty`, `error`,
`offline`.

Un écran livré avec seulement `content` n'est pas fini. La revue le refuse.

### Chargement

Un squelette, jamais un texte « Chargement… ». Et un squelette qui **ressemble à
la structure finale** : mêmes hauteurs, mêmes nombres de blocs. Un squelette
générique déplace le contenu au moment où il arrive, ce qui est pire que rien.

Sous 200 ms, on n'affiche rien du tout : un squelette qui clignote coûte plus
qu'il ne rassure.

### Vide

Un écran vide n'est pas un bug, c'est une invitation. Trois cas, trois textes
différents :

| Cas | Ce qu'on écrit |
| :--- | :--- |
| L'utilisateur peut agir | « Aucun créneau posé. Un enseignant choisira parmi ceux que vous proposez. » + le bouton |
| L'utilisateur ne peut rien faire | « Votre enseignant n'a pas encore publié votre planning. » Aucun bouton |
| C'est une bonne nouvelle | « Aucun dossier en attente. » Ton neutre, pas de félicitations |

Le troisième cas est celui qu'on oublie : un tableau de bord d'administration
vide veut dire que tout va bien, et ne doit pas ressembler à une panne.

### Erreur

Jamais « Une erreur est survenue ». Trois éléments, dans cet ordre :

```
quoi         Impossible de charger vos messages.
pourquoi     Votre connexion semble interrompue.
quoi faire   [ Réessayer ]
```

L'erreur se pose **sur l'élément concerné**, pas en plein écran. Un formulaire
dont un champ échoue montre l'erreur sous le champ, pas une bannière au dessus
du titre. Le plein écran est réservé au cas où l'écran entier n'a rien à montrer.

Aucun code technique visible, aucun identifiant de requête, aucun message
d'exception. S'il faut une référence pour le support, elle se copie depuis un
menu discret.

### Hors ligne

Déjà tenu par `OfflineBanner`. La règle : **le hors ligne dégrade, il ne bloque
pas**. Tout ce qui est en cache reste consultable. Seuls l'entrée en séance et
la validation d'un rapport ont besoin du réseau, et le rapport se met en file
plutôt que d'échouer.

Un contrôle indisponible hors ligne se grise **et dit pourquoi** au contact.

## 7. Le retour d'action

Proportionné à l'acte.

| Acte | Retour |
| :--- | :--- |
| Bascule d'un réglage | La bascule bouge. Rien d'autre |
| Créneau ajouté | La case change d'état, plus un retour local court en bas d'écran |
| Rapport envoyé | Retour local, et la ligne quitte la liste des rapports dus |
| Rapport mis en file hors ligne | Retour local persistant tant que la file n'est pas vidée |
| Dossier validé | La file avance sur le dossier suivant. Le retour est l'avancement lui-même |

Jamais de boîte de dialogue de succès. Une boîte de dialogue demande un geste
pour dire qu'un geste a réussi.

## 8. Notifications : quatre registres

| Registre | Exemple | Comportement |
| :--- | :--- | :--- |
| Information | Nouveau cahier de transmission | Groupable, silencieuse, consultable plus tard |
| Action requise | Rapport de cours manquant | Persistante tant que l'action n'est pas faite, non masquable |
| Temps réel | L'enseignant vous a partagé une page | Éphémère, contextuelle, jamais de son |
| Urgence | Votre cours commence dans 5 minutes | Prioritaire, une seule fois, jamais répétée |

Une notification d'information contient **le contenu utile**, pas une invitation
à ouvrir l'application. « Aicha a travaillé Al-Baqarah, 2 points de phonétique
relevés » plutôt que « un nouveau rapport est disponible ». C'est ce qui
justifie l'abonnement aux yeux de qui paie.

## 9. Écriture

Les règles anti-IA de `design-tokens.md` §6 s'appliquent sans exception. Trois
ajouts propres aux interfaces :

- **Le libellé d'un bouton est un verbe et son objet** : « Poser un créneau »,
  pas « Valider ». Un utilisateur qui lit le bouton doit pouvoir sauter le titre.
- **Un titre d'écran ne se souhaite pas la bienvenue.** « Aujourd'hui », pas
  « Bienvenue sur votre tableau de bord ».
- **Une durée s'exprime dans l'unité que l'utilisateur emploie.** « Dans 2
  jours », pas « le 9 septembre » pour un enfant ; l'inverse pour un comptable.

## 10. Ce qu'on ne fait jamais

- Fermer un écran sur minuterie.
- Afficher un compte à rebours anxiogène.
- Masquer une action derrière un geste non découvrable, sans doublon visible.
- Laisser un bouton actif qui échouera : à la limite des deux appareils, le
  bouton d'ajout est remplacé par une phrase. Un bouton qui échoue après le
  geste coûte plus en confiance qu'un bouton absent.
- Faire porter une restriction par le client seul. Le routeur est une commodité,
  la RLS est la barrière.
