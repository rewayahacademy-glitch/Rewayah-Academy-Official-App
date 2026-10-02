// Les espaces du controle en demonstration (CT-9, vague Controleur).
//
// Donnees fictives, aucun appel serveur (K-28). La demonstration remplit le
// port neutre `espacesCompteProvider` (lib/features/compte/espaces_compte.dart)
// avec les trois profils de `DonneesControleurDemo.profils` :
// - le controleur externe n'a que Controle ;
// - l'Enseignant-Controleur et l'Admin-Controleur ont leur espace principal
//   et Controle, avec le meme compte (C6) ;
// - une mission en cours retient en Controle (§4.2) ;
// - un acces revoque, ou une capacite absente, ferme Controle (C7, P-CTR-01).
//
// La propre Classe de l'Enseignant-Controleur n'est jamais proposee : c'est
// le serveur qui l'exclut (BR-1) ; la demonstration le montre en filtrant la
// seule seance en direct, celle d'An-Nour, qui est la sienne.
//
// Parametres d'adresse (tous facultatifs) : `profil` (externe, enseignant,
// admin), `espace=principal`, `mission=enCours`, `acces` (revoque,
// sansCapacite).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/domain/enums.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/nav_shell.dart';
import '../compte/compte_page.dart';
import '../compte/espaces_compte.dart';
import '../controleur/mission_controle.dart';
import 'classe_demo.dart' show DonneesClasseDemo;
import 'controleur_demo.dart';
import 'demo_controleur_page.dart'
    show adresseDemoControleur, missionDemoControleur;
import 'demo_enseignant_page.dart' show adresseDemoEnseignant;
import 'enseignant_demo.dart' show EcranDemoEnseignant;
import 'repere_demonstration.dart';

/// L'acces au controle dans la demonstration.
enum AccesDemoControleur {
  /// La capacite Controle est active.
  actif,

  /// La capacite a ete retiree pendant la navigation (P-CTR-01).
  revoque,

  /// Le compte n'a jamais eu la capacite (un enseignant qui ouvrirait le
  /// Controle).
  sansCapacite,
}

/// La situation d'espaces d'une page de demonstration.
@immutable
class SituationEspacesDemo {
  /// Cree la situation.
  const SituationEspacesDemo({
    this.profil = ProfilDemoControleur.externe,
    this.espacePrincipal = false,
    this.missionEnCours = false,
    this.acces = AccesDemoControleur.actif,
  });

  /// Lit la situation dans les parametres d'une adresse.
  factory SituationEspacesDemo.lire(Map<String, String> parametres) {
    T? lire<T extends Enum>(List<T> valeurs, String? nom) {
      for (final T v in valeurs) {
        if (v.name == nom) return v;
      }
      return null;
    }

    return SituationEspacesDemo(
      profil:
          lire(ProfilDemoControleur.values, parametres['profil']) ??
          ProfilDemoControleur.externe,
      espacePrincipal: parametres['espace'] == 'principal',
      missionEnCours: parametres['mission'] == 'enCours',
      acces:
          lire(AccesDemoControleur.values, parametres['acces']) ??
          AccesDemoControleur.actif,
    );
  }

  /// Le profil de demonstration.
  final ProfilDemoControleur profil;

  /// Vrai pour l'espace principal (Enseignant ou Admin), faux pour Controle.
  final bool espacePrincipal;

  /// Vrai quand une mission est en cours.
  final bool missionEnCours;

  /// L'acces au controle.
  final AccesDemoControleur acces;

  /// Les parametres d'adresse, sans les valeurs par defaut.
  Map<String, String> get parametres => <String, String>{
    if (profil != ProfilDemoControleur.externe) 'profil': profil.name,
    if (espacePrincipal) 'espace': 'principal',
    if (missionEnCours) 'mission': 'enCours',
    if (acces != AccesDemoControleur.actif) 'acces': acces.name,
  };

  /// La meme situation, dans l'espace Controle ou principal, sans mission.
  SituationEspacesDemo vers({required bool principal}) => SituationEspacesDemo(
    profil: profil,
    espacePrincipal: principal,
    acces: acces,
  );

  /// La meme situation, mission en cours.
  SituationEspacesDemo enMission() =>
      SituationEspacesDemo(profil: profil, missionEnCours: true, acces: acces);

  /// Le profil complet.
  ControleurDemo get controleur => DonneesControleurDemo.profils.firstWhere(
    (ControleurDemo c) => c.profil == profil,
  );

  /// L'espace principal du profil, ou nul pour le controleur externe.
  EspaceTravail? get principal => switch (profil) {
    ProfilDemoControleur.externe => null,
    ProfilDemoControleur.enseignant => EspaceTravail.enseignement,
    ProfilDemoControleur.admin => EspaceTravail.administration,
  };

  /// La projection d'espaces que le serveur rendrait.
  EspacesCompte get espaces {
    final EspaceTravail? p = principal;
    if (acces == AccesDemoControleur.sansCapacite) {
      return p == null
          ? EspacesCompte.aucun
          : EspacesCompte(disponibles: <EspaceTravail>[p], actif: p);
    }
    final EspacesCompte projection = p == null
        ? EspacesCompte(
            disponibles: const <EspaceTravail>[EspaceTravail.controle],
            actif: EspaceTravail.controle,
            missionEnCours: missionEnCours,
          )
        : EspacesCompte.cumul(
            principal: p,
            actif: espacePrincipal ? p : EspaceTravail.controle,
            missionEnCours: missionEnCours,
          );
    return acces == AccesDemoControleur.revoque
        ? projection.sansControle()
        : projection;
  }

  /// Les adresses des espaces, dans la demonstration.
  AdressesEspaces get adresses {
    final String principale = adresseDemoControleur(
      EcranDemoControleur.compte,
      espaces: vers(principal: true),
    );
    return AdressesEspaces(
      enseignement: principale,
      administration: principale,
      controle: adresseDemoControleur(
        EcranDemoControleur.controle,
        espaces: vers(principal: false),
      ),
      racine: Routes.demoControleur,
    );
  }
}

/// La projection d'espaces de la demonstration : une valeur fixe par page.
class EspacesCompteDemo extends EspacesCompteControleur {
  /// Cree la projection.
  EspacesCompteDemo(this._initiale);

  final EspacesCompte _initiale;

  @override
  EspacesCompte build() => _initiale;
}

/// Les surcharges d'espaces de [situation].
List<Override> surchargesEspacesDemo(SituationEspacesDemo situation) =>
    <Override>[
      espacesCompteProvider.overrideWith(
        () => EspacesCompteDemo(situation.espaces),
      ),
      adressesEspacesProvider.overrideWithValue(situation.adresses),
    ];

/// La mission attribuee a [profil] : le serveur n'attribue jamais sa propre
/// Classe a un Enseignant-Controleur (C6). La seule seance en direct de la
/// demonstration est celle d'An-Nour, la Classe de Sayyid Ibrahim : il n'a
/// donc aucune mission.
MissionControle? missionAttribueeDemo(
  EtatDemoControleur etat,
  ControleurDemo profil,
) {
  if (profil.classeExclue == DonneesClasseDemo.groupeId) return null;
  return missionDemoControleur(etat);
}

class _SessionPrincipaleDemo extends SessionControleur {
  _SessionPrincipaleDemo(this._role, this._id);

  final AppRole _role;
  final String _id;

  @override
  SessionState build() => SessionState(
    resolue: true,
    role: _role,
    profileId: _id,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// L'espace principal de l'Enseignant-Controleur ou de l'Admin-Controleur :
/// la VRAIE coquille de son role autour du VRAI `Compte`, comme `/compte` la
/// rend (`_CoquilleSecondaire`). Controle y est propose pour y passer.
class EspacePrincipalDemo extends StatelessWidget {
  /// Cree l'espace.
  const EspacePrincipalDemo({required this.situation, super.key});

  /// La situation (profil enseignant ou admin).
  final SituationEspacesDemo situation;

  @override
  Widget build(BuildContext context) {
    final bool admin = situation.profil == ProfilDemoControleur.admin;
    final List<Destination> destinations = destinationsPour(
      role: AppRole.teacher,
      mode: InterfaceMode.standard,
    );
    return ProviderScope(
      key: ValueKey<String>('principal-${situation.parametres}'),
      overrides: <Override>[
        sessionProvider.overrideWith(
          () => _SessionPrincipaleDemo(
            admin ? AppRole.admin : AppRole.teacher,
            situation.controleur.id,
          ),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        ...surchargesEspacesDemo(situation),
      ],
      child: RepereDemonstration(
        child: EnteteEspaces(
          child: admin
              // Aucune demonstration admin n'existe : les domaines restent
              // en place sans mener ailleurs (K-28).
              ? AdminShell(
                  domaines: domainesAdmin(voitDirection: false),
                  domaineActif: null,
                  onAller: (String _) {},
                  onCompte: () {},
                  child: const ComptePage(),
                )
              : NavShell(
                  destinations: destinations,
                  indexActif: null,
                  libellesDansLeRail: true,
                  // Les destinations Enseignant menent a la demonstration
                  // enseignant (EN-1b).
                  onAller: (String chemin) {
                    final int i = destinations.indexWhere(
                      (Destination d) => d.chemin == chemin,
                    );
                    if (i == -1) return;
                    context.go(
                      adresseDemoEnseignant(EcranDemoEnseignant.values[i]),
                    );
                  },
                  child: const ComptePage(),
                ),
        ),
      ),
    );
  }
}
