// I1 (02/11/2026) : l'invitation des familles importees, la marque de
// l'invitation d'enseignant en cours (UX-013, UX-017), et la page d'un lien
// de connexion deja servi (UX-018).
//
// Ce que le test prouve : les etats du bloc des familles (port absent,
// chargement, contenu, vide, erreur, hors ligne), l'envoi a une famille (le
// port est appele, le message le dit, la liste est relue), l'envoi a toutes
// derriere une confirmation qui dit le nombre (annuler n'envoie rien), le
// refus quand le nombre a change ; la marque d'invitation (code garde,
// expiration, effacement) ; 320 px texte x2 sans debordement.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_invitations/familles_importees.dart';
import 'package:rewayah_academy/features/admin_invitations/familles_importees_supabase.dart';
import 'package:rewayah_academy/features/admin_invitations/invitations_familles.dart';
import 'package:rewayah_academy/features/inscription/invitation_en_cours.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart'
    show coupuresAdresse;

import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_recrutement.dart';

FoyerImporte _foyer(String id, String email, EtatInvitationFamille etat) =>
    FoyerImporte(id: id, email: email, personnes: 2, etat: etat);

class _Port implements PortFamillesImportees {
  _Port({this.lecture, this.resultatTous, this.erreurEnvoi});

  final Future<FamillesImportees> Function()? lecture;
  final ResultatEnvoiTous? resultatTous;
  final Object? erreurEnvoi;
  final List<String> envois = <String>[];
  final List<int> envoisTous = <int>[];
  int lectures = 0;

  @override
  Future<FamillesImportees> lister() {
    lectures += 1;
    return (lecture ??
        () async => FamillesImportees(
          aEnvoyer: 2,
          foyers: <FoyerImporte>[
            _foyer(
              'f1',
              'famille.a@exemple.test',
              EtatInvitationFamille.aEnvoyer,
            ),
            _foyer('f2', 'famille.b@exemple.test', EtatInvitationFamille.echec),
            _foyer(
              'f3',
              'famille.c@exemple.test',
              EtatInvitationFamille.compteCree,
            ),
          ],
        ))();
  }

  @override
  Future<ResultatEnvoiFoyer> envoyer(String foyer) async {
    final Object? e = erreurEnvoi;
    if (e != null) Error.throwWithStackTrace(e, StackTrace.current);
    envois.add(foyer);
    return ResultatEnvoiFoyer.enFile;
  }

  @override
  Future<ResultatEnvoiTous> envoyerATous(int attendu) async {
    envoisTous.add(attendu);
    return resultatTous ?? EnvoiTousEnFile(attendu);
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortFamillesImportees? port,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/invitations',
  ecran: (_) => const SingleChildScrollView(child: InvitationsFamilles()),
  surcharges: <Override>[portFamillesImporteesProvider.overrideWithValue(port)],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
);

void main() {
  final r = t.i1.familles;

  group('familles importees : etats', () {
    testWidgets('port absent : une phrase, aucun bouton', (tester) async {
      await _monter(tester);
      expect(
        find.byKey(const ValueKey<String>('familles-indisponible')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
        findsNothing,
      );
    });

    testWidgets('chargement : un squelette', (tester) async {
      final Completer<FamillesImportees> jamais =
          Completer<FamillesImportees>();
      await _monter(tester, port: _Port(lecture: () => jamais.future));
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets(
      'contenu : adresse, etat en mots, envoi seulement si possible',
      (tester) async {
        await _monter(tester, port: _Port());
        expect(
          find.text(coupuresAdresse('famille.a@exemple.test')),
          findsOneWidget,
        );
        expect(find.text(r.etat.aEnvoyer), findsOneWidget);
        expect(find.text(r.etat.echec), findsOneWidget);
        expect(find.text(r.etat.compteCree), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('famille-envoyer-f1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('famille-envoyer-f2')),
          findsOneWidget,
        );
        // Une famille qui a ouvert son espace n'a aucun bouton.
        expect(
          find.byKey(const ValueKey<String>('famille-envoyer-f3')),
          findsNothing,
        );
        expect(find.text(r.envoyerToutes(n: 2)), findsOneWidget);
        expect(find.text(r.renvoyer), findsOneWidget);
      },
    );

    testWidgets('vide : un constat et quoi faire', (tester) async {
      await _monter(
        tester,
        port: _Port(
          lecture: () async =>
              const FamillesImportees(aEnvoyer: 0, foyers: <FoyerImporte>[]),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(r.vide), findsOneWidget);
    });

    testWidgets('erreur : « Reessayer » relit la liste', (tester) async {
      final _Port port = _Port(lecture: () async => throw StateError('panne'));
      await _monter(tester, port: port);
      expect(
        find.byKey(const ValueKey<String>('familles-erreur-liste')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : etat dedie, aucun envoi propose', (tester) async {
      await _monter(
        tester,
        port: _Port(lecture: () async => throw const HorsLigne()),
        horsLigne: true,
      );
      expect(find.byType(EtatSansDonnees), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
        findsNothing,
      );
    });

    testWidgets('tout est parti : une phrase, pas de bouton', (tester) async {
      await _monter(
        tester,
        port: _Port(
          lecture: () async => FamillesImportees(
            aEnvoyer: 0,
            foyers: <FoyerImporte>[
              _foyer(
                'f1',
                'famille.a@exemple.test',
                EtatInvitationFamille.envoyee,
              ),
            ],
          ),
        ),
      );
      expect(find.text(r.toutesEnvoyees), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
        findsNothing,
      );
    });
  });

  group('familles importees : envois', () {
    testWidgets('une famille : le port est appele, le message le dit', (
      tester,
    ) async {
      final _Port port = _Port();
      await _monter(tester, port: port);
      final int avant = port.lectures;
      await tester.tap(
        find.byKey(const ValueKey<String>('famille-envoyer-f1')),
      );
      await laisser(tester);
      expect(port.envois, <String>['f1']);
      expect(
        find.text(r.enFile(email: 'famille.a@exemple.test')),
        findsOneWidget,
      );
      expect(port.lectures, greaterThan(avant));
    });

    testWidgets('une famille hors ligne : rien n\'est dit parti', (
      tester,
    ) async {
      await _monter(tester, port: _Port(erreurEnvoi: const HorsLigne()));
      await tester.tap(
        find.byKey(const ValueKey<String>('famille-envoyer-f1')),
      );
      await laisser(tester);
      expect(find.text(r.horsLigne), findsOneWidget);
    });

    testWidgets(
      'toutes : confirmation avec le nombre ; annuler n\'envoie rien',
      (tester) async {
        final _Port port = _Port();
        await _monter(tester, port: port);
        await tester.tap(
          find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
        );
        await laisser(tester);
        expect(find.text(r.toutesQuestion(n: 2)), findsOneWidget);
        expect(find.text(r.toutesConsequence), findsOneWidget);
        await tester.tap(find.text(t.commun.annuler).last);
        await laisser(tester);
        expect(port.envoisTous, isEmpty);
      },
    );

    testWidgets('toutes : confirmer envoie le nombre vu', (tester) async {
      final _Port port = _Port();
      await _monter(tester, port: port);
      await tester.tap(
        find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
      );
      await laisser(tester);
      await tester.tap(find.text(r.toutesConfirmer(n: 2)));
      await laisser(tester);
      expect(port.envoisTous, <int>[2]);
      expect(find.text(r.toutesEnFile(n: 2)), findsOneWidget);
    });

    testWidgets('toutes : un nombre perime ne fait rien partir et le dit', (
      tester,
    ) async {
      final _Port port = _Port(resultatTous: const EnvoiTousNombreChange(3));
      await _monter(tester, port: port);
      await tester.tap(
        find.byKey(const ValueKey<String>('familles-envoyer-toutes')),
      );
      await laisser(tester);
      await tester.tap(find.text(r.toutesConfirmer(n: 2)));
      await laisser(tester);
      expect(find.text(r.nombreChange), findsOneWidget);
    });

    testWidgets('320 px, texte x2 : rien ne deborde, aucun mot coupe', (
      tester,
    ) async {
      await _monter(tester, port: _Port(), largeur: 320, echelle: 2);
      expect(tester.takeException(), isNull);
      verifierAucunMotCoupe(tester, find.byType(InvitationsFamilles));
    });
  });

  group('adaptateur : lecture de la reponse', () {
    test('foyers et nombre a envoyer', () {
      final FamillesImportees l = famillesImporteesJson(<String, dynamic>{
        'a_envoyer': 1,
        'foyers': <Object>[
          <String, dynamic>{
            'id': 'x',
            'email': 'a@exemple.test',
            'personnes': 3,
            'etat': 'envoyee',
            'envoyee_le': '2026-11-02T10:00:00Z',
          },
        ],
      });
      expect(l.aEnvoyer, 1);
      expect(l.foyers.single.etat, EtatInvitationFamille.envoyee);
      expect(l.foyers.single.envoyeeLe, isNotNull);
      expect(l.foyers.single.envoyable, isFalse);
    });

    test('un etat inconnu est refuse', () {
      expect(
        () => foyerImporteJson(<String, dynamic>{
          'id': 'x',
          'email': 'a@exemple.test',
          'etat': 'autre',
        }),
        throwsFormatException,
      );
    });
  });

  group('invitation en cours (UX-013, UX-017)', () {
    tearDown(oublierInvitationEnCours);

    test('le lien de l\'e-mail pose la marque avec le code', () {
      retenirInvitationDepuisAdresse(
        Uri.parse(
          'https://app.exemple.test/connexion?mode=creer&invitation=1&code=ABCD-EFGH-JKMN',
        ),
      );
      final InvitationEnCours? i = lireInvitationEnCours();
      expect(i?.code, 'ABCD-EFGH-JKMN');
      expect(i?.route, '${Routes.inscriptionInvitation}?code=ABCD-EFGH-JKMN');
    });

    test('une adresse sans invitation ne pose rien', () {
      retenirInvitationDepuisAdresse(
        Uri.parse('https://app.exemple.test/connexion?mode=creer'),
      );
      expect(lireInvitationEnCours(), isNull);
    });

    test('une marque sans code garde le code deja connu', () {
      retenirInvitationEnCours(code: 'abcd efgh jkmn');
      retenirInvitationEnCours();
      expect(lireInvitationEnCours()?.code, 'abcd efgh jkmn');
    });

    test('un code etrange n\'est pas garde', () {
      retenirInvitationEnCours(code: '<script>');
      final InvitationEnCours? i = lireInvitationEnCours();
      expect(i, isNotNull);
      expect(i?.code, isNull);
      expect(i?.route, Routes.inscriptionInvitation);
    });

    test('la marque expire et s\'efface', () {
      final DateTime t0 = DateTime.utc(2026, 11, 2, 10);
      retenirInvitationEnCours(code: 'ABCD-EFGH-JKMN', maintenant: t0);
      expect(
        lireInvitationEnCours(maintenant: t0.add(const Duration(hours: 1))),
        isNotNull,
      );
      expect(
        lireInvitationEnCours(maintenant: t0.add(const Duration(days: 3))),
        isNull,
      );
      expect(lireInvitationEnCours(maintenant: t0), isNull);
    });
  });
}
