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
  lectureProfil: LectureProfil.presente,
);

/// L'adresse de connexion qui garde [chemin] en destination de retour.
String _connexionAvecRetour(String chemin) => Uri(
  path: Routes.connexion,
  queryParameters: <String, String>{'retour': chemin},
).toString();

void main() {
  final DateTime maintenant = DateTime.utc(2026, 9, 6, 10);

  group('Scenario 3 : un compte en portail d attente ne passe nulle part', () {
    // Toutes les routes protegees de l'application, y compris celles d'autres
    // roles : le test vaut aussi pour une URL tapee directement sur le Web.
    final List<String> protegees = <String>[
      Routes.eleve,
      Routes.eleveCoran,
      Routes.eleveSuivi,
      Routes.tuteurAccueil,
      Routes.tuteurFoyer,
      Routes.tuteurReglages,
      Routes.tuteurSuivi,
      Routes.tuteurCompte,
      Routes.ficheElevePour('e1'),
      Routes.classePour('g1'),
      Routes.seancePour('s1'),
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
      Routes.adminOperationsRegroupements,
      Routes.adminOperationsOffres,
      Routes.adminOperationsPilotage,
      Routes.adminSecuriteAuditJournal,
      Routes.adminSecuriteAuditObservations,
      Routes.adminSecuriteAuditTirages,
      Routes.comptable,
      Routes.compte,
      Routes.compteProfil,
      Routes.compteReglages,
      Routes.compteProfils,
      Routes.salle,
      Routes.accesRefuse,
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
            role: AppRole.guardian,
            statut: AccountStatus.pendingKyc,
          ),
          cheminDemande: Routes.attente,
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    // CAND-06 : la carte a partager vit dans le sous-arbre du portail, ouvert
    // au compte en attente (le candidat), sans rien d'autre a ouvrir.
    test('la carte a partager (/attente/partage) reste atteignable', () {
      for (final AppRole role in <AppRole>[AppRole.teacher, AppRole.guardian]) {
        expect(
          deciderRedirection(
            session: _session(role: role, statut: AccountStatus.pendingKyc),
            cheminDemande: Routes.attentePartage,
            maintenant: maintenant,
          ),
          isNull,
          reason: '$role',
        );
      }
    });

    // K-47 (HL-A-6) : la piece d'identite ne concerne que l'enseignant.
    test('le depot de piece : ouvert a l enseignant, ferme au tuteur', () {
      String? pour(AppRole role) => deciderRedirection(
        session: _session(role: role, statut: AccountStatus.pendingKyc),
        cheminDemande: Routes.attentePiece,
        maintenant: maintenant,
      );
      expect(pour(AppRole.teacher), isNull);
      expect(pour(AppRole.guardian), Routes.attente);
      // AD-NETTOYAGE (m3) : la regle est positive, tout autre role est ferme.
      expect(pour(AppRole.student), Routes.attente);
      expect(pour(AppRole.admin), Routes.attente);
    });

    test('le depot de piece est ferme a un role illisible', () {
      expect(
        deciderRedirection(
          session: const SessionState(
            resolue: true,
            profileId: 'p1',
            householdId: 'h1',
            accountStatus: AccountStatus.pendingKyc,
            lectureProfil: LectureProfil.presente,
          ),
          cheminDemande: Routes.attentePiece,
          maintenant: maintenant,
        ),
        Routes.attente,
      );
    });
  });

  group('Chaque role reste dans son espace', () {
    // Les autres roles gardent le renvoi a leur racine d'avant le chantier
    // Tuteur V1 : la page « acces refuse » est reservee au tuteur tant que le
    // directeur n'a pas decide de l'etendre (revue phase 0, routes D3).
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

    test('un tuteur qui demande une route admin voit l acces refuse', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.guardian),
          cheminDemande: Routes.adminSecuriteAuditJournal,
          maintenant: maintenant,
        ),
        Routes.accesRefuse,
      );
    });

    test('la page d acces refuse est ouverte a chaque role actif', () {
      for (final AppRole role in AppRole.values) {
        expect(
          deciderRedirection(
            session: _session(role: role),
            cheminDemande: Routes.accesRefuse,
            maintenant: maintenant,
          ),
          isNull,
          reason: role.valeurSql,
        );
      }
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

    test('les roles autres que le tuteur gardent le portail commun', () {
      for (final AppRole role in AppRole.values) {
        if (role == AppRole.guardian) {
          continue;
        }
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

  group('AD-11 : la file des dossiers est gardee pour chaque role', () {
    // Routes.adminPersonnesDossiers porte des pieces d'identite : seul
    // l'administrateur y entre ; le tuteur voit l'acces refuse, les autres
    // roles repartent a leur racine.
    for (final AppRole role in AppRole.values) {
      test('${Routes.adminPersonnesDossiers} et ${role.valeurSql}', () {
        final String? decision = deciderRedirection(
          session: _session(role: role),
          cheminDemande: Routes.adminPersonnesDossiers,
          maintenant: maintenant,
        );
        if (role == AppRole.admin) {
          expect(decision, isNull);
        } else if (role == AppRole.guardian) {
          expect(decision, Routes.accesRefuse);
        } else {
          expect(decision, Routes.racinePour(role));
          expect(decision, isNot(Routes.adminPersonnesDossiers));
        }
      });
    }
  });

  group('Le tuteur : ses anciennes adresses communes le rejoignent', () {
    final Map<String, String> alias = <String, String>{
      Routes.compte: Routes.tuteurCompte,
      Routes.compteProfil: Routes.compteTuteurSousPage('informations'),
      Routes.compteReglages: Routes.tuteurComptePreferences,
      Routes.compteProfils: Routes.tuteurFoyer,
      Routes.compteProfilEnfantPour('e1'): Routes.ficheElevePour('e1'),
      '${Routes.compte}/inconnue': '${Routes.tuteurCompte}/inconnue',
      Routes.tcGroupes: Routes.tuteurAccueil,
      Routes.tcEspaceGroupe('g1'): Routes.classePour('g1'),
      '${Routes.tcEspaceGroupe('g1')}/x': Routes.classePour('g1'),
    };
    for (final MapEntry<String, String> a in alias.entries) {
      test('${a.key} -> ${a.value}', () {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: a.key,
            maintenant: maintenant,
          ),
          a.value,
        );
      });
    }

    test('toutes ses nouvelles routes restent sous /tuteur (R1, R2)', () {
      for (final String chemin in <String>[
        Routes.tuteurAccueilAlias,
        Routes.tuteurNotifications,
        Routes.tuteurClassesCatalogue,
        Routes.classePour('g1'),
        Routes.classeSousPage('g1', 'observer'),
        Routes.tuteurAjouterEnfant,
        Routes.tuteurAjouterEnfantAncien,
        Routes.tuteurFoyerAppareils,
        Routes.ficheEleveSousPage('e1', 'camera'),
        Routes.tuteurSuiviObservations,
        Routes.tuteurHistoriqueAlias,
        Routes.seancePour('s1'),
        Routes.tuteurCompteApparence,
        Routes.tuteurCompteConsentements,
      ]) {
        expect(
          chemin.startsWith('${Routes.prefixePour(AppRole.guardian)}/'),
          isTrue,
          reason: chemin,
        );
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: chemin,
        );
      }
      expect(Routes.prefixePour(AppRole.guardian), Routes.tuteurAccueil);
    });

    test('un autre role ne passe pas par les alias du tuteur', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.student),
          cheminDemande: Routes.tcEspaceGroupe('g1'),
          maintenant: maintenant,
        ),
        isNull,
      );
      expect(
        deciderRedirection(
          session: _session(role: AppRole.teacher),
          cheminDemande: Routes.tuteurAccueilAlias,
          maintenant: maintenant,
        ),
        Routes.enseignantJournee,
      );
    });
  });

  group('Les ecrans hors barre de l enseignant vivent sous son prefixe', () {
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

      test('un tuteur qui demande $chemin voit l acces refuse', () {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.accesRefuse,
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

    test('un visiteur sans session part se connecter, destination gardee', () {
      expect(
        deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: Routes.eleve,
          maintenant: maintenant,
        ),
        _connexionAvecRetour(Routes.eleve),
      );
      // La requete fait partie de la destination.
      expect(
        deciderRedirection(
          session: const SessionState.deconnecte(),
          cheminDemande: Routes.tuteurClassesCatalogue,
          cheminComplet: '${Routes.tuteurClassesCatalogue}?eleve=e1',
          maintenant: maintenant,
        ),
        _connexionAvecRetour('${Routes.tuteurClassesCatalogue}?eleve=e1'),
      );
    });

    test(
      'la racine d un visiteur sans session mene a la connexion (17/10)',
      () {
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: Routes.racine,
            maintenant: maintenant,
          ),
          Routes.connexion,
        );
        // Une route protegee va toujours a la connexion, avec son retour.
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: Routes.tuteurCompte,
            maintenant: maintenant,
          ),
          _connexionAvecRetour(Routes.tuteurCompte),
        );
      },
    );

    test('la salle et la classe ne deviennent jamais un retour', () {
      for (final String chemin in <String>[Routes.salle, '/tc/classe']) {
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.connexion,
          reason: chemin,
        );
      }
    });

    test('les sous-arbres publics restent ouverts sans session', () {
      for (final String chemin in <String>[
        Routes.connexion,
        Routes.connexionEleve,
        Routes.connexionEleveScanner,
        Routes.connexionEleveCode,
        Routes.connexionRecuperation,
        Routes.bienvenue,
        Routes.agentEntree,
        Routes.juridique,
        '${Routes.juridique}/confidentialite',
      ]) {
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: chemin,
        );
      }
      expect(Routes.publiques, <String>{
        Routes.connexion,
        Routes.bienvenue,
        Routes.agentEntree,
        Routes.juridique,
      });
    });

    test('les textes juridiques se lisent aussi connecte', () {
      for (final String chemin in <String>[
        Routes.juridique,
        '${Routes.juridique}/conditions',
      ]) {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: chemin,
        );
      }
    });

    test('un compte actif quitte l accueil public et la page hors ligne', () {
      for (final String chemin in <String>[
        Routes.bienvenue,
        Routes.horsLigne,
      ]) {
        expect(
          deciderRedirection(
            session: _session(role: AppRole.guardian),
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.tuteurAccueil,
          reason: chemin,
        );
      }
    });
  });

  group('Retour apres connexion : un chemin interne valide et ouvert', () {
    String? apresConnexion(AppRole role, String retour) => deciderRedirection(
      session: _session(role: role),
      cheminDemande: Routes.connexion,
      retour: retour,
      maintenant: maintenant,
    );

    test('la destination gardee est reprise, requete comprise', () {
      expect(
        apresConnexion(AppRole.guardian, Routes.ficheElevePour('e1')),
        Routes.ficheElevePour('e1'),
      );
      expect(
        apresConnexion(
          AppRole.guardian,
          '${Routes.tuteurClassesCatalogue}?eleve=e1',
        ),
        '${Routes.tuteurClassesCatalogue}?eleve=e1',
      );
    });

    test('une destination d un autre role ramene a la racine', () {
      expect(
        apresConnexion(AppRole.guardian, Routes.enseignantJournee),
        Routes.tuteurAccueil,
      );
    });

    test('une adresse externe, la salle ou l agent ne sont jamais repris', () {
      for (final String retour in <String>[
        'https://exemple.test/piege',
        '//exemple.test',
        '/salle',
        '/tc/classe',
        '/agent?jeton=x',
        '/tuteur/../admin',
        Routes.connexion,
        Routes.racine,
      ]) {
        expect(
          apresConnexion(AppRole.guardian, retour),
          Routes.tuteurAccueil,
          reason: retour,
        );
      }
    });

    test('une page d etat n est pas une destination a reprendre', () {
      // Revue phase 0 (routes D6) : `retour=/acces-refuse` faisait atterrir
      // sur « Acces refuse » juste apres la connexion.
      for (final AppRole role in <AppRole>[
        AppRole.guardian,
        AppRole.teacher,
        AppRole.student,
      ]) {
        for (final String retour in <String>[
          Routes.accesRefuse,
          Routes.horsLigne,
        ]) {
          expect(
            apresConnexion(role, retour),
            Routes.racinePour(role),
            reason: '${role.valeurSql} $retour',
          );
        }
      }
    });
  });

  group('Page introuvable : aucune route ne correspond', () {
    test('le routeur rend la page introuvable, quelle que soit la porte', () {
      final List<SessionState> sessions = <SessionState>[
        const SessionState.deconnecte(),
        const SessionState(
          resolue: true,
          profileId: 'p1',
          lectureProfil: LectureProfil.absente,
        ),
        _session(role: AppRole.guardian, statut: AccountStatus.pendingKyc),
        for (final AppRole role in AppRole.values) _session(role: role),
      ];
      for (final SessionState session in sessions) {
        for (final String chemin in <String>[
          '/tuteur/inconnue',
          '/nimporte/quoi',
          '/tuteur/foyer/e1/inconnue',
        ]) {
          expect(
            deciderRedirection(
              session: session,
              cheminDemande: chemin,
              routeConnue: false,
              maintenant: maintenant,
            ),
            isNull,
            reason: '$chemin (${session.porte.name})',
          );
        }
      }
    });
  });

  group('Hors ligne au demarrage : rien ne s ouvre', () {
    const SessionState injoignable = SessionState(
      resolue: true,
      profileId: 'p1',
      role: AppRole.guardian,
      lectureProfil: LectureProfil.injoignable,
    );

    test('la porte est hors ligne, ni attente ni acces', () {
      expect(injoignable.porte, PorteAcces.horsLigne);
    });

    test('toute adresse mene a la page hors ligne', () {
      for (final String chemin in <String>[
        Routes.racine,
        Routes.tuteurAccueil,
        Routes.attente,
        Routes.inscription,
        Routes.connexion,
        '/nimporte/quoi',
      ]) {
        expect(
          deciderRedirection(
            session: injoignable,
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          Routes.horsLigne,
          reason: chemin,
        );
      }
      expect(
        deciderRedirection(
          session: injoignable,
          cheminDemande: Routes.horsLigne,
          maintenant: maintenant,
        ),
        isNull,
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

    test('l inscription et ses etapes restent atteignables', () {
      for (final String chemin in <String>[
        Routes.inscription,
        Routes.inscriptionUsage,
        Routes.inscriptionIdentite,
        Routes.inscriptionGenre,
        Routes.inscriptionTelephone,
        Routes.inscriptionRecapitulatif,
      ]) {
        expect(
          deciderRedirection(
            session: sansProfil,
            cheminDemande: chemin,
            maintenant: maintenant,
          ),
          isNull,
          reason: chemin,
        );
      }
    });

    test('l etape du telephone est fermee a un compte deja profile', () {
      expect(
        deciderRedirection(
          session: _session(role: AppRole.teacher),
          cheminDemande: Routes.inscriptionTelephone,
          maintenant: maintenant,
        ),
        isNot(isNull),
      );
      expect(
        deciderRedirection(
          session: _session(role: AppRole.teacher),
          cheminDemande: Routes.inscriptionTelephone,
          maintenant: maintenant,
        ),
        isNot(Routes.inscriptionTelephone),
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

  group('Scenario 7 : le Teaching Core sous /tc/, autorisation par sous-arbre', () {
    // Plan d'integration Teaching Core, section 8.2 point 4 : chaque
    // sous-arbre `/tc/` porte ses propres roles. Le tuteur rejoint ses
    // classes sous `/tuteur/classes` (alias ci-dessus) : `/tc/groupes` ne
    // lui est plus servi.
    const Map<String, List<AppRole>> autorises = <String, List<AppRole>>{
      '/tc/groupes': <AppRole>[AppRole.student],
      '/tc/groupes/g1': <AppRole>[AppRole.student],
      '/tc/bibliotheque': <AppRole>[
        AppRole.student,
        AppRole.guardian,
        AppRole.teacher,
      ],
      // L'ancienne classe n'a plus de route : refusee a tous (A-05).
      '/tc/classe': <AppRole>[],
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
      // que lisent la route et le compositeur `RoutesTcB.avecGroupe`. L'egalite
      // se tient donc ici.
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
            } else if (role == AppRole.guardian &&
                entree.key.startsWith(Routes.tcGroupes)) {
              // Le tuteur n'est pas refuse : il est conduit a sa classe.
              expect(decision, startsWith(Routes.tuteurAccueil));
            } else if (role == AppRole.guardian) {
              expect(decision, Routes.accesRefuse);
            } else {
              // Les autres roles repartent chez eux, comme avant le chantier.
              expect(decision, Routes.racinePour(role));
            }
          },
        );
      }
    }
  });
}
