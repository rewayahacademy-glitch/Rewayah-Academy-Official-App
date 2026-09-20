import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

const HorlogeAffichee _riyad = HorlogeAffichee(
  fuseauIana: 'Asia/Riyadh',
  libelleVille: 'Riyad',
  heureLocaleRendue: '18:00',
  dateLocaleRendue: 'Lundi 21 septembre',
);

const HorlogeAffichee _conakry = HorlogeAffichee(
  fuseauIana: 'Africa/Conakry',
  libelleVille: 'Conakry',
  heureLocaleRendue: '15:00',
  dateLocaleRendue: 'Lundi 21 septembre',
);

FenetreSeance _fenetre() => FenetreSeance(
  debutUtc: DateTime.utc(2026, 9, 21, 15),
  finPrevueUtc: DateTime.utc(2026, 9, 21, 16, 30),
  fenetreAcces: const Duration(minutes: 20),
  graceApresFin: const Duration(minutes: 15),
);

SessionClockVM _horloge(
  DateTime maintenant, {
  HorlogeAffichee? contrepartie = _conakry,
  bool connecte = false,
  bool? seanceOuverte,
  NoticeDst? notice,
}) => SessionClockVM.depuisFenetre(
  fenetre: _fenetre(),
  maintenantServeurUtc: maintenant,
  horlogeUtilisateur: _riyad,
  horlogeContrepartie: contrepartie,
  connecte: connecte,
  seanceOuverte: seanceOuverte,
  noticeDst: notice,
);

void main() {
  group('SessionClockVM : les deux horloges', () {
    test('les heures arrivent deja rendues, jamais un offset', () {
      final SessionClockVM vm = _horloge(DateTime.utc(2026, 9, 21, 11, 32));
      expect(vm.horlogeUtilisateur.heureLocaleRendue, '18:00');
      expect(vm.horlogeContrepartie!.heureLocaleRendue, '15:00');
      // Le libelle est une ville lisible, jamais « UTC+3 ».
      expect(vm.horlogeUtilisateur.libelleVille, 'Riyad');
      expect(vm.horlogeContrepartie!.libelleVille, isNot(contains('UTC')));
    });

    test('deux fuseaux identiques ne donnent qu une horloge', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 11, 32),
        contrepartie: const HorlogeAffichee(
          fuseauIana: 'Asia/Riyadh',
          libelleVille: 'Riyad',
          heureLocaleRendue: '18:00',
          dateLocaleRendue: 'Lundi 21 septembre',
        ),
      );
      expect(vm.horlogeContrepartie, isNull);
    });

    test('aucune contrepartie donnee reste aucune contrepartie', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 11, 32),
        contrepartie: null,
      );
      expect(vm.horlogeContrepartie, isNull);
    });
  });

  group('SessionClockVM : le temps', () {
    test('le restant derive de l instant serveur, pas de l appareil', () {
      final DateTime instantServeur = DateTime.utc(2026, 9, 21, 11, 32);
      final SessionClockVM vm = _horloge(instantServeur);
      expect(vm.calculeeAUtc, instantServeur);
      expect(vm.restant, const Duration(hours: 3, minutes: 28));
      expect(vm.phase, PhaseSeance.avantFenetre);
      expect(vm.rejoindreOuvert, isFalse);
    });

    test('a T-20 la porte s ouvre', () {
      final SessionClockVM vm = _horloge(DateTime.utc(2026, 9, 21, 14, 40));
      expect(vm.phase, PhaseSeance.salleOuverte);
      expect(vm.rejoindreOuvert, isTrue);
      expect(vm.restant, const Duration(minutes: 20));
    });

    test('connecte avant T0, aucun temps academique n est consomme', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 14, 50),
        connecte: true,
      );
      expect(vm.phase, PhaseSeance.attenteAvantT0);
      // Le temps restant compte toujours vers le DEBUT : rien n'a commence.
      expect(vm.restant, const Duration(minutes: 10));
    });

    test('a T0 le cours est en cours', () {
      final SessionClockVM vm = _horloge(DateTime.utc(2026, 9, 21, 15));
      expect(vm.phase, PhaseSeance.enCours);
      expect(vm.restant, const Duration(hours: 1, minutes: 30));
      expect(vm.enDirect, isTrue);
    });

    test('en depassement, aucun nombre, aucun signe negatif', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 16, 40),
        seanceOuverte: true,
      );
      expect(vm.phase, PhaseSeance.prolongee);
      expect(vm.restant, isNull);
      expect(LibellesGroupe.ligneEtat(vm), LibellesGroupe.prolongee);
      expect(LibellesGroupe.ligneEtat(vm), isNot(contains('-')));
    });

    test('terminee, la porte est fermee', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 17),
        seanceOuverte: false,
      );
      expect(vm.phase, PhaseSeance.terminee);
      expect(vm.restant, isNull);
      expect(vm.rejoindreOuvert, isFalse);
    });

    test('la duree se lit de la fenetre, pas d une constante', () {
      expect(
        _horloge(DateTime.utc(2026, 9, 21, 11, 32)).duree,
        const Duration(hours: 1, minutes: 30),
      );
    });
  });

  group('SessionClockVM : la notice de changement d heure', () {
    test('elle est transportee, jamais calculee', () {
      final SessionClockVM vm = _horloge(
        DateTime.utc(2026, 9, 21, 11, 32),
        notice: NoticeDst(
          transitionUtc: DateTime.utc(2026, 10, 25, 1),
          fuseauConcerne: 'Europe/Paris',
          heureAvantRendue: '13:00',
          heureApresRendue: '12:00',
          echeance: EcheanceDst.j7,
        ),
      );
      expect(vm.noticeDst!.fuseauConcerne, 'Europe/Paris');
      expect(vm.noticeDst!.deplaceLHeure, isTrue);
      expect(LibellesGroupe.dstEcheance(EcheanceDst.j30), isNotEmpty);
      expect(LibellesGroupe.dstEcheance(EcheanceDst.j1), isNotEmpty);
    });

    test('une transition qui ne deplace pas l heure n annonce rien', () {
      final NoticeDst inerte = NoticeDst(
        transitionUtc: DateTime.utc(2026, 10, 25, 1),
        fuseauConcerne: 'Africa/Conakry',
        heureAvantRendue: '15:00',
        heureApresRendue: '15:00',
        echeance: EcheanceDst.j1,
      );
      expect(inerte.deplaceLHeure, isFalse);
    });
  });

  group('Le double de demonstration', () {
    test('rend une horloge coherente pour chaque etat annonce', () async {
      final HorlogeSeanceDemonstration double = HorlogeSeanceDemonstration(
        cadence: Duration.zero,
      );
      final Map<String, PhaseSeance> attendu = <String, PhaseSeance>{
        GroupesDemonstration.alFatiha: PhaseSeance.avantFenetre,
        GroupesDemonstration.anNour: PhaseSeance.salleOuverte,
        GroupesDemonstration.alIhsan: PhaseSeance.attenteAvantT0,
        GroupesDemonstration.alBaqara: PhaseSeance.enCours,
        GroupesDemonstration.alHikma: PhaseSeance.prolongee,
        GroupesDemonstration.arRahma: PhaseSeance.terminee,
      };
      for (final MapEntry<String, PhaseSeance> cas in attendu.entries) {
        final SessionClockVM? vm = await double.horlogeDe(groupeId: cas.key);
        expect(vm, isNotNull, reason: cas.key);
        expect(vm!.phase, cas.value, reason: cas.key);
      }
    });

    test(
      'un groupe sans occurrence materialisee ne rend aucune horloge',
      () async {
        // C'est l'etat REEL de la base : `sessions` n'a pas de `groupe_id` et
        // `materialiser_seances()` ignore les groupes.
        final HorlogeSeanceDemonstration double = HorlogeSeanceDemonstration(
          cadence: Duration.zero,
        );
        expect(
          await double.horlogeDe(groupeId: GroupesDemonstration.sabil),
          isNull,
        );
      },
    );

    test('l instant serveur ne vient pas de l horloge de la machine', () async {
      final HorlogeSeanceDemonstration double = HorlogeSeanceDemonstration(
        cadence: Duration.zero,
      );
      expect(await double.maintenantServeurUtc(), ancreDemonstration);
    });

    test('une cadence nulle ferme le flux apres une seule valeur', () async {
      final HorlogeSeanceDemonstration double = HorlogeSeanceDemonstration(
        cadence: Duration.zero,
      );
      final List<SessionClockVM> recues = await double.suivre(
        groupeId: GroupesDemonstration.alFatiha,
      ).toList();
      expect(recues, hasLength(1));
    });
  });
}
