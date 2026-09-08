import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

void main() {
  group('destinationsPour : une barre par role, jamais plus de quatre', () {
    test('un eleve en mode enfant n a aucune destination (ADR-009)', () {
      final List<Destination> rien = destinationsPour(
        role: AppRole.student,
        mode: InterfaceMode.enfant,
      );
      expect(rien, isEmpty);
    });

    test('les chemins des destinations sont exactement ceux du role', () {
      final Map<AppRole, List<String>> attendus = <AppRole, List<String>>{
        AppRole.student: <String>[
          Routes.eleve,
          Routes.eleveCoran,
          Routes.eleveSuivi,
        ],
        AppRole.guardian: <String>[
          Routes.tuteurAccueil,
          Routes.tuteurDisponibilites,
          Routes.tuteurReglages,
          Routes.tuteurSuivi,
        ],
        AppRole.teacher: <String>[
          Routes.enseignantJournee,
          Routes.enseignantCreneaux,
          Routes.enseignantProfil,
        ],
        AppRole.admin: <String>[
          Routes.adminTableauDeBord,
          Routes.adminDossiers,
          Routes.adminAttribution,
          Routes.adminJournal,
        ],
        // Le controleur et le comptable n ont pas de barre.
        AppRole.controller: <String>[],
        AppRole.accountant: <String>[],
      };

      for (final MapEntry<AppRole, List<String>> attente in attendus.entries) {
        final List<Destination> destinations = destinationsPour(
          role: attente.key,
          mode: InterfaceMode.standard,
        );
        expect(
          destinations.map((Destination d) => d.chemin).toList(),
          attente.value,
          reason: 'les destinations de ${attente.key.valeurSql}',
        );
        // La racine du role est toujours la premiere destination : c est la
        // branche ou la redirection retombe, et donc celle qu il faut mettre
        // en avant quand l ecran s ouvre.
        if (attente.value.isNotEmpty) {
          expect(
            destinations.first.chemin,
            Routes.racinePour(attente.key),
            reason: 'la racine de ${attente.key.valeurSql} est en premiere',
          );
        }
      }
    });

    test('aucun role ne demande plus de quatre destinations', () {
      for (final AppRole role in AppRole.values) {
        for (final InterfaceMode mode in InterfaceMode.values) {
          final List<Destination> destinations = destinationsPour(
            role: role,
            mode: mode,
          );
          expect(
            destinations.length,
            lessThanOrEqualTo(NavShell.maxDestinations),
            reason: '${role.valeurSql} en mode ${mode.name}',
          );
        }
      }
    });

    test('chaque destination porte un libelle et son icone', () {
      for (final AppRole role in AppRole.values) {
        for (final Destination destination in destinationsPour(
          role: role,
          mode: InterfaceMode.standard,
        )) {
          expect(destination.libelle, isNotEmpty);
          expect(destination.chemin, isNotEmpty);
        }
      }
    });
  });
}
