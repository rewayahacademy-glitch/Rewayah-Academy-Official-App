# TC_AGENT_F_REPORT.md — Realtime Protocol

> Worktree `D:\RA_TC\f`, branche `teaching-core/f-realtime`, baseline **`0071557`**.
> Lu par un controleur adversarial qui relancera les commandes. Ce qui est declare vert l'est ;
> ce qui ne l'est pas est ecrit en section 6.

---

## 1. Verdict en une page

| | |
|---|---|
| `flutter analyze lib test` | **propre** (« No issues found ») |
| `flutter test test/teaching_core/f` | **61 tests, tous verts** |
| Fichiers hors ownership modifies | **aucun** |
| Migration creee | **aucune** (decision D-12) |
| Dependance ajoutee | **aucune** (decision D-11) |
| Second fournisseur WebRTC | **aucun** |
| Second systeme de presence | **aucun** |
| `assets/i18n/fr.i18n.json` touche | **non** (decision D-03) |

**Ce qui marche de bout en bout, prouve :** la separation fiable / ephemere, l'ordonnancement par
revision (duplicata, hors ordre, lacune), la restauration d'etat a l'arrivee tardive et a la
reconnexion, le rappel discret cible, la projection des capacites.

**Ce qui ne marche pas en production, et pourquoi :** le socle n'expose pas encore la primitive
d'envoi generalisee, et la table d'etat durable n'existe pas. Les deux sont demandees, signature et
SQL exacts, dans `TC_CONTRACT_REQUEST_F.md`. Detail en section 6.

---

## 2. L'audit d'abord, comme la mission le demande

J'ai relu `docs/parallel-reports/02-livekit-audit.md` **plutot que d'en produire un troisieme**, puis
les quatre fichiers de `lib/core/video/` dans la baseline `0071557`.

### Ce que j'ai trouve, et qui contredit la cartographie

`TEACHING_CORE_BASELINE.md` §6.7 ecrit, contre `550e605` :

> « Zero occurrence de `publishData`, `DataReceived`, `DataPacket`, `setMetadata` dans tout le
> depot » — « `VideoSessionProvider` n'expose aucune primitive d'envoi ».

**Faux depuis `0071557`.** Le chantier enseignant a livre un premier canal de donnees complet :
`sujetContenuPresente`, `ContenuPresente`, `contenusPresentes`, `presenterContenu`,
`local.publishData(..., reliable: true, topic: ...)` et un `DataReceivedEvent` branche. Il republie
meme l'etat apres `RoomReconnectedEvent`.

**Ce que j'en ai fait :** je n'ai rien recree. Ce qui manque au socle n'est pas *un canal*, ce sont
**quatre dimensions** de celui qui existe : le canal ephemere (`reliable` est en dur a `true`), le
sujet libre (le recepteur jette tout sujet autre que `contenu-presente` des sa premiere ligne),
l'envoi adresse (aucun `destinationIdentities`), et la lecture des capacites signees depuis le
moteur (`_acces` est prive, sans accesseur). La demande d'extension est ecrite en consequence : un
**ajout**, pas une refonte, avec le corps d'implementation deja redige.

### Ce que j'ai reutilise, et ce que j'ai refuse de reutiliser

| Capacite existante | Ce que j'en fais |
|---|---|
| `moteurSalleProvider` (Provider **racine**) | Consomme par adaptateur. **Aucune seconde `Room`, aucun import de `livekit_client`** dans mon perimetre. |
| `EtatSalle.retabli` | **Le seul declencheur de restauration d'etat.** Le socle distingue deja cet etat de `connecte` pour cette raison exacte, et son commentaire le dit : « republier l'etat pedagogique en cours ». |
| `EtatSalle.instable` | Traduit en `EtatTransport.ouvert`, **pas** en coupure. « La seance continue, rien ne se demonte » : le traiter comme une coupure relirait le backend a chaque sursaut reseau. Test dedie. |
| `AccesSalle.capacites` | **Recopiees**, jamais deduites. Aucune capacite n'est calculee cote client. |
| `sujetContenuPresente` | Lu pour **l'ecarter** : les deux protocoles coexistent sur le meme canal sans se lire l'un l'autre. Test dedie. |
| `presenterContenu` | **Refuse volontairement.** Le mode d'affichage, la plage de travail, les plages masquees et les marqueurs n'y tiennent pas : la classe suivrait les tours de page en perdant le reste **en silence**. Un test verifie qu'aucun paquet du lot F n'y passe. |
| `lib/core/presence/` | **Pas touche.** Aucun systeme de presence concurrent. |
| Le patron de faux de `test/features/salle_test.dart` | Reproduit dans `test/teaching_core/f/faux/`, sans ecrire dans `test/support/` (D-06). |

---

## 3. Ce qui a ete construit

### 3.1 `lib/core/tc_realtime/` — le protocole

| Fichier | Role |
|---|---|
| `port_realtime_pedagogique.dart` | **Contrat canonique** (CONTRACTS section 9) : `PortRealtimePedagogique`, `CanalFiabilite`, `CapacitesPedagogiques`, `MessagePedagogique`. |
| `types_message.dart` | Les types de messages possedes par F, le sujet de transport, `CauseRevision`, et les fabriques de messages `eleve actif` et `rappel discret`. |
| `codec_message_pedagogique.dart` | Enveloppe / desenveloppe un message. Clefs d'une lettre, comme `ContenuPresente`. Empreinte pour la deduplication. |
| `port_transport_donnees.dart` | **Le port de transport** : deux canaux, un sujet, des destinataires, des capacites, un etat. C'est lui qui isole tout le lot de LiveKit. |
| `service_realtime_pedagogique.dart` | **Le coeur** : routage par canal, deduplication du fiable seulement, projection des capacites. Ne connait pas LiveKit. |
| `adaptateur_transport_livekit.dart` | Le transport pose sur `VideoSessionProvider`. Plan de controle vivant, plan de donnees declare **absent et nomme**. |
| `transport_memoire.dart` | `BusMemoire` + `TransportMemoire` : le double complet contre lequel le lot est prouve. Vit dans `lib/` pour qu'Agent E et Agent Q s'en servent sans le recopier. |
| `transport_indisponible.dart` | L'etat « hors salle », qui est la situation la plus frequente du produit. |
| `providers_tc_realtime.dart` | Le cablage Riverpod. Un seul point a surcharger. |
| `libelles_tc_realtime.dart` | Deux libelles d'echec, facade D-03. |

### 3.2 `lib/core/tc_etat_partage/` — l'etat partage

| Fichier | Role |
|---|---|
| `shared_content_state.dart` | **Contrat canonique** (CONTRACTS section 9) + `ModeAffichagePartage` + `suivante()`, qui interdit a l'appelant de choisir son numero de revision. |
| `reducteur_etat_partage.dart` | **L'ordonnanceur, pur** : aucune E/S, aucune horloge, aucun flux. Toute la discipline d'ordre du lot tient ici. |
| `codec_etat_partage.dart` | L'etat en JSON, **entier, jamais en delta**. Clefs alignees sur celles d'Agent D. |
| `port_etat_partage.dart` | **Contrat canonique** : `etatCourant`, `suivre`, `publier`, `restaurer`. |
| `port_etat_partage_persistant.dart` | Le port de persistance (nomme par OWNERSHIP, absent de CONTRACTS — voir la demande). |
| `etat_partage_memoire.dart` | Le **bouchon declare** en attendant la table `0030`. |
| `service_etat_partage.dart` | Le flux, la publication, la restauration. |
| `providers_tc_etat_partage.dart` | Le cablage Riverpod. |
| `ports_externes/` | Trois stubs `// TC-STUB-PORT` : `ContentPosition`, `ContentRange` (Agent B, AMENDEMENT 1), `MarqueurSemantique` + `IntentionPedagogique` (Agent D). |

### 3.3 Les trois decisions de conception qui portent le lot

**1. L'etat voyage entier, jamais en delta.** Un paquet perdu, duplique ou arrive en retard se traite
alors par **une seule comparaison de revision**, sans jamais rejouer un journal. Recevoir la revision
9 sans avoir vu 6, 7 ni 8 est parfaitement exploitable. C'est ce qui permet a un arrivant tardif de
se mettre a jour avec **un seul message**, et c'est la raison pour laquelle le lot n'a besoin
d'aucun historique — l'exigence de la spec ligne 1200.
*Plafond assume :* la taille du paquet fiable. Si les plages masquees et les marqueurs d'une seance
le depassaient un jour, la voie serait de **ne plus les transporter du tout** et de laisser le late
joiner les relire par le port de persistance. Surtout pas de passer en delta.

**2. Le backend d'abord, la diffusion ensuite.** L'ordre est porteur d'information, exactement comme
`annoncerSortie` avant `quitter()` dans la salle existante. Backend puis diffusion : si la diffusion
echoue, les connectes sont en retard d'une revision **mais un arrivant tardif obtient la bonne**.
Diffusion puis backend : les connectes voient un etat qu'aucun arrivant ne verra jamais. Le second
cas est le seul des deux qui produise **deux verites**.

**3. Le transport ne connait pas ce qu'il porte.** Le lot F route les types d'Agent D (`tc.outils.*`)
sans les declarer ni les decoder. Agent D peut ajouter `tc.outils.masquage` sans qu'une ligne du lot
F change — et c'est exactement ce que la regle « Agent D ne transporte pas lui-meme les strokes »
demande.

---

## 4. Les dix contrats de la mission, et ou ils sont

| Contrat exige (spec « PROMPT F ») | Ou | Canal |
|---|---|---|
| shared content state changed | `typeRevisionEtatPartage`, `ServiceEtatPartage.publier` | fiable |
| page / ayah / range changed | meme revision, `CauseRevision.position` / `.plage` | fiable |
| display mode changed | meme revision, `CauseRevision.mode` | fiable |
| pointer ephemeral | type d'Agent D (`tc.outils.pointeur`), route tel quel | **ephemere** |
| annotation stroke preview | type d'Agent D (`tc.outils.trait_en_cours`) | **ephemere** |
| annotation stroke committed | type d'Agent D (`tc.outils.trait_termine`) | fiable |
| active student changed | `messageEleveActif`, `typeEleveActif` | fiable |
| discreet nudge targeted | `messageRappelDiscret` + `emettreCible` | fiable, **adresse** |
| session role/capability projection | `ServiceRealtimePedagogique.capacites` | — |
| reconnect state restoration | `ServiceEtatPartage.restaurer` sur `EtatTransport.retabli` | **backend, pas realtime** |

---

## 5. Les tests — 61, tous verts

```
flutter test test/teaching_core/f     ->  +61: All tests passed!
```

| Fichier | Ce qu'il prouve |
|---|---|
| `reducteur_etat_partage_test.dart` (12) | revision 0 acceptee · revision croissante · **duplicata ecarte** · **hors ordre ecarte** · lacune exploitable · seance etrangere refusee · `restaurer(null)` n'efface rien · **une lecture de backend en retard n'ecrase pas le temps reel** · `suivante()` distingue « ne touche pas » de « retire » |
| `codec_etat_partage_test.dart` (10) | aller-retour complet · les quatre ancrages · mode inconnu -> `null` **sans repli** · revision negative -> `null` · **un marqueur illisible ne fait perdre que lui** · plage incomparable -> `null` · fraction hors bornes -> `null` · **aucune donnee sensible dans la charge** (liste de clefs figee) |
| `protocole_canaux_test.dart` (15) | **fiable et ephemere ne se melangent jamais** (deux tests croises) · **perdre 30 paquets ephemeres ne coute rien au fiable** · duplicata ecarte sur fiable / conserve sur ephemere · paquet illisible ne ferme pas le canal · seance etrangere ignoree · **sujet `contenu-presente` ignore** · **rappel discret : seul le destinataire le recoit** · la charge du rappel ne porte que l'`academy_id` · envoi sans droit **leve** · capacites projetees enseignant / eleve / controleur / hors salle |
| `etat_partage_seance_test.dart` (15) | **le durable est ecrit AVANT la diffusion** · l'emetteur voit son etat par le meme chemin · revision obsolete refusee sans rien ecrire · **arrivee tardive avec le reseau realtime coupe** · `etatCourant` lit le backend · **reconnexion : `retabli` restaure ce qui a ete manque** · **`instable` ne declenche aucune restauration** · backend en retard n'ecrase pas · **hors ordre ne fait jamais reculer la classe** · etat illisible garde l'etat courant · cause deduite · panne de lecture remontee |
| `adaptateur_transport_livekit_test.dart` (9) | partiel declare comme tel · capacites recopiees du jeton · traduction des etats de salle · droit refuse avant tout · hors salle nomme · **primitive absente nommee** · **aucun paquet ne part par `presenterContenu`** |

### Deux defauts trouves en ecrivant les tests, et corriges

1. **`close()` appele depuis `onCancel` bloque indefiniment.** Le futur rendu par `close()` n'aboutit
   qu'une fois `onCancel` termine ; l'attendre depuis `onCancel` est un interblocage. Une Classe Live
   quittee ne se serait **jamais** fermee. Corrige : `onCancel` n'annule que l'amont, et la sortie se
   ferme sur le `onDone` de l'amont.
2. **Un `async*` suspendu dans un `await for` ne peut pas etre annule.** L'annulation attend que le
   generateur reprenne, ce qui n'arrive jamais sur un flux silencieux. Corrige : controleur explicite
   avec `onListen` / `onCancel`. Le socle avait deja fait cette decouverte pour la presence — le
   commentaire de `presenceSeanceProvider` documente une boucle `async*` qui continuait a tourner
   apres la sortie de salle.

---

## 6. Limites — ce qui n'est PAS fait, et ce qui est bouche

**A lire avant toute integration. Rien ici n'est une surprise : tout est demande dans
`TC_CONTRACT_REQUEST_F.md`.**

1. **En production, rien n'est emis.** `AdaptateurTransportLiveKit.envoyer` leve
   `MotifEchecTransport.primitiveEnvoiAbsente` : le socle n'a pas de primitive d'envoi generalisee.
   Le transport se declare `DisponibiliteTransport.partiel`, et `capacites()` rend **tout a `false`**
   dans cet etat — Agent E n'affichera donc pas de commandes qui ne font rien. Debloque par la
   demande 1. **Tout le lot est prouve contre `TransportMemoire`, qui a les capacites que le core
   n'a pas encore.**

2. **La reception est vide sur LiveKit.** `AdaptateurTransportLiveKit.paquets()` rend un flux vide,
   pas une erreur. Meme cause, meme demande.

3. **La persistance est en memoire du processus.** `EtatPartageMemoire` ne survit ni a un
   redemarrage, ni a un second appareil, ni a un second processus. **Consequence concrete :
   l'arrivee tardive inter-appareils ne fonctionne pas tant que la migration `0030` n'est pas
   appliquee.** Le protocole, lui, est complet : le test « un arrivant obtient l etat courant SANS
   aucun message realtime » passe parce que les deux cotes partagent le meme magasin en memoire,
   ce que la table fera reellement.

4. **`PortEtatPartagePersistant` n'est pas au contrat.** Nomme dans `FILE_OWNERSHIP`, absent de
   `CONTRACTS`. Sa signature est proposee a l'inscription (demande 2.2). Si Agent Z l'amende
   differemment, **un seul fichier change** de mon cote.

5. **Q1 non tranchee : LiveKit ne dit pas par quel canal un paquet est arrive.** Verifie dans
   `livekit_client 2.12.0` : `DataReceivedEvent` porte `participant`, `data`, `topic`, **et rien
   d'autre**. Le canal doit donc etre porte par le sujet (deux sujets nommes). Le lot F n'en depend
   pas — son port expose `canal` explicitement — mais **l'adaptateur complet devra appliquer cette
   convention**, et elle est a valider par Agent Z.

6. **Les providers pointent sur `TransportIndisponible`.** C'est le bon defaut hors classe, mais
   **Agent E doit surcharger `portTransportDonneesProvider`** a l'entree en salle, avec le
   `AccesSalle` emis par `ServiceVideo.acces()` et `moteurSalleProvider`. Sans cette surcharge, le
   protocole existe et ne transporte rien. C'est le seul point de cablage.

7. **`AdaptateurTransportLiveKit` prend `profilLocalId` en parametre.** `AccesSalle` ne porte pas
   d'identite de participant, et `VideoSessionProvider` n'expose pas `_acces`. L'appelant la connait
   (sa propre session Supabase). La demande 1 inclut `accesCourant` pour supprimer un de ces deux
   detours ; l'identite en restera un.

8. **`capacites(sessionId)` n'utilise pas `sessionId`.** Un transport sert **une** salle, celle dont
   le jeton a ete emis. Le parametre reste pour respecter le contrat canonique.

9. **Plafond de la deduplication : 256 empreintes glissantes par abonnement.** Un duplicata qui
   arriverait apres 256 autres messages fiables passerait. Pour un canal qui porte des tours de page
   et des rappels, cela represente des heures. Voie de sortie si cela ne suffisait plus : un numero
   de sequence dans l'enveloppe — donc un amendement du contrat, pas une astuce locale. Marque
   `ponytail:` dans le code.

10. **`publier` leve si la diffusion echoue apres une ecriture durable reussie.** L'etat **n'est pas
    perdu** : il est en base, un arrivant tardif l'obtient, et une reconnexion resynchronise les
    connectes. Mais l'appelant qui reessaierait avec la meme revision se verrait refuser
    `revisionObsolete` — il doit **relire l'etat courant et repartir de la**, ce que
    `SharedContentState.suivante()` rend naturel. C'est un comportement assume, pas un oubli.

11. **Aucune interface, aucun golden, aucune route.** Le lot F est un protocole. Les deux seuls
    libelles produits sont des etats d'echec destines a la coque d'Agent E.

12. **Le lot n'a pas ete exerce contre un vrai serveur LiveKit.** Il ne pouvait pas l'etre : la
    primitive n'existe pas. L'audit `02-livekit-audit.md` note d'ailleurs que la salle LiveKit reelle
    n'est **pas prouvee** a ce jour.

### Defauts pre-existants croises, non corriges (hors mission)

- **`supabase/migrations/0029` est ecrite mais pas appliquee en base** (signale par
  `BASELINE_ADDENDUM.md`). Non touche.
- **`test/widgets/catalogue_galerie_test.dart` est rouge dans la baseline** (idem). **Mesure**, et
  non repris de l'addendum : `flutter test` sur tout le depot rend **`+931 -1`**, l'unique echec
  etant « La galerie est la preuve du catalogue — chaque fichier de lib/core/widgets a son entree ».
  Non touche ; aucun composant n'a ete ajoute a `lib/core/widgets/`, et le lot F n'a aucune
  interface.
- **`ContenuPresente` ordonne par horodatage d'emission**
  (`LiveKitSessionProvider._recevoirDonnees` compare `emisLe`). Deux appareils n'ont pas la meme
  horloge : un client dont l'horloge avance de quelques secondes peut faire ignorer les paquets
  suivants d'un autre. Le lot F n'a pas ce defaut — il ordonne par `revision`. **Signale, pas
  corrige** : le fichier est PROTECTED et le protocole coranique n'est pas mon perimetre.

---

## 7. Ce qu'Agent Z devra brancher, dans l'ordre

1. **Appliquer la demande 1** (`publierDonnees`, `donneesRecues`, `accesCourant`, et le relais de
   tout sujet dans `_recevoirDonnees`). Sans elle, rien n'est emis.
2. **Trancher Q1** (convention de sujet pour le canal ephemere), puis completer
   `adaptateur_transport_livekit.dart` — **un seul fichier**, deux methodes.
3. **Appliquer la migration `0030`** (`session_shared_content` + `publier_etat_partage()` + RLS),
   puis ecrire l'implementation Supabase de `PortEtatPartagePersistant` et surcharger
   `portEtatPartagePersistantProvider`. Le patron Dart existe : `EtatPartageMemoire` reproduit deja
   le refus de revision obsolete que la RPC devra tenir.
4. **Faire surcharger `portTransportDonneesProvider` par Agent E** a l'entree en salle.
5. **Supprimer les trois stubs** de `lib/core/tc_etat_partage/ports_externes/` et pointer sur les
   canoniques d'Agent B et d'Agent D.
6. **Fusionner `tc_i18n_F.json`** (2 clefs, sous-arbre `tc.realtime.*`), regenerer slang, remplacer
   `LibellesRealtime` et supprimer `libelles_tc_realtime.dart`.
7. **Inscrire au contrat** `MessagePedagogique`, `CanalFiabilite` et `PortEtatPartagePersistant`
   (demande 2), pour que le double d'Agent D cesse d'en etre un.

---

## 8. Ownership — verification

```
git status --porcelain
?? lib/core/tc_etat_partage/
?? lib/core/tc_realtime/
?? test/teaching_core/
+ docs/teaching-core/TC_AGENT_F_REPORT.md
+ docs/teaching-core/TC_CONTRACT_REQUEST_F.md
+ docs/teaching-core/i18n/tc_i18n_F.json
```

Aucun autre chemin. `flutter pub get` avait touche
`windows/flutter/generated_plugin_registrant.{cc,h}` et `generated_plugins.cmake` — fichiers generes
hors de mon perimetre, **restaures par `git checkout --`** avant le commit.
Aucune ecriture dans `D:\RA _APP\RA -OFFICIAL-APP`, ni dans un autre worktree `D:\RA_TC\<lettre>` :
les worktrees de B et de D n'ont ete ouverts **qu'en lecture**, pour verifier que mes stubs sont
identiques a leurs canoniques (AMENDEMENT 1 et AMENDEMENT 2 de `TEACHING_CORE_CONTRACTS.md`).
