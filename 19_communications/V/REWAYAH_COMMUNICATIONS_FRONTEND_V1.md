# REWAYAH - COMMUNICATIONS FRONTEND V1

**Version :** V1  
**Date :** 4 octobre 2026  
**Statut :** SPEC FRONTEND A EXECUTER APRES INVENTAIRE DU DEPOT  
**Perimetre :** FRONTEND ONLY  
**Agent d'execution :** Claude Code  
**Plateformes :** Flutter Android, iOS, Web/Desktop

## Sources d'autorite

1. Decisions explicites du directeur dans la conversation courante.
2. High-fi Communications V1 produites et corrigees avant cette spec.
3. `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`.
4. `DOSSIER_POUR_CHATGPT.md`.
5. `06_SPEC_FONCTIONNELLE_MVP.md`.
6. Contre-revue frontend du 3 octobre 2026.

> Cette vague est strictement frontend. Aucun changement Supabase, RLS, RPC, migration, stockage, LiveKit, fonction serveur ou politique de retention n'est autorise. Les dependances serveur necessaires sont documentees comme contrats futurs. Le frontend doit rester honnete : aucun succes, droit, envoi, moderation ou synchronisation n'est presente comme reel sans preuve.

---

# 0. DECISION EXECUTIVE

Communications V1 consolide :

1. `COM-01 Notifications`
2. `COM-02 Annonces`
3. `COM-03 Messages metier`
4. `COM-04 Communications contextuelles`
5. `COMMUNAUTE ENSEIGNANTS`
6. `LE STUDIO`

Ces univers sont distincts.

| Univers | Finalite | Public | Regle structurante |
|---|---|---|---|
| Messages metier | Traiter une communication liee a un objet Rewayah reel | familles, eleves adultes, enseignants, equipe autorisee | Aucun chat libre. Chaque fil possede un contexte canonique. |
| Communaute enseignants | Entraide professionnelle et pedagogique | enseignants autorises + moderation | Aucun commerce, aucune publicite, aucun lien affilie, aucune vente. |
| Le Studio | Bureau de travail quotidien de l'equipe interne | equipe interne autorisee | Canaux de travail, Aujourd'hui, activite, recherche, fichiers et mode focus. |

**North Star :** Rewayah ne construit ni WhatsApp, ni Slack, ni un reseau social generaliste. Chaque capacite de communication sert une tache Rewayah identifiable.

---

# 1. AUTORITE ET RECONCILIATION

## 1.1 Ordre d'autorite

Claude applique dans cet ordre :

1. securite, confidentialite et permissions deja prouvees dans le depot ;
2. decisions les plus recentes du directeur ;
3. high-fi Communications V1 pour composition, densite, hierarchie et placement ;
4. presente specification pour comportements, textes, etats et anti-doublon ;
5. Bible Frontend UI/UX V2 ;
6. design tokens et composants partages reels ;
7. documentation officielle Flutter et Material 3 ;
8. jamais une intuition personnelle de l'agent.

## 1.2 High-fi

Les high-fi font foi pour :

- structure ;
- proportion ;
- ordre des zones ;
- densite ;
- relation entre panneaux ;
- position des actions.

Les high-fi ne font pas foi pour :

- une permission non decidee ;
- une route inventee ;
- une valeur metier fictive ;
- une couleur qui contredit les tokens reels ;
- un role errone affiche par l'outil de generation ;
- un libelle genere qui contredit cette spec.

**Correction obligatoire :** lorsqu'une image generee affiche un shell Tuteur dans un ecran Enseignant, Studio ou Admin, Claude garde la composition mais remplace le shell par le shell reel du role. Aucun ecran ne doit recopier aveuglement une erreur de generation.

## 1.3 Design system gele

Obligatoire :

- DM Sans pour les titres ;
- Plus Jakarta Sans pour le reste ;
- palette Rewayah existante ;
- accent lavande existant ;
- light et dark existants ;
- cartes groupees sous forme d'un seul rectangle avec filets internes ;
- aucune nouvelle couleur locale ;
- aucune nouvelle famille de police ;
- aucun rayon ou spacing local arbitraire ;
- aucune duplication d'un composant existant.

---

# 2. FRONTIERE FRONTEND ONLY

Interdit :

- migration ;
- creation de table ;
- modification de policy ;
- creation de RPC ;
- modification LiveKit ;
- politique de retention definitive ;
- moderation serveur presentee comme operationnelle ;
- detection d'affiliation presentee comme garantie serveur ;
- push presente comme reel sans contrat ;
- chargement de donnees privees non fourni par les contrats existants.

Autorise :

- composants Flutter ;
- routes frontend necessaires si aucune route existante ne couvre le besoin ;
- ports abstraits ;
- adapters de demonstration hors production ;
- fixtures de demonstration ;
- etats loading, vide, erreur, indisponible, bloque ;
- responsive ;
- accessibilite ;
- tests widgets, golden tests, navigation, clavier et semantics.

---

# 3. MESSAGES METIER

## 3.1 Principe

Un fil metier est toujours lie a un objet identifiable.

Objets admis dans V1 :

- Classe ;
- eleve ;
- seance si le contrat actuel l'autorise ;
- dossier d'inscription ;
- paiement ou objet financier si le role y a deja acces ;
- mission de controle ;
- demande de remplacement ;
- support ou signalement si un contrat existant le porte.

Il n'existe pas de bouton global `Nouveau message` permettant de choisir n'importe quel utilisateur de Rewayah.

Il n'existe pas d'annuaire public d'utilisateurs.

Il n'existe pas de numero de telephone, adresse e-mail ou autre coordonnee familiale dans le fil.

## 3.2 Paires autorisees V1

| Emetteur | Destinataire | Autorise | Contexte requis |
|---|---|---:|---|
| Tuteur | Enseignant | Oui | Un de ses profils eleves dans une Classe de cet enseignant |
| Enseignant | Tuteur | Oui | Un profil eleve de sa Classe |
| Eleve adulte | Enseignant | Oui | Sa propre Classe |
| Enseignant | Eleve adulte | Oui | Sa propre Classe |
| Tuteur | Administration / equipe autorisee | Oui | Dossier, Classe, acces, finance ou support selon entree canonique |
| Administration / equipe autorisee | Tuteur | Oui | Meme objet |
| Enseignant | Administration / equipe autorisee | Oui | Affectation, Classe, planning, support, dossier professionnel |
| Administration / equipe autorisee | Enseignant | Oui | Meme objet |
| Controleur | Administration | Oui | Mission de controle |
| Enfant en Interface guidee | Communication libre | Non | L'enfant recoit les informations produit autorisees, sans messagerie libre V1 |
| Enseignant | Enseignant via DM communautaire | Non dans V1 | Utiliser la Communaute ou Le Studio si l'utilisateur appartient a l'equipe interne |
| Famille A | Famille B | Non | Jamais |
| Eleve | Eleve | Non dans V1 | Jamais |

Toute extension exige une nouvelle decision produit.

---

# 4. COMMUNAUTE ENSEIGNANTS

## 4.1 Finalite

La Communaute enseignants est un espace d'entraide professionnelle et pedagogique.

Elle accepte :

- questions pedagogiques ;
- retours d'experience ;
- methodes d'enseignement ;
- organisation de Classe ;
- ressources pedagogiques non commerciales ;
- documents internes ou gratuits autorises ;
- discussions sur des pratiques utiles a l'enseignement.

Elle interdit :

- publicite ;
- vente ;
- lien affilie ;
- code de reduction personnel ;
- code de parrainage ;
- lien de parrainage ;
- catalogue commercial ;
- offre de service personnelle ;
- promotion d'un cours payant externe ;
- recherche de clients ;
- collecte de prospects ;
- publication sponsorisee ;
- demande de contact prive dans un but commercial ;
- revente de livres, materiel, fichiers ou formations ;
- demande de paiement entre membres ;
- financement participatif personnel ;
- promotion repetitive d'une marque ;
- publication d'un produit uniquement pour generer du trafic ou des ventes.

Un enseignant peut citer un outil ou un produit lorsqu'il est necessaire a une explication pedagogique, mais :

- pas de lien d'achat ;
- pas de prix promotionnel ;
- pas de code ;
- pas de remuneration ;
- pas d'appel a acheter ;
- pas de message `contactez-moi pour commander`.

## 4.2 Pas de DM communautaire

Aucun bouton `Message prive` depuis le profil communautaire dans V1.

Objectif : eviter solicitation, promotion commerciale, contournement de la moderation et multiplication des canaux de communication.

---

# 5. POLITIQUE ANTI-PROMOTION

## 5.1 Composant canonique

Nom : `CommunityPromotionGuard`

Responsabilites :

- rappeler la politique ;
- afficher un blocage lorsqu'un contenu enfreint clairement la regle ;
- transmettre un motif de signalement a l'etat de demonstration ;
- rendre visible la difference entre contenu autorise et contenu commercial ;
- ne jamais pretendre effectuer une detection serveur reelle si elle n'existe pas.

## 5.2 Etats UI

| Etat | UI | Texte exact |
|---|---|---|
| Normal | bandeau discret | `Partage pedagogique uniquement` |
| Aide | panneau explicatif | `Aucune publicite. Aucun lien affilie. Aucune vente.` |
| Potentiellement commercial | warning composer | `Cette publication semble contenir une promotion commerciale. Retirez le lien, le code ou l'offre avant de publier.` |
| Lien affilie | blocage | `Les liens affilies ne sont pas autorises dans la Communaute enseignants.` |
| Vente | blocage | `La vente de produits ou de services n'est pas autorisee dans cet espace.` |
| Publication signalee | confirmation apres retour reel | ~~`Le contenu a ete signale a l'equipe de moderation.`~~ `Le contenu a été signalé. Il sera examiné.` (amendé le 05/10) |
| Moderation indisponible | erreur | ~~`Le signalement n'a pas pu etre envoye. Reessayez.`~~ `Le signalement n'a pas encore été confirmé. Réessayez dans un instant.` (amendé le 05/10) |

> **Amendement du 05/10/2026 (D-FUS-2 = option 1), décidé par délégation du directeur** (artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW). Les deux textes barrés contredisaient la règle K-59 et D5 (un échec réseau se dit « non confirmé », jamais « non envoyé » : l'application ne peut pas prouver que rien n'est parti) et le contrôle `affirmation-reseau` de `verifier_revue`. La spec suit désormais les textes du code (`com.socle.signalement.confirme`, `com.socle.signalement.erreur`) ; quand le service de modération est absent, le texte est « Le signalement n'est pas encore disponible ici. » (`com.socle.signalement.indisponible`). Voir `19_communications/DECISIONS_COM_FUS.md`, D-FUS-2.

## 5.3 Composer communautaire

Ne comporte pas :

- champ prix ;
- bouton produit ;
- bouton boutique ;
- bouton lien affilie ;
- bouton `Promouvoir` ;
- bouton `Sponsoriser` ;
- bouton `Contacter en prive` ;
- CTA commercial.

Comporte :

- texte ;
- categorie ;
- piece jointe autorisee ;
- publication.

## 5.4 Liens externes

Le frontend sait representer quatre etats :

- lien interne Rewayah ;
- ressource pedagogique externe ;
- lien commercial interdit ;
- lien non verifie.

Tant qu'aucun contrat serveur n'existe, la production ne doit pas afficher `Verifie` sur la seule base du client.

## 5.5 Moderation

Motifs V1 :

1. Publicite
2. Lien affilie
3. Vente non autorisee
4. Sollicitation commerciale
5. Contenu sans rapport avec la communaute
6. Harcelement ou langage inapproprie
7. Donnees personnelles d'un eleve ou d'une famille
8. Autre contenu a examiner

Actions visibles uniquement avec capability :

- masquer ;
- restaurer ;
- rejeter ;
- approuver apres examen ;
- ouvrir le contexte ;
- consulter l'auteur selon les droits existants.

Aucune sanction automatique de compte n'est definie dans cette spec frontend.

---

# 6. LE STUDIO

## 6.1 Definition

Le Studio est le bureau de travail quotidien de l'equipe interne Rewayah.

Profils eligibles selon permissions existantes :

- direction ;
- administration ;
- finance / comptabilite ;
- controle ;
- produit / technique ;
- pedagogie interne ;
- support interne ;
- collaborateurs internes explicitement autorises.

Un enseignant ordinaire n'entre pas automatiquement dans Le Studio.

Un enseignant qui doit contacter l'administration utilise Messages metier.

## 6.2 Liens commerciaux dans Le Studio

Les liens vers fournisseurs et outils lies a une tache professionnelle peuvent etre autorises selon permissions.

Restent interdits :

- liens affilies personnels ;
- codes de parrainage personnels ;
- vente personnelle ;
- sollicitation commerciale des collegues ;
- promotion repetee sans besoin operationnel.

## 6.3 North Star

Le Studio doit permettre a l'equipe de passer plusieurs heures par jour dans Rewayah sans surcharge cognitive.

Priorites :

1. savoir ce qui merite une action ;
2. retrouver rapidement une conversation ;
3. travailler dans le bon contexte ;
4. ne pas perdre un brouillon ;
5. retrouver fichiers et decisions ;
6. se concentrer sans chrome inutile ;
7. sortir vers le module canonique lorsqu'une tache appartient a un autre domaine.

---

# 7. LE STUDIO - AUJOURD'HUI

Composant : `StudioTodayBoard`

Identifiants : `COM-W00` desktop, `COM-M04` mobile.

Blocs :

1. A traiter aujourd'hui
2. Mentions et reponses
3. Decisions en attente
4. Echeances proches
5. Activite recente
6. Brouillons
7. Acces rapides

## Regle anti-doublon

- une ligne Finance ouvre Finance ;
- une ligne Planning ouvre Planning ;
- une ligne dossier ouvre le dossier ;
- une ligne Classe ouvre la Classe ;
- une action d'admission ouvre Admissions ;
- `Aujourd'hui` ne reimplemente aucune action metier complexe.

`Aujourd'hui` est un agregateur d'attention, pas un deuxieme centre operationnel.

---

# 8. ACTIVITY INBOX, BROUILLONS ET ELEMENTS ENREGISTRES

## 8.1 `ActivityInbox`

Types :

- message non lu ;
- mention ;
- reponse ;
- annonce importante ;
- decision demandee ;
- fichier partage ;
- action Studio locale ;
- changement contextuel provenant d'un module canonique.

Chaque item porte :

- type ;
- source ;
- auteur si autorise ;
- heure/date ;
- libelle court ;
- niveau d'attention ;
- destination ;
- etat lu/non lu ;
- etat action requise si pertinent.

## 8.2 `DraftPersistence`

Le brouillon doit survivre a la navigation locale.

Pour cette vague :

- adapter demo autorise ;
- memoire de session autorisee ;
- stockage local seulement si la couche existante est deja approuvee pour ce type de donnee.

Ne pas promettre synchronisation multi-appareil sans contrat serveur.

## 8.3 `SavedForLater`

Un message, une publication communautaire ou un element Studio peut etre marque `Enregistrer`.

Le raccourci conserve une reference vers l'objet canonique, pas une copie metier concurrente.

---

# 9. CANAUX DU STUDIO

## 9.1 Taxonomie cible

- Organisation
- Admissions & familles
- Pedagogie & qualite
- Planning & remplacements
- Finance
- Support
- Produit & technique
- Direction

Cette taxonomie sert la demo frontend. Elle ne cree aucune donnee serveur.

## 9.2 Visibilite

Composant : `StudioChannelVisibility`

Etats :

- visible ;
- restreint ;
- prive autorise ;
- absent.

**Regle :** un canal non autorise n'est pas rendu. Ne pas afficher une liste de canaux cadenas inutiles.

## 9.3 `StudioSharedAssetsPanel`

Dans un canal Studio :

- Elements epingles
- Fichiers recents
- Liens utiles
- Membres
- A propos
- Parametres du canal si capability

Ne pas transformer ce panneau en Bibliotheque pedagogique.

---

# 10. LE STUDIO - MODE FOCUS

## 10.1 Composants

- `StudioFocusToggle`
- `FocusExitDock`
- `MinimalComposer`
- `FocusStateRestorer`

## 10.2 Entree

Entree depuis un canal Studio.

Libelle : `Mode focus`

Le mode focus :

- est local a l'utilisateur ;
- n'est pas transmis aux autres membres ;
- ne change aucun droit ;
- ne modifie pas le canal ;
- ne passe pas le navigateur en plein ecran.

## 10.3 Ce qui disparait

Desktop :

- navigation principale ;
- liste des canaux ;
- panneau contextuel ;
- recherche globale ;
- cloche ;
- raccourcis ;
- compteurs non essentiels ;
- sections A propos ;
- actions de gestion de canal ;
- boutons de moderation hors contexte immediat ;
- widgets Aujourd'hui ;
- statistiques ;
- filtres secondaires.

Mobile :

- barre basse ;
- navigation secondaire ;
- menus non essentiels ;
- compteurs ;
- panneaux contextuels ;
- recherche.

## 10.4 Ce qui reste

Toujours visible :

- identite minimale `Le Studio` ;
- nom du canal ou contexte ;
- contenu du fil ;
- documents et vocaux du fil ;
- composer minimal ;
- action de sortie ;
- indicateur discret `Focus active` ;
- erreurs reseau ou permissions critiques.

Les reactions deviennent secondaires :

- desktop : visibles au survol ou focus clavier ;
- mobile : accessibles apres interaction explicite.

## 10.5 Sortie et restauration

Sortie par :

- `Quitter le focus` ;
- `Escape` sur desktop si aucun dialogue prioritaire n'est ouvert ;
- retour explicite sur mobile.

Restaurer :

- canal selectionne ;
- position de scroll ;
- brouillon ;
- largeur des panneaux si memorisee localement ;
- panneau droit ouvert/ferme ;
- filtres ;
- recherche locale si active.

Aucune perte de texte saisie n'est acceptable.

## 10.6 Accessibilite du Focus

Le focus applicatif ne doit pas :

- pieger le focus clavier ;
- masquer l'action de sortie au lecteur d'ecran ;
- supprimer les erreurs critiques ;
- supprimer le composer si l'utilisateur peut ecrire ;
- forcer une animation.

Avec reduction de mouvement : transition directe.

---

# 11. MESSAGES VOCAUX

## 11.1 Composant

`VoiceMessageComposer`

Duree maximale V1 : **3 minutes**.

## 11.2 Etats

1. Repos
2. Permission micro requise
3. Permission refusee
4. Enregistrement
5. Pause
6. Reprise
7. Limite proche
8. 3:00 atteint
9. Pre-ecoute
10. Supprimer
11. Envoyer
12. Envoi
13. Echec d'envoi
14. Vocal recu
15. Lecture
16. Pause lecture
17. Fin lecture

## 11.3 Regles

Aucun vocal n'est envoye automatiquement a l'arret.

Apres Stop :

- afficher pre-ecoute ;
- afficher duree ;
- proposer Supprimer ;
- proposer Envoyer.

Permission refusee :

`Le microphone n'est pas autorise pour Rewayah.`

Action : `Ouvrir les reglages` si la plateforme le permet, sinon `Fermer`.

---

# 12. PIECES JOINTES

Le frontend ne hardcode pas une politique de taille ou MIME non prouvee.

Port : `AttachmentPolicyPort`

Etats :

- autorise ;
- trop volumineux ;
- type interdit ;
- en cours ;
- envoye ;
- echec ;
- indisponible.

Afficher :

- nom ;
- type ;
- taille si disponible ;
- etat ;
- ouvrir/telecharger si autorise.

Ne jamais afficher :

- URL R2 brute ;
- chemin interne ;
- token signe ;
- secret ;
- identifiant technique incomprehensible.

---

# 13. NOTIFICATIONS ET ANNONCES

## 13.1 `NotificationCenter`

Filtres :

- Toutes
- Non lues
- Mentions
- Action requise

Niveaux :

| Niveau | Usage | Representation |
|---|---|---|
| Information | changement sans action immediate | neutre |
| A lire | information importante | badge texte |
| Action requise | action attendue | icone + libelle |
| Urgent | impact immediat et rare | accent d'alerte + texte |

La couleur seule n'est jamais suffisante.

## 13.2 Catalogue initial par role

### Tuteur

- annonce de Classe ;
- changement de seance ;
- validation/refus de dossier ;
- message metier ;
- reponse attendue ;
- acces ou finance si contrat existant ;
- observation si politique existante.

### Eleve adulte

- annonce de Classe ;
- changement de seance ;
- message enseignant ;
- travail ou ressource si le module existant emet deja cet evenement.

### Enseignant

- message d'une famille de sa Classe ;
- annonce direction ;
- changement planning ;
- remplacement si contrat existant ;
- mention communautaire ;
- reponse communautaire ;
- message administration.

### Administration

- dossier a traiter ;
- signalement communautaire ;
- reponse a un fil metier autorise ;
- annonce planifiee a publier ;
- evenement operationnel deja fourni par les modules existants.

### Controleur

- mission ;
- changement de mission ;
- reponse administration.

### Equipe Studio

- mention Studio ;
- reponse ;
- decision demandee ;
- element assigne ;
- annonce interne ;
- evenement contextuel autorise.

## 13.3 `ClassAnnouncementCard`

Une annonce de Classe apparait :

- dans l'espace Classe ;
- dans NotificationCenter ;
- eventuellement sur l'accueil si son niveau le justifie.

Elle ne devient pas un fil generaliste.

Actions :

- lire ;
- ouvrir la Classe ;
- ouvrir le detail si le contenu depasse la carte.

## 13.4 Publication

Direction / Administration autorisee :

- annonce globale ;
- annonce par public ;
- annonce par Classe ou ensemble autorise ;
- programmation si capability existante.

Enseignant :

- annonce uniquement a sa Classe ou audience explicitement autorisee ;
- aucune annonce globale.

Tuteur, eleve, controleur :

- aucune publication d'annonce dans V1.

---

# 14. UNE FONCTION = UN ENDROIT

| Fonction | Endroit canonique | Raccourcis autorises |
|---|---|---|
| Liste des fils metier | Messages metier | compteur / notification qui ouvre le fil |
| Lire et repondre | Fil metier | notification, objet lie |
| Publier annonce globale | Administration des communications | raccourci admin existant |
| Publier annonce de Classe | Espace Classe enseignant | raccourci autorise |
| Lire annonce | Espace Classe / NotificationCenter | notification ouvre l'annonce |
| Centre notifications | NotificationCenter partage | cloche des shells |
| Communaute enseignants | destination Enseignant | notification ouvre publication |
| Nouvelle publication | Communaute | un seul composer |
| Moderation | Administration des communications | Signalement ouvre une entree |
| Studio Aujourd'hui | accueil Studio | destination Studio |
| Canal Studio | StudioChannelWorkspace | Aujourd'hui, recherche, notification, mention |
| Fichiers canal | StudioSharedAssetsPanel | panneau contextuel |
| Recherche Studio | etat de recherche Studio | champ Studio |
| Mode focus | etat local canal Studio | bouton Focus |
| Historique messages | liste + fil + activite | aucun ecran separe |
| Regles anti-promotion | politique Communaute + moderation | bannieres uniquement |

Ne pas creer :

- `Messages` et `Messagerie` comme deux destinations ;
- deux centres de notifications ;
- un historique messages separe ;
- une page fichiers Studio concurrente du panneau ;
- une messagerie privee entre enseignants depuis la Communaute ;
- un marketplace ;
- un espace promotions ;
- un moteur de taches generales concurrent aux modules metier.

---

# 15. ARBORESCENCE FONCTIONNELLE

```text
COMMUNICATIONS
|
|-- NotificationCenter
|   |-- Toutes
|   |-- Non lues
|   |-- Mentions
|   |-- Action requise
|   `-- Detail / destination canonique
|
|-- Messages metier
|   |-- Liste fils
|   |-- Recherche
|   |-- Fil contextuel
|   |   |-- texte
|   |   |-- vocal
|   |   |-- piece jointe
|   |   |-- non lu / action requise
|   |   `-- contexte lie
|   `-- Etats indisponibles
|
|-- Communaute enseignants
|   |-- Flux
|   |-- Categories
|   |-- Recherche
|   |-- Publication
|   |-- Fil reponses
|   |-- Enregistrer
|   |-- Signaler
|   |-- Moderation
|   `-- CommunityPromotionGuard
|
`-- Le Studio
    |-- Aujourd'hui
    |   |-- A traiter
    |   |-- Mentions et reponses
    |   |-- Decisions en attente
    |   |-- Echeances proches
    |   |-- Activite recente
    |   `-- Brouillons
    |
    |-- Canaux
    |-- Canal actif
    |   |-- Messages
    |   |-- Vocaux
    |   |-- Pieces jointes
    |   |-- Reponses
    |   |-- Elements epingles
    |   `-- Panneau contextuel
    |
    |-- Recherche
    |-- Elements enregistres
    |-- Brouillons
    `-- Mode focus
```

---

# 16. ECRANS CANONIQUES MOBILE

## COM-M01 - Messages metier

Objectif : lire et repondre a une conversation contextuelle.

Contenu :

- header contextuel ;
- identite autorisee ;
- contexte Classe/eleve ;
- messages ;
- vocal ;
- piece jointe ;
- etat non lu / action requise ;
- composer ;
- retour.

High-fi : `maquette_ui_mobile_rewayah_en_mode_sombre.png`, ecran 1.

## COM-M02 - Communaute enseignants

Objectif : lire, rechercher et publier un contenu pedagogique.

Contenu :

- categories ;
- banner anti-promotion ;
- publications ;
- reponses ;
- enregistrer ;
- signaler ;
- CTA `Nouvelle publication`.

High-fi : `maquette_ui_mobile_rewayah_en_mode_sombre.png`, ecran 2.

## COM-M03 - Le Studio - Canal

Objectif : travailler dans un canal interne.

Contenu :

- canal ;
- messages ;
- vocaux ;
- fichiers ;
- reactions secondaires ;
- composer ;
- bouton Focus.

High-fi : `maquette_ui_mobile_rewayah_en_mode_sombre.png`, ecran 3.

## COM-M04 - Le Studio - Aujourd'hui

Objectif : savoir quoi traiter.

High-fi : `planche_ui_rewayah_studio_d_équipe.png`, ecran 1.

## COM-M05 - Le Studio - Focus

Objectif : travailler sans distraction.

High-fi : `planche_ui_rewayah_studio_d_équipe.png`, ecran 2.

## COM-M06 - Notifications et annonce

Objectif : trier les notifications et lire une annonce.

High-fi : `planche_ui_rewayah_studio_d_équipe.png`, ecran 3.

---

# 17. ECRANS CANONIQUES DESKTOP

## COM-W00 - Le Studio - Aujourd'hui

High-fi : `tableau_de_bord_rewayah_pastel.png`

Disposition :

- shell interne ;
- indicateurs d'attention ;
- trois colonnes fonctionnelles ;
- Aujourd'hui ;
- Activite recente ;
- Decisions ;
- Brouillons ;
- Acces rapides.

## COM-W01 - Messages metier

High-fi : `interface_de_messagerie_rewayah_en_français.png`

Disposition :

- navigation role a gauche ;
- liste fils ;
- fil central ;
- panneau contexte a droite.

## COM-W02 - Communaute enseignants

High-fi : `tableau_de_bord_communautaire_rewayah.png`

Correction obligatoire :

- shell Enseignant reel ;
- jamais `Foyer` actif ;
- role affiche = Enseignant ;
- menu Enseignant existant.

## COM-W03 - Le Studio - Canal

High-fi : `maquette_rewayah_du_canal_studio.png`

Disposition :

- navigation globale ;
- liste canaux ;
- canal central ;
- panneau assets/contexte.

Correction obligatoire :

- identite = membre equipe interne ;
- aucun faux role Tuteur ;
- canaux masques si capability absente.

## COM-W03F - Le Studio - Focus

High-fi : `interface_studio_en_mode_focus.annotate.png`

Le focus est un **etat** de COM-W03, pas une nouvelle destination.

## COM-W04 - Administration des communications

High-fi : `tableau_de_communication_rewayah.png`

Contenu :

- AnnouncementPublisher ;
- annonces planifiees ;
- regles audience ;
- ModerationQueue ;
- politique anti-promotion.

Correction obligatoire :

- shell Admin reel ;
- aucune ligne de matrice inventee depuis l'image ;
- matrice basee sur capabilities prouvees ou fixtures demo marquees.

---

# 18. ETATS QUI NE JUSTIFIENT PAS UN ECRAN SUPPLEMENTAIRE

## Recherche

`StudioSearch`, `CommunitySearch`, `ThreadSearch` sont des etats des surfaces existantes.

Desktop :

- champ persistant ;
- resultats dans le panneau de contenu ;
- filtres dans la meme surface ;
- retour conserve la position precedente.

Mobile :

- surface temporaire plein ecran ;
- retour restaure le contexte.

## Notifications desktop

La version desktop reutilise :

- shell du role ;
- pattern liste + detail ;
- `NotificationCenter` ;
- `ClassAnnouncementCard`.

Pas de nouvelle fonction.

## Detail annonce

Surface contextuelle ou page niveau 2 selon longueur.

Aucune navigation propre concurrente.

## Composer communautaire

Mobile : page focalisee ou sheet quasi plein ecran selon pattern existant.  
Desktop : panneau/composer dans Communaute.

Meme composant metier.

---

# 19. COMPOSANTS A CREER OU MAPPER

Avant creation, Claude recherche un composant equivalent.

| Nom fonctionnel | Responsabilite | Complexite |
|---|---|---|
| `ResponsiveWorkspaceShell` | 1, 2 ou 3 panneaux selon largeur | Elevee |
| `ContextThreadHeader` | contexte objet + identite autorisee | Moyenne |
| `ThreadContextPanel` | objet, participants, raccourcis | Moyenne |
| `VoiceMessageComposer` | workflow vocal complet | Elevee |
| `UnreadUrgencyBadge` | non lu / action / urgence accessible | Faible |
| `NotificationCenter` | liste filtree partagee | Moyenne |
| `ClassAnnouncementCard` | annonce contextuelle | Faible |
| `CommunityCategoryTabs` | categories Communaute | Faible |
| `PostComposerEntry` | entree unique nouvelle publication | Moyenne |
| `ReplyThread` | reponses structurees | Moyenne |
| `ModerationActions` | signaler, masquer, restaurer selon capability | Moyenne |
| `CommunityPromotionGuard` | politique anti-promo | Elevee |
| `StudioTodayBoard` | agregation d'attention | Elevee |
| `ActivityInbox` | liste activites | Moyenne |
| `DraftPersistence` | persistance de brouillons | Elevee |
| `SavedForLater` | references enregistrees | Moyenne |
| `StudioChannelList` | canaux, sections, non lus | Moyenne |
| `StudioSharedAssetsPanel` | fichiers, liens, epingles | Moyenne |
| `StudioChannelVisibility` | canal commun/restreint/prive | Elevee |
| `StudioFocusToggle` | entrer/sortir du focus | Moyenne |
| `FocusStateRestorer` | restauration apres focus | Elevee |
| `AnnouncementPublisher` | creer, previsualiser, programmer | Elevee |
| `AudienceRulesMatrix` | representation des scopes | Elevee |
| `ModerationQueue` | contenus signales | Elevee |
| `PromotionPolicyGuard` | raisons pub/affiliate/vente | Elevee |

---

# 20. POINTS D'IMPLEMENTATION SENSIBLES

## `ResponsiveWorkspaceShell`

Ne pas coder trois ecrans separes mobile/tablette/desktop.

Comportement :

- mobile : une surface a la fois ;
- tablette : master/detail si espace reel ;
- desktop : liste + contenu + contexte ;
- panneau droit fermable ;
- aucune colonne vide decorative ;
- largeurs memorisables localement si le pattern du projet le permet.

## `ContextThreadHeader`

Doit supporter :

- Classe ;
- eleve ;
- dossier ;
- mission ;
- autre objet autorise.

Recoit un view model deja nettoye.

## `CommunityPromotionGuard`

Frontend V1 :

- politique visible ;
- etats blocked/warning ;
- fixtures ;
- integration future via port.

Ne pas ecrire un moteur artisanal de detection comme garantie de securite.

## `StudioChannelVisibility`

Le frontend consomme un statut.

Un canal non autorise n'est pas rendu.

## `FocusStateRestorer`

Avant Focus, capturer localement :

- scroll ;
- selection ;
- largeur panneaux ;
- panneau droit ;
- draft ;
- recherche locale.

Restaurer sans animation obligatoire.

## `DraftPersistence`

Ne jamais persister en clair des donnees sensibles dans un stockage non approuve.

Si la couche locale existante n'est pas appropriee, limiter a memoire volatile et documenter.

## `AnnouncementPublisher`

Etapes :

1. contenu ;
2. audience ;
3. date/heure si programmee ;
4. previsualisation ;
5. publier.

Une seule action pleine a la fois.

Aucune publication affichee comme `Publiee` sans confirmation du contrat reel.

---

# 21. NAVIGATION PAR ROLE

## Tuteur

Communications n'ajoute pas automatiquement une cinquieme destination si le shell tuteur valide en possede quatre.

Claude inspecte le shell reel.

Entrees possibles :

- cloche ;
- Espace Classe ;
- Compte/Aide si un fil support existe ;
- raccourci existant.

## Enseignant

Communaute est une destination recurrente seulement si le shell valide l'integre.

Messages metier doit etre atteignable rapidement depuis :

- Classes ;
- notifications ;
- contexte eleve/famille autorise.

## Equipe interne

Le Studio est la destination principale de communication interne.

## Administration

Administration des communications appartient au shell Admin existant.

Ne pas remplacer le shell admin par le shell Tuteur.

---

# 22. COPYWRITING

## Lexique impose

- Messages
- Messages metier
- Communaute enseignants
- Le Studio
- Aujourd'hui
- Notifications
- Annonce
- Publication
- Reponse
- Enregistrer
- Signaler
- Mode focus
- Quitter le focus
- A traiter
- Action requise
- Brouillon
- Elements epingles
- Fichiers partages

Interdit comme fonctionnalite :

- marketplace
- sponsorise
- boutique
- deal
- follower
- influenceur
- viral
- feed social

Le mot `promotion` peut apparaitre uniquement dans un texte d'interdiction ou de moderation.

## Textes anti-promotion exacts

Titre : `Partage pedagogique uniquement`

Corps : `Cette communaute est reservee aux echanges professionnels entre enseignants.`

Regles :

- `Aucune publicite`
- `Aucun lien affilie`
- `Aucune vente de produit ou de service`
- `Aucune sollicitation commerciale`

Lien : `Voir les regles`

Erreur affilie : `Les liens affilies ne sont pas autorises dans la Communaute enseignants.`

Erreur vente : `La vente de produits ou de services n'est pas autorisee dans cet espace.`

## Focus

Entrer : `Mode focus`  
Etat : `Focus active`  
Sortie : `Quitter le focus`  
Aide : `Masquez les panneaux secondaires pour vous concentrer sur cette discussion.`

## Etats generiques

Vide messages : `Aucune conversation pour le moment.`

Vide communaute : `Aucune publication dans cette categorie.`

Vide Studio : `Aucune activite a traiter ici.`

Erreur : `Impossible de charger ce contenu.`

Action : `Reessayer`

Hors ligne : `Vous etes hors ligne. Les nouveaux messages ne peuvent pas etre actualises.`

Envoi non confirme : `Ce message n'a pas encore ete confirme.`

---

# 23. RESPONSIVE

## Mobile

- une tache dominante ;
- une surface a la fois ;
- retour explicite ;
- composer fixe sans recouvrir le dernier message ;
- clavier logiciel pris en compte ;
- safe area ;
- aucun panneau lateral permanent ;
- recherche temporaire plein ecran ;
- bottom navigation uniquement hors Focus.

## Tablette

2 panneaux si largeur suffisante :

- liste + contenu ;
- contexte en sheet/panneau temporaire.

## Desktop

Messages metier :

`Navigation | Conversations | Fil | Contexte`

Studio :

`Navigation | Canaux | Fil | Contexte`

Communaute :

`Navigation | Flux | Publication/Reponses | Aide/Regles`

Admin :

`Navigation | Contenu metier multi-colonnes`

Focus :

`Contenu centre + composer + sortie`, sans colonnes laterales.

---

# 24. ACCESSIBILITE

Obligatoire :

- cibles >= 48 dp quand applicable ;
- ordre clavier logique ;
- focus visible ;
- 200 % text scaling sans contenu critique coupe ;
- lecteur d'ecran ;
- statut non lu annonce ;
- urgence annoncee par texte ;
- boutons vocaux avec nom et etat ;
- waveform non necessaire a la comprehension ;
- `Pause`, `Reprendre`, `Supprimer`, `Envoyer` exposes semantiquement ;
- `Escape` sort du Focus seulement si aucun modal prioritaire ;
- contraste AA ;
- mouvement reduit ;
- aucune information encodee uniquement par couleur ;
- RTL possible ;
- icones directionnelles adaptees.

---

# 25. ETATS PAR ECRAN

Chaque ecran couvre au minimum :

1. chargement
2. contenu
3. vide
4. erreur partielle
5. erreur globale
6. hors ligne
7. permission refusee
8. action indisponible
9. envoi en cours
10. envoi echoue
11. contenu non lu
12. action requise
13. text scaling
14. clavier/focus
15. dark
16. light
17. mobile
18. tablette
19. desktop

Etats propres Messages :

- fil supprime ou inaccessible ;
- objet lie inaccessible ;
- piece jointe indisponible ;
- vocal permission refusee.

Etats propres Communaute :

- contenu bloque anti-promotion ;
- publication signalee ;
- categorie vide ;
- moderation indisponible.

Etats propres Studio :

- canal retire ;
- canal prive non autorise ;
- Focus ;
- brouillon restaure ;
- aucun element Aujourd'hui ;
- panneau contexte ferme.

Etats propres Annonces :

- programmee ;
- publiee ;
- echec ;
- audience indisponible ;
- previsualisation.

---

# 26. DONNEES DE DEMONSTRATION

Creer des fixtures isolees :

- fils parent/enseignant ;
- fil admin/famille ;
- fil controleur/admin ;
- 6 publications communautaires ;
- 2 publications bloquees anti-promotion ;
- 1 lien affilie bloque ;
- 1 vente bloquee ;
- 5 canaux Studio ;
- 1 canal prive absent pour un utilisateur ;
- 1 canal restreint autorise ;
- Today avec activite ;
- Today vide ;
- 1 brouillon ;
- 1 vocal ;
- 1 piece jointe ;
- 1 notification urgente ;
- 1 annonce ;
- 1 echec d'envoi ;
- 1 etat hors ligne.

Le mode demo ne doit jamais etre disponible en production.

---

# 27. RECETTE VISUELLE

Pour chaque high-fi :

- capture mobile 390 x 844 ou format reel equivalent ;
- capture desktop 1440 ;
- light et dark quand le shell existe dans les deux themes ;
- comparaison visuelle ;
- controle du role affiche ;
- controle de la navigation ;
- controle du texte ;
- controle des cartes groupees ;
- controle des tokens.

Ecarts interdits :

- vert utilise comme identite visuelle dominante ;
- beige invente comme theme produit ;
- shell Tuteur dans ecran Enseignant ;
- shell Tuteur dans Le Studio ;
- shell Tuteur dans Admin ;
- action dupliquee ;
- marketplace ou vente ;
- bouton DM enseignant depuis Communaute ;
- panneau desktop vide ;
- mobile etire sur desktop.

---

# 28. RECETTE FONCTIONNELLE

## R-COM-01 - Fil contextuel

Etant donne un enseignant avec une Classe autorisee, quand il touche une conversation depuis Messages, alors le fil s'ouvre avec le bon parent/eleve et le contexte de Classe, sans coordonnee privee.

## R-COM-02 - Inter-foyers

Etant donne une famille A, quand le frontend recoit une tentative de thread vers une famille B non autorisee, alors le thread n'est pas rendu comme accessible.

## R-COM-03 - Vocal

Quand l'utilisateur enregistre un vocal, alors il peut mettre en pause, reprendre, arreter, pre-ecouter, supprimer puis envoyer.

## R-COM-04 - Limite vocal

Quand 3:00 est atteint, alors l'enregistrement s'arrete et passe en pre-ecoute.

## R-COM-05 - Anti-pub

Quand une fixture marque un contenu comme publicite, alors le composer affiche le motif et n'affiche pas un faux succes de publication.

## R-COM-06 - Lien affilie

Quand une fixture marque un lien comme affilie, alors `CommunityPromotionGuard` bloque la publication avec le texte canonique.

## R-COM-07 - Communaute sans DM

Quand un enseignant ouvre le profil d'un autre enseignant depuis la Communaute, alors aucun CTA `Message prive` n'est disponible dans V1.

## R-COM-08 - Studio prive

Quand un membre n'a pas acces a un canal prive, alors le canal n'apparait pas.

## R-COM-09 - Focus

Etant donne un canal Studio ouvert, quand l'utilisateur active Focus, alors navigation, canaux, panneau droit, recherche et notifications disparaissent, tandis que contenu, composer et sortie restent accessibles.

## R-COM-10 - Sortie Focus

Quand l'utilisateur quitte Focus, alors position, canal, brouillon et panneaux compatibles sont restaures.

## R-COM-11 - Aujourd'hui

Quand un element Finance apparait dans Aujourd'hui, alors l'action ouvre Finance au lieu d'executer l'action dans Le Studio.

## R-COM-12 - Notification annonce

Quand l'utilisateur ouvre une notification d'annonce de Classe, alors il arrive a l'annonce et peut ouvrir la Classe concernee.

## R-COM-13 - Erreur reseau

Quand un envoi echoue, alors aucun statut `envoye` n'est affiche.

## R-COM-14 - Clavier

Sur Web, quand l'utilisateur navigue au clavier, alors l'ordre de focus est logique et le focus est visible.

## R-COM-15 - Clavier logiciel

Quand le clavier mobile s'ouvre, alors le composer reste utilisable et le dernier message peut rester visible.

---

# 29. PLAN D'EXECUTION CLAUDE

## L0 - Inventaire lecture seule

Avant toute mutation :

- routes ;
- shells par role ;
- `NotificationsPage` existante ;
- fil Controleur existant ;
- composants chat existants ;
- ports/adapters ;
- demo existante ;
- design tokens ;
- composants partages ;
- matrice `Garder / Ameliorer / Ajouter / Supprimer sur validation`.

Livrable : `UX_REVIEW_COMMUNICATIONS_L0.md`

Aucune ligne de code avant cette revue.

## L1 - Fondations partagees

- models UI ;
- lignes ;
- badges ;
- composer texte ;
- vocal ;
- pieces jointes ;
- empty/error/loading ;
- `ResponsiveWorkspaceShell`.

## L2 - Messages metier

- liste ;
- fil ;
- contexte ;
- mobile ;
- desktop ;
- demo ;
- tests.

## L3 - Communaute enseignants

- flux ;
- categories ;
- publication ;
- reponses ;
- enregistrer ;
- signaler ;
- anti-promotion ;
- demo ;
- tests.

## L4 - Studio

- Aujourd'hui ;
- channel list ;
- canal ;
- assets panel ;
- brouillons ;
- activite ;
- recherche ;
- visibility ;
- Focus ;
- demo ;
- tests.

## L5 - Notifications et annonces

- centre partage ;
- annonce Classe ;
- detail ;
- admin publisher ;
- audience UI ;
- moderation queue ;
- demo ;
- tests.

## L6 - Revue croisee

### Produit

Verifier :

- une fonction un endroit ;
- aucun chat libre ;
- aucun marketplace ;
- aucune permission inventee ;
- aucun doublon.

### UX/UI

Verifier :

- fidelite high-fi ;
- densite ;
- vrai desktop ;
- Focus ;
- shell role correct ;
- navigation sans impasse.

### Securite communautaire

Verifier :

- anti-pub ;
- anti-affiliation ;
- anti-vente ;
- signalement ;
- absence de DM communautaire ;
- donnees famille non exposees.

### Accessibilite

Verifier :

- clavier ;
- lecteur d'ecran ;
- text scaling ;
- contraste ;
- semantics vocal ;
- Focus.

### Architecture frontend

Verifier :

- composants partages ;
- aucun service concurrent ;
- ports propres ;
- demo isolee ;
- zero backend mutation.

## L7 - Recette

- golden tests ;
- widget tests ;
- navigation par tap ;
- demo role ;
- mobile ;
- tablette ;
- desktop ;
- dark ;
- light ;
- hors ligne ;
- Focus ;
- anti-promotion ;
- screenshots comparatifs.

---

# 30. HANDOFF CLAUDE - INSTRUCTION IMPERATIVE

Claude Code doit :

1. lire cette spec et les high-fi ;
2. inspecter le depot avant de coder ;
3. ne jamais recopier un shell de role errone de l'image ;
4. reutiliser les composants existants ;
5. ne pas toucher au backend ;
6. ne pas creer une messagerie libre ;
7. ne pas creer de DM enseignant depuis la Communaute ;
8. construire `CommunityPromotionGuard` et les etats de moderation ;
9. construire le Focus Studio comme etat local restaurable ;
10. garder Le Studio comme agregateur et bureau, pas comme copie des modules metier ;
11. respecter palette et polices gelees ;
12. fournir les captures mobile et desktop ;
13. fournir la carte des fonctions finale avec routes reelles ;
14. prouver chaque entree par un test qui touche le bouton reel ;
15. signaler tout conflit avant de choisir.

**Interdiction d'interpreter les high-fi comme une autorisation de creer une capability absente.**

---

# 31. HIGH-FI DE REFERENCE

## Mobile - 3 ecrans par planche

### Planche A

Fichier : `maquette_ui_mobile_rewayah_en_mode_sombre.png`

- COM-M01 Messages metier
- COM-M02 Communaute enseignants
- COM-M03 Le Studio - Canal

### Planche B

Fichier : `planche_ui_rewayah_studio_d_équipe.png`

- COM-M04 Le Studio - Aujourd'hui
- COM-M05 Le Studio - Focus
- COM-M06 Notifications et annonce

## Desktop - 1 ecran par planche

- `tableau_de_bord_rewayah_pastel.png` -> COM-W00 Le Studio - Aujourd'hui
- `interface_de_messagerie_rewayah_en_français.png` -> COM-W01 Messages metier
- `tableau_de_bord_communautaire_rewayah.png` -> COM-W02 Communaute enseignants
- `maquette_rewayah_du_canal_studio.png` -> COM-W03 Le Studio - Canal
- `interface_studio_en_mode_focus.annotate.png` -> COM-W03F Le Studio - Focus
- `tableau_de_communication_rewayah.png` -> COM-W04 Administration des communications

**Les images sont references de composition. Les textes de permissions et shells de role sont corriges par cette spec.**

---

# 32. HORS PERIMETRE

Ne pas construire :

- chat public ;
- DM libre entre tous les utilisateurs ;
- appels audio/video depuis Messages ;
- groupe de discussion cree librement par les familles ;
- marketplace ;
- boutique ;
- paiement peer-to-peer ;
- abonnement communautaire ;
- publicite ;
- affiliation ;
- score de popularite ;
- nombre d'abonnes ;
- classement d'enseignants ;
- algorithme de recommandation de feed ;
- stories ;
- diffusion live communautaire ;
- moteur IA de moderation autonome ;
- sanction automatique de compte ;
- retention backend definitive ;
- nouvelles tables ;
- push reel sans contrat ;
- synchronisation multi-appareil des brouillons sans contrat.

---

# 33. CRITERES DE FIN

Communications V1 frontend est terminee uniquement si :

- tous les ecrans high-fi ont une implementation atteignable ;
- shells de role corrects ;
- theme Rewayah respecte ;
- mobile non etire sur desktop ;
- Messages metier contextuel ;
- Communaute sans vente ni affiliation dans son UX ;
- aucun CTA DM enseignant communautaire ;
- Studio avec Aujourd'hui ;
- Studio avec Focus ;
- Focus restaure l'etat ;
- moderation avec etats ;
- vocaux avec workflow complet ;
- notifications partagees et contextuelles ;
- annonces ouvrent leur objet ;
- demo couvre les parcours ;
- tests touchent les vrais points d'entree ;
- zero backend modifie ;
- aucune fonctionnalite declaree reelle sans preuve.

---

# 34. AUTO-CONTROLE

## Couverture

- Messages metier : couvert
- Communaute enseignants : couvert
- Anti-promotion : couvert
- Liens affilies : couvert
- Vente : couvert
- Signalement : couvert
- Moderation : couvert
- Le Studio : couvert
- Aujourd'hui : couvert
- Focus mobile : couvert
- Focus desktop : couvert
- Recherche : couverte comme etat
- Brouillons : couverts
- Saved for later : couvert
- Fichiers : couverts
- Canaux prives : couverts
- Vocaux 3 minutes : couverts
- Notifications : couvertes
- Annonces : couvertes
- Admin communications : couvert
- Responsive : couvert
- Accessibilite : couverte
- Demo : couverte
- Recette : couverte
- Handoff Claude : couvert
- Frontend only : verrouille

## Risques volontairement non resolus dans Flutter

- retention exacte ;
- schema serveur des messages ;
- moderation automatique reelle ;
- detection reelle des liens affilies ;
- push ;
- stockage vocal ;
- stockage des pieces jointes ;
- matrice de permissions definitive ;
- synchronisation multi-device ;
- audit serveur ;
- idempotence d'envoi.

Aucun de ces points ne bloque la construction frontend si les etats `indisponible`, `demo` et les ports abstraits sont correctement utilises.

---

# FIN DU DOCUMENT
