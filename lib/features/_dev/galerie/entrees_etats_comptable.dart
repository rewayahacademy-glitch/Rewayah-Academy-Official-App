import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/comptable/visibilite_montants.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/comptable/carte_reserve_strategique.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/comptable/pourcentage_sensible.dart';
import '../../../core/widgets/comptable/resume_tresorerie.dart';
import '../../../core/widgets/ligne_destination_masquee.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import 'catalogue_galerie.dart';

/// Les entrees de galerie des composants partages du Comptable V1 (CPT-F,
/// spec §7, §16.3 ; DR-06) : le masque des montants, la destination masquee,
/// la famille des pastilles de statut, et les trois composants du dossier
/// `lib/core/widgets/comptable/` (Reserve, activite, synthese de tresorerie).
///
/// Inscrits par CPT-RC (revue CPT-R, M2 et m1). Dans un fichier a part du
/// catalogue, comme les entrees du Tuteur V1 : ces composants arrivent
/// ensemble et le catalogue n'a qu'une ligne a changer.
///
/// Les composants qui lisent la visibilite des montants sont rendus sous une
/// `ProviderScope` qui fixe l'etat (masques ou affiches) : la galerie montre
/// les deux sans dependre d'une session.
List<EntreeGalerie> entreesEtatsComptable() => <EntreeGalerie>[
  EntreeGalerie(
    nom: 'BasculeMontants',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'masques, avec le mot d etat',
        (BuildContext _) =>
            _visibilite(affiches: false, const BasculeMontants(avecEtat: true)),
      ),
      EtatGalerie(
        'affiches, avec le mot d etat',
        (BuildContext _) =>
            _visibilite(affiches: true, const BasculeMontants(avecEtat: true)),
      ),
      EtatGalerie(
        'etroit, sans libelle (bouton seul)',
        (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(320, 640)),
          child: _visibilite(
            affiches: false,
            const BasculeMontants(avecEtat: true),
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'MontantSensible',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'masque (par defaut)',
        (BuildContext _) => _visibilite(
          affiches: false,
          const MontantSensible(Montant(1250000, 'USD')),
        ),
      ),
      EtatGalerie(
        'revele',
        (BuildContext _) => _visibilite(
          affiches: true,
          const MontantSensible(Montant(1250000, 'USD')),
        ),
      ),
      EtatGalerie(
        'grand, revele',
        (BuildContext _) => _visibilite(
          affiches: true,
          const MontantSensible(
            Montant(4875050, 'USD'),
            taille: TailleMontant.grand,
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'LigneDestinationMasquee',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'mobile money verifiee',
        (BuildContext _) => const LigneDestinationMasquee(
          destination: DestinationMasquee(
            type: 'Mobile money',
            operateur: 'Orange Money',
            suffixe: '4423',
            pays: 'SN',
            devise: 'XOF',
            verification: EtatProfilPaiement.verifie,
          ),
        ),
      ),
      EtatGalerie(
        'banque a verifier',
        (BuildContext _) => const LigneDestinationMasquee(
          destination: DestinationMasquee(
            type: 'Compte bancaire',
            suffixe: '1234',
            pays: 'FR',
            devise: 'EUR',
            verification: EtatProfilPaiement.enVerification,
          ),
        ),
      ),
      EtatGalerie(
        'sans destination',
        (BuildContext _) => const LigneDestinationMasquee(),
      ),
    ],
  ),
  // Une FAMILLE de neuf pastilles dans un seul fichier, inscrite sous le nom
  // du fichier (`pastilles_comptable.dart`) : l'exception inverse de
  // `GrilleSemaine` (un composant hors de lib/core/widgets). Un etat par
  // pastille, chacune dans un etat representatif ; les autres valeurs se
  // lisent dans `test/core/widgets/pastilles_comptable_test.dart`.
  EntreeGalerie(
    nom: 'PastillesComptable',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'paiement sortant : pret a payer',
        (BuildContext _) =>
            const PastillePaiementSortant(EtatPaiementSortant.pretAPayer),
      ),
      EtatGalerie(
        'encaissement : conteste',
        (BuildContext _) =>
            const PastilleEncaissement(EtatEncaissement.conteste),
      ),
      EtatGalerie(
        'rapprochement : conflit',
        (BuildContext _) =>
            const PastilleRapprochement(EtatRapprochement.conflit),
      ),
      EtatGalerie(
        'profil de paiement : informations a completer',
        (BuildContext _) =>
            const PastilleProfilPaiement(EtatProfilPaiement.incomplet),
      ),
      EtatGalerie(
        'capacite payout : temporairement indisponible',
        (BuildContext _) => const PastilleCapacitePayout(
          CapacitePayout.temporairementIndisponible,
        ),
      ),
      EtatGalerie(
        'reserve : sous objectif',
        (BuildContext _) => const PastilleEtatReserve(EtatReserve.sousObjectif),
      ),
      EtatGalerie(
        'obligation de contractuel : a approuver',
        (BuildContext _) => const PastilleObligationContractuel(
          EtatObligationContractuel.aApprouver,
        ),
      ),
      EtatGalerie(
        'remboursement : approbation requise',
        (BuildContext _) =>
            const PastilleRemboursement(EtatRemboursement.approbationRequise),
      ),
      EtatGalerie(
        'demande de validation : en attente',
        (BuildContext _) =>
            const PastilleDemandeValidation(EtatDemandeValidation.enAttente),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'CarteReserveStrategique',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'sous objectif, couverture en mois, masquee',
        (BuildContext _) => _visibilite(
          affiches: false,
          CarteReserveStrategique(_reserveSousObjectif, onOuvrir: _rien),
        ),
      ),
      EtatGalerie(
        'atteinte, montant fixe, revelee',
        (BuildContext _) => _visibilite(
          affiches: true,
          const CarteReserveStrategique(_reserveAtteinte),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'LigneActivite',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'avec montant et changement d etat, masque',
        (BuildContext _) =>
            _visibilite(affiches: false, LigneActivite(_journalPaiement)),
      ),
      EtatGalerie(
        'sans montant',
        (BuildContext _) =>
            _visibilite(affiches: false, LigneActivite(_journalProfil)),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'PourcentageSensible',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'masque avec les montants (par defaut)',
        (BuildContext _) => _visibilite(
          affiches: false,
          PourcentageSensible(
            valeur: '82',
            gabarit: (String v) => t.comptable.commun.atteint(pourcent: v),
          ),
        ),
      ),
      EtatGalerie(
        'revele',
        (BuildContext _) => _visibilite(
          affiches: true,
          PourcentageSensible(
            valeur: '82',
            gabarit: (String v) => t.comptable.commun.atteint(pourcent: v),
          ),
        ),
      ),
    ],
  ),
  EntreeGalerie(
    nom: 'ResumeTresorerie',
    famille: FamilleComposant.composantEtat,
    etats: <EtatGalerie>[
      EtatGalerie(
        'masquee (par defaut)',
        (BuildContext _) =>
            _visibilite(affiches: false, const ResumeTresorerie(_synthese)),
      ),
      EtatGalerie(
        'revelee',
        (BuildContext _) =>
            _visibilite(affiches: true, const ResumeTresorerie(_synthese)),
      ),
    ],
  ),
];

void _rien() {}

/// Rend [enfant] sous une visibilite des montants fixee.
Widget _visibilite(Widget enfant, {required bool affiches}) => ProviderScope(
  overrides: <Override>[
    visibiliteMontantsProvider.overrideWith(() => _VisibiliteFixe(affiches)),
  ],
  child: enfant,
);

class _VisibiliteFixe extends VisibiliteMontants {
  _VisibiliteFixe(this._affiches);

  final bool _affiches;

  @override
  bool build() => _affiches;
}

const SyntheseTresorerie _synthese = SyntheseTresorerie(
  detenue: Montant(4875050, 'USD'),
  libre: Montant(1820000, 'USD'),
  protegee: Montant(2955050, 'USD'),
  enTransit: Montant(100000, 'USD'),
);

final IndicateursReserve _reserveSousObjectif = IndicateursReserve(
  mode: ModeObjectifReserve.couvertureMois,
  nombreMois: 3,
  objectif: const Montant(1800000, 'USD'),
  actuel: const Montant(1476000, 'USD'),
  manque: const Montant(324000, 'USD'),
  atteintPourMille: 820,
  etat: EtatReserve.sousObjectif,
  derniereAllocation: DateTime(2026, 9, 30),
  prochaineAllocation: DateTime(2026, 10, 31),
);

const IndicateursReserve _reserveAtteinte = IndicateursReserve(
  mode: ModeObjectifReserve.montantFixe,
  objectif: Montant(1000, 'USD'),
  actuel: Montant(1000, 'USD'),
  manque: Montant(0, 'USD'),
  atteintPourMille: 1000,
  etat: EtatReserve.atteint,
);

final EntreeJournal _journalPaiement = EntreeJournal(
  id: 'j-1',
  date: DateTime(2026, 10, 3, 9, 30),
  initiateur: 'Comptable',
  objet: 'Paiement de septembre',
  ancienEtat: 'Prêt à payer',
  nouvelEtat: 'Soumis',
  montant: const Montant(35000, 'USD'),
  reference: 'PAY-2026-0931',
);

final EntreeJournal _journalProfil = EntreeJournal(
  id: 'j-2',
  date: DateTime(2026, 10, 2, 14, 5),
  initiateur: 'La direction',
  objet: 'Profil de paiement vérifié',
);
