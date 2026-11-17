// NOUVEAU-FILS (directeur, 16/11/2026) : le badge « Nouveau » dans la liste des
// conversations. Le serveur dit `nouveau` (moins de 7 jours, jamais lue par
// l'equipe) ; l'ecran ne decide rien : il pose le badge du composant existant
// (`BadgeNouveau`), dit « aucun message » pour une conversation vide, et offre
// le filtre « Nouveaux » a cote de « Tous » et « Non lus ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_nouveau.dart';
import 'package:rewayah_academy/core/widgets/ligne_conversation.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_metier_supabase.dart';

final DateTime _maintenant = DateTime.utc(2026, 11, 16, 12);

ResumeFil _fil(
  String id, {
  String? apercu,
  bool nouveau = false,
  int nonLus = 0,
}) => ResumeFil(
  id: id,
  objet: ObjetLie(
    type: TypeObjetLie.candidature,
    id: 'cand-$id',
    libelle: 'Dossier $id',
  ),
  interlocuteurs: <Participant>[
    Participant(id: 'p-$id', nomAffiche: 'Personne $id'),
  ],
  apercu: apercu,
  dernierMessageLe: apercu == null
      ? null
      : _maintenant.subtract(const Duration(hours: 2)),
  attention: nonLus > 0
      ? IndicateurAttention(nonLus: nonLus)
      : IndicateurAttention.aucun,
  nouveau: nouveau,
);

Future<void> _monter(
  WidgetTester tester,
  List<ResumeFil> fils, {
  Size taille = const Size(1440, 900),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: Material(
        child: ListeFils(
          fils: fils,
          onOuvrir: (String _) {},
          horloge: () => _maintenant,
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _badgeDans(String filId) => find.descendant(
  of: find.byKey(ValueKey<String>('ligne-$filId')),
  matching: find.byKey(BadgeNouveau.clePastille),
);

void main() {
  group('lecture du serveur', () {
    Map<String, dynamic> json({Object? nouveau}) => <String, dynamic>{
      'id': '7c400000-0000-4000-8000-0000000000f9',
      'objet': <String, dynamic>{
        'type': 'classe',
        'id': '7c400000-0000-4000-8000-0000000000c1',
        'libelle': 'Classe 1',
      },
      'parties': <Object>[],
      'non_lus': 0,
      'messages': <Map<String, dynamic>>[],
      'nouveau': ?nouveau,
    };

    test('la cle `nouveau` du serveur devient `ResumeFil.nouveau`', () {
      const LibellesCommunicationSlang l = LibellesCommunicationSlang();
      expect(resumeFilJson(json(nouveau: true), l).nouveau, isTrue);
      expect(resumeFilJson(json(nouveau: false), l).nouveau, isFalse);
      // Un serveur plus ancien ne rend pas la cle : jamais nouveau.
      expect(resumeFilJson(json(), l).nouveau, isFalse);
      // Une valeur qui n'est pas un booleen vrai n'allume rien.
      expect(resumeFilJson(json(nouveau: 'true'), l).nouveau, isFalse);
    });
  });

  group('la ligne', () {
    testWidgets('le badge « Nouveau » se pose sur une conversation nouvelle, '
        'et sur elle seule', (WidgetTester tester) async {
      await _monter(tester, <ResumeFil>[
        _fil('n', apercu: 'Bonjour', nouveau: true),
        _fil('a', apercu: 'Merci'),
      ]);
      expect(_badgeDans('n'), findsOneWidget);
      expect(_badgeDans('a'), findsNothing);
      expect(find.text(t.commun.nouveau), findsOneWidget);
    });

    testWidgets('une conversation nouvelle sans message dit « Nouveau · aucun '
        'message » ; sans etre nouvelle, la phrase d\'avant', (
      WidgetTester tester,
    ) async {
      await _monter(tester, <ResumeFil>[_fil('v', nouveau: true), _fil('w')]);
      expect(_badgeDans('v'), findsOneWidget);
      expect(find.text(t.com.messages.ligne.sansMessage), findsOneWidget);
      expect(find.text(t.com.messages.ligne.sansApercu), findsOneWidget);
      expect(_badgeDans('w'), findsNothing);
      // Le lecteur d'ecran lit « Nouveau » puis « aucun message ».
      final SemanticsHandle poignee = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(
          RegExp(
            'Personne v.*${t.commun.nouveau}.*'
            '${t.com.messages.ligne.sansMessage}',
          ),
        ),
        findsOneWidget,
      );
      poignee.dispose();
    });

    testWidgets('nouveau et non lu : le badge et la pastille du nombre vivent '
        'ensemble', (WidgetTester tester) async {
      await _monter(tester, <ResumeFil>[
        _fil('n', apercu: 'Bonjour', nouveau: true, nonLus: 3),
      ]);
      expect(_badgeDans('n'), findsOneWidget);
      expect(find.byKey(LigneConversation.cleNonLus), findsOneWidget);
    });
  });

  group('le filtre « Nouveaux »', () {
    testWidgets('il montre les nouvelles conversations seules, et « Tous » les '
        'rend toutes', (WidgetTester tester) async {
      await _monter(tester, <ResumeFil>[
        _fil('n1', apercu: 'Un', nouveau: true),
        _fil('a1', apercu: 'Deux'),
        _fil('n2', nouveau: true),
        _fil('a2', apercu: 'Trois', nonLus: 1),
      ]);
      expect(find.byType(LigneConversation), findsNWidgets(4));
      await tester.tap(find.byKey(ListeFils.cleFiltreNouveaux));
      await tester.pump();
      expect(find.byType(LigneConversation), findsNWidgets(2));
      expect(find.byKey(const ValueKey<String>('ligne-n1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('ligne-n2')), findsOneWidget);
      await tester.tap(find.text(t.com.messages.filtres.tous));
      await tester.pump();
      expect(find.byType(LigneConversation), findsNWidgets(4));
    });

    testWidgets('sans conversation nouvelle, il le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, <ResumeFil>[_fil('a1', apercu: 'Deux')]);
      await tester.tap(find.byKey(ListeFils.cleFiltreNouveaux));
      await tester.pump();
      expect(find.byType(LigneConversation), findsNothing);
      expect(find.text(t.com.messages.filtres.aucunNouveau), findsOneWidget);
    });

    testWidgets(
      'quand les trois puces ne tiennent pas (polices de test a 390), « Nouveaux » se choisit sous « Plus »',
      (WidgetTester tester) async {
        await _monter(tester, <ResumeFil>[
          _fil('n1', apercu: 'Un', nouveau: true),
          _fil('a1', apercu: 'Deux'),
        ], taille: const Size(390, 844));
        expect(find.byType(LigneConversation), findsNWidgets(2));
        await tester.tap(find.text(t.commun.filtres.plus));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.com.messages.filtres.nouveaux).last);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('ligne-n1')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('ligne-a1')), findsNothing);
      },
    );

    testWidgets('les trois filtres sont la, dans l\'ordre « Tous », « Non '
        'lus », « Nouveaux »', (WidgetTester tester) async {
      await _monter(tester, <ResumeFil>[_fil('a1', apercu: 'Deux')]);
      final double tous = tester
          .getTopLeft(find.text(t.com.messages.filtres.tous))
          .dx;
      final double nonLus = tester
          .getTopLeft(find.text(t.com.messages.filtres.nonLus))
          .dx;
      final double nouveaux = tester
          .getTopLeft(find.text(t.com.messages.filtres.nouveaux))
          .dx;
      expect(tous, lessThan(nonLus));
      expect(nonLus, lessThan(nouveaux));
    });
  });

  test('les textes existent en francais, arabe et anglais', () async {
    final Set<String> motsFiltre = <String>{};
    final Set<String> motsVide = <String>{};
    for (final AppLocale l in AppLocale.values) {
      final c = (await l.build()).com.messages;
      motsFiltre.add(c.filtres.nouveaux);
      motsVide.add(c.ligne.sansMessage);
      expect(c.filtres.nouveaux.trim(), isNotEmpty, reason: l.languageCode);
      expect(c.filtres.aucunNouveau.trim(), isNotEmpty, reason: l.languageCode);
      expect(c.ligne.sansMessage.trim(), isNotEmpty, reason: l.languageCode);
    }
    expect(motsFiltre.length, AppLocale.values.length);
    expect(motsVide.length, AppLocale.values.length);
  });
}
