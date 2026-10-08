// La demonstration de la voie COM-STU (Le Studio) :
// `/demo/communications?voie=studio&situation=...`.
//
// Hors production : la route n'existe que si `environnementAutoriseDemo`
// l'autorise (DEMO-ENV-1), et rien ici n'est un port reel (K-28). Les
// fixtures (spec section 26 et section 9.1) : cinq canaux ranges dans la
// taxonomie du Studio, dont un restreint autorise et un prive autorise, un
// canal prive ABSENT pour la personne (jamais rendu, R-COM-08), un canal en
// lecture seule, un vocal, des pieces jointes, des elements epingles, des
// liens utiles (un interne, un externe), un echec d'envoi (R-COM-13) et un
// etat hors ligne. Pour Aujourd'hui (COM-STU-2, spec section 26 « Today
// avec activite », « Today vide », « 1 brouillon ») : une activite rangee dans
// les cinq blocs (dont une ligne Finance sans page, R-COM-11, une ligne
// dossier qui ouvre SON dossier, et une ligne d'un canal prive absent que le
// port ne rend jamais, R-COM-08), un brouillon dans le canal Admissions, et
// la situation « Aujourd'hui sans activite ». Pour le Mode focus (COM-STU-3,
// spec section 10, section 33 « Studio avec Focus ») : la situation « Un
// canal en mode focus » ouvre le canal Organisation deja en Focus ; partout
// ailleurs, « Mode focus » est dans l'en-tete de chaque canal ouvert.
//
// Une ligne qui ouvre un module hors du Studio (Finance, dossier, Classe)
// quitterait la demonstration pour une page qui demande une session : la
// demonstration le dit en une phrase et reste en place.
//
// Le Studio n'est ouvert qu'a la direction en V1 (QUESTIONS Q1) : la
// demonstration ne met donc en scene que ce point de vue, et le `?role=` de
// l'adresse est ignore.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/communications/capacites_communication.dart';
import '../../../core/communications/port_brouillons.dart';
import '../../../core/communications/port_elements_enregistres.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_studio/activite.dart' show libelleModule;
import '../../com_studio/aujourdhui_page.dart';
import '../../com_studio/brouillons_studio.dart';
import '../../com_studio/elements_enregistres_studio.dart';
import '../../com_studio/port_activite_studio.dart';
import '../../com_studio/port_studio.dart';
import '../../com_studio/recherche_studio.dart';
import '../../com_studio/studio_page.dart';
import 'com_vocal_demo.dart';
import 'demo_communications_page.dart';

/// Les situations que la demonstration sait mettre en scene.
enum SituationDemoStudio {
  /// Tout repond.
  normale,

  /// Le premier envoi de chaque message n'est pas confirme ; « Reessayer »
  /// rejoue la meme cle et aboutit (R-COM-13).
  echecEnvoi,

  /// L'appareil est hors ligne : le contenu deja lu reste, aucun envoi
  /// n'aboutit.
  horsLigne,

  /// L'adresse demande un canal prive qui n'est pas ouvert a la personne :
  /// il n'est pas rendu (R-COM-08).
  canalPrive,

  /// Aucun canal n'est ouvert a la personne.
  sansCanaux,

  /// Aujourd'hui n'a aucune activite, et aucun brouillon n'est garde.
  aujourdhuiVide,

  /// Le canal Organisation s'ouvre en Mode focus.
  focus,
}

/// Le canal que la situation « Mode focus » ouvre.
const String canalFocusDemo = 'organisation';

/// L'identifiant du canal prive que la personne ne voit jamais (R-COM-08).
const String canalPriveAbsentDemo = 'direction-strategie';

/// L'adresse de la demonstration du Studio dans [situation].
String adresseDemoStudio({
  SituationDemoStudio situation = SituationDemoStudio.normale,
}) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.studio.name,
    'situation': situation.name,
  },
).toString();

/// Le libelle d'une situation de la demonstration.
String libelleSituationDemoStudio(SituationDemoStudio situation) {
  final d = t.com.studio.demo;
  return switch (situation) {
    SituationDemoStudio.normale => d.normale,
    SituationDemoStudio.echecEnvoi => d.echec,
    SituationDemoStudio.horsLigne => d.horsLigne,
    SituationDemoStudio.canalPrive => d.canalPrive,
    SituationDemoStudio.sansCanaux => d.sansCanaux,
    SituationDemoStudio.aujourdhuiVide => d.aujourdhuiVide,
    SituationDemoStudio.focus => d.focus,
  };
}

/// La demonstration de la voie Le Studio.
class ComStudioDemo extends StatelessWidget {
  /// Cree la demonstration de la voie.
  const ComStudioDemo({super.key, this.role, this.situation});

  /// Le role mis en scene (`?role=`) : ignore, Le Studio n'a qu'un point de
  /// vue en V1 (la direction).
  final RoleDemoCommunications? role;

  /// La situation ; nulle, celle de l'adresse (`?situation=`), sinon le
  /// choix des situations.
  final SituationDemoStudio? situation;

  SituationDemoStudio? _situation(BuildContext context) {
    final SituationDemoStudio? donnee = situation;
    if (donnee != null) return donnee;
    if (GoRouter.maybeOf(context) == null) return null;
    final String? nom = GoRouterState.of(context)
        .uri
        .queryParameters['situation'];
    for (final SituationDemoStudio s in SituationDemoStudio.values) {
      if (s.name == nom) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SituationDemoStudio? s = _situation(context);
    if (s == null) return const _ChoixSituation();
    return _DemoStudio(
      key: ValueKey<String>('demo-studio-${s.name}'),
      situation: s,
    );
  }
}

class _ChoixSituation extends StatelessWidget {
  const _ChoixSituation();

  @override
  Widget build(BuildContext context) {
    final d = t.com.studio.demo;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    void aller(String adresse) => GoRouter.of(context).go(adresse);
    return PageShell(
      titre: t.com.studio.titre,
      sousTitre: t.com.socle.navigation.demo.detail,
      onRetour: () => aller(Routes.demoCommunications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.choisir,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final SituationDemoStudio s in SituationDemoStudio.values)
            LienFleche(
              key: ValueKey<String>('demo-studio-situation-${s.name}'),
              libelle: libelleSituationDemoStudio(s),
              onPress: () => aller(adresseDemoStudio(situation: s)),
            ),
        ],
      ),
    );
  }
}

class _DemoStudio extends StatefulWidget {
  const _DemoStudio({required this.situation, super.key});

  final SituationDemoStudio situation;

  @override
  State<_DemoStudio> createState() => _DemoStudioState();
}

class _DemoStudioState extends State<_DemoStudio> {
  late final StudioDemo _port = StudioDemo(situation: widget.situation);
  late final ActiviteStudioDemo _activite = ActiviteStudioDemo(
    situation: widget.situation,
  );
  late final BrouillonsMemoire _brouillons = brouillonsStudioDemo(
    widget.situation,
  );
  final ElementsEnregistresMemoire _enregistres = ElementsEnregistresMemoire();

  /// Le Studio s'ouvre sur Aujourd'hui, son accueil ; l'adresse d'un canal
  /// prive ouvre ce canal ; le Mode focus ouvre son canal.
  late VueStudio _vue = switch (widget.situation) {
    SituationDemoStudio.canalPrive ||
    SituationDemoStudio.focus => VueStudio.canaux,
    _ => VueStudio.aujourdhui,
  };
  late String? _canalId = switch (widget.situation) {
    SituationDemoStudio.canalPrive => canalPriveAbsentDemo,
    SituationDemoStudio.focus => canalFocusDemo,
    _ => null,
  };

  /// Le module qu'une ligne aurait ouvert hors de la demonstration.
  String? _horsDemo;

  /// Ouvre un chemin interne : un canal du Studio s'ouvre dans la
  /// demonstration ; tout autre chemin quitterait la demonstration, il est
  /// ignore.
  void _ouvrir(String chemin) {
    final String? id = canalDuChemin(chemin);
    if (id == null) return;
    setState(() {
      _vue = VueStudio.canaux;
      _canalId = id;
      _horsDemo = null;
    });
  }

  /// Ouvre une destination d'Aujourd'hui ou des brouillons : un canal
  /// s'ouvre ici ; un autre module est nomme, la demonstration reste.
  void _ouvrirDestination(DestinationStudio d) {
    if (canalDuChemin(d.chemin) != null) {
      _ouvrir(d.chemin);
      return;
    }
    setState(() => _horsDemo = libelleModule(d.module));
  }

  void _allerVue(VueStudio v) => setState(() {
    _vue = v;
    _canalId = null;
    _horsDemo = null;
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        portStudioProvider.overrideWithValue(_port),
        portActiviteStudioProvider.overrideWithValue(_activite),
        portBrouillonsProvider.overrideWithValue(_brouillons),
        portElementsEnregistresProvider.overrideWithValue(_enregistres),
        // COM-FUS : le composer vocal du canal (faux micro, envoi accuse).
        // Le provider lu par la page est surcharge lui-meme : sans
        // `dependencies`, il se resoudrait dans la portee racine.
        capacitesCommunicationProvider.overrideWith(
          (Ref _) => const CapacitesCommunicationsFixes(<CapaciteCommunication>{
            CapaciteCommunication.envoyerVocal,
          }).capacites(),
        ),
        ...surchargesVocalDemo(),
        if (widget.situation == SituationDemoStudio.horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: CoquilleStudio(
        vue: _vue,
        focusInitial: widget.situation == SituationDemoStudio.focus,
        sousTitre: t.com.studio.demo.vue(
          situation: libelleSituationDemoStudio(widget.situation),
        ),
        onAllerVue: _allerVue,
        onRetourListe: _canalId == null
            ? null
            : () => setState(() => _canalId = null),
        onQuitter: () =>
            GoRouter.of(context)
                .go(adresseDemoCommunications(VoieDemoCommunications.studio)),
        child: _avecAvis(switch (_vue) {
          VueStudio.aujourdhui => TableauAujourdhui(
            onOuvrir: _ouvrirDestination,
            onVoirBrouillons: () => _allerVue(VueStudio.brouillons),
            destinationCanal: cheminCanalStudio,
          ),
          VueStudio.canaux => EspaceStudio(
            canalId: _canalId,
            onOuvrirCanal: (String id) => setState(() => _canalId = id),
            onOuvrir: _ouvrir,
          ),
          VueStudio.enregistres => VueElementsEnregistres(onOuvrir: _ouvrir),
          VueStudio.brouillons => VueBrouillonsStudio(
            onOuvrir: _ouvrirDestination,
            destinationCanal: cheminCanalStudio,
          ),
        }),
      ),
    );
  }

  /// La vue, precedee de la phrase qui dit le module qu'une ligne aurait
  /// ouvert dans l'application.
  Widget _avecAvis(Widget vue) {
    final String? module = _horsDemo;
    if (module == null) return vue;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            t.com.studio.demo.horsDemo(module: module),
            key: cleAvisHorsDemoStudio,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        Expanded(child: vue),
      ],
    );
  }
}

/// La cle de la phrase « Dans l'application, cette ligne ouvre... », pour
/// les tests.
const ValueKey<String> cleAvisHorsDemoStudio = ValueKey<String>(
  'demo-studio-hors-demo',
);

/// L'identifiant du canal qu'ouvre [chemin] (`/admin/studio/canaux/:id`),
/// ou `null` si le chemin mene ailleurs.
String? canalDuChemin(String chemin) {
  const String prefixe = '${Routes.adminStudioCanaux}/';
  if (!chemin.startsWith(prefixe)) return null;
  final String reste = chemin.substring(prefixe.length);
  if (reste.isEmpty || reste.contains('/')) return null;
  return Uri.decodeComponent(reste);
}

/// Un canal de la demonstration, avec ce qu'il partage.
class _CanalDemo {
  _CanalDemo(this.canal, this.partages);

  Canal canal;
  final PartagesCanal partages;
}

/// Les membres de l'equipe de la demonstration (noms fictifs), dans la
/// langue de l'interface (COM-RC tour 7).
abstract final class _Equipe {
  static Participant get soi => Participant(
    id: 'p-soi',
    nomAffiche: t.com.studio.demo.f.nadia,
    fonction: t.com.studio.demo.f.fonctionDirection,
    estSoi: true,
  );
  static Participant get mariam => Participant(
    id: 'p-mariam',
    nomAffiche: t.com.studio.demo.f.mariam,
    fonction: t.com.studio.demo.f.fonctionCoordination,
  );
  static Participant get youssef => Participant(
    id: 'p-youssef',
    nomAffiche: t.com.studio.demo.f.youssef,
    fonction: t.com.studio.demo.f.fonctionProduit,
  );
  static Participant get amina => Participant(
    id: 'p-amina',
    nomAffiche: t.com.studio.demo.f.amina,
    fonction: t.com.studio.demo.f.fonctionPedagogie,
  );
  static Participant get samira => Participant(
    id: 'p-samira',
    nomAffiche: t.com.studio.demo.f.samira,
    fonction: t.com.studio.demo.f.fonctionAdmissions,
  );
  static Participant get ibrahim => Participant(
    id: 'p-ibrahim',
    nomAffiche: t.com.studio.demo.f.ibrahim,
    fonction: t.com.studio.demo.f.fonctionPlanning,
  );
}

PieceJointe _pdf(String id, String nom, int octets) => PieceJointe(
  reference: ReferencePieceJointe(id),
  nom: nom,
  nature: NaturePieceJointe.document,
  typeLisible: 'PDF',
  tailleOctets: octets,
);

/// Les noms, canaux et textes de la demonstration, dans la langue de
/// l'interface (COM-RC tour 7 : plus de francais dans l'arabe).
Traductions$com$studio$demo$f$fr get _f => t.com.studio.demo.f;

/// Les canaux de la demonstration (spec section 9.1 et section 26), le canal
/// prive absent compris : c'est le port qui le retire, jamais l'ecran seul.
List<(Canal, PartagesCanal)> fixturesStudioDemo(DateTime maintenant) {
  final DateTime m = maintenant.toUtc();
  DateTime il(int minutes) => m.subtract(Duration(minutes: minutes));
  final PieceJointe planning = _pdf('pj-planning', _f.fichierPlanning, 1153434);
  final PieceJointe moderation = _pdf(
    'pj-moderation',
    _f.fichierModeration,
    819200,
  );
  final PieceJointe vocal = PieceJointe(
    reference: ReferencePieceJointe('pj-vocal-youssef'),
    nom: _f.fichierVocal,
    nature: NaturePieceJointe.vocal,
    typeLisible: _f.pieceAudio,
    duree: const Duration(seconds: 42),
    // R-04 : le vocal recu de la demonstration se lit (lecture simulee).
    peutOuvrir: true,
  );
  final PieceJointe compteRendu = _pdf(
    'pj-compte-rendu',
    _f.fichierCompteRendu,
    245760,
  );
  return <(Canal, PartagesCanal)>[
    (
      Canal(
        resume: ResumeCanal(
          id: 'organisation',
          nom: _f.canalOrganisation,
          section: SectionStudio.organisation,
          visibilite: VisibiliteCanal.visible,
          description: _f.canalOrganisationDetail,
          attention: const IndicateurAttention(
            nonLus: 2,
            niveau: NiveauAttention.aLire,
          ),
          dernierMessageLe: il(20),
        ),
        membres: <Participant>[
          _Equipe.soi,
          _Equipe.mariam,
          _Equipe.youssef,
          _Equipe.amina,
          _Equipe.samira,
          _Equipe.ibrahim,
        ],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-org-1',
            auteur: _Equipe.mariam,
            texte: _f.messagePlanning,
            envoyeLe: il(95),
            piecesJointes: <PieceJointe>[planning],
          ),
          MessageCommunication(
            id: 'm-org-2',
            auteur: _Equipe.youssef,
            texte: '',
            envoyeLe: il(70),
            piecesJointes: <PieceJointe>[vocal],
          ),
          MessageCommunication(
            id: 'm-org-3',
            auteur: _Equipe.amina,
            texte: _f.messageSupports,
            envoyeLe: il(40),
          ),
          MessageCommunication(
            id: 'm-org-4',
            auteur: _Equipe.samira,
            texte: _f.messageMerci,
            envoyeLe: il(20),
            mentionneSoi: true,
          ),
        ],
        capacites: const <CapaciteCanal>{
          CapaciteCanal.ecrire,
          CapaciteCanal.parametres,
        },
      ),
      PartagesCanal(
        epingles: <ElementPartage>[
          ElementPartage(
            id: 'ep-planning',
            titre: _f.partagePlanning,
            nature: NaturePartage.epingle,
            piece: planning,
            detail: _f.epinglePar(nom: _Equipe.mariam.nomAffiche),
          ),
          ElementPartage(
            id: 'ep-moderation',
            titre: _f.partageModeration,
            nature: NaturePartage.epingle,
            piece: moderation,
            detail: _f.epinglePar(nom: _Equipe.youssef.nomAffiche),
          ),
        ],
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-planning',
            titre: _f.fichierPlanning,
            nature: NaturePartage.fichier,
            piece: planning,
            detail: _f.partagePar(nom: _Equipe.mariam.nomAffiche),
          ),
        ],
        liens: <ElementPartage>[
          ElementPartage(
            id: 'li-remplacements',
            titre: _f.lienRemplacements,
            nature: NaturePartage.lien,
            destination: Routes.canalStudioPour('remplacements'),
          ),
          ElementPartage(
            id: 'li-charte',
            titre: _f.lienCharte,
            nature: NaturePartage.lien,
            hote: 'rewayah.org',
          ),
        ],
      ),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'admissions',
          nom: _f.canalAdmissions,
          section: SectionStudio.admissionsFamilles,
          visibilite: VisibiliteCanal.visible,
          description: _f.canalAdmissionsDetail,
          attention: const IndicateurAttention(
            nonLus: 1,
            niveau: NiveauAttention.actionRequise,
            mention: true,
          ),
          dernierMessageLe: il(55),
        ),
        membres: <Participant>[_Equipe.soi, _Equipe.samira, _Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-adm-1',
            auteur: _Equipe.samira,
            texte: _f.messageDossiers,
            envoyeLe: il(55),
            mentionneSoi: true,
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'qualite',
          nom: _f.canalQualite,
          section: SectionStudio.pedagogieQualite,
          visibilite: VisibiliteCanal.restreint,
          description: _f.canalQualiteDetail,
          dernierMessageLe: il(60 * 26),
        ),
        membres: <Participant>[_Equipe.soi, _Equipe.amina, _Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-qua-1',
            auteur: _Equipe.amina,
            texte: _f.messageCompteRendu,
            envoyeLe: il(60 * 26),
            piecesJointes: <PieceJointe>[compteRendu],
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-compte-rendu',
            titre: _f.fichierCompteRendu,
            nature: NaturePartage.fichier,
            piece: compteRendu,
            detail: _f.partagePar(nom: _Equipe.amina.nomAffiche),
          ),
        ],
      ),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'remplacements',
          nom: _f.canalRemplacements,
          section: SectionStudio.planningRemplacements,
          visibilite: VisibiliteCanal.visible,
          description: _f.canalRemplacementsDetail,
          dernierMessageLe: il(60 * 3),
        ),
        membres: <Participant>[_Equipe.soi, _Equipe.ibrahim],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-rem-1',
            auteur: _Equipe.ibrahim,
            texte: _f.messageRemplacement,
            envoyeLe: il(60 * 3),
          ),
        ],
      ),
      PartagesCanal(),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'cloture',
          nom: _f.canalCloture,
          section: SectionStudio.finance,
          visibilite: VisibiliteCanal.priveAutorise,
          description: _f.canalClotureDetail,
          dernierMessageLe: il(60 * 50),
        ),
        membres: <Participant>[_Equipe.soi, _Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-clo-1',
            auteur: _Equipe.mariam,
            texte: _f.messageJustificatifs,
            envoyeLe: il(60 * 50),
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(),
    ),
    // Le canal prive dont la personne n'est pas membre : le serveur ne le
    // rendrait pas. Le port de demonstration le garde pour prouver qu'il
    // ne sort jamais (R-COM-08).
    (
      Canal(
        resume: ResumeCanal(
          id: canalPriveAbsentDemo,
          nom: _f.canalDirection,
          section: SectionStudio.direction,
          visibilite: VisibiliteCanal.absent,
          description: _f.canalDirectionDetail,
          dernierMessageLe: il(10),
        ),
        membres: <Participant>[_Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-dir-1',
            auteur: _Equipe.mariam,
            texte: _f.messageBudget,
            envoyeLe: il(10),
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-budget',
            titre: _f.fichierBudget,
            nature: NaturePartage.fichier,
            piece: _pdf('pj-budget', _f.fichierBudget, 40960),
          ),
        ],
      ),
    ),
  ];
}

/// Le port du Studio de la demonstration : en memoire, sans serveur. Jamais
/// branche hors de `environnementAutoriseDemo`.
///
/// Comme le ferait le serveur, il ne rend JAMAIS un canal absent : ni dans
/// `canaux()`, ni par `canal(id)`, ni par `partages`, ni dans `rechercher`.
class StudioDemo implements PortStudio {
  /// Cree le port dans [situation]. [maintenant] fixe l'heure des fixtures
  /// (les tests la donnent).
  StudioDemo({
    this.situation = SituationDemoStudio.normale,
    DateTime? maintenant,
  }) : _canaux = <String, _CanalDemo>{
         for (final (Canal c, PartagesCanal p) in fixturesStudioDemo(
           maintenant ?? DateTime.now(),
         ))
           c.id: _CanalDemo(c, p),
       };

  /// La situation mise en scene.
  final SituationDemoStudio situation;

  final Map<String, _CanalDemo> _canaux;
  final Set<String> _clesEnEchec = <String>{};

  /// Les cles d'idempotence recues, dans l'ordre (pour les tests).
  final List<String> clesRecues = <String>[];

  /// Les canaux que la personne voit : jamais un canal absent.
  Iterable<_CanalDemo> get _autorises =>
      situation == SituationDemoStudio.sansCanaux
      ? const <_CanalDemo>[]
      : _canaux.values.where(
          (_CanalDemo c) => c.canal.resume.visibilite.estRendu,
        );

  _CanalDemo? _autorise(String id) {
    for (final _CanalDemo c in _autorises) {
      if (c.canal.id == id) return c;
    }
    return null;
  }

  /// Le canal [id] tel qu'il est en memoire, absent compris (pour les
  /// tests).
  Canal? canalEnMemoire(String id) => _canaux[id]?.canal;

  @override
  Future<List<ResumeCanal>> canaux() async => <ResumeCanal>[
    for (final _CanalDemo c in _autorises) c.canal.resume,
  ];

  @override
  Future<Canal?> canal(String canalId) async => _autorise(canalId)?.canal;

  @override
  Future<PartagesCanal> partages(String canalId) async =>
      _autorise(canalId)?.partages ?? PartagesCanal.aucun;

  @override
  Future<ResultatsStudio> rechercher(String texte) async {
    final List<String> mots = motsRecherche(texte);
    if (mots.isEmpty) return ResultatsStudio();
    final List<ResumeCanal> canaux = <ResumeCanal>[];
    final List<MessageTrouve> messages = <MessageTrouve>[];
    final List<FichierTrouve> fichiers = <FichierTrouve>[];
    for (final _CanalDemo c in _autorises) {
      final ResumeCanal r = c.canal.resume;
      if (contientTousLesMots('${r.nom} ${r.description ?? ''}', mots)) {
        canaux.add(r);
      }
      for (final MessageCommunication m in c.canal.messages) {
        if (m.texte.isNotEmpty &&
            contientTousLesMots('${m.texte} ${m.auteur.nomAffiche}', mots)) {
          messages.add(MessageTrouve(canal: r, message: m));
        }
      }
      for (final ElementPartage e in <ElementPartage>[
        ...c.partages.epingles,
        ...c.partages.fichiers,
      ]) {
        if (e.piece != null && contientTousLesMots(e.titre, mots)) {
          fichiers.add(FichierTrouve(canal: r, element: e));
        }
      }
    }
    return ResultatsStudio(
      canaux: canaux,
      messages: messages,
      fichiers: fichiers,
    );
  }

  @override
  Future<void> marquerLu(String canalId) async {
    final _CanalDemo? c = _autorise(canalId);
    if (c == null) return;
    final ResumeCanal r = c.canal.resume;
    c.canal = _copie(
      c.canal,
      resume: ResumeCanal(
        id: r.id,
        nom: r.nom,
        section: r.section,
        visibilite: r.visibilite,
        description: r.description,
        dernierMessageLe: r.dernierMessageLe,
      ),
    );
  }

  @override
  Future<void> envoyer(String canalId, String texte, String cle) async {
    clesRecues.add(cle);
    final _CanalDemo? c = _autorise(canalId);
    if (c == null || !c.canal.peut(CapaciteCanal.ecrire)) {
      throw StateError('Canal non autorise');
    }
    switch (situation) {
      case SituationDemoStudio.horsLigne:
        throw StateError('Hors ligne');
      case SituationDemoStudio.echecEnvoi:
        // Le premier essai d'une cle echoue ; le nouvel essai, meme cle,
        // aboutit.
        if (_clesEnEchec.add(cle)) throw StateError('Envoi non confirme');
      case SituationDemoStudio.normale ||
          SituationDemoStudio.canalPrive ||
          SituationDemoStudio.sansCanaux ||
          SituationDemoStudio.aujourdhuiVide ||
          SituationDemoStudio.focus:
        break;
    }
    final DateTime maintenant = DateTime.now().toUtc();
    final ResumeCanal r = c.canal.resume;
    c.canal = _copie(
      c.canal,
      resume: ResumeCanal(
        id: r.id,
        nom: r.nom,
        section: r.section,
        visibilite: r.visibilite,
        description: r.description,
        attention: r.attention,
        dernierMessageLe: maintenant,
      ),
      messages: <MessageCommunication>[
        ...c.canal.messages,
        MessageCommunication(
          id: 'envoye-$cle',
          auteur: _Equipe.soi,
          texte: texte,
          envoyeLe: maintenant,
        ),
      ],
    );
  }

  static Canal _copie(
    Canal c, {
    ResumeCanal? resume,
    List<MessageCommunication>? messages,
  }) => Canal(
    resume: resume ?? c.resume,
    membres: c.membres,
    messages: messages ?? c.messages,
    capacites: c.capacites,
  );
}

/// Le texte du brouillon de la demonstration, garde dans le canal
/// Admissions (spec section 26, « 1 brouillon »), dans la langue de
/// l'interface.
String get texteBrouillonDemo => _f.brouillon;

/// Les brouillons de la demonstration : en memoire, comme en production
/// (spec section 8.2), avec le brouillon du canal Admissions, sauf quand
/// Aujourd'hui doit etre vide.
BrouillonsMemoire brouillonsStudioDemo(
  SituationDemoStudio situation, {
  DateTime Function()? maintenant,
}) {
  final BrouillonsMemoire memoire = BrouillonsMemoire(maintenant: maintenant);
  if (situation != SituationDemoStudio.aujourdhuiVide) {
    // `BrouillonsMemoire` ecrit sans attendre : le brouillon est garde des
    // ici.
    unawaited(
      memoire.enregistrer(cleBrouillonCanal('admissions'), texteBrouillonDemo),
    );
  }
  return memoire;
}

/// Les lignes d'activite de la demonstration (spec section 8.1 et section 26,
/// « Today avec activite »), la ligne d'un canal prive absent comprise :
/// c'est le port qui la retire, jamais l'ecran seul (R-COM-08).
List<ActiviteStudio> fixturesActiviteStudioDemo(DateTime maintenant) {
  final DateTime m = maintenant.toUtc();
  DateTime il(int minutes) => m.subtract(Duration(minutes: minutes));
  DateTime dans(int jours) => m.add(Duration(days: jours));
  ObjetLie canal(String id, String nom) => ObjetLie(
    type: TypeObjetLie.canal,
    id: id,
    libelle: nom,
    destination: Routes.canalStudioPour(id),
  );
  return <ActiviteStudio>[
    // A traiter : une ligne Finance, urgente, sans page (R-COM-11) ; un
    // dossier a valider, qui ouvre SON dossier.
    ActiviteStudio(
      id: 'act-paiement',
      type: TypeActivite.changementModule,
      module: ModuleCanonique.finance,
      libelle: _f.activitePaiement,
      survenueLe: il(35),
      objet: ObjetLie(
        type: TypeObjetLie.autre,
        id: 'echeancier-haddad',
        libelle: _f.objetEcheancier,
      ),
      niveau: NiveauAttention.urgent,
      actionRequise: true,
    ),
    ActiviteStudio(
      id: 'act-dossier-karim',
      type: TypeActivite.changementModule,
      module: ModuleCanonique.dossiers,
      libelle: _f.activiteDossierKarim,
      survenueLe: il(80),
      objet: ObjetLie(
        type: TypeObjetLie.dossier,
        id: 'profil-karim',
        libelle: _f.objetDossierKarim,
        destination: Routes.adminPersonnesDossiers,
      ),
      niveau: NiveauAttention.actionRequise,
      actionRequise: true,
    ),
    // Mentions et reponses.
    ActiviteStudio(
      id: 'act-mention-admissions',
      type: TypeActivite.mention,
      module: ModuleCanonique.studio,
      libelle: _f.activiteMention,
      survenueLe: il(55),
      objet: canal('admissions', _f.canalAdmissions),
      auteur: Participant(id: 'p-samira', nomAffiche: _f.samira),
      niveau: NiveauAttention.aLire,
    ),
    ActiviteStudio(
      id: 'act-reponse-organisation',
      type: TypeActivite.reponse,
      module: ModuleCanonique.studio,
      libelle: _f.activiteReponse,
      survenueLe: il(40),
      objet: canal('organisation', _f.canalOrganisation),
      auteur: Participant(id: 'p-amina', nomAffiche: _f.amina),
      niveau: NiveauAttention.aLire,
    ),
    // Decisions en attente : Planning (sans page), puis une Classe.
    ActiviteStudio(
      id: 'act-decision-remplacement',
      type: TypeActivite.decisionDemandee,
      module: ModuleCanonique.planning,
      libelle: _f.activiteRemplacant,
      survenueLe: il(150),
      objet: ObjetLie(
        type: TypeObjetLie.remplacement,
        id: 'remplacement-mardi',
        libelle: _f.objetRemplacement,
      ),
      auteur: Participant(id: 'p-ibrahim', nomAffiche: _f.ibrahim),
      niveau: NiveauAttention.actionRequise,
      actionRequise: true,
    ),
    ActiviteStudio(
      id: 'act-decision-classe',
      type: TypeActivite.decisionDemandee,
      module: ModuleCanonique.classes,
      libelle: _f.activiteOuverture,
      survenueLe: il(60 * 5),
      objet: ObjetLie(
        type: TypeObjetLie.classe,
        id: 'classe-samedi',
        libelle: _f.objetClasseSamedi,
        destination: Routes.adminOperationsGroupes,
      ),
      auteur: Participant(id: 'p-mariam', nomAffiche: _f.mariam),
      lu: true,
      actionRequise: true,
    ),
    // Echeances proches.
    ActiviteStudio(
      id: 'act-echeance-cloture',
      type: TypeActivite.changementModule,
      module: ModuleCanonique.finance,
      libelle: _f.activiteCloture,
      survenueLe: il(60 * 24),
      objet: ObjetLie(
        type: TypeObjetLie.autre,
        id: 'cloture-septembre',
        libelle: _f.objetCloture,
      ),
      lu: true,
      echeance: dans(2),
    ),
    ActiviteStudio(
      id: 'act-echeance-bilans',
      type: TypeActivite.changementModule,
      module: ModuleCanonique.classes,
      libelle: _f.activiteBilans,
      survenueLe: il(60 * 30),
      objet: ObjetLie(
        type: TypeObjetLie.classe,
        id: 'bilans-mi-parcours',
        libelle: _f.objetBilans,
        destination: Routes.adminOperationsGroupes,
      ),
      lu: true,
      echeance: dans(5),
    ),
    // Activite recente.
    ActiviteStudio(
      id: 'act-messages-organisation',
      type: TypeActivite.messageNonLu,
      module: ModuleCanonique.studio,
      libelle: _f.activiteMessages,
      survenueLe: il(20),
      objet: canal('organisation', _f.canalOrganisation),
      niveau: NiveauAttention.aLire,
    ),
    ActiviteStudio(
      id: 'act-annonce',
      type: TypeActivite.annonceImportante,
      module: ModuleCanonique.communications,
      libelle: _f.activiteAnnonce,
      survenueLe: il(60 * 3),
      objet: ObjetLie(
        type: TypeObjetLie.annonce,
        id: 'annonce-fermeture',
        libelle: _f.objetFermeture,
        destination: Routes.adminCommunicationsAnnonces,
      ),
      lu: true,
    ),
    ActiviteStudio(
      id: 'act-fichier-planning',
      type: TypeActivite.fichierPartage,
      module: ModuleCanonique.studio,
      libelle: _f.activiteFichier(nom: _f.mariam, fichier: _f.fichierPlanning),
      survenueLe: il(95),
      objet: canal('organisation', _f.canalOrganisation),
      auteur: Participant(id: 'p-mariam', nomAffiche: _f.mariam),
      lu: true,
    ),
    ActiviteStudio(
      id: 'act-inscription',
      type: TypeActivite.changementModule,
      module: ModuleCanonique.admissions,
      libelle: _f.activiteInscription,
      survenueLe: il(60 * 6),
      objet: ObjetLie(
        type: TypeObjetLie.dossier,
        id: 'profil-benali',
        libelle: _f.objetDossierBenali,
        destination: Routes.adminPersonnesDossiers,
      ),
      lu: true,
    ),
    // Le canal prive dont la personne n'est pas membre : le serveur ne
    // rendrait pas cette ligne.
    ActiviteStudio(
      id: 'act-prive',
      type: TypeActivite.mention,
      module: ModuleCanonique.studio,
      libelle: _f.activiteBudget,
      survenueLe: il(10),
      objet: canal(canalPriveAbsentDemo, _f.canalDirection),
      niveau: NiveauAttention.urgent,
    ),
  ];
}

/// L'activite du Studio de la demonstration : en memoire, sans serveur.
/// Jamais branchee hors de `environnementAutoriseDemo`.
///
/// Comme le ferait le serveur, elle ne rend JAMAIS une ligne d'un canal
/// absent pour la personne (R-COM-08), ni de ligne de canal quand aucun
/// canal ne lui est ouvert. Hors ligne, le contenu deja lu reste (le
/// bandeau le dit).
class ActiviteStudioDemo implements PortActiviteStudio {
  /// Cree le port dans [situation]. [maintenant] fixe l'heure des fixtures
  /// (les tests la donnent).
  ActiviteStudioDemo({
    this.situation = SituationDemoStudio.normale,
    DateTime? maintenant,
  }) : _lignes = situation == SituationDemoStudio.aujourdhuiVide
           ? <ActiviteStudio>[]
           : fixturesActiviteStudioDemo(maintenant ?? DateTime.now());

  /// La situation mise en scene.
  final SituationDemoStudio situation;

  final List<ActiviteStudio> _lignes;

  /// Les lignes marquees lues, dans l'ordre (pour les tests).
  final List<String> marqueesLues = <String>[];

  bool _autorisee(ActiviteStudio a) {
    if (a.objet.type != TypeObjetLie.canal) return true;
    if (situation == SituationDemoStudio.sansCanaux) return false;
    return a.objet.id != canalPriveAbsentDemo;
  }

  @override
  Future<List<ActiviteStudio>> activites() async {
    return <ActiviteStudio>[
      for (final ActiviteStudio a in _lignes)
        if (_autorisee(a)) a,
    ];
  }

  @override
  Future<void> marquerLu(String activiteId) async {
    marqueesLues.add(activiteId);
    for (int i = 0; i < _lignes.length; i++) {
      if (_lignes[i].id == activiteId) _lignes[i] = _lignes[i].marqueeLue();
    }
  }
}
