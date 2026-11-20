/// PRAXIS-VISIBLE (20/11/2026) : la page « Le travail de Praxis », sous
/// Personnes > Candidatures.
///
/// Le directeur voit enfin ce que son assistant fait : les objectifs que
/// Praxis se fixe, puis les dossiers qu'il a ranges (pile et raison) ou lus
/// (etiquette), filtrables par pile et par etiquette. Une ligne ouvre la page
/// du dossier (empilee, comme depuis la file), ou la carte « L'avis de Praxis »
/// montre l'avis entier ; le retour ramene ici, avec les memes filtres.
///
/// **L'adresse dit les filtres** (`?pile=pret_a_decider&etiquette=pepite`) : un
/// rechargement ou un lien rend le meme ecran ; un filtre change l'adresse par
/// `replace` (le retour ne rejoue pas les filtres un a un). Une valeur
/// inconnue est ignoree.
///
/// **Pourquoi une page et pas un filtre de la file** : la file est paginee au
/// serveur (`lister_candidatures`), qui ne connait ni la pile ni l'etiquette ;
/// filtrer une page de 50 a l'ecran mentirait sur le reste. Ici, tout vient de
/// `direction_praxis_rangements` et `direction_praxis_impressions`, lues en
/// entier ; les nombres par pile et par etiquette sont ceux du serveur.
///
/// Etats : chargement (squelette), contenu, vide, aucun resultat (« Effacer
/// les filtres »), erreur (« Reessayer »), hors ligne (bandeau de `PageShell`
/// et l'etat commun), refus du serveur (lecteur qui n'est pas la direction).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/agent/travail_praxis.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_praxis.dart';
import 'objectifs_praxis.dart';

/// Un dossier vu par Praxis : range, lu, ou les deux.
@immutable
class DossierVuParPraxis {
  /// Cree la ligne.
  const DossierVuParPraxis({
    required this.reference,
    required this.nom,
    this.rangement,
    this.impression,
  });

  /// La reference (`CAND-...`).
  final String reference;

  /// Le nom du candidat, tel que le serveur le rend.
  final String nom;

  /// Le rangement courant, ou `null`.
  final RangementPraxis? rangement;

  /// L'impression courante, ou `null`.
  final ImpressionPraxis? impression;

  /// Le dernier passage de Praxis sur ce dossier.
  DateTime get vuLe {
    final DateTime? a = rangement?.rangeLe;
    final DateTime? b = impression?.noteeLe;
    if (a == null) return b!;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}

/// Les dossiers vus par Praxis, du plus recent au plus ancien.
List<DossierVuParPraxis> dossiersVusParPraxis(
  List<RangementPraxis> rangements,
  List<ImpressionPraxis> impressions,
) {
  final Map<String, RangementPraxis> r = <String, RangementPraxis>{
    for (final RangementPraxis x in rangements) x.reference: x,
  };
  final Map<String, ImpressionPraxis> i = <String, ImpressionPraxis>{
    for (final ImpressionPraxis x in impressions) x.reference: x,
  };
  final List<DossierVuParPraxis> lignes =
      <DossierVuParPraxis>[
        for (final String ref in <String>{...r.keys, ...i.keys})
          DossierVuParPraxis(
            reference: ref,
            nom: (r[ref]?.nom.isNotEmpty ?? false)
                ? r[ref]!.nom
                : i[ref]?.nom ?? '',
            rangement: r[ref],
            impression: i[ref],
          ),
      ]..sort(
        (DossierVuParPraxis a, DossierVuParPraxis b) =>
            b.vuLe.compareTo(a.vuLe),
      );
  return lignes;
}

/// La page « Le travail de Praxis ».
class TravailPraxisPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const TravailPraxisPage({
    super.key,
    this.requete = const <String, String>{},
    this.ouvrirDossier,
  });

  /// Les parametres de l'adresse (`pile`, `etiquette`).
  final Map<String, String> requete;

  /// Ouvre la page du dossier [reference], ou `null` : la ligne ne s'ouvre pas.
  final void Function(String reference)? ouvrirDossier;

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('travail-praxis-page');

  /// La pastille du filtre par pile [pile].
  static Key clePile(PilePraxis pile) =>
      ValueKey<String>('travail-praxis-filtre-pile-${pile.sql}');

  /// Le menu du filtre par etiquette.
  static const Key cleEtiquette = ValueKey<String>(
    'travail-praxis-filtre-etiquette',
  );

  /// La liste des dossiers.
  static const Key cleListe = ValueKey<String>('travail-praxis-liste');

  /// La ligne d'un dossier.
  static Key cleLigne(String reference) =>
      ValueKey<String>('travail-praxis-ligne-$reference');

  /// Aucun dossier vu.
  static const Key cleVide = ValueKey<String>('travail-praxis-vide');

  /// Aucun dossier pour ces filtres.
  static const Key cleAucunResultat = ValueKey<String>(
    'travail-praxis-aucun-resultat',
  );

  /// L'erreur, le hors ligne ou le refus.
  static const Key cleErreur = ValueKey<String>('travail-praxis-erreur');

  /// Le squelette.
  static const Key cleChargement = ValueKey<String>(
    'travail-praxis-chargement',
  );

  /// « Afficher les dossiers suivants ».
  static const Key cleVoirPlus = ValueKey<String>('travail-praxis-voir-plus');

  /// Le nombre de lignes affichees d'un coup.
  static const int parTranche = 50;

  @override
  ConsumerState<TravailPraxisPage> createState() => _TravailPraxisPageEtat();
}

class _TravailPraxisPageEtat extends ConsumerState<TravailPraxisPage> {
  int _visibles = TravailPraxisPage.parTranche;

  PilePraxis? get _pile => PilePraxis.depuisSql(widget.requete['pile']);

  EtiquettePraxis? get _etiquette =>
      EtiquettePraxis.depuisSql(widget.requete['etiquette']);

  /// Reporte les filtres dans l'adresse, par `replace`. Hors routeur (tests
  /// montes sans GoRouter), rien a faire.
  void _filtrer({
    required PilePraxis? pile,
    required EtiquettePraxis? etiquette,
  }) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur == null) return;
    final Map<String, String> requete = <String, String>{
      for (final MapEntry<String, String> e in widget.requete.entries)
        if (e.key != 'pile' && e.key != 'etiquette') e.key: e.value,
      'pile': ?pile?.sql,
      'etiquette': ?etiquette?.sql,
    };
    unawaited(
      routeur.replace<void>(Routes.adminPersonnesTravailPraxisPour(requete)),
    );
  }

  void _relire() {
    ref
      ..invalidate(rangementsPraxisProvider)
      ..invalidate(impressionsPraxisProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tr = t.admin.praxis.travail;
    final TextStyle attenue = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    return PageShell(
      key: TravailPraxisPage.clePage,
      titre: tr.titre,
      // Le retour ramene d'ou l'on vient (la file, filtres gardes) ; sans
      // pile (lien ouvert directement, rechargement), la file.
      onRetour: () {
        final GoRouter routeur = GoRouter.of(context);
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.adminPersonnesCandidatures);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Largeur de lecture : sur un ecran d'ordinateur, ces deux phrases
          // ne s'etirent pas sur toute la page (garde du bureau, regle B4).
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurLecture,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TexteSansCoupure(tr.intro, style: attenue),
                  Ecart.vXs,
                  TexteSansCoupure(tr.rappel, style: attenue),
                ],
              ),
            ),
          ),
          Ecart.vXl,
          const ObjectifsPraxis(),
          Ecart.vXxl,
          SectionHeader(titre: tr.dossiers),
          Ecart.vSm,
          _dossiers(context),
        ],
      ),
    );
  }

  Widget _dossiers(BuildContext context) {
    final tr = t.admin.praxis.travail;
    final AsyncValue<PageRangements> rangements = ref.watch(
      rangementsPraxisProvider,
    );
    final AsyncValue<PageImpressions> impressions = ref.watch(
      impressionsPraxisProvider,
    );
    if (rangements.error is PermissionInsuffisante ||
        impressions.error is PermissionInsuffisante) {
      return EtatSysteme(
        key: TravailPraxisPage.cleErreur,
        nature: NatureEtat.permissionRefusee,
        phrase: tr.permission,
      );
    }
    if (rangements.hasError || impressions.hasError) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return KeyedSubtree(
        key: TravailPraxisPage.cleErreur,
        child: horsLigne
            ? EtatSansDonnees(quoi: tr.horsLigne, onAction: _relire)
            : EmptyState(
                message: tr.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: _relire,
              ),
      );
    }
    if (!rangements.hasValue || !impressions.hasValue) {
      return const Skeleton.liste(
        key: TravailPraxisPage.cleChargement,
        lignes: 4,
      );
    }
    final PageRangements r = rangements.requireValue;
    final PageImpressions i = impressions.requireValue;
    final List<DossierVuParPraxis> tous = dossiersVusParPraxis(
      r.lignes,
      i.lignes,
    );
    if (tous.isEmpty) {
      return EmptyState(
        key: TravailPraxisPage.cleVide,
        message: tr.vide,
        invitation: tr.videDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }
    final PilePraxis? pile = _pile;
    final EtiquettePraxis? etiquette = _etiquette;
    final List<DossierVuParPraxis> filtres = <DossierVuParPraxis>[
      for (final DossierVuParPraxis d in tous)
        if ((pile == null || d.rangement?.pile == pile) &&
            (etiquette == null || d.impression?.etiquette == etiquette))
          d,
    ];
    final List<DossierVuParPraxis> montres = filtres
        .take(_visibles)
        .toList(growable: false);
    final void Function(String)? ouvrir = widget.ouvrirDossier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RangeeFiltres(
          replier: false,
          filtres: <Widget>[
            // L'etiquette d'abord : au telephone, elle reste visible quand les
            // piles defilent.
            MenuFiltre<EtiquettePraxis>(
              key: TravailPraxisPage.cleEtiquette,
              libelle: tr.etiquette,
              valeur: etiquette,
              entrees: <EntreeFiltre<EtiquettePraxis>>[
                EntreeFiltre<EtiquettePraxis>(
                  valeur: null,
                  libelle: tr.toutesEtiquettes,
                ),
                for (final EtiquettePraxis e in EtiquettePraxis.values)
                  EntreeFiltre<EtiquettePraxis>(
                    valeur: e,
                    libelle: libelleEtiquette(e),
                    compteur: i.parEtiquette[e] ?? 0,
                  ),
              ],
              onChoix: (EtiquettePraxis? e) =>
                  _filtrer(pile: pile, etiquette: e),
            ),
            // Les quatre piles en pastilles, chacune avec son nombre (celui
            // du serveur) : tout se voit d'un coup d'oeil, un toucher filtre,
            // un second relache.
            for (final PilePraxis p in PilePraxis.values)
              FilterPill(
                key: TravailPraxisPage.clePile(p),
                libelle: libellePile(p),
                compteur: r.parPile[p] ?? 0,
                retenue: pile == p,
                onPress: () =>
                    _filtrer(pile: pile == p ? null : p, etiquette: etiquette),
              ),
          ],
        ),
        Ecart.vMd,
        TexteSansCoupure(
          tr.nombre(n: '${filtres.length}'),
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        if (filtres.isEmpty)
          EmptyState(
            key: TravailPraxisPage.cleAucunResultat,
            message: tr.aucunResultat,
            invitation: tr.aucunResultatDetail,
            icone: AppIcons.rienAAfficher,
            libelleAction: tr.effacer,
            onAction: () => _filtrer(pile: null, etiquette: null),
          )
        else
          DataCollection<DossierVuParPraxis>(
            key: TravailPraxisPage.cleListe,
            defileSeule: false,
            defileAvecLaPage: true,
            lignes: montres,
            cle: (DossierVuParPraxis d) =>
                TravailPraxisPage.cleLigne(d.reference),
            onSelectionner: ouvrir == null
                ? null
                : (DossierVuParPraxis d) => ouvrir(d.reference),
            piedDePage: filtres.length > montres.length
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: LienFleche(
                      key: TravailPraxisPage.cleVoirPlus,
                      libelle: tr.voirPlus,
                      alignerEnDebut: true,
                      onPress: () => setState(
                        () => _visibles += TravailPraxisPage.parTranche,
                      ),
                    ),
                  )
                : null,
            colonnes: _colonnes(),
          ),
      ],
    );
  }

  TextStyle _attenue(BuildContext context) =>
      AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle());

  List<ColonneDonnees<DossierVuParPraxis>> _colonnes() {
    final tr = t.admin.praxis.travail;
    String pile(DossierVuParPraxis d) =>
        d.rangement == null ? tr.pasRange : libellePile(d.rangement!.pile);
    String etiquette(DossierVuParPraxis d) => d.impression == null
        ? tr.pasLu
        : libelleEtiquette(d.impression!.etiquette);
    return <ColonneDonnees<DossierVuParPraxis>>[
      ColonneDonnees<DossierVuParPraxis>(
        titre: tr.colonneNom,
        role: RoleColonne.identifiante,
        flex: 3,
        texte: (DossierVuParPraxis d) => d.nom.isEmpty ? d.reference : d.nom,
      ),
      ColonneDonnees<DossierVuParPraxis>(
        titre: tr.colonnePile,
        flex: 2,
        texte: pile,
        rendu: (BuildContext context, DossierVuParPraxis d) =>
            d.rangement == null
            ? TexteSansCoupure(pile(d), style: _attenue(context))
            : StatusPill(libelle: pile(d), ton: tonPile(d.rangement!.pile)),
      ),
      ColonneDonnees<DossierVuParPraxis>(
        titre: tr.colonneEtiquette,
        flex: 2,
        texte: etiquette,
        rendu: (BuildContext context, DossierVuParPraxis d) =>
            d.impression == null
            ? TexteSansCoupure(etiquette(d), style: _attenue(context))
            : StatusPill(
                libelle: etiquette(d),
                ton: tonEtiquette(d.impression!.etiquette),
              ),
      ),
      ColonneDonnees<DossierVuParPraxis>(
        titre: tr.colonneRaison,
        role: RoleColonne.aPart,
        flex: 4,
        texte: (DossierVuParPraxis d) => d.rangement?.raison ?? '',
      ),
      ColonneDonnees<DossierVuParPraxis>(
        titre: tr.colonneDate,
        flex: 1,
        tabulaire: true,
        texte: (DossierVuParPraxis d) => jourPraxis(d.vuLe),
      ),
    ];
  }
}
