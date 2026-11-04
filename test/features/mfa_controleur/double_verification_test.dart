// MFA-DIRECTION : la montee en aal2 au moment d'un geste qui l'exige.
// Refus 42501 en aal1 -> feuille du code -> code accepte -> geste rejoue une
// fois. Sans facteur : la feuille mene a Compte > Securite. Hors direction,
// ou deja en aal2 : le refus remonte, aucune feuille. Code refuse : le champ
// le dit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/mfa_controleur/double_verification.dart';
import 'package:rewayah_academy/features/mfa_controleur/port_mfa.dart';

import '../../support/harnais.dart';

class _Port implements PortMfa {
  _Port(this.situationRendue);
  SituationMfa situationRendue;
  bool refuserCode = false;
  final List<String> codes = <String>[];

  @override
  Future<SituationMfa> situation() async => situationRendue;

  @override
  Future<EnrolementTotp> enroler() => throw UnimplementedError();

  @override
  Future<void> verifier({
    required String facteurId,
    required String code,
  }) async {
    codes.add(code);
    if (refuserCode) throw const MfaCodeRefuse();
  }
}

class _Session extends SessionControleur {
  _Session(this.role, {this.aal2 = false});
  final AppRole role;
  final bool aal2;
  @override
  SessionState build() => SessionState(
    resolue: true,
    role: role,
    profileId: 'p1',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
    doubleVerificationFaite: aal2,
  );
}

/// Un ecran temoin : un bouton qui joue le geste, la ligne du resultat.
class _Temoin extends ConsumerStatefulWidget {
  const _Temoin(this.geste);
  final Future<String> Function() geste;
  @override
  ConsumerState<_Temoin> createState() => _TemoinState();
}

class _TemoinState extends ConsumerState<_Temoin> {
  String resultat = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        TextButton(
          onPressed: () async {
            String r;
            try {
              r = await avecDoubleVerification(context, ref, widget.geste);
            } on PermissionInsuffisante {
              r = 'refuse';
            }
            setState(() => resultat = r);
          },
          child: const Text('geste'),
        ),
        Text('resultat:$resultat'),
      ],
    ),
  );
}

Future<(_Port, List<int>)> _monter(
  WidgetTester tester, {
  required AppRole role,
  bool aal2 = false,
  SituationMfa situation = const MfaAVerifier('f1'),
  int refusAvantSucces = 1,
}) async {
  final _Port port = _Port(situation);
  final List<int> essais = <int>[];
  await tester.pumpWidget(
    hote(
      _Temoin(() async {
        essais.add(essais.length);
        if (essais.length <= refusAvantSucces) {
          throw const PermissionInsuffisante('test');
        }
        return 'fait';
      }),
      surcharges: <Override>[
        portMfaProvider.overrideWithValue(port),
        sessionProvider.overrideWith(() => _Session(role, aal2: aal2)),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (port, essais);
}

void main() {
  testWidgets('direction en aal1 : le code est demande, le geste rejoue', (
    tester,
  ) async {
    final (_Port port, List<int> essais) = await _monter(
      tester,
      role: AppRole.admin,
    );
    await tester.tap(find.text('geste'));
    await tester.pumpAndSettle();
    expect(find.text('Code de vérification'), findsWidgets);
    await tester.enterText(find.byKey(CleDoubleVerification.champ), '123456');
    await tester.tap(find.byKey(CleDoubleVerification.confirmer));
    await tester.pumpAndSettle();
    expect(port.codes, <String>['123456']);
    expect(essais.length, 2);
    expect(find.text('resultat:fait'), findsOneWidget);
  });

  testWidgets('code refuse : le champ le dit, rien n est rejoue', (
    tester,
  ) async {
    final (_Port port, List<int> essais) = await _monter(
      tester,
      role: AppRole.admin,
    );
    port.refuserCode = true;
    await tester.tap(find.text('geste'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(CleDoubleVerification.champ), '000000');
    await tester.tap(find.byKey(CleDoubleVerification.confirmer));
    await tester.pumpAndSettle();
    expect(find.textContaining("Ce code n'est pas bon"), findsOneWidget);
    expect(essais.length, 1);
  });

  testWidgets('sans facteur : la feuille mene a Compte > Securite', (
    tester,
  ) async {
    await _monter(tester, role: AppRole.admin, situation: const MfaAEnroler());
    await tester.tap(find.text('geste'));
    await tester.pumpAndSettle();
    expect(find.text("Activez d'abord la double vérification"), findsOneWidget);
    expect(find.byKey(CleDoubleVerification.ouvrirSecurite), findsOneWidget);
  });

  for (final (String nom, AppRole role, bool aal2) cas
      in <(String, AppRole, bool)>[
        ('un tuteur', AppRole.guardian, false),
        ('la direction deja en aal2', AppRole.admin, true),
      ]) {
    testWidgets('${cas.$1} : le refus remonte, aucune feuille', (tester) async {
      final (_, List<int> essais) = await _monter(
        tester,
        role: cas.$2,
        aal2: cas.$3,
      );
      await tester.tap(find.text('geste'));
      await tester.pumpAndSettle();
      expect(find.text('Code de vérification'), findsNothing);
      expect(find.text('resultat:refuse'), findsOneWidget);
      expect(essais.length, 1);
    });
  }

  test('estRefusDeDroit : PermissionInsuffisante, rien d autre', () {
    expect(estRefusDeDroit(const PermissionInsuffisante('x')), isTrue);
    expect(estRefusDeDroit(Exception('x')), isFalse);
  });
}
