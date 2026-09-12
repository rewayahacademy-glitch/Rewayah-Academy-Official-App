# Plan d'exécution - Étape 5
## La salle, le Coran comme contenu structuré, la présence

Ce document décrit **ce qui doit exister** et **comment on le vérifiera**. Il
tient pour l'étape 5 le rôle que `etape-4-dashboards.md` tient pour l'étape 4 :
c'est un lot **L0**, documentaire, écrit avant tout code (lot **N0** de l'ordre
de travail de l'ADR-019).

Sources : `docs/design/00-bible-frontend-v2.md` §19-32 (texte intégral déjà
adopté par l'ADR-019, lu en entier pour ce lot), `docs/architecture/decisions.md`
ADR-001, 002, 004, 005, 006, 008, 009, 010, 011, 012 (l'architecture de la salle,
déjà tranchée), `etape-0-1-fondations.md` pour le schéma existant,
`docs/design/08-catalogue-ecrans.md` pour les quatre écrans concernés.

---

## 1. Ce que l'étape 5 doit rendre possible

L'étape 4 s'arrête à la porte de la salle : `ENS-02` a son bouton de lancement
non rendu, `ELV-02` mène au placeholder de `ELV-04`, et la route `/salle` sert
`EcranAConstruire(destination: 'ELV-03 / ENS-03')` (`lib/core/router/app_router.dart`).
À la fin de l'étape 5, ces parcours fonctionnent de bout en bout :

| # | Parcours | Écrans |
| :-- | :--- | :--- |
| 1 | Un élève entre en cours, suit l'enseignant sur le document partagé, peut explorer le Coran de son côté sans perdre sa place | `ELV-03`, `ELV-04` |
| 2 | Un enseignant entre en cours, contrôle le document partagé, voit qui est présent, en retard, déconnecté | `ENS-03` |
| 3 | Un contrôleur observe une séance en cours sans être vu ni entendu | `CTR-02` |
| 4 | Un élève ou un enseignant lit le Coran hors séance, reprend exactement où il s'était arrêté | `ELV-04` |
| 5 | L'administration dispose d'états de présence représentables, au-delà d'une seule couleur, pour trancher un litige de temps effectif (question 16 du registre) | Consommé par `ADM-04`, étape 6 |

Ce que ce lot **ne fait pas** : aucun de ces écrans ne se code ici. La liste
ci-dessus décrit ce que le codage de l'étape 5 devra rendre possible, pas ce que
N0 livre.

---

## 2. Ce qui est déjà tranché, et sur quoi ce document s'appuie sans le rouvrir

La salle a déjà dix ADR d'architecture, écrits aux étapes 0-1, avant même que le
premier écran de dashboard existe. Ce lot ne les rediscute pas : il pose la
couche UX que la Bible V2 exige par-dessus, et le modèle de contenu Coran qui
manquait.

| ADR | Ce qu'il fige déjà | Ce que N0 en fait |
| :--- | :--- | :--- |
| ADR-001 | LiveKit, portabilité, audio d'abord, `video_config`, `VideoSessionProvider` abstrait | Base technique de `ELV-03`/`ENS-03`/`CTR-02`, non rediscutée |
| ADR-002 | Enregistrement audio systématique, 30 jours, indicateur permanent | L'indicateur d'enregistrement est un élément fixe de la hiérarchie visuelle §5.2 ci-dessous |
| ADR-004 | Groupes jusqu'à 6, `allow_multi_participant_sessions` fermé par défaut, `session_peers_v` | Les écrans de salle décrits ici valent pour 1-to-1 ; le multi-participants reste fermé, § 9 |
| ADR-005 | Token éphémère (T-10 à T+fin+10), pas de lien partageable, pre-flight obligatoire, aucun tchat ni partage d'écran ni fichier, filigrane, fin automatique | Contrat déjà complet pour ce que le **serveur** interdit ; ce document ajoute ce que l'**écran** doit montrer |
| ADR-006 | Archives audio légères, jamais côté client | Sans effet sur ce lot |
| ADR-008 | Filigrane abandonné, coordonnées jamais visibles à l'enseignant | Rappelé en §11 sécurité |
| ADR-009 | Caméra élève : attribut de profil, jamais une action répétée ; mode enfant à deux commandes | Cadre directement `ELV-03` §7 |
| ADR-010 | Un seul appareil en séance à la fois | Sans effet direct sur l'écran, déjà appliqué à l'émission du token |
| ADR-011 | Contrôleur invisible, bandeau permanent **sans paramètre**, déjà codé (`lib/core/widgets/permanent_notice.dart`) | `CTR-02` réutilise ce composant tel quel, § 7 |
| ADR-012 | Photo de profil, jamais dans `session_peers_v` | Rappelé en §11 |

**Ce qui existe déjà en code, avant tout lot de l'étape 5** : `BilletSalle`
(`lib/core/router/billet_salle.dart`, le billet éphémère qui porte l'ADR-005),
`PermanentNotice` (le bandeau de l'ADR-011), la route `Routes.salle` câblée dans
`app_router.dart`, l'enum `StatutSeance` (neuf valeurs, dont `preflight`,
`enCours`, `enseignantAbsent`, `eleveAbsent`, `incidentTechnique`, déjà
consommées par `ADM-01`), et la colonne `student_profiles.riwaya` (`text`,
défaut `'hafs'`, jamais écrite à une autre valeur en base). L'étape 5 ne part
donc pas de zéro.

---

## 3. Décisions de l'opérateur, prises le 11 septembre 2026 (ADR-020)

### 3.1 Riwaya et édition du Coran : Hafs, Complexe du Roi Fahd

Question 3 du registre (« Warsh ou Hafs ») est **résolue** : **Hafs ʿan ʿĀṣim**,
édition **Mushaf Al-Madinah An-Nabawiyyah** du **Complexe du Roi Fahd pour
l'impression du Noble Coran** (Mujammaʿ al-Malik Fahd), « avec tout ce qui va
avec » — c'est-à-dire la pagination standard de cette édition (604 pages, 15
lignes par page, tracé Uthmani de ce complexe), pas une simple reconstitution
approximative du texte.

Ce choix **confirme un défaut déjà présent dans le schéma depuis l'étape 1** :
`student_profiles.riwaya` vaut `'hafs'` par défaut, et aucune ligne n'a jamais
porté une autre valeur. La colonne reste `text` libre (pas un `enum` fermé à
une seule valeur) : rien n'empêche techniquement un profil futur de déclarer
une autre riwaya, mais **le contenu Coran lui-même — le texte, la pagination,
les métadonnées de mise en page — n'est chargé que pour Hafs/Madina en MVP-0**.
Un profil qui porterait une autre valeur de `riwaya` n'aurait simplement aucun
contenu à afficher : ce cas n'est pas géré, et n'a pas à l'être ici.

**Ce qui reste ouvert, et n'est pas tranché par cette décision** : la **source
technique** des données (quel jeu de données ou quelle API sert la pagination
exacte du Mushaf Madina, quelle police glyphe-par-page ou quel encodage Unicode,
quelle licence). C'est un choix de fournisseur/format au moment du codage, pas
une décision de riwaya. Il n'est pas inventé ici.

### 3.2 Méthode : ce lot spécifie, il ne code pas

Comme le lot L0 de l'étape 4, N0 produit une spécification complète (ce
document) plus la mise à jour du registre et de `README.md`. Le découpage en
lots de codage (§12) est une **proposition**, pas un engagement : il sera
confirmé au début du premier lot de code de l'étape 5.

### 3.3 Aucune dérogation à la Bible V2 sur ce périmètre

Contrairement à l'ADR-019 (§7.2 couleurs, §7.3 mode sombre), aucune dérogation
n'est nécessaire ici : les §19-32 de la Bible sont un modèle UX abstrait, sans
prescription de jetons ou de composants qui entrerait en conflit avec ce que le
dépôt a déjà posé.

---

## 4. Le Coran comme contenu structuré (Bible §23-24, §27-28)

### 4.1 Modèle de données

La Bible interdit de modéliser le Coran comme un PDF (§23) : la couche
d'affichage ne doit pas dépendre d'un fichier, le rendu doit être découplé du
modèle de données. Adapté au vocabulaire déjà en place dans ce dépôt (français,
`snake_case` en base) :

| Entité Bible | Entité proposée | Rôle |
| :--- | :--- | :--- |
| Mushaf | `mushaf` | Une édition physique de référence. Une seule ligne en MVP-0 : Madina/Roi Fahd, Hafs |
| Edition / Script | porté par `mushaf` | Le tracé Uthmani du complexe, pas un champ séparé tant qu'une deuxième édition n'existe pas |
| Chapter | `sourate` | Numéro, nom arabe, nom translittéré, lieu de révélation |
| Juz | `juz` | Numéro, position de départ |
| Page | `page_mushaf` | Numéro (1 à 604), sourates qu'elle contient |
| Verse | `verset` | Sourate, numéro, texte, page, ligne |
| Word | `mot` | Position dans le verset, position sur la page. **Nécessaire seulement si le focus mot-à-mot (§21.1 « focus », §26 niveau 2) est construit dès le premier lot** ; sinon reporté, la granularité verset suffit à un premier lecteur |
| Layout Metadata | colonnes de `page_mushaf`/`verset` | Ce qui permet un rendu fidèle à la mise en page réelle de l'édition, pas un reflow libre |

**Ce que ce modèle ne fixe pas** : le format de stockage exact (table SQL
important le jeu de données une fois pour toutes, contre un appel à une API
externe à chaque lecture). C'est un arbitrage de coût/latence/hors-ligne à faire
au codage, pas ici — mais la Bible est claire sur un point qui, lui, **est**
tranché : quel que soit le choix, la couche Flutter ne doit jamais dépendre
d'un identifiant de fichier PDF.

### 4.2 État partagé de séance contre état personnel (§24)

Distinction **obligatoire**, dit la Bible (§24), et elle recoupe exactement la
classification état métier / UI / préférence déjà ajoutée à
`03-architecture-information.md` §8 par le lot B0 :

| Type | Exemples (Bible §24.1/24.2) | Portée proposée |
| :--- | :--- | :--- |
| État partagé de séance | Document sélectionné par l'enseignant, page présentée, verset ciblé, focus pédagogique, pointeur, annotation partagée | Une ligne par séance en cours, éphémère, poussée par l'enseignant aux élèves connectés (canal temps réel LiveKit data ou Supabase Realtime, à trancher au codage) |
| État personnel élève | Dernière position de lecture, page personnelle, zoom, préférences | `student_reading_position` : une ligne par élève, indépendante de toute séance, c'est elle qui porte la reprise (§4.3) |

**Règle critique (§24.3), reprise ici sans l'affaiblir** : une action partagée
de l'enseignant (il tourne la page pour toute la classe) ne doit **jamais**
écraser silencieusement `student_reading_position`. Les deux états coexistent :
l'élève peut suivre l'enseignant (§4.4) ou explorer de son côté sans perdre sa
position personnelle.

### 4.3 Reprise de lecture (§27-28)

Une position, per la Bible, comprend potentiellement `document_id`, `edition_id`
(ici `mushaf_id`), `page_number`, `chapter_number`, `verse_number`,
`word_position`, `scroll_offset`, `zoom_level`, `timestamp`. Proposition adaptée
à la granularité retenue en §4.1 (verset, pas mot, sauf extension) :

```
student_reading_position (
  student_profile_id, mushaf_id,
  page_mushaf, sourate, verset,
  zoom_level, updated_at
)
```

Une ligne par élève : la position la plus récente écrase la précédente,
`updated_at` sert à afficher « Reprendre : Sourate Al-Baqara, verset 30 »
(§28) sur `ELV-02` et `ELV-04`, jamais caché dans un réglage.

### 4.4 Mode suivi enseignant (§25)

État `FOLLOWING_TEACHER` / `STUDENT_EXPLORING` (vocabulaire Bible, à
franciser au codage, par exemple `suitEnseignant` / `explorePersonnel`). Un
élève qui s'écarte du document de l'enseignant voit une action « Retour au
point de l'enseignant » ; revenir dessus rebascule en suivi. Ne jamais
téléporter l'élève sans son geste — la Bible l'interdit explicitement (§25),
et cela recoupe la règle déjà en place « ne pas imposer un rafraîchissement
silencieux qui détruit une action locale » (même esprit que l'invariant
`ENS-06` sur la concurrence : la base ou l'état tranche, jamais un écrasement
muet).

---

## 5. La salle : modèle UX et hiérarchie (Bible §19-22, §25-26, §32)

### 5.1 Sous-systèmes et dégradation indépendante (§19, §32)

La salle n'est pas un écran vidéo unique : Media, Shared Document Stage,
Teacher Controls, Attendance, Participant Context, Session State — chacun doit
pouvoir se dégrader **indépendamment**. Traduit en exigence vérifiable :

| Sous-système en panne | Ce qui doit rester utilisable |
| :--- | :--- |
| Média (LiveKit) | Le document partagé reste consultable, la reprise de lecture fonctionne |
| Document partagé | La vidéo reste utilisable, la séance continue |
| Service de présence | Ne jamais afficher un état de présence final comme certain si sa source n'est pas disponible — un état « inconnu » existe et se montre comme tel, pas comme « absent » |
| Réseau faible | La dégradation s'affiche clairement (ADR-001 : bascule automatique en audio seul) |
| Reconnexion | L'état métier et visuel se restaure sans reconstruire tout l'écran |

### 5.2 Hiérarchie visuelle par gabarit (§20)

| Gabarit | Priorité |
| :--- | :--- |
| Mobile portrait | 1. média actif selon contexte · 2. contenu partagé/pédagogique · 3. action essentielle · 4. contrôles secondaires. Le bandeau permanent (ADR-011) ne doit **jamais** couvrir une zone importante du Coran |
| Mobile paysage | vidéo, document, contrôles contextuels, disposition plus riche |
| Tablette | split réel si l'espace le permet, même logique que `app_gabarit.dart` déjà en place pour le reste du produit |
| Desktop | vidéo/outils enseignant à gauche, document partagé à droite, session/contrôles/participants en bande basse — pattern donné par la Bible, l'implémentation exacte reste ouverte aux contraintes réelles |

### 5.3 Document partagé et mode immersif (§21-22)

Le document partagé (`SharedDocumentStage`, nom repris tel quel de la Bible) a
son propre état : document courant, type, page, verset, focus, pointeur,
annotation éventuelle, zoom, navigation, mode page/focus/immersif. Il devient
le **contenu primaire** quand la pédagogie de la séance porte dessus (§21.2).

Le mode immersif (§22) est **obligatoire** pour la lecture du Coran, surtout
mobile : `CONTENT > CHROME`. Le Coran ne se traite jamais comme une petite
`AppCard` entourée de contrôles — contrainte directe pour `ELV-04`, qui vient
d'ores et déjà casser l'habitude prise sur tous les écrans repris aux lots R
(carte sur fond, cf. R0/R4) : ici, le motif s'inverse délibérément, et ce
n'est pas une régression au sens de la Bible §51.

### 5.4 Contrôles enseignant par fréquence (§26)

| Niveau | Contenu | Exigence |
| :--- | :--- | :--- |
| 1 — immédiat | page précédente/suivante, aller à une page, pointeur/focus | Jamais à plus d'un tap, geste répété toutes les minutes |
| 2 — pédagogique | focus verset, annotation si supportée, mode de lecture | Un peu plus profond, pas un menu |
| 3 — configuration | préférences, édition, options avancées | Peut être derrière un menu, usage rare |

---

## 6. La présence : machine à états (Bible §29-31)

### 6.1 Ce qui existe déjà, et ce qui manque

Deux mécanismes existent déjà et ne se recouvrent pas :

- **`StatutSeance`** (`lib/core/domain/enums.dart`) : l'état de la **séance
  entière**, neuf valeurs (`planifiee`, `preflight`, `enCours`, `terminee`,
  `enseignantAbsent`, `eleveAbsent`, `incidentTechnique`, `annuleeTard`,
  `annulee`), déjà consommé par `ADM-01`. Il ne dit rien de **qui**, seulement
  de la séance dans son ensemble.
- **`session_events`** (`session_event_type` : `joined`, `left`,
  `track_subscribed`, `track_unsubscribed`, `record_started`, `record_ended`,
  plus une colonne `source`) : le journal **brut** des webhooks LiveKit, par
  participant. C'est un flux d'événements techniques, pas un état.

**Ce qui manque, et que la Bible §29 exige** : un état de présence **par
participant**, représenté comme une machine à états avec ses transitions (pas
seulement une couleur finale), calculé à partir des deux mécanismes ci-dessus
plus l'horaire planifié. Ce n'est **pas** une nouvelle table d'événements
bruts : c'est une **dérivation**, vue ou calcul, au-dessus de `session_events`
et `sessions`.

### 6.2 Les 14 états (Bible §29.1, traduits, aucun ni ajouté ni retiré)

La Bible l'interdit explicitement : « ne jamais inventer ou supprimer un état
métier existant ». Les 14 états, tels quels :

| Bible | Proposition FR | Se déduit de |
| :--- | :--- | :--- |
| scheduled | `planifiee` | Avant l'ouverture de la fenêtre de token (T-10 min, ADR-005) |
| waiting | `enAttente` | Fenêtre ouverte, aucun `joined` encore reçu |
| joining | `enConnexion` | Token émis, connexion LiveKit en cours, avant le premier `joined` |
| present | `presente` | Dernier événement du participant = `joined` (ou `track_subscribed` qui le confirme) |
| late | `enRetard` | `joined` reçu après l'heure planifiée + un seuil — **le seuil est un paramètre `app_config` à fixer au codage, non inventé ici** |
| disconnected | `deconnectee` | `left` reçu **sans** geste explicite de sortie (voir §6.3 sur la colonne `source`) avant la fin planifiée |
| reconnecting | `enReconnexion` | Fenêtre courte après un `deconnectee`, en attente d'un nouveau `joined` |
| reconnected | `reconnectee` | Nouveau `joined` du même participant, même séance, après un `deconnectee` |
| left | `sortie` | `left` avec un geste explicite (bouton de sortie, `source` le distingue) |
| absent | `absente` | Séance terminée (`StatutSeance.terminee` ou `*Absent`), aucun `joined` jamais reçu pour ce participant |
| excused | `excusee` | Décision administrative explicite — **mécanisme non conçu ici**, voir §6.5 |
| pending confirmation | `confirmationEnAttente` | Séance terminée, présence calculée mais pas encore consolidée |
| manually overridden | `corrigeeManuel` | Un enseignant ou un administrateur corrige l'état calculé, geste journalisé (`audit_logs`, même esprit qu'ADR-011) |
| finalized | `finalisee` | État consolidé, immuable, celui qui pourra un jour alimenter la paie (question 16 du registre) |

### 6.3 Ce que la base devra gagner pour distinguer sortie volontaire et perte réseau

`session_events.source` existe déjà (colonne du schéma étape 1) mais son
vocabulaire de valeurs n'est pas fixé. Proposition pour l'étape 5 : au moins
`user_action` (bouton de sortie pressé) contre `network`/`server` (LiveKit
signale une perte de connexion ou ferme la salle). C'est la distinction qui
permet à `left` de ne jamais se confondre avec `disconnected`. **La valeur
exacte de ce vocabulaire, et le seuil de `enReconnexion`, restent à fixer au
codage** : ce ne sont pas des décisions de riwaya ou d'architecture, ce sont
des paramètres à mesurer contre le vrai comportement des webhooks LiveKit.

### 6.4 Diagramme de transition (Bible §29.2, cas nominal)

```
planifiee → enAttente → enConnexion → presente
                                          ↓
                                    deconnectee
                                          ↓
                                    enReconnexion
                                          ↓
                                    reconnectee → presente
```

`presente` peut aussi mener directement à `sortie` (geste volontaire) ou à
`absente` si la séance se termine sans qu'un seul `joined` n'ait jamais été
vu. `confirmationEnAttente` s'ouvre à la fin de la séance pour tout
participant qui n'est pas encore `finalisee` ; `corrigeeManuel` et `excusee`
peuvent intervenir à tout moment après coup, toujours journalisés.

### 6.5 Information de contexte, jamais une seule couleur (§29.3)

Chaque état affiché porte : l'état actuel, une heure utile (quand est-il entré,
depuis quand est-il déconnecté), un contexte (« reconnexion en cours depuis 12
secondes »), une action possible s'il y en a une, et un historique quand c'est
pertinent. Une pastille de couleur seule ne suffit jamais pour un état
critique — règle directement héritée du principe déjà en place sur `ADM-01` (le
zéro s'affiche comme les autres valeurs, jamais une absence).

**Ce qui n'est pas conçu ici, et reste ouvert** : le mécanisme précis par
lequel une administration marque `excusee` (quel écran, quelle policy —
probablement dans le registre `ADM-06`/`ADM-04` déjà existant, à confirmer au
codage) et la nomenclature figée des événements demandée par la question 19 du
registre. La présence en donne une première brique (`session_event_type` plus
les états ci-dessus), mais la liste complète (matching, séance, contenu) reste
au-delà du périmètre de N0.

### 6.6 Vue enseignant et vue élève (Bible §30-31)

| Rôle | Ce qu'il doit comprendre | Ce qu'il ne doit pas voir |
| :--- | :--- | :--- |
| Enseignant (`ENS-03`) | Qui est présent, en retard, absent, déconnecté ; ce qui est provisoire contre finalisé | Détails superflus dans la vue principale — consultables, pas imposés |
| Élève (`ELV-03`) | Son propre état ; si une reconnexion est nécessaire ; si une action est requise ; si le cours est encore actif | Aucun détail administratif (pas les états des autres, sauf ce que `session_peers_v` autorise déjà par l'ADR-004) |

---

## 7. Écrans

### `ELV-03` Salle, élève

Plein écran, pas de `PageShell` ni d'`AppCard` (§5.3 : contenu avant chrome).
Bandeau permanent de l'ADR-011 en haut, jamais masqué (invariant déjà noté au
catalogue §4). Micro et caméra fermés à l'entrée, un tap les ouvre — vrai pour
tous les rôles (même invariant catalogue). Quand `camera_policy` du profil
vaut `interdite` (ADR-009), le bouton caméra **n'existe pas**, il n'est pas
grisé : cohérent avec la règle déjà appliquée à `ActionPrincipale` désactivée
(lot T2) — un contrôle qui ne peut jamais réussir ne doit jamais être rendu.

En mode enfant (ADR-009) : deux commandes seulement, micro et sortie. Aucune
liste de participants, aucun réglage, aucun bouton de signalement (ADR-005 déjà
noté).

Le document partagé occupe le contenu primaire quand l'enseignant l'active
(§5.3) ; sinon la vidéo de l'enseignant domine (Makharij, ADR-001). L'état de
présence personnel de l'élève (§6.6) reste visible en permanence, discret,
jamais superposé au texte du Coran.

### `ENS-03` Salle, enseignant

Même socle que `ELV-03` (bandeau, plein écran, document partagé), plus les
contrôles de niveau 1/2/3 (§5.4) et le tableau de présence de tous les
participants (§6.6). La sortie mène obligatoirement à `ENS-04` (invariant
catalogue déjà noté) — `ENS-04` reste hors périmètre MVP-0 immédiat (cahier de
transmission, étape 6), donc cette destination existe comme contrat d'écran
mais son contenu n'est pas ce lot.

### `CTR-02` Observation invisible

Réutilise `ELV-03`/`ENS-03` presque à l'identique côté rendu (même bandeau,
même document partagé), avec les restrictions déjà écrites à l'ADR-011 :
aucune publication, absence de la liste des participants, entrée et sortie
sans annonce. « Bandeau noir permanent » du catalogue (§1, zone Journée et
salle) à confirmer visuellement au codage — la Bible ne prescrit pas de
couleur spécifique, c'est une différenciation déjà actée dans le catalogue,
pas une invention de ce lot.

### `ELV-04` Coran

Lecteur plein écran, colonne de lecture bornée sur desktop (déjà au catalogue).
Mode immersif par défaut (§5.3) : contrôles secondaires masqués, révélés par un
tap, jamais superposés durablement au texte. Réapparition de l'accès « Reprendre »
(§4.3) en évidence, jamais caché dans un réglage — même exigence que la
Bible §28 pour toute fonction fréquente.

Accessible depuis `ELV-02` (bloc permanent Coran, déjà noté en
`etape-4-dashboards.md` §5) et, en séance, comme le document partagé lui-même
quand l'enseignant l'active (§4.4, mode suivi).

---

## 8. Invariants de l'étape 5

| # | Invariant | Où il s'applique |
| :-- | :--- | :--- |
| J1 | Le bandeau permanent ne change jamais, y compris pendant une visite de contrôle | `PermanentNotice`, sans paramètre, déjà codé |
| J2 | Une action partagée de l'enseignant n'écrase jamais silencieusement `student_reading_position` | §4.2, §4.3 |
| J3 | Un état de présence indisponible s'affiche comme inconnu, jamais comme « absent » par défaut | §5.1, §6.5 |
| J4 | Aucun des 14 états de présence de la Bible §29.1 n'est ni ajouté ni supprimé sans décision écrite | §6.2 |
| J5 | Le bouton caméra n'existe pas quand la politique l'interdit ; il n'est jamais grisé | ADR-009, §7 `ELV-03` |
| J6 | La couche d'affichage du Coran ne dépend jamais d'un identifiant de fichier PDF | ADR §23, §4.1 |
| J7 | Une couleur seule ne représente jamais un état de présence critique | §6.5 |
| J8 | Le mode suivi de l'élève ne téléporte jamais silencieusement une exploration personnelle en cours | §4.4 |

---

## 9. Ce que l'étape 5 ne fait pas

- **Aucun groupe de plus de deux participants effectifs.**
  `allow_multi_participant_sessions` reste fermé (ADR-004) ; les écrans décrits
  ici visent le 1-to-1, le contrôleur en plus. Le multi-participants reste
  prévu par le schéma, pas construit par ce lot.
- **Aucun cahier de transmission.** `ENS-04` et `TUT-06` restent l'étape 6
  (ADR-003). `ENS-03` y mène en contrat d'écran seulement.
- **Aucune annotation collaborative avancée** au-delà de ce que §21.1
  mentionne comme « éventuelle » : la Bible elle-même la traite comme
  optionnelle selon les spécifications, pas comme un P0.
- **Aucune finalisation de paie.** La question 16 du registre (litige sur le
  temps effectif) reste ouverte : ce lot pose l'état `finalisee`, il ne
  construit pas ce qui s'en sert.
- **Aucun choix de source de données Coran.** Voir §3.1 : la riwaya est
  tranchée, le fournisseur technique des données ne l'est pas.
- **Aucune nomenclature d'événements complète** au sens de la question 19 du
  registre : seule la brique présence est posée ici (§6.5).

---

## 10. Ce qui reste ouvert avant ou pendant le codage

| # | Question | Pourquoi elle n'est pas tranchée ici |
| :-- | :--- | :--- |
| a | Source technique des données du Mushaf Madina (API, jeu de données, licence, police) | Choix de fournisseur, pas de riwaya (§3.1) |
| b | Seuil de retard (`late`) et fenêtre de reconnexion | Paramètres à mesurer contre le comportement réel des webhooks LiveKit, pas à deviner (§6.2, §6.3) |
| c | Vocabulaire exact de `session_events.source` | Même raison (§6.3) |
| d | Écran et policy pour marquer un participant `excusee` | Probablement `ADM-04`/`ADM-06`, à confirmer au codage (§6.5) |
| e | Canal de diffusion de l'état partagé de séance (LiveKit data channel, Supabase Realtime, autre) | Arbitrage technique de latence/coût, pas une question de conception (§4.2) |
| f | Granularité mot-à-mot du Coran (`mot` en §4.1) | Reportée tant que le focus mot-à-mot n'est pas un P0 confirmé |

Ces six points sont volontairement laissés ouverts : les inventer ici
reviendrait à faire à la place de l'opérateur ou du codage ce que ce lot n'a
pas mandat de faire.

---

## 11. Sécurité et confidentialité (Bible §33, rappel sans changement)

Rien de neuf par rapport à ADR-008 et ADR-012, déjà en place : aucune donnée de
contact, aucune métadonnée privée ne s'affiche dans la salle simplement parce
qu'elle est disponible côté serveur. `session_peers_v` (ADR-004) et l'absence
de photo hors des contextes listés à l'ADR-012 restent la règle dans les
quatre écrans de ce lot.

---

## 12. Découpage en lots proposé (confirmé le 12 septembre 2026)

Proposition, sur le modèle de l'étape 4 — un lot, un commit, jamais en bloc.
**Découpage confirmé par l'opérateur le 12 septembre 2026** (« je t'ai donné
toutes les specs »), et N1 exécuté le jour même.

| Lot | Contenu | État |
| :-- | :--- | :--- |
| N0 | Cette spécification, l'ADR-020, la mise à jour du registre | **Fait** (`39aec71`) |
| N1 | Migration : `mushaf`/`sourate`/`page_mushaf`/`verset`, `student_reading_position`, vue ou fonction de présence dérivée | **Fait** (`a736a43`), 15 contrôles — reste à appliquer à la base réelle, `MISE-EN-SERVICE.md` §5.2 |
| N2 | `VideoSessionProvider`/`LiveKitSessionProvider` (ADR-001), pre-flight, émission de token | À faire — **c'est ici que se décide le fournisseur vidéo et ses clés**, et ici que naît la trace qui rendra `en_connexion` dérivable |
| N3 | `ELV-03`/`ENS-03`/`CTR-02` : coquille de salle, document partagé, contrôles enseignant niveau 1 | À faire — remplace le plus gros placeholder du routeur |
| N4 | Machine à états de présence : calcul, affichage, vue enseignant et élève | **Fait** (13 septembre 2026). Le calcul existait depuis N1 ; ce lot livre l'affichage — `lib/core/presence/`, `LignePresence` au catalogue, et la migration `0011` qui **borne** `presence_seance_v`, laissée sans filtre d'appelant par N1 |
| N5 | `ELV-04` : lecteur Coran, mode immersif, reprise de lecture | À faire — demande d'abord l'import du jeu de données coranique |
| N6 | Mode suivi enseignant, annotation si retenue | À faire |
| N7 | Vérifications de fin d'étape, scénarios d'acceptation, documentation | À faire |

---

## 13. Ce que la base devrait gagner (proposition, non écrite ici)

Ce tableau est une **proposition de migration**, pas une migration : elle sera
écrite et affinée au lot N1, comme `0005` l'a été au lot L1 de l'étape 4.

| Objet proposé | Rôle |
| :--- | :--- |
| `mushaf` | Une ligne en MVP-0 : Madina/Roi Fahd, Hafs (§3.1, §4.1) |
| `sourate`, `page_mushaf`, `verset` (, `mot` si retenu) | Le contenu structuré du Coran (§4.1) |
| `student_reading_position` | L'état personnel de lecture, un par élève (§4.3) |
| Vue ou fonction de présence dérivée (nom à fixer, ex. `presence_participant_v`) | Calcule les 14 états de §6.2 à partir de `session_events` et `sessions`, jamais lue directement en table brute par un écran |
| Vocabulaire étendu de `session_events.source` | Distingue sortie volontaire et perte réseau (§6.3) |
| Policy d'écriture pour `excusee`/`corrigeeManuel` | Journalisée comme toute décision administrative (§6.5) |

---

Fin de la spécification N0. Elle ne modifie aucun écran, aucune migration,
aucun code : seuls ce document, `decisions.md` (ADR-020, questions 3 et 19 du
registre) et `docs/design/README.md` §4 BIS/§9 changent à ce lot.
