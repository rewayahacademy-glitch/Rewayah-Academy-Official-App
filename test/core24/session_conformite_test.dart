import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

void main() {
  SessionState session(AppRole role, AccountStatus status) => SessionState(
    resolue: true,
    profileId: 'profil',
    role: role,
    accountStatus: status,
    lectureProfil: LectureProfil.presente,
  );
  test('KYC famille facultatif, statut compte conserve', () {
    for (final AppRole role in <AppRole>[AppRole.student, AppRole.guardian]) {
      final SessionState s = session(role, AccountStatus.pendingKyc);
      expect(s.porte, PorteAcces.actif);
      expect(s.accountStatus, AccountStatus.pendingKyc);
    }
  });
  test('enseignant actif sans clearance reste en onboarding', () {
    expect(
      session(AppRole.teacher, AccountStatus.active).porte,
      PorteAcces.attente,
    );
  });
  test('enseignant avec clearance serveur atteint ses cours', () {
    final SessionState s = session(AppRole.teacher, AccountStatus.pendingKyc)
        .copyWith(teacherOperational: true);
    expect(s.porte, PorteAcces.actif);
  });
  test('suspension prioritaire a la conformite', () {
    expect(
      session(AppRole.student, AccountStatus.disabled).porte,
      PorteAcces.suspendu,
    );
  });
}
