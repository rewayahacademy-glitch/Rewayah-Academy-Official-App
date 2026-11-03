// Lot O1 (02/11/2026) : le planning lit la capacite d'observer en direction
// dans la session ; les tests du planning montent une session de direction.

import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

/// Une session resolue, du role donne (la direction par defaut).
class SessionPlanning extends SessionControleur {
  /// Cree la session.
  SessionPlanning([this._role = AppRole.admin]);

  final AppRole _role;

  @override
  SessionState build() => SessionState(
    resolue: true,
    role: _role,
    profileId: 'test',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}
