// AVIS-PUBLICS : le formulaire d'avis s'ouvre avec un lien, jamais avec un
// compte. La garde ne l'envoie ni sur la connexion, ni sur le portail
// d'attente, ni sur la racine du role : un visiteur sans session, un compte
// en attente, suspendu ou actif le voient tel quel, jeton compris.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

SessionState _session(AppRole role, AccountStatus statut) => SessionState(
  resolue: true,
  profileId: 'p1',
  householdId: 'h1',
  role: role,
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 10, 19, 10);
  final String chemin = Routes.avisPour('Qx7_-k2AbC');

  test('l adresse du formulaire est /avis/<jeton>', () {
    expect(chemin, '/avis/Qx7_-k2AbC');
    expect(Routes.avisPour('a b'), '/avis/a%20b');
  });

  test('sans session : ni connexion, ni redirection', () {
    expect(
      deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: chemin,
        maintenant: maintenant,
      ),
      isNull,
    );
  });

  test('connecte, en attente ou suspendu : le formulaire reste ouvert', () {
    for (final AppRole role in AppRole.values) {
      for (final AccountStatus statut in AccountStatus.values) {
        expect(
          deciderRedirection(
            session: _session(role, statut),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: '${role.name} ${statut.name}',
        );
      }
    }
  });

  test('l ecran de la direction reste reserve a la direction', () {
    expect(
      deciderRedirection(
        session: _session(AppRole.guardian, AccountStatus.active),
        cheminDemande: Routes.adminOperationsAvis,
        maintenant: maintenant,
      ),
      isNotNull,
    );
    expect(
      deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.adminOperationsAvis,
        maintenant: maintenant,
      ),
      isNotNull,
    );
    expect(
      deciderRedirection(
        session: _session(AppRole.admin, AccountStatus.active),
        cheminDemande: Routes.adminOperationsAvis,
        maintenant: maintenant,
      ),
      isNull,
    );
  });
}
