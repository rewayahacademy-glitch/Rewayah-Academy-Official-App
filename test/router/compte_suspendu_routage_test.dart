// COMPTE-SUSPENDU (11/11/2026). Un compte desactive arrive sur le portail
// d'attente, et nulle part ailleurs, AVANT comme APRES le hook de SEC-GARDE-5
// (20261123400000), qui retire le role et le foyer du jeton d'un compte
// desactive :
//   - avant : le jeton porte encore le role, le profil dit « disabled » :
//     porte suspendu ;
//   - apres : le jeton n'a plus de role : porte attente (fenetre « profil
//     present, role absent ») ; le portail lit etat_dossier, qui dit
//     « disabled », et montre le bloc suspendu.
// Les textes juridiques (dont les mentions legales et leur courriel de
// contact) restent lisibles dans les deux cas.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

SessionState _desactive({required AppRole? role}) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: AccountStatus.disabled,
  lectureProfil: LectureProfil.presente,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 11, 11, 12);
  for (final (String quand, AppRole? role, PorteAcces porte)
      in <(String, AppRole?, PorteAcces)>[
        (
          'avant le hook (role encore dans le jeton)',
          AppRole.guardian,
          PorteAcces.suspendu,
        ),
        ('apres le hook (jeton sans role)', null, PorteAcces.attente),
      ]) {
    group('compte desactive, $quand', () {
      final SessionState session = _desactive(role: role);

      test('la porte est $porte', () {
        expect(session.porte, porte);
      });

      test('toute route protegee mene au portail', () {
        for (final String chemin in <String>[
          Routes.racine,
          Routes.salle,
          Routes.attentePiece,
        ]) {
          expect(
            deciderRedirection(
              session: session,
              cheminDemande: chemin,
              maintenant: maintenant,
            ),
            Routes.attente,
            reason: chemin,
          );
        }
      });

      test('le portail et les mentions legales restent ouverts', () {
        for (final String chemin in <String>[
          Routes.attente,
          TexteJuridique.mentions.chemin,
        ]) {
          expect(
            deciderRedirection(
              session: session,
              cheminDemande: chemin,
              maintenant: maintenant,
            ),
            isNull,
            reason: chemin,
          );
        }
      });
    });
  }
}
