// FN-023 : les bornes du chrono de `/salle` viennent des seances servies.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/features/salle_seance/bornes_salle.dart';

void main() {
  final DateTime debut = DateTime.utc(2026, 11, 1, 17);
  final DateTime fin = DateTime.utc(2026, 11, 1, 18);

  LigneBornes ligne(String id, {String? groupe, bool aCreer = false}) =>
      (id: id, groupeId: groupe, aCreer: aCreer, debut: debut, fin: fin);

  test('la seance se trouve par son identifiant', () {
    final BornesChrono? b = bornesDeLaSeance(
      seanceId: 's1',
      groupeId: 'g1',
      lignes: <LigneBornes>[ligne('s0'), ligne('s1')],
    );
    expect(b, BornesChrono(debutUtc: debut, finPrevueUtc: fin));
  });

  test('a defaut, le cours du moment de la Classe encore sans seance', () {
    final BornesChrono? b = bornesDeLaSeance(
      seanceId: 's-cree-au-rejoindre',
      groupeId: 'g1',
      lignes: <LigneBornes>[
        ligne('cours-sans-seance:g2', groupe: 'g2', aCreer: true),
        ligne('cours-sans-seance:g1', groupe: 'g1', aCreer: true),
      ],
    );
    expect(b?.debutUtc, debut);
    expect(b?.finPrevueUtc, fin);
  });

  test('une seance d une autre Classe ne donne jamais ses bornes', () {
    expect(
      bornesDeLaSeance(
        seanceId: 'sX',
        groupeId: 'g1',
        lignes: <LigneBornes>[ligne('s2', groupe: 'g1')],
      ),
      isNull,
    );
  });

  test('rien de lu : aucun chrono, rien d invente', () {
    expect(
      bornesDeLaSeance(
        seanceId: 's1',
        groupeId: null,
        lignes: const <LigneBornes>[],
      ),
      isNull,
    );
  });

  test(
    'le provider lit les seances de l eleve servies par le serveur',
    () async {
      final ProviderContainer c = ProviderContainer(
        overrides: [
          seancesProvider.overrideWith(
            (Ref ref) async => <Seance>[
              Seance(
                id: 's1',
                debut: debut,
                fin: fin,
                statut: StatutSeance.planifiee,
                eleveId: 'e',
                elevePrenom: 'Amina',
                eleveIdentifiant: '',
                enseignantId: 't',
                enseignantPrenom: 'Yusuf',
                enseignantIdentifiant: '',
              ),
            ],
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(seancesProvider.future);
      expect(
        c.read(
          bornesSalleProvider((
            seanceId: 's1',
            groupeId: null,
            enseignant: false,
          )),
        ),
        BornesChrono(debutUtc: debut, finPrevueUtc: fin),
      );
    },
  );
}
