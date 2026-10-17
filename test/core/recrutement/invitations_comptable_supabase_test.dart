// BF1-03 : les adaptateurs de l'invitation d'un comptable.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/recrutement/invitations_comptable_supabase.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final Map<String, Object?> _inv = <String, Object?>{
  'code': 'ABCD-EFGH-JKMN',
  'email': 'cpt@test.invalid',
  'expire_le': '2026-10-31T10:00:00+00:00',
  'etat': 'active',
  'utilisee_le': null,
};

AppelInvitation _rend(Object? reponse, [List<String>? appels]) =>
    (String f, Map<String, dynamic>? p) async {
      appels?.add(f);
      return reponse;
    };

void main() {
  test('inviter : creee, deja invite, refus metier', () async {
    final List<String> appels = <String>[];
    final Invitation i = await InvitationsComptableSupabase.avecAppel(
      _rend(<String, Object?>{'statut': 'creee', 'invitation': _inv}, appels),
    ).inviter('cpt@test.invalid');
    expect(i.etat, EtatInvitation.active);
    expect(appels.single, 'inviter_comptable');
    await expectLater(
      InvitationsComptableSupabase.avecAppel(
        _rend(<String, Object?>{'statut': 'deja_invite', 'invitation': _inv}),
      ).inviter('x'),
      throwsA(isA<DejaInvite>()),
    );
    await expectLater(
      InvitationsComptableSupabase.avecAppel(
        _rend(<String, Object?>{
          'statut': 'compte_existant',
          'invitation': null,
        }),
      ).inviter('x'),
      throwsA(isA<CompteExistant>()),
    );
    await expectLater(
      InvitationsComptableSupabase.avecAppel(
        _rend(<String, Object?>{
          'statut': 'email_invalide',
          'invitation': null,
        }),
      ).inviter('x'),
      throwsA(isA<EmailInvalide>()),
    );
  });

  test('lister et verifier', () async {
    expect(
      (await InvitationsComptableSupabase.avecAppel(
        _rend(<Object?>[_inv]),
      ).lister()).single.code,
      'ABCD-EFGH-JKMN',
    );
    expect(
      await VerificationInvitationComptableSupabase.avecAppel(
        _rend(<String, Object?>{
          'resultat': 'deja_utilisee',
          'expire_le': null,
        }),
      ).verifierInvitation('c'),
      isA<InvitationDejaUtilisee>(),
    );
  });

  test('inscrire : les quatre issues et une forme inconnue', () async {
    for (final (String code, ResultatInscriptionComptable attendu)
        in <(String, ResultatInscriptionComptable)>[
          ('consommee', ResultatInscriptionComptable.consommee),
          ('inconnue', ResultatInscriptionComptable.inconnue),
          ('deja_utilisee', ResultatInscriptionComptable.dejaUtilisee),
          ('expiree', ResultatInscriptionComptable.expiree),
        ]) {
      expect(
        await InscriptionComptableSupabase.avecAppel(
          _rend(<String, Object?>{'resultat': code}),
        ).inscrire(code: 'c', prenom: 'N', nom: 'B'),
        attendu,
      );
    }
    await expectLater(
      InscriptionComptableSupabase.avecAppel(
        _rend(<String, Object?>{'resultat': 'autre'}),
      ).inscrire(code: 'c', prenom: 'N', nom: 'B'),
      throwsFormatException,
    );
  });

  test('42501 : non autorise ; coupure : hors ligne', () async {
    Future<Object?> refus(String _, Map<String, dynamic>? _) async =>
        throw const PostgrestException(message: 'aal2', code: '42501');
    Future<Object?> coupure(String _, Map<String, dynamic>? _) async =>
        throw const SocketException('coupe');
    await expectLater(
      InvitationsComptableSupabase.avecAppel(refus).inviter('x'),
      throwsA(isA<NonAutorise>()),
    );
    await expectLater(
      InscriptionComptableSupabase.avecAppel(coupure)
          .inscrire(code: 'c', prenom: 'N', nom: 'B'),
      throwsA(isA<HorsLigne>()),
    );
  });
}
