// La demonstration de la voie COM-VOC (Message vocal) :
// `/demo/communications?voie=vocal&role=...`.
//
// **Jamais en production** : la route n'existe que sous
// `environnementAutoriseDemo` (`routesDemoCommunications`). Les doubles de ce
// fichier (faux enregistreur, lecture simulee) ne sont branches qu'ici, dans
// un `ProviderScope` propre a la page : l'application garde ses ports neutres
// (`EnregistreurVocalIndisponible`, `LectureVocaleIndisponible`), et aucun
// micro reel n'est ouvert (K-19 : ni `record` ni `permission_handler`).
//
// La page montre le composer dans l'emplacement vocal du composer des
// communications (`FilDiscussion.emplacementVocal`, pose par COM-F), un vocal
// recu (fixture section 26 : « 1 vocal ») et les vocaux envoyes. Cinq
// situations se choisissent avec `SelecteurSection` : micro autorise, a
// demander, refuse, envoi non confirme (le premier envoi echoue, le second
// passe), micro indisponible (le port neutre de production).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/communications/port_pieces_jointes.dart';
import '../../../core/communications/textes_fil_communication.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/controle_segmente.dart';
import '../../../core/widgets/fil_discussion.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pile_cartes.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/selecteur_section.dart';
import '../../../core/widgets/vue_etat_communication.dart';
import '../../com_vocal/composer_vocal.dart';
import '../../com_vocal/envoi_vocal.dart';
import '../../com_vocal/lecteur_vocal.dart';
import '../../com_vocal/port_enregistreur_vocal.dart';
import 'demo_communications_page.dart';

/// L'intervalle de la lecture simulee : la position avance chaque seconde.
const Duration _intervalleLecture = Duration(seconds: 1);

/// Le delai d'un envoi de demonstration, pour voir « Envoi en cours ».
const Duration _delaiEnvoi = Duration(seconds: 1);

/// La duree du vocal recu de demonstration (0:28, maquette COM-W01).
const Duration dureeVocalRecuDemo = Duration(seconds: 28);

/// La hauteur de la conversation de demonstration, a texte normal : le fil
/// demande une hauteur bornee, elle grandit avec le texte.
const double _hauteurConversation = 640;

/// Une lecture simulee : la position avance avec l'horloge, sans aucun son.
class LectureVocaleSimulee implements LectureVocale {
  /// Cree la lecture d'un vocal de duree [duree].
  LectureVocaleSimulee({required this.duree, required this.horloge});

  @override
  final Duration duree;

  /// L'horloge (fixe dans les tests).
  final HorlogeVocale horloge;

  final ValueNotifier<EtatLectureAudio> _etat = ValueNotifier<EtatLectureAudio>(
    const EtatLectureAudio(),
  );
  Duration _base = Duration.zero;
  DateTime? _debut;
  Timer? _tic;
  Timer? _fin;
  bool _liberee = false;

  @override
  ValueListenable<EtatLectureAudio> get etat => _etat;

  Duration get _position {
    final DateTime? debut = _debut;
    final Duration p = debut == null
        ? _base
        : _base + horloge().difference(debut);
    return p > duree ? duree : p;
  }

  void _arreterMinuteries() {
    _tic?.cancel();
    _fin?.cancel();
    _tic = null;
    _fin = null;
  }

  void _maj() {
    if (_liberee) return;
    final Duration p = _position;
    if (p >= duree) {
      _arreterMinuteries();
      _base = duree;
      _debut = null;
      _etat.value = EtatLectureAudio(position: duree, termine: true);
      return;
    }
    _etat.value = EtatLectureAudio(position: p, enLecture: _debut != null);
  }

  @override
  Future<void> lire() async {
    if (_liberee || _debut != null) return;
    if (_etat.value.termine) _base = Duration.zero;
    _debut = horloge();
    _tic = Timer.periodic(_intervalleLecture, (_) => _maj());
    _fin = Timer(duree - _base, _maj);
    _etat.value = EtatLectureAudio(position: _base, enLecture: true);
  }

  @override
  Future<void> mettreEnPause() async {
    if (_liberee || _debut == null) return;
    _base = _position;
    _debut = null;
    _arreterMinuteries();
    _maj();
  }

  @override
  Future<void> relire() async {
    if (_liberee) return;
    _arreterMinuteries();
    _debut = null;
    _base = Duration.zero;
    _etat.value = const EtatLectureAudio();
    await lire();
  }

  @override
  Future<void> liberer() async {
    if (_liberee) return;
    _liberee = true;
    _arreterMinuteries();
    _etat.dispose();
  }
}

/// Le faux enregistreur de la demonstration : aucun micro, une permission
/// choisie par la situation, des vocaux qui ne sont que des durees.
class EnregistreurVocalDemonstration implements PortEnregistreurVocal {
  /// Cree l'enregistreur.
  EnregistreurVocalDemonstration({
    required this.horloge,
    PermissionMicro permissionInitiale = PermissionMicro.accordee,
    this.reponseALaDemande = PermissionMicro.accordee,
  }) : _permission = permissionInitiale;

  /// L'horloge des pre-ecoutes.
  final HorlogeVocale horloge;

  /// La reponse a la demande d'autorisation.
  final PermissionMicro reponseALaDemande;

  PermissionMicro _permission;
  int _compteur = 0;
  bool _actif = false;

  /// Les vocaux effaces (pour les tests).
  final List<String> supprimes = <String>[];

  /// Le nombre d'enregistrements abandonnes (pour les tests).
  int abandons = 0;

  /// Vrai si un enregistrement est en cours ou en pause.
  bool get actif => _actif;

  @override
  Future<PermissionMicro> permission() async => _permission;

  @override
  Future<PermissionMicro> demanderPermission() async {
    _permission = reponseALaDemande;
    return _permission;
  }

  @override
  Future<void> demarrer() async {
    if (_permission != PermissionMicro.accordee) {
      throw StateError('Microphone non autorise.');
    }
    _actif = true;
  }

  @override
  Future<void> mettreEnPause() async {}

  @override
  Future<void> reprendre() async {}

  @override
  Future<EnregistrementVocal> arreter({required Duration duree}) async {
    _actif = false;
    return EnregistrementVocal(id: 'vocal-demo-${++_compteur}', duree: duree);
  }

  @override
  Future<void> abandonner() async {
    _actif = false;
    abandons++;
  }

  @override
  Future<void> supprimer(EnregistrementVocal vocal) async {
    supprimes.add(vocal.id);
  }

  @override
  Future<LectureVocale> preEcoute(EnregistrementVocal vocal) async =>
      LectureVocaleSimulee(duree: vocal.duree, horloge: horloge);
}

/// La lecture des vocaux recus en demonstration : une lecture simulee.
class LecturesVocalesDemonstration implements PortLectureVocale {
  /// Cree le port.
  const LecturesVocalesDemonstration({required this.horloge});

  /// L'horloge des lectures.
  final HorlogeVocale horloge;

  @override
  Future<LectureVocale> ouvrir(PieceJointe vocal) async => LectureVocaleSimulee(
    duree: vocal.duree ?? dureeVocalRecuDemo,
    horloge: horloge,
  );
}

/// L'envoi des vocaux en demonstration : un accuse apres un court delai,
/// aucun serveur. Les vocaux acceptes sont gardes pour les tests.
class EnvoiVocalDemonstration implements PortEnvoiVocal {
  /// Cree l'envoi de demonstration.
  EnvoiVocalDemonstration({this.delai = _delaiEnvoi});

  /// Le delai avant l'accuse, pour voir « Envoi en cours ».
  final Duration delai;

  /// Les cles acceptees, dans l'ordre (pour les tests).
  final List<String> cles = <String>[];

  @override
  Future<void> envoyer({
    required DestinationVocal destination,
    required EnregistrementVocal vocal,
    required String cleIdempotence,
  }) async {
    await Future<void>.delayed(delai);
    cles.add(cleIdempotence);
  }
}

/// Les doubles du vocal pour une autre demonstration (Messages, Studio,
/// COM-FUS) : faux enregistreur autorise, lecture simulee, envoi accuse.
/// Hors production seulement : ces surcharges ne sont posees que par les
/// pages de `/demo/communications`, sous `environnementAutoriseDemo`. La
/// capacite `envoyerVocal` s'ouvre a part, avec les autres capacites de la
/// demonstration.
List<Override> surchargesVocalDemo({HorlogeVocale horloge = DateTime.now}) =>
    <Override>[
      portEnregistreurVocalProvider.overrideWithValue(
        EnregistreurVocalDemonstration(horloge: horloge),
      ),
      portLectureVocaleProvider.overrideWithValue(
        LecturesVocalesDemonstration(horloge: horloge),
      ),
      portEnvoiVocalProvider.overrideWithValue(EnvoiVocalDemonstration()),
    ];

/// Les situations de la demonstration.
enum ScenarioVocalDemo {
  /// Le micro est autorise.
  autorise,

  /// L'autorisation doit etre demandee (puis accordee).
  aDemander,

  /// Le micro est refuse.
  refuse,

  /// Le premier envoi n'est pas confirme, le second passe.
  nonConfirme,

  /// Aucun enregistreur : le port neutre de production.
  indisponible,
}

/// Le libelle d'une situation.
String libelleScenarioVocalDemo(ScenarioVocalDemo s) {
  final d = t.com.vocal.demo;
  return switch (s) {
    ScenarioVocalDemo.autorise => d.autorise,
    ScenarioVocalDemo.aDemander => d.aDemander,
    ScenarioVocalDemo.refuse => d.refuse,
    ScenarioVocalDemo.nonConfirme => d.nonConfirme,
    ScenarioVocalDemo.indisponible => d.indisponible,
  };
}

/// Le vocal recu de la demonstration (fixture section 26).
final PieceJointe vocalRecuDemo = PieceJointe(
  reference: ReferencePieceJointe('vocal_demo_recu'),
  nom: 'message-vocal.m4a',
  nature: NaturePieceJointe.vocal,
  typeLisible: 'Audio',
  duree: dureeVocalRecuDemo,
  peutOuvrir: true,
);

/// La demonstration de la voie COM-VOC.
class ComVocalDemo extends ConsumerStatefulWidget {
  /// Cree la demonstration de la voie.
  const ComVocalDemo({super.key, this.role});

  /// Le role mis en scene (`?role=`) : il choisit l'auteur du vocal recu
  /// (une famille pour l'enseignant, l'enseignante sinon). Un choix
  /// d'affichage, jamais un role de session.
  final RoleDemoCommunications? role;

  /// La cle de la conversation de demonstration.
  static const ValueKey<String> cleConversation = ValueKey<String>(
    'vocal-demo-conversation',
  );

  @override
  ConsumerState<ComVocalDemo> createState() => _ComVocalDemoState();
}

class _ComVocalDemoState extends ConsumerState<ComVocalDemo> {
  ScenarioVocalDemo _scenario = ScenarioVocalDemo.autorise;
  late final HorlogeVocale _horloge = ref.read(horlogeVocaleProvider);
  late EnregistreurVocalDemonstration _enregistreur = _creer(_scenario);
  late final PortLectureVocale _lectures = LecturesVocalesDemonstration(
    horloge: _horloge,
  );
  final List<EnregistrementVocal> _envoyes = <EnregistrementVocal>[];
  bool _premierEnvoiEchoue = false;

  EnregistreurVocalDemonstration _creer(ScenarioVocalDemo s) =>
      EnregistreurVocalDemonstration(
        horloge: _horloge,
        permissionInitiale: switch (s) {
          ScenarioVocalDemo.aDemander => PermissionMicro.aDemander,
          ScenarioVocalDemo.refuse => PermissionMicro.refusee,
          _ => PermissionMicro.accordee,
        },
      );

  void _choisir(ScenarioVocalDemo s) {
    setState(() {
      _scenario = s;
      _enregistreur = _creer(s);
      _premierEnvoiEchoue = false;
    });
  }

  Future<void> _envoyer(EnregistrementVocal vocal) async {
    await Future<void>.delayed(_delaiEnvoi);
    if (_scenario == ScenarioVocalDemo.nonConfirme && !_premierEnvoiEchoue) {
      _premierEnvoiEchoue = true;
      throw StateError('Envoi de demonstration non confirme.');
    }
    if (mounted) setState(() => _envoyes.add(vocal));
  }

  @override
  Widget build(BuildContext context) {
    final d = t.com.vocal.demo;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String auteur = widget.role == RoleDemoCommunications.enseignant
        ? d.auteurParent
        : d.auteurEnseignante;
    return ProviderScope(
      overrides: <Override>[
        portEnregistreurVocalProvider.overrideWithValue(
          _scenario == ScenarioVocalDemo.indisponible
              ? const EnregistreurVocalIndisponible()
              : _enregistreur,
        ),
        portLectureVocaleProvider.overrideWithValue(_lectures),
      ],
      child: PageShell(
        titre: t.com.vocal.titre,
        sousTitre: t.com.socle.navigation.demo.detail,
        onRetour: () => GoRouter.of(context).go(Routes.demoCommunications),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const BandeauHorsLigneCommunication(),
            Text(
              d.contexte,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vLg,
            SelecteurSection<ScenarioVocalDemo>(
              libelle: d.situations,
              sections: <Segment<ScenarioVocalDemo>>[
                for (final ScenarioVocalDemo s in ScenarioVocalDemo.values)
                  Segment<ScenarioVocalDemo>(
                    valeur: s,
                    libelle: libelleScenarioVocalDemo(s),
                  ),
              ],
              valeur: _scenario,
              onChange: _choisir,
            ),
            Ecart.vXxl,
            SectionHeader(titre: d.recu),
            Ecart.vMd,
            AppCard(
              child: LecteurVocalRecu(
                key: const ValueKey<String>('vocal-demo-recu'),
                vocal: vocalRecuDemo,
                auteur: auteur,
              ),
            ),
            Ecart.vXxl,
            SectionHeader(titre: d.repondre),
            Ecart.vMd,
            SizedBox(
              key: ComVocalDemo.cleConversation,
              height: MediaQuery.textScalerOf(context)
                  .scale(_hauteurConversation),
              child: FilDiscussion(
                messages: <MessageFil>[
                  MessageFil(
                    id: 'vocal-demo-message',
                    auteur: auteur,
                    texte: d.messageRecu,
                    horodatage: d.horodatage,
                    deSoi: false,
                  ),
                ],
                textes: textesFilCommunication(),
                onEnvoyer: (String _) async {},
                emplacementVocal: ComposerVocal(
                  key: ValueKey<ScenarioVocalDemo>(_scenario),
                  onEnvoyer: _envoyer,
                ),
              ),
            ),
            if (_envoyes.isNotEmpty) ...<Widget>[
              Ecart.vXxl,
              SectionHeader(titre: d.envoyes),
              Ecart.vMd,
              PileCartes(
                children: <Widget>[
                  for (final EnregistrementVocal v in _envoyes)
                    AppCard(
                      key: ValueKey<String>('vocal-demo-envoye-${v.id}'),
                      child: LecteurVocal(
                        ouvrir: () async => LectureVocaleSimulee(
                          duree: v.duree,
                          horloge: _horloge,
                        ),
                        duree: v.duree,
                        auteur: t.com.socle.composants.composer.auteurSoi,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
