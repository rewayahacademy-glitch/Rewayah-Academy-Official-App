// FERMETURE-SALLE (directeur, 11/11/2026, seconde moitie de SEC-1, journal
// D-018) : apres le depart de l'enseignant et un delai de grace, le serveur
// ferme le micro des eleves ; a la fin de la seance, il ferme la salle.
// L'application ne decide rien : elle demande au serveur de relire la regle
// aux deux moments utiles, et lit ce que LiveKit lui dit ensuite.

// fake_async est la dependance de flutter_test qui porte son horloge simulee
// (version fixee par le SDK) ; pubspec.yaml n'est pas modifie par ce lot.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/video/fermeture_salle.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';

AccesSalle _acces(String role, {bool publier = true}) => AccesSalle.depuisJson(
  <String, dynamic>{
    'ws_url': 'wss://exemple',
    'token': 'jeton',
    'room_name': 'salle',
    'provider': 'cloud',
    'role': role,
    'expire_le': '2026-11-11T18:05:00Z',
    'capabilities': <String, dynamic>{
      'can_publish': true,
      'can_publish_video': false,
      'can_publish_data': role == 'teacher',
      'can_subscribe': true,
      'can_moderate': role == 'teacher',
      'hidden': false,
    },
    'publication_differee': !publier,
  },
).pourLaDemande(seanceId: 'seance-1');

void main() {
  group('le micro ferme parce que l\'enseignant n\'est plus la', () {
    final AccesSalle ouvert = _acces('student');
    final AccesSalle ferme = ouvert.avecPublication(
      peutPublier: false,
      peutPublierVideo: false,
    );

    test('droit ouvert puis ferme, sans enseignant dans la salle : c\'est ce '
        'cas', () {
      expect(
        microFermeSansEnseignant(
          avant: ouvert,
          apres: ferme,
          enseignantPresent: false,
        ),
        isTrue,
      );
    });

    test('l\'enseignant est la (recitation d\'un camarade) : ce n\'est pas ce '
        'cas', () {
      expect(
        microFermeSansEnseignant(
          avant: ouvert,
          apres: ferme,
          enseignantPresent: true,
        ),
        isFalse,
      );
    });

    test('le droit etait deja ferme (attente avant le cours), ou il s\'ouvre : '
        'rien a dire', () {
      expect(
        microFermeSansEnseignant(
          avant: ferme,
          apres: ferme,
          enseignantPresent: false,
        ),
        isFalse,
      );
      expect(
        microFermeSansEnseignant(
          avant: ferme,
          apres: ouvert,
          enseignantPresent: false,
        ),
        isFalse,
      );
      expect(
        microFermeSansEnseignant(
          avant: null,
          apres: ferme,
          enseignantPresent: false,
        ),
        isFalse,
      );
    });
  });

  group('la salle fermee par le serveur ne se confond avec rien d\'autre', () {
    test('seule la salle supprimee compte ; ni l\'exclusion, ni la panne', () {
      expect(salleFermeeParLeServeur(lk.DisconnectReason.roomDeleted), isTrue);
      for (final lk.DisconnectReason? raison in <lk.DisconnectReason?>[
        null,
        lk.DisconnectReason.participantRemoved,
        lk.DisconnectReason.duplicateIdentity,
        lk.DisconnectReason.clientInitiated,
        lk.DisconnectReason.signalClose,
        lk.DisconnectReason.serverShutdown,
        lk.DisconnectReason.unknown,
      ]) {
        expect(salleFermeeParLeServeur(raison), isFalse, reason: '$raison');
      }
    });

    test('la salle supprimee reste un echec pour les ecrans, sans reprise '
        'automatique, et le moteur ne la dit fermee qu\'apres coup', () {
      expect(
        LiveKitSessionProvider.issueDeconnexion(lk.DisconnectReason.roomDeleted),
        (etat: EtatSalle.echec, ailleurs: false),
      );
      // Rentrer seul dans une salle que le serveur vient de fermer, ce serait
      // rentrer contre sa decision.
      expect(repriseSansGestePermise(lk.DisconnectReason.roomDeleted), isFalse);
      expect(LiveKitSessionProvider().salleFermee, isFalse);
    });

    test('la cause « seance terminee » ne se reessaie pas, a la difference de '
        '« votre enseignant vous a fait sortir »', () {
      expect(CauseImpasse.seanceTerminee.seReessaye, isFalse);
      expect(CauseImpasse.retire.seReessaye, isTrue);
    });
  });

  group('les phrases', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    test('en francais : celles du directeur', () {
      expect(
        t.salle.fermeture.sansEnseignantTitre,
        'Votre enseignant n\'est plus dans la salle',
      );
      expect(
        t.salle.fermeture.microFerme,
        'Votre micro est fermé jusqu\'à son retour.',
      );
      expect(
        t.salle.fermeture.sansEnseignantTitreTutoie,
        'Ton enseignant n\'est plus dans la salle',
      );
      expect(
        t.salle.fermeture.microFermeTutoie,
        'Ton micro est fermé jusqu\'à son retour.',
      );
      expect(t.salle.fermeture.seanceTerminee, 'La séance est terminée.');
      // Distincte de la phrase d'une exclusion par l'enseignant.
      expect(t.salle.fermeture.seanceTerminee, isNot(t.salle.retire));
    });

    test('en arabe : traduites, jamais le francais recopie', () async {
      final List<String> fr = <String>[
        t.salle.fermeture.sansEnseignantTitre,
        t.salle.fermeture.microFerme,
        t.salle.fermeture.seanceTerminee,
        t.salle.fermeture.seanceTermineeDetail,
      ];
      await LocaleSettings.setLocale(AppLocale.ar);
      final List<String> ar = <String>[
        t.salle.fermeture.sansEnseignantTitre,
        t.salle.fermeture.microFerme,
        t.salle.fermeture.seanceTerminee,
        t.salle.fermeture.seanceTermineeDetail,
      ];
      for (int i = 0; i < fr.length; i++) {
        expect(ar[i], isNot(fr[i]));
        expect(RegExp('[A-Za-z]').hasMatch(ar[i]), isFalse, reason: ar[i]);
      }
    });
  });

  group('la reponse du serveur a la verification', () {
    test('le temps restant se lit ; toute autre forme ne donne rien', () {
      expect(resteAvantEcheance(<String, dynamic>{'reste_s': 117}), 117);
      expect(resteAvantEcheance(<String, dynamic>{'reste_s': 0}), 0);
      expect(resteAvantEcheance(<String, dynamic>{'reste_s': null}), isNull);
      expect(resteAvantEcheance(<String, dynamic>{'reste_s': -3}), isNull);
      expect(resteAvantEcheance(<String, dynamic>{'reste_s': '12'}), isNull);
      expect(resteAvantEcheance(<String, dynamic>{}), isNull);
      expect(resteAvantEcheance(null), isNull);
      expect(resteAvantEcheance('texte'), isNull);
    });
  });

  group('la veille : l\'enseignant n\'est plus dans la salle', () {
    test('elle demande la verification apres cinq secondes, puis a '
        'l\'echeance que le serveur annonce', () {
      fakeAsync((FakeAsync temps) {
        final List<AccesSalle> demandes = <AccesSalle>[];
        final List<int?> reponses = <int?>[117, null];
        final VeilleFermeture veille = VeilleFermeture((AccesSalle a) async {
          demandes.add(a);
          return reponses[demandes.length - 1];
        });
        final AccesSalle acces = _acces('student');
        veille.observer(acces: acces, enseignantPresent: true);
        temps.elapse(const Duration(minutes: 5));
        expect(demandes, isEmpty, reason: 'enseignant present : rien');

        veille.observer(acces: acces, enseignantPresent: false);
        temps.elapse(const Duration(seconds: 4));
        expect(demandes, isEmpty);
        temps.elapse(const Duration(seconds: 1));
        expect(demandes, hasLength(1));
        // Le serveur a dit : encore 117 secondes.
        temps.elapse(const Duration(seconds: 118));
        expect(demandes, hasLength(1));
        temps.elapse(const Duration(seconds: 1));
        expect(demandes, hasLength(2));
        veille.arreter();
      });
    });

    test('l\'enseignant revient avant l\'echeance : plus aucune demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          return 117;
        });
        final AccesSalle acces = _acces('student');
        veille.observer(acces: acces, enseignantPresent: false);
        temps.elapse(const Duration(seconds: 5));
        expect(demandes, 1);
        veille.observer(acces: acces, enseignantPresent: true);
        temps.elapse(const Duration(minutes: 10));
        expect(demandes, 1);
        veille.arreter();
      });
    });

    test('le serveur a ferme le micro (le droit arrive ferme) : la veille se '
        'tait', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          return 0;
        });
        final AccesSalle acces = _acces('student');
        veille.observer(acces: acces, enseignantPresent: false);
        temps.elapse(const Duration(seconds: 5));
        expect(demandes, 1);
        veille.observer(
          acces: acces.avecPublication(
            peutPublier: false,
            peutPublierVideo: false,
          ),
          enseignantPresent: false,
        );
        temps.elapse(const Duration(minutes: 10));
        expect(demandes, 1);
        veille.arreter();
      });
    });

    test('un eleve qui attend avant le cours (droit ferme), un enseignant, un '
        'tuteur : rien n\'est demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          return null;
        });
        for (final AccesSalle acces in <AccesSalle>[
          _acces('student', publier: false),
          _acces('teacher'),
          _acces('guardian_observer'),
        ]) {
          veille.observer(acces: acces, enseignantPresent: false);
          temps.elapse(const Duration(minutes: 5));
        }
        expect(demandes, 0);
        veille.arreter();
      });
    });

    test('une panne du serveur n\'arrete rien : la demande est refaite', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          throw StateError('serveur muet');
        });
        veille.observer(acces: _acces('student'), enseignantPresent: false);
        temps.elapse(const Duration(seconds: 5));
        expect(demandes, 1);
        temps.elapse(VeilleFermeture.ecartSansReponse);
        expect(demandes, 2);
        veille.arreter();
        temps.elapse(const Duration(minutes: 10));
        expect(demandes, 2, reason: 'sortie de la salle : plus rien');
      });
    });
  });

  group('la veille : la fin du depassement autorise', () {
    test('rien avant ; une demande juste apres ; puis une par minute tant que '
        'la salle reste ouverte', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final DateTime debut = DateTime.utc(2026, 11, 11, 12);
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          return null;
        }, maintenant: () => debut.add(temps.elapsed));
        // L'enseignant aussi demande : la regle vaut pour toute la salle.
        veille.observer(acces: _acces('teacher'), enseignantPresent: false);
        veille.finPorteUtc = debut.add(const Duration(minutes: 10));
        temps.elapse(const Duration(minutes: 10));
        expect(demandes, 0);
        temps.elapse(VeilleFermeture.delaiPremiereDemande);
        expect(demandes, 1);
        temps.elapse(VeilleFermeture.ecartApresLaFin);
        expect(demandes, 2);
        // Salle fermee : le moteur sort.
        veille.arreter();
        temps.elapse(const Duration(minutes: 10));
        expect(demandes, 2);
      });
    });

    test('sans fin connue, ou hors salle : aucune demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final DateTime debut = DateTime.utc(2026, 11, 11, 12);
        final VeilleFermeture veille = VeilleFermeture((AccesSalle _) async {
          demandes++;
          return null;
        }, maintenant: () => debut.add(temps.elapsed));
        veille.observer(acces: _acces('teacher'), enseignantPresent: false);
        temps.elapse(const Duration(hours: 2));
        expect(demandes, 0, reason: 'fin inconnue');
        veille.observer(acces: null, enseignantPresent: false);
        veille.finPorteUtc = debut;
        temps.elapse(const Duration(hours: 1));
        expect(demandes, 0, reason: 'hors salle');
      });
    });
  });
}
