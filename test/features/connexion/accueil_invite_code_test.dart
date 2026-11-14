// INVITATION-CODE-ACCUEIL (14/11/2026) : le serveur rend le code de l'invitation
// d'enseignant de l'adresse de la session ; il est lu, et retenu pour que
// l'inscription ouvre l'ecran de l'invitation avec lui.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/connexion/accueil_invite.dart';

void main() {
  test('le code d\'une invitation d\'enseignant est lu', () {
    final InvitationAccueil? i = InvitationAccueil.depuisJson(<String, Object?>{
      'etat': 'invite',
      'role': 'enseignant',
      'code': ' ABCD-EFGH-JKMN ',
    });
    expect(i?.role, RoleInvite.enseignant);
    expect(i?.code, 'ABCD-EFGH-JKMN');
  });

  test('sans code, ou code vide : nul, jamais invente', () {
    expect(
      InvitationAccueil.depuisJson(<String, Object?>{
        'etat': 'invite',
        'role': 'comptable',
      })?.code,
      isNull,
    );
    expect(
      InvitationAccueil.depuisJson(<String, Object?>{
        'etat': 'invite',
        'role': 'enseignant',
        'code': '  ',
      })?.code,
      isNull,
    );
  });
}
