import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/tc_catalogue/routes_tc_b.dart';

SessionState _session({
  required AppRole role,
  AccountStatus statut = AccountStatus.active,
}) => SessionState(
  resolue: true,
  profileId: 'p1',
  householdId: 'h1',
  role: role,
  accountStatus: statut,
  teacherOperational: role == AppRole.teacher && statut == AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 9, 6, 10);

  group('Scenario 3 : un compte en portail d attente ne passe nulle part', () {
    // Toutes les routes protegees de l'application, y compris celles d'autres
    // roles : le test vaut aussi pour une URL tapee directement sur le Web.
    // Non `const` : les cinq poses de l'enseignant se construisent par
    // fonction, un identifiant faisant partie du chemin.
    final List<String> protegees = <String>[
      Routes.eleve,
      Routes.eleveCoran,
      Routes.eleveSuivi,
      Routes.tuteurAccueil,
      Routes.tuteurFoyer,
      Routes.tuteurDisponibilites,
      Routes.tuteurReglages,
      Routes.tuteurSuivi,
      Routes.enseignantJournee,
      Routes.enseignantCreneaux,
      Routes.enseignantProfil,
      // Les cinq ecrans hors barre du role Enseignant. Un dossier non valide
      // ne doit pas davantage atteindre un cahier de transmission qu'une
      // journee : le cahier porte des prenoms d'enfants.
      Routes.enseignantBienvenue,
      Routes.cahierPour('s1'),
      Routes.groupePour('g1'),
      Routes.revuePour('g1'),
      Routes.controleur,
      Routes.admin,
      Routes.adminPersonnesDossiers,
      Routes.adminOperationsAttributions,
      Routes.adminSecuriteAuditJournal,
      Routes.comptable,
      Routes.compte,
      Routes.compteProfil,
      Routes.compteReglages,
      Routes.compteProfils,
      Routes.salle,
    ];

    for (final AccountStatus statut in <AccountStatus>[
      AccountStatus.pendingKyc,
      AccountStatus.disabled,
    ]) {
      for (final String chemin in protegees) {
        test('$chemin est refuse a un compte ${statut.valeurSql}', () {
          expect(
            deciderRedirection(
              session: _session(role: AppRole.teacher, statut: statut),
              cheminDemande: chemin,
              maintenant: maintenant,
            ),
            Routes.attente,
          );
        });
      }
    }

    test(
      'un statut illisible se traite comme une attente, jamais comme un acces',
      () {
        const SessionState sansStatut = SessionState(
          resolue: true,
          profileId: 'p1',
          role: AppRole.admin,
          lectureProfil: LectureProfil.presente,
        );
        expect(sansStatut.porte, PorteAcces.attente);
        expect(
          deciderRedirection(
            session: sansStatut,
            cheminDemande: Routes.adminSecuriteAuditJournal,
            maintenant: maintenant,
          ),
          Routes.attente,
        );
      },
    );

    test('le portail d attente lui-meme reste atteignable', () {
      expect(
        deciderRedirection(
          session: _session(
            role: AppRole.teacher,
            statut: AccountStatus.pendingKyc,
          ),
          cheminDemande: Routes.attente,
          maintenant: maintenant,
        ),
        isNull,
      );
    });
  });

  group('Chaque role reste dans son espace', () {
    test('un eleve qui demande une route admin repart chez lui', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.student),
          cheminDemande: Routes.adminSecuriteAuditJournal,
          maintenant: maintenant,
        ),
        Routes.eleve,
      );
    });

    test('un enseignant qui demande le foyer d un tuteur repart chez lui', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.teacher),
          cheminDemande: Routes.tuteurFoyer,
          maintenant: maintenant,
        ),
        Routes.enseignantJournee,
      );
    });

    test('chaque role atteint bien sa propre racine', () {
      for (final AppRole role in AppRole.values) {
        expect(
          deciderRedirection(
            session: _session(role: role),
            cheminDemande: Routes.racinePour(role),
            maintenant: maintenant,
          ),
          isNull,
          reason: 'le role ${role.valeurSql} ne peut pas atteindre sa racine',
        );
      }
    });

    test('un compte provisoire accede comme un compte actif (ADR-014)', () {
      expect(
        deciderRedirection(
          session: _session(
            role: AppRole.guardian,
            statut: AccountStatus.provisionalActive,
          ),
          cheminDemande: Routes.tuteurFoyer,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('un compte actif atteint le portail commun depuis chaque role', () {
      for (final AppRole role in AppRole.values) {
        expect(
          deciderRedirection(
            session: _session(role: role),
            cheminDemande: Routes.compteReglages,
            maintenant: maintenant,
          ),
          isNull,
          reason: 'le role ${role.valeurSql} doit atteindre ses reglages',
        );
      }
    });
  });

  group('Les ecrans hors barre de l enseignant vivent sous son prefixe', () {
    // Ces cinq ecrans ne sont pas des destinations : ce sont des poses, ouvertes
    // depuis un ecran puis quittees. Ils n'en sont pas moins gouvernes par la
    // garde de prefixe, et c'est la raison pour laquelle ils portent tous
    // `/enseignant`. Ce groupe gele ce choix : un cahier pose a `/cahier`
    // passerait ces tests a l'envers.
    final List<String> poses = <String>[
      Routes.enseignantBienvenue,
      Routes.cahierPour('seance-1'),
      Routes.groupePour('groupe-1'),
      Routes.revuePour('groupe-1'),
    ];

    for (final String chemin in poses) {
      test('un enseignant atteint $chemin', () {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.teacher),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: '$chemin doit etre sous le prefixe du role enseignant',
        );
      });

      test('un tuteur qui demande $chemin repart chez lui', () {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.tuteurAccueil,
        );
      });
    }

    test('la garde de prefixe est bien ce qui les autorise', () {
      // Preuve directe : le meme ecran pose hors du prefixe serait refuse a
      // l'enseignant lui-meme. C'est le piege que documente `routes.dart`.
      expect(
        deciderRedirection(
          session: _session(role: AppRole.teacher),
          cheminDemande: '/cahier/seance-1',
          maintenant: maintenant,
        ),
        Routes.enseignantJournee,
      );
      for (final String chemin in poses) {
        expect(
          chemin.startsWith(Routes.prefixePour(AppRole.teacher)),
          isTrue,
          reason: '$chemin sort du prefixe de l enseignant',
        );
      }
    });
  });

  group('ADR-005 : la salle n est ni partageable ni memorisable', () {
    test('sans billet, une adresse de salle renvoie a la racine du role', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.student),
          cheminDemande: Routes.salle,
          maintenant: maintenant,
        ),
        Routes.eleve,
      );
    });

    test('avec un billet vivant, l entree passe', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.student),
          cheminDemande: Routes.salle,
          billet: BilletSalle(sessionId: 's1', emisA: maintenant),
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('un billet perime ne rouvre rien', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.student),
          cheminDemande: Routes.salle,
          billet: BilletSalle(
            sessionId: 's1',
            emisA: maintenant.subtract(BilletSalle.duree),
          ),
          maintenant: maintenant,
        ),
        Routes.eleve,
      );
    });
  });

  group('Etats de session sans acces', () {
    test('tant que la session n est pas resolue, rien n est decide', () {
      expect(
        deciderRedirection(
          session: const SessionState.chargement(),
          cheminDemande: Routes.adminSecuriteAuditJournal,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('un visiteur sans session part se connecter', () {
      expect(
        deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: Routes.eleve,
          maintenant: maintenant,
        ),
        Routes.connexion,
      );
    });
  });

  group('Etape 3, scenario 1 : un compte sans profil va s inscrire', () {
    // Une session valide dont la lecture de profil a abouti sans rien trouver.
    // C'est l'etat d'un compte tout juste cree : le jeton ne porte encore ni
    // role ni foyer, puisque le hook les lit dans une ligne qui n'existe pas.
    const SessionState sansProfil = SessionState(
      resolue: true,
      profileId: 'p1',
      lectureProfil: LectureProfil.absente,
    );

    test('la porte est bien celle de l inscription, pas la deconnexion', () {
      expect(sansProfil.porte, PorteAcces.inscription);
    });

    for (final String chemin in <String>[
      Routes.racine,
      Routes.connexion,
      Routes.attente,
      Routes.eleve,
      Routes.tuteurFoyer,
      Routes.enseignantJournee,
      Routes.adminSecuriteAuditJournal,
      Routes.salle,
    ]) {
      test('$chemin renvoie sur l inscription', () {
        expect(
          deciderRedirection(
            session: sansProfil,
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.inscription,
        );
      });
    }

    test('l inscription elle-meme reste atteignable', () {
      expect(
        deciderRedirection(
          session: sansProfil,
          cheminDemande: Routes.inscription,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('un compte deja profile ne peut pas revenir a l inscription', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.guardian),
          cheminDemande: Routes.inscription,
          maintenant: maintenant,
        ),
        // La racine du tuteur est son accueil, `TUT-01`, et non l'ecran de
        // gestion des appareils : c'est le suivi du foyer qui accueille le
        // parent, pas son administration.
        Routes.tuteurAccueil,
      );
    });

    test(
      'un compte en attente ne peut pas non plus s y refabriquer un profil',
      () {
        expect(
          deciderRedirection(
            session: _session(
              role: AppRole.guardian,
              statut: AccountStatus.disabled,
            ),
            cheminDemande: Routes.inscription,
            maintenant: maintenant,
          ),
          Routes.attente,
        );
      },
    );
  });

  group('Etape 3, scenario 2 : un echec de lecture n est pas une absence', () {
    // La distinction est la seule chose qui separe « inscris-toi » de
    // « attends » : les deux etats se ressemblent depuis le client.
    const SessionState lectureEchouee = SessionState(
      resolue: true,
      profileId: 'p1',
      lectureProfil: LectureProfil.echouee,
    );

    test(
      'un echec ferme sur le portail d attente, il n ouvre pas l inscription',
      () {
        expect(lectureEchouee.porte, PorteAcces.attente);
        expect(
          deciderRedirection(
            session: lectureEchouee,
            cheminDemande: Routes.inscription,
            maintenant: maintenant,
          ),
          Routes.attente,
        );
      },
    );

    test('tant que la lecture n a pas eu lieu, rien n est decide', () {
      const SessionState pasEncoreLue = SessionState(
        resolue: true,
        profileId: 'p1',
      );
      expect(pasEncoreLue.porte, PorteAcces.chargement);
      expect(
        deciderRedirection(
          session: pasEncoreLue,
          cheminDemande: Routes.adminSecuriteAuditJournal,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('un profil present dont le jeton n a pas encore le role attend', () {
      // Fenetre entre la creation du profil et le rafraichissement du jeton.
      // Elle se ferme, mais elle ne doit rien ouvrir en attendant.
      const SessionState jetonEnRetard = SessionState(
        resolue: true,
        profileId: 'p1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      );
      expect(jetonEnRetard.porte, PorteAcces.attente);
    });
  });

  group('Scenario 6 : une seule arborescence pour les deux modes', () {
    test('les racines de role ne dependent pas du mode d interface', () {
      const SessionState enfant = SessionState(
        resolue: true,
        profileId: 'p1',
        role: AppRole.student,
        accountStatus: AccountStatus.active,
        interfaceMode: InterfaceMode.enfant,
        lectureProfil: LectureProfil.presente,
      );
      const SessionState standard = SessionState(
        resolue: true,
        profileId: 'p1',
        role: AppRole.student,
        accountStatus: AccountStatus.active,
        interfaceMode: InterfaceMode.standard,
        lectureProfil: LectureProfil.presente,
      );

      for (final String chemin in <String>[
        Routes.eleve,
        Routes.eleveCoran,
        Routes.eleveSuivi,
        Routes.adminSecuriteAuditJournal,
        Routes.salle,
      ]) {
        expect(
          deciderRedirection(
            session: enfant,
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          deciderRedirection(
            session: standard,
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          reason: '$chemin se comporte differemment selon le mode',
        );
      }
    });
  });

  group(
    'Scenario 7 : le Teaching Core sous /tc/, autorisation par sous-arbre',
    () {
      // Plan d'integration Teaching Core, section 8.2 point 4 : chaque
      // sous-arbre `/tc/` porte ses propres roles, contrairement au prefixe
      // unique de `Routes.prefixePour`. Sans cette autorisation, les sept
      // chemins sont inatteignables pour tous les roles : `/tc/` n'appartient
      // a aucun.
      const Map<String, List<AppRole>> autorises = <String, List<AppRole>>{
        '/tc/groupes': <AppRole>[AppRole.student, AppRole.guardian],
        '/tc/groupes/g1': <AppRole>[AppRole.student, AppRole.guardian],
        '/tc/bibliotheque': <AppRole>[AppRole.student, AppRole.guardian],
        '/tc/classe': <AppRole>[AppRole.teacher, AppRole.student],
        '/tc/mushaf': <AppRole>[AppRole.student],
        '/tc/observation/s1': <AppRole>[
          AppRole.guardian,
          AppRole.admin,
          AppRole.controller,
        ],
      };

      test('les deux constantes de la Bibliotheque designent la meme adresse', () {
        // `/tc/bibliotheque` est ecrit en dur DEUX fois : `Routes.tcBibliotheque`,
        // que lit le garde d'autorisation ci-dessus, et `RoutesTcB.bibliotheque`,
        // que lisent la route et le compositeur `RoutesTcB.avecGroupe`. Rien
        // dans `lib/` ne les relie, et rien ne peut le faire :
        // `core/router/routes.dart` importerait alors `features/`, ce qui
        // inverse le sens des dependances du depot. L'egalite se tient donc
        // ici. Sans elle, le jour ou l'une bouge, l'adresse serait composee
        // correctement puis rejetee par la redirection, sans rien de rouge.
        expect(RoutesTcB.bibliotheque, Routes.tcBibliotheque);
      });

      for (final MapEntry<String, List<AppRole>> entree in autorises.entries) {
        for (final AppRole role in AppRole.values) {
          final bool doitPasser = entree.value.contains(role);
          test(
            '${entree.key} ${doitPasser ? "s ouvre" : "se refuse"} a ${role.valeurSql}',
            () {
              final String? decision = deciderRedirection(
                session: _session(role: role),
                cheminDemande: entree.key,
                maintenant: maintenant,
              );
              if (doitPasser) {
                expect(decision, isNull);
              } else {
                expect(decision, Routes.racinePour(role));
              }
            },
          );
        }
      }
    },
  );
}
