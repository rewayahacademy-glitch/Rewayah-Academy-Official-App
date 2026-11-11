// LUMIERE-ACCUEILS 3 et 4 : les signaux viennent seulement des etats que le
// serveur rend, dans l'ordre de priorite ; un etat illisible ou inconnu ne
// fait jamais de signal.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accueil/signaux_accueils.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';

Alerte _a(GraviteAlerte g) => Alerte(
  id: 'a-${g.name}',
  gravite: g,
  titre: 'Signalement',
  creeeLe: DateTime.utc(2026, 11, 11),
);

IndicateursAdmin _i({
  int dossiers = 0,
  int incidents = 0,
  int demandes = 0,
  int rapports = 0,
}) => IndicateursAdmin(
  dossiersEnAttente: dossiers,
  foyersSansEnseignant: 0,
  rapportsManquants: rapports,
  incidents24h: incidents,
  comptesEchus: 0,
  demandesEnAttente: demandes,
);

void main() {
  group('Aujourd\'hui de l\'enseignant', () {
    test('rien a signaler : aucun signal, aucune lumiere', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 0,
        cahiersARemplir: 0,
      );
      expect(s, isEmpty);
      expect(signalDominant(s), isNull);
    });

    test('ordre : remplacements (urgent), puis cahiers (a preparer)', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 2,
        cahiersARemplir: 3,
      );
      expect(s, <SignalAccueil<MotifEnseignant>>[
        const SignalAccueil<MotifEnseignant>(
          nature: NatureHalo.urgent,
          motif: MotifEnseignant.remplacement,
          nombre: 2,
        ),
        const SignalAccueil<MotifEnseignant>(
          nature: NatureHalo.aPreparer,
          motif: MotifEnseignant.cahier,
          nombre: 3,
        ),
      ]);
      expect(signalDominant(s)!.motif, MotifEnseignant.remplacement);
    });

    test(
      'LUMIERE 3 : eleves pas encore entres, rouge, apres les remplacements',
      () {
        final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
          offresRemplacement: 1,
          cahiersARemplir: 2,
          elevesPasEntres: 3,
        );
        expect(
          s.map((SignalAccueil<MotifEnseignant> x) => x.motif),
          <MotifEnseignant>[
            MotifEnseignant.remplacement,
            MotifEnseignant.absents,
            MotifEnseignant.cahier,
          ],
        );
        expect(s[1].nature, NatureHalo.urgent);
        expect(s[1].nombre, 3);
        expect(
          signalDominant(
            signauxAujourdhui(
              offresRemplacement: 0,
              cahiersARemplir: 1,
              elevesPasEntres: 1,
            ),
          )!.motif,
          MotifEnseignant.absents,
        );
      },
    );

    test('seul le cahier : la lumiere orange est la dominante', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 0,
        cahiersARemplir: 1,
      );
      expect(signalDominant(s)!.nature, NatureHalo.aPreparer);
    });
  });

  group('accueil de la direction', () {
    test('illisible : aucun signal invente', () {
      expect(signauxDirection(alertes: null, indicateurs: null), isEmpty);
    });

    test('seul un signalement urgent allume le rouge', () {
      final List<SignalAccueil<MotifDirection>> s = signauxDirection(
        alertes: <Alerte>[_a(GraviteAlerte.important), _a(GraviteAlerte.info)],
        indicateurs: _i(),
      );
      expect(s, isEmpty);
      final List<SignalAccueil<MotifDirection>> r = signauxDirection(
        alertes: <Alerte>[
          _a(GraviteAlerte.urgent),
          _a(GraviteAlerte.important),
        ],
        indicateurs: _i(),
      );
      expect(r.single.nature, NatureHalo.urgent);
      expect(r.single.motif, MotifDirection.signalement);
      expect(r.single.nombre, 1);
    });

    test(
      'ordre : signalement, puis incidents, dossiers, demandes (a preparer)',
      () {
        final List<SignalAccueil<MotifDirection>> s = signauxDirection(
          alertes: <Alerte>[_a(GraviteAlerte.urgent)],
          indicateurs: _i(dossiers: 4, incidents: 1, demandes: 2, rapports: 9),
        );
        expect(
          s.map((SignalAccueil<MotifDirection> x) => x.motif),
          <MotifDirection>[
            MotifDirection.signalement,
            MotifDirection.incidents,
            MotifDirection.dossiers,
            MotifDirection.demandes,
          ],
        );
        expect(
          s
              .skip(1)
              .every(
                (SignalAccueil<MotifDirection> x) =>
                    x.nature == NatureHalo.aPreparer,
              ),
          isTrue,
        );
        expect(signalDominant(s)!.motif, MotifDirection.signalement);
      },
    );

    test('dossiers : la lumiere suit le chiffre affiche, pas le compteur', () {
      expect(
        signauxDirection(
          alertes: const <Alerte>[],
          indicateurs: _i(dossiers: 2),
          dossiersAffiches: 0,
        ),
        isEmpty,
      );
      expect(
        signauxDirection(
          alertes: const <Alerte>[],
          indicateurs: _i(),
          dossiersAffiches: 1,
        ).single.nombre,
        1,
      );
    });
  });
}
