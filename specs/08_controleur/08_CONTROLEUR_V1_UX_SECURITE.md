# REWAYAH ACADEMY - 08_CONTROLEUR_V1_UX_SECURITE

**Version :** V1  
**Date :** 27/09/2026  
**Statut :** PROPOSITION À VALIDER PAR LE DIRECTEUR  
**Phase :** FRONTEND / UX / UI / contrats à déclarer, aucun backend à implémenter dans ce lot  
**Périmètre principal :** Contrôleur permanent  
**Périmètre réservé :** fondations communes pour Contrôleur / Évaluateur invité, sans construire son expérience complète ici

---

# 0. RÈGLE D'AUTORITÉ

Ce document distingue quatre niveaux :

- **FAIT** : prouvé par le dossier Rewayah ou par une décision explicite récente du directeur.
- **DÉCISION** : règle produit explicitement donnée par le directeur dans cette conversation.
- **PROPOSITION** : solution UX/UI ou sécurité à valider.
- **BLOQUANT AVANT PRODUCTION** : point non suffisamment documenté pour permettre une ouverture réelle sans validation spécialisée.

Aucun point non documenté ne devient silencieusement une règle métier.

---

# 1. POSITIONNEMENT DU RÔLE

## 1.1 Mission

**DÉCISION :** le Contrôleur vérifie que l'expérience réellement délivrée correspond à ce que Rewayah promet.

Il apporte le jugement humain que l'application ne peut pas déduire correctement :

- qualité de l'explication ;
- attitude professionnelle ;
- qualité de la correction ;
- interaction enseignant-élèves ;
- niveau d'attention et d'engagement observable ;
- gestion du groupe ;
- respect du programme et du cadre pédagogique ;
- climat relationnel ;
- comportement inhabituel ;
- situation nécessitant l'attention de l'administration.

Le système calcule tout ce qui est objectivable :

- heure prévue ;
- heure réelle d'entrée ;
- retard ;
- durée ;
- reconnexions ;
- incidents réseau ;
- participants présents ;
- séance concernée ;
- classe ;
- enseignant ;
- objectif / support si disponible ;
- horodatage de la visite.

Le Contrôleur ne ressaisit jamais ces faits.

## 1.2 Qui peut être Contrôleur permanent

**DÉCISION :**

- un Enseignant ;
- un Admin ;
- une personne externe intégrée durablement comme personnel de contrôle.

**INTERDIT :** le Tuteur n'est pas un Contrôleur dans le modèle actuel.

Le rôle Contrôleur est donc une **capability / un espace professionnel**, pas nécessairement une identité séparée.

Pour une personne déjà Enseignant ou Admin :

- même identité Rewayah ;
- pas de deuxième compte ;
- espace Contrôle distinct ;
- permissions Contrôle actives uniquement dans ce contexte.

Pour une personne externe permanente :

- compte Rewayah dédié ;
- profil professionnel minimal ;
- rôle principal Contrôleur.

## 1.3 Contrôleur invité

Le Contrôleur / Évaluateur invité est différent :

- accès temporaire ;
- périmètre explicite ;
- expiration automatique ;
- pas de profil permanent ;
- toutes les actions restent attribuables et journalisées.

Son UX détaillée sera spécifiée après le Contrôleur permanent, mais l'architecture du permanent ne doit rien empêcher de ce futur modèle.

---

# 2. CE QUI EXISTE DÉJÀ ET DOIT ÊTRE RÉUTILISÉ

## 2.1 Code fonctionnel déjà présent

**FAIT :**

- racine Contrôleur actuelle : `/controleur` ;
- `CTR-01` Planning du contrôle existe et est atteignable ;
- `CTR-02` Observation invisible existe et ouvre la salle ;
- le Contrôleur peut actuellement observer une séance sans micro ni caméra ;
- `Mon compte` partagé existe sur `/compte` ;
- `CTR-03` compte rendu / grille d'audit n'existe pas ;
- le signalement structuré Contrôleur n'existe pas ;
- le Contrôleur invité n'existe pas ;
- une seconde porte d'observation `/tc/observation/:seanceId` existe pour le Tuteur et ne doit pas devenir un deuxième système Contrôleur.

## 2.2 Réutilisation impérative de la salle

**DÉCISION D'ARCHITECTURE FRONTEND :** ne pas reconstruire LiveKit.

Le Contrôleur permanent réutilise le mode Contrôleur de la salle existante `/salle`.

Interdictions :

- créer un deuxième moteur média ;
- créer une deuxième room ;
- copier le mode Tuteur ;
- dupliquer la logique de reconnexion ;
- créer un nouveau fournisseur LiveKit ;
- exposer micro ou caméra au Contrôleur.

## 2.3 Composants partagés à réutiliser avant toute création

Claude inspecte les signatures réelles avant usage et réutilise au minimum :

- `ActionPrincipale` ;
- `PageShell` ;
- `PageParcours` ;
- `PageImmersive` ;
- `NavShell` ;
- `EntetePage` ;
- `AppCard` ;
- `GroupeReglages` + `LigneRubrique` ;
- `ControleSegmente` ;
- `StatusPill` ;
- `EcranResultat` ;
- `EtatSysteme` ;
- `EmptyState` ;
- `BlocAsynchrone` ;
- `Skeleton` ;
- `OfflineBanner` ;
- `LocalFeedback` ;
- `ConfirmDestructive` ;
- `AppBottomSheet` ;
- `SectionHeader` ;
- `LienFleche` ;
- `LigneCleValeur` ;
- `SignalRow` ;
- `FilterPill` ;
- `MenuFiltre` ;
- `MenuActions` ;
- `DataCollection` ;
- `PermanentNotice` ;
- `Pressable`.

## 2.4 Maquettes existantes réutilisables

Il n'existe aucune maquette Contrôleur dédiée prouvée.

À réutiliser comme références de pattern, sans recopier aveuglément le rôle Tuteur :

1. **Historique.png**
   - structure filtres + liste ;
   - statuts discrets ;
   - lignes détaillées ;
   - hiérarchie mobile ;
   - utile pour `CTR-05 Historique des contrôles`.

2. **MAN #26 - historique des observations côté administration**
   - déjà prévu par le chantier Tuteur ;
   - ne pas redessiner dans ce lot ;
   - futur Admin doit consommer les nouvelles visites Contrôleur dans ce même domaine d'audit au lieu de créer une deuxième histoire parallèle.

3. **Classe Details.png**
   - utile seulement pour le langage de la carte séance / CTA / planning ;
   - ne pas reprendre ses fonctions Tuteur ;
   - le Contrôleur ne choisit pas lui-même une classe depuis cette page.

4. **Salle / classe Live existante**
   - référence d'immersion ;
   - le support pédagogique reste dominant ;
   - les médias sont secondaires.

---

# 3. PRINCIPES UX DU CONTRÔLE

## 3.1 Le système organise, l'humain observe

La charge cognitive du Contrôleur doit être minimale.

Le système :

- sélectionne la séance ;
- vérifie le périmètre ;
- vérifie l'éligibilité ;
- empêche les conflits évidents ;
- prépare les faits mesurables ;
- ouvre la salle ;
- journalise la visite ;
- prépare le compte rendu ;
- joint le contexte à toute remarque ;
- transmet immédiatement à l'Admin.

Le Contrôleur :

- observe ;
- donne un avis structuré ;
- ajoute une remarque libre si nécessaire ;
- cible un enseignant, un élève ou la classe entière si nécessaire ;
- transmet.

## 3.2 Pas de planning manuel des visites

**DÉCISION :** Rewayah choisit les salles à visiter de façon pseudo-aléatoire sous contraintes.

Objectif :

- chaque classe reçoit au minimum une visite par semaine ;
- impossible pour l'enseignant de prédire quelle séance sera visitée ;
- éviter le sur-place opérationnel lorsque l'académie dépasse 100 classes ;
- obtenir au fil du temps des observations provenant de plusieurs contrôleurs lorsque possible.

Le client Flutter ne tire jamais la séance au hasard.

L'UI affiche uniquement la mission attribuée par le système.

## 3.3 Révélation tardive

Le Contrôleur ne reçoit pas un calendrier de toutes les visites futures.

État normal :

- prochaine mission disponible maintenant ou prochain créneau proche ;
- identité de la classe révélée uniquement quand la mission devient actionnable ;
- aucune liste de toutes les salles en direct.

## 3.4 Diffusion différée

**DÉCISION :**

- Admin : accès instantané à chaque contrôle ;
- Enseignant : pas de notification immédiate indiquant qu'il vient d'être observé ;
- synthèse enseignant : publication différée à la fin de la période mensuelle ;
- les dates/heures exactes des contrôles restent internes à l'Admin sauf décision contraire ;
- Tuteur : pas de rapport RH brut.

**PROPOSITION :** côté famille, n'afficher qu'un signal institutionnel non sensible du type « Suivi qualité Rewayah effectué ce mois-ci » si la Direction confirme que cette information est utile.

---

# 4. ARCHITECTURE D'INFORMATION

## 4.1 Navigation principale Contrôleur

Nouvelle navigation cible :

1. **Contrôle**
2. **Historique**
3. **Échanges**
4. **Compte**

Justification :

- Contrôle = tâche quotidienne ;
- Historique = preuves de ses propres missions ;
- Échanges = canal direct avec l'Administration ;
- Compte = espace partagé existant.

Mobile : barre basse.  
Tablette : rail.  
Desktop : barre latérale réelle.

Pour Enseignant/Admin multi-rôle : l'entrée dans `Contrôle` change de **contexte de travail**, pas d'identité.

## 4.2 Commutation d'espace

**PROPOSITION :** réutiliser la zone `Espaces` du Compte partagé comme point canonique pour passer de :

- Enseignant -> Contrôle ;
- Admin -> Contrôle ;
- Contrôle -> rôle principal.

Un raccourci dans l'en-tête peut ouvrir ce même sélecteur. Il ne crée pas un second mécanisme.

Lors du passage en mode Contrôle :

- toutes les capacités visibles sont recalculées ;
- aucune action Enseignant/Admin ne reste active dans la salle Contrôleur ;
- revenir au rôle principal nécessite de quitter la mission en cours.

---

# 5. CARTE DES FONCTIONS ANTI-DOUBLON

| Fonction | Écran canonique | Entrées |
|---|---|---|
| Voir la prochaine mission | CTR-01 | racine Contrôle |
| Ouvrir une mission | CTR-01 -> CTR-02 | CTA de mission |
| Observer la séance | CTR-02 | mission active uniquement |
| Quitter l'observation | CTR-02 | commande unique Quitter |
| Produire le compte rendu | CTR-03 | sortie de CTR-02 |
| Ajouter une remarque ciblée | CTR-03 | étape Remarque |
| Contacter l'Admin à propos de la mission | CTR-04 | raccourci depuis CTR-03 / détail historique vers même thread |
| Voir ses contrôles passés | CTR-05 | Historique |
| Voir le détail d'un contrôle | CTR-06 | ligne historique |
| Ajouter un complément à un rapport envoyé | CTR-06 -> CTR-03B | action Ajouter un complément |
| Voir ses échanges Admin | CTR-04 | navigation Échanges |
| Gérer son compte | `/compte` | Compte |
| Changer d'espace | `/compte` > Espaces | raccourci éventuel d'en-tête vers même surface |

Aucune recherche globale de classes, élèves ou enseignants n'est créée pour le Contrôleur.

---

# 6. PARCOURS DE BOUT EN BOUT

## P-CTR-01 - Entrer dans l'espace Contrôle

1. La personne possède une capacité Contrôleur active.
2. Elle ouvre son sélecteur d'espace.
3. Elle choisit `Contrôle`.
4. Le système vérifie l'autorisation effective.
5. Si autorisé, `CTR-01` s'ouvre.
6. Si l'autorisation a expiré ou été retirée, aucun contenu précédent ne reste visible.
7. Message : `Votre accès au contrôle n'est plus actif.`
8. Action : `Revenir à mon espace`.

## P-CTR-02 - Mission proposée

1. Le Contrôleur ouvre `Contrôle`.
2. Rewayah fournit zéro ou une mission actionnable.
3. L'écran affiche : classe, heure, durée prévue, enseignant, statut de salle et contexte minimal.
4. Aucun nom de famille d'élève, contact, donnée financière ou profil privé.
5. Si la salle n'est pas encore accessible : compteur / état d'attente.
6. Quand elle est accessible : CTA `Commencer le contrôle`.

## P-CTR-03 - Observation

1. Le Contrôleur touche `Commencer le contrôle`.
2. Le serveur confirme une autorisation de mission encore valide.
3. Entrée dans `CTR-02` mode incognito.
4. Micro absent.
5. Caméra absente.
6. Chat de classe absent.
7. Publication de données dans la salle interdite.
8. Support, enseignant et élèves visibles uniquement selon la projection autorisée.
9. Le Contrôleur peut couper/rétablir localement le son reçu, agrandir le support et quitter.
10. Sa présence est journalisée mais non révélée en temps réel aux participants.
11. En cas de coupure réseau, la salle passe en état reconnecting réel, jamais en faux direct.
12. La sortie mène au compte rendu.

## P-CTR-04 - Compte rendu ultra-court

1. La page charge les faits automatiques.
2. Question principale : `Avez-vous quelque chose à signaler ?`
3. Choix :
   - `Rien à signaler`
   - `Ajouter une observation`
   - `Signaler un point important`
4. Si `Rien à signaler` : envoi en une action, puis possibilité d'annuler quelques secondes via feedback local si techniquement sûr.
5. Si observation : parcours guidé court.
6. L'Admin reçoit immédiatement le rapport final.
7. Aucune notification immédiate n'est envoyée à l'enseignant.

## P-CTR-05 - Observation structurée

Étape 1 : nature

- Point positif
- À suivre
- Intervention Admin souhaitée

Étape 2 : domaine

- Pédagogie
- Interaction avec les élèves
- Gestion de la classe
- Respect du cadre
- Comportement / climat
- Autre

Étape 3 : personne concernée

- Enseignant
- Classe entière
- Élève précis
- Aucun participant précis

Pour un élève : sélectionner depuis le roster autorisé, jamais saisir librement un identifiant technique.

Étape 4 : texte libre facultatif ou obligatoire selon gravité

Placeholder : `Décrivez seulement ce que vous avez observé.`

Étape 5 : récapitulatif

CTA : `Envoyer le compte rendu`

## P-CTR-06 - Canal direct Admin

1. Depuis un rapport ou son détail, action `Écrire à l'administration`.
2. Ouvre le thread canonique de la mission dans `CTR-04`.
3. Le contexte de la visite est joint automatiquement.
4. Le Contrôleur n'a pas besoin de recopier classe, enseignant ou date.
5. L'Admin peut répondre.
6. Aucun participant de la classe n'a accès à ce canal.

## P-CTR-07 - Rapport déjà envoyé

Un rapport envoyé n'est pas réécrit silencieusement.

Action : `Ajouter un complément`.

Le complément conserve :

- auteur ;
- date ;
- heure ;
- rapport parent ;
- contenu ;
- motif facultatif.

## P-CTR-08 - Mission indisponible

Cas : séance annulée, autorisation révoquée, conflit détecté, salle fermée.

Le Contrôleur ne peut pas forcer l'entrée.

Message générique : `Cette mission n'est plus disponible.`

Action : `Revenir au contrôle`.

Ne pas révéler un détail de sécurité inutile.

---

# 7. FICHES ÉCRANS

## CTR-01 - Contrôle

**Objectif :** permettre de réaliser la mission attribuée sans rechercher une classe.

Mobile :

1. En-tête `Contrôle`.
2. Statut de couverture personnel utile, sans score : `Cette semaine : 4 contrôles réalisés` si la donnée est fiable.
3. Carte dominante `Votre prochaine mission`.
4. Informations strictement nécessaires.
5. CTA unique `Commencer le contrôle` quand disponible.
6. Bloc secondaire `Compte rendu à terminer` uniquement si nécessaire.
7. Aucun tableau global des classes.

Desktop :

- sidebar Contrôleur ;
- contenu principal max-width lisible ;
- colonne principale Mission ;
- colonne secondaire État / rapports à terminer ;
- ne pas étirer le mobile.

États :

- chargement ;
- aucune mission ;
- mission prévue ;
- salle accessible ;
- mission révoquée ;
- hors ligne ;
- permission retirée ;
- rapport en attente.

Textes proposés :

- vide : `Aucun contrôle n'est à réaliser pour le moment.`
- aide : `Rewayah vous proposera une mission lorsqu'une séance compatible sera disponible.`
- hors ligne : `Vous devez être en ligne pour commencer un contrôle.`

## CTR-02 - Observation discrète

**Objectif :** observer sans intervenir.

Utiliser `PageImmersive` registre salle.

Zone haute Contrôleur, visible seulement par lui :

- `Contrôle Rewayah` ;
- durée de présence personnelle ;
- état réseau ;
- action Quitter.

Contenu :

- support pédagogique dominant ;
- vidéo enseignant secondaire ;
- vidéos élèves selon mise en page existante et permissions ;
- roster minimal si nécessaire.

Commandes :

- Son reçu ;
- Agrandir le support ;
- Quitter.

Interdits :

- micro ;
- caméra ;
- lever la main ;
- chat de classe ;
- annotation ;
- changement de support ;
- gestion de présence ;
- ouverture de profil complet ;
- coordonnées ;
- message direct à un élève ;
- export ;
- téléchargement.

## CTR-03 - Compte rendu

**Objectif :** transformer l'observation humaine en donnée utile avec le minimum de saisie.

Pattern : `PageParcours`.

Écran initial :

Titre : `Compte rendu`
Sous-titre : classe + heure, données serveur.

Question : `Avez-vous quelque chose à signaler ?`

Cartes :

- `Rien à signaler`
- `Ajouter une observation`
- `Signaler un point important`

Aucune valeur présélectionnée.

### CTR-03A - Observation

Questions une par page.

Ne pas afficher une grille de 25 critères sur mobile.

### CTR-03B - Complément

Même langage visuel, mais bandeau : `Ce complément sera ajouté au rapport existant.`

Aucune édition destructive de l'original.

## CTR-04 - Échanges

**Objectif :** canal professionnel direct avec l'Admin.

Liste de threads par mission ou sujet.

Chaque thread montre :

- titre humain ;
- classe ou sujet ;
- dernière activité ;
- état `Réponse reçue` / `En attente` ;
- aucune donnée privée inutile.

Dans un thread lié à une visite, le contexte est épinglé en haut.

## CTR-05 - Historique

Réutiliser le pattern de `Historique.png` :

- filtres proches de la liste ;
- lignes séparées ;
- statuts discrets ;
- accès détail ;
- pas de mosaïque de grandes cartes.

Filtres :

- Période ;
- Classe ;
- État du rapport.

Ne pas ajouter Enseignant comme filtre si le Contrôleur n'est pas autorisé à parcourir librement tous les enseignants.

Ligne :

- date ;
- classe ;
- enseignant d'affichage ;
- durée observée ;
- statut `Envoyé`, `Complément ajouté`, `À terminer`.

## CTR-06 - Détail d'un contrôle

Sections :

1. Mission
2. Faits automatiques
3. Observation du Contrôleur
4. Compléments
5. Échanges Admin

Actions :

- `Ajouter un complément`
- `Écrire à l'administration`

Pas d'édition du rapport final.

---

# 8. DONNÉES ET CONFIDENTIALITÉ

## 8.1 Données que le Contrôleur peut voir pendant une mission

Minimum nécessaire :

- nom humain de la classe ;
- enseignant, prénom / nom d'affichage professionnel autorisé ;
- objectif ou cycle utile à l'observation ;
- support actif ;
- prénoms / identifiants pédagogiques minimaux des élèves présents si nécessaire ;
- audio / vidéo live de la séance ;
- état de salle ;
- faits automatiques liés à la mission.

## 8.2 Données interdites par défaut

Le Contrôleur ne voit pas :

- e-mail famille ;
- téléphone ;
- adresse ;
- identité légale complète d'un mineur ;
- KYC ;
- documents d'identité ;
- paiements ;
- solde ;
- appareils ;
- données d'un autre foyer ;
- notes administratives ;
- sanctions internes ;
- rémunération enseignant ;
- messages privés hors thread de contrôle ;
- exports ;
- secrets ;
- URL brutes de stockage ;
- enregistrements audio passés, sauf mission juridique spécifique séparée et autorisée.

## 8.3 Pas de cache durable

**PROPOSITION SÉCURITÉ :** aucune donnée Contrôleur sensible ne doit être conservée en cache local persistant par défaut.

Les brouillons peuvent rester en mémoire de l'application pendant la tâche.

Toute persistance hors ligne d'un rapport doit faire l'objet d'une décision de sécurité séparée avant production.

## 8.4 Captures d'écran

Ne jamais promettre « capture impossible » sur toutes les plateformes.

PROPOSITION : watermark discret dans l'interface Contrôleur avec identité du contrôleur et horodatage, uniquement visible pour lui, afin de décourager la diffusion externe.

---

# 9. RBAC / ABAC ET SÉPARATION DES CAPACITÉS

## 9.1 Règle fondamentale

L'UI ne décide jamais qu'une personne est autorisée parce qu'un bouton est visible.

Chaque entrée privilégiée doit être confirmée par l'autorité serveur effective.

## 9.2 Capacité Contrôleur

Le modèle doit pouvoir exprimer au minimum :

- Contrôleur actif / inactif ;
- date de début ;
- date de fin éventuelle ;
- périmètre autorisé ;
- capacité à observer ;
- capacité à écrire un rapport ;
- capacité à ouvrir le canal Admin.

Aucun droit Admin général n'est hérité du rôle Contrôleur.

## 9.3 Séparation dynamique des rôles

Un Enseignant-Contrôleur en mode Contrôle :

- n'utilise pas ses outils Enseignant ;
- ne contrôle jamais sa propre séance ;
- ne peut pas corriger la présence ;
- ne peut pas éditer le dossier pédagogique ;
- ne peut pas rejoindre comme enseignant depuis la même mission.

Un Admin-Contrôleur en mode Contrôle :

- n'utilise pas ses actions Admin dans la salle ;
- produit un rapport comme n'importe quel Contrôleur ;
- toute décision administrative se fait après sortie dans l'espace Admin.

## 9.4 Conflits d'intérêt

**DÉCISION PRODUIT RECOMMANDÉE :**

Exclure automatiquement :

- propre classe de l'Enseignant-Contrôleur ;
- séance où il est remplaçant ;
- toute mission où il est participant actif.

À documenter plus tard : relations personnelles / familiales connues et autres conflits déclarés.

## 9.5 Principe deny-by-default

Si :

- le périmètre est inconnu ;
- l'autorisation n'est pas récupérable ;
- la mission a expiré ;
- l'état serveur est contradictoire ;

alors l'observation est refusée.

Aucun mode dégradé ne doit élargir les droits.

---

# 10. JOURNAL D'AUDIT

Toute opération sensible doit laisser une trace distincte du rapport pédagogique.

Événements minimum :

- capacité Contrôleur attribuée ;
- capacité modifiée ;
- capacité révoquée ;
- changement de périmètre ;
- mission attribuée ;
- mission ouverte ;
- entrée dans la salle ;
- sortie ;
- durée ;
- refus d'autorisation ;
- rapport envoyé ;
- complément ajouté ;
- thread Admin ouvert ;
- message envoyé ;
- consultation d'un rapport sensible ;
- tentative d'accès hors périmètre.

Le Contrôleur ne peut ni modifier ni supprimer ces traces.

Le rapport et le journal d'audit sont deux objets différents.

---

# 11. SÉLECTION DES MISSIONS

## 11.1 Objectifs

- minimum hebdomadaire par classe ;
- imprévisibilité ;
- répartition entre contrôleurs ;
- compatibilité horaire ;
- exclusion des conflits ;
- capacité à ajouter des contrôles supplémentaires lorsqu'une anomalie institutionnelle le justifie.

## 11.2 Ce que l'UI ne doit pas révéler

Au Contrôleur :

- algorithme exact de priorité ;
- liste complète des classes non encore contrôlées ;
- motif interne d'un contrôle supplémentaire, sauf nécessité.

À l'Enseignant :

- aucune indication en temps réel d'une visite particulière ;
- aucun compteur « dernière visite » permettant de prédire la prochaine.

## 11.3 Données de couverture

Admin pourra plus tard voir :

- classes non contrôlées dans la fenêtre ;
- nombre de visites ;
- diversité des contrôleurs ;
- rapports à examiner ;
- anomalies répétées.

Le Contrôleur voit seulement sa charge personnelle utile.

---

# 12. SYNTHÈSE MENSUELLE ENSEIGNANT

À ajouter plus tard au rôle Enseignant, ne pas reconstruire ce rôle maintenant.

Claude doit marquer dans le tableau de suivi :

**ENS - Qualité et parcours professionnel**

Contenu futur :

- synthèse mensuelle des observations publiables ;
- éléments positifs ;
- points à suivre ;
- réponses / échanges autorisés ;
- historique qualité ;
- badges / responsabilités ;
- éligibilité à certaines promotions ;
- aucune vitesse brute d'apprentissage des élèves comme score de performance.

La paie reste un domaine séparé.

---

# 13. IMPACTS ADMIN À ENREGISTRER POUR PLUS TARD

Ne pas construire maintenant, mais ajouter au registre Administration finale :

1. Attribution / révocation de la capacité Contrôleur.
2. Définition du périmètre.
3. Contrôleur externe permanent.
4. Rotation et couverture des classes.
5. Vue des missions réalisées en temps réel.
6. File de rapports.
7. Signalements urgents.
8. Canal de discussion avec le Contrôleur.
9. Historique immuable.
10. Détection des Contrôleurs qui valident mécaniquement tout.
11. Calibration entre Contrôleurs.
12. Gestion des conflits d'intérêt.
13. Synthèse mensuelle Enseignant.
14. Publication ou non d'un signal qualité Tuteur.
15. Contrôleur / Évaluateur invité.
16. Révocation immédiate d'un accès privilégié.
17. Revue périodique des privilèges.
18. Accès au journal d'audit séparé de l'administration des droits.

---

# 14. SÉCURITÉ, RGPD / UK GDPR ET PROTECTION DES MINEURS

## 14.1 Point critique : observation non annoncée

L'objectif Rewayah est de ne pas révéler l'instant exact d'une visite.

Cela ne doit pas devenir une surveillance secrète juridiquement non documentée.

**BLOQUANT AVANT PRODUCTION :** la politique de monitoring des enseignants doit être revue juridiquement / DPO.

La documentation doit expliquer au personnel avant activation :

- que des observations qualité non annoncées peuvent avoir lieu ;
- pourquoi ;
- qui peut observer ;
- quelles données sont vues ;
- ce qui est enregistré ;
- ce qui ne l'est pas ;
- combien de temps les données sont conservées ;
- qui les consulte ;
- comment elles peuvent influencer une décision ;
- voies de contestation / correction ;
- contact confidentialité.

Le bandeau permanent `Cours enregistré, visite de contrôle possible.` est conservé, mais ne suffit pas à lui seul à documenter tout le traitement.

## 14.2 DPIA

**GATE PRODUIT RECOMMANDÉ :** aucune ouverture réelle de ce module sans DPIA formalisée.

Raisons :

- monitoring de travailleurs / prestataires ;
- enfants / personnes vulnérables ;
- vidéo / audio live ;
- évaluation de performance possible ;
- effets possibles sur promotion / responsabilité / rémunération ;
- accès transfrontière possible.

## 14.3 Base légale

Ne jamais coder `consentement = base légale`.

La base légale applicable doit être choisie et documentée avec conseil spécialisé.

Le consentement est particulièrement fragile dans une relation de travail à cause du déséquilibre de pouvoir.

## 14.4 Minimisation

Ne collecter ni exposer une donnée « au cas où ».

La visite qualité n'autorise pas automatiquement l'accès aux dossiers complets des élèves ou de l'enseignant.

## 14.5 Finalité

Les données de contrôle sont créées pour la qualité institutionnelle et les décisions qui en découlent selon politique publiée.

Toute réutilisation ultérieure pour une autre finalité doit être documentée et validée.

## 14.6 Rétention

**BLOQUANT :** aucune durée de conservation des rapports Contrôleur n'est actuellement prouvée.

Ne pas inventer 30 jours, 1 an, 5 ans, etc.

La règle sera ajoutée à la politique de conservation Admin après DPIA / validation juridique.

## 14.7 Mineurs

Par défaut :

- pas de nom de famille complet si non nécessaire ;
- pas de coordonnées ;
- pas de contact direct Contrôleur-enfant ;
- pas de téléchargement ;
- pas de copie locale persistante ;
- pas de partage du rapport avec d'autres familles ;
- accès strictement missionnel.

## 14.8 Accès international

**À VALIDER :** un Contrôleur situé dans un pays différent des élèves ou du responsable de traitement peut soulever des exigences de transfert international selon l'organisation juridique et les flux réels.

Ne pas ouvrir un accès externe permanent sans cette revue.

---

# 15. POINTS DE SÉCURITÉ NON DOCUMENTÉS À MARQUER COMME BLOQUANTS

Claude ne les résout pas dans le frontend. Il les ajoute au tableau :

1. Niveau d'authentification requis pour une observation privilégiée.
2. MFA / step-up auth pour Contrôleur.
3. Procédure de révocation immédiate.
4. Politique exacte de conservation des rapports.
5. Base légale du monitoring enseignant.
6. DPIA.
7. Politique de contestation d'un rapport.
8. Traitement des données sensibles captées accidentellement dans la vidéo / audio.
9. Transferts internationaux.
10. Politique de capture d'écran / watermark.
11. Persistance locale éventuelle d'un brouillon.
12. Notification juridique requise aux élèves / parents / enseignants.
13. Qui peut consulter un rapport brut.
14. Qui peut exporter.
15. Qui peut voir l'identité du Contrôleur après publication mensuelle.

---

# 16. RECETTE FRONTEND

Le lot Contrôleur n'est pas terminé tant que les scénarios suivants ne sont pas visibles et testables en mode démonstration hors production :

1. Contrôleur dédié ouvre son espace.
2. Enseignant bascule vers Contrôle sans second compte.
3. Admin bascule vers Contrôle sans conserver ses actions Admin dans la salle.
4. Utilisateur sans capability ne voit pas l'espace.
5. Capability révoquée pendant navigation -> sortie sûre.
6. Aucune mission -> état vide correct.
7. Mission proposée -> CTA correct.
8. Salle non ouverte -> aucun accès anticipé.
9. Observation -> aucun micro / caméra / chat.
10. Reconnexion -> pas de faux direct.
11. Quitter -> compte rendu.
12. `Rien à signaler` -> rapport envoyé.
13. Observation structurée -> rapport envoyé.
14. Remarque ciblée enseignant.
15. Remarque ciblée élève avec identité minimale.
16. Canal Admin conserve le contexte.
17. Rapport envoyé non éditable.
18. Complément ajouté.
19. Historique filtre correctement.
20. Mobile 390.
21. Tablette 768.
22. Desktop 1440.
23. Light.
24. Dark.
25. Texte 200 %.
26. Clavier complet desktop.
27. Lecteur d'écran.
28. RTL structurel.
29. Hors ligne.
30. Accès refusé.
31. Aucun contenu privé interdit dans capture QA.
32. Aucune donnée de démonstration dans production.

---

# 17. HANDOFF CLAUDE - ORDRE DE TRAVAIL

Claude doit travailler dans cet ordre :

1. Inspecter le dépôt réel et confirmer l'état actuel de `CTR-01`, `CTR-02`, `/salle`, `/compte`, `NavShell`, composants partagés.
2. Produire `CONTROLEUR_EXISTING_MAPPING.md` avec preuves fichier:ligne.
3. Produire la carte fonctions -> route -> composant existant -> modification minimale.
4. Ne modifier aucun backend, migration, RLS, RPC ou LiveKit core dans ce lot.
5. Déclarer les contrats manquants comme dépendances frontend.
6. Réutiliser `/salle` Contrôleur.
7. Refondre `CTR-01` pour Mission automatique, pas catalogue de toutes les séances.
8. Ajouter navigation Contrôleur adaptative.
9. Construire `CTR-03`, `CTR-04`, `CTR-05`, `CTR-06` avec composants partagés.
10. Ajouter mode démonstration Contrôleur hors production.
11. Produire captures 390 / 768 / 1440, clair et sombre.
12. Lancer revue UX indépendante.
13. Lancer revue accessibilité.
14. Lancer revue frontière sécurité / données visibles.
15. Marquer tous les BLOQUANTS sécurité / légal dans le tableau principal.
16. Ajouter les impacts Enseignant / Tuteur / Admin au backlog, sans réouvrir leurs lots maintenant.

---

# 18. RÉFÉRENCES EXTERNES À UTILISER LORS DE LA REVUE SPÉCIALISÉE

Références officielles / reconnues à vérifier au moment de l'implémentation :

- UK ICO - Data protection and monitoring workers.
- UK ICO - Data Protection Impact Assessments.
- UK ICO - Age Appropriate Design / Children's Code.
- Règlement (UE) 2016/679 - articles 5, 25, 32 et DPIA selon contexte.
- NIST - Least Privilege et Separation of Duties.
- OWASP - Authorization Cheat Sheet.
- OWASP - Logging Cheat Sheet.
- WCAG 2.2 AA.
- Material Design 3.
- Apple Human Interface Guidelines.

---

# 19. DÉCISIONS ENCORE À VALIDER PAR LE DIRECTEUR

1. La synthèse mensuelle Enseignant masque-t-elle systématiquement les dates exactes de visite ?
2. Le Tuteur voit-il seulement un indicateur institutionnel ou aucun signal de contrôle ?
3. Durée cible / maximale d'une observation Contrôleur.
4. Possibilité pour le Contrôleur de refuser une mission et avec quels motifs.
5. Seuil de couverture : « au moins une fois par semaine » doit-il être absolu ou une politique configurable ?
6. Les contrôles supplémentaires déclenchés par anomalie restent-ils indiscernables des contrôles aléatoires pour le Contrôleur ?
7. L'enseignant voit-il l'identité des Contrôleurs dans sa synthèse mensuelle ?
8. Les badges / promotions liés à la fonction Contrôleur seront-ils publics, internes ou les deux ?
9. L'enseignant peut-il répondre directement à un constat publié ou seulement demander une révision à l'Admin ?

---

# 20. CONCLUSION DE CONCEPTION

Le Contrôleur Rewayah ne doit pas devenir un mini-Admin ni un inspecteur bureaucratique.

Le produit doit produire trois effets :

1. **Rassurer** : chaque classe sait qu'une vraie supervision institutionnelle existe.
2. **Responsabiliser** : l'enseignant sait que la qualité promise est effectivement vérifiée, sans pouvoir prédire le moment.
3. **Protéger** : l'observation reste bornée, minimale, traçable, non interactive et gouvernée par des permissions fortes.

La règle de conception est donc :

**Rewayah organise et trace. Le Contrôleur observe et qualifie. L'Admin décide.**
