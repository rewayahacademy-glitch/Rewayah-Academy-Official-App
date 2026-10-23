// RECRUT-ECRANS (1/5) : « Inviter un enseignant », cote administration.
//
// Ce que le test prouve : les cinq etats (chargement, contenu, vide, erreur,
// hors ligne), le port absent, la creation (code montre, liste relue), les
// refus metier, la revocation confirmee et son absence sur une invitation qui
// n'est plus active, 320 px texte x2 en LTR et RTL sans debordement.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_invitations/invitations_page.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart'
    show coupuresAdresse;

import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortInvitationsEnseignant {
  _Port({
    this.lecture,
    this.echecInviter,
    this.echecRevoquer = false,
    this.erreurRevoquer,
  });

  final Future<List<Invitation>> Function()? lecture;
  final Object? echecInviter;
  final bool echecRevoquer;
  final Object? erreurRevoquer;
  final InvitationsDemo interne = InvitationsDemo();

  @override
  Future<Invitation> inviter(String email) async {
    final Object? e = echecInviter;
    if (e != null) Error.throwWithStackTrace(e, StackTrace.current);
    return interne.inviter(email);
  }

  @override
  Future<List<Invitation>> lister() => (lecture ?? interne.lister)();

  @override
  Future<void> revoquer(String code) async {
    final Object? e = erreurRevoquer;
    if (e != null) Error.throwWithStackTrace(e, StackTrace.current);
    if (echecRevoquer) throw StateError('perdu');
    return interne.revoquer(code);
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortInvitationsEnseignant? port,
  PortInvitationsEnseignant? comptable,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/invitations',
  ecran: (_) => const InvitationsPage(),
  surcharges: <Override>[
    portInvitationsEnseignantProvider.overrideWithValue(port),
    portInvitationsComptableProvider.overrideWithValue(comptable),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

void main() {
  final r = t.recrutement.invitations;

  group('etats', () {
    testWidgets('port absent : une phrase, aucun formulaire', (tester) async {
      await _monter(tester);
      expect(
        find.byKey(const ValueKey<String>('invitations-indisponible')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('invitations-email')),
        findsNothing,
      );
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('chargement : un squelette', (tester) async {
      final Completer<List<Invitation>> jamais = Completer<List<Invitation>>();
      await _monter(tester, port: _Port(lecture: () => jamais.future));
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('contenu : adresse, code, echeance, etat en mots', (
      tester,
    ) async {
      await _monter(tester, port: _Port());
      expect(
        find.text(coupuresAdresse('candidat.valide@exemple.test')),
        findsOneWidget,
      );
      expect(find.text(r.etat.active), findsOneWidget);
      expect(find.text(r.etat.utilisee), findsOneWidget);
      expect(find.text(r.etat.expiree), findsOneWidget);
      expect(find.textContaining('DEMO-VALIDE'), findsOneWidget);
    });

    testWidgets('vide : un constat et une invitation a agir', (tester) async {
      await _monter(
        tester,
        port: _Port(lecture: () async => const <Invitation>[]),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(r.vide), findsOneWidget);
    });

    testWidgets('erreur : « Reessayer » relit la liste', (tester) async {
      int appels = 0;
      await _monter(
        tester,
        port: _Port(
          lecture: () async {
            appels += 1;
            if (appels == 1) throw StateError('panne');
            return <Invitation>[];
          },
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('invitations-erreur-liste')),
        findsOneWidget,
      );
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('hors ligne sans donnees : l\'etat dedie', (tester) async {
      await _monter(
        tester,
        horsLigne: true,
        port: _Port(lecture: () async => throw StateError('hors ligne')),
      );
      expect(find.byType(EtatSansDonnees), findsOneWidget);
    });

    testWidgets('hors ligne avec donnees : aucune revocation proposee', (
      tester,
    ) async {
      await _monter(tester, horsLigne: true, port: _Port());
      expect(find.text(r.revoquer), findsNothing);
    });
  });

  group('creation', () {
    testWidgets('une adresse valide cree l\'invitation et la liste la montre', (
      tester,
    ) async {
      await _monter(tester, port: _Port());
      await tester.enterText(
        find.byKey(const ValueKey<String>('invitations-email')),
        'nouvelle@exemple.test',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('invitations-inviter')),
      );
      await laisser(tester);
      expect(
        find.byKey(const ValueKey<String>('invitations-succes')),
        findsOneWidget,
      );
      expect(
        find.text(coupuresAdresse('nouvelle@exemple.test')),
        findsOneWidget,
      );
    });

    for (final (String nom, Object erreur, String message) cas
        in <(String, Object, String)>[
          ('adresse invalide', const EmailInvalide(), r.emailInvalide),
          ('compte existant', const CompteExistant(), r.compteExistant),
          ('non autorise', const NonAutorise(), r.nonAutorise),
          ('hors ligne', const HorsLigne(), r.horsLigne),
          ('panne', StateError('x'), r.erreur),
        ]) {
      testWidgets('refus : ${cas.$1}', (tester) async {
        await _monter(tester, port: _Port(echecInviter: cas.$2));
        await tester.enterText(
          find.byKey(const ValueKey<String>('invitations-email')),
          'x@exemple.test',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('invitations-inviter')),
        );
        await laisser(tester);
        expect(find.text(cas.$3), findsOneWidget);
      });
    }

    testWidgets('deja invite : l\'invitation active existante est montree', (
      tester,
    ) async {
      await _monter(tester, port: _Port());
      await tester.enterText(
        find.byKey(const ValueKey<String>('invitations-email')),
        'candidat.valide@exemple.test',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('invitations-inviter')),
      );
      await laisser(tester);
      expect(find.text(r.dejaInvite), findsOneWidget);
    });
  });

  group('revocation', () {
    testWidgets('seule une invitation active se revoque, apres confirmation', (
      tester,
    ) async {
      await _monter(tester, port: _Port());
      expect(find.text(r.revoquer), findsOneWidget);
      await tester.tap(find.text(r.revoquer));
      await laisser(tester);
      await tester.tap(find.text(r.revoquer).last);
      await laisser(tester);
      expect(find.text(r.etat.revoquee), findsOneWidget);
      expect(find.text(r.revoquer), findsNothing);
    });

    testWidgets('un echec de revocation se dit', (tester) async {
      await _monter(tester, port: _Port(echecRevoquer: true));
      await tester.tap(find.text(r.revoquer));
      await laisser(tester);
      await tester.tap(find.text(r.revoquer).last);
      await laisser(tester);
      expect(find.text(r.revoquerEchec), findsOneWidget);
    });
  });

  // Lot F2 : inviter un enseignant ou un comptable.
  group('comptable', () {
    final c = r.comptable;
    final Finder carteComptable = find.byKey(
      const ValueKey<String>('invitations-role-comptable'),
    );

    Future<void> choisirComptable(WidgetTester tester) async {
      await tester.ensureVisible(carteComptable);
      await tester.tap(carteComptable);
      await laisser(tester);
    }

    Future<void> inviter(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const ValueKey<String>('invitations-email')),
        'compta@exemple.test',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('invitations-inviter')),
      );
      await laisser(tester);
    }

    testWidgets('sans port comptable : aucune carte, rien ne change', (
      tester,
    ) async {
      await _monter(tester, port: _Port());
      expect(
        find.byKey(const ValueKey<String>('invitations-role')),
        findsNothing,
      );
      expect(find.text(r.titre), findsWidgets);
    });

    testWidgets('deux ports : deux cartes differentes, expliquees', (
      tester,
    ) async {
      await _monter(tester, port: _Port(), comptable: _Port());
      expect(find.text(c.choixQuestion), findsOneWidget);
      expect(find.text(c.enseignantTitre), findsOneWidget);
      expect(find.text(c.enseignantExplication), findsOneWidget);
      expect(find.text(c.comptableTitre), findsOneWidget);
      expect(find.text(c.comptableExplication), findsOneWidget);
      expect(find.text(c.champEmail), findsNothing);
    });

    testWidgets('la carte comptable cree une invitation de comptable', (
      tester,
    ) async {
      final _Port enseignant = _Port();
      final _Port comptable = _Port(lecture: () async => const <Invitation>[]);
      await _monter(tester, port: enseignant, comptable: comptable);
      await choisirComptable(tester);
      expect(find.text(c.champEmail), findsOneWidget);
      expect(find.text(c.vide), findsOneWidget);
      await inviter(tester);
      final String code = (await comptable.interne.lister())
          .firstWhere((Invitation i) => i.email == 'compta@exemple.test')
          .code;
      expect(find.text(c.creee(code: code)), findsOneWidget);
      // Le port enseignant n'a rien recu.
      expect(
        (await enseignant.interne.lister()).where(
          (Invitation i) => i.email == 'compta@exemple.test',
        ),
        isEmpty,
      );
    });

    testWidgets('refus du serveur : « double verification requise »', (
      tester,
    ) async {
      await _monter(
        tester,
        port: _Port(),
        comptable: _Port(echecInviter: const NonAutorise()),
      );
      await choisirComptable(tester);
      await inviter(tester);
      expect(find.text(c.doubleVerification), findsOneWidget);
    });

    testWidgets('revocation refusee : « double verification requise »', (
      tester,
    ) async {
      await _monter(
        tester,
        port: _Port(),
        comptable: _Port(erreurRevoquer: const NonAutorise()),
      );
      await choisirComptable(tester);
      expect(find.text(c.liste), findsOneWidget);
      await tester.tap(find.text(r.revoquer));
      await laisser(tester);
      await tester.tap(find.text(r.revoquer).last);
      await laisser(tester);
      expect(find.text(c.doubleVerification), findsOneWidget);
    });

    testWidgets(
      'seul le port comptable : le formulaire comptable, sans carte',
      (tester) async {
        await _monter(tester, comptable: _Port());
        expect(
          find.byKey(const ValueKey<String>('invitations-role')),
          findsNothing,
        );
        expect(find.text(c.champEmail), findsOneWidget);
      },
    );

    for (final TextDirection direction in <TextDirection>[
      TextDirection.ltr,
      TextDirection.rtl,
    ]) {
      testWidgets('deux cartes, 320 px, texte x2, $direction', (tester) async {
        await _monter(
          tester,
          port: _Port(),
          comptable: _Port(),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });

  group('gabarits', () {
    for (final TextDirection direction in <TextDirection>[
      TextDirection.ltr,
      TextDirection.rtl,
    ]) {
      testWidgets('320 px, texte x2, $direction : rien ne deborde', (
        tester,
      ) async {
        await _monter(
          tester,
          port: _Port(),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
