// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : l'adaptateur Supabase traduit
// les RPC de 20261120000000 sans rien decider.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/invitations_personnelles_supabase.dart';
import 'package:rewayah_academy/core/candidature/port_invitations_personnelles.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, dynamic> _apercu = <String, dynamic>{
  'aInviter': 3,
  'aRenvoyer': 1,
  'dejaInvites': 2,
  'dejaInscrits': 5,
  'revoquees': 0,
  'desinscrits': 1,
  'sansAdresse': 4,
  'plafondJour': 300,
  'envoyes24h': 10,
  'resteAujourdhui': 290,
};

void main() {
  test('apercu : la bonne RPC, les comptes lus', () async {
    final List<String> appels = <String>[];
    final InvitationsPersonnellesSupabase a =
        InvitationsPersonnellesSupabase.avecAppel((String nom, [_]) async {
          appels.add(nom);
          return _apercu;
        });
    final ApercuInvitationsPersonnelles r = await a.apercu();
    expect(appels, <String>['apercu_invitations_candidats_importes']);
    expect(r.eligibles, 4);
    expect(r.resteAujourdhui, 290);
  });

  test('envoyer : nombre attendu et limite passes au serveur', () async {
    Map<String, dynamic>? params;
    final InvitationsPersonnellesSupabase a =
        InvitationsPersonnellesSupabase.avecAppel((
          String nom, [
          Map<String, dynamic>? p,
        ]) async {
          expect(nom, 'envoyer_invitations_candidats_importes');
          params = p;
          return <String, dynamic>{
            'misEnFile': 4,
            'restants': 0,
            'resteAujourdhui': 286,
          };
        });
    final ResultatInvitationsPersonnelles r = await a.envoyer(attendu: 4);
    expect(params, <String, dynamic>{'p_attendu': 4, 'p_limite': 200});
    expect(r.misEnFile, 4);
  });

  test('refus rendus dans la reponse : nombre change, plafond, inconnu', () {
    InvitationsPersonnellesSupabase avec(Map<String, dynamic> j) =>
        InvitationsPersonnellesSupabase.avecAppel((String _, [_]) async => j);
    expect(
      avec(<String, dynamic>{'erreur': 'nombre_change', 'eligibles': 6})
          .envoyer(attendu: 4),
      throwsA(isA<NombreChange>().having((e) => e.eligibles, 'eligibles', 6)),
    );
    expect(
      avec(<String, dynamic>{
        'erreur': 'plafond_atteint',
        'restants': 9,
        'resteAujourdhui': 0,
      }).envoyer(attendu: 9),
      throwsA(isA<PlafondAtteint>().having((e) => e.restants, 'restants', 9)),
    );
    expect(
      avec(<String, dynamic>{'erreur': 'autre'}).envoyer(attendu: 1),
      throwsA(isA<InvitationsPersonnellesRefusInconnu>()),
    );
  });

  test('codes du serveur : 42501, 22023, fonction absente, reseau', () {
    InvitationsPersonnellesSupabase leve(Exception e) =>
        InvitationsPersonnellesSupabase.avecAppel(
          (String _, [_]) async => throw e,
        );
    expect(
      leve(const PostgrestException(message: 'x', code: '42501')).apercu(),
      throwsA(isA<PermissionInsuffisante>()),
    );
    expect(
      leve(const PostgrestException(message: 'x', code: '22023'))
          .envoyer(attendu: 1),
      throwsA(isA<InvitationsPersonnellesInvalide>()),
    );
    expect(
      leve(const PostgrestException(message: 'x', code: 'PGRST202')).apercu(),
      throwsA(isA<CapaciteIndisponible>()),
    );
    expect(
      leve(Exception('SocketException: coupure')).envoyer(attendu: 1),
      throwsA(isA<InvitationsPersonnellesHorsLigne>()),
    );
  });
}
