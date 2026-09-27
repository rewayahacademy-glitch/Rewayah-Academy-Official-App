# TC_CONTRACT_REQUEST_F.md — Agent F, Realtime Protocol

> Baseline : **`0071557`**. Worktree `D:\RA_TC\f`, branche `teaching-core/f-realtime`.
> Destinataire : **Agent Z**. Chaque demande est ecrite pour etre appliquee **sans me reinterroger** :
> signature exacte, comportement en cas d'echec, et ce qui casse si on s'en ecarte.

---

## 0. Ce que la cartographie disait, et ce que la baseline `0071557` dit maintenant

`TEACHING_CORE_FILE_OWNERSHIP.md` et `TEACHING_CORE_BASELINE.md` §6.7 affirment, contre `550e605` :

> « Zero occurrence de `publishData`, `DataReceived`, `DataPacket`, `setMetadata` dans tout le depot. »
> « `VideoSessionProvider` n'expose **aucune primitive d'envoi**. »

**Ce n'est plus vrai.** Le chantier enseignant a livre, dans `0071557`, un premier canal de donnees :

| Ce qui existe desormais | Ou |
|---|---|
| `const String sujetContenuPresente = 'contenu-presente';` | `lib/core/video/video_session_provider.dart:246` |
| `class ContenuPresente` (page, sourate, verset, presentePar, emisLe) | idem `:262` |
| `Stream<ContenuPresente> get contenusPresentes;` | idem `:378` |
| `Future<void> presenterContenu(ContenuPresente contenu);` | idem `:388` |
| `local.publishData(..., reliable: true, topic: sujetContenuPresente)` | `livekit_session_provider.dart:314` |
| `..on<lk.DataReceivedEvent>(_recevoirDonnees)` | idem `:205` |
| Republication de l'etat apres `RoomReconnectedEvent` | idem `:189` |

**La demande d'Agent F change donc de nature.** Elle n'est plus « ajoutez un canal de donnees » mais
**« generalisez celui qui existe »**. Le socle actuel transporte :

- **un** sujet (`contenu-presente`),
- **une** charge typee (page / sourate / verset),
- **un** canal (`reliable: true` en dur),
- **en diffusion** (aucun `destinationIdentities`),
- et **jette a la reception tout paquet d'un autre sujet** (`_recevoirDonnees`, premiere ligne).

Le protocole pedagogique a besoin des quatre autres dimensions. La section 1 les demande.

### Ce qui n'est PAS demande, et qu'il ne faut pas re-verifier

- **Le droit d'emettre.** `autoriser_jeton_video()` calcule `v_publier_data := (role = 'teacher')`,
  `supabase/functions/_shared/livekit.ts:103` le pose en `canPublishData`, et
  `CapacitesSalle.peutPublierDonnees` l'expose en Dart. **La chaine est complete de bout en bout.**
- **La metadata participant.** `livekit.ts:86` pose `metadata = {"role": ...}` et rien d'autre.
  Agent F **ne demande aucun champ supplementaire** : aucune PII ne doit y entrer, et le protocole
  n'en a pas besoin — il porte lui-meme son emetteur.
- **`presenterContenu` / `contenusPresentes`.** A conserver **tels quels**. Le protocole pedagogique
  ne passe pas par eux (test : `adaptateur_transport_livekit_test.dart`,
  « aucun paquet ne part par la primitive coranique du socle »). Deux protocoles, deux sujets,
  aucune lecture croisee.

---

## 1. DEMANDE DART 1 — generaliser le canal de donnees du socle

**Fichier :** `lib/core/video/video_session_provider.dart` **[PROTECTED]** — Agent Z uniquement.
**Nature :** ajout pur. Aucune signature existante n'est modifiee ni supprimee.

### 1.1 Les deux types a ajouter

```dart
/// Un paquet de donnees applicatif recu de la salle.
///
/// Le socle ne le decode pas : il transporte des octets sous un sujet nomme.
@immutable
class PaquetDonnees {
  const PaquetDonnees({
    required this.sujet,
    required this.charge,
    required this.fiable,
    this.emetteurIdentite,
  });

  /// Le sujet nomme du paquet. Chaine vide quand l'emetteur n'en a pose aucun.
  final String sujet;

  /// Les octets recus, tels quels.
  final List<int> charge;

  /// Vrai quand le paquet est arrive par le canal fiable.
  ///
  /// Voir la QUESTION OUVERTE Q1 : LiveKit ne le dit pas a la reception.
  final bool fiable;

  /// L'identite du participant emetteur, telle que le jeton l'a inscrite.
  /// `null` quand le paquet vient du serveur ou que le SDK ne la donne pas.
  /// **Elle ne decide d'aucun droit** : la barriere est le jeton signe.
  final String? emetteurIdentite;
}

/// Pourquoi une publication de donnees n'a pas eu lieu.
enum MotifEchecPublication {
  /// Le jeton signe n'accorde pas `can_publish_data` a l'appelant.
  droitRefuse,

  /// Aucune salle ouverte.
  horsSalle,

  /// Le transport a refuse le paquet.
  transport,
}

/// L'echec d'une publication de donnees.
class EchecPublicationDonnees implements Exception {
  const EchecPublicationDonnees(this.motif, [this.detail]);

  final MotifEchecPublication motif;
  final String? detail;

  @override
  String toString() =>
      'EchecPublicationDonnees($motif${detail == null ? '' : ', $detail'})';
}
```

### 1.2 Les trois membres a ajouter a `VideoSessionProvider`

```dart
abstract interface class VideoSessionProvider {
  // ... les membres existants, inchanges ...

  /// Pose un paquet de donnees applicatif sur le canal de la salle.
  ///
  /// [fiable] a `true` : ordonne et garanti. A `false` : perte acceptee, pour
  /// ce qui doit etre FRAIS plutot que complet — un pointeur, un apercu de
  /// trait. Exiger une garantie de livraison pour trente paquets par seconde
  /// encombrerait le canal qui porte les tours de page.
  ///
  /// [destinataires] vide vaut diffusion a toute la salle ; sinon le paquet
  /// n'est remis qu'a ces identites (rappel discret).
  ///
  /// **Leve [EchecPublicationDonnees]. N'avale JAMAIS.** C'est la seule
  /// difference de contrat avec [presenterContenu], qui refuse en silence, et
  /// elle est exigee : `PortRappelDiscret` (CONTRACTS section 12) impose
  /// « un message n'apparait QUE si l'envoi echoue ». Un appelant ne peut pas
  /// savoir qu'un envoi a echoue si la primitive se tait.
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  });

  /// Les paquets de donnees recus, **tous sujets confondus**.
  ///
  /// Flux de diffusion, **sans rejeu** : contrairement a [contenusPresentes],
  /// il ne rend pas le dernier paquet a un nouvel abonne. La reprise d'etat
  /// d'Agent F ne passe pas par le realtime mais par le backend
  /// (`PortEtatPartagePersistant`), conformement a la spec ligne 1200.
  ///
  /// Il livre aussi les paquets de sujet `contenu-presente` : chaque
  /// consommateur filtre son propre sujet, et le protocole coranique garde en
  /// plus son flux typé [contenusPresentes]. Un paquet vu sur deux flux
  /// distincts ne gene personne ; un paquet jete silencieusement, si.
  Stream<PaquetDonnees> get donneesRecues;

  /// L'acces courant, ou `null` hors salle.
  ///
  /// Le lot F en lit **uniquement** `capacites` et n'invente rien. Sans lui,
  /// un adaptateur feature-level ne peut pas savoir s'il a le droit d'emettre
  /// et doit se faire repasser le `AccesSalle` par l'ecran, ce qui multiplie
  /// les endroits ou il peut diverger.
  AccesSalle? get accesCourant;
}
```

### 1.3 L'implementation attendue dans `LiveKitSessionProvider` **[PROTECTED]**

Le SDK fait deja tout ; il s'agit de trois traductions. Verifie contre `livekit_client 2.12.0`.

```dart
final StreamController<PaquetDonnees> _donnees =
    StreamController<PaquetDonnees>.broadcast();

@override
Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

@override
AccesSalle? get accesCourant => _acces;

@override
Future<void> publierDonnees({
  required String sujet,
  required List<int> charge,
  required bool fiable,
  List<String> destinataires = const <String>[],
}) async {
  final AccesSalle? acces = _acces;
  if (acces == null) {
    throw const EchecPublicationDonnees(MotifEchecPublication.horsSalle);
  }
  if (!acces.capacites.peutPublierDonnees) {
    throw const EchecPublicationDonnees(MotifEchecPublication.droitRefuse);
  }
  final lk.LocalParticipant? local = _salle?.localParticipant;
  if (local == null) {
    throw const EchecPublicationDonnees(MotifEchecPublication.horsSalle);
  }
  try {
    await local.publishData(
      charge,
      reliable: fiable,
      topic: sujet,
      destinationIdentities: destinataires.isEmpty ? null : destinataires,
    );
  } catch (e) {
    throw EchecPublicationDonnees(MotifEchecPublication.transport, '$e');
  }
}
```

**Et la seule modification d'une methode existante** — `_recevoirDonnees`, qui jette aujourd'hui tout
sujet etranger des sa premiere ligne :

```dart
void _recevoirDonnees(lk.DataReceivedEvent evenement) {
  final String sujet = evenement.topic ?? '';
  // AJOUT : tout paquet est relaye, avant le traitement specifique du socle.
  if (!_donnees.isClosed) {
    _donnees.add(PaquetDonnees(
      sujet: sujet,
      charge: evenement.data,
      fiable: sujet != sujetProtocolePedagogiqueEphemere,  // voir Q1
      emetteurIdentite: evenement.participant?.identity,
    ));
  }
  if (sujet != sujetContenuPresente) {
    return;   // INCHANGE a partir d'ici
  }
  // ... corps existant, mot pour mot ...
}
```

Ne pas oublier `await _donnees.close();` dans `liberer()`, a cote des quatre `close()` existants.

### 1.4 QUESTION OUVERTE Q1 — LiveKit ne dit pas par quel canal un paquet est arrive

**Fait verifie, pas une supposition.** Dans `livekit_client 2.12.0`, `DataReceivedEvent` porte
**exactement trois champs** : `participant`, `data`, `topic`. Le `DataPacket_Kind`
(`RELIABLE` / `LOSSY`) est choisi a l'emission (`local.dart`, `publishData`) et **n'est pas remonte
au recepteur**.

**Consequence :** `PaquetDonnees.fiable` ne peut pas etre lu du SDK. La seule reconstitution possible
est de **porter le canal dans le sujet** :

```dart
const String sujetProtocolePedagogique = 'tc-pedagogique';          // fiable
const String sujetProtocolePedagogiqueEphemere = 'tc-pedagogique-l'; // ephemere
```

L'adaptateur fait la correspondance dans les deux sens ; le protocole, lui, ne connait qu'un sujet et
un canal. **Ne pas mettre le canal dans l'enveloppe du message** : il faudrait alors decoder chaque
paquet de pointeur avant de savoir s'il nous concerne, trente fois par seconde, pour rien.

**Arbitrage demande a Agent Z :** valider cette convention de suffixe, ou dire qu'il prefere un champ
`fiable` porte autrement. Le lot F n'en depend pas — son port `PortTransportDonnees` expose deja
`canal` explicitement, et c'est l'adaptateur LiveKit, non le protocole, qui absorbera la convention.

---

## 2. DEMANDE DART 2 — inscrire au contrat quatre surfaces nommees mais non specifiees

`TEACHING_CORE_CONTRACTS.md` **nomme** ces surfaces sans jamais en donner la signature. Trois agents
(D, E, F) ecrivent contre elles. Voici les formes publiees par Agent F, a inscrire telles quelles.

### 2.1 `MessagePedagogique` et `CanalFiabilite`

Annonces en CONTRACTS section 9 et section 17, **jamais definis**. Agent D a du en ecrire un double
local (`TC_CONTRACT_REQUEST_D.md` section 2) pour compiler. **La forme d'Agent F est identique a
celle d'Agent D, au caractere pres** — verifie ligne a ligne contre
`D:\RA_TC\d\lib\core\tc_outils\ports_externes\port_realtime_pedagogique.dart`.

Chemin canonique : `lib/core/tc_realtime/port_realtime_pedagogique.dart`.

```dart
enum CanalFiabilite { fiable, ephemere }

@immutable
class MessagePedagogique {
  const MessagePedagogique({
    required this.type,            // 'tc.<domaine>.<evenement>'
    required this.sessionId,
    required this.emetteurProfilId,
    required this.charge,          // Map<String, dynamic>, serialisable
    required this.emisLeUtc,       // UTC ; DATE le message, ne l'ORDONNE pas
  });
  final String type;
  final String sessionId;
  final String emetteurProfilId;
  final Map<String, dynamic> charge;
  final DateTime emisLeUtc;
}
```

**Pourquoi une enveloppe plate plutot qu'une hierarchie scellee :** le transport n'a pas a connaitre
les types qu'il porte. Agent D ajoute `tc.outils.masquage` sans qu'une ligne du lot F change, et
c'est exactement ce que la regle « Agent D ne transporte pas lui-meme les strokes » demande.

**Espaces de noms des types, pour qu'aucun agent n'ecrase celui d'un autre :**
`tc.etat_partage.*` et `tc.realtime.*` (F) · `tc.outils.*` (D).

### 2.2 `PortEtatPartagePersistant`

Nomme dans `TEACHING_CORE_FILE_OWNERSHIP.md` (« Ports produits : `PortRealtimePedagogique`,
`PortEtatPartage`, `PortEtatPartagePersistant` »), **absent de CONTRACTS**.
Chemin canonique : `lib/core/tc_etat_partage/port_etat_partage_persistant.dart`.

```dart
abstract class PortEtatPartagePersistant {
  Future<SharedContentState?> lire(String sessionId);
  Future<SharedContentState> enregistrer(SharedContentState etat);
  Future<void> effacer(String sessionId);
}

enum MotifEchecEtatPartage { revisionObsolete, droitRefuse, reseau, persistanceAbsente }

class EchecEtatPartage implements Exception {
  const EchecEtatPartage(this.motif, {this.revisionStockee});
  final MotifEchecEtatPartage motif;
  final int? revisionStockee;
}
```

### 2.3 `PortTransportDonnees`

Port **interne au lot F**, non annonce ailleurs. Il n'a pas besoin d'etre inscrit au contrat
partage ; il est mentionne ici pour qu'Agent Z sache par ou brancher l'implementation complete :
`lib/core/tc_realtime/port_transport_donnees.dart`. Le jour ou la demande 1 est appliquee, **un seul
fichier change** : `adaptateur_transport_livekit.dart`.

### 2.4 Ecart signale, non corrige : `SharedContentState` n'est pas `const`

CONTRACTS section 9 ecrit la classe `@immutable`. Elle l'est. Mais son constructeur **ne peut pas
etre `const`** : `updatedAtUtc` est un `DateTime`, et l'assertion qui garantit `isUtc` est un appel
de getter, donc pas une expression constante. Le constructeur est `@immutable` sans `const`.
Meme nature d'ecart que celui d'Agent B sur `ContentPosition._()`.

---

## 3. DEMANDE SQL — la persistance de `SharedContentState`

> **Aucune migration n'est ecrite par Agent F** (decision D-12). Derniere migration existante :
> **`0029`**. La premiere libre est `0030`. Ce qui suit est la demande, pas le fichier.

### 3.1 Pourquoi elle est bloquante

Sans elle, **l'exigence centrale de la mission n'est pas tenue en production** : « un late joiner ou
une reconnexion doit pouvoir recuperer l'etat COURANT sans dependre de l'historique des messages
realtime » (spec ligne 1200). LiveKit ne conserve aucun paquet — le socle l'ecrit deja en clair dans
`LiveKitSessionProvider` : « le serveur n'a garde aucun paquet de donnees ».

Aujourd'hui, `EtatPartageMemoire` tient lieu de magasin : il ne survit **ni a un redemarrage, ni a un
second appareil, ni a un second processus**. Le protocole est complet et prouve ; c'est sa seule
dependance manquante.

### 3.2 La table

**Table existante qu'elle etend : aucune.** Verifie : zero occurrence de `shared_content`,
`etat_partage` ou `session_shared` dans `supabase/`. `student_reading_position` (0007) est **la
mauvaise table** : son commentaire normatif porte l'invariant **J2** — elle ne reference aucune
seance, et « une page tournee par l'enseignant pour toute la classe ne doit jamais l'ecrire ».
La position de **groupe** est un stockage distinct. C'est celui-ci.

```sql
-- 0030_etat_partage_seance.sql  (ecrit par Agent Z, jamais par Agent F)

create table public.session_shared_content (
  session_id            uuid primary key
                          references public.sessions(id) on delete cascade,
  resource_id           uuid        not null,
  resource_version_id   uuid,
  content_position      jsonb       not null,
  content_range         jsonb,
  display_mode          text        not null
                          check (display_mode in ('page', 'verse', 'focus')),
  hidden_ranges         jsonb       not null default '[]'::jsonb,
  semantic_markers      jsonb       not null default '[]'::jsonb,
  group_resume_position jsonb,
  revision              integer     not null check (revision >= 0),
  updated_by            uuid        not null references public.profiles(id),
  updated_at            timestamptz not null default now()
);

-- Une seule ligne par seance : l'etat COURANT, pas un journal. C'est ce qui
-- permet a un arrivant tardif de se mettre a jour avec UNE lecture.
-- La monotonie de `revision` est tenue par la RPC ci-dessous, PAS par le
-- client : une contrainte entre clients polis n'est pas une garantie.
```

**Pourquoi une seule ligne et pas un journal :** chaque revision porte l'etat **entier**. Recevoir la
revision 9 sans avoir vu 6, 7 ni 8 suffit. Conserver l'historique servirait a rejouer, et le rejeu
est exactement ce que la spec interdit.

### 3.3 La RPC d'ecriture — c'est elle qui rend la monotonie garantie

```sql
create or replace function public.publier_etat_partage(
  p_session_id            uuid,
  p_resource_id           uuid,
  p_resource_version_id   uuid,
  p_content_position      jsonb,
  p_content_range         jsonb,
  p_display_mode          text,
  p_hidden_ranges         jsonb,
  p_semantic_markers      jsonb,
  p_group_resume_position jsonb,
  p_revision              integer
) returns public.session_shared_content
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ligne public.session_shared_content;
begin
  -- 1. Le droit. Decide ICI, jamais cote client.
  if not public.session_belongs_to_teacher(p_session_id, auth.uid())
     and public.app_role() <> 'admin' then
    raise exception 'insufficient_privilege' using errcode = '42501';
  end if;

  -- 2. La monotonie. `where revision < p_revision` est la garantie :
  --    un paquet hors ordre, un duplicata ou un second appareil en retard
  --    n'ecrasent rien.
  insert into public.session_shared_content as c (
    session_id, resource_id, resource_version_id, content_position,
    content_range, display_mode, hidden_ranges, semantic_markers,
    group_resume_position, revision, updated_by, updated_at
  ) values (
    p_session_id, p_resource_id, p_resource_version_id, p_content_position,
    p_content_range, p_display_mode, p_hidden_ranges, p_semantic_markers,
    p_group_resume_position, p_revision, auth.uid(), now()
  )
  on conflict (session_id) do update
    set resource_id           = excluded.resource_id,
        resource_version_id   = excluded.resource_version_id,
        content_position      = excluded.content_position,
        content_range         = excluded.content_range,
        display_mode          = excluded.display_mode,
        hidden_ranges         = excluded.hidden_ranges,
        semantic_markers      = excluded.semantic_markers,
        group_resume_position = excluded.group_resume_position,
        revision              = excluded.revision,
        updated_by            = excluded.updated_by,
        updated_at            = excluded.updated_at
    where c.revision < excluded.revision
  returning * into v_ligne;

  -- 3. Course perdue : on rend la ligne stockee, l'appelant relit et repart.
  if v_ligne.session_id is null then
    select * into v_ligne from public.session_shared_content
      where session_id = p_session_id;
  end if;

  return v_ligne;
end;
$$;
```

Le client distingue les deux cas en comparant `v_ligne.revision` a `p_revision` : egales, l'ecriture
a eu lieu ; inferieure, c'est `MotifEchecEtatPartage.revisionObsolete` avec `revisionStockee`.

### 3.4 RLS

```sql
alter table public.session_shared_content enable row level security;

-- Lecture : tout participant inscrit a la seance, y compris l'observateur
-- masque. C'est la lecture du LATE JOINER.
create policy ssc_participant_read on public.session_shared_content
  for select to authenticated using (
    public.app_account_valid()
    and exists (
      select 1 from public.session_participants sp
      where sp.session_id = session_shared_content.session_id
        and sp.profile_id = auth.uid()
        and sp.deleted_at is null
    )
  );

create policy ssc_admin_read on public.session_shared_content
  for select to authenticated using (public.app_role() = 'admin');

-- AUCUNE policy d'ecriture directe : l'ecriture passe par la RPC, qui est le
-- seul endroit ou la monotonie est tenue.
```

### 3.5 Les deux regles de securite a repeter, mot pour mot

1. **Jamais `grant execute` a `agent_ro` sur `publier_etat_partage`.** C'est une RPC volatile et
   d'ecriture ; `get_advisors` ne detecte pas ce defaut. Un `grant select` sur la table a `agent_ro`
   est acceptable **si et seulement si** la vue d'exposition repete le filtre d'appelant.
2. **Toute vue d'exposition nouvelle repete le filtre d'appelant et le masquage
   `agent_identite_masquee()` colonne par colonne.** Le motif est duplique a la main dans le depot :
   une surface oubliee est une fuite avec une banniere devant.

### 3.6 Ce que la table ne porte PAS, et ne doit jamais porter

Ni telephone, ni courriel, ni adresse, ni identite de tuteur, ni nom de famille, ni geolocalisation,
ni identifiant d'appareil. `updated_by` est un `profile_id` — l'identite que le jeton LiveKit porte
deja. Un test contractuel fige la liste des cles encodees
(`codec_etat_partage_test.dart`, « aucune donnee sensible ne figure dans la charge encodee »).

---

## 4. DEPENDANCE DEMANDEE

**Aucune.** `pubspec.yaml` reste gele (decision D-11).

Ce qui a ete essaye avec l'existant avant de conclure :

- **`package:async` (`StreamGroup`, `StreamQueue`)** aurait simplifie le pont entre la lecture de
  depart et le flux vivant dans `PortEtatPartage.suivre`. Remplace par un `StreamController` a
  `onListen` / `onCancel` explicites, sans dependance. 30 lignes, testees.
- **Un moteur de serialisation** (`json_serializable`, `freezed`). Remplace par des fonctions libres
  dans `codec_etat_partage.dart` et `codec_message_pedagogique.dart`. Le codec **devait** de toute
  facon vivre hors des classes de contrat : les stuber avec des methodes les ferait diverger du
  canonique, ce que le controle pre-merge traite en BLOCKER.
- **Realtime Supabase** (`.channel`, `onPostgresChanges`). Ecarte : il n'est utilise nulle part dans
  `lib/`, ce serait un **second systeme temps reel** a cote de LiveKit, et l'interdiction de la spec
  vise precisement cela.

## 5. ICONES DEMANDEES

**Aucune.** Le lot F n'a pas d'interface.

## 6. LIBELLES

Deux, deposes dans `docs/teaching-core/i18n/tc_i18n_F.json`, sous-arbre `tc.realtime.*`, avec leur
facade `lib/core/tc_realtime/libelles_tc_realtime.dart`. Ils nomment deux etats **d'echec** que seul
le protocole connait ; il n'y a aucun libelle de reussite, une presentation qui arrive etant
visible par elle-meme.

---

## 7. Recapitulatif pour Agent Z

| # | Demande | Fichier / objet | Bloquant ? |
|---|---|---|---|
| 1 | `publierDonnees`, `donneesRecues`, `accesCourant`, `PaquetDonnees`, `EchecPublicationDonnees` | `lib/core/video/video_session_provider.dart` **[P]** | **Oui** — sans elle, rien n'est emis en production |
| 1' | Relayer tout sujet dans `_recevoirDonnees`, fermer `_donnees` dans `liberer()` | `lib/core/video/livekit_session_provider.dart` **[P]** | **Oui** |
| Q1 | Arbitrer la convention de suffixe de sujet pour le canal ephemere | convention | Non — l'adaptateur absorbe |
| 2 | Inscrire `MessagePedagogique`, `CanalFiabilite`, `PortEtatPartagePersistant` au contrat | `TEACHING_CORE_CONTRACTS.md` | Non — formes deja alignees D/F |
| 3 | `session_shared_content` + `publier_etat_partage()` + RLS | migration `0030` | **Oui** — sans elle, pas de reprise d'etat reelle |
| 4 | Dependance | aucune | — |
| 5 | Icone | aucune | — |
| 6 | Fusion slang de `tc.realtime.*` (2 clefs) | `assets/i18n/fr.i18n.json` | Non |
