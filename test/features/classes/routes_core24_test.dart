import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/classes/routes_core24.dart';

SessionState _actif(AppRole role) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

void main() {
  test('les deux routes vivent sous le prefixe de leur role', () {
    final List<RouteBase> routes = routesCore24();
    expect(routes, hasLength(2));
    expect(
      CheminsCore24.enseignantClasses,
      startsWith(Routes.prefixePour(AppRole.teacher)),
    );
    expect(
      CheminsCore24.tuteurClasses,
      startsWith(Routes.prefixePour(AppRole.guardian)),
    );
    for (final RouteBase route in routes) {
      expect(route, isA<GoRoute>());
    }
  });

  test('la porte du routeur les laisse passer sans une ligne de plus', () {
    // `deciderRedirection` n'a pas bouge : c'est le prefixe qui decide.
    expect(
      deciderRedirection(
        session: _actif(AppRole.teacher),
        cheminDemande: CheminsCore24.enseignantClasses,
        maintenant: DateTime(2026, 9, 21),
      ),
      isNull,
    );
    expect(
      deciderRedirection(
        session: _actif(AppRole.guardian),
        cheminDemande: CheminsCore24.tuteurClasses,
        maintenant: DateTime(2026, 9, 21),
      ),
      isNull,
    );
  });

  test('un role qui demande la route de l autre repart chez lui', () {
    expect(
      deciderRedirection(
        session: _actif(AppRole.teacher),
        cheminDemande: CheminsCore24.tuteurClasses,
        maintenant: DateTime(2026, 9, 21),
      ),
      Routes.racinePour(AppRole.teacher),
    );
    expect(
      deciderRedirection(
        session: _actif(AppRole.student),
        cheminDemande: CheminsCore24.enseignantClasses,
        maintenant: DateTime(2026, 9, 21),
      ),
      Routes.racinePour(AppRole.student),
    );
  });
}
