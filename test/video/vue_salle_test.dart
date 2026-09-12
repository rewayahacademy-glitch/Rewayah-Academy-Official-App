import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';

/// Un acces emis par le backend, dans l'un des quatre roles.
///
/// Les capacites suivent exactement ce que `autoriser_jeton_video()` calcule :
/// l'enseignant publie image et donnees, l'eleve la voix et l'image seulement
/// si sa politique l'autorise, l'observateur et le controleur rien du tout.
AccesSalle _acces(String role, {bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher' || (role == 'student' && camera),
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime(2026, 9, 12, 18, 30),
);

ParticipantSalle _personne({
  required String identite,
  required String role,
  bool local = false,
  bool micro = false,
  bool camera = false,
}) => ParticipantSalle(
  identite: identite,
  nom: identite,
  role: role,
  estLocal: local,
  micro: micro,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

VueSalle _vue({
  required AccesSalle? acces,
  bool materielPret = true,
  EtatSalle etat = EtatSalle.connecte,
  List<ParticipantSalle> participants = const <ParticipantSalle>[],
  QualiteLien qualite = QualiteLien.bonne,
  CauseImpasse? impasse,
}) => VueSalle.depuis(
  materielPret: materielPret,
  acces: acces,
  etatMoteur: etat,
  participants: participants,
  qualite: qualite,
  impasse: impasse,
);

void main() {
  group('Le role vient du jeton, jamais de la session', () {
    test('les quatre roles de participant_role sont reconnus', () {
      expect(RoleSalle.depuis('teacher'), RoleSalle.enseignant);
      expect(RoleSalle.depuis('student'), RoleSalle.eleve);
      expect(RoleSalle.depuis('guardian_observer'), RoleSalle.tuteurObservateur);
      expect(RoleSalle.depuis('masked_controller'), RoleSalle.controleur);
    });

    test('un role inconnu retombe sur le plus ferme, jamais sur le plus ouvert', () {
      // Le jour ou la base gagnera un cinquieme role, une application non mise
      // a jour doit donner une salle en lecture seule, pas un jeu de commandes
      // devine. Le repli n'est donc ni `eleve` ni `enseignant`.
      expect(RoleSalle.depuis('quelque_chose_de_neuf'), RoleSalle.inconnu);
      expect(RoleSalle.depuis(null), RoleSalle.inconnu);
    });
  });

  group('Les phases, dans l ordre de la verite', () {
    test('le materiel passe avant tout le reste', () {
      final VueSalle vue = _vue(acces: null, materielPret: false);
      expect(vue.phase, PhaseSalle.materiel);
    });

    test('sans jeton, on est en ouverture', () {
      expect(_vue(acces: null).phase, PhaseSalle.ouverture);
    });

    test('avec jeton, l etat du moteur decide', () {
      final AccesSalle acces = _acces('student');
      expect(
        _vue(acces: acces, etat: EtatSalle.connexion).phase,
        PhaseSalle.connexion,
      );
      expect(
        _vue(acces: acces, etat: EtatSalle.connecte).phase,
        PhaseSalle.enSalle,
      );
      expect(
        _vue(acces: acces, etat: EtatSalle.reconnexion).phase,
        PhaseSalle.reconnexion,
      );
      expect(_vue(acces: acces, etat: EtatSalle.echec).phase, PhaseSalle.refus);
    });

    test('une impasse connue passe devant un moteur qui se croit connecte', () {
      // L'ordre compte : un jeton refuse alors qu'une connexion precedente
      // tient encore afficherait sinon une salle ou l'on n'est plus.
      final VueSalle vue = _vue(
        acces: _acces('student'),
        impasse: CauseImpasse.acces,
      );
      expect(vue.phase, PhaseSalle.refus);
      expect(vue.cause, CauseImpasse.acces);
    });

    test('un echec sans cause nommee est un echec de lien', () {
      final VueSalle vue = _vue(acces: _acces('student'), etat: EtatSalle.echec);
      expect(vue.cause, CauseImpasse.reseau);
      expect(vue.cause.seReessaye, isTrue);
    });
  });

  group('Les quatre refus se traduisent, sans rien inventer', () {
    test('les deux pannes de configuration ne se distinguent pas a l ecran', () {
      // Le backend les distingue (503 « non configuree » contre trousseau
      // inutilisable) ; l'usager n'a rien a en faire : dans les deux cas il n'y
      // a rien a reparer de son cote.
      expect(
        CauseImpasse.depuis(MotifRefusSalle.videoNonConfiguree),
        CauseImpasse.configuration,
      );
      expect(
        CauseImpasse.depuis(MotifRefusSalle.fournisseurIndisponible),
        CauseImpasse.configuration,
      );
    });

    test('un refus d acces ne se reessaye pas, l heure n aura pas change', () {
      expect(CauseImpasse.depuis(MotifRefusSalle.acces), CauseImpasse.acces);
      expect(CauseImpasse.acces.seReessaye, isFalse);
      expect(CauseImpasse.configuration.seReessaye, isFalse);
      expect(CauseImpasse.materiel.seReessaye, isTrue);
      expect(CauseImpasse.reseau.seReessaye, isTrue);
    });
  });

  group('Les capacites decident des commandes, jamais le mode d interface', () {
    test('un eleve dont la politique interdit la camera ne peut pas la montrer', () {
      final VueSalle vue = _vue(acces: _acces('student'));
      expect(vue.peutParler, isTrue);
      expect(vue.peutMontrer, isFalse);
    });

    test('un eleve autorise peut montrer son image', () {
      final VueSalle vue = _vue(acces: _acces('student', camera: true));
      expect(vue.peutMontrer, isTrue);
    });

    test('un observateur et un controleur ne publient rien', () {
      for (final String role in <String>[
        'guardian_observer',
        'masked_controller',
      ]) {
        final VueSalle vue = _vue(acces: _acces(role));
        expect(vue.peutParler, isFalse, reason: role);
        expect(vue.peutMontrer, isFalse, reason: role);
      }
    });

    test('sans jeton, aucune capacite n est supposee', () {
      final VueSalle vue = _vue(acces: null);
      expect(vue.peutParler, isFalse);
      expect(vue.peutMontrer, isFalse);
    });
  });

  group('L invisibilite du controleur, telle qu ADR-011 la definit', () {
    test('il ne figure pas dans sa propre liste de participants', () {
      // **Le test visuel de la fonction** (fiche produit `CTR-02`) : il doit
      // lire exactement ce que lit l'enseignant, deux personnes, sans s y
      // trouver. Sans ce retrait, son ecran en afficherait trois.
      final VueSalle vue = _vue(
        acces: _acces('masked_controller'),
        participants: <ParticipantSalle>[
          _personne(identite: 'c1', role: 'masked_controller', local: true),
          _personne(identite: 't1', role: 'teacher'),
          _personne(identite: 'e1', role: 'student'),
        ],
      );

      expect(vue.invisible, isTrue);
      expect(vue.moi, isNull);
      expect(vue.participantsListes.length, 2);
      expect(
        vue.participantsListes.map((ParticipantSalle p) => p.identite),
        <String>['t1', 'e1'],
      );
    });

    test('l enseignant lit les deux memes personnes, lui compris', () {
      final VueSalle vue = _vue(
        acces: _acces('teacher'),
        participants: <ParticipantSalle>[
          _personne(identite: 't1', role: 'teacher', local: true),
          _personne(identite: 'e1', role: 'student'),
        ],
      );

      expect(vue.participantsListes.length, 2);
      expect(vue.moi?.identite, 't1');
      expect(vue.voitLesParticipants, isTrue);
    });

    test('l eleve et l observateur ne voient pas la liste', () {
      // Une seance est plafonnee a deux participants en MVP-0 (ADR-004) : une
      // liste de deux lignes dont une est soi-meme n'apprend rien, et le mode
      // enfant n'a droit qu'a deux commandes.
      expect(_vue(acces: _acces('student')).voitLesParticipants, isFalse);
      expect(
        _vue(acces: _acces('guardian_observer')).voitLesParticipants,
        isFalse,
      );
    });
  });

  group('Qui occupe le grand cadre', () {
    test('l eleve voit son enseignant', () {
      final VueSalle vue = _vue(
        acces: _acces('student'),
        participants: <ParticipantSalle>[
          _personne(identite: 'e1', role: 'student', local: true),
          _personne(identite: 't1', role: 'teacher'),
        ],
      );
      expect(vue.dominant?.identite, 't1');
      expect(vue.autres, isEmpty);
    });

    test('l enseignant voit son eleve, et non le tuteur qui assiste', () {
      // « Assister » entre en observateur : il ne prend pas la place de
      // l'eleve dans le cadre, sinon le cours se donnerait au spectateur.
      final VueSalle vue = _vue(
        acces: _acces('teacher'),
        participants: <ParticipantSalle>[
          _personne(identite: 't1', role: 'teacher', local: true),
          _personne(identite: 'g1', role: 'guardian_observer'),
          _personne(identite: 'e1', role: 'student'),
        ],
      );
      expect(vue.dominant?.identite, 'e1');
      expect(vue.autres.map((ParticipantSalle p) => p.identite), <String>['g1']);
    });

    test('qui observe voit l enseignant en grand', () {
      final VueSalle vue = _vue(
        acces: _acces('masked_controller'),
        participants: <ParticipantSalle>[
          _personne(identite: 'c1', role: 'masked_controller', local: true),
          _personne(identite: 'e1', role: 'student'),
          _personne(identite: 't1', role: 'teacher'),
        ],
      );
      expect(vue.dominant?.identite, 't1');
    });

    test('a defaut du role attendu, le premier venu occupe le cadre', () {
      // Plutot qu'un cadre vide alors que quelqu'un est bien la : une salle ou
      // l'on entend une voix sans voir personne se lit comme une panne.
      final VueSalle vue = _vue(
        acces: _acces('student'),
        participants: <ParticipantSalle>[
          _personne(identite: 'e1', role: 'student', local: true),
          _personne(identite: 'g1', role: 'guardian_observer'),
        ],
      );
      expect(vue.dominant?.identite, 'g1');
    });

    test('seul en salle se sait', () {
      final VueSalle vue = _vue(
        acces: _acces('student'),
        participants: <ParticipantSalle>[
          _personne(identite: 'e1', role: 'student', local: true),
        ],
      );
      expect(vue.seulEnSalle, isTrue);
      expect(vue.dominant, isNull);
    });
  });

  group('La qualite du lien ne se dit que quand elle compte', () {
    test('les deux valeurs basses se disent', () {
      for (final QualiteLien lien in <QualiteLien>[
        QualiteLien.mediocre,
        QualiteLien.perdue,
      ]) {
        expect(
          _vue(acces: _acces('student'), qualite: lien).lienADire,
          isTrue,
          reason: lien.name,
        );
      }
    });

    test('un bon lien ne s annonce pas', () {
      // Annoncer « connexion excellente » pendant un cours n'apporte rien et
      // occuperait la place que le Coran prendra.
      for (final QualiteLien lien in <QualiteLien>[
        QualiteLien.excellente,
        QualiteLien.bonne,
        QualiteLien.inconnue,
      ]) {
        expect(
          _vue(acces: _acces('student'), qualite: lien).lienADire,
          isFalse,
          reason: lien.name,
        );
      }
    });
  });
}
