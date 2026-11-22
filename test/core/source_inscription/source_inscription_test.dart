// REF-SUIVI (22/11/2026) : le `ref` du lien d'une organisation est garde sans
// ecraser une source plus ancienne, envoye une fois a la connexion, puis
// efface ; une panne le laisse.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/source_inscription/source_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

class _Connecte extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'p-1',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

class _Visiteur extends SessionControleur {
  @override
  SessionState build() => const SessionState.deconnecte();
}

Future<void> _ouvrir(NoterSource noter, {bool connecte = true}) async {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      sessionProvider.overrideWith(connecte ? _Connecte.new : _Visiteur.new),
      noterSourceProvider.overrideWithValue(noter),
    ],
  );
  addTearDown(c.dispose);
  c.read(veilleSourceInscriptionProvider);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() => effacerMemoireAppareil(cleSourceInscription));

  test('forme du ref : minuscules, chiffres, tirets, 1 a 48', () {
    expect(refValide('chingford-londres'), 'chingford-londres');
    expect(refValide('a' * 48), isNotNull);
    expect(refValide('a' * 49), isNull);
    expect(refValide('Chingford'), isNull);
    expect(refValide('a_b'), isNull);
    expect(refValide(''), isNull);
    expect(refValide(null), isNull);
  });

  test('un ref valide est garde ; un ref invalide ou absent ne garde rien', () {
    capturerSourceInscription(adresse: Uri.parse('https://x.test/connexion?ref=Bad_1'));
    capturerSourceInscription(adresse: Uri.parse('https://x.test/connexion'));
    expect(sourceInscriptionEnAttente(), isNull);
    capturerSourceInscription(adresse: Uri.parse('https://x.test/connexion?ref=mosquee-a'));
    expect(sourceInscriptionEnAttente(), 'mosquee-a');
  });

  test('la premiere source gagne, sauf si elle a plus de 30 jours', () {
    final DateTime t0 = DateTime.utc(2026, 11, 22);
    capturerSourceInscription(adresse: Uri.parse('https://x.test/?ref=mosquee-a'), maintenant: t0);
    capturerSourceInscription(
      adresse: Uri.parse('https://x.test/?ref=mosquee-b'),
      maintenant: t0.add(const Duration(days: 29)),
    );
    expect(sourceInscriptionEnAttente(maintenant: t0.add(const Duration(days: 29))), 'mosquee-a');
    capturerSourceInscription(
      adresse: Uri.parse('https://x.test/?ref=mosquee-b'),
      maintenant: t0.add(const Duration(days: 31)),
    );
    expect(sourceInscriptionEnAttente(maintenant: t0.add(const Duration(days: 31))), 'mosquee-b');
  });

  test('connecte : la porte est appelee une fois, la valeur locale effacee', () async {
    capturerSourceInscription(adresse: Uri.parse('https://x.test/?ref=mosquee-a'));
    final List<String> appels = <String>[];
    await _ouvrir((String r) async {
      appels.add(r);
      return true;
    });
    expect(appels, <String>['mosquee-a']);
    expect(sourceInscriptionEnAttente(), isNull);
  });

  test('un compte qui avait deja une source (faux) efface aussi la valeur locale', () async {
    capturerSourceInscription(adresse: Uri.parse('https://x.test/?ref=mosquee-a'));
    await _ouvrir((String r) async => false);
    expect(sourceInscriptionEnAttente(), isNull);
  });

  test('une panne laisse la valeur pour la prochaine ouverture', () async {
    capturerSourceInscription(adresse: Uri.parse('https://x.test/?ref=mosquee-a'));
    await _ouvrir((String r) async => throw TimeoutException('reseau'));
    expect(sourceInscriptionEnAttente(), 'mosquee-a');
  });

  test('sans session, rien n\'est envoye', () async {
    capturerSourceInscription(adresse: Uri.parse('https://x.test/?ref=mosquee-a'));
    int appels = 0;
    await _ouvrir((String r) async {
      appels++;
      return true;
    }, connecte: false);
    expect(appels, 0);
    expect(sourceInscriptionEnAttente(), 'mosquee-a');
  });
}
