# 02 - Classe et visio

**Version :** V1  
**Date :** 25/09/2026  
**Statut :** PROPOSITION À VALIDER PAR LE DIRECTEUR

## 0. Portée, autorité et fermeture du périmètre

Ce document ferme la verticale « Classe et visio » pour la rencontre réelle entre un élève et son enseignant. Il couvre l'entrée depuis l'espace de Classe, l'ouverture de la salle, les vérifications préalables, la visio LiveKit, la présence, le support partagé, la continuité après coupure, la sortie, les notices d'observation côté enseignant et côté élève, et le passage vers l'après-séance.

Il ne redéfinit pas les fonctions déjà attribuées à d'autres verticales : observation tuteur détaillée, validation administrative des dossiers, cahier pédagogique complet, bibliothèque complète, lecteur du Coran complet, contrôle administratif et contrôle qualité. Il définit cependant leurs contrats d'entrée et de sortie quand ils croisent la salle.

### Sources d'autorité appliquées

1. Messages du directeur dans la conversation courante.
2. `DOSSIER_POUR_CHATGPT.md`, surtout A §1 bis, A §1 ter, B2, E §11, E §14 et F.
3. `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1`, surtout §§4, 5, 9, 10, 11, 13, 14, 15 et 18.
4. `REWAYAH_FRONTEND_UIUX_BIBLE_V2`, surtout les principes Classe en direct, navigation adaptative, continuité, zoning, accessibilité et états réseau.
5. `REWAYAH_REFERENTIEL_ACADEMIQUE_V1`, surtout l'assiduité, le groupe stable, la charge enseignant et le principe « l'app absorbe la bureaucratie ».

### Décisions fermes appliquées

- À l'écran, le mot est « Classe », jamais « groupe ».
- La salle est unique. Les deux implémentations actuelles `/salle` et `/tc/classe` doivent être consolidées par l'agent d'intégration. Ce document décrit une seule expérience canonique.
- Le parcours prioritaire est : élève et enseignant voient la même séance, entrent dans la même salle, se voient et s'entendent selon permissions, puis la présence est enregistrée sans double comptage.
- La fenêtre d'entrée est pilotée par le serveur, cible par défaut T-20 minutes et configurable. Aucun écran ne recalcule une règle locale divergente.
- Le fait de rejoindre avant T0 prouve la préparation, mais ne crédite pas de présence académique avant T0.
- Le minuteur est dérivé de l'occurrence serveur et ne devient jamais négatif.
- Le support pédagogique domine la composition lorsqu'il est actif. La vidéo redevient dominante quand aucun support n'est présenté.
- La salle continue d'exister pendant la navigation interne. Ouvrir une ressource ou revenir à la Classe ne doit pas volontairement fermer LiveKit.
- Le micro enseignant et le micro élève sont coupés à l'entrée. La caméra est coupée à l'entrée et n'est proposée à l'élève que si la politique du profil l'autorise.
- Aucun micro ne peut être ouvert à distance par un enseignant, un tuteur, un contrôleur ou l'administration.
- La vue enseignant n'obtient aucune coordonnée privée du foyer.
- L'observation d'un tuteur est visible à l'enseignant et à l'enfant concerné, pas aux autres élèves.
- Le quota tuteur retenu par la décision la plus récente est 2 visites par compte parent et par séance, 2 minutes maximum par visite selon la politique effective. Une visite écourtée est consommée. Cette règle n'est jamais codée en dur dans le client.
- L'enregistrement audio est présenté comme réel uniquement quand le serveur confirme l'état réel. Le texte permanent retenu est « Cours enregistré, visite de contrôle possible. » tant que cette décision n'est pas révisée.
- Un écran ne montre jamais un succès, une place, une permission média, un enregistrement ou une présence comme acquis sans garantie serveur.

### CONFLITS explicitement neutralisés

**CONFLIT 1 - quotas d'observation.** Le Teaching Core V1 mentionne encore 1 visite et 120 secondes totales. La décision du directeur du 24/09 au soir fixe 2 visites par parent et par séance, avec une visite écourtée consommée. La décision du directeur prime.

**CONFLIT 2 - vocabulaire « Cours en cours ».** Des textes existants et le Teaching Core utilisent cette formule. Le lexique imposé l'interdit. Cette spec emploie « Séance en direct » et « La séance se poursuit ».

**CONFLIT 3 - trois fenêtres d'entrée.** Le code actuel emploie T0 côté élève, T-10 côté enseignant et T-20 côté serveur. La spec canonique retient la valeur serveur configurable, cible T-20 par défaut.

**CONFLIT 4 - enregistrement.** Des documents historiques déconseillent l'activation automatique. La décision récente du directeur affirme que l'enregistrement audio est réel et que le bandeau doit rester. L'UI doit toutefois consommer un état serveur réel, jamais simuler l'enregistrement.

---

## 1. Fiche des rôles concernés

### 1.1 Élève adulte ou élève en interface standard

**Profil d'usage.** Adolescent, adulte ou élève dont l'interface standard est autorisée. Utilise téléphone, tablette ou ordinateur. Peut être peu à l'aise techniquement. Le français est la langue produit de référence de cette V1.

**Tâches principales, par ordre.**

1. Comprendre quand a lieu la prochaine séance et quand l'accès ouvre.
2. Rejoindre la bonne Classe sans gérer LiveKit, les jetons ni les fuseaux techniques.
3. Voir et entendre l'enseignant, et être vu ou entendu selon sa politique média.
4. Suivre automatiquement le support présenté.
5. Reprendre sans perdre le contexte après une coupure réseau.

**Ne doit jamais voir.** Coordonnées d'autres familles, notes internes enseignant/admin, identifiants techniques, jetons LiveKit, présence d'un contrôleur incognito, visite admin incognito, politiques serveur brutes, secrets de stockage, journaux d'audit.

**Capacités.** Rejoindre si autorisé, activer ou couper son micro, activer ou couper sa caméra uniquement si autorisée, agrandir le support, ouvrir les contrôles de lecture permis, quitter, revenir dans la salle tant que le serveur l'autorise.

### 1.2 Élève utilisant l'Interface guidée

**Profil d'usage.** Enfant, personne âgée ou toute personne bénéficiant d'une interface plus simple. Le besoin d'assistance est déterminé par la politique de profil, pas uniquement par l'âge.

**Tâches principales, par ordre.**

1. Reconnaître immédiatement la prochaine action.
2. Rejoindre la séance avec un minimum de décisions.
3. Voir le support et l'enseignant sans chrome inutile.
4. Comprendre si son parent observe.
5. Quitter ou revenir à l'accueil sans impasse.

**Ne doit jamais voir.** Roster complet, détails techniques, réglages de Classe, informations financières, KYC, notes pédagogiques internes, données des autres élèves.

**Capacités.** Rejoindre, couper ou activer le micro, gérer la caméra si autorisée, agrandir le support, quitter. Un libellé parlé doit être disponible pour les actions principales dès que les fichiers audio existent.

### 1.3 Enseignant

**Profil d'usage.** Adulte enseignant, sur mobile au besoin mais tablette ou ordinateur préférable pour le stylet, le support partagé et le roster. Doit pouvoir enseigner sans gérer la complexité technique du système.

**Tâches principales, par ordre.**

1. Entrer dans la bonne séance à l'heure et vérifier son matériel.
2. Voir qui est présent et identifier l'élève actif sans exposer la famille.
3. Enseigner en audio/vidéo et présenter un support partagé.
4. Appeler un élève, consulter sa fiche pédagogique et gérer la file de récitation.
5. Terminer la séance et passer au cahier prérempli.

**Ne doit jamais voir.** Téléphone, e-mail, adresse, identité complète des tuteurs, paiements, coordonnées du foyer, pièces KYC, géolocalisation précise, identifiants privés d'appareil.

**Capacités.** Rejoindre une séance qui lui est assignée, activer micro/caméra, sélectionner le support, piloter l'état partagé, consulter le roster pédagogique, rappeler discrètement un élève, quitter et transmettre au cahier.

---

## 2. Navigation

**PROPOSITION de navigation cible pour les verticales qui ne sont pas encore figées par une high-fi.** Les entrées de salle et la salle unique sont fermes ; la répartition future des destinations Élève/Enseignant sera validée dans leurs documents respectifs sans créer de seconde route de salle.

La salle n'est pas une destination principale. Elle est un état de travail éphémère ouvert depuis une destination stable et doit rester restaurable.

### 2.1 Élève standard

Destinations de haut niveau retenues pour cette verticale : **Accueil · Classes · Progression · Compte**. Cette spec ne refond pas l'ensemble du rôle élève, mais réserve « Classes » comme destination canonique du travail de Classe. Si la verticale Élève adulte adopte une autre architecture validée, l'entrée vers `CLV-01` doit rester unique.

Chemin canonique : `Accueil` ou `Classes` → carte de la Classe → `CLV-01 Espace Classe` → `Rejoindre la séance` → `CLV-04 Salle élève`.

### 2.2 Interface guidée

Pas de barre basse dense. L'écran d'accueil porte la prochaine séance et le bouton principal. Le retour doit toutefois rester possible. Chemin canonique : `Accueil` → `Rejoindre la séance` → `CLV-05 Salle guidée` → `Quitter` → `CLV-09 Fin de séance` → `Accueil`.

### 2.3 Enseignant

Destinations de haut niveau de la verticale Enseignant : **Journée · Classes · Ressources · Profil**. Le chantier Enseignant finalisera l'ensemble de la navigation. Pour la salle, le chemin unique est : `Journée` ou `Classes` → `CLV-02 Espace Classe enseignant` → `CLV-03 Préparation technique` → `CLV-06 Salle enseignant`.

### 2.4 Navigation pendant une salle active

- La barre principale peut être remplacée par un chrome de séance compact.
- Toute navigation interne qui conserve LiveKit affiche un retour immédiat vers la salle active.
- Le libellé de ce retour est **« Revenir à la séance »**.
- La présence de la salle active n'autorise pas une deuxième route ou un deuxième moteur de visio.
- Sur mobile, le bouton retour du système ne ferme jamais silencieusement la salle. Il ouvre soit le retour à la Classe avec conservation de la salle, soit une confirmation de sortie si l'action quitterait réellement LiveKit.

---

## 3. Carte des fonctions, anti-doublon

| Fonction | Écran unique / surface canonique | Route ou portée | Emplacement exact | Point d'entrée |
|---|---|---|---|---|
| Voir la prochaine séance d'une Classe | `CLV-01` élève, `CLV-02` enseignant | espace de Classe | première grande carte après l'en-tête | carte de Classe depuis Accueil/Classes/Journée |
| Rejoindre | `CLV-01` élève, `CLV-02` enseignant | espace de Classe | CTA plein dans la carte de séance | fenêtre serveur ouverte |
| Préflight enseignant | `CLV-03` | surface focalisée non partageable | étape avant entrée réelle | bouton « Rejoindre la séance » enseignant |
| Vérification silencieuse élève | `CLV-04` / `CLV-05` | état d'entrée de `/salle` | couche d'entrée, affichée seulement si blocage | CTA Rejoindre |
| Visio élève standard | `CLV-04` | `/salle` canonique | zone média secondaire ou primaire selon support | entrée autorisée |
| Visio Interface guidée | `CLV-05` | `/salle` canonique | média et support, chrome réduit | entrée autorisée |
| Visio enseignant | `CLV-06` | `/salle` canonique | support dominant, vidéo secondaire, commandes basses | préflight validé |
| Micro/caméra | `CLV-04`, `CLV-05`, `CLV-06` | salle | dock inférieur | salle active |
| Roster enseignant | `CLV-07` | panneau de `/salle` | panneau latéral desktop, sheet mobile | bouton « Élèves » de `CLV-06` |
| Fiche pédagogique d'un élève | `CLV-07` | même panneau | détail de l'élève sélectionné | ligne du roster |
| Choisir un support pour la séance | `CLV-08` | panneau de `/salle` | panneau latéral desktop, sheet mobile | bouton « Supports » de `CLV-06` |
| Afficher le support partagé | `CLV-04`, `CLV-05`, `CLV-06` | salle | zone de contenu primaire | choix enseignant + `SharedContentState` |
| Reconnexion | états des `CLV-04`, `CLV-05`, `CLV-06` | salle active | bandeau non modal | perte du transport |
| Réseau faible | états des salles | salle active | indicateur texte + icône | mesure réseau |
| Notice observation parent | `CLV-05` enfant et `CLV-06` enseignant | salle active | indicateur discret non bloquant | présence observateur autorisée |
| Sortie élève | `CLV-04`, `CLV-05` | salle | commande « Quitter » | action utilisateur ou fin serveur |
| Fin de séance élève | `CLV-09` | résultat local puis retour Classe | écran bref de sortie | salle terminée |
| Sortie enseignant | `CLV-06` | salle | commande « Terminer pour moi » | action enseignant |
| Passage au cahier | `CLV-10` | transition vers `ENS-04` | CTA plein | salle terminée ou sortie enseignant |
| Barre de reprise d'une salle active | composant transversal de session | application | barre compacte hors salle | navigation interne pendant LiveKit |

### Raccourcis admis

- Accueil élève et destination Classes peuvent tous deux ouvrir **le même `CLV-01`**.
- Journée enseignant et destination Classes peuvent tous deux ouvrir **le même `CLV-02`**.
- La barre « Revenir à la séance » ouvre **la même instance de salle**, jamais une nouvelle connexion parallèle.

---

## 4. Parcours de bout en bout

### P01 - Élève standard, entrée normale

1. L'élève ouvre Accueil ou Classes.
2. Il touche la carte de sa Classe.
3. `CLV-01` affiche la prochaine séance, son heure locale, l'heure de l'enseignant si différente, la durée et le décompte.
4. Avant `join_opens_at`, aucun bouton plein d'entrée n'est actif. Le texte indique l'heure d'ouverture réelle.
5. À partir de `join_opens_at`, le CTA devient « Rejoindre la séance ».
6. L'élève touche le CTA.
7. Le client demande au serveur une autorisation de séance et un jeton court.
8. Si le serveur refuse, l'écran explique la cause sans promettre l'accès.
9. Si le média est utilisable, `CLV-04` s'ouvre avec micro coupé et caméra coupée.
10. Avant T0, la salle affiche un état d'attente. Ce temps ne compte pas comme présence académique.
11. À T0, l'état devient « Séance en direct ».
12. Si l'enseignant présente un support, le support devient la zone principale.
13. À la fin serveur, l'élève voit `CLV-09`, puis revient à sa Classe.

### P02 - Élève Interface guidée

1. L'enfant voit sur son accueil une seule action pleine relative à la séance.
2. Le bouton devient actif selon la fenêtre serveur.
3. Il touche « Rejoindre la séance ».
4. Les vérifications réseau et média se font silencieusement.
5. Si une permission indispensable manque, une seule question claire apparaît avec une action principale.
6. `CLV-05` s'ouvre sans roster complet et sans configuration secondaire.
7. Le support suit automatiquement l'enseignant.
8. Si son tuteur observe, l'enfant voit « Ton parent regarde la séance. » avec un indicateur discret.
9. En quittant, il voit un écran bref de fin puis revient à l'accueil.
10. Aucune impasse n'est permise : retour et déconnexion restent accessibles conformément à la règle globale, même si la navigation principale est minimale.

### P03 - Enseignant, entrée normale

1. L'enseignant ouvre Journée ou sa Classe.
2. `CLV-02` affiche la séance assignée et la liste pédagogique nécessaire.
3. À l'ouverture serveur, le CTA devient « Préparer la séance ».
4. Il touche ce CTA.
5. `CLV-03` teste réseau, micro et disponibilité média sans publier de flux.
6. Si le micro est indisponible, l'enseignant peut corriger puis retester. Il ne peut pas entrer dans un état trompeur « tout est prêt ».
7. Il touche « Entrer dans la séance ».
8. Le serveur délivre le jeton pour cette séance et ses permissions.
9. `CLV-06` s'ouvre. Micro et caméra restent coupés jusqu'à action volontaire.
10. Il peut afficher le roster, sélectionner un élève, ouvrir un support et piloter l'état partagé.
11. Il termine la séance ou quitte sa participation.
12. `CLV-10` l'oriente vers le cahier prérempli `ENS-04` sans perdre l'identifiant de séance.

### P04 - Élève rejoint avant l'enseignant

1. Le serveur autorise l'entrée dans la fenêtre.
2. La salle affiche « La salle est ouverte. Votre enseignant n'est pas encore arrivé. ».
3. Le décompte affiche « La séance commence dans {durée}. » avant T0.
4. Aucun état d'absence enseignant n'est produit à partir du client.
5. À l'arrivée de l'enseignant, l'interface bascule sans rechargement complet.

### P05 - Reconnexion après perte réseau

1. LiveKit signale une perte de connexion.
2. La salle conserve le support et affiche « Connexion interrompue. Reconnexion en cours… ».
3. Les commandes qui exigent le serveur sont temporairement indisponibles.
4. Le client réutilise le contexte de séance autorisé ou redemande un jeton si nécessaire.
5. Le transport d'état rejoue la dernière révision durable de `SharedContentState`.
6. Le retour réseau affiche « Connexion rétablie. » brièvement, sans toast permanent.
7. La présence est reconstruite par intervalles réels. La reconnexion ne crée pas une nouvelle absence.
8. En cas d'échec durable, l'écran propose « Réessayer » et « Quitter la séance ».

### P06 - Réseau faible

1. Le système détecte une qualité insuffisante.
2. L'audio est prioritaire.
3. La vidéo peut être réduite ou suspendue selon les capacités LiveKit, sans changer la présence.
4. Le texte visible est « Réseau faible. L'audio est prioritaire. ».
5. Aucun faux état « hors ligne » n'est affiché tant que la room reste connectée.

### P07 - Support partagé

1. L'enseignant ouvre `CLV-08`.
2. Il choisit une ressource autorisée pour la Classe.
3. Le serveur ou le contrat partagé confirme la ressource et sa version.
4. `SharedContentState` publie la position et la révision.
5. Les élèves reçoivent l'état et affichent le support sans partage vidéo d'écran.
6. Un changement d'élève actif ne change pas la position du support.
7. Une reconnexion restaure la dernière position durable.
8. Les annotations restent une couche séparée du contenu source.

### P08 - Observation tuteur pendant une séance

1. Le serveur valide l'observateur et émet son accès selon la politique effective.
2. `CLV-06` enseignant reçoit l'état observateur et affiche « Tuteur de {prénom} observe. ».
3. `CLV-05` de l'enfant concerné affiche « Ton parent regarde la séance. ».
4. Les autres élèves ne reçoivent pas cette information.
5. Aucun micro ou caméra de l'observateur n'est publiable.
6. La fin de la visite retire l'indicateur sans notification de sortie intrusive.

### P09 - Permission micro refusée

1. L'utilisateur tente d'activer son micro.
2. Le système constate que la permission OS est refusée.
3. L'interface affiche « Le micro est bloqué dans les réglages de cet appareil. ».
4. Action principale : « Ouvrir les réglages » si la plateforme le permet.
5. Action secondaire : « Continuer sans micro ».
6. L'enseignant ne reçoit jamais un état prétendant que le micro fonctionne.

### P10 - Caméra élève interdite par politique

1. La salle reçoit `can_publish_video = false`.
2. Aucun bouton caméra actif n'est montré.
3. À sa place, un statut non interactif indique « Caméra désactivée pour ce profil. » dans les détails média, pas dans le contenu principal.
4. Une tentative technique externe de publication est refusée côté serveur.

### P11 - Séance prolongée

1. L'heure de fin prévue est dépassée alors que la séance serveur reste ouverte.
2. Le minuteur ne descend jamais sous zéro.
3. Le libellé devient « La séance se poursuit. ».
4. L'accès/reconnexion reste piloté par le serveur.
5. La présence finale est calculée après clôture ou consolidation serveur.

### P12 - Salle terminée ou accès révoqué

1. Le serveur clôt la séance ou révoque l'accès.
2. Les contrôles média sont arrêtés.
3. L'élève voit `CLV-09` avec « La séance est terminée. ».
4. L'enseignant voit `CLV-10` avec l'action vers le cahier.
5. Une reconnexion à la room close n'est pas tentée en boucle.

---
## 5. Fiches écran

### CLV-01 - Espace Classe, élève

**Identifiant :** `CLV-01`  
**Nom visible :** nom humain de la Classe  
**Route :** route actuelle `/tc/groupes/:groupeId`, nom interne conservé tant que le routeur n'est pas migré  
**Écran parent :** Accueil élève ou liste des Classes  
**Destination active :** Classes, ou Accueil si la verticale Élève retient l'entrée directe comme destination principale.

**Entrées.** Carte de Classe depuis Accueil ou Classes. Retour depuis la salle si l'élève quitte sans fermer son accès.  
**Sorties.** `Rejoindre la séance` vers `CLV-04` ou `CLV-05` selon le profil ; `Voir les ressources` vers la verticale Bibliothèque ; retour vers Accueil/Classes.

**Objectif unique.** Donner à l'élève tout ce qu'il doit savoir pour rejoindre la prochaine séance de cette Classe sans chercher ailleurs.  
**Action principale.** `Rejoindre la séance`, uniquement quand le serveur l'autorise.  
**Actions secondaires.** `Voir les ressources`, `Voir le travail` si un travail existe, retour.

#### Disposition mobile 390 x 844

1. AppBar compacte, retour à gauche, titre DM Sans `titleLarge`, menu d'accessibilité uniquement si déjà présent dans le shell.
2. Bloc identité de Classe, marge latérale `lg = 16`, espacement vertical `xxl = 24`. Photo publique de l'enseignant, `Sayyid` ou `Sayyida`, nom autorisé, cours et niveau humain. Aucun code interne.
3. `AppCard` dominante unique, rayon `lg = 24`, contenant la prochaine séance. Une seule surface, lignes séparées par des filets en retrait : date, heure locale, heure enseignant si différente, durée, décompte, état d'accès.
4. CTA plein hauteur `52`, largeur disponible. Avant ouverture, remplacer le CTA par un libellé d'état non interactif et le prochain instant utile.
5. Texte discret : `Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.`
6. Carte groupée `Avant la prochaine séance`, au maximum trois actions, uniquement si des tâches existent.
7. Aperçu Bibliothèque, trois couvertures maximum, puis `Voir les ressources`.
8. Bas de page respirant `respiration = 64`, puis navigation principale.

#### Tablette 768

Rail persistant 80. Contenu max `largeurLecture = 800`. Deux colonnes seulement si les tâches existent : colonne principale 60 % avec séance, colonne secondaire 40 % avec travail et ressources. Le CTA reste dans la carte de séance et ne migre pas dans une barre d'action séparée.

#### Desktop 1440

Sidebar 256, contenu centré jusqu'à `largeurMaxContenu = 1200`. Colonne principale environ 720 pour la séance et le travail, colonne secondaire environ 360 pour enseignant et ressources. La page ne devient pas une grille de petites cartes.

#### Textes exacts

- Titre de section : `Prochaine séance`
- Libellé heure utilisateur : `Votre heure`
- Libellé heure enseignant : `Chez {Sayyid/Sayyida} {prénom}`
- Libellé durée : `Durée`
- Avant ouverture : `La salle ouvrira à {heure locale}.`
- Fenêtre ouverte avant T0 : `La salle est ouverte. La séance commence dans {durée}.`
- À T0 : `Séance en direct`
- Prolongation : `La séance se poursuit.`
- CTA : `Rejoindre la séance`
- Ressources : `Ressources de la Classe`
- Travail : `Avant la prochaine séance`
- Appareil : `Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.`
- Accessibilité photo : `Photo de {Sayyid/Sayyida} {nom}`
- Accessibilité CTA : `Rejoindre la séance de {nom de la Classe}`

#### États

**Chargement.** Squelette de la carte principale. Texte lecteur d'écran : `Chargement de la prochaine séance.` Aucun faux horaire.

**Contenu.** Données serveur présentes, heure et décompte calculés depuis l'occurrence.

**Aucune séance planifiée.** Titre `Aucune séance planifiée`. Corps `Cette Classe n'a pas de prochaine séance confirmée.` Action secondaire `Actualiser`.

**Séance annulée.** `Cette séance est annulée.` Puis, si connue, `Prochaine séance : {date et heure}.` Aucun bouton rejoindre.

**Erreur du bloc séance.** `Impossible d'afficher la prochaine séance.` Action `Réessayer`.

**Erreur de page.** `Impossible d'ouvrir cette Classe.` Action `Réessayer`. Retour toujours disponible.

**Hors ligne.** Si une occurrence mise en cache existe : `Vous êtes hors ligne. Les horaires affichés peuvent avoir changé.` Le bouton Rejoindre est absent car le réseau est requis. Action `Réessayer`.

**Capacité serveur indisponible.** `L'accès à la salle ne peut pas être vérifié pour le moment.` Action `Réessayer`. Aucun bouton de contournement.

**Permission refusée.** `Vous n'avez pas accès à cette Classe.` Action `Retour à mes Classes`.

**Fenêtre fermée.** `La salle ouvrira à {heure locale}.`

**Fenêtre ouverte.** CTA actif.

**Séance terminée.** `Cette séance est terminée.` Le bloc présente la prochaine occurrence confirmée.

#### Données

- Classe : `GroupHomeVM` ou contrat existant équivalent, à mapper avant création.
- Enseignant public : identifiant d'affichage, titre Sayyid/Sayyida, photo publique, aucun KYC.
- Occurrence : `session_id`, `starts_at_utc`, `ends_at_utc`, `join_opens_at_utc`, `reference_timezone`.
- Conversion utilisateur : zone IANA du profil, jamais offset hardcodé.
- Durée : minutes serveur formatées `1 h`, `1 h 30`.
- État : annulée, ouverte, en attente, active, prolongée, terminée.
- Travail et ressources : seulement identifiants et aperçus autorisés.

**CONTRAT À CRÉER si aucun équivalent complet n'existe :** `get_student_class_home(student_id, class_id) -> GroupHomeVM + SessionClockVM + up to 3 assignments + library_preview`; erreurs `not_member`, `class_closed`, `session_unavailable`, `forbidden`.

#### Règles serveur et confidentialité

Le serveur décide l'adhésion, la prochaine occurrence, la fenêtre d'entrée et l'état de séance. Le client ne montre jamais un autre foyer, les notes internes, les données privées enseignant ou un jeton média.

#### Accessibilité

Ordre : retour, titre, enseignant, séance, CTA, conseil appareil, travail, ressources. Cibles 48 dp minimum. À 200 %, la carte passe en pile verticale. Contraste AA. Aucun état porté uniquement par couleur. Les horaires sont lus avec le fuseau. Mouvement réduit respecte le réglage global.

#### Critères d'acceptation

- Étant donné un élève membre, quand il touche sa Classe depuis la navigation, alors `CLV-01` s'ouvre et affiche la prochaine occurrence serveur.
- Étant donné une fenêtre non ouverte, quand la page s'affiche, alors aucun CTA actif de salle n'est présent.
- Étant donné `join_opens_at` atteint, quand l'écran se rafraîchit, alors `Rejoindre la séance` devient disponible sans changer de route.
- Étant donné un écran 1440, quand la page est capturée, alors elle utilise une composition desktop et non une colonne mobile étirée.

**Référentiel UX appliqué.** Material Design 3 pour hiérarchie et navigation adaptative, WCAG 2.2 AA pour cibles et zoom texte, Nielsen « visibilité de l'état du système », loi de Fitts pour le CTA principal proche de la zone d'action.

**Référence visuelle.** `IMG-CLV-01_mobile_clair`, `IMG-CLV-01_desktop_clair`.

---

### CLV-02 - Espace Classe, enseignant

**Identifiant :** `CLV-02`  
**Nom visible :** nom humain de la Classe  
**Route actuelle :** `/enseignant/groupe/:groupeId`, le mot interne peut rester dans la route  
**Écran parent :** Journée ou Classes enseignant  
**Destination active :** Classes ou Journée selon le point d'entrée, sans dupliquer l'écran.

**Entrées.** Carte de la journée, carte de Classe.  
**Sorties.** `Préparer la séance` vers `CLV-03`, `Voir les élèves` vers la vue pédagogique hors live du rôle Enseignant, `Ressources` vers la bibliothèque enseignant lorsqu'elle sera câblée, retour.

**Objectif unique.** Préparer la prochaine séance de cette Classe en un coup d'œil.  
**Action principale.** `Préparer la séance` lorsque la fenêtre serveur est ouverte.  
**Actions secondaires.** `Voir les élèves`, `Ressources`, `Voir le travail prévu`.

#### Disposition mobile 390 x 844

1. AppBar avec retour et titre.
2. Identité de la Classe, cours, cycle/niveau, repère couleur administré, capacité réelle.
3. Carte dominante de séance : heure enseignant, heure de référence de Classe si différente, durée, décompte, notice DST si active.
4. CTA plein `Préparer la séance`.
5. Carte groupée `Élèves`, lignes compactes prénom + identifiant académie + état de présence récent utile, sans contact familial.
6. `Préparation pédagogique`, au maximum trois items : support de reprise, travail en cours, alerte pédagogique autorisée.
7. Conseil appareil identique, discret.

#### Tablette 768

Rail 80. Colonne principale séance + préparation ; colonne secondaire roster compact. Stylet et clavier ne modifient pas le layout de base.

#### Desktop 1440

Sidebar 256. Trois zones possibles : Classe 220, séance/préparation 600-720, contexte 300-360. Les informations privées familiales ne sont jamais demandées au backend pour remplir la colonne contexte.

#### Textes exacts

- `Prochaine séance`
- `Votre heure`
- `Heure de la Classe`
- `Durée`
- `La salle ouvrira à {heure}.`
- `La salle est ouverte. La séance commence dans {durée}.`
- CTA `Préparer la séance`
- `Élèves`
- `Préparation pédagogique`
- `Ressources`
- DST : `L'heure locale de cette Classe change le {date}. Vérifiez les prochaines séances.`
- Appareil : `Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.`

#### États

Chargement : `Chargement de la Classe.`  
Vide élèves : `Aucun élève inscrit dans cette Classe.`  
Séance absente : `Aucune prochaine séance confirmée.`  
Séance annulée : `Cette séance est annulée.`  
Erreur bloc : `Impossible de charger la prochaine séance.` + `Réessayer`.  
Erreur page : `Impossible d'ouvrir cette Classe.` + `Réessayer`.  
Hors ligne : `Vous êtes hors ligne. La préparation reste consultable, mais la salle nécessite une connexion.`  
Serveur indisponible : `L'autorisation de séance ne peut pas être vérifiée pour le moment.`  
Permission refusée : `Cette Classe ne vous est pas attribuée.` + `Retour à ma journée`.  
Fenêtre fermée : aucun CTA actif.  
Fenêtre ouverte : CTA `Préparer la séance`.  
Séance active déjà rejointe : CTA `Revenir à la séance`.

#### Données

`GroupHomeVM`, `SessionClockVM`, projection des élèves limitée, support de reprise, assignments actifs. Fuseaux IANA. Aucun numéro de téléphone, e-mail, tuteur ou paiement.

**CONTRAT À CRÉER si nécessaire :** `get_teacher_class_home(teacher_id, class_id)` avec contrôle d'affectation permanent ou remplacement temporaire valide.

#### Règles

Le serveur décide l'affectation, le remplacement et l'accès. Un enseignant en voyage voit sa conversion locale mais ne déplace pas l'heure institutionnelle. Les données pédagogiques restent celles autorisées par `TeacherStudentProjection`.

#### Accessibilité

Ordre de lecture logique, 48 dp, 200 % sans écrêtement, clavier desktop, focus visible, contraste AA, notice DST non portée par couleur.

#### Critères d'acceptation

- Étant donné un enseignant assigné, quand il touche la Classe depuis Journée, alors `CLV-02` s'ouvre.
- Étant donné un enseignant non assigné, quand il tente l'URL, alors aucune donnée de roster n'est livrée.
- Étant donné une transition DST future, quand une occurrence est affectée, alors une notice textuelle est visible avant l'échéance selon la politique serveur.
- Étant donné une salle déjà active, quand l'enseignant revient à la Classe, alors le CTA est `Revenir à la séance` et ne crée pas une seconde room.

**Référentiel UX appliqué.** MD3, WCAG 2.2 AA, Nielsen « reconnaissance plutôt que rappel », loi de proximité.

**Référence visuelle.** `IMG-CLV-02_mobile_clair`, `IMG-CLV-02_desktop_clair`.

---

### CLV-03 - Préparation technique enseignant

**Identifiant :** `CLV-03`  
**Nom visible :** `Préparer la séance`  
**Route :** surface focalisée attachée à l'entrée de salle, non partageable, sans deep link public  
**Écran parent :** `CLV-02`  
**Destination active :** aucune destination secondaire ; contexte Classe conservé.

**Entrées.** Bouton `Préparer la séance`.  
**Sorties.** `Entrer dans la séance` vers `CLV-06`, `Retour à la Classe` vers `CLV-02`.

**Objectif unique.** Vérifier que l'enseignant peut entrer avec un audio utilisable sans lui imposer de réglages superflus.  
**Action principale.** `Entrer dans la séance` quand les contrôles indispensables sont validés.  
**Actions secondaires.** `Tester le micro`, `Choisir un micro` si plusieurs appareils, `Retour à la Classe`.

#### Disposition mobile

Colonne max `largeurFormulaire = 640`. Retour en haut. Titre. Une carte groupée unique `Vérifications` avec lignes Réseau, Micro, Caméra. La caméra n'est pas bloquante sauf politique spécifique. Le micro est indispensable à l'enseignement en direct. Zone d'action basse avec CTA plein 52. Aucun aperçu vidéo géant.

#### Tablette et desktop

Contenu centré, max 640. Sur desktop, panneau latéral facultatif avec rappel séance, sans reproduire toute la Classe. Pas de modal miniature pour une tâche qui peut nécessiter permissions système.

#### Textes exacts

- Titre `Préparer la séance`
- Intro `Vérifiez le son avant d'entrer.`
- `Réseau`
- `Connexion prête`
- `Connexion instable`
- `Micro`
- `Micro prêt`
- `Aucun micro détecté`
- `Tester le micro`
- `Caméra`
- `Caméra prête`
- `Caméra non disponible`
- CTA `Entrer dans la séance`
- Secondaire `Retour à la Classe`
- Permission OS : `Le micro est bloqué dans les réglages de cet appareil.`
- Action permission : `Ouvrir les réglages`

#### États

**Chargement.** `Vérification du matériel…` avec progression indéterminée.

**Prêt.** Réseau utilisable, micro détecté. CTA actif. Cela ne signifie pas que le serveur autorisera la room ; l'autorisation finale est demandée à l'entrée.

**Réseau faible.** `Connexion instable. L'audio sera prioritaire.` CTA actif si LiveKit estime l'entrée possible.

**Micro absent.** `Aucun micro détecté. Connectez ou activez un micro pour enseigner.` CTA désactivé. Action `Réessayer`.

**Permission refusée.** `Le micro est bloqué dans les réglages de cet appareil.` Action principale `Ouvrir les réglages`, secondaire `Retour à la Classe`.

**Caméra absente.** `Caméra non disponible. Vous pouvez entrer sans caméra.` Le micro reste le critère principal.

**Erreur serveur d'autorisation.** Après CTA : `L'accès à cette séance ne peut pas être autorisé pour le moment.` Action `Réessayer`.

**Séance non assignée.** `Cette séance ne vous est pas attribuée.` Action `Retour à ma journée`.

**Séance terminée.** `Cette séance est terminée.` Action `Retour à la Classe`.

#### Données

Liste des devices média locale, permissions OS, qualité réseau locale, contexte `session_id`. Jeton LiveKit non demandé avant l'action d'entrée, sauf si l'architecture existante impose un pré-token court et non publiable.

#### Règles

Aucun secret LiveKit côté Flutter. Le test micro ne publie pas vers la salle. Aucun micro ouvert automatiquement. Aucune caméra ouverte automatiquement.

#### Accessibilité

Chaque état possède icône + texte. 48 dp. Focus clavier séquentiel. Les indicateurs audio ne dépendent pas d'une animation rapide. Mouvement réduit supprimant les oscillations décoratives.

#### Critères d'acceptation

- Étant donné la fenêtre ouverte, quand l'enseignant touche `Préparer la séance`, alors `CLV-03` s'ouvre.
- Étant donné la permission micro refusée, quand la vérification se termine, alors le CTA d'entrée n'annonce pas un micro prêt.
- Étant donné un réseau faible mais utilisable, quand l'écran s'affiche, alors le texte annonce la priorité audio et permet l'entrée si le serveur l'autorise.
- Étant donné un micro prêt, quand l'enseignant touche `Entrer dans la séance`, alors l'autorisation serveur est demandée pour cette séance précise.

**Référentiel UX appliqué.** GOV.UK pour message d'erreur actionnable, Nielsen « prévention des erreurs », MD3 pour formulaire focalisé, WCAG 2.2 AA.

**Référence visuelle.** `IMG-CLV-03_mobile_clair`, `IMG-CLV-03_desktop_clair`.

---
### CLV-04 - Salle en direct, élève standard

**Identifiant :** `CLV-04`  
**Nom visible :** `Séance en direct`  
**Route canonique :** `/salle` après consolidation des deux salles  
**Écran parent :** `CLV-01`  
**Destination active :** aucune destination de navigation ordinaire, la séance est un contexte temporaire.

**Entrées.** `Rejoindre la séance` depuis `CLV-01`, `Revenir à la séance` depuis la barre de session active.  
**Sorties.** `Quitter` vers `CLV-09`, navigation interne autorisée vers support/Classe avec session conservée.

**Objectif unique.** Permettre à l'élève de suivre la séance et d'interagir avec son média sans être distrait par les outils enseignant.  
**Action principale.** Aucune action pleine persistante pendant une séance active. La tâche principale est le contenu pédagogique.  
**Actions secondaires.** Micro, caméra si autorisée, agrandir le support, quitter.

#### Disposition mobile 390 x 844

1. Bandeau supérieur compact, pleine largeur, hauteur minimale nécessaire : `Séance en direct`, état réseau en texte si pertinent, indicateur d'enregistrement réel si confirmé.
2. Si aucun support n'est actif : vidéo enseignant dominante, vidéo élève en vignette ou masquée selon politique.
3. Si un support est actif : support plein écran ou quasi plein écran. La vidéo enseignant devient vignette repositionnable dans des zones qui ne couvrent jamais le texte coranique ni les commandes de page.
4. Indicateur d'observation parent uniquement pour l'élève concerné, sous forme de pilule discrète avec texte, jamais couleur seule.
5. Dock inférieur compact : `Micro`, `Caméra` si autorisée, `Agrandir` si support, `Quitter`. Toutes les cibles 48 dp.
6. Aucun roster complet. Aucun accès aux fiches d'autres élèves.
7. Les changements de support sont animés au maximum selon le jeton de mouvement court, désactivables avec mouvement réduit.

#### Tablette 768

Support au centre, vignette enseignant latérale ou en coin non couvrant. Panneau de contexte uniquement si l'élève ouvre une option autorisée. Aucun panneau permanent de roster.

#### Desktop 1440

Sidebar globale masquée pendant la salle. Composition 2 panneaux : support principal environ 70-75 %, média secondaire environ 25-30 %. En absence de support, média central plus large. Barre de commandes basse. Largeur de contenu pédagogique non étirée au-delà de sa géométrie naturelle.

#### Textes exacts

- `Séance en direct`
- Avant T0 : `La salle est ouverte. La séance commence dans {durée}.`
- Enseignant absent avant T0 : `Votre enseignant n'est pas encore arrivé.`
- Après T0 sans enseignant : `Votre enseignant n'est pas encore dans la salle.`
- Enregistrement confirmé : `Cours enregistré, visite de contrôle possible.`
- Réseau faible : `Réseau faible. L'audio est prioritaire.`
- Reconnexion : `Connexion interrompue. Reconnexion en cours…`
- Reconnexion réussie : `Connexion rétablie.`
- Prolongation : `La séance se poursuit.`
- Observation : `Votre parent observe la séance.`
- Micro : `Micro`
- Caméra : `Caméra`
- Support : `Agrandir le support`
- Quitter : `Quitter`
- Confirmation de sortie volontaire : titre `Quitter la séance ?`, corps `Vous pourrez revenir si la séance est encore ouverte.`, actions `Rester` et `Quitter la séance`.
- Permission micro refusée : `Le micro est bloqué dans les réglages de cet appareil.`
- Caméra interdite par politique : `Caméra désactivée pour ce profil.`
- Accessibilité micro coupé : `Micro coupé. Activer le micro.`
- Accessibilité micro actif : `Micro actif. Couper le micro.`
- Accessibilité caméra coupée : `Caméra coupée. Activer la caméra.`
- Accessibilité caméra active : `Caméra active. Couper la caméra.`

#### États

**Chargement d'entrée.** Fond neutre, texte `Ouverture de la salle…`. Pas de vidéo fictive.

**Autorisation en cours.** `Vérification de votre accès…`.

**Avant T0.** Salle connectée, média autorisé, présence académique non commencée. Texte `La salle est ouverte. La séance commence dans {durée}.`.

**Séance active, aucun support.** Vidéo enseignant dominante. Si vidéo absente mais audio présent : avatar enseignant + `Caméra de l'enseignant coupée.`.

**Séance active, support partagé.** Support dominant. Position reçue depuis `SharedContentState`.

**Support en chargement.** Zone primaire indique `Chargement du support…`. La visio continue.

**Support indisponible.** `Le support ne peut pas être affiché.` Action `Réessayer`. L'audio/vidéo continue.

**Réseau faible.** Bandeau non modal `Réseau faible. L'audio est prioritaire.` La vidéo peut être réduite.

**Reconnexion en cours.** L'état de support reste visible si mis en cache. Commandes de publication désactivées jusqu'à reprise.

**Reconnexion réussie.** Message bref `Connexion rétablie.` puis disparition sans exiger d'action.

**Reconnexion impossible.** Page de salle conservée, texte `Impossible de rétablir la connexion.` Actions `Réessayer` et `Quitter la séance`.

**Hors ligne confirmé.** `Vous êtes hors ligne. La séance nécessite une connexion.` Action `Réessayer`.

**Permission micro refusée.** Micro reste coupé, texte actionnable dans la feuille média.

**Caméra non autorisée serveur.** Bouton caméra absent ou désactivé avec explication dans le panneau média. Jamais un bouton qui échoue après coup sans raison visible.

**Observation parent active.** Pilule `Votre parent observe la séance.` uniquement pour l'élève concerné.

**Enregistrement non confirmé.** Ne pas afficher le bandeau d'enregistrement comme actif. Si la politique exige une information mais le statut est inconnu : `L'état de l'enregistrement ne peut pas être vérifié.` et action de sécurité selon contrat serveur. Aucun faux succès.

**Séance prolongée.** Remplacer le décompte par `La séance se poursuit.`.

**Accès révoqué.** `Votre accès à cette séance a pris fin.` puis `CLV-09`.

**Séance terminée.** Transition vers `CLV-09`.

#### Données

- Autorisation et jeton : contrat serveur de session, expiration courte.
- Media permissions : claims du token et politique profil.
- Room state : LiveKit.
- Présence : événements signés, pas l'horloge UI.
- Support : `SharedContentState` et ressource versionnée.
- Observation : événement de présence observateur minimal, uniquement si l'élève est concerné.
- Enregistrement : état serveur explicite `recording_active`, pas un booléen client présumé.

**CONTRAT À CRÉER si nécessaire :** `request_session_join(session_id, participant_profile_id, role=student)` retourne `room_url`, `token`, `expires_at`, `permissions`, `session_clock`, `recording_state`, `shared_state_revision`; erreurs `too_early`, `session_closed`, `not_enrolled`, `account_blocked`, `media_policy_denied`, `temporarily_unavailable`.

#### Règles

Le client ne peut pas publier un média non autorisé. Aucun lien public de salle. Le billet d'entrée n'est pas sérialisé dans l'URL. Le support partagé ne modifie pas la source canonique. Navigation interne ne ferme pas volontairement la room.

#### Accessibilité

Support en premier dans l'ordre de lecture lorsqu'il est actif. Commandes média annoncées avec état. 48 dp. Contraste AA. Sous-titres non prévus par la source, donc non inventés. Zoom système à 200 % : le dock passe sur deux lignes ou dans une feuille, sans masquer le support. Clavier desktop : Tab vers commandes, Échap ne quitte jamais sans confirmation.

#### Critères d'acceptation

- Étant donné une fenêtre ouverte, quand l'élève touche `Rejoindre la séance`, alors la salle demande un jeton serveur et n'utilise pas une room statique.
- Étant donné un support actif, quand l'enseignant change de position, alors l'élève reçoit la nouvelle révision sans partage d'écran vidéo.
- Étant donné une coupure courte, quand la connexion revient, alors la salle restaure le support et la présence n'est pas doublée.
- Étant donné une caméra interdite, quand la salle s'ouvre, alors aucun contrôle ne permet de publier la caméra.
- Étant donné une observation parent, quand le parent entre, alors seul l'enfant concerné voit l'indicateur.

**Référentiel UX appliqué.** Bible V2 priorité contenu pédagogique, MD3 pour les commandes, Apple HIG pour permissions média contextualisées, WCAG 2.2 AA, Nielsen visibilité d'état sans surcharge.

**Référence visuelle.** `IMG-CLV-04_mobile_clair`, `IMG-CLV-04_mobile_sombre`, `IMG-CLV-04_desktop_clair`.

---

### CLV-05 - Salle en direct, Interface guidée

**Identifiant :** `CLV-05`  
**Nom visible :** `Ma séance`  
**Route :** même `/salle`, rendu guidé selon politique de profil  
**Écran parent :** accueil guidé  
**Destination active :** aucune.

**Entrées.** `Rejoindre la séance` depuis l'accueil guidé.  
**Sorties.** `Quitter` vers `CLV-09`, retour accueil.

**Objectif unique.** Laisser l'élève suivre le cours avec le moins de choix possible.  
**Action principale.** Le support ou l'enseignant, pas un bouton.  
**Actions secondaires.** `Parler`, `Caméra` si autorisée, `Agrandir`, `Quitter`.

#### Disposition mobile

1. Titre court `Ma séance` en DM Sans, sans sous-navigation.
2. Support plein écran prioritaire lorsqu'il existe.
3. Vignette enseignant grande et lisible, jamais sur le texte sacré.
4. Indicateur parent avec pictogramme + texte.
5. Dock de 3 ou 4 contrôles maximum, cibles 72 dp : `Parler`, `Caméra`, `Agrandir`, `Quitter`.
6. Chaque contrôle porte un pictogramme et un libellé. Libellé audio disponible lorsque l'asset existe, le texte reste toujours affiché.

#### Tablette et desktop

Même hiérarchie, plus d'air, jamais plus de fonctions. Support central, vidéo enseignant latérale. Les cibles restent généreuses, minimum 72 dp pour les actions guidées.

#### Textes exacts

Phrases de 10 mots maximum.

- `Ma séance`
- `La séance commence bientôt.`
- `Ton professeur arrive.`
- `Parler`
- `Couper le micro`
- `Caméra`
- `Couper la caméra`
- `Agrandir`
- `Quitter`
- Observation : `Ton parent regarde la séance.`
- Réseau : `Le réseau est faible.`
- Reconnexion : `Je reconnecte la séance…`
- Échec : `La connexion ne revient pas.`
- Action : `Réessayer`
- Fin : `La séance est terminée.`
- Permission : `Le micro est bloqué sur cet appareil.`
- Action permission : `Ouvrir les réglages`

#### États

**Chargement.** `J'ouvre ta séance…` est interdit car l'application ne doit pas parler à la première personne. Retenu : `Ouverture de la séance…`.

**Attente avant T0.** `La séance commence bientôt.` Le décompte peut être affiché en grand `18 min` sans phrase longue.

**Enseignant absent.** `Ton professeur arrive.` uniquement avant T0. Après T0 : `Ton professeur n'est pas encore là.`.

**Support actif.** Support dominant, suivi automatique.

**Réseau faible.** `Le réseau est faible.` + sous-texte `Le son reste prioritaire.`

**Reconnexion.** `Je reconnecte la séance…` est abandonné pour éviter la première personne. Texte final : `Reconnexion de la séance…`.

**Échec reconnexion.** `La connexion ne revient pas.` Actions `Réessayer`, `Quitter`.

**Micro refusé.** `Le micro est bloqué sur cet appareil.`

**Caméra interdite.** Aucun bouton caméra. Aucune explication longue sur l'écran principal.

**Parent observe.** `Ton parent regarde la séance.` avec icône œil/personne, jamais animation anxiogène.

**Enregistrement réel.** La notice générale reste présente sous forme compacte, avec formulation adulte canonique si imposée contractuellement. Pour l'Interface guidée, PROPOSITION de formulation visible : `Le cours est enregistré.` et accessibilité détaillée `Cours enregistré, visite de contrôle possible.`. Ne remplacer le texte contractuel signé que sur décision.

**Fin.** `La séance est terminée.` puis action `Retour à l'accueil`.

#### Données

Mêmes contrats que `CLV-04`, mais la projection UI exclut roster, métadonnées avancées, outils et texte technique.

#### Règles

L'Interface guidée n'élargit jamais les permissions. Le serveur reste identique. Les libellés audio ne sont pas considérés livrés tant que les fichiers ne sont pas présents. Aucune navigation invisible qui enferme l'enfant : retour et déconnexion doivent exister via un accès contrôlé conforme à la verticale Élève enfant.

#### Accessibilité

Cibles 72 dp, texte + pictogramme, lecture audio disponible, contraste AA, mouvement réduit, ordre très court : support, professeur, statut, contrôles, quitter. À 200 %, une action par ligne si nécessaire.

#### Critères d'acceptation

- Étant donné un profil en Interface guidée, quand il rejoint, alors aucun roster ni fonction pédagogique enseignant n'est présent.
- Étant donné un parent observateur, quand l'indicateur apparaît, alors le texte est compréhensible en moins de 10 mots.
- Étant donné une caméra non autorisée, quand la salle s'affiche, alors le bouton caméra n'est pas proposé.
- Étant donné un écran étroit, quand le texte est agrandi à 200 %, alors les contrôles restent atteignables sans couvrir le support.

**Référentiel UX appliqué.** Bible V2 Interface guidée, WCAG 2.2 AA, Fitts pour cibles 72 dp, Hick pour nombre de choix réduit.

**Référence visuelle.** `IMG-CLV-05_mobile_clair`, `IMG-CLV-05_mobile_sombre`, `IMG-CLV-05_desktop_clair`.

---

### CLV-06 - Salle en direct, enseignant

**Identifiant :** `CLV-06`  
**Nom visible :** `Séance en direct`  
**Route :** `/salle`  
**Écran parent :** `CLV-03`  
**Destination active :** aucune.

**Entrées.** `Entrer dans la séance` depuis le préflight, `Revenir à la séance` depuis la barre persistante.  
**Sorties.** `Terminer pour moi` vers `CLV-10`, navigation interne vers ressources ou Classe en conservant la room.

**Objectif unique.** Donner à l'enseignant le contrôle pédagogique nécessaire sans transformer la salle en console technique.  
**Action principale.** Aucune action pleine persistante. Le support et l'enseignement dominent.  
**Actions secondaires.** Micro, caméra, Élèves, Supports, outils pédagogiques contextuels, quitter.

#### Disposition mobile

1. Header : nom de Classe, état `Séance en direct`, durée restante ou `La séance se poursuit.`.
2. Support dominant si actif. Sinon vidéo de la Classe dominante.
3. Vignette vidéo de l'enseignant si caméra active.
4. Bouton compact `Élèves {présents}/{effectif}` ouvrant `CLV-07`.
5. Bouton compact `Supports` ouvrant `CLV-08`.
6. Teaching Dock compact uniquement pour les outils effectivement câblés : pointer, marquer, masquer/révéler, annotation. Aucun outil fictif.
7. Dock média : micro, caméra, réseau, quitter.
8. Notice observateur tuteur : pilule discrète sous le header, `Tuteur de {prénom} observe.` avec temps restant seulement si la politique fournit cette donnée à l'enseignant.

#### Tablette 768

Support environ 70 %, contexte 30 %. Roster repliable. Teaching Dock flottant le long du support sans le couvrir. Excellent support stylet.

#### Desktop 1440

Structure recommandée : panneau roster 240-280 quand ouvert, support central flexible, contexte/média 280-320. Si roster fermé, le support gagne l'espace. Aucune sidebar globale en plus. Les vidéos ne réduisent pas le Coran sous une largeur lisible.

#### Textes exacts

- `Séance en direct`
- `Élèves {présents}/{effectif}`
- `Supports`
- `Micro`
- `Caméra`
- `Réseau`
- `Quitter`
- `Tuteur de {prénom} observe.`
- `Réseau faible. L'audio est prioritaire.`
- `Connexion interrompue. Reconnexion en cours…`
- `Connexion rétablie.`
- `La séance se poursuit.`
- `Cours enregistré, visite de contrôle possible.`
- Sortie : titre `Quitter la séance ?`
- Sortie corps `Vous passerez ensuite au cahier de transmission.`
- Actions `Rester` et `Quitter et ouvrir le cahier`

#### États

**Entrée / chargement.** `Ouverture de la séance…`.

**Avant T0.** Roster peut montrer les personnes connectées, mais présence académique n'est pas encore créditée.

**Actif sans support.** Média dominant. `Supports` disponible.

**Actif avec support.** Support dominant, dock pédagogique visible.

**Aucun élève connecté.** `Aucun élève n'est encore connecté.` La séance reste ouverte.

**Roster partiel.** Les élèves non connectés apparaissent avec état `Pas encore connecté`, pas `Absent` avant consolidation serveur.

**Réseau faible.** `Réseau faible. L'audio est prioritaire.`

**Reconnexion.** Conserver le support à la dernière révision, désactiver les actions temps réel non rejouables.

**Support indisponible.** `Le support ne peut pas être affiché.` `Réessayer`. Visio continue.

**Publication data interdite.** Si le token ne permet pas l'état partagé : `Le partage du support n'est pas disponible pour cette séance.` L'enseignant peut continuer audio/vidéo. Aucun bouton factice.

**Observation tuteur.** `Tuteur de {prénom} observe.` Aucun nom complet du tuteur si non nécessaire. Aucun bouton de refus en salle si la politique serveur autorise déjà l'observation.

**Contrôleur/admin incognito.** Aucun indicateur participant. L'audit est serveur. La salle enseignant ne doit pas révéler leur présence.

**Enregistrement actif.** Notice permanente canonique. Si état inconnu, ne pas affirmer l'enregistrement.

**Séance prolongée.** `La séance se poursuit.`.

**Fin serveur.** Commandes média fermées, transition `CLV-10`.

#### Données

LiveKit room, `TeacherStudentProjection`, `SharedContentState`, `SessionClockVM`, présence temps réel non consolidée, politique média, observation minimale, recording state.

#### Règles

Aucune donnée privée du foyer n'est livrée. L'enseignant peut enseigner oralement sans système de commandes vocales. La sélection d'un élève ne change pas la page/support. Le client ne déclare pas un élève absent avant consolidation.

#### Accessibilité

Focus clavier visible sur tous les contrôles. Raccourcis clavier ne sont ajoutés que s'ils sont documentés dans la verticale Enseignant. Teaching Dock accessible au clavier et au stylet. Les statuts ont texte + icône. 48 dp. 200 % : roster passe en panneau plein ou sheet, pas de colonnes écrasées.

#### Critères d'acceptation

- Étant donné un enseignant autorisé, quand il entre, alors micro et caméra sont coupés.
- Étant donné un support partagé, quand il ouvre `Élèves`, alors la position du support ne change pas.
- Étant donné un tuteur observateur, quand il entre, alors l'enseignant voit l'indicateur mais les autres élèves non concernés ne reçoivent pas de notice.
- Étant donné un contrôleur incognito, quand il observe, alors il n'apparaît pas dans le roster enseignant.
- Étant donné une fin de séance, quand l'enseignant quitte, alors la transition conserve `session_id` pour le cahier.

**Référentiel UX appliqué.** Bible V2 contenu pédagogique > contrôles, MD3 adaptive, WCAG 2.2 AA, Nielsen réduction de charge cognitive.

**Référence visuelle.** `IMG-CLV-06_mobile_clair`, `IMG-CLV-06_desktop_clair`, `IMG-CLV-06_desktop_sombre`.

---
### CLV-07 - Élèves de la séance et fiche pédagogique

**Identifiant :** `CLV-07`  
**Nom visible :** `Élèves`  
**Route :** panneau local de `/salle`, pas de route autonome partageable  
**Écran parent :** `CLV-06`  
**Destination active :** salle.

**Entrées.** Bouton `Élèves {présents}/{effectif}`.  
**Sorties.** Fermer vers `CLV-06`, sélectionner un élève pour afficher sa fiche dans le même panneau.

**Objectif unique.** Donner à l'enseignant le contexte pédagogique strictement nécessaire pour l'élève qu'il accompagne.  
**Action principale.** Aucune action pleine. La sélection de l'élève est l'interaction principale.  
**Actions secondaires.** `Rappeler`, `Choisir pour réciter`, `Noter`, `Signaler un besoin` si ces capacités sont réellement câblées.

#### Disposition mobile

Bottom sheet `arrondiFeuille = 24`, hauteur adaptative. En-tête `Élèves`, compteur, bouton fermer. Liste unique, sans carte par élève : une carte groupée contient les lignes, séparées par filets. Chaque ligne : prénom, identifiant académie, statut de connexion textuel. Tap ouvre la fiche dans la même sheet. La fiche utilise une seule carte groupée avec sections Niveau, Objectif actuel, Dernière séance, À reprendre, Présence récente, Travail actuel. Barre d'actions contextuelles en bas.

#### Tablette

Panneau latéral 320-360. Liste en haut, fiche en dessous ou panneau maître-détail si la largeur le permet.

#### Desktop

Panneau persistant 280-320 à gauche. Liste courte. Sélection met à jour le panneau contexte sans naviguer hors salle.

#### Textes exacts

- Titre `Élèves`
- États live : `Connecté`, `Pas encore connecté`, `Connexion interrompue`
- Fiche : `Niveau`, `Objectif actuel`, `Dernière séance`, `À reprendre`, `Présence récente`, `Travail actuel`
- Actions : `Rappeler`, `Choisir pour réciter`, `Noter`, `Signaler un besoin`
- Rappel envoyé : aucun toast si transport accepté.
- Échec rappel : `Le rappel n'a pas pu être envoyé.` + `Réessayer`
- Vide : `Aucun élève inscrit dans cette Classe.`
- Erreur : `Impossible de charger les élèves.` + `Réessayer`

#### États

Chargement : skeleton des lignes.  
Contenu : liste serveur.  
Vide : message exact ci-dessus.  
Erreur bloc : message + réessayer, la salle continue.  
Hors ligne : si liste en cache, `Données hors ligne. Les états de connexion peuvent être obsolètes.`  
Permission refusée : panneau fermé, `Vous n'avez pas accès à ces informations.` dans une surface résultat.  
Élève sélectionné : fiche pédagogique.  
Donnée absente : afficher `Non renseigné` seulement pour un champ réellement facultatif, ne jamais inventer.  
Rappel cooldown : `Vous venez d'envoyer un rappel à {prénom}.` sans compte à rebours anxiogène.

#### Données

`TeacherStudentProjection` uniquement : prénom, identifiant académie, niveau, parcours, unité actuelle, objectifs actifs, dernière séance, points de reprise, présence récente, travail, notes pédagogiques autorisées, état live. Le backend ne livre jamais téléphone, e-mail, adresse, identité tuteur, paiements, géolocalisation ou identifiants appareil.

**CONTRAT À CRÉER si nécessaire :** `get_session_teacher_roster(session_id, teacher_id)` avec projection minimale et contrôle d'assignation.

#### Règles

Le statut `Pas encore connecté` n'est pas `Absent`. Une absence académique est une conclusion serveur après la fenêtre pertinente. Un rappel ne déclenche jamais le micro de l'élève. Un changement d'élève ne change ni support, ni focus, ni annotation.

#### Accessibilité

Chaque ligne minimum 48 dp. Statuts lus textuellement. Fiche en ordre sémantique. À 200 %, la fiche devient une colonne. Focus retourne au bouton `Élèves` à la fermeture.

#### Critères d'acceptation

- Étant donné une salle enseignant, quand il touche `Élèves`, alors le panneau s'ouvre sans quitter LiveKit.
- Étant donné un élève sélectionné, quand la fiche s'affiche, alors aucune coordonnée familiale n'est présente dans les données ou l'UI.
- Étant donné un rappel accepté par le transport, quand l'enseignant touche `Rappeler`, alors aucun toast de succès superflu n'apparaît.
- Étant donné un rappel échoué, alors un message explicite et `Réessayer` sont visibles.

**Référentiel UX appliqué.** Progressive disclosure, Nielsen, WCAG 2.2 AA, principe anti-concurrence Rewayah.

**Référence visuelle.** `IMG-CLV-07_mobile_clair`, `IMG-CLV-07_desktop_clair`.

---

### CLV-08 - Choisir un support pour la séance

**Identifiant :** `CLV-08`  
**Nom visible :** `Supports`  
**Route :** panneau local de `/salle`, la bibliothèque complète reste la verticale `10_BIBLIOTHEQUE_ET_RESSOURCES.md`  
**Écran parent :** `CLV-06`  
**Destination active :** salle.

**Entrées.** Bouton `Supports`.  
**Sorties.** Sélection d'une ressource autorisée vers `CLV-06` avec support actif, `Voir toute la bibliothèque` vers la bibliothèque tout en conservant la salle, fermer.

**Objectif unique.** Choisir rapidement le support à présenter pendant la séance.  
**Action principale.** La sélection d'un support.  
**Actions secondaires.** `Voir toute la bibliothèque`, fermer.

#### Disposition mobile

Bottom sheet avec titre `Supports`. Section `Reprendre` si une position de Classe existe, puis `Récents`, puis `Ressources de la Classe`. Vraies couvertures ou icônes de type contrôlées, pas de vignettes générées trompeuses. Une ressource = une ligne/tuile avec titre, type, version si utile, disponibilité hors ligne. Maximum de contenu visible avant `Voir toute la bibliothèque` pour garder le choix court.

#### Tablette

Panneau latéral 360-400, grille 2 colonnes si les titres tiennent à 150 % de texte, sinon liste.

#### Desktop

Panneau latéral 400, recherche uniquement si le volume justifie et si la verticale Bibliothèque la fournit. La salle reste visible derrière, aucune coupure.

#### Textes exacts

- `Supports`
- `Reprendre`
- `Récents`
- `Ressources de la Classe`
- `Voir toute la bibliothèque`
- Chargement `Chargement des supports…`
- Vide `Aucun support n'est disponible pour cette Classe.`
- Erreur `Impossible de charger les supports.`
- Hors ligne `Vous êtes hors ligne. Seuls les supports déjà disponibles sur cet appareil sont accessibles.`
- Version indisponible `Cette version du support n'est plus disponible.`

#### États

Chargement, contenu, vide, erreur, hors ligne, permission refusée, ressource supprimée/non publiée, version expirée, téléchargement requis, support déjà actif. Aucune ressource privée d'une autre Classe.

#### Données

`LibraryResource`, `ResourceVersion`, autorisation de Classe, couverture, type, version publiée, source/licence côté admin mais pas nécessairement visible ici. `SharedContentState` reçoit `resource_id`, `resource_version_id`, position initiale.

#### Règles

La source publiée est immuable. Un PDF téléchargé n'est pas la source interactive du Coran. La sélection n'interrompt pas LiveKit. Une ressource non autorisée n'est pas livrée au client.

#### Accessibilité

48 dp, titres non tronqués à 200 %, couvertures avec libellé sémantique, focus retourne à `Supports` après fermeture.

#### Critères d'acceptation

- Étant donné une salle active, quand l'enseignant touche `Supports`, alors la room reste connectée.
- Étant donné une ressource autorisée, quand elle est choisie, alors la version exacte est publiée dans l'état partagé.
- Étant donné une ressource non autorisée, alors elle n'est pas livrée ni visible.
- Étant donné hors ligne, alors aucune ressource non mise en cache n'est annoncée disponible.

**Référentiel UX appliqué.** MD3 bottom sheet, Hick pour choix court, Nielsen reconnaissance visuelle, WCAG 2.2 AA.

**Référence visuelle.** `IMG-CLV-08_mobile_clair`, `IMG-CLV-08_desktop_clair`.

---

### CLV-09 - Fin de séance, élève

**Identifiant :** `CLV-09`  
**Nom visible :** `Séance terminée`  
**Route :** état de sortie non partageable, puis retour Classe/Accueil  
**Écran parent :** `CLV-04` ou `CLV-05`  
**Destination active :** Classes ou Accueil.

**Entrées.** Fin serveur ou sortie volontaire confirmée.  
**Sorties.** `Retour à la Classe` pour standard, `Retour à l'accueil` pour guidée.

**Objectif unique.** Confirmer la fin de la connexion sans demander de travail supplémentaire à l'élève.  
**Action principale.** `Retour à la Classe` ou `Retour à l'accueil` selon l'interface.  
**Action secondaire.** Aucune obligatoire. Un micro-feedback éventuel appartient au rôle Élève et ne s'affiche pas systématiquement.

#### Disposition

État résultat centré, largeur `largeurEtatVide = 400`. Titre, phrase, action pleine. En Interface guidée, cibles 72 dp et texte très court. Aucun feu d'artifice, aucune animation longue. Si une animation d'encouragement est retenue, durée inférieure à une seconde et supprimée avec mouvement réduit.

#### Textes exacts

Standard :
- `Séance terminée`
- `Vous pouvez retrouver votre travail dans votre Classe.`
- `Retour à la Classe`

Guidée :
- `La séance est terminée.`
- `Retour à l'accueil`

Sortie avant fin :
- `Vous avez quitté la séance.`
- `Vous pourrez revenir tant qu'elle reste ouverte.`
- `Retour à la Classe`

#### États

Fin serveur, sortie volontaire, accès révoqué, erreur de clôture locale. Si la clôture réseau échoue mais LiveKit est déjà coupé, ne pas retenir l'utilisateur. Journal technique réessayé en arrière-plan uniquement si idempotent.

#### Données

État final serveur si disponible, identifiant de Classe, travail mis à jour. Aucun statut de présence final inventé avant consolidation.

#### Règles

Ne jamais afficher `Présent` ou `Absent` comme résultat final si la consolidation n'est pas confirmée. Aucun formulaire obligatoire.

#### Accessibilité

Focus initial sur le titre, puis corps, puis CTA. 48/72 dp. Contraste AA. Mouvement réduit.

#### Critères d'acceptation

- Étant donné une fin de séance, quand LiveKit ferme, alors l'élève voit un état de fin et une sortie claire.
- Étant donné une présence non consolidée, alors aucune conclusion de présence n'est affichée.
- Étant donné l'Interface guidée, alors le texte visible reste sous 10 mots par phrase.

**Référentiel UX appliqué.** Nielsen état de fin clair, WCAG, GOV.UK langage simple.

**Référence visuelle.** `IMG-CLV-09_mobile_clair`, `IMG-CLV-09_desktop_clair`.

---

### CLV-10 - Fin de séance, enseignant

**Identifiant :** `CLV-10`  
**Nom visible :** `Séance terminée`  
**Route :** transition vers `/enseignant/seance/:seanceId/cahier`  
**Écran parent :** `CLV-06`  
**Destination active :** Journée.

**Entrées.** Fin serveur, action `Quitter et ouvrir le cahier`.  
**Sorties.** `Ouvrir le cahier` vers `ENS-04`.

**Objectif unique.** Faire passer l'enseignant immédiatement de la séance au cahier prérempli.  
**Action principale.** `Ouvrir le cahier`.  
**Action secondaire.** `Revenir à ma journée` uniquement si la politique autorise de différer, avec rappel visible dans Journée.

#### Disposition

État résultat centré sur mobile. Sur desktop, panneau simple dans la coquille enseignant avec récapitulatif minimal : Classe, heure réelle de fin, nombre d'élèves connectés comme donnée technique non définitive, statut `Cahier à compléter`. Aucun formulaire ici.

#### Textes exacts

- `Séance terminée`
- `Le cahier est prêt avec les informations de la séance.`
- `Ouvrir le cahier`
- Secondaire si autorisé : `Revenir à ma journée`
- Si cahier indisponible : `Le cahier ne peut pas être ouvert pour le moment.`
- Action : `Réessayer`

#### États

Cahier prêt, préparation du cahier, erreur de préparation, hors ligne avec file idempotente si réellement supportée, permission refusée, séance sans identifiant valide. Aucun faux « cahier enregistré ».

#### Données

`session_id`, `class_id`, occurrence, événements de présence, support final, position de reprise candidate. Le cahier complet est défini dans `04_ENSEIGNANT.md`.

#### Règles

Cette transition ne duplique pas le cahier. Elle ouvre l'unique `ENS-04`. Les données préremplies viennent des événements réels ; l'enseignant corrige les exceptions.

#### Accessibilité

Ordre court, CTA 52, 200 % sans coupure, focus sur le titre puis CTA.

#### Critères d'acceptation

- Étant donné une séance terminée, quand l'enseignant quitte, alors `session_id` est conservé jusqu'au cahier.
- Étant donné un cahier indisponible, alors l'écran ne prétend pas l'avoir créé et permet de réessayer.
- Étant donné le retour à Journée, alors un cahier en attente reste visible si le serveur le signale.

**Référentiel UX appliqué.** Nielsen continuité de tâche, MD3 résultat + CTA unique, WCAG 2.2 AA.

**Référence visuelle.** `IMG-CLV-10_mobile_clair`, `IMG-CLV-10_desktop_clair`.

---
## 6. Copywriting de la verticale

### 6.1 Registres

- Élève adulte / standard : vouvoiement, encourageant, respectueux, orienté action.
- Interface guidée : tutoiement bienveillant, phrases de 10 mots maximum, pictogramme + libellé.
- Enseignant : vouvoiement, professionnel, précis, vocabulaire pédagogique autorisé.

### 6.2 Lexique imposé

Utiliser : `Classe`, `Séance`, `Séance en direct`, `Sayyid`, `Sayyida`, `Interface guidée`, `Rejoindre la séance`, `Revenir à la séance`, `Support`, `Élèves`, `Cahier de transmission`.

Interdire à l'écran : `groupe`, `session`, `Cours en cours`, `mode enfant`, `matching`, `room`, `token`, `LiveKit`, `RPC`, codes internes, identifiants DB.

### 6.3 Dix corrections avant / après

| Avant interdit ou insuffisant | Après retenu |
|---|---|
| `Cours en cours · 47 min` | `Séance en direct · 47 min restantes` |
| `Mes groupes` | `Mes Classes` |
| `Voir le groupe` | `Voir la Classe` |
| `Lancer le cours` | `Préparer la séance` puis `Entrer dans la séance` |
| `Votre session a expiré` | `Votre accès à cette séance a pris fin.` |
| `La salle s'ouvre dix minutes avant` | `La salle ouvrira à {heure locale}.` |
| `Erreur vidéo` | `La vidéo ne peut pas démarrer. Vous pouvez continuer avec le son.` |
| `Micro permission denied` | `Le micro est bloqué dans les réglages de cet appareil.` |
| `Participant absent` avant consolidation | `Pas encore connecté` |
| `Parent online` | `Tuteur de {prénom} observe.` côté enseignant, `Ton parent regarde la séance.` côté enfant |

### 6.4 Modèles de messages

**Erreur récupérable.** `{Ce qui ne fonctionne pas}. {Conséquence courte}.` Action : `Réessayer`.

**Permission média.** `Le micro est bloqué dans les réglages de cet appareil.` Action : `Ouvrir les réglages`.

**Attente.** `La salle est ouverte. La séance commence dans {durée}.`

**Réseau faible.** `Réseau faible. L'audio est prioritaire.`

**Reconnexion.** `Connexion interrompue. Reconnexion en cours…`

**Indisponibilité serveur.** `L'accès à la salle ne peut pas être vérifié pour le moment.`

**Fin.** `La séance est terminée.`

**Succès évident.** Aucun toast si l'action est immédiatement visible, notamment activation micro, sélection support, ouverture roster, retour en salle.

---

## 7. Maquettes

### 7.1 Maquettes existantes réutilisées

Aucune maquette cible existante ne couvre la salle élève ou enseignant. Les maquettes d'observation tuteur existantes servent uniquement à vérifier la cohérence de l'indicateur d'observation et ne doivent pas dicter le layout de la salle principale.

### 7.2 Nouvelles maquettes obligatoires

Toutes les images suivantes doivent employer exclusivement les jetons gelés, DM Sans pour titres et Plus Jakarta Sans pour le reste. Les couleurs sont sémantiques. Aucune barre d'état de téléphone, aucun décor de planche dans l'écran.

#### IMG-CLV-01_mobile_clair

Écran `CLV-01`, 390 x 844, clair. AppBar retour + nom Classe. Identité enseignant. Grande carte séance en un seul rectangle avec filets. État fenêtre ouverte, CTA `Rejoindre la séance`. Conseil tablette. Bloc `Avant la prochaine séance` et trois couvertures Bibliothèque. Navigation basse cohérente avec Élève. **IMAGE À PRODUIRE.**

#### IMG-CLV-01_desktop_clair

Écran `CLV-01`, 1440 x 900, clair. Sidebar desktop. Deux colonnes, séance dominante à gauche, enseignant et ressources à droite. Même textes que mobile. **IMAGE À PRODUIRE.**

#### IMG-CLV-02_mobile_clair

Écran `CLV-02`, 390 x 844, clair. Carte Classe, carte séance, CTA `Préparer la séance`, roster compact, préparation pédagogique. Aucun ancien flux « prendre un élève ». **IMAGE À PRODUIRE.**

#### IMG-CLV-02_desktop_clair

Écran `CLV-02`, 1440 x 900. Sidebar Enseignant. Séance au centre, roster/context à droite. Notice DST visible comme texte secondaire. **IMAGE À PRODUIRE.**

#### IMG-CLV-03_mobile_clair

Écran `CLV-03`, 390 x 844. Titre `Préparer la séance`. Carte groupée Réseau, Micro, Caméra. Micro prêt, caméra facultative. CTA `Entrer dans la séance`. **IMAGE À PRODUIRE.**

#### IMG-CLV-03_desktop_clair

Écran `CLV-03`, 1440 x 900. Colonne centrée max 640, résumé séance secondaire. **IMAGE À PRODUIRE.**

#### IMG-CLV-04_mobile_clair

Écran `CLV-04`, 390 x 844. Support actif dominant, vidéo enseignant en vignette, bandeau `Séance en direct`, dock Micro/Caméra/Agrandir/Quitter. Aucun roster. **IMAGE À PRODUIRE.**

#### IMG-CLV-04_mobile_sombre

Même état en sombre réel, mêmes rôles sémantiques, pas de valeurs claires codées en dur. **IMAGE À PRODUIRE.**

#### IMG-CLV-04_desktop_clair

Écran `CLV-04`, 1440 x 900. Support 72 %, média secondaire 28 %, commandes basses. **IMAGE À PRODUIRE.**

#### IMG-CLV-04_reconnexion_mobile_clair

État de `CLV-04`, 390 x 844. Support maintenu en arrière-plan, bandeau `Connexion interrompue. Reconnexion en cours…`, contrôles de publication indisponibles. **IMAGE À PRODUIRE.**

#### IMG-CLV-05_mobile_clair

Écran `CLV-05`, 390 x 844. Interface guidée, grand support, grande vignette professeur, cibles 72 dp, maximum quatre actions. **IMAGE À PRODUIRE.**

#### IMG-CLV-05_mobile_observation_clair

Même écran avec l'indicateur `Ton parent regarde la séance.`. Aucun nom de parent, aucune donnée des autres élèves. **IMAGE À PRODUIRE.**

#### IMG-CLV-05_mobile_sombre

Même composition en sombre. **IMAGE À PRODUIRE.**

#### IMG-CLV-05_desktop_clair

Écran guidé 1440 x 900, plus d'air sans ajouter de fonctions. **IMAGE À PRODUIRE.**

#### IMG-CLV-06_mobile_clair

Écran `CLV-06`, 390 x 844. Support actif, bouton `Élèves 4/4`, `Supports`, Teaching Dock compact, média et quitter. **IMAGE À PRODUIRE.**

#### IMG-CLV-06_mobile_observation_clair

Même écran avec pilule `Tuteur de {prénom} observe.`. **IMAGE À PRODUIRE.**

#### IMG-CLV-06_desktop_clair

Écran `CLV-06`, 1440 x 900. Roster replié, support central dominant, média secondaire, dock flottant. **IMAGE À PRODUIRE.**

#### IMG-CLV-06_desktop_sombre

Même écran en sombre réel. **IMAGE À PRODUIRE.**

#### IMG-CLV-07_mobile_clair

`CLV-07`, 390 x 844. Bottom sheet Élèves, liste groupée puis fiche d'un élève avec données pédagogiques uniquement. **IMAGE À PRODUIRE.**

#### IMG-CLV-07_desktop_clair

`CLV-07`, 1440 x 900. Panneau latéral roster + fiche, salle visible au centre. **IMAGE À PRODUIRE.**

#### IMG-CLV-08_mobile_clair

`CLV-08`, 390 x 844. Bottom sheet Supports, Reprendre, Récents, Ressources de la Classe, couvertures reconnaissables, `Voir toute la bibliothèque`. **IMAGE À PRODUIRE.**

#### IMG-CLV-08_desktop_clair

`CLV-08`, 1440 x 900. Panneau de supports à côté de la salle, room visuellement conservée. **IMAGE À PRODUIRE.**

#### IMG-CLV-09_mobile_clair

`CLV-09`, 390 x 844. État résultat centré `Séance terminée`, texte standard et CTA `Retour à la Classe`. **IMAGE À PRODUIRE.**

#### IMG-CLV-09_guidee_mobile_clair

`CLV-09`, 390 x 844, Interface guidée. `La séance est terminée.` et grand CTA `Retour à l'accueil`. **IMAGE À PRODUIRE.**

#### IMG-CLV-10_mobile_clair

`CLV-10`, 390 x 844. `Séance terminée`, `Le cahier est prêt avec les informations de la séance.`, CTA `Ouvrir le cahier`. **IMAGE À PRODUIRE.**

#### IMG-CLV-10_desktop_clair

`CLV-10`, 1440 x 900. Résultat dans coquille Enseignant, récapitulatif minimal et CTA cahier. **IMAGE À PRODUIRE.**

### 7.3 Règle d'éthique visuelle

Les images ci-dessus sont des maquettes de travail autorisées par la demande récente du directeur. Toute illustration publique, capture store, icône ou visuel marketing devra être validé séparément contre les anciennes règles d'éthique visuelle avant publication.

---

## 8. Dépendances serveur

Les noms ci-dessous sont des contrats cibles. L'intégrateur doit mapper d'abord l'existant et ne jamais créer une table, RPC ou service concurrent si un équivalent existe.

| Contrat | Entrée | Sortie | Erreurs minimales | Accès | Écrans |
|---|---|---|---|---|---|
| `get_student_class_home` | `student_profile_id`, `class_id` | `GroupHomeVM`, `SessionClockVM`, tâches, aperçu ressources | `forbidden`, `not_member`, `class_closed`, `temporarily_unavailable` | élève membre | CLV-01 |
| `get_teacher_class_home` | `teacher_id`, `class_id` | `GroupHomeVM`, clock, projection élèves, reprise | `forbidden`, `not_assigned`, `class_closed` | enseignant assigné/remplaçant valide | CLV-02 |
| `request_session_join` | `session_id`, identité participant, rôle effectif | URL, token court, permissions, clock, recording state, revision état partagé | `too_early`, `closed`, `not_member`, `not_assigned`, `blocked`, `policy_denied`, `unavailable` | participant autorisé | CLV-04, 05, 06 |
| `refresh_session_join` | `session_id`, preuve session courante | nouveau token court ou refus | `closed`, `revoked`, `unavailable` | participant déjà autorisé | reconnexion |
| `get_session_shared_state` | `session_id`, dernière révision connue | `SharedContentState` | `forbidden`, `not_found` | participant salle | CLV-04, 05, 06 |
| `publish_session_shared_state` | `session_id`, revision attendue, nouvel état | revision confirmée | `conflict`, `forbidden`, `invalid_resource` | enseignant avec droit data | CLV-06, 08 |
| `get_session_teacher_roster` | `session_id`, `teacher_id` | `TeacherStudentProjection[]` | `forbidden`, `not_assigned` | enseignant | CLV-07 |
| `send_student_nudge` | `session_id`, `student_id`, `teacher_id` | acceptation transport | `cooldown`, `forbidden`, `offline`, `unavailable` | enseignant de la séance | CLV-07 |
| `get_session_recording_state` | `session_id` | `active/inactive/unavailable`, policy version | `forbidden`, `unavailable` | participants autorisés | salles |
| `get_session_observer_notice` | `session_id`, participant | notice minimale si concerné | `forbidden` | enseignant ou enfant concerné | CLV-05, CLV-06 |
| `attendance_event_ingest` | événements LiveKit signés | ack idempotent | signature, duplicate, out_of_order | serveur uniquement | aucune UI directe |
| `get_attendance_live_projection` | `session_id` | états de connexion non consolidés | `forbidden` | enseignant | CLV-06, 07 |
| `finalize_attendance` | session close + intervalles | résultat académique | `conflict`, `incomplete_evidence` | backend/admin correction auditée | après séance |
| `prepare_teacher_notebook` | `session_id` | identifiant cahier, données préremplies | `unavailable`, `forbidden`, `not_finalized` | enseignant assigné | CLV-10 |

### 8.1 Contraintes de sûreté

- Token LiveKit émis côté serveur, durée courte, permissions minimales.
- Webhooks signés, idempotents et tolérants aux événements hors ordre.
- Aucune autorisation persistante en cache comme source de vérité.
- RLS empêche une famille de lire une autre famille.
- La projection enseignant exclut les coordonnées privées par construction serveur.
- L'état partagé durable porte une révision pour la reconnexion.
- Les mouvements éphémères de pointeur/stylet ne deviennent pas des écritures durables à chaque pixel.
- Les occurrences sont matérialisées en UTC, récurrence en fuseau IANA.
- Le minuteur UI se base sur le serveur et l'occurrence, pas uniquement sur l'horloge du téléphone.
- L'entrée avant T0 et la présence académique sont deux concepts distincts.

---

## 9. Recette de la verticale

### 9.1 Rencontre réelle minimale

1. Créer ou utiliser une Classe réelle avec enseignant attitré et élève inscrit.
2. Vérifier que l'élève et l'enseignant voient la même occurrence et le même horaire après conversion.
3. Avant `join_opens_at`, vérifier l'absence de CTA actif.
4. À `join_opens_at`, toucher le CTA depuis la navigation, sans appel direct au routeur dans le test.
5. Vérifier le jeton serveur et l'entrée dans une seule room.
6. Vérifier micro et caméra coupés à l'entrée.
7. Activer volontairement le micro enseignant puis le micro élève.
8. Vérifier audio bidirectionnel.
9. Activer caméra selon politique et vérifier vidéo.
10. Vérifier qu'un élève non autorisé à la caméra ne peut pas la publier.

### 9.2 Présence

1. Élève rejoint à T-18.
2. Vérifier que la connexion avant T0 est tracée mais ne crédite pas 18 minutes de présence académique.
3. Couper le réseau 20 secondes puis reconnecter.
4. Vérifier qu'aucune absence supplémentaire n'est créée.
5. Envoyer deux fois le même webhook et vérifier l'idempotence.
6. Vérifier qu'avant consolidation l'enseignant voit `Pas encore connecté`, pas `Absent`.
7. Corriger ensuite une présence côté administration dans sa verticale, avec audit.

### 9.3 Support partagé

1. Enseignant ouvre Supports en restant dans LiveKit.
2. Sélectionne une ressource autorisée.
3. Élève standard et Interface guidée reçoivent la même version et la même position.
4. Déplacer la position du support.
5. Couper le réseau de l'élève.
6. Reconnecter et vérifier la reprise à la dernière révision durable.
7. Changer d'élève actif et vérifier que le support ne bouge pas.
8. Vérifier qu'aucune annotation ne modifie la source.

### 9.4 Observation et confidentialité

1. Tuteur autorisé entre pendant la séance.
2. Vérifier l'indicateur côté enseignant.
3. Vérifier l'indicateur uniquement chez l'enfant concerné.
4. Vérifier l'absence d'indicateur chez les autres élèves.
5. Vérifier que le tuteur ne peut publier ni micro, ni caméra, ni data.
6. Vérifier que le contrôleur incognito n'apparaît ni roster ni notices.
7. Vérifier que le roster enseignant ne contient aucune coordonnée familiale dans la réponse réseau, pas seulement dans l'UI.

### 9.5 Résilience

1. Réseau faible : audio prioritaire, message textuel.
2. Reconnexion courte : support conservé.
3. Reconnexion longue : message d'échec + Réessayer + Quitter.
4. Token expiré pendant séance : refresh autorisé ou sortie propre.
5. Session close : aucune boucle de reconnexion.
6. Serveur d'autorisation indisponible : aucun faux accès.
7. Support indisponible : visio continue.

### 9.6 UX multi-format

Pour chacun des écrans `CLV-01` à `CLV-10` :

- capture mobile 390 clair ;
- capture 1440 clair ;
- états sombres explicitement listés pour les salles ;
- texte à 200 % ;
- navigation clavier desktop ;
- lecteur d'écran ;
- RTL sur un échantillon de contenu arabe sans inverser le chrome français ;
- mouvement réduit ;
- aucune cible sous 48 dp, 72 dp en Interface guidée.

### 9.7 Définition de terminé

La verticale n'est terminée que si :

- le fichier d'écran est atteignable depuis la racine réelle ;
- un bouton réel y mène ;
- le parcours est testé en touchant les boutons ;
- le build servi contient les textes attendus ;
- un élève et un enseignant se rencontrent réellement dans la même room ;
- les permissions sont garanties côté serveur ;
- la présence résiste aux doublons et reconnexions ;
- la capture mobile et desktop correspond aux spécifications ;
- aucune seconde salle concurrente n'est encore exposée.

---

## 10. Hors périmètre, pour plus tard

- Détail complet du cahier de transmission : `04_ENSEIGNANT.md`.
- Progression, diagnostic, disponibilité, absence enseignant et remplacement : `04_ENSEIGNANT.md`, `07_ADMINISTRATION.md`.
- Observation tuteur détaillée : verticale Tuteur déjà spécifiée.
- Observation admin et contrôleur, grilles et comptes rendus : `07_ADMINISTRATION.md`, `08_CONTROLEUR_ET_INVITE.md`.
- Catalogue complet, import, versionnement et offline : `10_BIBLIOTHEQUE_ET_RESSOURCES.md`.
- Fidélité Mushaf, navigation Coran, 604 pages, 15 lignes, marques canoniques : `11_LECTEUR_DU_CORAN.md`.
- Notifications push/e-mail : rôle concerné + `13_PUBLICATION.md`.
- Paiement, solde et rémunération : `09_FINANCE_ET_COMPTABLE.md`.
- Aucun moteur de commandes vocales.
- Aucun système de jetons d'agents IA dans cette vague.

---

## 11. Auto-contrôle

### 11.1 Comptage

- Fiches de rôle / usages : **3**.
- Destinations/navigation contextualisées : **3 profils + 1 règle de session active**.
- Fonctions dans la carte anti-doublon : **20**.
- Parcours de bout en bout : **12**.
- Fiches écran/surfaces : **10**, de `CLV-01` à `CLV-10`.
- États métier explicitement décrits dans les fiches : **108**, sans compter les valeurs dynamiques injectées dans ces états.
- Textes visibles exacts listés dans les rubriques `Textes exacts` : **128** entrées.
- Contrats serveur listés : **13**.
- Recettes de parcours : **7 blocs**, couvrant rencontre, présence, support, observation, résilience, multi-format et définition de terminé.
- Nouvelles maquettes identifiées : **26**.
- Maquettes existantes revendiquées comme cible de salle : **0**.

### 11.2 Règles cochées

- [x] Une fonction a un emplacement canonique unique.
- [x] Aucun doublon `/salle` / `/tc/classe` n'est conservé comme produit cible.
- [x] Un titre, une tâche dominante et une seule action pleine quand une action pleine est nécessaire.
- [x] Les cartes groupées sont un seul rectangle avec filets.
- [x] Navigation, retour et sortie explicités.
- [x] Le web possède de vraies compositions 1440.
- [x] Mobile, tablette et desktop sont décrits séparément.
- [x] Tous les écrans ont chargement, erreur, hors ligne ou indisponibilité pertinente, permissions et états métier.
- [x] Aucun faux succès serveur.
- [x] T-20 configurable et présence à T0 distingués.
- [x] Reconnexion sans double présence couverte.
- [x] Réseau faible et audio prioritaire couverts.
- [x] Micro/caméra OFF à l'entrée couverts.
- [x] Caméra élève conditionnée par politique couverte.
- [x] Aucune ouverture distante de micro.
- [x] Support partagé et reprise après coupure couverts.
- [x] Roster enseignant limité pédagogiquement.
- [x] Aucune coordonnée famille côté enseignant.
- [x] Notice tuteur côté enseignant et enfant couverte.
- [x] Contrôleur/admin incognito non révélé aux participants.
- [x] Enregistrement affiché seulement si état serveur réel.
- [x] Vocabulaire `Classe`, `Séance`, `Séance en direct`, `Interface guidée` respecté.
- [x] `Cours en cours`, `groupe`, `mode enfant`, `session` ne sont pas employés comme libellés UI cibles.
- [x] DM Sans titres et Plus Jakarta Sans reste rappelés.
- [x] Jetons spacing, rayons et gabarits gelés utilisés.
- [x] Cibles 48 dp, 72 dp guidée, texte 200 %, contraste AA, mouvement réduit couverts.
- [x] Données, contrats serveur, erreurs et règles d'accès décrits.
- [x] Critères d'acceptation `Étant donné / quand / alors` présents pour chaque fiche.
- [x] Maquettes nouvelles inventoriées sans prétendre que les images actuelles font foi.
- [x] Les conflits documentaires majeurs sont explicitement résolus selon l'ordre d'autorité.
- [x] Aucun contenu hors périmètre n'a été glissé dans les écrans.

### 11.3 Condition de fermeture

Aucun document de « complétion Classe et visio » ne doit être nécessaire après validation de cette V1. Toute évolution future doit être une nouvelle version du présent document avec décision datée, pas un addendum destiné à réparer un oubli.
