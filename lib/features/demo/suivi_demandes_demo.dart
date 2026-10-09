// OFFRES-FAM-1 : l'adaptateur de demonstration du suivi des demandes de
// creneau, et les notifications de ses transitions. Rien ne quitte
// l'appareil (K-28).
//
// Il simule ce que le serveur fera (ligne Backend OFFRES-FAM-1) :
// - l'etape de chaque demande et ses transitions, diffusees a la famille ;
// - ce que le serveur SAIT et ne rend PAS : le nombre d'autres demandeurs du
//   meme regroupement et l'enseignant propose avant sa confirmation. Ces
//   donnees vivent ici pour que les tests prouvent qu'elles ne sortent
//   jamais du port ;
// - les heures en heure murale du fuseau du foyer.
import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/capacites/port_notifications.dart';
import '../../core/offres/port_suivi_demandes.dart';
import '../../core/router/routes.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart';
import 'mode_demonstration.dart' show DonneesDemo;

/// Une demande telle que le serveur simule la connait.
class DemandeServeurDemo {
  /// Cree la demande, a l'etape [etape].
  DemandeServeurDemo({
    required this.demandeId,
    required this.eleveId,
    required this.prenom,
    required this.creneau,
    required this.etape,
    required this.transitions,
    this.fuseauIana = 'Europe/Paris',
    this.personnalise = false,
    this.autresDemandeurs = 0,
    this.enseignant,
    this.debutCours,
    this.motif,
    this.peutChoisirAutreCreneau = false,
  });

  /// L'identifiant.
  final String demandeId;

  /// L'eleve.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Les jours et l'heure choisis.
  final CreneauDemande creneau;

  /// Le fuseau du foyer.
  final String fuseauIana;

  /// Creneau personnalise.
  final bool personnalise;

  /// Donnee serveur seulement : les autres eleves du regroupement.
  int autresDemandeurs;

  /// Donnee serveur : l'enseignant propose, puis confirme.
  String? enseignant;

  /// L'etape atteinte.
  EtapeDemande etape;

  /// Chaque transition atteinte et son instant.
  final List<(EtapeDemande, DateTime)> transitions;

  /// Le debut des cours, heure murale du foyer.
  DateTime? debutCours;

  /// Le motif d'une demande close.
  MotifCloture? motif;

  /// Capacite de rechoisir.
  bool peutChoisirAutreCreneau;

  /// Ce que le port rend a la famille.
  SuiviDemande versFamille() => SuiviDemande(
    demandeId: demandeId,
    eleveId: eleveId,
    prenom: prenom,
    etape: etape,
    creneau: creneau,
    fuseauIana: fuseauIana,
    personnalise: personnalise,
    enseignant: enseignant,
    debutCours: debutCours,
    motif: motif,
    peutChoisirAutreCreneau: peutChoisirAutreCreneau,
  );
}

/// Le port de demonstration : une liste de demandes et leurs transitions.
class SuiviDemandesDemo implements PortSuiviDemandes {
  /// Cree le port sur [demandes]. [echec] : la lecture echoue.
  SuiviDemandesDemo(this.demandes, {this.echec = false});

  /// Le foyer de demonstration : Yusuf a demande un creneau personnalise
  /// (etape 1), Aicha a sa classe et son enseignante (etape 3).
  factory SuiviDemandesDemo.demonstration() => SuiviDemandesDemo(
    <DemandeServeurDemo>[demandeYusufEnvoyee(), demandeAichaAffectee()],
  );

  /// Les quatre etapes, une par eleve.
  factory SuiviDemandesDemo.quatreEtapes() =>
      SuiviDemandesDemo(<DemandeServeurDemo>[
        demandeYusufEnvoyee(),
        DemandeServeurDemo(
          demandeId: 'demo-demande-ines',
          eleveId: 'demo-eleve-ines',
          prenom: 'Inès',
          creneau: const CreneauDemande(
            joursIso: <int>[6, 7],
            heure: 10,
            minute: 0,
          ),
          etape: EtapeDemande.classeValidee,
          transitions: <(EtapeDemande, DateTime)>[
            (EtapeDemande.envoyee, DateTime(2026, 10, 3, 9, 12)),
            (EtapeDemande.classeValidee, DateTime(2026, 10, 7, 14)),
          ],
          autresDemandeurs: 5,
          // Propose par le systeme, pas encore confirme : jamais rendu.
          enseignant: 'Sayyida Khadija',
        ),
        demandeAichaAffectee(),
        DemandeServeurDemo(
          demandeId: 'demo-demande-bilal',
          eleveId: 'demo-eleve-bilal',
          prenom: 'Bilal',
          creneau: const CreneauDemande(
            joursIso: <int>[3],
            heure: 19,
            minute: 30,
          ),
          etape: EtapeDemande.close,
          transitions: <(EtapeDemande, DateTime)>[
            (EtapeDemande.envoyee, DateTime(2026, 9, 28, 20, 5)),
            (EtapeDemande.close, DateTime(2026, 10, 6, 11)),
          ],
          motif: MotifCloture.offreRetiree,
          peutChoisirAutreCreneau: true,
        ),
      ]);

  /// Yusuf : creneau personnalise, en attente du quota.
  static DemandeServeurDemo demandeYusufEnvoyee() => DemandeServeurDemo(
    demandeId: 'demo-demande-yusuf',
    eleveId: DonneesDemo.yusufId,
    prenom: 'Yusuf',
    creneau: const CreneauDemande(
      joursIso: <int>[4, 1, 2],
      heure: 18,
      minute: 0,
    ),
    etape: EtapeDemande.envoyee,
    transitions: <(EtapeDemande, DateTime)>[
      (EtapeDemande.envoyee, DateTime(2026, 10, 8, 19, 40)),
    ],
    personnalise: true,
    autresDemandeurs: 3,
  );

  /// Aicha : classe validee, enseignante affectee, debut fixe.
  static DemandeServeurDemo demandeAichaAffectee() => DemandeServeurDemo(
    demandeId: 'demo-demande-aicha',
    eleveId: DonneesDemo.aichaId,
    prenom: 'Aïcha',
    creneau: const CreneauDemande(joursIso: <int>[1, 3], heure: 17, minute: 30),
    etape: EtapeDemande.enseignantAffecte,
    transitions: <(EtapeDemande, DateTime)>[
      (EtapeDemande.envoyee, DateTime(2026, 9, 30, 18, 2)),
      (EtapeDemande.classeValidee, DateTime(2026, 10, 2, 10)),
      (EtapeDemande.enseignantAffecte, DateTime(2026, 10, 5, 16, 30)),
    ],
    autresDemandeurs: 4,
    enseignant: 'Sayyida Maryam',
    debutCours: DateTime(2026, 10, 19, 17, 30),
  );

  /// Les demandes du serveur simule.
  final List<DemandeServeurDemo> demandes;

  /// Vrai : la lecture echoue (serveur muet).
  final bool echec;

  final StreamController<void> _changements =
      StreamController<void>.broadcast();

  /// Fait passer [demandeId] a l'etape [etape], le [quand] donne.
  void avancer(
    String demandeId,
    EtapeDemande etape,
    DateTime quand, {
    MotifCloture? motif,
    DateTime? debutCours,
  }) {
    final DemandeServeurDemo d = demandes.firstWhere(
      (DemandeServeurDemo e) => e.demandeId == demandeId,
    );
    d
      ..etape = etape
      ..motif = motif ?? d.motif
      ..debutCours = debutCours ?? d.debutCours
      ..transitions.add((etape, quand));
    _changements.add(null);
  }

  List<SuiviDemande> _lire() => <SuiviDemande>[
    for (final DemandeServeurDemo d in demandes) d.versFamille(),
  ];

  @override
  Stream<List<SuiviDemande>> suivre() async* {
    if (echec) {
      throw StateError('serveur');
    }
    yield _lire();
    await for (final void _ in _changements.stream) {
      yield _lire();
    }
  }
}

/// Les notifications de chaque transition des demandes simulees : une par
/// etape atteinte, la plus recente d'abord, vers l'ecran de suivi.
///
/// Le port des notifications n'a pas de type : une notification est un titre
/// deja redige et une destination. Ce titre vient de
/// [titreNotificationDemande], comme la carte du suivi.
class NotificationsSuiviDemandesDemo implements PortNotifications {
  /// Cree les notifications de [suivi].
  const NotificationsSuiviDemandesDemo(this.suivi);

  /// Le suivi simule.
  final SuiviDemandesDemo suivi;

  @override
  Future<List<NotificationTuteur>> liste() async {
    final List<NotificationTuteur> toutes =
        <NotificationTuteur>[
          for (final DemandeServeurDemo d in suivi.demandes)
            for (final (EtapeDemande etape, DateTime quand) in d.transitions)
              NotificationTuteur(
                id: '${d.demandeId}-${etape.name}',
                titre: titreNotificationDemande(
                  SuiviDemande(
                    demandeId: d.demandeId,
                    eleveId: d.eleveId,
                    prenom: d.prenom,
                    etape: etape,
                    creneau: d.creneau,
                    fuseauIana: d.fuseauIana,
                    motif: d.motif,
                  ),
                ),
                date: quand,
                destination: Routes.tuteurDemandes,
              ),
        ]..sort(
          (NotificationTuteur a, NotificationTuteur b) =>
              b.date.compareTo(a.date),
        );
    return toutes;
  }

  @override
  Future<NotificationTuteur?> detail(String id) async {
    for (final NotificationTuteur n in await liste()) {
      if (n.id == id) return n;
    }
    return null;
  }
}

/// Les surcharges du suivi des demandes pour la demonstration tuteur.
List<Override> surchargesSuiviDemandesDemo() {
  final SuiviDemandesDemo suivi = SuiviDemandesDemo.demonstration();
  return <Override>[
    portSuiviDemandesProvider.overrideWithValue(suivi),
    portNotificationsProvider.overrideWithValue(
      NotificationsSuiviDemandesDemo(suivi),
    ),
  ];
}
