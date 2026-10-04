import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_accents_profils.dart';
import '../../../core/capacites/port_paiements_foyer.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/mouvements_profil.dart';
import '../../../core/finance/politique_commerciale.dart';
import '../../../core/finance/suivi_paiement.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/avatar_tile.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/identite_profil.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/ligne_allocation.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/ligne_transaction.dart';
import '../../../core/widgets/menu_filtre.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import '../fiche_eleve_page.dart';
import '../ligne_membre.dart' show dateEcheance;
import '../photo_eleve.dart';

/// Les mouvements d'un profil, relus a chaque ouverture (FI-BR-05) : libere
/// des que la page se ferme (`autoDispose`), pour qu'apres une recharge
/// l'historique rouvert porte le nouveau mouvement, jamais l'ancienne liste.
final FutureProviderFamily<List<MouvementProfil>, String>
mouvementsProfilProvider = FutureProvider.autoDispose
    .family<List<MouvementProfil>, String>(
      (Ref ref, String profilId) =>
          ref.watch(portPaiementsFoyerProvider).mouvements(profilId),
    );

/// Les mouvements d'un profil eleve (`/tuteur/foyer/:eleveId/mouvements`,
/// FI-6b ; guide Finance V4 §4, §5.2 ; maquettes 05 et 06).
///
/// Une liste de `LigneTransaction` sur telephone, un tableau (date, libelle,
/// montant, statut, recu) sur bureau : jamais une colonne mobile etiree. Le
/// montant est **toujours signe**, jamais dit par la couleur seule. Le
/// filtre « par personne » mene aux mouvements d'un autre profil du foyer.
/// Le recu s'ouvre en surface de lecture et ne reprend que ce que la source
/// rend (date, reference, moyen, montant, repartition).
///
/// **Historique en ajout seul** (guide §5.7) : aucune action de suppression
/// ni d'edition, aucun bouton plein. Etats : chargement, contenu, vide,
/// erreur, hors ligne, et production (`CapaciteIndisponible`).
class MouvementsElevePage extends ConsumerWidget {
  /// Cree la page.
  const MouvementsElevePage({required this.eleveId, super.key});

  /// L'eleve concerne : un identifiant de chemin, jamais une autorisation.
  final String eleveId;

  /// Le filtre par personne.
  static const Key filtreKey = Key('ficheEleve.mouvements.filtre');

  /// La liste (telephone).
  static const Key listeKey = Key('ficheEleve.mouvements.liste');

  /// Le tableau (bureau).
  static const Key tableauKey = Key('ficheEleve.mouvements.tableau');

  /// Le recu ouvert.
  static const Key recuKey = Key('ficheEleve.mouvements.recu');

  /// Le lien « Voir le recu » du mouvement [id].
  static Key voirRecuKey(String id) => Key('ficheEleve.mouvements.recu.$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.mouvements.titre,
      onRetour: () =>
          GoRouter.of(context)
              .go(Routes.ficheEleveSousPage(eleveId, 'finances')),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _CorpsMouvements(profil: profil),
    );
  }
}

/// Le libelle d'un mouvement, selon sa nature rendue.
String libelleMouvement(MouvementProfil m) => switch (m.nature) {
  NatureMouvement.recharge => t.ficheEleve.mouvements.nature.recharge,
  NatureMouvement.debitPeriode => switch (m.periode) {
    final DateTime p => t.ficheEleve.mouvements.nature.mensualiteDe(
      mois: t.commun.dates.mois[p.month - 1],
      annee: p.year.toString(),
    ),
    null => t.ficheEleve.mouvements.nature.mensualite,
  },
  NatureMouvement.avoir => t.ficheEleve.mouvements.nature.avoir,
  NatureMouvement.remise => t.ficheEleve.mouvements.nature.remise,
  NatureMouvement.taxe => t.ficheEleve.mouvements.nature.taxe,
};

/// L'icone du type d'un mouvement (guide §5.2, revue 5 b) : decorative, le
/// libelle dit deja le type ; la couleur n'y porte rien.
AppIcon iconeMouvement(NatureMouvement nature) => switch (nature) {
  NatureMouvement.recharge => AppIcons.ajouter,
  NatureMouvement.debitPeriode => AppIcons.creneaux,
  NatureMouvement.avoir || NatureMouvement.remise => AppIcons.finance,
  NatureMouvement.taxe => AppIcons.info,
};

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

/// La date d'un mouvement avec son heure locale : « 1 octobre 2026 à
/// 09:30 » (guide §5.2, revue 5 b). Jamais le jour seul : deux recharges du
/// meme jour se distinguent.
String dateHeureMouvement(DateTime date) {
  final DateTime locale = date.toLocal();
  return t.ficheEleve.mouvements.dateHeure(
    date: dateEcheance(locale),
    heure: t.ficheEleve.mouvements.heureChiffres(
      heures: _deuxChiffres(locale.hour),
      minutes: _deuxChiffres(locale.minute),
    ),
  );
}

/// Le statut d'un mouvement, en texte.
String libelleStatut(StatutMouvement s) => switch (s) {
  StatutMouvement.enregistre => t.ficheEleve.mouvements.statut.enregistre,
  StatutMouvement.enConfirmation =>
    t.ficheEleve.mouvements.statut.enConfirmation,
};

/// Le moyen de paiement d'un recu, `null` pour un rail jamais montre au
/// lancement (FI10) : la ligne n'apparait pas.
String? _libelleRail(RailPaiement rail) => switch (rail) {
  RailPaiement.webStripe => t.argent.moyen.webStripe,
  RailPaiement.iosStoreKit || RailPaiement.androidPlay => null,
};

class _CorpsMouvements extends ConsumerWidget {
  const _CorpsMouvements({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HistoriqueMouvements(
    lecture: ref.watch(mouvementsProfilProvider(profil.eleveId)),
    onRelire: () => ref.invalidate(mouvementsProfilProvider(profil.eleveId)),
    textes: (
      contexte: t.ficheEleve.mouvements.contexte(prenom: profil.prenom),
      indisponibleTitre: t.ficheEleve.mouvements.indisponibleTitre,
      indisponiblePhrase: t.ficheEleve.mouvements.indisponiblePhrase(
        prenom: profil.prenom,
      ),
      erreurTitre: t.ficheEleve.mouvements.erreurTitre(prenom: profil.prenom),
      videTitre: t.ficheEleve.mouvements.videTitre,
      videPhrase: t.ficheEleve.mouvements.videPhrase(prenom: profil.prenom),
    ),
    filtre: _FiltrePersonne(profil: profil),
  );
}

/// Les textes de l'historique, selon qui le lit : le tuteur (le prenom du
/// profil) ou l'eleve adulte (FI-9b, « vos »).
typedef TextesHistoriqueMouvements = ({
  String contexte,
  String indisponibleTitre,
  String indisponiblePhrase,
  String erreurTitre,
  String videTitre,
  String videPhrase,
});

/// L'historique des mouvements d'un profil (FI-6b, repris par FI-9b) : la
/// phrase de contexte (K-58), le filtre eventuel, puis la liste (telephone)
/// ou le tableau (bureau), et les etats : chargement, contenu, vide, erreur,
/// hors ligne, production (`CapaciteIndisponible`).
class HistoriqueMouvements extends ConsumerWidget {
  /// Cree l'historique.
  const HistoriqueMouvements({
    required this.lecture,
    required this.onRelire,
    required this.textes,
    super.key,
    this.filtre,
  });

  /// Les mouvements lus.
  final AsyncValue<List<MouvementProfil>> lecture;

  /// Relit la source.
  final VoidCallback onRelire;

  /// Les textes de la page et de ses etats.
  final TextesHistoriqueMouvements textes;

  /// Le filtre par personne ; `null` : aucun (l'eleve adulte n'a que son
  /// profil).
  final Widget? filtre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: PorteeEtat.page,
        titre: textes.indisponibleTitre,
        phrase: textes.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    } else if (erreur != null) {
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: onRelire)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: textes.erreurTitre,
              onAction: onRelire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 4);
    } else if (lecture.requireValue.isEmpty) {
      corps = EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: textes.videTitre,
        phrase: textes.videPhrase,
      );
    } else {
      final List<MouvementProfil> mouvements = lecture.requireValue;
      corps = AppGabarit.de(context) == Gabarit.desktop
          ? _Tableau(mouvements: mouvements)
          : _Liste(mouvements: mouvements);
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textesTheme = Theme.of(context).textTheme;
    final Widget? choix = filtre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // K-58 : une phrase de contexte d'abord.
        Text(
          textes.contexte,
          style: palette.inkMuted.applyTo(
            textesTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        if (choix != null) ...<Widget>[choix, Ecart.vLg],
        corps,
      ],
    );
  }
}

/// Le filtre « par personne » : un autre profil du foyer, dont on ouvre les
/// mouvements. Absent quand le foyer n'a qu'un profil.
class _FiltrePersonne extends ConsumerWidget {
  const _FiltrePersonne({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProfilEleveFoyer>> lecture = ref.watch(
      profilsElevesFoyerProvider,
    );
    final List<ProfilEleveFoyer> profils = lecture.hasValue && !lecture.hasError
        ? lecture.requireValue
        : <ProfilEleveFoyer>[profil];
    if (profils.length < 2) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MenuFiltre<String>(
        key: MouvementsElevePage.filtreKey,
        libelle: t.ficheEleve.mouvements.personne,
        valeur: profil.eleveId,
        entrees: <EntreeFiltre<String>>[
          for (final ProfilEleveFoyer p in profils)
            EntreeFiltre<String>(
              valeur: p.eleveId,
              libelle: p.prenom,
              // Guide §3.4 : la personne se reconnait a son portrait.
              avatar: PhotoEleve(
                prenom: p.prenom,
                cleAvatar: p.cleAvatar,
                diametre: AppAvatar.petit,
              ),
              enveloppeAvatar: BandeauProfil.enveloppe(
                diametre: AppAvatar.petit,
                accent: accentLu(ref.watch(accentsProfilsProvider), p.eleveId),
              ),
            ),
        ],
        onChoix: (String? id) {
          if (id == null || id == profil.eleveId) return;
          GoRouter.of(context).go(Routes.ficheEleveSousPage(id, 'mouvements'));
        },
      ),
    );
  }
}

/// La pastille d'un mouvement en confirmation ; rien pour un mouvement
/// enregistre, l'etat normal (E12).
Widget? _pastille(MouvementProfil m) => switch (m.statut) {
  StatutMouvement.enConfirmation => StatusPill(
    libelle: libelleStatut(m.statut),
    ton: TonEtat.accent,
  ),
  StatutMouvement.enregistre => null,
};

/// Le recu de [m], s'il peut se montrer : seul un mouvement enregistre en a
/// un. En confirmation, rien n'est encore credite (FI9) : un recu le ferait
/// lire comme un paiement reussi (guide §5.4).
RecuPaiement? _recuMontrable(MouvementProfil m) => switch (m.statut) {
  StatutMouvement.enregistre => m.recu,
  StatutMouvement.enConfirmation => null,
};

/// Ouvre le recu de [m] en surface de lecture.
Future<void> _ouvrirRecu(BuildContext context, RecuPaiement recu) =>
    AppBottomSheet.ouvrirLecture<void>(
      context,
      titre: t.ficheEleve.mouvements.recu.titre,
      sousTitre: recu.reference,
      libelleFermer: t.ficheEleve.mouvements.recu.fermer,
      constructeur: (BuildContext _) => _ContenuRecu(recu: recu),
    );

/// Le lien « Voir le recu » d'un mouvement qui en a un.
Widget _lienRecu(BuildContext context, MouvementProfil m, RecuPaiement recu) =>
    LienFleche(
      key: MouvementsElevePage.voirRecuKey(m.id),
      libelle: t.ficheEleve.mouvements.voirRecu,
      libelleSemantique: t.ficheEleve.mouvements.voirRecuSemantique(
        reference: recu.reference,
      ),
      onPress: () => _ouvrirRecu(context, recu),
    );

/// Telephone : une seule carte a lignes fines (contenus lies, K-55).
class _Liste extends StatelessWidget {
  const _Liste({required this.mouvements});

  final List<MouvementProfil> mouvements;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: MouvementsElevePage.listeKey,
    child: CarteGroupee(
      sections: <Widget>[
        for (final MouvementProfil m in mouvements)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LigneTransaction(
                icone: iconeMouvement(m.nature),
                libelle: libelleMouvement(m),
                date: dateHeureMouvement(m.date),
                montant: m.montant,
                statut: _pastille(m),
              ),
              if (_recuMontrable(m) case final RecuPaiement recu)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _lienRecu(context, m, recu),
                ),
            ],
          ),
      ],
    ),
  );
}

/// Bureau : un tableau dans une seule carte, une ligne par mouvement.
class _Tableau extends StatelessWidget {
  const _Tableau({required this.mouvements});

  final List<MouvementProfil> mouvements;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle entete = palette.inkMuted.applyTo(
      textes.labelLarge ?? const TextStyle(),
    );
    final TextStyle cellule = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle chiffres = AppTypography.tabulaire(cellule);
    return KeyedSubtree(
      key: MouvementsElevePage.tableauKey,
      child: CarteGroupee(
        sections: <Widget>[
          Semantics(
            header: true,
            child: _LigneTableau(
              date: Text(t.ficheEleve.mouvements.colonne.date, style: entete),
              libelle: Text(
                t.ficheEleve.mouvements.colonne.libelle,
                style: entete,
              ),
              montant: Text(
                t.ficheEleve.mouvements.colonne.montant,
                style: entete,
                textAlign: TextAlign.end,
              ),
              statut: Text(
                t.ficheEleve.mouvements.colonne.statut,
                style: entete,
              ),
              recu: Text(t.ficheEleve.mouvements.colonne.recu, style: entete),
            ),
          ),
          for (final MouvementProfil m in mouvements)
            _LigneTableau(
              date: Text(dateHeureMouvement(m.date), style: chiffres),
              libelle: Row(
                children: <Widget>[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                      child: Icon(iconeMouvement(m.nature).repos),
                    ),
                  ),
                  Ecart.hSm,
                  Expanded(child: Text(libelleMouvement(m), style: cellule)),
                ],
              ),
              montant: Text(
                formaterMontant(m.montant, signe: true),
                style: chiffres,
                textAlign: TextAlign.end,
              ),
              statut: Align(
                alignment: AlignmentDirectional.centerStart,
                child:
                    _pastille(m) ??
                    Text(libelleStatut(m.statut), style: cellule),
              ),
              recu: switch (_recuMontrable(m)) {
                final RecuPaiement recu => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _lienRecu(context, m, recu),
                ),
                null => const SizedBox.shrink(),
              },
            ),
        ],
      ),
    );
  }
}

/// Une ligne du tableau : cinq colonnes de parts fixes.
class _LigneTableau extends StatelessWidget {
  const _LigneTableau({
    required this.date,
    required this.libelle,
    required this.montant,
    required this.statut,
    required this.recu,
  });

  final Widget date;
  final Widget libelle;
  final Widget montant;
  final Widget statut;
  final Widget recu;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(flex: 2, child: date),
      Ecart.hLg,
      Expanded(flex: 3, child: libelle),
      Ecart.hLg,
      Expanded(flex: 2, child: montant),
      Ecart.hXxl,
      Expanded(flex: 2, child: statut),
      Ecart.hLg,
      Expanded(flex: 2, child: recu),
    ],
  );
}

/// Le recu : rien d'autre que ce que la source rend.
class _ContenuRecu extends ConsumerWidget {
  const _ContenuRecu({required this.recu});

  final RecuPaiement recu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? moyen = _libelleRail(recu.rail);
    return SingleChildScrollView(
      key: MouvementsElevePage.recuKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: t.ficheEleve.mouvements.recu.date,
            valeur: dateEcheance(recu.date),
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: t.ficheEleve.mouvements.recu.reference,
            valeur: recu.reference,
            chiffres: true,
            valeurEnFin: true,
          ),
          if (moyen != null)
            LigneCleValeur(
              cle: t.ficheEleve.mouvements.recu.moyen,
              valeur: moyen,
              valeurEnFin: true,
            ),
          LigneCleValeur(
            cle: t.ficheEleve.mouvements.recu.montant,
            valeur: formaterMontant(recu.total),
            chiffres: true,
            valeurEnFin: true,
          ),
          if (recu.allocations.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            Semantics(
              header: true,
              child: Text(
                t.ficheEleve.mouvements.recu.repartition,
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            for (final AllocationProfil a in recu.allocations)
              LigneAllocation(
                prenom: a.prenom,
                montant: a.montant,
                avatar: BandeauProfil(
                  avatar: AvatarTile(
                    prenom: a.prenom,
                    diametre: AppAvatar.moyen,
                  ),
                  diametre: AppAvatar.moyen,
                  accent: accentLu(
                    ref.watch(accentsProfilsProvider),
                    a.profilId,
                  ),
                  // Le bandeau remonte dans la marge de la ligne, le cercle
                  // reste en haut : rien ne depasse la ligne, et le prenom
                  // s'aligne sur le cercle, pas sur le bandeau (R2-08).
                  remontee: LigneCleValeur.margeVerticale,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
