// Beneficiaires vus par le Comptable (FIN-CPT-W07, liste ; spec §16, §27.2,
// §35). Constructeur pose par CPT-F ; ecrit par la voie CPT-BEN (CPT-BEN-1).
//
// Une phrase de contexte, les filtres par etat du profil (pastilles avec leur
// nombre, `?filtre=infos` depuis Aujourd'hui), puis un tableau dense sur
// bureau et des cartes ailleurs (`DataCollection`) : beneficiaire, type,
// destination **masquee par la source** (« Mobile money · Operateur A •••• 4423 »),
// etat du profil, paiements en attente. Toucher une ligne ouvre son profil
// (W07). Aucun « Modifier coordonnees » nulle part (R-FIN-11, 12) : la seule
// ecriture possible, ailleurs, est celle du beneficiaire lui-meme.
//
// Cinq etats : chargement (squelette), contenu, vide (aucun beneficiaire, ou
// aucun avec ce filtre), erreur (reessayer), hors ligne. Tant que la source
// n'existe pas (production, `CapaciteIndisponible('CPT-BR-06')`), l'ecran
// reste « en preparation », sans un chiffre.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/data_collection.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import 'etat_beneficiaires.dart';

/// La liste des beneficiaires, onglet « Beneficiaires » de Paiements.
class BeneficiairesPage extends ConsumerStatefulWidget {
  /// Cree la page. [filtre] vient de `?filtre=` (`infos` pour les
  /// informations manquantes, depuis Aujourd'hui), brut.
  const BeneficiairesPage({super.key, this.filtre});

  /// Le filtre, brut.
  final String? filtre;

  /// La cle de la collection.
  static const Key collectionKey = ValueKey<String>('cpt-ben-collection');

  @override
  ConsumerState<BeneficiairesPage> createState() => _BeneficiairesPageEtat();
}

class _BeneficiairesPageEtat extends ConsumerState<BeneficiairesPage> {
  late FiltreListeBeneficiaires _filtre = FiltreListeBeneficiaires.depuis(
    widget.filtre,
  );

  @override
  void didUpdateWidget(BeneficiairesPage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.filtre != widget.filtre) {
      _filtre = FiltreListeBeneficiaires.depuis(widget.filtre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = t.comptable.beneficiaires;
    final AsyncValue<List<ProfilPaiementBeneficiaire>> liste = ref.watch(
      beneficiairesProvider,
    );
    void relire() => ref.invalidate(beneficiairesProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    return PageShell(
      titre: b.titre,
      sousTitre: b.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPaiementsComptable(),
        indexActif: 2,
      ),
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      // `DataCollection` defile lui-meme (en-tete de colonnes colle).
      defilante: false,
      // Texte agrandi (`AppGabarit.seuilTexteColonne`) : l'introduction
      // defile avec la page et les filtres tiennent sur une ligne qu'on fait
      // glisser ; la collection garde toute la hauteur de la vue.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          final Widget bloc = BlocAsynchrone<List<ProfilPaiementBeneficiaire>>(
            valeur: liste,
            squelette: const SingleChildScrollView(
              child: Skeleton.liste(lignes: 6),
            ),
            onReessayer: relire,
            vide: SingleChildScrollView(
              child: EmptyState(
                message: b.vide,
                invitation: b.videDetail,
                icone: AppIcons.beneficiaire,
                registre: RegistreVide.subi,
              ),
            ),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
              // Source absente : l'ecran reste « en preparation ».
              if (erreur is CapaciteIndisponible) {
                return SingleChildScrollView(
                  child: EmptyState(
                    message: t.comptable.commun.enPreparationTitre,
                    invitation: t.comptable.commun.enPreparationPhrase,
                  ),
                );
              }
              if (horsLigne) {
                return SingleChildScrollView(
                  child: EtatSysteme.sansDonnees(
                    quoi: t.sansDonnees.beneficiaires,
                    onAction: reessayer,
                  ),
                );
              }
              return null;
            },
            construire: (List<ProfilPaiementBeneficiaire> profils) => _Corps(
              profils: profils,
              filtre: _filtre,
              filtresEnLigne: empiler,
              onFiltre: (FiltreListeBeneficiaires f) =>
                  setState(() => _filtre = f),
            ),
          );
          final List<Widget> tete = <Widget>[
            Text(
              b.intro,
              style: AppPalette.of(context).inkMuted
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
            Ecart.vLg,
          ];
          if (!empiler) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...tete,
                Expanded(child: bloc),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...tete,
                SizedBox(height: contraintes.maxHeight, child: bloc),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Les filtres, puis la collection (ou le vide du filtre).
class _Corps extends StatelessWidget {
  const _Corps({
    required this.profils,
    required this.filtre,
    required this.onFiltre,
    this.filtresEnLigne = false,
  });

  final List<ProfilPaiementBeneficiaire> profils;
  final FiltreListeBeneficiaires filtre;
  final ValueChanged<FiltreListeBeneficiaires> onFiltre;

  /// Vrai a texte agrandi : les filtres sur une seule ligne glissante.
  final bool filtresEnLigne;

  @override
  Widget build(BuildContext context) {
    final b = t.comptable.beneficiaires;
    final List<ProfilPaiementBeneficiaire> visibles = profils
        .where(filtre.retient)
        .toList(growable: false);
    int nombre(FiltreListeBeneficiaires f) => profils.where(f.retient).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Seuls les filtres qui retiennent quelqu'un (et « Tous », et le
        // filtre courant) : une pastille a zero n'appelle aucun geste.
        Builder(
          builder: (BuildContext _) {
            final List<Widget> pastilles = <Widget>[
              for (final FiltreListeBeneficiaires f
                  in FiltreListeBeneficiaires.values)
                if (f == FiltreListeBeneficiaires.tous ||
                    f == filtre ||
                    nombre(f) > 0)
                  FilterPill(
                    key: ValueKey<String>('cpt-ben-filtre-${f.name}'),
                    libelle: f.libelle,
                    compteur: nombre(f),
                    retenue: f == filtre,
                    onPress: () => onFiltre(f),
                  ),
            ];
            if (!filtresEnLigne) {
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: pastilles,
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final Widget p in pastilles) ...<Widget>[p, Ecart.hSm],
                ],
              ),
            );
          },
        ),
        Ecart.vLg,
        if (visibles.isEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: EmptyState(
                message: b.videFiltre,
                invitation: b.videFiltreDetail,
                icone: AppIcons.rienAAfficher,
                registre: RegistreVide.subi,
              ),
            ),
          )
        else
          Expanded(
            child: DataCollection<ProfilPaiementBeneficiaire>(
              key: BeneficiairesPage.collectionKey,
              lignes: visibles,
              cle: (ProfilPaiementBeneficiaire p) =>
                  ValueKey<String>('cpt-ben-ligne-${p.identite.id}'),
              onSelectionner: (ProfilPaiementBeneficiaire p) =>
                  context.push(Routes.comptableBeneficiairePour(p.identite.id)),
              colonnes: <ColonneDonnees<ProfilPaiementBeneficiaire>>[
                ColonneDonnees<ProfilPaiementBeneficiaire>(
                  titre: b.colonneBeneficiaire,
                  role: RoleColonne.identifiante,
                  flex: 3,
                  texte: (ProfilPaiementBeneficiaire p) => p.identite.nom,
                ),
                ColonneDonnees<ProfilPaiementBeneficiaire>(
                  titre: b.colonneType,
                  texte: (ProfilPaiementBeneficiaire p) =>
                      libelleTypeBeneficiaire(p.identite.type),
                ),
                ColonneDonnees<ProfilPaiementBeneficiaire>(
                  titre: b.colonneDestination,
                  flex: 3,
                  tabulaire: true,
                  role: RoleColonne.aPart,
                  texte: (ProfilPaiementBeneficiaire p) =>
                      texteDestination(p.destination),
                ),
                ColonneDonnees<ProfilPaiementBeneficiaire>(
                  titre: b.colonneEtat,
                  flex: 2,
                  texte: (ProfilPaiementBeneficiaire p) =>
                      libelleProfilPaiement(p.etat),
                  rendu: (BuildContext _, ProfilPaiementBeneficiaire p) =>
                      PastilleProfilPaiement(p.etat),
                ),
                ColonneDonnees<ProfilPaiementBeneficiaire>(
                  titre: b.colonneEnAttente,
                  flex: 2,
                  tabulaire: true,
                  texte: (ProfilPaiementBeneficiaire p) =>
                      p.obligationsEnAttente == 0
                      ? b.aucunEnAttente
                      : b.enAttente(n: p.obligationsEnAttente),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
