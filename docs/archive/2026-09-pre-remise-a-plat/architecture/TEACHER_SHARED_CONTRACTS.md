# TEACHER_SHARED_CONTRACTS

Les interfaces que les agents A à E **consomment** pour construire le rôle
Enseignant, et qu'ils ne modifient jamais.

Produit par l'**Agent 0** le 19 septembre 2026. Base : `BASELINE_SHA = 550e605`.

> **Règle de lecture.** Tout ce qui est ici existe déjà, ou est posé par l'Agent Z
> avant le lancement des agents. Un besoin non couvert ne se comble pas en
> touchant au cœur : il s'écrit dans `docs/parallel-reports/CONTRACT_REQUEST_<AGENT>.md`.
>
> Les signatures sont **copiées du code**, avec leur fichier. Si une signature
> diffère de ce que tu lis dans le dépôt, le dépôt a raison : signale l'écart.

---

## 1. Le patron d'écran, à imiter sans exception

Tout écran du produit passe par `PageShell`. Le squelette canonique, copié de
`lib/features/admin_configuration_regles/regles_page.dart` :

```dart
class MonEcran extends ConsumerWidget {
  /// Cree l'ecran.
  const MonEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Chose>> choses = ref.watch(chosesProvider);

    return PageShell(
      titre: t.enseignant.monEcran.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          switch (choses) {
            AsyncValue<List<Chose>>(hasValue: true) => _Corps(
              choses: choses.requireValue,
            ),
            AsyncValue<List<Chose>>(hasError: true) => EmptyState(
              message: t.enseignant.monEcran.erreur,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(chosesProvider),
            ),
            _ => const Skeleton.liste(lignes: 5),
          },
        ],
      ),
    );
  }
}
```

À retenir :

- `PageShell` porte déjà le fond, la gouttière du gabarit, la largeur bornée à
  1200, **le bandeau hors ligne** et la zone d'action collée en bas. Un écran ne
  refait aucun des cinq ;
- `const PageShell({required Widget child, Key? key, String? titre, Widget? entete, Widget? actions, bool defilante = true})`
  (`lib/core/widgets/page_shell.dart:33`). `actions` est **un** `Widget`, pas une
  liste ;
- `defilante: false` quand le corps gère son propre défilement ;
- le chargement se dit par `Skeleton`, le vide et l'erreur par `EmptyState` :
  jamais un `CircularProgressIndicator` nu, jamais un `Text('erreur')` ;
- les sous-widgets d'un écran sont **privés** (`_Corps`), et le seul membre
  public est la page elle-même ;
- `ref.invalidate(provider)` est le geste de relecture ;
- aucun écran ne compare une largeur à un nombre : `AppGabarit.de(context)` le
  fait, en un seul endroit.

**Deux vocabulaires responsive coexistent** dans `app_gabarit.dart` : `Gabarit`
(mobile/tablette/desktop, seuils 600/1200) et `ClasseLargeur`
(compacte/moyenne/étendue/large, seuils 600/840/1200). Pour ce lot, **emploie
`Gabarit`** : c'est celui que la salle, les créneaux et les écrans admin
utilisent déjà. Ne mélange pas les deux dans un même écran.

---

## 2. Séances du jour

### Le contrat de l'enseignant, `ENS-02`

**Nouveau, posé par l'Agent Z.** `lib/core/enseignant/service_enseignant.dart`.

```dart
abstract interface class ServiceEnseignant {
  Future<List<SeanceEnseignant>> seances();
  Future<List<MembreSeance>> rosterDeSeance(String seanceId);
  Future<List<GroupeEnseignant>> groupes();
  Future<List<MembreSeance>> membresDuGroupe(String groupeId);
  Future<List<CahierEnRetard>> cahiersEnRetard();
  Future<BrouillonCahier?> brouillon(String seanceId);
  Future<void> deposerCahier({
    required String cleIdempotence,
    required Map<String, dynamic> contenu,
    required String seanceId,
  });
}
```

Providers, `lib/core/enseignant/service_enseignant.dart` :

| Provider | Type |
| :--- | :--- |
| `serviceEnseignantProvider` | `Provider<ServiceEnseignant>` |
| `seancesEnseignantProvider` | `FutureProvider<List<SeanceEnseignant>>` |
| `rosterSeanceProvider` | `FutureProviderFamily<List<MembreSeance>, String>` (paramètre : `seanceId`) |
| `groupesEnseignantProvider` | `FutureProvider<List<GroupeEnseignant>>` |
| `membresGroupeEnseignantProvider` | `FutureProviderFamily<List<MembreSeance>, String>` (paramètre : `groupeId`) |
| `cahiersEnRetardProvider` | `FutureProvider<List<CahierEnRetard>>` |
| `brouillonCahierProvider` | `FutureProviderFamily<BrouillonCahier?, String>` (paramètre : `seanceId`) |

### Pourquoi `seancesEnseignantProvider` et pas `seancesProvider`

`seancesProvider` (`ServicePlanning`) passe par `mes_seances_v`, qui **joint
`session_participants` et rend donc une ligne par élève**. Un cours de groupe de
cinq enfants y apparaît cinq fois. Pour la Journée d'un enseignant, emploie
`seancesEnseignantProvider`, qui lit `mes_seances_enseignant_v`, groupée par
séance.

`seancesProvider` reste juste, et reste employé par `TUT-01`, `ELV-02` et
`CTR-01`. Ne le modifie pas.

### Modèles, `lib/core/enseignant/modeles_enseignant.dart`

```dart
class SeanceEnseignant {
  final String id;
  final DateTime debut;
  final DateTime fin;
  final StatutSeance? statut;      // null = illisible, jamais un repli sur planifiee
  final int nbParticipants;
  final bool cahierDepose;
  final String? groupeId;          // null = cours individuel
  final String? groupeLibelle;
  final TypePublicGroupe? typePublic;
  final int? seuilMax;
  final int minutesInterruption;

  bool get estGroupe;              // groupeId != null
  Duration get duree;
  bool enCoursA(DateTime maintenant);
  Duration avantDebut(DateTime maintenant);
  bool get attendSonCahier;
}

class MembreSeance {
  final String studentId;
  final String identifiantImmuable;
  final String? prenom;            // null quand un agent observe : masquage en base
  final String? niveau;
  final String? riwaya;
  final DateTime? rejointLe;
  String get libelle;              // prenom, ou identifiant si masque
}

class GroupeEnseignant {
  final String id;
  final String libelle;
  final TypePublicGroupe type;
  final int seuilMax;
  final Creneau creneau;
  final int nbMembres;
  final DateTime creeLe;
  int get placesLibres;
  bool get complet;
}

class CahierEnRetard {
  final String seanceId;
  final DateTime debut;
  final DateTime fin;
  final int nbParticipants;
  final int heuresDeRetard;
  final String? groupeId;
  final String? groupeLibelle;
  bool get enRetard;               // vrai au dela de 24 h
}
```

`MembreSeance` **n'a aucun champ de nom de famille**, et c'est le point :
l'invariant ADR-008 tient par construction, il n'y a pas de champ à oublier de
masquer. `MembreGroupe` (`core/admin/service_groupes.dart`) en porte un parce que
l'administration en a le droit : **ne l'emploie pas côté enseignant.**

### Timeline de la journée

`lib/core/planning/journee.dart`, inchangé et suffisant :

```dart
enum SorteEntree { cours, pause, priere }   // l'ORDRE est le tri a heure egale

class EntreeJournee {
  EntreeJournee.cours(Seance this.seance);
  EntreeJournee.priere(InterruptionPriere this.interruption);
  const EntreeJournee.pause({required DateTime debut, required DateTime fin});
  final SorteEntree sorte;
  final DateTime debut;
  final DateTime fin;
  final Seance? seance;
  final InterruptionPriere? interruption;
  Duration get duree;
}

List<EntreeJournee> construireJournee({
  required List<Seance> seances,
  required ReglagesPriere? reglages,
  required DateTime debut,
  required DateTime fin,
  required Duration pauseMaximale,
});

Seance? prochainCours(List<Seance> seances, DateTime maintenant);
Seance? seanceAnnuleeDuJour(List<Seance> seances, DateTime maintenant);
List<InterruptionPriere> interruptionsDe(Seance seance, ReglagesPriere? reglages);
```

`construireJournee` est **le seul point d'entrée correct** pour mêler cours,
pauses et prières. Quatre features l'importent déjà. N'en écris pas une variante
locale.

Les lignes de la colonne passent par `TimelineRow`
(`const TimelineRow({required EntreeJournee entree, Key? key})`), qui décide
lui-même du libellé et de l'icône de chaque sorte.

`pauseMaximale` vient de `valeurRegleProvider`, jamais d'une constante :

```dart
typedef DemandeRegle = ({String profilId, CleRegle cle});
final FutureProviderFamily<int, DemandeRegle> valeurRegleProvider;
enum CleRegle { dureeSeance, minimumPayable, pauseEntreCours, plafondEleves }
```

### Prières

```dart
final FutureProviderFamily<ReglagesPriere?, String> reglagesPriereProvider; // enseignantId
List<InterruptionPriere> interruptionsEntre({
  required ReglagesPriere reglages, required DateTime debut, required DateTime fin,
});
String libellePriere(Priere priere);
```

---

## 3. Groupes et élèves autorisés

| Besoin | Contrat | Remarque |
| :--- | :--- | :--- |
| les élèves d'une séance | `rosterSeanceProvider(seanceId)` | lit `teacher_roster_v` |
| mes groupes | `groupesEnseignantProvider` | lit `mes_groupes_v` (migration `0025`) |
| les membres d'un groupe | `membresGroupeEnseignantProvider(groupeId)` | RPC `mon_groupe_detail` |

**N'emploie pas** `membresGroupeProvider` ni `groupesProvider`
(`core/admin/service_groupes.dart`) : ils passent par `groupe_detail()` et
`groupes_admin()`, réservées à l'administration, et la première rend un nom de
famille.

`TypePublicGroupe` existe déjà, ne le recrée pas :

```dart
enum TypePublicGroupe { enfant('enfant'), adulte('adulte') }  // 5 enfants, 6 adultes
```

⚠ **`niveau` n'est pas le niveau institutionnel.** `MembreSeance.niveau` vient de
`student_profiles.level`, un texte libre. Le niveau du programme vit dans
`progression_historique`, dont la migration n'est pas appliquée. N'écris pas
« niveau du programme » à l'écran pour cette valeur.

---

## 4. Préflight

```dart
class ResultatPreVol {
  const ResultatPreVol({
    required bool microDisponible,
    required bool cameraDisponible,
    required bool sortieAudioDisponible,
    required bool permissionRefusee,
  });
  bool get peutEntrer;
}

abstract interface class ServicePreVol { Future<ResultatPreVol> verifier(); }
final Provider<ServicePreVol> servicePreVolProvider;
final FutureProvider<ResultatPreVol> preVolProvider;
```

**Emploie `preVolProvider`**, jamais `servicePreVolProvider` en impératif : deux
chemins existaient, l'Agent Z a tranché pour le provider afin que la Journée et
la salle lisent le préflight de la même manière.

La fenêtre d'ouverture de la salle est de **dix minutes** avant l'heure, miroir
côté client de `autoriser_jeton_video` (ADR-005). La constante vivait dans
`journee_page.dart` ; l'Agent Z la remonte en `core`. **Ne la redéclare pas** :
si tu ne la trouves pas en `core`, demande-la par `CONTRACT_REQUEST`.

---

## 5. Entrée et sortie de salle

### Entrer

```dart
class BilletSalle {
  const BilletSalle({required String sessionId, required DateTime emisA});
  static const Duration duree = Duration(minutes: 20);
  bool valideA(DateTime maintenant);
}
```

On entre en salle par `GoRouter.of(context).go(Routes.salle, extra: BilletSalle(...))`.
Le billet ne voyage **jamais** dans l'URL (ADR-005) : une adresse copiée n'ouvre
rien. `deciderRedirection` refuse déjà `/salle` sans billet présentable.

### Sortir

La sortie de salle mène au **cahier de transmission**, et c'est obligatoire :

```dart
Routes.cahierPour(seanceId)   // '/enseignant/seance/<id>/cahier'
```

Le branchement de la sortie est fait par l'Agent Z dans `salle_page.dart`, qui
ne t'appartient pas.

### Dans la salle

`lib/features/salle/salle_page.dart` et `vue_salle.dart` sont **un seul écran
pour quatre rôles** (élève, enseignant, contrôleur, tuteur observateur) :
propriété de l'Agent Z, lecture seule pour tout le monde. L'agent B construit
ses surfaces dans `lib/features/salle_enseignant/` et l'Agent Z les insère en un
seul point.

Le contrat du moteur vidéo (`lib/core/video/video_session_provider.dart`) et
celui du **contenu présenté** sont posés par le socle : leurs signatures exactes
sont dans `docs/parallel-reports/SOCLE_SALLE_REPORT.md`. Interdictions
permanentes : aucun second provider vidéo, aucune réimplémentation de WebRTC,
aucun Coran transformé en PDF, image ou vidéo.

Le bandeau permanent d'enregistrement passe par `PermanentNotice`
(`lib/core/widgets/permanent_notice.dart`), verrou ADR-011 vérifié par
`tool/verifier_jetons.dart` : **personne ne le modifie, personne n'en écrit un
second.** `BandeauObservation` est déjà posé par `lib/app.dart` au-dessus de tous
les écrans.

---

## 6. Cahier de transmission

### Lire le brouillon

```dart
final AsyncValue<BrouillonCahier?> b = ref.watch(brouillonCahierProvider(seanceId));
```

```dart
class BrouillonCahier {
  final String seanceId;
  final DateTime debut;
  final DateTime fin;
  final StatutSeance? statut;
  final int dureeMinutes;               // calcule par la base
  final int minutesInterruption;
  final bool dejaDepose;
  final String? groupeId;
  final List<ParticipantBrouillon> participants;
  final List<EvenementSeance> evenements;

  List<ParticipantBrouillon> get exceptions;  // les SEULS a regarder
  bool get toutEstNominal;
}

class ParticipantBrouillon {
  final MembreSeance membre;
  final EtatPresence presence;          // deduite, jamais saisie
  final DateTime? entreLe;
  final DateTime? derniereTraceLe;
  final PositionLecture? position;      // lecture seule (invariant J2)
  final UniteCurriculum? unite;         // null si le programme n'est pas installe
  bool get estUneException;
}
```

**Le principe anti-burnout est porté par le modèle** : `exceptions` rend les
seules lignes qui demandent un regard, et `toutEstNominal` dit qu'un seul geste
suffit. Une présence `inconnu` est une exception : ne pas savoir demande un
regard autant qu'une absence, et `inconnu` n'est **jamais** affiché « absent »
(invariant J3).

`UniteCurriculum.codeTechnique` (par exemple `F1-PHO-01`) a une **interdiction UX
explicite** : il ne sert jamais de titre, seulement de sous-texte technique
discret. Le libellé à afficher est `nomHumain`.

### Rendre le cahier

```dart
class DecisionEleve {
  const DecisionEleve({
    required String studentId,
    bool confirme = true,          // le defaut, c'est « Continuer »
    String? motifException,
    String? pointPhonetique,
    String? objectifPersonnel,
    String? travailMaison,
    bool nouveauSuspendu = false,
  });
}

class CahierARendre {
  const CahierARendre({
    required String seanceId,
    required List<DecisionEleve> decisions,
    String? noteGroupe,            // facultatif : aucun narratif obligatoire
  });
}
```

`DecisionEleve` est **volontairement étroit** : aucun champ ne permet de modifier
le curriculum institutionnel, de changer un cycle fixe ni de valider un gate. Ce
que le modèle n'offre pas, l'écran n'a pas à l'offrir.

Soumission, hors ligne comprise :

```dart
final SoumissionCahier soumission = ref.read(soumissionCahierProvider);
final SortCahier sort = await soumission.soumettre(cahier);
// SortCahier.envoye  -> le serveur a accepte
// SortCahier.enFile  -> enregistre localement, partira au retour du reseau
```

La clé d'idempotence est générée **par la file, à la rédaction**, et jamais
regénérée au rejeu : c'est ce qui permet à la contrainte d'unicité C9 de refuser
un doublon. **N'écris pas ta propre file hors ligne** : `FileRapports`,
`DepotRapports` et la table drift existent depuis l'étape 2, et le socle leur a
donné leur implémentation.

### Correction de présence

`lib/features/presence_correction/` existe, est testé, et **n'est branché à
rien**. Son propre commentaire dit qu'il attend d'être inséré « dans la salle
enseignant ou l'espace administration ». **Ne redessine pas une feuille
« signaler une exception »** : réutilise ce panneau. Il est attribué à l'agent C,
qui le branche dans le cahier.

---

## 7. Disponibilités

```dart
class Creneau {
  const Creneau({
    required int jour,      // ISO : 1 = lundi, 7 = dimanche
    required int heure,     // heure locale pleine, 0 a 23
    required String fuseau, // IANA
    DateTime? poseLe,
  });
  // operator == ignore poseLe : une case reposee reste la meme case
}

abstract interface class ServicePlanning {
  Future<String> monFuseau();
  Future<List<Creneau>> disponibilites(String profilId);
  Future<void> poser({required String profilId, required Creneau creneau});
  Future<void> retirer({required String profilId, required Creneau creneau});
  Future<List<Seance>> seances();
  Future<List<Affectation>> affectations();
}
```

| Provider | Type |
| :--- | :--- |
| `servicePlanningProvider` | `Provider<ServicePlanning>` |
| `monFuseauProvider` | `FutureProvider<String>` |
| `disponibilitesProvider` | `FutureProviderFamily<List<Creneau>, String>` (paramètre : `profilId`) |

`monFuseau()` rend le fuseau **où l'enseignant pose ses créneaux**, jamais celui
de l'appareil : celui-là suit le voyageur, le cours ne bouge pas.

La grille est un composant partagé, **à réutiliser tel quel** :

```dart
const GrilleSemaine({
  required List<Creneau> creneaux,
  required String fuseau,
  required void Function(Creneau creneau, bool posee) onBasculer,
  Key? key,
  bool enCours = false,
});
static const int heureDebut = 6;
static const int heureFin = 21;
```

Elle vit dans `lib/features/disponibilites/grille_semaine.dart`, c'est-à-dire
dans la feature du **tuteur**. C'est une dette assumée
(`TEACHER_PARALLEL_BASELINE.md` §5.5) : importe-la, ne la déplace pas, et surtout
**n'ajoute aucun paramètre** — tout changement de signature modifierait
silencieusement l'écran du tuteur `TUT-04`.

⚠ `availability_slots` existe en base mais **n'est pas la table vivante** :
`weekly_availability` l'est. N'écris jamais dans la première.

⚠ Le repli `'Europe/Paris'` est déjà codé en dur en six endroits. **N'en ajoute
pas un septième** : passe par `monFuseauProvider`.

---

## 8. Matching

```dart
class EleveEnAttente {
  const EleveEnAttente({
    required String eleveId,
    required String prenom,
    required String identifiantImmuable,
    required Creneau creneau,
    required DateTime depuis,
    required InterfaceMode mode,
    String? niveau,
  });
  int joursDAttente(DateTime maintenant);
}

List<EleveEnAttente> parAnciennete(List<EleveEnAttente> feed);

abstract interface class ServiceMatching {
  Future<List<EleveEnAttente>> elevesEnAttente();
  Future<void> prendre({required String eleveId, required Creneau creneau});
  Future<void> demander({
    required SorteDemande sorte, required String sujetId,
    required String motif, CleRegle? cle, int? valeur,
  });
}

final FutureProvider<List<EleveEnAttente>> elevesEnAttenteProvider;
```

- **le tri canonique est l'ancienneté d'attente**, jamais l'alphabétique.
  `parAnciennete` le fait. Le double tri (base **et** client) est **délibéré et
  documenté** : ne le « simplifie » pas, c'est un correctif payé ;
- le feed rend **une ligne par créneau compatible**, pas par élève : compter les
  lignes annoncerait quatre familles là où une seule attend ;
- `prendre` s'appuie sur la RPC `prendre_eleve(p_student_profile_id, p_weekday, p_hour)`,
  `security definer`. **La base tranche la concurrence** : si un autre enseignant
  a pris le créneau, l'appel échoue. L'écran dit le conflit clairement, fait
  disparaître la ligne et relit le feed. Aucun verrou local ne décide du
  gagnant ;
- le plafond d'élèves se lit par `valeurRegleProvider((profilId: moi, cle: CleRegle.plafondEleves))`.
  Au plafond, le bouton « Prendre » **n'est pas rendu** : une phrase l'explique
  et donne accès à `demander(sorte: SorteDemande.plafond, ...)` ;
- `EleveEnAttente` ne porte **aucune coordonnée de famille**. N'en affiche
  jamais : prénom et identifiant immuable, rien d'autre.

⚠ Il existe **trois feeds de la même file** en base (`eleves_en_attente_v`,
`eleves_sans_enseignant()`, `enseignants_pour()`). N'en crée pas un quatrième et
n'en change aucun.

---

## 9. Profil, dossier, KYC

```dart
class ProfilEnseignant {
  const ProfilEnseignant({
    required String prenom,
    required String identifiant,
    String? pays,
    List<String> langues = const <String>[],
    int? plafondHeures,
    AccountStatus? statutCompte,
    VerificationEnseignant? verification,
  });
}

abstract interface class ServiceProfilEnseignant {
  Future<ProfilEnseignant?> profil(String profilId);
}
final FutureProvider<ProfilEnseignant?> profilEnseignantProvider;
```

**`profilEnseignantProvider` existe et n'est consommé par aucun écran.**
`ProfilEnseignantPage` refabrique aujourd'hui ses chiffres depuis
`seancesProvider` et `elevesEnAttenteProvider`. C'est le contrat mort à brancher,
et il ne faut surtout pas en écrire un troisième.

Dossier et pièces :

```dart
abstract interface class ServiceDossier {
  Future<void> creerProfil({required AppRole role, required String prenom,
                            required String nom, Genre? genre});
  Future<EtatDossier> etat();
  Future<void> accepterContrat(SorteContrat sorte, String version);
  Future<void> deposerPiece(PieceAEnvoyer piece);
  static const int tailleMaximaleOctets = 8 * 1024 * 1024;
}
final FutureProvider<EtatDossier> etatDossierProvider;

class EtatDossier {
  const EtatDossier({
    required bool profilExiste, AppRole? role, AccountStatus? statutCompte,
    bool pieceDeposee = false, StatutPiece? statutPiece, String? motifRefus,
    DateTime? deposeLe, bool contratSigne = false, bool accuseSigne = false,
  });
  EtapeDossier get etape;
  List<PieceManquante> get manquants;
}

enum EtapeDossier { incomplet, enVerification, refuse, suspendu }
enum PieceManquante { accuse, contrat, pieceIdentite }

abstract interface class SelecteurFichier {
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type);
}
```

Les accusés obligatoires **existent déjà** (ADR-011) :

```dart
enum SorteContrat {
  conditionsTuteur('guardian_terms'),
  contratEnseignant('teacher_nda'),
  accuseEnregistrementControle('recording_and_control_notice'),
}
static SorteContrat pour(AppRole role);   // teacher -> contratEnseignant
```

⚠ **Un seul enregistrement couvre les deux dispositifs.**
`signature_page.dart` écrit une unique acceptation
`recording_and_control_notice` qui porte à la fois l'enregistrement audio et la
visite de contrôle. Le protocole demande deux accusés explicites. Rendre les deux
**séparément opposables** exigerait une valeur de `contract_kind` de plus, donc
une migration : c'est une **demande de contrat**, pas un écran à ajouter. Écris-le
dans ton `CONTRACT_REQUEST` plutôt que de le contourner.

⚠ Que les deux points soient montrés **deux fois** (à l'accusé puis au contrat)
est **voulu** par l'ADR-011 et documenté : ce n'est pas un doublon à corriger.

Session, lecture seule :

```dart
final NotifierProvider<SessionControleur, SessionState> sessionProvider;
// SessionState : resolue, role, householdId, profileId, accountStatus,
//                interfaceMode, lectureProfil, observation
//                bool get connecte / peutEcrire / peutVoirDirection
//                PorteAcces get porte
enum PorteAcces { chargement, deconnecte, inscription, attente, suspendu, actif }
```

Le `profileId` de l'enseignant connecté se lit **toujours** ici, jamais ailleurs.

Déconnexion : `ServiceAuth.deconnexion()` via `serviceAuthProvider`. Le Profil
(`ENS-05`) en porte l'accès depuis que « Compte » a quitté la barre.

---

## 10. Réseau et états

```dart
final StreamProvider<bool> horsLigneProvider;   // source unique du fait « hors ligne »
```

`PageShell` porte déjà le bandeau hors ligne : n'en pose pas un second. Ce
provider sert à **désactiver une action** qui ne peut pas aboutir hors ligne (la
prise d'un créneau, par exemple) et à le dire.

Les cinq états d'un écran, exigés pour chacun : `loading`, `content`, `empty`,
`error`, `offline`. Plus, selon l'écran, ses états propres : préflight échoué,
élève absent détecté, rapport en retard, conflit, créneau déjà pris, plafond
atteint, déjà déposé.

---

## 11. Harnais de test

`test/support/harnais.dart`, **propriété de l'Agent Z**. Tu l'emploies, tu ne
l'écris pas.

```dart
Widget hote(Widget enfant, {
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
});

Widget hoteRoutant({
  required String depart,
  required List<RouteBase> routes,
  List<Override> surcharges = const <Override>[],
  InterfaceMode mode = InterfaceMode.standard,
});
```

`Override` s'importe depuis `package:flutter_riverpod/misc.dart`.

Faux disponibles, tous en mémoire : `FauxServiceEnseignant`, `FauxDepotRapports`,
`FauxServicePlanning`, `FauxServiceMatching`, `FauxServiceRegles`,
`FauxServicePriere`, `FauxServicePreVol`, `FauxServiceVideo`,
`FauxServicePresence`, `FauxMoteurSalle`, `FauxServiceReseau`,
`FauxServiceDossier`, `FauxServiceAuth`, `FauxSelecteurFichier`,
`FauxServiceProfil…` et une quinzaine d'autres. **Lis le fichier avant d'écrire
un faux** : en écrire un qui existe est exactement la duplication que ce lot
refuse.

Deux constructeurs de données pour abréger les cas de test :

```dart
SeanceEnseignant seanceDeTest({String id, required DateTime debut, Duration duree,
  StatutSeance? statut, int nbParticipants, bool cahierDepose,
  String? groupeId, String? groupeLibelle, int? seuilMax, int minutesInterruption});

MembreSeance membreDeTest({String studentId, String identifiant,
  String? prenom, String? niveau, String? riwaya});
```

`FauxServiceEnseignant.delai` existe pour une raison : sans délai, un faux résout
son futur dans la micro-tâche que le premier `pump` vide, et **l'état de
chargement n'existe jamais**. Pose un délai pour mesurer le squelette.

---

## 12. Les chaînes de texte

`assets/i18n/fr.i18n.json` est **fermé**. Déclare tes clés dans
`docs/parallel-reports/i18n_<AGENT>.json`, un objet JSON fusionné tel quel à la
racine :

```json
{ "enseignant": { "cahier": { "titre": "Cahier de transmission",
                              "duree": "{minutes} min" } } }
```

```dart
Text(t.enseignant.cahier.titre)
Text(t.enseignant.cahier.duree(minutes: '$minutes'))
```

- convention : `role.ecran.element`, donc toujours sous `enseignant.<ecran>` ;
- interpolation en accolades, `{minutes}`, jamais `$minutes` ;
- **français seulement** : l'arabe est un talon volontaire et le repli renvoie le
  français ;
- **cherche avant d'écrire.** Des clés existent déjà sans appelant :
  `salle.ouvrirCoran`, `vide.aucunRapport`, et tout `enseignant.journee.*`. En
  créer une jumelle donnerait deux clés pour un même bouton ;
- `t.disponibilites.joursLongs` / `joursCourts` sont lus par **sept écrans** :
  emploie-les, ne les renomme pas.

---

## 13. Ce qui manque, et qu'on ne comble pas seul

Déjà instruit par l'Agent 0 ; n'ouvre pas de `CONTRACT_REQUEST` pour ceux-là,
c'est déjà fait ou décidé :

| Manque | Traitement |
| :--- | :--- |
| séances groupées par séance | vue `mes_seances_enseignant_v`, migration `0025` |
| lien séance ↔ groupe | `sessions.groupe_id`, migration `0025` |
| lecture enseignant des groupes | `mes_groupes_v` + `mon_groupe_detail`, migration `0025` |
| préremplissage du cahier | RPC `brouillon_cahier` |
| cahiers en retard | RPC `mes_rapports_en_attente` |
| implémentation de la file hors ligne | `DepotRapportsDrift` + `SoumissionCahier` |
| contenu présenté vers l'élève | contrat posé par le socle salle |
| Coran par sourate et verset | conversion ajoutée par le socle salle |
| états réseau `instable` / `retabli` | ajoutés par le socle salle |
| quatrième destination « Compte » | retirée par l'Agent Z |
| quatre routes contextuelles | posées par l'Agent Z |

> ⚠ **La migration `0025` est écrite mais n'est pas appliquée** : l'accès en
> écriture à la base de production est fermé dans cette session. Les écrans se
> construisent et se testent contre les faux du harnais, ce qui ne dépend
> d'aucune base. En exécution réelle, les lectures concernées échoueront jusqu'à
> ce que la migration soit poussée : **c'est exactement pourquoi l'état `error` de
> chaque écran n'est pas optionnel.**

---

## 14. Interdictions, une dernière fois

1. n'écris que dans tes fichiers (`TEACHER_FILE_OWNERSHIP.md`) ;
2. aucune dépendance nouvelle ;
3. aucun second `GoRouter`, provider vidéo, service de disponibilité, de matching
   ou de rapport ;
4. aucun composant de `lib/core/widgets/` dupliqué, aucun fichier ajouté dedans ;
5. aucun état global créé pour contourner un contrat manquant ;
6. aucune table ajoutée à `AppDatabase` (quatre, ni plus ni moins) ;
7. aucune migration SQL ;
8. **aucune commande `flutter analyze`, `flutter test`, `dart run slang` ou
   `build_runner`** : plusieurs agents travaillent en parallèle et ces commandes
   se disputent `.dart_tool`. La vérification est centralisée chez l'Agent Z ;
9. `assets/i18n/*.json` ne s'ouvre pas ;
10. aucun nom de famille, courriel ni téléphone de famille affiché.
