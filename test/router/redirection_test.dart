import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

SessionState _session({
  required AppRole role,
  AccountStatus statut = AccountStatus.active,
}) => SessionState(
  resolue: true,
  profileId: 'p1',
  householdId: 'h1',
  role: role,
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 9, 6, 10);

  group('Scenario 3 : un compte en portail d attente ne passe nulle part', () {
    // Toutes les routes protegees de l'application, y compris celles d'autres
    // roles : le test vaut aussi pour une URL tapee directement sur le Web.
    const List<String> protegees = <String>[
      Routes.eleve,
      Routes.eleveCoran,
      Routes.eleveSuivi,
      Routes.tuteurFoyer,
      Routes.tuteurDisponibilites,
      Routes.tuteurReglages,
      Routes.tuteurSuivi,
      Routes.enseignantJournee,
      Routes.enseignantCreneaux,
      Routes.enseignantProfil,
      Routes.controleur,
      Routes.adminTableauDeBord,
      Routes.adminDossiers,
      Routes.adminAttribution,
      Routes.adminJournal,
      Routes.comptable,
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
              session: _session(role: AppRole.guardian, statut: statut),
              cheminDemande: chemin,
              maintenant: maintenant,
            ),
            Routes.attente,
          );
        });
      }
    }

    test('un statut illisible se traite comme une attente, jamais comme un acces', () {
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
          cheminDemande: Routes.adminJournal,
          maintenant: maintenant,
        ),
        Routes.attente,
      );
    });

    test('le portail d attente lui-meme reste atteignable', () {
      expect(
        deciderRedirection(
          session: _session(
            role: AppRole.guardian,
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
          cheminDemande: Routes.adminJournal,
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
          cheminDemande: Routes.adminJournal,
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
      Routes.adminJournal,
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
        Routes.tuteurFoyer,
      );
    });

    test('un compte en attente ne peut pas non plus s y refabriquer un profil', () {
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
    });
  });

  group('Etape 3, scenario 2 : un echec de lecture n est pas une absence', () {
    // La distinction est la seule chose qui separe « inscris-toi » de
    // « attends » : les deux etats se ressemblent depuis le client.
    const SessionState lectureEchouee = SessionState(
      resolue: true,
      profileId: 'p1',
      lectureProfil: LectureProfil.echouee,
    );

    test('un echec ferme sur le portail d attente, il n ouvre pas l inscription', () {
      expect(lectureEchouee.porte, PorteAcces.attente);
      expect(
        deciderRedirection(
          session: lectureEchouee,
          cheminDemande: Routes.inscription,
          maintenant: maintenant,
        ),
        Routes.attente,
      );
    });

    test('tant que la lecture n a pas eu lieu, rien n est decide', () {
      const SessionState pasEncoreLue = SessionState(
        resolue: true,
        profileId: 'p1',
      );
      expect(pasEncoreLue.porte, PorteAcces.chargement);
      expect(
        deciderRedirection(
          session: pasEncoreLue,
          cheminDemande: Routes.adminJournal,
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
        Routes.adminJournal,
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
}
