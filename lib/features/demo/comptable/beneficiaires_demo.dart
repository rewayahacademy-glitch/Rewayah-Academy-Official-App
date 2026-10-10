// La demonstration des beneficiaires, de la relance et de « Recevoir mes
// paiements » (CPT-BR-06, 11, 16). Posee vide par CPT-F, remplie par la voie
// CPT-BEN (CPT-BEN-1, CPT-BEN-2 ; `20_comptable/02_DECOUPAGE.md`, liste B).
//
// Spec §44 tenue ici : les 15 enseignants et les 5 contractuels du socle,
// **2 infos manquantes** (`ens-03` sans methode, `ens-07` incomplet),
// **1 methode modifiee recemment** (`ens-01`, 1er octobre), **1 externe
// « Invitation envoyee »** (`ctr-05`), plus une methode en verification
// (`ens-05`) et des paiements suspendus (`ens-11`). La relance ouvre le fil
// metier « Profil de paiement » des Messages de demonstration (CPT-COM,
// CPT-BR-11) : un message n'y est « Envoye » que sur l'accuse du port de
// demonstration, et l'externe n'a pas de fil ; aucune coordonnee reelle :
// les suffixes sont fictifs, l'app ne voit jamais rien d'autre, et la saisie
// securisee rend un jeton opaque de demonstration.
//
// Hors production (K-09) : ces doubles ne sont branches que par
// `surchargesDemoBeneficiaires`, lue par la demonstration Comptable.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/capacites/port_mes_moyens_paiement.dart';
import '../../../core/communications/capacites_communication.dart';
import '../../../core/communications/port_brouillons.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../com_messages/port_messages_metier.dart';
import '../communications/com_messages_demo.dart' show MessagesMetierDemo;
import 'socle_comptable_demo.dart';

/// Les profils de demonstration, construits a partir des personnes du socle.
abstract final class ProfilsBeneficiairesDemo {
  /// Le beneficiaire sans aucune methode (infos manquantes).
  static const String sansMethode = 'ens-03';

  /// Le beneficiaire a la methode incomplete (infos manquantes).
  static const String incomplet = 'ens-07';

  /// Le beneficiaire dont la methode vient d'etre modifiee (§21.4).
  static const String modifieRecemment = 'ens-01';

  /// Le beneficiaire dont la nouvelle methode est en verification.
  static const String enVerification = 'ens-05';

  /// Le beneficiaire aux paiements suspendus.
  static const String suspendu = 'ens-11';

  /// Le contractuel externe sans compte (§18).
  static const String externe = 'ctr-05';

  /// Les actions ouvertes a un profil avec compte et methode.
  static const PermissionsFinance _completes = PermissionsFinance(
    actions: <ActionFinance>{
      ActionFinance.relancer,
      ActionFinance.demanderMiseAJour,
      ActionFinance.suspendre,
    },
  );

  static DestinationMasquee _mobile(
    String suffixe,
    EtatProfilPaiement verification, {
    DateTime? modifiee,
  }) => DestinationMasquee(
    type: SocleComptableDemo.destinationMobile.type,
    operateur: SocleComptableDemo.destinationMobile.operateur,
    suffixe: suffixe,
    pays: SocleComptableDemo.destinationMobile.pays,
    devise: SocleComptableDemo.destinationMobile.devise,
    verification: verification,
    derniereModification: modifiee,
  );

  static DestinationMasquee _banque(
    String suffixe,
    EtatProfilPaiement verification, {
    DateTime? modifiee,
  }) => DestinationMasquee(
    type: SocleComptableDemo.destinationBanque.type,
    suffixe: suffixe,
    pays: SocleComptableDemo.destinationBanque.pays,
    devise: SocleComptableDemo.destinationBanque.devise,
    verification: verification,
    derniereModification: modifiee,
  );

  /// L'historique de demonstration : trois mois verses.
  static List<PaiementPasse> _historique(String id, int dollars) =>
      <PaiementPasse>[
        for (int mois = 9; mois >= 7; mois--)
          PaiementPasse(
            obligationId: 'obl-$id-2026-${mois.toString().padLeft(2, '0')}',
            date: DateTime(2026, mois, 28),
            periode: '${t.commun.dates.mois[mois - 1]} 2026',
            montant: SocleComptableDemo.usd(dollars),
            etat: EtatPaiementSortant.reussi,
            reference: 'DEMO-$id-$mois',
          ),
      ];

  /// Tous les profils, dans l'ordre du socle : enseignants puis contractuels.
  static List<ProfilPaiementBeneficiaire> tous() {
    final List<ProfilPaiementBeneficiaire> profils =
        <ProfilPaiementBeneficiaire>[];
    final List<IdentiteBeneficiaire> personnes = <IdentiteBeneficiaire>[
      ...SocleComptableDemo.enseignants,
      ...SocleComptableDemo.contractuels,
    ];
    for (int i = 0; i < personnes.length; i++) {
      final IdentiteBeneficiaire p = personnes[i];
      // Un suffixe fictif par personne, quatre chiffres.
      final String suffixe = (1000 + (i * 379) % 9000).toString();
      profils.add(switch (p.id) {
        modifieRecemment => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.verifie,
          destination: _mobile(
            SocleComptableDemo.destinationMobile.suffixe,
            EtatProfilPaiement.verifie,
            modifiee: DateTime(2026, 10, 1),
          ),
          derniereModification: DateTime(2026, 10, 1),
          capacite: CapacitePayout.prisEnCharge,
          historique: _historique(p.id, 205),
          permissions: _completes,
          obligationsEnAttente: 1,
        ),
        sansMethode => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.aucunMoyen,
          permissions: const PermissionsFinance(
            actions: <ActionFinance>{ActionFinance.relancer},
          ),
          obligationsEnAttente: 1,
        ),
        incomplet => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.incomplet,
          destination: _mobile(suffixe, EtatProfilPaiement.incomplet),
          derniereModification: DateTime(2026, 9, 12),
          permissions: const PermissionsFinance(
            actions: <ActionFinance>{
              ActionFinance.relancer,
              ActionFinance.demanderMiseAJour,
            },
          ),
          obligationsEnAttente: 1,
          historique: _historique(p.id, 180),
        ),
        enVerification => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.enVerification,
          destination: _banque(
            suffixe,
            EtatProfilPaiement.enVerification,
            modifiee: DateTime(2026, 10, 3),
          ),
          derniereModification: DateTime(2026, 10, 3),
          capacite: CapacitePayout.verificationRequise,
          permissions: const PermissionsFinance(
            actions: <ActionFinance>{
              ActionFinance.relancer,
              ActionFinance.suspendre,
            },
          ),
          obligationsEnAttente: 1,
          historique: _historique(p.id, 190),
        ),
        suspendu => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.suspendu,
          destination: _mobile(suffixe, EtatProfilPaiement.verifie),
          derniereModification: DateTime(2026, 8, 20),
          capacite: CapacitePayout.prisEnCharge,
          permissions: const PermissionsFinance(
            actions: <ActionFinance>{
              ActionFinance.relancer,
              ActionFinance.suspendre,
            },
          ),
          historique: _historique(p.id, 160),
        ),
        // Externe sans compte : aucune relance par fil, l'invitation se
        // renvoie depuis son obligation (CPT-BR-08, DR-16).
        externe => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.invitationEnvoyee,
          obligationsEnAttente: 1,
        ),
        _ => ProfilPaiementBeneficiaire(
          identite: p,
          etat: EtatProfilPaiement.verifie,
          destination: i.isEven
              ? _mobile(suffixe, EtatProfilPaiement.verifie)
              : _banque(suffixe, EtatProfilPaiement.verifie),
          derniereModification: DateTime(2026, 6, 1 + i),
          capacite: i.isEven
              ? CapacitePayout.prisEnCharge
              : CapacitePayout.temporairementIndisponible,
          historique: _historique(p.id, 150 + 5 * i),
          permissions: _completes,
          obligationsEnAttente: i < SocleComptableDemo.enseignants.length
              ? 1
              : 0,
        ),
      });
    }
    return profils;
  }
}

/// Les beneficiaires en demonstration. **Sans etat** : chaque action rend le
/// profil tel qu'il serait apres elle, et la page le garde (le serveur, plus
/// tard, le garde pour de bon).
class BeneficiairesPaiementDemo implements PortBeneficiairesPaiement {
  /// Cree le double.
  const BeneficiairesPaiementDemo();

  ProfilPaiementBeneficiaire _trouver(String beneficiaireId) =>
      ProfilsBeneficiairesDemo.tous().firstWhere(
        (ProfilPaiementBeneficiaire p) => p.identite.id == beneficiaireId,
        orElse: () => throw StateError('beneficiaire inconnu'),
      );

  static ProfilPaiementBeneficiaire _avec(
    ProfilPaiementBeneficiaire p, {
    required EtatProfilPaiement etat,
    required PermissionsFinance permissions,
  }) => ProfilPaiementBeneficiaire(
    identite: p.identite,
    etat: etat,
    destination: p.destination,
    derniereModification: p.derniereModification,
    capacite: p.capacite,
    historique: p.historique,
    permissions: permissions,
    obligationsEnAttente: p.obligationsEnAttente,
  );

  @override
  Future<List<ProfilPaiementBeneficiaire>> liste(
    FiltreBeneficiaires filtre,
  ) async => <ProfilPaiementBeneficiaire>[
    for (final ProfilPaiementBeneficiaire p in ProfilsBeneficiairesDemo.tous())
      if ((filtre.etat == null || p.etat == filtre.etat) &&
          (filtre.type == null || p.identite.type == filtre.type))
        p,
  ];

  @override
  Future<ProfilPaiementBeneficiaire> profil(String beneficiaireId) async =>
      _trouver(beneficiaireId);

  @override
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(
    String beneficiaireId,
  ) async {
    final ProfilPaiementBeneficiaire p = _trouver(beneficiaireId);
    return _avec(
      p,
      etat: EtatProfilPaiement.actionRequise,
      permissions: PermissionsFinance(
        actions: <ActionFinance>{
          for (final ActionFinance a in p.permissions.actions)
            if (a != ActionFinance.demanderMiseAJour) a,
        },
      ),
    );
  }

  @override
  Future<ProfilPaiementBeneficiaire> suspendre({
    required String beneficiaireId,
    required String motif,
  }) async {
    final ProfilPaiementBeneficiaire p = _trouver(beneficiaireId);
    return _avec(
      p,
      etat: EtatProfilPaiement.suspendu,
      permissions: p.permissions,
    );
  }

  @override
  Future<ProfilPaiementBeneficiaire> reprendre(String beneficiaireId) async {
    final ProfilPaiementBeneficiaire p = _trouver(beneficiaireId);
    return _avec(
      p,
      etat: p.destination?.verification ?? EtatProfilPaiement.aucunMoyen,
      permissions: p.permissions,
    );
  }

  @override
  Future<ProfilPaiementBeneficiaire> marquerVerificationRequise(
    String beneficiaireId,
  ) async {
    final ProfilPaiementBeneficiaire p = _trouver(beneficiaireId);
    return _avec(
      p,
      etat: EtatProfilPaiement.enVerification,
      permissions: p.permissions,
    );
  }

  @override
  Future<List<EntreeJournal>> journal(String beneficiaireId) async {
    final ProfilPaiementBeneficiaire p = _trouver(beneficiaireId);
    final DateTime? modifiee = p.derniereModification;
    if (modifiee == null) return const <EntreeJournal>[];
    return <EntreeJournal>[
      EntreeJournal(
        id: 'jrn-$beneficiaireId-2',
        date: DateTime(modifiee.year, modifiee.month, modifiee.day + 1),
        initiateur: t.comptable.commun.prestataireDemonstration(
          nom: SocleComptableDemo.prestataires.first.nom,
        ),
        objet: t.comptable.beneficiaires.profilTitre,
        ancienEtat: libelleProfilPaiement(EtatProfilPaiement.enVerification),
        nouvelEtat: libelleProfilPaiement(p.etat),
      ),
      EntreeJournal(
        id: 'jrn-$beneficiaireId-1',
        date: modifiee,
        initiateur: p.identite.nom,
        objet: t.comptable.beneficiaires.profilTitre,
        ancienEtat: libelleProfilPaiement(EtatProfilPaiement.verifie),
        nouvelEtat: libelleProfilPaiement(EtatProfilPaiement.enVerification),
      ),
    ];
  }
}

/// Les fils « Profil de paiement » que la relance peut ouvrir (CPT-COM) :
/// un par beneficiaire qui a un compte Rewayah. L'externe sans compte n'en a
/// pas (CPT-BR-08 : « Renvoyer l'invitation » reste son seul recours).
/// L'objet se nomme « Profil de paiement » seul : l'interlocuteur est deja
/// nomme en tete du fil, le repeter allongeait la ligne compacte a 320 en
/// texte x2 (revue CPT-COM).
List<ConversationPossible> conversationsProfilPaiementDemo() =>
    <ConversationPossible>[
      for (final IdentiteBeneficiaire b in <IdentiteBeneficiaire>[
        ...SocleComptableDemo.enseignants,
        ...SocleComptableDemo.contractuels,
      ])
        if (b.id != ProfilsBeneficiairesDemo.externe)
          ConversationPossible(
            interlocuteur: Participant(id: b.id, nomAffiche: b.nom),
            objet: ObjetLie(
              type: TypeObjetLie.profilPaiement,
              id: b.id,
              libelle: t.comptable.beneficiaires.profilTitre,
            ),
          ),
    ];

/// « Recevoir mes paiements » du Comptable de demonstration (§20) : une
/// mise a jour demandee sur sa methode, donc la notice §27.1. **Avec etat**
/// (une instance par demonstration) : ajouter, remplacer, supprimer et
/// choisir la preferee se suivent comme chez le prestataire, sans aucune
/// coordonnee.
class MesMoyensPaiementDemo implements PortMesMoyensPaiement {
  /// Cree le double, parti de [depart] (par defaut, [etatDepart]).
  MesMoyensPaiementDemo({EtatMesMoyensPaiement? depart})
    : _etat = depart ?? etatDepart;

  /// Les types de methode proposes en demonstration.
  static const List<String> types = <String>['Mobile money', 'Compte bancaire'];

  /// L'etat de depart de la demonstration.
  static const EtatMesMoyensPaiement etatDepart = EtatMesMoyensPaiement(
    etat: EtatProfilPaiement.actionRequise,
    moyens: <MoyenPaiementPersonnel>[
      MoyenPaiementPersonnel(
        id: 'moy-1',
        preferee: true,
        destination: DestinationMasquee(
          type: 'Mobile money',
          operateur: 'Operateur A',
          suffixe: '2718',
          pays: 'GN',
          devise: 'GNF',
          verification: EtatProfilPaiement.actionRequise,
        ),
      ),
    ],
    corridorsProposes: types,
  );

  /// Un etat sans aucune methode (notice §27.1, R-FIN-19).
  static const EtatMesMoyensPaiement aucun = EtatMesMoyensPaiement(
    etat: EtatProfilPaiement.aucunMoyen,
    corridorsProposes: types,
  );

  EtatMesMoyensPaiement _etat;
  int _suivant = 2;

  EtatMesMoyensPaiement _poser(
    List<MoyenPaiementPersonnel> moyens, {
    bool verification = false,
  }) {
    final List<MoyenPaiementPersonnel> actifs = moyens
        .where((MoyenPaiementPersonnel m) => m.active)
        .toList(growable: false);
    final EtatProfilPaiement etat = actifs.isEmpty
        ? EtatProfilPaiement.aucunMoyen
        : verification
        ? EtatProfilPaiement.enVerification
        : actifs
              .firstWhere(
                (MoyenPaiementPersonnel m) => m.preferee,
                orElse: () => actifs.first,
              )
              .destination
              .verification;
    _etat = EtatMesMoyensPaiement(
      etat: etat,
      moyens: moyens,
      payoutSuspenduTemporairement: etat == EtatProfilPaiement.enVerification,
      corridorsProposes: _etat.corridorsProposes,
    );
    return _etat;
  }

  MoyenPaiementPersonnel _nouveau(BrouillonMoyenPaiement b, bool preferee) {
    final String id = 'moy-${_suivant++}';
    return MoyenPaiementPersonnel(
      id: id,
      preferee: preferee,
      destination: DestinationMasquee(
        type: b.type,
        operateur: b.operateur,
        // Un suffixe fictif tire du compteur : le jeton ne contient aucune
        // coordonnee, la demonstration n'en a donc aucune a masquer.
        suffixe: (5000 + _suivant * 211).toString(),
        pays: b.pays,
        devise: b.devise,
        verification: EtatProfilPaiement.enVerification,
        derniereModification: SocleComptableDemo.aujourdhui,
      ),
    );
  }

  @override
  Future<EtatMesMoyensPaiement> etat() async => _etat;

  @override
  Future<SaisieSecurisee> ouvrirSaisieSecurisee(String type) async {
    final bool banque = type == SocleComptableDemo.destinationBanque.type;
    final DestinationMasquee modele = banque
        ? SocleComptableDemo.destinationBanque
        : SocleComptableDemo.destinationMobile;
    return SaisieSecurisee(
      jeton: 'jeton-demo-$_suivant',
      pays: modele.pays,
      devise: modele.devise,
      operateur: modele.operateur,
    );
  }

  @override
  Future<EtatMesMoyensPaiement> ajouter(
    BrouillonMoyenPaiement brouillon,
  ) async {
    final bool premiere = _etat.moyens.every(
      (MoyenPaiementPersonnel m) => !m.active,
    );
    final bool preferee = premiere || brouillon.preferee;
    return _poser(<MoyenPaiementPersonnel>[
      for (final MoyenPaiementPersonnel m in _etat.moyens)
        MoyenPaiementPersonnel(
          id: m.id,
          destination: m.destination,
          preferee: !preferee && m.preferee,
          active: m.active,
        ),
      _nouveau(brouillon, preferee),
    ], verification: true);
  }

  @override
  Future<EtatMesMoyensPaiement> remplacer({
    required String moyenId,
    required BrouillonMoyenPaiement brouillon,
  }) async {
    final MoyenPaiementPersonnel? ancien = _etat.moyens
        .where((MoyenPaiementPersonnel m) => m.id == moyenId)
        .firstOrNull;
    // L'ancienne methode est conservee inactive (§19, « selon regle » : la
    // regle de la demonstration est de la conserver).
    return _poser(<MoyenPaiementPersonnel>[
      for (final MoyenPaiementPersonnel m in _etat.moyens)
        if (m.id == moyenId)
          MoyenPaiementPersonnel(
            id: m.id,
            destination: m.destination,
            preferee: false,
            active: false,
          )
        else
          m,
      _nouveau(brouillon, ancien?.preferee ?? false),
    ], verification: true);
  }

  @override
  Future<EtatMesMoyensPaiement> supprimer(String moyenId) async {
    final List<MoyenPaiementPersonnel> restants = <MoyenPaiementPersonnel>[
      for (final MoyenPaiementPersonnel m in _etat.moyens)
        if (m.id != moyenId) m,
    ];
    final bool sansPreferee = restants.every(
      (MoyenPaiementPersonnel m) => !m.preferee || !m.active,
    );
    final int premiereActive = restants.indexWhere(
      (MoyenPaiementPersonnel m) => m.active,
    );
    return _poser(<MoyenPaiementPersonnel>[
      for (int i = 0; i < restants.length; i++)
        MoyenPaiementPersonnel(
          id: restants[i].id,
          destination: restants[i].destination,
          preferee:
              restants[i].preferee || (sansPreferee && i == premiereActive),
          active: restants[i].active,
        ),
    ]);
  }

  @override
  Future<EtatMesMoyensPaiement> choisirPreferee(String moyenId) async =>
      _poser(<MoyenPaiementPersonnel>[
        for (final MoyenPaiementPersonnel m in _etat.moyens)
          MoyenPaiementPersonnel(
            id: m.id,
            destination: m.destination,
            preferee: m.id == moyenId,
            active: m.active,
          ),
      ]);

  @override
  Future<List<EntreeJournal>> journal() async => <EntreeJournal>[
    EntreeJournal(
      id: 'jrn-moi-1',
      date: DateTime(2026, 10, 2),
      initiateur: t.comptable.commun.prestataireDemonstration(
        nom: SocleComptableDemo.prestataires.first.nom,
      ),
      objet: t.comptable.beneficiaires.recevoir.mesMethodes,
      ancienEtat: libelleProfilPaiement(EtatProfilPaiement.verifie),
      nouvelEtat: libelleProfilPaiement(EtatProfilPaiement.actionRequise),
    ),
  ];
}

/// L'etat des fils de la demonstration Comptable : UNE session pour toute
/// la demonstration, car chaque ecran monte sa propre portee
/// (`CoquilleComptableDemo`). Le message modele prerempli par « Relancer »
/// sur le profil doit se retrouver dans le champ du fil, et un message
/// envoye dans le fil doit y etre encore quand on y revient (CPT-COM). En
/// memoire du processus seulement, hors production (K-09) ;
/// [reinitialiserDemoBeneficiaires] repart d'une session vierge.
final class SessionFilsDemoBeneficiaires {
  SessionFilsDemoBeneficiaires._();

  /// Les brouillons des fils (dont le message modele prerempli).
  final BrouillonsMemoire brouillons = BrouillonsMemoire();

  /// Les Messages metier : le fil « Profil de paiement » cree a la demande.
  final MessagesMetierDemo messages = MessagesMetierDemo.surObjets(
    aOuvrir: conversationsProfilPaiementDemo(),
  );
}

SessionFilsDemoBeneficiaires? _session;

/// La session en cours des fils de la demonstration Comptable.
SessionFilsDemoBeneficiaires get sessionFilsDemoBeneficiaires =>
    _session ??= SessionFilsDemoBeneficiaires._();

/// Repart d'une session vierge : aucun brouillon, aucun fil ouvert. Les
/// tests l'appellent avant chaque parcours, pour qu'aucun n'herite des
/// brouillons ou des messages d'un autre.
void reinitialiserDemoBeneficiaires() => _session = null;

/// Les surcharges de la demonstration des beneficiaires.
List<Override> surchargesDemoBeneficiaires() => <Override>[
  portBeneficiairesPaiementProvider.overrideWithValue(
    const BeneficiairesPaiementDemo(),
  ),
  // CPT-COM : la relance ouvre le fil metier « Profil de paiement » des
  // Messages de demonstration, ecriture ouverte (COM-BR-16), hors production.
  portMessagesMetierProvider.overrideWithValue(
    sessionFilsDemoBeneficiaires.messages,
  ),
  portBrouillonsProvider.overrideWithValue(
    sessionFilsDemoBeneficiaires.brouillons,
  ),
  capacitesCommunicationProvider.overrideWith(
    (Ref _) => const CapacitesCommunicationsFixes(<CapaciteCommunication>{
      CapaciteCommunication.ecrireDansFil,
    }).capacites(),
  ),
  portMesMoyensPaiementProvider.overrideWithValue(MesMoyensPaiementDemo()),
];
