/// PARCOURS-BOUT-EN-BOUT (directeur, 22/11/2026 : « une visuelle qui montre les
/// etapes par lesquelles l'inscription passe, comme les etapes du programme »).
///
/// La frise complete de l'inscription, de la demande a l'enseignant affecte :
/// demande envoyee, lue par la direction, acceptee (ou « a completer » quand la
/// direction demande une precision), puis les etapes de la classe deja
/// existantes (`FriseAttente`) : classe en formation, classe confirmee,
/// enseignant affecte, tout est pret.
///
/// **Uniquement des etats fournis par le serveur** : `ma_demande_admission`
/// (etat, issue, precisions, dates). Aucun signal serveur ne dit « la direction
/// a ouvert la demande » : l'etape « Lue par la direction » est donc « en
/// cours » tant que la direction n'a rien decide, et « faite » des qu'elle a
/// demande une precision. Les etapes de la classe ne se franchissent qu'apres
/// l'acceptation : avant, elles sont « a venir », ce qui est vrai.
///
/// Meme ligne que la frise de la classe ([LigneFrise]) : marqueur a icone et
/// mot d'etat (jamais la couleur seule), une seule carte mise en avant, aucune
/// barre qui avance seule. Les dates se lisent a l'heure de la personne avec le
/// nom de son fuseau, puis l'heure de La Mecque.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/attente_classe/modele_attente.dart' show EtatEtapeAttente;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/quand_avec_fuseau.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../dossier/apprenants_demande.dart';
import 'frise_attente.dart' show LigneFrise;
import 'libelles_attente.dart' show libelleEtatEtape;

/// Les sept etapes, dans l'ordre.
enum CleEtapeInscription {
  /// La demande est partie.
  envoyee,

  /// La direction la lit.
  lue,

  /// La direction decide : acceptee, ou a completer.
  decision,

  /// La classe se forme.
  formation,

  /// La classe est confirmee.
  confirmee,

  /// L'enseignant est affecte.
  enseignant,

  /// Tout est pret.
  pret,
}

/// Une etape de la frise de l'inscription.
class EtapeInscription {
  /// Cree l'etape.
  const EtapeInscription({
    required this.cle,
    required this.etat,
    this.quand,
    this.precision = false,
  });

  /// Laquelle.
  final CleEtapeInscription cle;

  /// Son etat, tel que le serveur l'a rendu.
  final EtatEtapeAttente etat;

  /// Quand elle a ete franchie (instant UTC), si le serveur le dit.
  final DateTime? quand;

  /// Vrai pour l'etape de decision quand la direction demande une precision.
  final bool precision;
}

/// Le nombre d'etapes de la frise de l'inscription.
const int nombreEtapesInscription = 7;

/// Les etapes d'une demande **en cours ou a completer** (une demande refusee a
/// son propre ecran, sans frise). Pur : ne calcule rien que le serveur n'ait
/// rendu.
List<EtapeInscription> etapesInscription({
  required IssueDemandeFamille issue,
  DatesAdmission? dates,
}) {
  final bool aCompleter = issue == IssueDemandeFamille.aCompleter;
  return <EtapeInscription>[
    EtapeInscription(
      cle: CleEtapeInscription.envoyee,
      etat: EtatEtapeAttente.fait,
      quand: dates?.recueLe,
    ),
    EtapeInscription(
      cle: CleEtapeInscription.lue,
      etat: aCompleter ? EtatEtapeAttente.fait : EtatEtapeAttente.enCours,
      quand: aCompleter ? dates?.decisionLe : null,
    ),
    EtapeInscription(
      cle: CleEtapeInscription.decision,
      etat: aCompleter ? EtatEtapeAttente.enCours : EtatEtapeAttente.aVenir,
      precision: aCompleter,
    ),
    for (final CleEtapeInscription c in <CleEtapeInscription>[
      CleEtapeInscription.formation,
      CleEtapeInscription.confirmee,
      CleEtapeInscription.enseignant,
      CleEtapeInscription.pret,
    ])
      EtapeInscription(cle: c, etat: EtatEtapeAttente.aVenir),
  ];
}

String _nom(EtapeInscription e) {
  final n = t.friseInscription.etapes;
  return switch (e.cle) {
    CleEtapeInscription.envoyee => n.envoyee,
    CleEtapeInscription.lue => n.lue,
    CleEtapeInscription.decision => e.precision ? n.aCompleter : n.acceptee,
    CleEtapeInscription.formation => n.formation,
    CleEtapeInscription.confirmee => n.confirmee,
    CleEtapeInscription.enseignant => n.enseignant,
    CleEtapeInscription.pret => n.pret,
  };
}

String? _dit(EtapeInscription e) {
  final d = t.friseInscription.dit;
  final a = t.suiviAttente.dit;
  return switch (e.cle) {
    CleEtapeInscription.envoyee => d.envoyee,
    CleEtapeInscription.lue =>
      e.etat == EtatEtapeAttente.fait ? d.lueFait : d.lueEnCours,
    CleEtapeInscription.decision =>
      e.precision ? d.aCompleter : d.accepteeAVenir,
    CleEtapeInscription.formation => a.formationAVenir,
    CleEtapeInscription.confirmee => a.confirmeeAVenir,
    CleEtapeInscription.enseignant => a.enseignantAVenir,
    CleEtapeInscription.pret => a.pretAVenir,
  };
}

/// La frise, rendue a partir des etapes. Aucune lecture : voir
/// [BlocFriseInscription].
class FriseInscription extends StatelessWidget {
  /// Cree la frise.
  const FriseInscription({required this.etapes, super.key});

  /// Les etapes.
  final List<EtapeInscription> etapes;

  /// La cle de la ligne de l'etape [cle].
  static Key cleEtape(CleEtapeInscription cle) =>
      ValueKey<String>('inscription-etape-${cle.name}');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor secondaire = palette.encreSecondaireSur(
      palette.surfaceCanvas,
    );
    return Column(
      key: const ValueKey<String>('inscription-frise'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, EtapeInscription e) in etapes.indexed)
          _Ligne(
            key: cleEtape(e.cle),
            numero: i + 1,
            etape: e,
            derniere: i == etapes.length - 1,
            palette: palette,
            textes: textes,
            secondaire: secondaire,
          ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.numero,
    required this.etape,
    required this.derniere,
    required this.palette,
    required this.textes,
    required this.secondaire,
    super.key,
  });

  final int numero;
  final EtapeInscription etape;
  final bool derniere;
  final AppPalette palette;
  final TextTheme textes;
  final AppInkColor secondaire;

  @override
  Widget build(BuildContext context) {
    final bool enCours = etape.etat == EtatEtapeAttente.enCours;
    final bool aVenir = etape.etat == EtatEtapeAttente.aVenir;
    final String nom = _nom(etape);
    final String? dit = _dit(etape);
    final DateTime? quand = etape.quand;
    final String? date = quand == null ? null : quandAvecFuseau(quand);
    final TextStyle titre = (enCours ? palette.inkAccent : palette.inkStrong)
        .applyTo(
          (enCours ? textes.titleMedium : textes.titleSmall) ??
              const TextStyle(),
        )
        .copyWith(
          color: aVenir ? secondaire.applyTo(const TextStyle()).color : null,
        );
    final TextStyle detail = secondaire.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle corps = (aVenir ? secondaire : palette.inkStrong).applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(nom, style: titre),
        Text(libelleEtatEtape(etape.etat), style: detail),
        if (date != null)
          Text(
            date,
            key: ValueKey<String>('inscription-date-${etape.cle.name}'),
            style: detail,
          ),
        if (dit != null) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            dit,
            key: ValueKey<String>('inscription-dit-${etape.cle.name}'),
            style: corps,
          ),
        ],
      ],
    );
    return LigneFrise(
      etat: etape.etat,
      derniere: derniere,
      cleMarqueur: ValueKey<String>(
        'inscription-marqueur-${etape.cle.name}-${etape.etat.name}',
      ),
      etiquette: <String>[
        t.friseInscription.etapeSurTotal(
          n: numero,
          total: nombreEtapesInscription,
          etape: nom,
        ),
        libelleEtatEtape(etape.etat),
        ?date,
        ?dit,
      ].join(', '),
      child: enCours
          ? AppCard(
              key: ValueKey<String>('inscription-en-cours-${etape.cle.name}'),
              surface: palette.washAccent,
              child: contenu,
            )
          : contenu,
    );
  }
}

/// La frise de l'inscription avec ses cinq etats : chargement, contenu, vide
/// (aucune demande lue), erreur, hors ligne. Lit `ma_demande_admission` ; une
/// demande refusee n'a pas de frise (son ecran le dit).
class BlocFriseInscription extends ConsumerWidget {
  /// Cree le bloc.
  const BlocFriseInscription({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    void relire() => ref
      ..invalidate(demandeFamilleProvider)
      ..invalidate(datesAdmissionProvider);
    final AsyncValue<DemandeFamille?> demande = ref.watch(
      demandeFamilleProvider,
    );
    final DatesAdmission? dates = ref.watch(datesAdmissionProvider).value;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.friseInscription.titre, style: textes.titleLarge),
        Ecart.vXs,
        Text(t.friseInscription.contexte, style: textes.bodyMedium),
        Ecart.vLg,
        BlocAsynchrone<DemandeFamille?>(
          key: const ValueKey<String>('inscription-bloc'),
          valeur: demande,
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: relire,
          estVide: (DemandeFamille? d) => d == null,
          vide: EmptyState(
            key: const ValueKey<String>('inscription-vide'),
            message: t.friseInscription.vide,
            icone: AppIcons.creneaux,
            registre: RegistreVide.subi,
          ),
          erreurVersEtat: (Object _, VoidCallback? reessayer) => horsLigne
              ? EtatSansDonnees(
                  key: const ValueKey<String>('inscription-sans-donnees'),
                  quoi: t.friseInscription.sansDonnees,
                  onAction: reessayer,
                )
              : EtatSysteme(
                  key: const ValueKey<String>('inscription-erreur'),
                  nature: NatureEtat.echecServeur,
                  phrase: t.friseInscription.erreur,
                  onAction: reessayer,
                ),
          construire: (DemandeFamille? d) {
            if (d == null || d.issue == IssueDemandeFamille.refusee) {
              return const SizedBox.shrink();
            }
            return FriseInscription(
              etapes: etapesInscription(issue: d.issue, dates: dates),
            );
          },
        ),
      ],
    );
  }
}
