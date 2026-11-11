// LUMIERE-ACCUEILS 3 et 4 : les signaux viennent seulement des etats que le
// serveur rend, dans l'ordre de priorite ; un etat illisible ou inconnu ne
// fait jamais de signal.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accueil/signaux_accueils.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';

PresenceParticipant _p(EtatPresence etat, {String role = 'student'}) =>
    PresenceParticipant(
      profilId: 'p-${etat.name}-$role',
      role: role,
      prenom: 'Eleve',
      identifiantImmuable: 'RA-26-0001',
      etat: etat,
      consolide: false,
    );

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
        presenceEnCours: null,
        cahiersARemplir: 0,
      );
      expect(s, isEmpty);
      expect(signalDominant(s), isNull);
    });

    test('ordre : remplacements, presence (urgents), puis cahiers', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 2,
        presenceEnCours: <PresenceParticipant>[
          _p(EtatPresence.absente),
          _p(EtatPresence.enRetard),
          _p(EtatPresence.presente),
        ],
        cahiersARemplir: 3,
      );
      expect(s, <SignalAccueil<MotifEnseignant>>[
        const SignalAccueil<MotifEnseignant>(
          nature: NatureSignal.urgent,
          motif: MotifEnseignant.remplacement,
          nombre: 2,
        ),
        const SignalAccueil<MotifEnseignant>(
          nature: NatureSignal.urgent,
          motif: MotifEnseignant.presence,
          nombre: 2,
        ),
        const SignalAccueil<MotifEnseignant>(
          nature: NatureSignal.aPreparer,
          motif: MotifEnseignant.cahier,
          nombre: 3,
        ),
      ]);
      expect(signalDominant(s)!.motif, MotifEnseignant.remplacement);
    });

    test('presence : excusee, inconnue, deconnectee et l\'enseignant ne comptent pas', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 0,
        presenceEnCours: <PresenceParticipant>[
          _p(EtatPresence.excusee),
          _p(EtatPresence.inconnu),
          _p(EtatPresence.deconnectee),
          _p(EtatPresence.absente, role: 'teacher'),
        ],
        cahiersARemplir: 0,
      );
      expect(s, isEmpty);
    });

    test('seul le cahier : la lumiere orange est la dominante', () {
      final List<SignalAccueil<MotifEnseignant>> s = signauxAujourdhui(
        offresRemplacement: 0,
        presenceEnCours: const <PresenceParticipant>[],
        cahiersARemplir: 1,
      );
      expect(signalDominant(s)!.nature, NatureSignal.aPreparer);
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
      expect(r.single.nature, NatureSignal.urgent);
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
                    x.nature == NatureSignal.aPreparer,
              ),
          isTrue,
        );
        expect(signalDominant(s)!.motif, MotifDirection.signalement);
      },
    );
  });
}
