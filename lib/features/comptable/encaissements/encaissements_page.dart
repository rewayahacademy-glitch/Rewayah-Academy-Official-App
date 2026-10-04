// Encaissements (FIN-CPT-W05, M02 ecran 2 ; spec §24, §33, §45). Posee « en
// preparation » par CPT-F avec son constructeur definitif ; **propriete de la
// voie CPT-ENC**, qui ecrit dans `lib/features/comptable/encaissements/**`
// seulement (`20_comptable/02_DECOUPAGE.md`).
//
// Composition (planche H08 W05, composition seulement, K-63) : filtres §33
// avec leur compteur, recherche famille / reference (DR-18 : dans la table,
// jamais globale), puis
// - a 1440 (bureau, texte normal) : le tableau §24.2 ; une ligne choisie
//   ouvre le panneau detail a droite (§33) et le tableau garde ses colonnes
//   essentielles ;
// - sous 1200, ou texte agrandi : une liste de cartes, chacune ouvre la page
//   detail (`/comptable/tresorerie/encaissements/:id`).
//
// Etats §24.1 rendus par la source (`PastilleEncaissement`, mot + point,
// jamais la couleur seule) ; « Confirme » seulement sur retour du port
// (§24.3). Montants masques par defaut (`MontantSensible`), aucune colonne
// triable (DR-06). Lit `portEncaissementsProvider` (CPT-BR-07) ; sans source,
// la page reste « en preparation ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_encaissements.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/comptable/visibilite_montants.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bouton_icone.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import 'commun_encaissements.dart';
import 'contenu_encaissement.dart';
import 'donnees_encaissements.dart';

/// La liste des encaissements, onglet « Encaissements » de Tresorerie.
class EncaissementsPage extends ConsumerStatefulWidget {
  /// Cree la page. [filtre] vient de `?filtre=`, brut.
  const EncaissementsPage({super.key, this.filtre});

  /// Le filtre d'etat, brut.
  final String? filtre;

  /// La cle du champ de recherche.
  static const Key rechercheKey = ValueKey<String>('enc-recherche');

  /// La cle du panneau detail (bureau).
  static const Key panneauKey = ValueKey<String>('enc-panneau');

  /// La cle de la ligne ou de la carte d'un encaissement.
  static Key ligneKey(String id) => ValueKey<String>('enc-ligne-$id');

  /// La cle de la pilule d'un filtre.
  static Key filtreKey(FiltreListeEncaissements f) =>
      ValueKey<String>('enc-filtre-${f.name}');

  @override
  ConsumerState<EncaissementsPage> createState() => _EncaissementsPageState();
}

class _EncaissementsPageState extends ConsumerState<EncaissementsPage> {
  late FiltreListeEncaissements _filtre = FiltreListeEncaissements.depuis(
    widget.filtre,
  );
  final TextEditingController _recherche = TextEditingController();
  String? _selection;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _ouvrir(Encaissement e, {required bool panneau}) {
    if (panneau) {
      setState(() => _selection = e.id);
    } else {
      context.push(Routes.comptableEncaissementPour(e.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = t.comptable.encaissements;
    final bool panneau = composeEnPanneau(context);
    final AsyncValue<List<Encaissement>> valeur = ref.watch(
      listeEncaissementsProvider,
    );
    final bool sansSource =
        valeur.hasError && valeur.error is CapaciteIndisponible;
    return PageShell(
      titre: e.titre,
      sousTitre: e.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
        indexActif: 1,
      ),
      actionsEntete: const <Widget>[BasculeMontants()],
      defilante: !panneau || sansSource,
      child: sansSource
          ? const EnPreparationComptable()
          : BlocEncaissements<List<Encaissement>>(
              valeur: valeur,
              onReessayer: () => ref.invalidate(listeEncaissementsProvider),
              vide: EmptyState(message: e.videTitre, invitation: e.videPhrase),
              construire: (List<Encaissement> tous) =>
                  _contenu(context, tous, panneau: panneau),
            ),
    );
  }

  Widget _contenu(
    BuildContext context,
    List<Encaissement> tous, {
    required bool panneau,
  }) {
    final e = t.comptable.encaissements;
    final List<Encaissement> lignes = <Encaissement>[
      for (final Encaissement x in tous)
        if (_filtre.retient(x.etat) && correspondRecherche(x, _recherche.text))
          x,
    ];
    final Widget filtres = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final FiltreListeEncaissements f
            in FiltreListeEncaissements.values)
          FilterPill(
            key: EncaissementsPage.filtreKey(f),
            libelle: f.libelle,
            retenue: f == _filtre,
            compteur: tous.where((Encaissement x) => f.retient(x.etat)).length,
            onPress: () => setState(() {
              _filtre = f;
              _selection = null;
            }),
          ),
      ],
    );
    final Widget recherche = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurFormulaire),
      child: TextField(
        key: EncaissementsPage.rechercheKey,
        controller: _recherche,
        textInputAction: TextInputAction.search,
        onChanged: (String _) => setState(() => _selection = null),
        decoration: InputDecoration(
          isDense: true,
          hintText: e.recherche,
          prefixIcon: Icon(AppIcons.recherche.repos),
        ),
      ),
    );
    final Widget aucun = EmptyState(
      message: e.videFiltreTitre,
      invitation: e.videFiltrePhrase,
      libelleAction: e.voirTous,
      onAction: () => setState(() {
        _filtre = FiltreListeEncaissements.tous;
        _recherche.clear();
      }),
    );
    final List<Widget> tete = <Widget>[
      filtres,
      Ecart.vLg,
      Align(alignment: AlignmentDirectional.centerStart, child: recherche),
      Ecart.vLg,
    ];
    if (!panneau) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...tete,
          if (lignes.isEmpty)
            aucun
          else
            for (int i = 0; i < lignes.length; i++) ...<Widget>[
              if (i > 0) Ecart.vLg,
              _CarteEncaissement(
                key: EncaissementsPage.ligneKey(lignes[i].id),
                encaissement: lignes[i],
                onPress: () => _ouvrir(lignes[i], panneau: false),
              ),
            ],
        ],
      );
    }
    final String? choisi = lignes.any((Encaissement x) => x.id == _selection)
        ? _selection
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...tete,
        Expanded(
          child: lignes.isEmpty
              ? SingleChildScrollView(child: aucun)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: choisi == null ? 1 : 3,
                      child: _TableEncaissements(
                        lignes: lignes,
                        compacte: choisi != null,
                        onChoisir: (Encaissement x) =>
                            _ouvrir(x, panneau: true),
                      ),
                    ),
                    if (choisi != null) ...<Widget>[
                      Ecart.hXxl,
                      Expanded(
                        flex: 2,
                        child: _Panneau(
                          key: EncaissementsPage.panneauKey,
                          encaissementId: choisi,
                          onFermer: () => setState(() => _selection = null),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Le texte d'un montant tel qu'il s'affiche : le masque tant que les
/// montants sont masques, jamais le chiffre (DR-06).
String _texteMontant(Montant m, {required bool affiche}) =>
    affiche ? formaterMontant(m) : MontantSensible.masquePour(m.devise);

/// Les prenoms des profils concernes, ou rien.
String _profils(Encaissement e) => e.profils.isEmpty
    ? ''
    : t.comptable.encaissements.profilsPour(
        prenoms: e.profils.map((AffectationProfil p) => p.prenom).join(', '),
      );

/// Le tableau §24.2 (bureau). [compacte] : le panneau est ouvert, le tableau
/// garde date, famille, net et etat ; le reste est dans le panneau.
class _TableEncaissements extends ConsumerWidget {
  const _TableEncaissements({
    required this.lignes,
    required this.compacte,
    required this.onChoisir,
  });

  final List<Encaissement> lignes;
  final bool compacte;
  final void Function(Encaissement e) onChoisir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.comptable.encaissements;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    ColonneDonnees<Encaissement> montant(
      String titre,
      Montant Function(Encaissement x) lire, {
      bool attenu = false,
    }) => ColonneDonnees<Encaissement>(
      titre: titre,
      flex: 2,
      tabulaire: true,
      texte: (Encaissement x) => _texteMontant(lire(x), affiche: affiche),
      rendu: (BuildContext _, Encaissement x) =>
          MontantSensible(lire(x), attenue: attenu),
    );
    final List<ColonneDonnees<Encaissement>> colonnes =
        <ColonneDonnees<Encaissement>>[
          ColonneDonnees<Encaissement>(
            titre: e.colDate,
            flex: 2,
            tabulaire: true,
            texte: (Encaissement x) => dateComptable(x.date),
          ),
          ColonneDonnees<Encaissement>(
            titre: e.colFamille,
            role: RoleColonne.identifiante,
            flex: 3,
            texte: (Encaissement x) => x.famille,
            rendu: (BuildContext _, Encaissement x) => Semantics(
              button: true,
              label: e.ouvrirDetailLecteur(famille: x.famille),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExcludeSemantics(child: Text(x.famille, style: fort)),
                  if (x.profils.isNotEmpty) Text(_profils(x), style: attenue),
                ],
              ),
            ),
          ),
          if (!compacte) ...<ColonneDonnees<Encaissement>>[
            ColonneDonnees<Encaissement>(
              titre: e.colReference,
              flex: 2,
              tabulaire: true,
              texte: (Encaissement x) => x.reference,
            ),
            montant(e.colBrut, (Encaissement x) => x.brut),
            montant(e.colFrais, (Encaissement x) => x.frais, attenu: true),
          ],
          montant(e.colNet, (Encaissement x) => x.net),
          if (!compacte)
            ColonneDonnees<Encaissement>(
              titre: e.colMoyen,
              flex: 2,
              texte: (Encaissement x) => e.moyenPrestataire(
                moyen: x.moyen,
                prestataire: x.prestataire,
              ),
              rendu: (BuildContext _, Encaissement x) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(x.moyen, style: fort),
                  Text(x.prestataire, style: attenue),
                ],
              ),
            ),
          ColonneDonnees<Encaissement>(
            titre: e.colEtat,
            flex: 3,
            texte: (Encaissement x) => libelleEncaissement(x.etat),
            rendu: (BuildContext _, Encaissement x) => _Etats(x),
          ),
        ];
    return DataCollection<Encaissement>(
      colonnes: colonnes,
      lignes: lignes,
      cle: (Encaissement x) => EncaissementsPage.ligneKey(x.id),
      onSelectionner: onChoisir,
    );
  }
}

/// L'etat de l'encaissement et, quand il attend encore quelque chose, celui
/// de son rapprochement.
class _Etats extends StatelessWidget {
  const _Etats(this.encaissement);

  final Encaissement encaissement;

  @override
  Widget build(BuildContext context) {
    final EtatRapprochement? r = encaissement.rapprochement;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        PastilleEncaissement(encaissement.etat),
        if (r != null && r != EtatRapprochement.rapproche)
          PastilleRapprochement(r),
      ],
    );
  }
}

/// Le panneau detail (bureau, §33) : il defile seul, le tableau reste en
/// place.
class _Panneau extends StatelessWidget {
  const _Panneau({
    required this.encaissementId,
    required this.onFermer,
    super.key,
  });

  final String encaissementId;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: SingleChildScrollView(
        key: ValueKey<String>('enc-panneau-$encaissementId'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: BoutonIcone(
                icone: AppIcons.fermer,
                libelle: t.comptable.encaissements.fermerDetail,
                onPress: onFermer,
              ),
            ),
            DetailEncaissementLu(encaissementId: encaissementId),
          ],
        ),
      ),
    );
  }
}

/// Un encaissement en carte (sous 1200 ou texte agrandi, M02 ecran 2) :
/// famille, profils, date et moyen, le net masquable, l'etat ; la carte
/// ouvre la page detail.
class _CarteEncaissement extends StatelessWidget {
  const _CarteEncaissement({
    required this.encaissement,
    required this.onPress,
    super.key,
  });

  final Encaissement encaissement;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.comptable.encaissements;
    final Encaissement x = encaissement;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final Widget identite = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          x.famille,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        if (x.profils.isNotEmpty) Text(_profils(x), style: attenue),
        Text(
          '${dateComptable(x.date)} · '
          '${e.moyenPrestataire(moyen: x.moyen, prestataire: x.prestataire)}',
          style: attenue,
        ),
      ],
    );
    final Widget net = MontantSensible(x.net, taille: TailleMontant.corps);
    return AppCard(
      onPress: onPress,
      libelleSemantique: e.ouvrirDetailLecteur(famille: x.famille),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (texteAgrandi(context)) ...<Widget>[identite, Ecart.vSm, net] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: identite),
                Ecart.hLg,
                net,
              ],
            ),
          Ecart.vSm,
          _Etats(x),
        ],
      ),
    );
  }
}
