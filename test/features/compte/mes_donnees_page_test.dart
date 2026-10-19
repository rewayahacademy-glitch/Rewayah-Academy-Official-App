// CPT-SUPPR-EXPORT : l'ecran « Mes donnees » du Compte. Les cinq etats
// (chargement, contenu, vide, erreur, hors ligne), le telechargement de la
// copie, la demande de suppression avec sa confirmation, l'annulation, et la
// rubrique qui n'existe que si le port repond.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_mes_donnees.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_enregistrement_fichier.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/mes_donnees_page.dart';

import 'support_compte.dart';

final DateTime _demandeeLe = DateTime(2026, 10, 18, 10);

SituationSuppression _vide({
  List<Montant> dus = const <Montant>[],
  int seances = 0,
}) => SituationSuppression(
  delaiJours: 14,
  montantsDus: dus,
  seancesAVenir: seances,
);

SituationSuppression _enCours() => SituationSuppression(
  delaiJours: 14,
  montantsDus: const <Montant>[],
  seancesAVenir: 0,
  demande: DemandeSuppression(
    id: 'd1',
    delaiJours: 14,
    demandeeLe: _demandeeLe,
    echeanceLe: _demandeeLe.add(const Duration(days: 14)),
  ),
);

/// Un port a l'etat modifiable : demander et annuler le font evoluer.
class _FauxPort implements PortMesDonnees {
  _FauxPort({SituationSuppression? depart, this.erreurSituation})
    : etat = depart ?? _vide();

  SituationSuppression etat;
  Object? erreurSituation;
  Object? erreurExport;
  Object? erreurAction;
  Completer<SituationSuppression>? attente;
  int lectures = 0;
  final List<String?> demandes = <String?>[];
  int annulations = 0;
  int exports = 0;

  @override
  Future<CopieDonnees> exporter() {
    exports++;
    final Object? e = erreurExport;
    if (e != null) return Future<CopieDonnees>.error(e);
    return Future<CopieDonnees>.value(
      const CopieDonnees(
        octets: <int>[123, 125],
        nomFichier: 'rewayah-mes-donnees-2026-10-18.json',
      ),
    );
  }

  @override
  Future<SituationSuppression> situation() {
    lectures++;
    final Completer<SituationSuppression>? a = attente;
    if (a != null) return a.future;
    final Object? e = erreurSituation;
    if (e != null) return Future<SituationSuppression>.error(e);
    return Future<SituationSuppression>.value(etat);
  }

  @override
  Future<void> demander({String? motif}) {
    final Object? e = erreurAction;
    if (e != null) return Future<void>.error(e);
    demandes.add(motif);
    etat = _enCours();
    return Future<void>.value();
  }

  @override
  Future<void> annuler() {
    final Object? e = erreurAction;
    if (e != null) return Future<void>.error(e);
    annulations++;
    etat = _vide();
    return Future<void>.value();
  }
}

class _FauxEnregistrement implements PortEnregistrementFichier {
  _FauxEnregistrement({this.destination = 'file:///copie.json'});

  String? destination;
  final List<({String nom, String mime, List<int> octets})> appels =
      <({String nom, String mime, List<int> octets})>[];

  @override
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    appels.add((nom: nomFichierPropose, mime: typeMime, octets: octets));
    return destination;
  }
}

List<Override> _surcharges(
  _FauxPort port,
  _FauxEnregistrement fichier, {
  bool horsLigne = false,
}) => <Override>[
  portMesDonneesProvider.overrideWithValue(port),
  portEnregistrementFichierProvider.overrideWithValue(fichier),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
];

Future<void> _monter(
  WidgetTester tester,
  _FauxPort port,
  _FauxEnregistrement fichier, {
  bool horsLigne = false,
  Size taille = const Size(390, 844),
}) => monterEcran(
  tester,
  const MesDonneesPage(),
  surcharges: _surcharges(port, fichier, horsLigne: horsLigne),
  taille: taille,
);

final Finder _telecharger = find.byKey(MesDonneesPage.actionKey);
final Finder _demander = find.byKey(MesDonneesPage.demanderKey);
final Finder _annuler = find.byKey(MesDonneesPage.annulerKey);

void main() {
  final d = t.compte.donnees;

  group('contenu', () {
    testWidgets('sans demande : le delai, la copie, la demande possible', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _FauxPort(), _FauxEnregistrement());
      expect(find.text(d.titre), findsWidgets);
      expect(find.text(d.copie.intro), findsOneWidget);
      expect(find.text(d.copie.exclus), findsOneWidget);
      expect(find.text(d.suppression.intro(n: 14)), findsOneWidget);
      expect(find.text(d.suppression.effacement), findsOneWidget);
      expect(find.text(d.suppression.conservation), findsOneWidget);
      // L'etat vide : rien en cours, et la demande reste possible.
      expect(find.byKey(MesDonneesPage.aucuneDemandeKey), findsOneWidget);
      expect(_demander, findsOneWidget);
      expect(_annuler, findsNothing);
      expect(_telecharger, findsOneWidget);
      expect(find.text(d.suppression.soldeTitre), findsNothing);
      expect(find.text(d.suppression.seancesTitre), findsNothing);
    });

    testWidgets(
      'le delai affiche suit la configuration, pas une valeur en dur',
      (WidgetTester tester) async {
        await _monter(
          tester,
          _FauxPort(
            depart: const SituationSuppression(
              delaiJours: 3,
              montantsDus: <Montant>[],
              seancesAVenir: 0,
            ),
          ),
          _FauxEnregistrement(),
        );
        expect(find.text(d.suppression.intro(n: 3)), findsOneWidget);
        expect(find.text(d.suppression.intro(n: 14)), findsNothing);
      },
    );

    testWidgets(
      'un solde et des seances a venir sont dits, la demande reste possible',
      (WidgetTester tester) async {
        await _monter(
          tester,
          _FauxPort(
            depart: _vide(
              dus: const <Montant>[Montant(4500, 'USD')],
              seances: 2,
            ),
          ),
          _FauxEnregistrement(),
        );
        expect(find.text(d.suppression.soldeTitre), findsOneWidget);
        expect(find.textContaining('45'), findsWidgets);
        expect(find.text(d.suppression.seancesTitre), findsOneWidget);
        expect(find.text(d.suppression.seancesDetail(n: 2)), findsOneWidget);
        expect(_demander, findsOneWidget);
      },
    );

    testWidgets('une demande en cours : ses dates et l annulation', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(depart: _enCours()),
        _FauxEnregistrement(),
      );
      expect(find.text(d.suppression.enCoursTitre), findsOneWidget);
      expect(_annuler, findsOneWidget);
      expect(_demander, findsNothing);
      expect(find.byKey(MesDonneesPage.motifKey), findsNothing);
    });
  });

  group('etats', () {
    testWidgets('chargement : un squelette, la copie reste disponible', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort()
        ..attente = Completer<SituationSuppression>();
      await _monter(tester, port, _FauxEnregistrement());
      expect(find.byType(Skeleton), findsWidgets);
      expect(_telecharger, findsOneWidget);
      expect(_demander, findsNothing);
    });

    testWidgets('erreur : la page reste, un Reessayer relit', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(erreurSituation: Exception('panne'));
      await _monter(tester, port, _FauxEnregistrement());
      expect(_telecharger, findsOneWidget);
      expect(_demander, findsNothing);
      final int avant = port.lectures;
      port.erreurSituation = null;
      await toucher(tester, find.text(t.commun.reessayer));
      expect(port.lectures, greaterThan(avant));
      expect(_demander, findsOneWidget);
    });

    testWidgets('hors ligne : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(erreurSituation: Exception('reseau')),
        _FauxEnregistrement(),
        horsLigne: true,
      );
      expect(find.text(t.sansDonnees.mesDonnees), findsOneWidget);
      expect(_demander, findsNothing);
    });

    testWidgets('permission refusee : une phrase, aucune action', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _FauxPort(erreurSituation: const PermissionInsuffisante('x')),
        _FauxEnregistrement(),
      );
      expect(find.text(d.suppression.refuse), findsOneWidget);
      expect(_demander, findsNothing);
    });
  });

  group('copie', () {
    testWidgets('telecharge un fichier JSON et le dit', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort();
      final _FauxEnregistrement fichier = _FauxEnregistrement();
      await _monter(tester, port, fichier);
      await toucher(tester, _telecharger);
      expect(port.exports, 1);
      expect(fichier.appels, hasLength(1));
      expect(fichier.appels.single.nom, 'rewayah-mes-donnees-2026-10-18.json');
      expect(fichier.appels.single.mime, 'application/json');
      expect(fichier.appels.single.octets, <int>[123, 125]);
      expect(find.text(d.copie.reussi), findsOneWidget);
    });

    testWidgets('renoncer au selecteur de fichiers n est pas une erreur', (
      WidgetTester tester,
    ) async {
      final _FauxEnregistrement fichier = _FauxEnregistrement(
        destination: null,
      );
      await _monter(tester, _FauxPort(), fichier);
      await toucher(tester, _telecharger);
      expect(fichier.appels, hasLength(1));
      expect(find.byKey(MesDonneesPage.retourCopieKey), findsNothing);
    });

    testWidgets('un echec le dit et ne pretend rien d enregistre', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort()..erreurExport = Exception('panne');
      final _FauxEnregistrement fichier = _FauxEnregistrement();
      await _monter(tester, port, fichier);
      await toucher(tester, _telecharger);
      expect(find.text(d.copie.echec), findsOneWidget);
      expect(find.text(d.copie.reussi), findsNothing);
      expect(fichier.appels, isEmpty);
    });

    testWidgets('hors ligne, la phrase dit de se reconnecter', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort()..erreurExport = Exception('reseau');
      await _monter(tester, port, _FauxEnregistrement(), horsLigne: true);
      await toucher(tester, _telecharger);
      expect(find.text(d.copie.horsLigne), findsOneWidget);
    });

    testWidgets('un refus du serveur est dit', (WidgetTester tester) async {
      final _FauxPort port = _FauxPort()
        ..erreurExport = const PermissionInsuffisante('x');
      await _monter(tester, port, _FauxEnregistrement());
      await toucher(tester, _telecharger);
      expect(find.text(d.copie.refuse), findsOneWidget);
    });
  });

  group('suppression', () {
    testWidgets('demander passe par une confirmation, envoie le motif', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort();
      await _monter(tester, port, _FauxEnregistrement());
      await tester.enterText(
        find.descendant(
          of: find.byKey(MesDonneesPage.motifKey),
          matching: find.byType(EditableText),
        ),
        '  Nous déménageons  ',
      );
      await toucher(tester, _demander);
      // La confirmation dit la consequence avant d'agir.
      expect(find.text(d.suppression.confirmerQuestion), findsWidgets);
      expect(
        find.text(d.suppression.confirmerConsequence(n: 14)),
        findsOneWidget,
      );
      expect(port.demandes, isEmpty);
      await toucher(tester, find.text(d.suppression.confirmerAction));
      expect(port.demandes, <String?>['Nous déménageons']);
      expect(find.text(d.suppression.demandeEnvoyee), findsOneWidget);
      // La page relit : la demande est en cours, l'annulation est offerte.
      expect(find.text(d.suppression.enCoursTitre), findsOneWidget);
      expect(_annuler, findsOneWidget);
      expect(_demander, findsNothing);
    });

    testWidgets('garder son compte dans la confirmation n envoie rien', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort();
      await _monter(tester, port, _FauxEnregistrement());
      await toucher(tester, _demander);
      await toucher(tester, find.text(d.suppression.confirmerRester));
      expect(port.demandes, isEmpty);
      expect(find.text(d.suppression.demandeEnvoyee), findsNothing);
      expect(_demander, findsOneWidget);
    });

    testWidgets('sans motif, aucun motif n est envoye', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort();
      await _monter(tester, port, _FauxEnregistrement());
      await toucher(tester, _demander);
      await toucher(tester, find.text(d.suppression.confirmerAction));
      expect(port.demandes, <String?>[null]);
    });

    testWidgets('annuler la demande en cours', (WidgetTester tester) async {
      final _FauxPort port = _FauxPort(depart: _enCours());
      await _monter(tester, port, _FauxEnregistrement());
      await toucher(tester, _annuler);
      expect(port.annulations, 1);
      expect(find.text(d.suppression.demandeAnnulee), findsOneWidget);
      expect(_demander, findsOneWidget);
      expect(_annuler, findsNothing);
    });

    testWidgets('un echec le dit, le compte n a pas change', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort()..erreurAction = Exception('panne');
      await _monter(tester, port, _FauxEnregistrement());
      await toucher(tester, _demander);
      await toucher(tester, find.text(d.suppression.confirmerAction));
      expect(find.text(d.suppression.echec), findsOneWidget);
      expect(find.text(d.suppression.demandeEnvoyee), findsNothing);
      expect(_demander, findsOneWidget);
    });

    testWidgets('hors ligne, la phrase dit de se reconnecter', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(depart: _enCours())
        ..erreurAction = Exception('reseau');
      await _monter(tester, port, _FauxEnregistrement(), horsLigne: true);
      await toucher(tester, _annuler);
      expect(find.text(d.suppression.horsLigne), findsOneWidget);
      expect(_annuler, findsOneWidget);
    });
  });

  group('lisibilite', () {
    for (final (String nom, Size taille) in <(String, Size)>[
      ('320 px', const Size(320, 700)),
      ('1440 px', const Size(1440, 900)),
    ]) {
      testWidgets('aucun debordement a $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          _FauxPort(
            depart: _vide(
              dus: const <Montant>[Montant(4500, 'USD')],
              seances: 3,
            ),
          ),
          _FauxEnregistrement(),
          taille: taille,
        );
        expect(tester.takeException(), isNull);
        expect(_telecharger, findsOneWidget);
      });
    }
  });

  group('rubrique du Compte', () {
    Future<void> monterRubrique(
      WidgetTester tester,
      PortMesDonnees port, {
      required VoidCallback onOuvrir,
    }) => monterEcran(
      tester,
      Scaffold(body: RubriqueMesDonnees(onOuvrir: onOuvrir)),
      surcharges: <Override>[portMesDonneesProvider.overrideWithValue(port)],
    );

    testWidgets('visible quand le port repond, ouvre l ecran', (
      WidgetTester tester,
    ) async {
      int ouvertures = 0;
      await monterRubrique(tester, _FauxPort(), onOuvrir: () => ouvertures++);
      expect(find.byKey(RubriqueMesDonnees.ligneKey), findsOneWidget);
      await toucher(tester, find.text(d.ligne));
      expect(ouvertures, 1);
    });

    testWidgets('absente quand la capacite n existe pas', (
      WidgetTester tester,
    ) async {
      await monterRubrique(
        tester,
        const MesDonneesIndisponibles(),
        onOuvrir: () {},
      );
      expect(find.byKey(RubriqueMesDonnees.ligneKey), findsNothing);
      expect(find.text(d.ligne), findsNothing);
    });

    testWidgets('absente quand le serveur refuse ce compte', (
      WidgetTester tester,
    ) async {
      await monterRubrique(
        tester,
        _FauxPort(erreurSituation: const PermissionInsuffisante('x')),
        onOuvrir: () {},
      );
      expect(find.byKey(RubriqueMesDonnees.ligneKey), findsNothing);
    });

    testWidgets('presente sur une panne : la page dira l echec', (
      WidgetTester tester,
    ) async {
      await monterRubrique(
        tester,
        _FauxPort(erreurSituation: Exception('panne')),
        onOuvrir: () {},
      );
      expect(find.byKey(RubriqueMesDonnees.ligneKey), findsOneWidget);
    });

    test('une capacite indisponible se dit CapaciteIndisponible', () {
      expect(
        const MesDonneesIndisponibles().situation(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('arabe', () {
    test('chaque pluriel de jours et de seances est traduit', () async {
      final Traductions ar = await AppLocale.ar.build();
      final suppression = ar.compte.donnees.suppression;
      final Set<String> intros = <String>{
        for (final int n in <int>[0, 1, 2, 3, 11, 100]) suppression.intro(n: n),
      };
      expect(intros, hasLength(6), reason: 'zero, one, two, few, many, other');
      final Set<String> consequences = <String>{
        for (final int n in <int>[0, 1, 2, 3, 11, 100])
          suppression.confirmerConsequence(n: n),
      };
      expect(consequences, hasLength(6));
      final Set<String> seances = <String>{
        for (final int n in <int>[0, 1, 2, 3, 11, 100])
          suppression.seancesDetail(n: n),
      };
      expect(seances, hasLength(6));
      // Le nombre est isole dans le texte arabe, jamais colle au latin.
      expect(suppression.intro(n: 3), contains('\u2068'));
      expect(
        suppression.soldeDetail(montant: '45 USD'),
        contains('\u206845 USD\u2069'),
      );
    });
  });
}
