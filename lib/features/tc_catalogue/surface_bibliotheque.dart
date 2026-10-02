import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/port_catalogue.dart';
import '../../core/tc_bibliotheque/recherche_catalogue.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/tc_telechargement/port_etat_offline.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_ressource.dart';
import 'libelles_bibliotheque.dart';

/// Ce qu'un appelant fait d'une ressource choisie.
///
/// [position] est non nulle quand la recherche portait un repere -- « 2:255 »,
/// « 40 » -- et que la ressource l'accepte : on ouvre alors directement au bon
/// endroit plutot qu'au debut.
typedef ChoixRessource = void Function(
  LibraryResource ressource,
  ContentPosition? position,
);

/// La Bibliotheque, **la seule**.
///
/// Ce widget est le corps partage par l'ecran hors classe et par le
/// `ClassLibraryPicker`. Ce n'est pas une commodite : c'est la forme que prend
/// la decision D-20. Deux surfaces separees divergeraient en contenu, en etat
/// hors ligne et en droits, et personne ne le verrait avant la production.
///
/// Seul l'**ordre de decouverte** change selon [contexte] (spec sections 6.1
/// et 6.2), et cet ordre est decide dans `VueCatalogue.depuis`, hors de tout
/// widget.
///
/// **Aucune dependance a LiveKit, ni directe ni transitive.** Ce fichier
/// n'importe rien de `lib/core/video/` : c'est ce qui garantit qu'ouvrir la
/// Bibliotheque en classe ne peut pas toucher a la room. Un test le verifie en
/// relisant les imports du fichier.
///
/// La surface est un `CustomScrollView` : les cartes se construisent a la
/// demande. Un catalogue de plusieurs centaines de supports ne construit donc
/// que ce que l'ecran montre.
class SurfaceBibliotheque extends ConsumerStatefulWidget {
  /// Cree la surface.
  const SurfaceBibliotheque({
    required this.contexte,
    required this.onChoisir,
    super.key,
    this.groupeId,
    this.enTete,
  });

  /// Ou la Bibliotheque est ouverte.
  final ContexteDecouverte contexte;

  /// Le groupe dont on montre les ressources epinglees. `null` hors contexte
  /// de groupe : la section « Pour ce groupe » disparait alors, elle ne se
  /// remplit pas d'autre chose.
  final String? groupeId;

  /// Ce qui se passe quand une ressource est choisie.
  final ChoixRessource onChoisir;

  /// Un bandeau pose au-dessus de la recherche, propre a l'appelant.
  final Widget? enTete;

  @override
  ConsumerState<SurfaceBibliotheque> createState() => _SurfaceEtat();
}

class _SurfaceEtat extends ConsumerState<SurfaceBibliotheque> {
  final TextEditingController _recherche = TextEditingController();
  String _requete = '';
  FiltreCatalogue _filtre = const FiltreCatalogue();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DonneesCatalogue> donnees = ref.watch(
      donneesCatalogueProvider(widget.groupeId),
    );
    // L'etat du reseau vient de la source unique du produit. Ouvrir un second
    // abonnement `Connectivity` ferait diverger cette surface du bandeau
    // `OfflineBanner` pose juste au-dessus.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final DonneesCatalogue? valeur = donnees.value;

    final VueCatalogue vue = VueCatalogue.depuis(
      contexte: widget.contexte,
      tous: valeur?.tous ?? const <LibraryResource>[],
      recents: valeur?.recents ?? const <LibraryResource>[],
      pourGroupe: valeur?.pourGroupe ?? const <LibraryResource>[],
      etatsOffline: valeur?.etatsOffline ?? const <String, EtatOffline>{},
      reprise: valeur?.reprise,
      horsLigne: horsLigne,
      requete: _requete,
      filtre: _filtre,
      // Riverpod 3 relance un provider en echec tout seul : l'etat repasse par
      // `AsyncLoading` en conservant `hasError`. On lit donc `hasValue` et
      // `hasError`, jamais le type d'execution.
      chargement: !donnees.hasValue && !donnees.hasError,
      echec: donnees.hasError && !donnees.hasValue,
    );

    return CustomScrollView(
      slivers: <Widget>[
        if (widget.enTete != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: widget.enTete,
            ),
          ),
        SliverToBoxAdapter(child: _barre(context, vue)),
        ..._corps(context, vue),
        const SliverToBoxAdapter(child: Ecart.vSection),
      ],
    );
  }

  /// La recherche et les deux axes de filtre.
  ///
  /// Le type est un axe **ferme** -- cinq valeurs fixees par le contrat -- donc
  /// il se rend en pastilles. La disponibilite en est un aussi, mais elle se
  /// rend en menu : cinq pastilles de plus sur la meme ligne repousseraient la
  /// liste sous le pli sur un telephone, et c'est exactement le defaut que
  /// `MenuFiltre` a ete ecrit pour corriger.
  Widget _barre(BuildContext context, VueCatalogue vue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: t.tc.bibliotheque.rechercheLibelle,
          textField: true,
          child: TextField(
            controller: _recherche,
            onChanged: (String valeur) => setState(() => _requete = valeur),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: t.tc.bibliotheque.rechercheIndication,
              prefixIcon: Icon(AppIcons.recherche.repos),
            ),
          ),
        ),
        Ecart.vMd,
        // Une rangee qui defile cache des filtres hors de la vue (ONGLETS-1) :
        // les pastilles passent a la ligne, tout est visible.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final TypeRessource type in TypeRessource.values)
              FilterPill(
                libelle: libelleTypeRessource(type),
                retenue: _filtre.types?.contains(type) ?? false,
                onPress: () => _basculerType(type),
              ),
            MenuFiltre<EtatOffline>(
              libelle: t.tc.bibliotheque.filtre.disponibilite,
              valeur: _filtre.etatOffline,
              entrees: <EntreeFiltre<EtatOffline>>[
                EntreeFiltre<EtatOffline>(
                  valeur: null,
                  libelle: t.tc.bibliotheque.effacerRecherche,
                ),
                for (final EtatOffline e in EtatOffline.values)
                  EntreeFiltre<EtatOffline>(
                    valeur: e,
                    libelle: libelleOffline(e),
                  ),
              ],
              onChoix: (EtatOffline? valeur) => setState(() {
                _filtre = valeur == null
                    ? _filtre.avec(relacher: const <String>{'etatOffline'})
                    : _filtre.avec(etatOffline: valeur);
              }),
            ),
          ],
        ),
        Ecart.vLg,
      ],
    );
  }

  List<Widget> _corps(BuildContext context, VueCatalogue vue) {
    switch (vue.etat) {
      case EtatCatalogue.chargement:
        return const <Widget>[
          SliverToBoxAdapter(child: Skeleton.liste(lignes: 4)),
        ];
      case EtatCatalogue.indisponible:
        return <Widget>[
          SliverToBoxAdapter(
            child: EmptyState(
              message: t.tc.bibliotheque.indisponible.message,
              icone: AppIcons.avertissement,
              libelleAction: t.tc.bibliotheque.indisponible.action,
              onAction: () =>
                  ref.invalidate(donneesCatalogueProvider(widget.groupeId)),
            ),
          ),
        ];
      case EtatCatalogue.vide:
        // Un catalogue vide n'est pas une panne et ne propose rien : la
        // personne ne peut pas publier un support elle-meme.
        return <Widget>[
          SliverToBoxAdapter(
            child: EmptyState(
              message: t.tc.bibliotheque.vide.message,
              invitation: t.tc.bibliotheque.vide.invitation,
              registre: RegistreVide.subi,
            ),
          ),
        ];
      case EtatCatalogue.aucunResultat:
        // Celui-la est actionnable : relacher la recherche depend d'elle.
        return <Widget>[
          SliverToBoxAdapter(
            child: EmptyState(
              message: t.tc.bibliotheque.aucunResultat.message,
              invitation: t.tc.bibliotheque.aucunResultat.invitation,
              libelleAction: t.tc.bibliotheque.effacerRecherche,
              onAction: _relacher,
            ),
          ),
        ];
      case EtatCatalogue.contenu:
        return <Widget>[
          if (vue.reprise != null) ..._sectionReprise(context, vue),
          for (final SectionCatalogue section in vue.sections)
            ..._section(context, vue, section),
        ];
    }
  }

  /// « Continuer » : une seule carte, celle qu'on reprend.
  ///
  /// Ce n'est pas une section permanente : elle n'existe que s'il y a
  /// reellement quelque chose a reprendre (CONTRACTS section 2, invariant 4).
  List<Widget> _sectionReprise(BuildContext context, VueCatalogue vue) {
    final ReprisLecture reprise = vue.reprise!;
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: SectionHeader(titre: t.tc.bibliotheque.sections.continuer),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.section),
          child: _carte(context, vue, reprise.ressource, reprise.position),
        ),
      ),
    ];
  }

  List<Widget> _section(
    BuildContext context,
    VueCatalogue vue,
    SectionCatalogue section,
  ) => <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: SectionHeader(
          titre: libelleSection(section.id),
          compteur: section.ressources.length,
        ),
      ),
    ),
    SliverList.separated(
      itemCount: section.ressources.length,
      separatorBuilder: (BuildContext _, int _) => Ecart.vLg,
      itemBuilder: (BuildContext contexte, int index) {
        final LibraryResource r = section.ressources[index];
        return _carte(
          contexte,
          vue,
          r,
          RechercheCatalogue.positionDemandee(_requete, r),
        );
      },
    ),
    const SliverToBoxAdapter(child: Ecart.vSection),
  ];

  Widget _carte(
    BuildContext context,
    VueCatalogue vue,
    LibraryResource r,
    ContentPosition? position,
  ) {
    final bool ouvrable = vue.ouvrable(r);
    return CarteRessource(
      ressource: r,
      etatOffline: vue.etatOffline(r.id),
      onPress: ouvrable ? () => widget.onChoisir(r, position) : null,
      raisonIndisponible: ouvrable
          ? null
          : (r.publiee
                ? t.tc.bibliotheque.message.horsLigneNonTelecharge
                : t.tc.bibliotheque.detail.sansVersion),
    );
  }

  void _basculerType(TypeRessource type) => setState(() {
    final Set<TypeRessource> retenus = Set<TypeRessource>.of(
      _filtre.types ?? const <TypeRessource>{},
    );
    if (!retenus.remove(type)) retenus.add(type);
    _filtre = retenus.isEmpty
        ? _filtre.avec(relacher: const <String>{'types'})
        : _filtre.avec(types: retenus);
  });

  void _relacher() => setState(() {
    _recherche.clear();
    _requete = '';
    _filtre = const FiltreCatalogue();
  });
}
