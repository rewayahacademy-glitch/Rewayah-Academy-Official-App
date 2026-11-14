// SYNCHRO-SESSION (13/11/2026, `docs/current/salle/HARMONIE-2026-11-13.md`
// section 7, journal D-045) : la vraie page `/salle` (`SallePage`, faux
// moteur, controleur de session de l'application) qu'on ferme (salle reduite)
// et qu'on rouvre, sans quitter l'appel. La synchronisation et la Dynamique
// chrono vivent avec l'appel : ce qui arrive pendant que la page est fermee
// est la a son retour, une seule fois ; les traits survivent ; l'enseignant
// qui a reduit la salle rejoue la page a qui entre ; quitter ne laisse rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/gestes_salle.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/seance_vivante.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;
import 'package:rewayah_academy/features/salle_seance/dynamique_chrono.dart';
import 'package:rewayah_academy/features/salle_seance/notes_deposees.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart' show FauxMoteurSalle;
import '../support/salle_chrono.dart';

/// Les gestes de l'enseignant, sans reseau.
class _Gestes implements PortGestesSalle {
  @override
  Future<void> appliquer(
    String seanceId,
    String eleveId,
    GesteSalle geste,
  ) async {}

  @override
  Future<IssueRecitation> faireReciter(String seanceId, String eleveId) async =>
      IssueRecitation.ouverte;

  @override
  Future<void> terminerRecitation(String seanceId, {String? eleveId}) async {}

  @override
  Future<void> readmettre(String seanceId, String eleveId) async {}

  @override
  Future<List<EleveSorti>> sortis(String seanceId) async =>
      const <EleveSorti>[];
}

ParticipantSalle _qui(String id, String role, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: id == 'e2' ? 'Aicha' : '',
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

PaquetDonnees _parole(String? profil, String prenom) => PaquetDonnees(
  sujet: sujetProtocolePedagogique,
  charge: messageVersOctets(
    MessagePedagogique(
      type: typeParoleSalle,
      sessionId: 's1',
      emetteurProfilId: 't1',
      charge: profil == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'profil': profil, 'prenom': prenom},
      emisLeUtc: DateTime.now().toUtc(),
    ),
  ),
  fiable: true,
  emetteurIdentite: 't1',
);

const ContentPosition _page42 = ContentPosition.page(
  resourceId: 'mushaf-madina-15',
  resourceVersionId: '1',
  page: 42,
);

const Key _cleHote = ValueKey<String>('hote-salle');

/// La page qu'on ferme (salle reduite) et qu'on rouvre, dans le meme appel.
class _Salle {
  _Salle(this.moteur, this.ouverte, this.tester);

  final FauxMoteurSalle moteur;
  final ValueNotifier<bool> ouverte;
  final WidgetTester tester;

  ProviderContainer get conteneur =>
      ProviderScope.containerOf(tester.element(find.byKey(_cleHote)));

  ControleurSessionPersistante get controleur =>
      conteneur.read(controleurSessionProvider);

  SeanceVivante? get seance => seanceTenue(controleur, 's1');

  Future<void> fermer() async {
    ouverte.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SallePage), findsNothing);
  }

  Future<void> rouvrir() async {
    ouverte.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(SallePage), findsOneWidget);
  }
}

Future<_Salle> _monter(
  WidgetTester tester, {
  required String role,
  List<Override> autres = const <Override>[],
}) async {
  fixerVueCapture(tester, const Size(390, 844), 2);
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final ValueNotifier<bool> ouverte = ValueNotifier<bool>(true);
  addTearDown(ouverte.dispose);
  await tester.pumpWidget(
    hoteCapture(
      ValueListenableBuilder<bool>(
        key: _cleHote,
        valueListenable: ouverte,
        builder: (BuildContext _, bool salle, Widget? _) =>
            salle ? const SallePage(seanceId: 's1') : const SizedBox.expand(),
      ),
      surcharges: surchargesSalleChrono(
        role,
        moteur,
        moderer: role == 'teacher',
        autres: <Override>[
          signalRappelProvider.overrideWithValue(() {}),
          portGestesSalleProvider.overrideWithValue(_Gestes()),
          ...autres,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  moteur
    ..publier(<ParticipantSalle>[
      _qui('t1', 'teacher', local: role == 'teacher'),
      _qui('e1', 'student', local: role != 'teacher'),
    ])
    ..publierQualite(QualiteLien.bonne)
    ..publierContenu(
      ContenuPresente(
        page: 42,
        sourate: 2,
        verset: 255,
        presentePar: 't1',
        emisLe: DateTime.now(),
      ),
    );
  await tester.pumpAndSettle();
  return _Salle(moteur, ouverte, tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('reduire, recevoir une recitation, rouvrir la salle : la marque '
      'est la, une seule fois ; quitter : plus rien ne vit', (
    WidgetTester tester,
  ) async {
    final _Salle salle = await _monter(tester, role: 'student');
    final SeanceVivante? avant = salle.seance;
    expect(avant, isNotNull, reason: 'la seance nait avec l appel adopte');
    await salle.fermer();
    expect(salle.seance, same(avant), reason: 'elle survit a la page');

    final String titre = t.tc.classe.recitation.actif(prenom: 'Aicha');
    salle.moteur.recevoirDonnees(_parole('e2', 'Aicha'));
    await tester.pump();
    // Dite pendant que la page est fermee, par la seance de l'appel.
    expect(salle.seance!.dynamique.alerte?.titre, titre);
    await tester.pump(AppMouvement.alerteChrono);
    await tester.pump(AppMouvement.battementDynamique);
    expect(salle.seance!.dynamique.alerte, isNull);

    await salle.rouvrir();
    expect(salle.seance, same(avant));
    // L'alerte deja dite ne se rejoue pas ; la marque est la, une fois.
    expect(find.byKey(DynamiqueChrono.cleAlerte), findsNothing);
    final SemanticsHandle s = tester.ensureSemantics();
    expect(find.bySemanticsLabel(titre), findsOneWidget);
    s.dispose();

    await salle.fermer();
    final FauxMoteurSalle moteur = salle.moteur;
    await salle.controleur.quitter();
    await tester.pump();
    expect(avant!.libere, isTrue);
    expect(salle.seance, isNull);
    expect(moteur.ecouteParticipants, isFalse);
    expect(moteur.ecoutePaquets, isFalse);
    expect(moteur.ecouteContenus, isFalse);
    // Fin du test : le cadre verifie qu'aucune minuterie ne reste.
  });

  testWidgets('sortir de la page et revenir : les traits sont la', (
    WidgetTester tester,
  ) async {
    final _Salle salle = await _monter(tester, role: 'student');
    final SeanceVivante seance = salle.seance!;
    // Un trait recu de l'enseignant, pose dans le depot de la seance comme
    // le fait la reception (couche temporaire, sans seance).
    final AnnotationLayer couche = (await seance.synchro!.depot.couche(
      resourceId: _page42.resourceId,
      portee: PorteeAnnotation.temporaire,
    ))!;
    await seance.synchro!.depot.ajouterTrait(
      couche.id,
      const TraitVectoriel(
        id: 'trait-recu',
        ancrage: _page42,
        points: <PointNormalise>[
          PointNormalise(0.1, 0.2),
          PointNormalise(0.4, 0.25),
        ],
        outil: OutilTrait.stylet,
      ),
    );
    await tester.pump();
    await salle.fermer();
    await salle.rouvrir();
    final ProviderContainer portee = ProviderScope.containerOf(
      tester.element(find.byType(SalleSeance)),
    );
    expect(
      portee
          .read(notesDeposeesProvider(_page42.resourceId))
          .map((TraitVectoriel t) => t.id),
      <String>['trait-recu'],
    );
    await salle.fermer();
    await salle.controleur.quitter();
    await tester.pump();
  });

  testWidgets('l enseignant reduit la salle, un eleve entre : il recoit la '
      'page presentee', (WidgetTester tester) async {
    final _Salle salle = await _monter(tester, role: 'teacher');
    await salle.fermer();
    // Passe le calme de l'entree (ceux que la visio annonce tout de suite
    // ne sont pas des arrivees).
    for (int i = 0; i < 6; i++) {
      await tester.pump(AppMouvement.battementDynamique);
    }
    final int avant = salle.moteur.contenusPresentesDemandes.length;
    salle.moteur.publier(<ParticipantSalle>[
      _qui('t1', 'teacher', local: true),
      _qui('e1', 'student'),
      _qui('e2', 'student'),
    ]);
    await tester.pump();
    expect(salle.moteur.contenusPresentesDemandes.length, avant + 1);
    expect(salle.moteur.contenusPresentesDemandes.last.page, 42);
    // Et l'arrivee est dite par la meme Dynamique chrono.
    expect(
      salle.seance!.dynamique.alerte?.titre,
      t.salle.dynamique.arriveePrenom(prenom: 'Aicha'),
    );
    await tester.pump(AppMouvement.alerteArrivees);
    await tester.pump(AppMouvement.battementDynamique);
    await salle.controleur.quitter();
    await tester.pump();
  });
}
