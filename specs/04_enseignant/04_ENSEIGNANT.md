# REWAYAH ACADEMY - 04_ENSEIGNANT

**Version :** V1  
**Date :** 26/09/2026  
**Statut :** PROPOSITION À VALIDER PAR LE DIRECTEUR  
**Périmètre :** verticale complète du rôle Enseignant  
**Rôle principal :** Enseignant  
**Dépendances fortes :** `02_CLASSE_ET_VISIO.md`, `03_ADMIN_VALIDATION_DOSSIERS.md`, référentiel académique, Teaching Core, Bible Frontend UI/UX V2  
**Principe directeur :** le professeur enseigne. L'application absorbe la bureaucratie, les calculs, la préparation répétitive et les vérifications mécaniques.

---

# 0. Mission de cette verticale

Cette verticale ferme l'expérience Enseignant V1.

Elle doit transformer l'espace enseignant en un véritable cockpit pédagogique, pas en un logiciel administratif.

L'enseignant doit pouvoir :

1. comprendre sa journée en quelques secondes ;
2. préparer une séance en moins d'une minute lorsque rien d'anormal ne bloque ;
3. entrer dans la séance sans refaire des réglages inutiles ;
4. enseigner sans quitter la salle pour consulter un élève, ouvrir un support ou signaler un problème ;
5. utiliser la file de récitation, le support partagé et les outils pédagogiques sans multiplier les menus ;
6. terminer la séance en validant un cahier prérempli, avec saisie des seules exceptions ;
7. gérer ses Classes, disponibilités, absences et remplacements sans casser le principe d'enseignant référent permanent ;
8. ne jamais recevoir les coordonnées privées ou les documents d'identité des familles.

La cible produit n'est pas de donner plus d'outils à l'enseignant. La cible est de lui faire effectuer moins d'actions pour mieux enseigner.

---

# 1. Autorité et ordre de lecture

Claude Code applique les sources dans cet ordre :

1. demande explicite la plus récente du directeur ;
2. sécurité, confidentialité, RLS, permissions LiveKit et contrats serveur réellement migrés ;
3. `02_CLASSE_ET_VISIO.md` pour tout ce qui appartient à l'entrée, au préflight, à la salle, au chrono, à la présence, à la reconnexion et à la sortie de séance ;
4. `03_ADMIN_VALIDATION_DOSSIERS.md` pour la porte d'activation du compte enseignant ;
5. `00_LIRE_D_ABORD.md`, `01_PRODUIT_ET_PARCOURS.md`, `02_ARCHITECTURE_ET_SECURITE.md`, `03_DESIGN_SYSTEM_ET_UX.md` ;
6. `REWAYAH_REFERENTIEL_ACADEMIQUE_V1` ;
7. `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1` ;
8. présent document pour la verticale Enseignant ;
9. composants et routes réellement présents dans le dépôt ;
10. référentiels UX externes cités dans la section 3, uniquement pour améliorer l'expérience, jamais pour inventer une règle métier.

## 1.1 Interdiction de dupliquer `02_CLASSE_ET_VISIO`

`ENS-03 Salle` existe déjà comme verticale transversale dans `02_CLASSE_ET_VISIO.md`.

Le présent document :

- raccorde l'enseignant à cette salle ;
- décrit les extensions spécifiques au rôle enseignant ;
- décrit les points d'entrée et de sortie ;
- décrit le roster pédagogique, la file de récitation et les surfaces contextuelles ;
- ne recrée jamais une deuxième salle, un deuxième préflight, une deuxième machine de reconnexion ou un deuxième moteur de présence.

Si le fichier actif `02_CLASSE_ET_VISIO.md` n'est pas retrouvé dans le dépôt, Claude bloque uniquement le raccordement qui en dépend, consigne l'absence, puis poursuit les écrans indépendants.

## 1.2 Règle de preuve

Pour toute capacité, distinguer explicitement :

- spécifiée ;
- présente dans le code ;
- branchée depuis un vrai bouton ;
- testée localement ;
- testée sur staging ;
- déployée.

Un widget mort ou un service non utilisé ne compte pas comme fonctionnalité.

---

# 2. État actuel connu à auditer avant modification

Le dernier inventaire fourni au chantier décrit notamment :

- `ENS-01 Premiers pas` sur `/enseignant/bienvenue`, mais sans point d'entrée réel ;
- `ENS-02 Votre journée` sur `/enseignant/journee`, atteignable mais encore contaminé par l'ancien modèle de prise d'élèves individuels ;
- `ENS-06 Créneaux` sur `/enseignant/creneaux`, atteignable mais encore fondé sur l'ancien matching individuel ;
- `ENS-05 Profil` sur `/enseignant/profil`, atteignable, sans parcours d'envoi de photo publique ;
- `ENS-07 Fiche de la classe` sur `/enseignant/groupe/:groupeId`, atteignable ;
- `ENS-08 Revue de la classe`, atteignable mais vide à cause des permissions actuelles ;
- `ENS-03 Salle` sur `/salle`, atteignable ;
- `ENS-04 Cahier de transmission`, atteignable après la salle ;
- roster pédagogique complet hors séance non raccordé correctement ;
- Coran hors salle absent pour l'enseignant ;
- sélecteur Bibliothèque en séance présent dans du code non branché ;
- Teaching Dock et état partagé présents partiellement mais non branchés selon le dernier inventaire ;
- déclaration d'absence et remplacement absents ;
- double fuseau et notices DST absents ;
- notifications applicatives non garanties.

Claude doit réinspecter le dépôt courant avant de considérer cette photographie comme encore exacte.

---

# 3. Recherche externe appliquée à l'expérience Enseignant

Les références externes ci-dessous servent seulement à valider des principes UX et de charge de travail. Elles ne modifient aucune règle Rewayah.

## 3.1 Charge de travail enseignant

Références :

- UK Department for Education, Workload Reduction Taskforce ;
- UK Department for Education, Data Management Review Group ;
- Education Endowment Foundation, `Teacher Feedback to Improve Pupil Learning` ;
- Education Endowment Foundation, travaux 2026 sur feedback et autonomie.

Conclusions applicables :

1. une collecte de données doit avoir un objectif explicite ;
2. une donnée déjà observable ou calculable ne doit pas être ressaisie ;
3. le feedback utile doit être précis, actionnable et soutenable ;
4. le système ne doit pas imposer une fréquence ou une longueur de commentaire sans valeur pédagogique ;
5. les tâches non pédagogiques doivent être minimisées pour préserver le temps d'enseignement.

Conséquence Rewayah :

- présence automatique ;
- rapport prérempli ;
- aucune feuille de présence manuelle ;
- aucune narration hebdomadaire ;
- commentaire textuel seulement lorsqu'une exception le justifie ;
- données de séance dérivées automatiquement du système ;
- prochaines actions pédagogiques courtes et structurées.

## 3.2 Flutter multi-format

Références :

- Flutter, Adaptive and responsive design ;
- Flutter, Large screen devices ;
- Flutter, Best practices for adaptive design ;
- Flutter, User input & accessibility.

Conséquence Rewayah :

- breakpoint par espace disponible, pas par nom de plateforme ;
- téléphone, tablette et desktop ont des compositions distinctes ;
- clavier, souris, trackpad et stylet doivent être considérés ;
- les flux fréquents doivent être utilisables au clavier sur desktop ;
- le contexte et la position de lecture doivent être restaurés.

## 3.3 LiveKit Flutter

Références :

- LiveKit Flutter SDK, `FastConnectOptions` ;
- LiveKit Flutter SDK, événements `RoomReconnectingEvent` et `RoomReconnectedEvent`.

Conséquence Rewayah :

- micro, caméra et écran restent non publiés par défaut ;
- un préflight peut tester localement un périphérique sans publier dans la salle ;
- l'UI doit distinguer reconnexion en cours, reconnexion réussie et déconnexion définitive ;
- la reconnexion ne doit pas effacer le support, la position pédagogique ou le contexte local lorsque le SDK et le backend permettent leur restauration.

Claude vérifie la version LiveKit réellement installée avant toute utilisation d'une API.

## 3.4 Apple HIG et WCAG 2.2

Conséquence Rewayah :

- préserver le contexte ;
- feedback passif proche de l'objet concerné ;
- confirmation modale seulement quand la conséquence la justifie ;
- ne jamais cacher le focus clavier derrière une barre persistante ;
- statut accessible au lecteur d'écran ;
- cibles Rewayah d'au moins 48 dp, donc plus strictes que le minimum WCAG 2.2 de 24 CSS px.

---

# 4. Contradictions à neutraliser avant implémentation

## 4.1 Ancien matching individuel

OBSOLETE :

- `Élèves en attente` ;
- `Prendre {jour} à {heure}` ;
- toute logique où l'enseignant prend un élève isolé.

NOUVELLE LOGIQUE :

- Classes précréées ;
- rythme récurrent complet ;
- enseignant référent permanent ;
- l'enseignant se positionne sur la Classe entière, jamais sur une seule occurrence normale ;
- un remplacement ponctuel ne change pas le titulaire.

## 4.2 Fenêtre d'entrée

Le dépôt a historiquement porté plusieurs valeurs.

Décision d'architecture :

- l'UI ne calcule ni ne code une durée locale ;
- elle consomme `join_opens_at` ou le contrat équivalent de `02_CLASSE_ET_VISIO.md` ;
- la valeur courante peut être proche de T-20, mais elle reste serveur et configurable.

## 4.3 Libellé interdit

Ne jamais afficher :

`Cours en cours`

Employer selon le contexte :

- `Séance en direct`
- `En séance`
- `Séance toujours en direct`

## 4.4 Capacités et durées

Plusieurs documents historiques portent des capacités différentes.

Règle :

- ne jamais coder `4`, `5`, `6`, `60`, `90` comme vérité UI ;
- afficher la capacité et la durée fournies par la Classe ou sa politique publiée ;
- toute nouvelle valeur commerciale ou académique doit être versionnée côté serveur.

## 4.5 Observation parent

Les anciennes valeurs du Teaching Core sont remplacées par la décision plus récente :

- 2 visites maximum par parent et par séance par défaut ;
- 120 secondes maximum par visite ;
- une visite écourtée est consommée ;
- l'enseignant voit une notice discrète ;
- l'enfant concerné voit une notice ;
- les autres élèves ne sont pas interrompus ;
- l'UI lit toujours la politique effective du serveur.

## 4.6 Enregistrement

Décision directeur la plus récente :

- l'enregistrement audio est réel ;
- le stockage dédié R2 existe selon la décision fournie ;
- la notice produit est conservée.

Claude doit tout de même vérifier le raccordement serveur réel avant de présenter un état comme techniquement garanti.

---

# 5. North Star UX Enseignant

## 5.1 Contrat anti-burnout obligatoire

Objectifs déjà imposés par le référentiel Rewayah :

- avant séance : moins d'une minute lorsque tout est normal ;
- après séance : moins de 45 secondes pour la séance entière lorsque tout est normal ;
- aucun rapport narratif hebdomadaire ;
- l'app produit le résumé ;
- l'enseignant ne modifie que les exceptions.

## 5.2 Objectifs UX complémentaires, PROPOSITION

Les objectifs ci-dessous sont des critères de conception, pas des règles académiques :

- comprendre la prochaine action depuis l'accueil en moins de 10 secondes ;
- accéder à une Classe attribuée en 2 interactions maximum depuis la navigation principale ;
- entrer dans une séance ouverte depuis `Aujourd'hui` avec au plus 2 interactions intentionnelles après préflight non bloquant ;
- ouvrir la fiche pédagogique d'un élève en 1 interaction depuis le roster ;
- ne jamais traverser plus d'une surface intermédiaire pour ouvrir un support ;
- si aucun problème n'existe après la séance, permettre une validation du cahier en 1 action principale après lecture ;
- ne jamais afficher plus de 3 alertes prioritaires simultanément sur `Aujourd'hui`.

## 5.3 Règle d'or

**Normal = automatique et calme. Exception = visible et actionnable.**

Un professeur dont tout va bien ne doit pas travailler pour l'application.

---

# 6. Fiche du rôle

## 6.1 Qui est l'enseignant Rewayah

Utilisateur professionnel ou semi-professionnel qui enseigne depuis téléphone, tablette ou ordinateur, souvent avec plusieurs Classes et plusieurs fuseaux horaires.

Il peut avoir :

- une aisance numérique moyenne ;
- une connexion variable ;
- plusieurs langues d'enseignement ;
- plusieurs Classes récurrentes ;
- des remplacements ponctuels ;
- des élèves mineurs et adultes ;
- des cours successifs avec peu de temps entre eux.

## 6.2 Ses cinq tâches prioritaires

1. voir sa prochaine séance et entrer à l'heure ;
2. savoir quoi enseigner et où reprendre ;
3. voir les informations pédagogiques indispensables des élèves ;
4. enseigner avec le support et les outils sans quitter la salle ;
5. clôturer le cours rapidement et préparer la suite.

## 6.3 Ce qu'il ne doit jamais voir

- téléphone d'un tuteur ;
- e-mail familial ;
- adresse ;
- KYC ;
- document d'identité ;
- paiements ;
- solde ;
- coordonnées privées ;
- géolocalisation précise ;
- identifiants privés d'appareil ;
- notes internes administration non autorisées ;
- données d'une Classe qui ne lui est pas attribuée ou pour laquelle il n'a pas une permission temporaire de remplacement.

---

# 7. Navigation canonique

PROPOSITION à appliquer seulement après inspection du routeur réel.

Destinations principales, maximum 4 :

1. `Aujourd'hui`
2. `Classes`
3. `Disponibilités`
4. `Profil`

Ordre identique sur tous les formats.

## 7.1 Mobile

NavigationBar / barre basse Rewayah.

## 7.2 Tablette

NavigationRail.

## 7.3 Desktop

Sidebar persistante.

## 7.4 Destinations non principales

Ne pas ajouter dans la navigation principale :

- Bibliothèque ;
- Coran ;
- Cahier ;
- Revue de Classe ;
- fiche élève ;
- signalement ;
- absence ;
- remplacement ;
- photo publique.

Ces fonctions s'ouvrent depuis leur objet métier.

## 7.5 Retour et déconnexion

- retour visible sur toute page de niveau 2 ;
- déconnexion toujours atteignable via la coquille ou Profil ;
- aucune tâche focalisée ne devient une impasse.

---

# 8. Carte anti-doublon des fonctions

| Fonction | Surface canonique | Route / conteneur | Entrée |
|---|---|---|---|
| Comprendre la journée | ENS-02 | `/enseignant/journee` | navigation `Aujourd'hui` |
| Voir toutes mes Classes | ENS-09 | route existante à retrouver, sinon `CONTRAT À CRÉER` | navigation `Classes` |
| Voir une Classe | ENS-07 | `/enseignant/groupe/:groupeId` | ENS-09 ou ENS-02 |
| Préparer la prochaine séance | ENS-07, bloc contextuel | même Classe | carte prochaine séance |
| Préflight matériel | surface de `02_CLASSE_ET_VISIO` | contrat existant | CTA d'entrée |
| Entrer en séance | ENS-03 | `/salle` | flux exact de `02_CLASSE_ET_VISIO` |
| Voir le roster | ENS-07 hors séance, ENS-03 en séance | panneau / sheet | Classe ou salle |
| Voir un élève | ENS-11 | sheet / panneau contextuel unique | roster |
| Faire réciter | ENS-11 en contexte Live | action contextuelle | fiche élève |
| Appeler discrètement | ENS-11 en contexte Live | action contextuelle | fiche élève |
| Ouvrir une ressource | sélecteur Bibliothèque partagé | panneau / sheet | Classe ou Teaching Dock |
| Reprendre le support | ENS-07 | action contextuelle | Classe |
| Signaler un besoin | ENS-12 | sheet / dialog court | fiche élève |
| Finaliser la séance | ENS-04 | `/enseignant/seance/:seanceId/cahier` | sortie de salle / À terminer |
| Corriger une présence | ENS-04 | panneau intégré | ligne élève |
| Fixer le travail | ENS-04 | bloc Travail | préremplissage |
| Voir la santé pédagogique | ENS-08 | route existante de revue | Classe, uniquement si utile |
| Déclarer une absence | ENS-13 | sheet liée à une occurrence | séance planifiée |
| Voir le remplacement | ENS-13 | même objet occurrence | `Aujourd'hui` / Classe |
| Déclarer mes disponibilités | ENS-06 | `/enseignant/creneaux` conservé si pertinent | navigation |
| Voir les Classes compatibles | ENS-06 | même destination | disponibilités |
| Se positionner sur une Classe | ENS-06B | détail / confirmation | carte d'offre |
| Modifier ma photo publique | ENS-05A | sous-flux Profil | ENS-05 |
| Modifier profil professionnel | ENS-05 | `/enseignant/profil` | navigation |
| Réglages communs | écran commun existant | `/compte/reglages` | ENS-05 |

Aucune fonction ne doit être reconstruite ailleurs.

---

# 9. Parcours de bout en bout

## P-ENS-01 - Dossier validé vers espace Enseignant

1. `03_ADMIN_VALIDATION_DOSSIERS` obtient un état serveur réellement actif.
2. Le routeur relit les capacités du compte.
3. Si les premiers pas obligatoires ne sont pas terminés, ouvrir ENS-01.
4. Sinon ouvrir ENS-02.
5. Aucun état local ne simule une activation.
6. Aucun enseignant refusé, suspendu ou incomplet ne contourne la porte.

## P-ENS-02 - Premiers pas sans bureaucratie

1. ENS-01 affiche uniquement les éléments réellement manquants.
2. La photo publique professionnelle est distincte du KYC.
3. Langues et fuseau utilisent les valeurs serveur.
4. L'enseignant déclare ses disponibilités dans ENS-06.
5. Les Classes compatibles deviennent consultables.
6. Une action déjà confirmée par le serveur n'est jamais redemandée.
7. Une fois les prérequis complétés, ENS-01 disparaît du parcours quotidien.

## P-ENS-03 - Comprendre sa journée

1. Ouvrir ENS-02.
2. La prochaine séance est dominante.
3. Le CTA reflète l'état réel :
   - préparer ;
   - entrer selon `02` ;
   - reconnecter selon `02` ;
   - finaliser le cahier ;
   - voir la Classe.
4. Les autres séances sont affichées dans la chronologie.
5. Les cahiers en attente apparaissent dans `À terminer`.
6. Les alertes n'existent que si une action humaine est nécessaire.

## P-ENS-04 - Préparer une séance

1. Ouvrir la Classe.
2. Lire l'objectif commun.
3. Voir le support et la position de reprise proposés.
4. Voir uniquement les élèves nécessitant une attention particulière.
5. Ouvrir un élève si nécessaire.
6. Ouvrir ou télécharger le support si nécessaire.
7. Entrer dans le préflight de `02`.
8. Aucun formulaire de préparation obligatoire.

## P-ENS-05 - Entrer en séance

1. Utiliser l'état serveur de fenêtre d'accès.
2. Préflight de `02`.
3. Micro et caméra non publiés par défaut.
4. Résoudre seulement les blocages réels.
5. Obtenir token court et permissions serveur.
6. Connecter la salle unique.
7. Restaurer support et contexte.
8. Ne jamais créer une seconde room ou seconde route de classe Live.

## P-ENS-06 - Enseigner

1. Support dominant.
2. Roster secondaire.
3. File de récitation visible sans masquer le support.
4. Ouvrir ENS-11 sans quitter LiveKit.
5. Changer d'élève actif sans changer le support ni la position.
6. Ouvrir la Bibliothèque comme panneau / sheet.
7. Choisir une ressource remplace le support actif sans couper la salle.
8. Teaching Dock contrôle focus, marqueur, masquage, annotation, pointeur, stylet selon les capacités réelles.
9. L'élève suit l'état partagé lorsque l'enseignant dirige la présentation.
10. Une navigation Rewayah ne coupe pas volontairement la room.

## P-ENS-07 - Connexion instable

1. LiveKit émet un état de reconnexion.
2. L'UI affiche un statut non alarmiste.
3. Le support local et la position restent visibles si possible.
4. La présence académique ne devient pas automatiquement une absence.
5. Après reconnexion, restaurer l'état partagé autoritatif.
6. Ne pas dupliquer les événements de présence.
7. Si la reconnexion échoue, afficher l'action de reprise de `02`.

## P-ENS-08 - Observer un tuteur présent

1. Le serveur autorise une visite.
2. L'enseignant reçoit une notice discrète.
3. Le cours continue.
4. Aucun dialogue modal.
5. Aucun bouton d'admission.
6. La sortie du tuteur ne déclenche pas de notification perturbatrice.
7. Le quota n'est jamais calculé par l'enseignant.

## P-ENS-09 - Fin de séance vers cahier

1. La salle se termine.
2. Ouvrir ENS-04 avec préremplissage.
3. Présence, durée, support, position, plage présentée et ordre de récitation sont repris si les contrats les garantissent.
4. Par défaut, les élèves sont dans l'état académique normal applicable.
5. L'enseignant modifie uniquement les exceptions.
6. Travail maison proposé.
7. Position de reprise proposée.
8. Valider.
9. Le succès n'apparaît qu'après confirmation serveur.
10. Retour ENS-02.

## P-ENS-10 - Cahier à terminer plus tard

PROPOSITION soumise à contrat serveur :

1. Si un brouillon durable ou une queue offline fiable existe, l'enseignant peut quitter le cahier avec `Terminer plus tard`.
2. ENS-02 affiche le cahier dans `À terminer`.
3. Aucun brouillon local fragile n'est présenté comme enregistré.
4. Sans garantie de persistance, ne pas proposer cette sortie.

## P-ENS-11 - Déclarer une absence

1. Depuis une occurrence future, ouvrir ENS-13.
2. L'absence concerne l'occurrence, pas le contrat permanent de Classe.
3. Confirmer.
4. Le serveur déclenche le workflow de remplacement existant.
5. L'enseignant voit l'état réel : recherche, confirmé, non confirmé, annulé.
6. Le titulaire reste le référent permanent.

## P-ENS-12 - Assurer un remplacement

1. Une offre de remplacement réelle est fournie par le serveur.
2. L'enseignant autorisé l'accepte.
3. Le serveur arbitre la concurrence.
4. La séance temporaire apparaît dans ENS-02 avec l'état `Remplacement`.
5. L'enseignant reçoit le paquet pédagogique strictement nécessaire.
6. Il n'obtient aucune donnée privée familiale.
7. Après séance, son cahier rejoint l'historique de la Classe.
8. L'affectation permanente ne change pas.

## P-ENS-13 - Déclarer des disponibilités et choisir une Classe

1. ENS-06 enregistre les plages de disponibilité.
2. Le serveur calcule les Classes dont l'intégralité du pattern récurrent est compatible.
3. L'enseignant ouvre ENS-06B.
4. Tous les jours et heures de la Classe sont visibles avant action.
5. L'enseignant ne peut pas prendre uniquement lundi et abandonner mercredi.
6. La réservation / candidature est transactionnelle.
7. L'état final vient du serveur.
8. Si une validation admin est requise, afficher `En attente de validation`.
9. Ne jamais afficher `Classe attribuée` avant confirmation.

## P-ENS-14 - Signalement

1. Ouvrir un élève.
2. `Signaler un besoin`.
3. Choisir une catégorie autorisée.
4. Contexte Classe, séance, élève et enseignant prérempli.
5. `Détails internes` et `Résumé partageable` restent séparés.
6. Une note interne ne part jamais automatiquement à la famille.
7. L'administration reçoit l'objet structuré.

---

# 10. ENS-01 - Premiers pas

**Route existante :** `/enseignant/bienvenue`  
**Destination principale :** aucune, flux d'activation  
**Objectif :** rendre l'enseignant assignable sans le forcer à relire ou ressaisir des données déjà validées.

## 10.1 Contenu

Titre :

`Bienvenue dans votre espace enseignant`

Sous-texte :

`Préparez votre espace avant votre première Classe.`

Carte groupée unique `À terminer`, uniquement avec les éléments manquants :

- `Ajouter ma photo professionnelle`
- `Vérifier mes langues d'enseignement`
- `Vérifier mon fuseau horaire`
- `Déclarer mes disponibilités`

Ne pas afficher une tâche déjà confirmée.

## 10.2 CTA principal

Le CTA dépend du premier prérequis manquant.

Exemples de libellés exacts autorisés par état :

- `Ajouter ma photo`
- `Vérifier mes informations`
- `Déclarer mes disponibilités`
- `Voir ma journée`

Ne jamais afficher quatre boutons pleins simultanément.

## 10.3 États

- chargement ;
- dossier actif, premiers pas incomplets ;
- tout est complet ;
- photo manquante ;
- informations professionnelles incomplètes ;
- fuseau manquant ;
- disponibilités manquantes ;
- service temporairement indisponible ;
- hors ligne ;
- permission refusée ;
- compte suspendu après chargement.

## 10.4 Interdictions

- aucun ancien texte `L'académie vous confie des élèves sur ces heures` ;
- aucun matching individuel ;
- aucune demande de KYC supplémentaire ;
- aucune copie du contrat signé ;
- aucune photo d'identité utilisée comme photo publique.

## 10.5 Responsive

Mobile : une colonne, progression légère, une action dominante.

Desktop : carte centrale de largeur limitée, aucune grande grille administrative.

## 10.6 Critères d'acceptation

- Étant donné une photo déjà confirmée, quand ENS-01 charge, alors la tâche photo n'apparaît pas.
- Étant donné tous les prérequis satisfaits, quand l'enseignant revient, alors ENS-01 ne bloque pas ENS-02.
- Étant donné un état serveur suspendu, quand la page charge, alors aucun accès actif n'est simulé.

---

# 11. ENS-02 - Aujourd'hui

**Route existante :** `/enseignant/journee`  
**Nom visible proposé :** `Aujourd'hui`  
**Destination active :** Aujourd'hui  
**Objectif :** montrer immédiatement la prochaine action utile de l'enseignant.

## 11.1 Ordre des blocs

1. titre `Aujourd'hui` ;
2. carte dominante `Prochaine séance` ;
3. `Ma journée` ;
4. `À terminer`, seulement si non vide ;
5. `Alertes utiles`, seulement si non vide.

## 11.2 Carte Prochaine séance

Données :

- nom de Classe ;
- parcours / niveau humain ;
- langue ;
- heure locale enseignant ;
- heure de référence de Classe si différente ;
- durée ;
- décompte serveur ;
- état de salle ;
- support / position de reprise si autorisé ;
- nombre d'élèves prévu ;
- éventuel statut `Remplacement`.

CTA contextuel :

- avant fenêtre d'entrée : `Préparer la séance`
- fenêtre ouverte : utiliser exactement le CTA de `02_CLASSE_ET_VISIO.md`
- reconnexion : utiliser exactement le CTA de `02`
- séance terminée et cahier requis : `Finaliser le cahier`
- aucun autre besoin : `Voir la Classe`

## 11.3 Ma journée

Chronologie ordonnée.

Chaque ligne :

- heure ;
- Classe ;
- durée ;
- état ;
- exception éventuelle.

Ne pas transformer la chronologie en calendrier complexe sur mobile.

## 11.4 À terminer

Maximum 3 éléments visibles.

Types :

- cahier non finalisé ;
- correction explicitement demandée ;
- action serveur requise.

Lien :

`Voir tout`

uniquement si une vraie destination existe.

## 11.5 Alertes utiles

Afficher seulement une anomalie actionnable :

- changement DST ;
- séance reportée ;
- remplacement ;
- problème de ressource ;
- information administrative exigeant une action.

Ne pas afficher les succès normaux.

## 11.6 États

- journée avec prochaine séance ;
- aucune séance aujourd'hui ;
- séance future ;
- fenêtre d'entrée ouverte ;
- enseignant déjà connecté ;
- reconnexion ;
- séance prolongée ;
- séance terminée ;
- cahier en attente ;
- remplacement ;
- annulation ;
- report ;
- changement de fuseau ;
- chargement ;
- rafraîchissement ;
- hors ligne avec données en cache ;
- erreur ;
- permission retirée.

## 11.7 Textes

Vide :

`Aucune séance prévue aujourd'hui.`

Aide :

`Vos prochaines Classes restent accessibles dans Classes.`

Erreur :

`Impossible de charger votre journée.`

Action :

`Réessayer`

Hors ligne :

`Vous êtes hors ligne. Les informations affichées peuvent ne pas être à jour.`

## 11.8 Desktop

Composition en deux colonnes :

- contenu principal : prochaine séance + chronologie ;
- colonne secondaire : à terminer + alertes.

La prochaine séance reste visuellement dominante.

## 11.9 Critères d'acceptation

- Étant donné une séance dans la fenêtre serveur, quand ENS-02 charge, alors le CTA d'entrée de `02` est disponible.
- Étant donné aucune anomalie, alors la section `Alertes utiles` n'est pas rendue.
- Étant donné un cahier non finalisé, alors il est atteignable sans chercher dans une autre section.
- Étant donné un changement DST réel, alors les deux heures utiles sont explicites.

---

# 12. ENS-09 - Mes Classes

**Route :** rechercher un équivalent réel avant de créer une nouvelle route.  
**Nom visible :** `Classes`  
**Destination active :** Classes  
**Objectif :** retrouver immédiatement une Classe permanente.

## 12.1 Carte Classe

Une carte n'est pas un mini-dashboard.

Afficher :

- nom de Classe ;
- parcours / niveau ;
- langue ;
- rythme récurrent condensé ;
- prochaine séance ;
- heure locale ;
- effectif réel ;
- état de Classe ;
- anomalie uniquement si action nécessaire.

Toute la carte ouvre ENS-07.

## 12.2 Tri

Par défaut :

1. Classe avec séance la plus proche ;
2. autres Classes actives ;
3. Classes sans prochaine occurrence seulement si elles restent pertinentes.

Le serveur fournit les données et l'ordre métier lorsqu'il existe.

## 12.3 États

- plusieurs Classes ;
- une Classe ;
- aucune Classe attribuée ;
- Classe en attente d'activation ;
- Classe suspendue ;
- prochaine séance modifiée ;
- remplacement temporaire ;
- chargement ;
- hors ligne ;
- erreur ;
- permission retirée.

## 12.4 Vide

Titre :

`Aucune Classe attribuée`

Texte :

`Les Classes confirmées apparaîtront ici.`

Action éventuelle :

`Voir les Classes disponibles`

uniquement si ENS-06 est réellement disponible.

---

# 13. ENS-07 - Espace Classe

**Route existante :** `/enseignant/groupe/:groupeId`  
**Nom visible :** nom de la Classe  
**Destination active :** Classes  
**Objectif :** réunir tout ce qui est utile avant et entre les séances sans devenir un tableau administratif.

## 13.1 Mobile, ordre vertical

1. identité de Classe ;
2. prochaine séance ;
3. `Préparer la séance` ;
4. roster pédagogique ;
5. ressources récentes ;
6. progression / anomalie utile.

## 13.2 Prochaine séance

Même machine de temps que ENS-02.

Aucune duplication d'état calculé côté widget.

## 13.3 Préparer la séance

Afficher :

- `Objectif de la séance`
- `Reprendre`
- support ;
- position / plage ;
- jusqu'à 3 alertes pédagogiques individuelles.

Action :

`Reprendre le support`

si une position réelle existe.

Aucun formulaire obligatoire.

## 13.4 Roster pédagogique

Chaque ligne peut montrer :

- prénom ;
- identifiant Académie ;
- niveau humain ;
- objectif actuel ;
- indicateur de préparation ;
- présence récente résumée ;
- état Live quand la séance est active.

Toute la ligne ouvre ENS-11.

## 13.5 Ressources récentes

Maximum 3 couvertures.

Actions :

- ouvrir ;
- voir les ressources de cette Classe.

La Bibliothèque complète appartient à sa verticale, le composant ici n'en crée pas une copie.

## 13.6 Progression utile

Afficher la santé de cohorte de manière lisible :

- étape commune ;
- prochain gate ;
- renforcement commun si serveur le signale ;
- élèves hors corridor sous forme d'anomalies actionnables.

Ne jamais afficher un classement des élèves.

## 13.7 États

- Classe normale ;
- séance proche ;
- salle ouverte ;
- séance en direct ;
- séance prolongée ;
- cahier précédent à terminer ;
- aucun support ;
- aucune ressource ;
- roster vide ;
- élève temporairement indisponible ;
- gate proche ;
- consolidation requise ;
- anomalie de cohorte ;
- annulation ;
- report ;
- remplacement ;
- chargement ;
- hors ligne ;
- erreur ;
- permission retirée.

## 13.8 Desktop

Trois zones maximum :

- navigation globale ;
- contenu Classe principal ;
- contexte pédagogique secondaire.

Pas de cinq onglets internes sur mobile.

## 13.9 Critères d'acceptation

- Étant donné une position de reprise, quand la Classe ouvre, alors `Reprendre le support` restaure la position sans chercher dans la Bibliothèque.
- Étant donné un élève, quand sa ligne est activée, alors ENS-11 s'ouvre sans exposer les coordonnées familiales.
- Étant donné une salle active, quand l'enseignant ouvre une ressource autorisée, alors LiveKit n'est pas volontairement déconnecté.

---

# 14. ENS-11 - Fiche pédagogique élève

**Conteneur :** panneau latéral desktop/tablette, sheet mobile.  
**Route dédiée :** aucune par défaut.  
**Objectif :** donner au professeur une forte connaissance pédagogique et une faible connaissance privée.

## 14.1 Données autorisées

Projection minimale :

- prénom ;
- identifiant Académie ;
- niveau ;
- parcours ;
- unité actuelle ;
- objectifs actifs ;
- dernière séance ;
- position de reprise ;
- assiduité récente ;
- travail actuel ;
- notes pédagogiques autorisées ;
- état Live.

## 14.2 Données interdites

- téléphone ;
- e-mail ;
- adresse ;
- nom complet du tuteur si non nécessaire ;
- paiement ;
- KYC ;
- appareil privé ;
- géolocalisation ;
- autres enfants du foyer.

## 14.3 Actions contextuelles

En séance :

- `Faire réciter`
- `Appeler discrètement`
- `Noter`
- `Signaler un besoin`

Hors séance :

- les actions Live n'apparaissent pas ;
- `Signaler un besoin` reste possible si autorisé ;
- consultation de la progression reste possible.

## 14.4 Appeler discrètement

Comportement :

- action ciblée ;
- signal léger côté élève ;
- aucune ouverture distante du micro ;
- pas de boucle de confirmation ;
- message seulement en cas d'échec ;
- cooldown serveur / transport si prévu.

Texte élève :

`Le professeur vous appelle`

## 14.5 Faire réciter

- place l'élève comme actif dans la file de récitation ;
- ne change pas le support ;
- ne change pas le focus ;
- ne change pas la position ;
- ne réinitialise pas les annotations.

## 14.6 États

- données complètes ;
- données partielles autorisées ;
- élève en séance ;
- élève déconnecté ;
- élève en reconnexion ;
- aucune note ;
- action indisponible hors Live ;
- appel envoi ;
- appel échoué ;
- permission retirée ;
- chargement ;
- erreur de bloc.

---

# 15. ENS-06 - Disponibilités et Classes disponibles

**Route existante :** `/enseignant/creneaux` à préserver si elle reste canonique.  
**Destination active :** Disponibilités  
**Objectif :** déclarer une disponibilité une fois, puis ne voir que les Classes réellement compatibles.

## 15.1 Suppression obligatoire de l'ancien modèle

Retirer de l'expérience :

- liste `Élèves en attente` ;
- `Prendre {jour} à {heure}` ;
- affectation élève par élève.

## 15.2 Mobile

Bloc 1 :

`Mes disponibilités`

Liste par jour avec plages.

Action secondaire :

`Modifier`

Action primaire contextuelle si rien n'est défini :

`Ajouter mes disponibilités`

Bloc 2 :

`Classes disponibles`

Cartes filtrées par le serveur.

## 15.3 Desktop

Deux colonnes :

- disponibilité hebdomadaire ;
- Classes compatibles.

Ne pas transformer le desktop en version mobile étirée.

## 15.4 Règle de compatibilité

La compatibilité finale appartient au serveur.

Elle doit considérer, selon les contrats réellement existants :

- l'intégralité du pattern récurrent ;
- collisions avec Classes existantes ;
- fuseau ;
- compétences / parcours autorisés ;
- langue ;
- public ;
- limites de charge applicables ;
- statut assignable.

Aucun score opaque côté Flutter.

## 15.5 États Disponibilités

- aucune disponibilité ;
- plages enregistrées ;
- modification en cours ;
- sauvegarde ;
- sauvegarde confirmée ;
- conflit ;
- hors ligne ;
- erreur ;
- permission refusée.

## 15.6 États Classes disponibles

- Classes compatibles ;
- aucune Classe compatible ;
- Classe prise par un autre enseignant ;
- enseignant non éligible ;
- limite de charge atteinte ;
- réservation en cours ;
- réservation confirmée ;
- en attente de validation ;
- refus serveur ;
- liste indisponible ;
- chargement ;
- erreur.

## 15.7 Texte vide

Titre :

`Aucune Classe compatible pour le moment`

Texte :

`Modifiez vos disponibilités si votre emploi du temps a changé.`

Ne jamais promettre qu'une Classe apparaîtra bientôt.

---

# 16. ENS-06B - Détail d'une Classe disponible

**Conteneur :** page mobile, panneau ou page desktop selon architecture réelle.  
**Objectif :** comprendre l'engagement récurrent avant de se positionner.

## 16.1 Données obligatoires

- nom de Classe ;
- parcours ;
- niveau ;
- public ;
- langue ;
- date de début ;
- durée ;
- fuseau de référence ;
- heure locale enseignant ;
- tous les jours récurrents ;
- capacité réelle si utile ;
- charge hebdomadaire ;
- état d'éligibilité.

## 16.2 Règle non négociable

L'enseignant accepte la Classe entière.

Il ne peut pas sélectionner seulement certaines séances normales du pattern.

## 16.3 CTA

`Réserver cette Classe`

Le libellé peut être remplacé par le terme exact du contrat métier si le dépôt utilise candidature plutôt que réservation.

Ne jamais inventer cette sémantique côté UI : Claude doit vérifier le backend.

## 16.4 Confirmation

Titre :

`Confirmer cette Classe ?`

Résumé :

- tous les jours ;
- heures locales ;
- date de début ;
- durée.

Action principale :

`Confirmer`

Action secondaire :

`Annuler`

## 16.5 Succès

Si attribution immédiate réellement confirmée :

`Cette Classe vous est attribuée.`

Si validation humaine requise :

`Votre demande a été transmise.`

Sous-texte :

`Elle apparaîtra dans vos Classes après confirmation.`

Ne jamais confondre les deux.

## 16.6 Nature d'une offre de Classe

La surface `Classes disponibles` ne doit pas transformer une offre de planning en Classe active fictive.

Claude doit retrouver dans le modèle réel la distinction entre :

- pattern / offre précréée ;
- réservation ou candidature enseignant ;
- affectation enseignant confirmée ;
- publication aux familles ;
- inscriptions ;
- Classe active.

Une offre sans enseignant confirmé ne doit pas être présentée aux familles comme une Classe déjà opérationnelle.

Côté enseignant, l'objet peut être visible comme opportunité professionnelle si le serveur le déclare réservable.

L'enseignant voit le pattern complet avant de s'engager.

## 16.7 Politique de charge et progression professionnelle

Une décision antérieure du chantier Classes V2 prévoit une charge initiale bornée et une progression professionnelle par niveaux.

Claude doit d'abord retrouver la politique active dans les documents et contrats courants avant de l'implémenter.

Si cette politique est toujours active, elle est représentée comme une politique serveur versionnée, jamais comme des constantes Flutter.

Décision antérieure à vérifier :

| Niveau professionnel | Charge / privilège annoncé |
|---|---|
| Certifié | jusqu'à 2 Classes |
| Bronze | jusqu'à 3 Classes |
| Argent | jusqu'à 4 Classes |
| Or | jusqu'à 5 Classes |
| Platine | privilèges de mentorat selon politique |

Principes non négociables si le système est conservé :

- promotion validée humainement ;
- aucune rétrogradation automatique silencieuse ;
- fiabilité, préflight, obligations pédagogiques, contrôle qualité et continuité peuvent contribuer à l'éligibilité ;
- la vitesse brute des élèves ne détermine jamais seule un niveau professionnel ;
- un badge éventuel n'est pas utilisé pour classer publiquement les enseignants ;
- un badge n'est pas affiché comme argument marketing sur une offre de Classe sans relation réelle ;
- ENS-06 consomme seulement `current_class_limit`, `current_class_count`, `eligibility_state` et une explication humaine rendues par le serveur.

Texte si limite atteinte :

`Votre charge actuelle ne permet pas de réserver une Classe supplémentaire.`

Action éventuelle uniquement si un workflow réel existe :

`Voir les conditions d'évolution`

Aucune promesse de promotion automatique.

---

# 17. ENS-13 - Absence et remplacement

**Conteneur :** sheet / dialog lié à une occurrence.  
**Objectif :** signaler une impossibilité sans casser le contrat permanent de Classe.

## 17.1 Déclarer une absence

Titre :

`Vous ne pourrez pas assurer cette séance ?`

Résumé :

- Classe ;
- date ;
- heure ;
- durée.

Notice :

`Votre affectation à la Classe reste inchangée.`

CTA :

`Déclarer mon absence`

Action secondaire :

`Annuler`

## 17.2 Après confirmation

États serveur possibles :

- `Absence enregistrée`
- `Recherche d'un remplaçant`
- `Remplaçant confirmé`
- `Aucun remplaçant confirmé`
- `Séance annulée`
- `Demande annulée`

Ne jamais afficher `Remplaçant confirmé` sur la seule base d'un envoi de notification.

## 17.3 Enseignant remplaçant

Sur ENS-02, carte avec libellé :

`Remplacement`

Avant la séance, fournir uniquement :

- objectif ;
- support ;
- position ;
- travail précédent ;
- élèves à surveiller ;
- règles pédagogiques nécessaires.

Aucune coordonnée familiale.

## 17.4 Règle permanente

Le titulaire reste le professeur référent de la Classe.

Le remplacement modifie une occurrence et son historique, pas l'affectation ordinaire.

---

# 18. ENS-03 - Salle enseignant, contrat d'intégration

**Route canonique :** `/salle`  
**Autorité UX et fonctionnelle :** `02_CLASSE_ET_VISIO.md`  
**Objectif de cette section :** empêcher une divergence lorsque `04` est implémenté.

## 18.1 À réutiliser intégralement depuis `02`

- porte d'entrée ;
- préflight ;
- token ;
- permissions ;
- états salle ;
- présence ;
- timer ;
- chrono ;
- réseau ;
- reconnexion ;
- fin de séance ;
- enregistrement ;
- notice permanente ;
- observation ;
- sortie.

## 18.2 Extensions enseignant obligatoires

- support dominant ;
- roster contextuel ;
- ENS-11 ;
- file de récitation ;
- Teaching Dock ;
- sélecteur Bibliothèque ;
- reprise du support ;
- signalement ;
- notice tuteur discrète.

## 18.3 Mobile

- support quasi plein écran ;
- roster en sheet ;
- bouton résumé type `{présents}/{effectif}` seulement si la donnée est fiable ;
- Teaching Dock compact ;
- vidéo en vignette secondaire ;
- aucune toolbar sur le texte coranique.

## 18.4 Tablette / desktop

- support dominant ;
- roster dans panneau secondaire ;
- outils dans zone stable ;
- statut média / réseau / quitter accessible ;
- aucune multiplication de fenêtres.

## 18.5 File de récitation

Afficher :

- élève actif ;
- prochains élèves, liste courte.

Changer l'élève actif ne modifie pas :

- page ;
- position ;
- focus ;
- annotation ;
- support.

## 18.6 Observation tuteur

Notice enseignant :

`Le parent de {prenom} observe la séance.`

Si le lien familial réellement connu est disponible et autorisé, le libellé peut utiliser le terme familial défini par `02`.

Pas de popup.

Pas de bouton accepter / refuser.

## 18.7 Réseau

États visuels sobres :

- connecté ;
- réseau dégradé ;
- reconnexion ;
- reconnecté ;
- déconnecté.

L'audio reste prioritaire lorsque la qualité baisse.

---

# 19. Sélecteur de ressources enseignant

**Propriété fonctionnelle :** verticale Bibliothèque partagée.  
**Point d'entrée :** ENS-07 et Teaching Dock.  
**Objectif :** ouvrir un support sans quitter la Classe.

## 19.1 Ordre

1. `Récents`
2. `Cette Classe`
3. `Tous les supports`
4. recherche

## 19.2 Responsive

- mobile : sheet quasi plein écran ;
- tablette / desktop : panneau latéral.

## 19.3 Règle Live

Choisir une ressource :

- remplace le support actif ;
- conserve LiveKit ;
- publie l'état partagé seulement si l'enseignant possède la capability requise ;
- n'altère pas la source canonique.

## 19.4 États

- chargement ;
- récents ;
- aucune ressource récente ;
- recherche ;
- aucun résultat ;
- ressource indisponible ;
- téléchargée ;
- cache ;
- hors ligne ;
- erreur ;
- permission refusée.

---

# 20. ENS-04 - Cahier de transmission

**Route existante :** `/enseignant/seance/:seanceId/cahier`  
**Objectif :** terminer une séance normale en moins de 45 secondes.

## 20.1 Préremplissage obligatoire si les données existent

- présence ;
- retard ;
- durée ;
- reconnexions utiles ;
- support affiché ;
- position finale ;
- plage de contenu ;
- ordre de récitation ;
- objectif commun ;
- travail précédent ;
- proposition de position de reprise ;
- proposition de travail maison.

## 20.2 Philosophie

Le professeur ne rédige pas le résumé de ce que le système sait déjà.

Il vérifie, puis modifie les exceptions.

## 20.3 Structure mobile

1. titre `Cahier de séance` ;
2. résumé de séance ;
3. élèves ;
4. travail avant la prochaine séance ;
5. position de reprise ;
6. éventuel signalement ;
7. CTA `Valider le cahier`.

## 20.4 Élèves

État par défaut fourni par le curriculum / système.

Actions pédagogiques autorisées selon contexte :

- `Continuer`
- `Renforcer`
- `Suspendre le nouveau`

`Suspendre le nouveau` ne doit être proposé que lorsque la logique académique concernée le permet.

Une exception exige un motif court seulement si le contrat académique ou serveur le demande.

## 20.5 Présence

La présence automatique est affichée.

Action :

`Corriger`

ouvre le panneau existant.

Une correction :

- demande un motif ;
- est auditée ;
- ne réécrit pas silencieusement l'événement brut.

## 20.6 Travail

Maximum 3 actions pour l'élève.

Types déterminés par le contrat académique.

Un travail peut être :

- ajouté ;
- modifié ;
- retiré.

Ne pas transformer le cahier en éditeur de cours.

## 20.7 Validation

CTA :

`Valider le cahier`

Pendant envoi :

`Enregistrement…`

Succès serveur :

`Cahier enregistré`

Puis retour automatique ou CTA :

`Retour à ma journée`

Ne jamais afficher un succès si la donnée est seulement en file locale.

## 20.8 Hors ligne

Si une queue conciliable existe :

Statut :

`En attente d'envoi`

Texte :

`Le cahier sera envoyé lorsque la connexion reviendra.`

Il reste visible dans ENS-02 tant que le serveur n'a pas confirmé.

## 20.9 États

- prérempli complet ;
- prérempli partiel ;
- aucune exception ;
- une exception ;
- plusieurs exceptions ;
- correction de présence ;
- travail proposé ;
- aucun travail ;
- position de reprise ;
- sauvegarde ;
- succès ;
- conflit de version ;
- hors ligne avec queue ;
- hors ligne sans queue ;
- erreur ;
- permission expirée ;
- séance déjà finalisée ailleurs.

## 20.10 Critères d'acceptation

- Étant donné une séance normale, quand le cahier charge, alors aucune présence n'est à saisir manuellement.
- Étant donné aucun changement, quand l'enseignant vérifie puis valide, alors aucune zone narrative obligatoire n'existe.
- Étant donné une correction de présence, alors un motif et une trace d'audit sont nécessaires.
- Étant donné une sauvegarde locale non synchronisée, alors l'écran n'affiche jamais `Cahier enregistré`.

---

# 21. ENS-08 - Revue pédagogique de Classe

**Route existante :** `/enseignant/groupe/:groupeId/revue`  
**Objectif :** intervenir uniquement lorsque la cohorte ou un gate exige une décision pédagogique.

## 21.1 Ne pas afficher au quotidien

Cette surface s'ouvre depuis :

- une anomalie réelle ;
- un gate proche ;
- une revue mensuelle / cycle ;
- une action explicite depuis ENS-07.

## 21.2 Contenu

- étape de Classe ;
- prochain gate ;
- santé de cohorte ;
- élèves hors corridor ;
- consolidation commune recommandée ;
- progression individuelle utile ;
- décisions proposées.

## 21.3 Règles académiques

Le professeur peut :

- renforcer ;
- ajuster la quantité ;
- suspendre le nouveau ;
- recommander un transfert ;
- recommander une réorientation ;
- motiver brièvement une exception.

Il ne peut pas :

- sauter un gate obligatoire ;
- modifier le standard final ;
- promouvoir sur pression familiale ;
- créer un curriculum parallèle ;
- certifier sans l'autorité prévue.

## 21.4 Seuils

Les seuils proviennent du curriculum versionné.

Ne jamais coder `40 %`, `4/5`, `5/6` directement dans le widget même si le référentiel actuel les décrit.

## 21.5 États

- aucun sujet à revoir ;
- consolidation recommandée ;
- élève hors corridor ;
- gate proche ;
- transfert à proposer ;
- réorientation à proposer ;
- donnée académique incomplète ;
- chargement ;
- erreur ;
- permission refusée.

---

# 22. ENS-12 - Signaler un besoin

**Conteneur :** sheet / dialog court.  
**Entrée :** ENS-11.  
**Objectif :** remonter un problème sans recopier le contexte.

## 22.1 Catégories

Utiliser uniquement les catégories réellement supportées.

Cible actuelle du Teaching Core :

- `Problème pédagogique`
- `Présence`
- `Technique`
- `Changement`
- `Autre`

## 22.2 Prérempli

- enseignant ;
- Classe ;
- séance si applicable ;
- élève ;
- timestamp ;
- contexte technique si autorisé.

## 22.3 Champs

`Détails internes`

et, si l'enseignant est autorisé à le rédiger :

`Résumé partageable`

Notice :

`Les détails internes ne sont pas envoyés automatiquement à la famille.`

## 22.4 CTA

`Envoyer le signalement`

## 22.5 États

- formulaire ;
- envoi ;
- succès ;
- hors ligne ;
- erreur ;
- permission refusée ;
- contexte devenu invalide.

---

# 23. ENS-05 - Profil enseignant

**Route :** `/enseignant/profil`  
**Destination active :** Profil  
**Objectif :** gérer l'identité professionnelle et accéder aux réglages, sans mélanger la journée d'enseignement.

## 23.1 Sections

1. identité professionnelle ;
2. photo publique ;
3. langues d'enseignement ;
4. fuseau ;
5. statut du compte ;
6. capacités / éventuelles limites rendues par le serveur ;
7. niveau professionnel / badge uniquement si la politique active le prévoit ;
8. contrats en lecture ;
9. `Mes réglages` ;
10. déconnexion.

## 23.2 Ne pas dupliquer

- disponibilités restent dans ENS-06 ;
- rémunération appartient à Finance ;
- KYC reste dans le coffre / parcours administratif ;
- paramètres d'appareil communs restent dans `/compte/reglages`.

## 23.3 Indicateurs qualité

Si un contrat réel existe, une section sobre peut montrer :

- ponctualité ;
- séances assurées ;
- cahiers à jour ;
- contrôle qualité.

Interdictions :

- classement public ;
- score brut des élèves ;
- comparaison compétitive ;
- note individuelle d'un élève ou tuteur ;
- badge présenté comme une garantie de qualité pédagogique absolue.

Si un niveau professionnel existe, afficher sa conséquence utile, pas une gamification. La source de vérité reste la politique serveur.

## 23.4 États

- profil complet ;
- photo manquante ;
- compte actif ;
- compte non assignable ;
- capacité limitée ;
- données qualité indisponibles ;
- chargement ;
- erreur ;
- hors ligne ;
- suspension.

---

# 24. ENS-05A - Photo publique professionnelle

**Entrée :** ENS-05.  
**Objectif :** fournir la photo visible dans les Classes, distincte des pièces KYC.

## 24.1 Textes

Titre :

`Photo professionnelle`

Aide :

`Cette photo peut être visible par les élèves et les familles de vos Classes.`

Notice :

`N'utilisez pas votre pièce d'identité.`

Action :

`Choisir une photo`

Après sélection :

`Utiliser cette photo`

Modifier :

`Remplacer la photo`

## 24.2 Règles

- stockage et autorisation séparés du coffre KYC ;
- aucune URL R2 brute dans Flutter ;
- aucune réutilisation automatique de la pièce d'identité ;
- aucun traitement biométrique inventé ;
- si une validation humaine de photo existe réellement, afficher son état ;
- sinon ne pas inventer d'état `En validation`.

## 24.3 États

- aucune photo ;
- sélection ;
- aperçu ;
- upload ;
- upload échoué ;
- upload confirmé ;
- remplacement ;
- permission refusée ;
- fichier non supporté ;
- taille dépassée selon contrat réel.

---

# 25. Copywriting Enseignant

## 25.1 Registre

- vouvoiement ;
- professionnel ;
- précis ;
- orienté action ;
- vocabulaire pédagogique autorisé ;
- phrases courtes ;
- aucune culpabilisation ;
- aucune sur-notification.

## 25.2 Lexique imposé

Employer :

- `Classe`
- `Séance`
- `Séance en direct`
- `Sayyid`
- `Sayyida`
- `Interface guidée`

Ne pas employer à l'écran :

- `groupe` comme nom produit ;
- `Session` ;
- `Cours en cours` ;
- `matching` ;
- identifiants backend ;
- codes académiques internes.

## 25.3 Dix corrections obligatoires de ton

| À éviter | À afficher |
|---|---|
| Prenez un élève en attente | Voir les Classes disponibles |
| Cours individuel | Classe |
| Cours en cours | Séance en direct |
| Matching | Classes disponibles |
| Rapport obligatoire | Cahier de séance |
| Remplir la présence | Vérifier la présence |
| Votre rapport est incomplet | Ce cahier reste à finaliser |
| Erreur inconnue | Impossible d'enregistrer le cahier. Réessayez. |
| Succès ! | ne rien afficher si le résultat est déjà évident |
| Élève problématique | Élève à renforcer |

---

# 26. Données et contrats serveur

Tous les noms ci-dessous sont des noms cibles. Claude doit mapper les équivalents réels avant toute création.

## 26.1 `TeacherBootstrapVM`

Sortie :

- état compte ;
- premiers pas ;
- photo publique ;
- langues ;
- fuseau ;
- assignable ;
- capacités ;
- limites applicables.

## 26.2 `TeacherTodayVM`

Sortie :

- maintenant serveur ;
- prochaine occurrence ;
- chronologie du jour ;
- états Live ;
- cahiers à terminer ;
- alertes actionnables ;
- notice DST.

## 26.3 `TeacherClassSummaryVM`

Sortie :

- Classe ;
- curriculum ;
- niveau ;
- langue ;
- récurrence ;
- capacité ;
- prochaine occurrence ;
- état ;
- exception.

## 26.4 `TeacherClassHomeVM`

Sortie :

- résumé Classe ;
- séance suivante ;
- objectif ;
- reprise ;
- roster pédagogique ;
- ressources récentes ;
- progression utile ;
- anomalies.

## 26.5 `TeacherStudentProjection`

Respecter strictement la projection de données pédagogiques minimales définie en section 14.

## 26.6 `TeacherAvailabilityVM`

Entrée / sortie :

- fuseau enseignant ;
- jours ;
- plages ;
- version ;
- validation serveur.

## 26.7 `TeacherClassOpportunityVM`

Sortie :

- pattern complet ;
- compatibilité ;
- raisons d'inéligibilité ;
- état de réservation ;
- contraintes visibles.

## 26.8 `reserve_teacher_class`

Contraintes :

- transaction serveur ;
- vérification collisions ;
- pattern complet ;
- statut enseignant ;
- limite de charge ;
- concurrence ;
- réponse autoritative.

## 26.9 `TeacherAbsenceCommand`

Entrée :

- occurrence ;
- version ;
- motif / catégorie uniquement si contrat l'exige.

Sortie :

- absence enregistrée ;
- état de remplacement ;
- nouvelle version occurrence.

## 26.10 `TeacherReplacementOfferVM`

- occurrence ;
- Classe ;
- contexte pédagogique minimal ;
- expiration éventuelle ;
- capacité d'accepter.

## 26.11 `LessonCloseoutVM`

- présence consolidée ;
- durée ;
- support ;
- position ;
- plage ;
- ordre de récitation ;
- objectifs ;
- propositions ;
- exceptions ;
- version.

## 26.12 `TeacherConcernCommand`

- catégorie ;
- contexte prérempli ;
- détails internes ;
- résumé partageable optionnel ;
- règles d'accès.

## 26.13 `TeacherPublicPhoto`

- état ;
- référence stockage sûre ;
- miniature / dérivés si architecture existante ;
- updated_at ;
- éventuelle modération seulement si réellement implémentée.

---

# 27. Sécurité et confidentialité

## 27.1 RLS

Tests minimum :

- enseignant A ne voit pas Classe B ;
- remplaçant voit uniquement l'occurrence et le contexte autorisé ;
- après fin du remplacement, l'accès temporaire cesse ;
- aucune donnée familiale privée dans `TeacherStudentProjection` ;
- un identifiant UI masqué ne remplace jamais une policy.

## 27.2 LiveKit

Token :

- par séance ;
- court ;
- permissionné ;
- publication selon rôle ;
- jamais de secret LiveKit côté Flutter.

## 27.3 R2

- photo publique distincte KYC ;
- ressources distinctes ;
- URLs temporaires / mécanisme autorisé ;
- aucun secret dans logs.

## 27.4 Audit

Tracer au minimum :

- corrections de présence ;
- déclarations d'absence ;
- acceptation de remplacement ;
- modifications pédagogiques sensibles ;
- accès administratifs / contrôleur selon leurs verticales.

---

# 28. Accessibilité

Pour toutes les surfaces :

- cibles Rewayah au moins 48 dp ;
- texte à 200 % sans écrêtage critique ;
- focus clavier visible ;
- focus non masqué par barre Live ou dock ;
- ordre de Tab cohérent ;
- Enter / Space activent les contrôles standards ;
- Escape ferme sheet / dialog lorsque pertinent ;
- état jamais indiqué par couleur seule ;
- contraste AA minimum ;
- lecteur d'écran : nom, rôle, état, valeur ;
- statut dynamique annoncé sans voler le focus ;
- arabe RTL correct dans le contenu arabe ;
- réduction de mouvement respectée ;
- stylet supporté là où le renderer l'autorise, jamais requis.

---

# 29. Responsive et multi-input

## Mobile

Priorité :

- prochaine action ;
- support ;
- roster contextuel ;
- grandes cibles ;
- sheets plutôt que sidebars internes.

## Tablette

Priorité :

- support + contexte ;
- roster disponible sans recouvrir le contenu ;
- stylet ;
- rail de navigation.

## Desktop

Priorité :

- raccourcis ;
- clavier ;
- souris ;
- hover ;
- panneaux persistants raisonnables ;
- pas de mobile étiré.

## Raccourcis, PROPOSITION à valider

Sur salle desktop uniquement et si aucun conflit :

- `M` : bascule micro ;
- `V` : bascule caméra ;
- `R` : roster ;
- `B` : Bibliothèque ;
- `Esc` : ferme la surface contextuelle.

Ne pas implémenter un raccourci global sans vérifier les conflits avec saisie, navigateur et accessibilité.

---

# 30. Ce que l'application doit automatiser

| Donnée / tâche | Automatique | Intervention enseignant |
|---|---|---|
| Présence | oui | seulement ambiguïté / correction |
| Retard | oui | seulement correction |
| Reconnexion | oui | aucune saisie |
| Durée | oui | aucune saisie |
| Objectif commun | curriculum | ajustement autorisé |
| Passage affiché | oui | choix pédagogique |
| Position de reprise | oui | confirmer / ajuster |
| Ordre de récitation | oui si instrumentation fiable | changer l'élève actif |
| Travail proposé | oui | ajuster |
| Rapport | prérempli | exceptions |
| Résumé tuteur | généré selon règle | message personnalisé seulement si utile |
| Écart de cohorte | détecté | jugement humain |
| Gate | planifié | évaluation humaine |
| Transfert | suggéré | recommandation humaine |

---

# 31. Gates de validation multidisciplinaire

Cette section remplace toute validation vague de type `ça semble bon`.

## Gate Produit

PASS si :

- enseignant référent permanent préservé ;
- aucune reprise du matching individuel ;
- Classes récurrentes complètes ;
- absence et remplacement ne changent pas silencieusement le titulaire.

## Gate Pédagogie

PASS si :

- curriculum reste autorité ;
- enseignant garde son jugement dans les marges prévues ;
- aucun automatisme ne certifie, sanctionne ou promeut ;
- le Hifz protège la révision ;
- le groupe n'est pas immobilisé indéfiniment par une seule situation.

## Gate Charge enseignant

PASS si :

- aucune présence manuelle normale ;
- aucune narration hebdomadaire ;
- préparation normale sous 1 minute ;
- cahier normal sous 45 secondes ;
- aucune donnée saisie deux fois ;
- une alerte normale ne demande pas d'action.

## Gate UX/UI

PASS si :

- une tâche dominante par écran ;
- une action pleine principale ;
- cartes groupées en un seul rectangle avec filets internes ;
- mobile, tablette, desktop réellement distincts ;
- aucune impasse ;
- design tokens gelés respectés.

## Gate Realtime

PASS si :

- une seule salle ;
- reconnexion sans doublon ;
- support et room ne sont pas attachés au lifecycle d'une page ;
- Bibliothèque et fiche élève ne coupent pas LiveKit ;
- état de média et état pédagogique restent séparés.

## Gate Sécurité

PASS si :

- aucun contact famille enseignant ;
- aucun KYC enseignant ou élève dans les surfaces pédagogiques ;
- RLS testée ;
- token LiveKit borné ;
- remplacement borné à son périmètre.

## Gate Accessibilité

PASS si :

- 48 dp ;
- 200 % texte ;
- clavier ;
- lecteur d'écran ;
- RTL ;
- focus non masqué ;
- état non porté par couleur seule.

---

# 32. Recette de bout en bout

## R-ENS-01 Activation

Admin valide un enseignant de test, le compte relit l'état serveur, les premiers pas réels s'affichent, puis l'enseignant atteint sa journée.

## R-ENS-02 Photo

L'enseignant ajoute une photo publique, le KYC reste inchangé, la photo apparaît dans une Classe autorisée.

## R-ENS-03 Disponibilités

L'enseignant enregistre des disponibilités, se reconnecte, les mêmes plages reviennent depuis le serveur.

## R-ENS-04 Classe récurrente

Une offre lundi-mercredi-vendredi ne peut pas être acceptée seulement le lundi.

## R-ENS-05 Concurrence

Deux enseignants tentent la même réservation, le serveur produit un seul résultat gagnant selon sa règle et l'autre UI affiche le conflit réel.

## R-ENS-06 Journée

La prochaine séance est immédiatement identifiable, le CTA suit l'état serveur.

## R-ENS-07 Préparation

Objectif, reprise et élèves à surveiller sont visibles sans formulaire.

## R-ENS-08 Préflight

Micro/caméra restent non publiés, seul un vrai blocage demande une action.

## R-ENS-09 Salle

Enseignant et élève entrent dans la même occurrence LiveKit et se voient / s'entendent selon permissions.

## R-ENS-10 Ressource

L'enseignant ouvre la Bibliothèque, choisit un support, la salle reste connectée, l'élève reçoit l'état partagé.

## R-ENS-11 Roster

Ouvrir un élève ne révèle ni téléphone, ni e-mail, ni parent, ni paiement.

## R-ENS-12 Récitation

Changer l'élève actif ne change pas le support.

## R-ENS-13 Réseau

Couper le réseau puis revenir, aucune double présence, contexte restauré.

## R-ENS-14 Observation

Une visite tuteur autorisée affiche une notice discrète à l'enseignant sans popup d'admission.

## R-ENS-15 Cahier normal

Après une séance sans anomalie, le cahier est prérempli et validable sans narration.

## R-ENS-16 Exception

Corriger une présence exige un motif et crée une trace auditée.

## R-ENS-17 Hors ligne

Un cahier mis en queue affiche `En attente d'envoi` jusqu'à confirmation serveur.

## R-ENS-18 Absence

Le titulaire déclare une absence sur une occurrence, la Classe permanente garde le même titulaire.

## R-ENS-19 Remplacement

Un remplaçant confirmé reçoit le contexte pédagogique minimal, assure la séance, renseigne le cahier, puis perd l'accès temporaire approprié.

## R-ENS-20 Fuseau

Tester Europe / Amérique du Nord autour d'un changement DST. Aucune heure n'est dérivée d'un offset fixe.

## R-ENS-21 Responsive

Tester 390, 768, 1440, clair, sombre, clavier et lecteur d'écran.

---

# 33. Tests anti-cauchemar

Le rôle n'est pas terminé tant qu'un test humain ne peut pas répondre `oui` à toutes ces questions :

1. Puis-je savoir en moins de 10 secondes ce que je dois faire maintenant ?
2. Puis-je préparer une séance sans remplir un formulaire ?
3. Puis-je entrer dans la salle sans rouvrir cinq menus ?
4. Puis-je voir l'élève dont j'ai besoin sans voir sa vie privée ?
5. Puis-je changer de support sans quitter la visio ?
6. Puis-je appeler un élève sans lui ouvrir le micro à distance ?
7. Puis-je signaler un problème sans recopier son nom, sa Classe et la séance ?
8. Puis-je finir un cours normal sans écrire un paragraphe ?
9. Puis-je retrouver un cahier non terminé immédiatement ?
10. Puis-je déclarer une absence sans perdre ma Classe ?
11. Puis-je assurer un remplacement sans reconstruire l'historique ?
12. Puis-je travailler au clavier sur desktop ?
13. Puis-je lire l'écran à 200 % de zoom / texte sans perdre les actions critiques ?
14. Une panne réseau me laisse-t-elle comprendre ce qui se passe sans me faire refaire le travail ?

---

# 34. Lotissement recommandé à Claude Code

Ne pas exécuter tous les fichiers en parallèle sans ownership.

## Lot 0 - Audit et mapping

Avant code :

- routes ;
- guards ;
- écrans ENS existants ;
- services ;
- providers ;
- modèles ;
- LiveKit version ;
- contrats de `02` ;
- RLS ;
- tables / RPC ;
- code mort ;
- tests ;
- i18n ;
- design tokens ;
- composants partagés.

Livrable :

`04_ENSEIGNANT_EXISTING_MAPPING.md`

## Lot 1 - Shell, Premiers pas, Profil, photo

Ownership limité aux surfaces concernées.

## Lot 2 - Aujourd'hui, Classes, Espace Classe

Réutiliser les composants Session / Classe existants.

## Lot 3 - Disponibilités et Classes disponibles

Supprimer l'ancien matching UI sans supprimer silencieusement une donnée backend encore utilisée ailleurs.

## Lot 4 - Roster et fiche élève

Projection serveur minimale + sécurité.

## Lot 5 - Raccordement à `02_CLASSE_ET_VISIO`

Aucun nouveau moteur LiveKit.

## Lot 6 - Cahier et signalements

Préremplissage, exceptions, offline honnête.

## Lot 7 - Absence et remplacement

Occurrences, titulariat, permissions temporaires.

## Lot 8 - Revue pédagogique

Brancher uniquement si les contrats académiques existent.

## Lot 9 - QA multi-format et recette

Golden, intégration, RLS, LiveKit, DST, offline, accessibilité.

---

# 35. Checklist avant le premier commit

Claude doit prouver :

- [ ] version de la branche de base ;
- [ ] `02_CLASSE_ET_VISIO.md` actif retrouvé ;
- [ ] `03_ADMIN_VALIDATION_DOSSIERS.md` actif retrouvé ;
- [ ] aucune autre branche / agent ne possède les mêmes fichiers ;
- [ ] état réel des routes ENS-01 à ENS-08 ;
- [ ] route canonique de liste des Classes ;
- [ ] modèle réel de disponibilités ;
- [ ] ancien matching identifié ;
- [ ] contrat réel de réservation / candidature de Classe identifié ;
- [ ] policy réelle de charge enseignant identifiée ;
- [ ] `join_opens_at` réel identifié ;
- [ ] version LiveKit identifiée ;
- [ ] salle unique confirmée ;
- [ ] contrat de préflight confirmé ;
- [ ] contrat de présence confirmé ;
- [ ] contrat de reconnexion confirmé ;
- [ ] contrat de cahier confirmé ;
- [ ] projection élève enseignant vérifiée ;
- [ ] RLS enseignant vérifiée ;
- [ ] stockage photo publique vérifié ;
- [ ] workflow absence / remplacement vérifié ou déclaré absent ;
- [ ] fuseaux IANA et DST vérifiés ;
- [ ] tokens DM Sans / Plus Jakarta Sans confirmés ;
- [ ] composants partagés inventoriés ;
- [ ] textes interdits recherchés dans i18n ;
- [ ] aucune migration distante avant autorisation ;
- [ ] aucun faux succès dans les fixtures production.

---

# 36. Recherche UX que Claude doit revalider au moment d'implémenter

Créer :

`UX_REVIEW_04_ENSEIGNANT.md`

Pour chaque proposition importante :

- décision UX ;
- source officielle consultée ;
- date ;
- règle utile ;
- conséquence Rewayah ;
- conforme / ajusté / non applicable.

Sources minimum :

- Flutter Adaptive & Responsive ;
- Flutter Large Screens ;
- Flutter User Input & Accessibility ;
- Material Design 3 ;
- Apple HIG ;
- WCAG 2.2 ;
- LiveKit Flutter docs correspondant à la version installée ;
- EEF feedback / workload ;
- DfE workload reduction pour les principes de charge.

Les sources externes ne peuvent jamais modifier une permission, une règle académique ou un contrat financier.

---

# 37. Hors périmètre de `04_ENSEIGNANT.md`

Ne pas construire ici :

- finance complète ;
- salaire / payout ;
- comptabilité ;
- leaderboard ;
- notation automatique des élèves ;
- IA qui décide d'une progression ;
- certification automatique ;
- moteur complet Bibliothèque si sa verticale ne l'a pas encore livré ;
- moteur Coran si sa verticale ne l'a pas encore livré ;
- administration complète ;
- portail tuteur ;
- rôle contrôleur ;
- nouvelles règles KYC ;
- messagerie privée directe enseignant-famille ;
- coordonnées familiales ;
- curriculum parallèle ;
- nouveau système WebRTC ;
- seconde salle Live ;
- nouveau routeur global ;
- nouveau thème.

---

# 38. Maquettes à produire pour fermer la verticale

Les visuels existants du Tuteur servent de langage de composition, pas de source métier.

Réutiliser :

- carte de prochaine séance ;
- carte groupée à filets internes ;
- hiérarchie typographique ;
- navigation adaptative ;
- états historiques ;
- light / dark ;
- composition desktop structurée.

Nouvelles maquettes nécessaires :

1. `IMG-ENS-01` Premiers pas, mobile clair ;
2. `IMG-ENS-02` Aujourd'hui, mobile sombre ;
3. `IMG-ENS-02D` Aujourd'hui, desktop clair ;
4. `IMG-ENS-09` Mes Classes, mobile clair ;
5. `IMG-ENS-07` Espace Classe, mobile sombre ;
6. `IMG-ENS-07D` Espace Classe, desktop clair ;
7. `IMG-ENS-11` Fiche élève, mobile sheet ;
8. `IMG-ENS-11D` Fiche élève, desktop side panel ;
9. `IMG-ENS-06` Disponibilités + Classes disponibles, mobile ;
10. `IMG-ENS-06D` Disponibilités + Classes disponibles, desktop ;
11. `IMG-ENS-06B` Détail Classe disponible ;
12. `IMG-ENS-03D` salle enseignant desktop, uniquement comme vue du contrat `02` ;
13. `IMG-ENS-03M` salle enseignant mobile, uniquement comme vue du contrat `02` ;
14. `IMG-ENS-04` Cahier prérempli, mobile ;
15. `IMG-ENS-04D` Cahier prérempli, desktop ;
16. `IMG-ENS-13` Absence / remplacement ;
17. `IMG-ENS-05` Profil enseignant ;
18. `IMG-ENS-05A` Photo publique.

Règles :

- DM Sans titres français ;
- Plus Jakarta Sans autres textes ;
- aucune barre d'état décorative dans la maquette produit ;
- aucun faux nom présenté comme règle ;
- aucun prix fictif ;
- aucun code backend visible ;
- même système visuel que le produit déjà validé ;
- web = vraie composition ordinateur ;
- aucune couleur inventée hors tokens.

---

# 39. Auto-contrôle

## 39.1 Surfaces couvertes

1. ENS-01 Premiers pas
2. ENS-02 Aujourd'hui
3. ENS-09 Mes Classes
4. ENS-07 Espace Classe
5. ENS-11 Fiche pédagogique élève
6. ENS-06 Disponibilités et Classes disponibles
7. ENS-06B Détail Classe disponible
8. ENS-13 Absence et remplacement
9. ENS-03 Raccordement Salle
10. Sélecteur ressources enseignant
11. ENS-04 Cahier
12. ENS-08 Revue pédagogique
13. ENS-12 Signalement
14. ENS-05 Profil
15. ENS-05A Photo publique

## 39.2 Parcours couverts

14 parcours de bout en bout.

## 39.3 Recettes

21 recettes de bout en bout.

## 39.4 Règles contrôlées

- [x] rôle complet, pas seulement dashboard ;
- [x] ancien matching retiré de la cible ;
- [x] enseignant référent permanent ;
- [x] marketplace / réservation de Classe entière ;
- [x] disponibilités ;
- [x] Classes attribuées ;
- [x] préparation ;
- [x] entrée en séance ;
- [x] salle unique ;
- [x] roster ;
- [x] fiche élève ;
- [x] file de récitation ;
- [x] Bibliothèque sans déconnexion ;
- [x] reconnexion ;
- [x] observation ;
- [x] cahier prérempli ;
- [x] travail ;
- [x] progression ;
- [x] signalements ;
- [x] absence ;
- [x] remplacement ;
- [x] photo publique distincte KYC ;
- [x] profil ;
- [x] fuseaux / DST ;
- [x] confidentialité ;
- [x] mobile / tablette / desktop ;
- [x] clair / sombre à produire ;
- [x] clavier / accessibilité ;
- [x] aucune finance avancée dans ce lot ;
- [x] aucune seconde salle ;
- [x] aucune duplication de `02_CLASSE_ET_VISIO` ;
- [x] aucune promesse de succès sans confirmation serveur ;
- [x] objectif anti-burnout explicite ;
- [x] préparation normale sous 1 minute ;
- [x] cahier normal sous 45 secondes ;
- [x] aucun rapport narratif hebdomadaire ;
- [x] une fonction = un emplacement canonique.

---

# 40. Condition de sortie de la verticale

`04_ENSEIGNANT.md` est considéré terminé uniquement lorsqu'un enseignant de test peut :

1. être réellement activé après la validation admin ;
2. compléter ses prérequis professionnels ;
3. déclarer ses disponibilités ;
4. voir et se positionner sur une Classe compatible complète ;
5. retrouver une Classe attribuée ;
6. préparer une séance ;
7. entrer dans la salle unique de `02` ;
8. enseigner avec support, roster et file de récitation ;
9. survivre à une reconnexion ;
10. terminer le cahier sans bureaucratie ;
11. déclarer une absence sur une occurrence ;
12. assurer un remplacement temporaire avec contexte ;
13. retrouver la séance suivante sans perte de progression ;
14. faire tout cela sans accès aux données privées des familles.

Si le parcours est seulement maquetté ou si les écrans ne sont pas branchés par de vrais boutons, le statut reste `NON TERMINÉ`.
