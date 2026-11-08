// RELEVE-SUIVI point 7 (08/11/2026) : la ligne de progression de Ma classe,
// pour l'eleve adulte, lue par `progression_famille` (branche « titulaire de
// soi »). En production, l'adaptateur ne la remplissait jamais : les tests
// « niveau et derniere etape » et « lecture en echec » sont ROUGES sans ce
// lot ; les trois autres gardent qu'aucune ligne n'est inventee.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/features/accueil_adulte/port_espace_adulte.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class _Progression implements PortProgressionFamille {
  _Progression(this._reponse);
  final Future<ProgressionEleve> Function(String) _reponse;
  final List<String> lus = <String>[];

  @override
  Future<ProgressionEleve> progression(String eleveId) {
    lus.add(eleveId);
    return _reponse(eleveId);
  }
}

class _Espace extends EspaceAdulteIndisponible {
  const _Espace(this._vue);
  final MaClasseAdulteVM _vue;

  @override
  Future<MaClasseAdulteVM> maClasse() async => _vue;
}

class _Session extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'p-adulte',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
    eleveAutonome: true,
  );
}

Future<MaClasseAdulteVM> _lire(MaClasseAdulteVM vue, _Progression port) async {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(_Session.new),
      portEspaceAdulteProvider.overrideWithValue(_Espace(vue)),
      portProgressionFamilleProvider.overrideWithValue(port),
    ],
  );
  addTearDown(c.dispose);
  return c.read(maClasseAdulteProvider.future);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test(
    'Ma classe dit le niveau et la derniere etape partagee, lus pour soi',
    () async {
      final _Progression port = _Progression(
        (String id) async => ProgressionEleve(
          eleveId: id,
          niveauHumain: 'Les bases',
          jalons: const <String>['Lire avec les voyelles', 'Les lettres'],
        ),
      );
      final MaClasseAdulteVM vue = await _lire(
        const MaClasseAdulteVM(groupeId: 'g1'),
        port,
      );
      expect(port.lus, <String>['p-adulte']);
      expect(
        vue.ligneProgression,
        LibellesGroupe.joindre('Les bases', 'Lire avec les voyelles'),
      );
    },
  );

  test('rien de partage : aucune section, rien d invente', () async {
    final MaClasseAdulteVM vue = await _lire(
      const MaClasseAdulteVM(groupeId: 'g1'),
      _Progression((String id) async => ProgressionEleve(eleveId: id)),
    );
    expect(vue.ligneProgression, isNull);
  });

  test('lecture en echec : « Non disponible » pour cette ligne seule, '
      'Ma classe reste lisible', () async {
    final MaClasseAdulteVM vue = await _lire(
      const MaClasseAdulteVM(groupeId: 'g1'),
      _Progression(
        (String _) async => throw StateError('progression indisponible'),
      ),
    );
    expect(vue.groupeId, 'g1');
    expect(vue.ligneProgression, t.compte.nonDisponible);
  });

  test('compte refuse par le serveur (role eleve) : ligne masquee, sans '
      'ecran d erreur', () async {
    for (final PostgrestException refus in <PostgrestException>[
      const PostgrestException(message: 'permission denied', code: '42501'),
      const PostgrestException(
        message: 'progression indisponible',
        code: 'P0001',
      ),
    ]) {
      final MaClasseAdulteVM vue = await _lire(
        const MaClasseAdulteVM(groupeId: 'g1'),
        _Progression((String _) async => throw refus),
      );
      expect(vue.groupeId, 'g1');
      expect(vue.ligneProgression, isNull);
    }
  });

  test('une vraie panne du serveur reste « Non disponible »', () async {
    final MaClasseAdulteVM vue = await _lire(
      const MaClasseAdulteVM(groupeId: 'g1'),
      _Progression(
        (String _) async =>
            throw const PostgrestException(message: 'timeout', code: '57014'),
      ),
    );
    expect(vue.ligneProgression, t.compte.nonDisponible);
  });

  test('sans adaptateur : aucune section, rien de simule', () async {
    final MaClasseAdulteVM vue = await _lire(
      const MaClasseAdulteVM(groupeId: 'g1'),
      _Progression(
        (String _) async => throw const CapaciteIndisponible('DB-CRS-11'),
      ),
    );
    expect(vue.ligneProgression, isNull);
  });

  test('sans Classe, ou ligne deja rendue : aucune lecture', () async {
    final _Progression port = _Progression(
      (String id) async => ProgressionEleve(eleveId: id, niveauHumain: 'X'),
    );
    expect(
      (await _lire(const MaClasseAdulteVM(), port)).ligneProgression,
      isNull,
    );
    expect(
      (await _lire(
        const MaClasseAdulteVM(groupeId: 'g1', ligneProgression: 'Demo'),
        port,
      )).ligneProgression,
      'Demo',
    );
    expect(port.lus, isEmpty);
  });
}
