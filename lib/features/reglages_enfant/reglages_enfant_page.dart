import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/domain/enums.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/regles/service_regles.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/setting_row.dart';

/// `TUT-05` : les demandes du tuteur, profil eleve par profil eleve.
///
/// **Une fonction = un seul endroit** (03, section 1 ter point 1) : depuis le
/// lot B (fiche eleve), la photo, la camera et l'interface de chaque eleve se
/// reglent dans sa fiche (`/tuteur/foyer/:eleveId/{informations,camera,
/// interface}`). Cette page n'en garde qu'un **renvoi** par eleve vers la
/// fiche, jamais une copie des reglages. La route `/tuteur/reglages` sera
/// redirigee vers le Foyer par le coordinateur (mapping C6, demande B-4).
///
/// C'est encore d'ici que le tuteur **demande** : reaffectation, duree de
/// seance et minimum payable. Une demande n'a pas d'ecran a elle, elle part de
/// l'ecran ou la regle se constate (ADR-017, section 5 de
/// `etape-4-dashboards.md`).
class ReglagesEnfantPage extends ConsumerWidget {
  /// Cree l'ecran des reglages.
  const ReglagesEnfantPage({super.key});

  /// Le renvoi d'un eleve vers sa fiche.
  static Key renvoiKey(String eleveId) => Key('reglagesEnfant.renvoi.$eleveId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveDuFoyer>> enfants = ref.watch(
      elevesDuFoyerProvider,
    );
    final List<EleveDuFoyer> foyer = enfants.value ?? const <EleveDuFoyer>[];

    return PageShell(
      titre: t.reglagesEnfant.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TexteSansCoupure(t.reglagesEnfant.intro, style: textes.bodySmall),
          Ecart.vXl,
          SectionHeader(titre: t.compte.titre),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.profil,
                description: t.compte.profilDetail,
                icon: AppIcons.profil,
                onPress: () => context.push(Routes.compteProfil),
              ),
              SettingRow(
                title: t.compte.profils,
                description: t.compte.profilsDetail,
                icon: AppIcons.foyer,
                onPress: () => context.push(Routes.compteProfils),
              ),
              SettingRow(
                title: t.compte.reglages,
                description: t.compte.reglagesDetail,
                icon: AppIcons.reglages,
                onPress: () => context.push(Routes.compteReglages),
              ),
            ],
          ),
          Ecart.vXl,
          if (enfants.hasValue && foyer.isEmpty)
            EmptyState(
              message: t.enfant.aucun,
              invitation: t.enfant.aucunDetail,
              libelleAction: t.enfant.titre,
              onAction: () =>
                  GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
            )
          else
            for (final EleveDuFoyer enfant in foyer)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _CarteEnfant(enfant: enfant),
              ),
        ],
      ),
    );
  }
}

/// Une carte par eleve : sa photo et son prenom, le renvoi vers sa fiche,
/// ses demandes. Aucun identifiant interne a l'ecran.
class _CarteEnfant extends StatelessWidget {
  const _CarteEnfant({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // AVATAR-1 : couple avatar + prenom du composant partage.
          AvatarNom.enLigne(
            prenom: enfant.prenom,
            diametre: AppAvatar.grand,
            avatar: _Photo(enfant: enfant),
            styleNom: textes.titleLarge,
          ),
          Ecart.vMd,
          // Photo, camera et interface : un renvoi vers la fiche, leur seule
          // place (lot B, LB-3).
          KeyedSubtree(
            key: ReglagesEnfantPage.renvoiKey(enfant.id),
            child: GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  icone: AppIcons.reglages,
                  libelle: t.reglagesEnfant.renvoi,
                  legende: t.reglagesEnfant.renvoiLegende(
                    dePrenom: deDevant(enfant.prenom),
                  ),
                  onPress: () =>
                      GoRouter.of(context).go(Routes.ficheElevePour(enfant.id)),
                ),
              ],
            ),
          ),
          Ecart.vLg,
          _Demandes(enfant: enfant),
        ],
      ),
    );
  }
}

/// La photo actuelle, par URL signee, avec repli sur les initiales.
class _Photo extends ConsumerWidget {
  const _Photo({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? cle = enfant.cleAvatar;
    // Lu par `value`, jamais par le type d'execution de l'AsyncValue : Riverpod
    // relance un provider en echec et repasse par AsyncLoading. Tant que l'URL
    // manque, la tuile montre les initiales, ce qui est le repli prevu.
    final String? url = cle == null
        ? null
        : ref.watch(avatarUrlProvider(cle)).value;

    return AvatarTile(
      prenom: enfant.prenom,
      urlSignee: url,
      diametre: AppAvatar.grand,
    );
  }
}

/// Les trois demandes que le tuteur peut deposer pour son enfant.
///
/// Elles partent d'ici et pas d'un ecran a elles : c'est ici que le parent
/// constate la regle, donc ici qu'il la conteste. La reaffectation n'est
/// proposee que si un enseignant suit l'enfant, sinon il n'y a rien a changer
/// et la base refuserait la demande apres le geste.
class _Demandes extends ConsumerWidget {
  const _Demandes({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final List<Affectation> liens =
        ref.watch(affectationsProvider).value ?? const <Affectation>[];
    final bool affecte = liens.any(
      (Affectation a) => a.active && a.eleveId == enfant.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // COUPE-MOTS-4 : « changement » ne se coupe plus en Interface guidee.
        TexteSansCoupure(t.tuteur.reglages.demandes, style: textes.titleMedium),
        Ecart.vSm,
        // Les trois demandes sont tertiaires, pas secondaires : ce sont des
        // requetes administratives que l'administration tranche, pas des
        // reglages immediats comme la camera ou le mode d'affichage
        // (`02-regles-ux.md` section 3, « derriere un geste : secondaire ou
        // administratif »). Avec la camera et le mode deja au niveau
        // secondaire ailleurs sur la carte, un troisieme secondaire ici
        // depasserait le plafond de deux par ecran.
        if (affecte)
          ActionPrincipale(
            libelle: t.tuteur.reglages.demandeReaffectation,
            niveau: NiveauAction.tertiaire,
            onPress: () => _ouvrir(context, SorteDemande.reaffectation, null),
          )
        else
          // Le bouton n'est pas rendu : la phrase explique la limite, comme le
          // plafond de `ENS-06`.
          TexteSansCoupure(
            t.tuteur.reglages.demandeSansEnseignant(prenom: enfant.prenom),
            style: textes.bodySmall,
          ),
        Ecart.vSm,
        ActionPrincipale(
          libelle: t.tuteur.reglages.demandeDuree,
          niveau: NiveauAction.tertiaire,
          onPress: () =>
              _ouvrir(context, SorteDemande.regle, CleRegle.dureeSeance),
        ),
        Ecart.vSm,
        ActionPrincipale(
          libelle: t.tuteur.reglages.demandeMinimum,
          niveau: NiveauAction.tertiaire,
          onPress: () =>
              _ouvrir(context, SorteDemande.regle, CleRegle.minimumPayable),
        ),
      ],
    );
  }

  Future<void> _ouvrir(
    BuildContext context,
    SorteDemande sorte,
    CleRegle? cle,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext contexteFeuille) =>
        FeuilleDemandeTuteur(enfant: enfant, sorte: sorte, cle: cle),
  );
}

/// La feuille de demande du tuteur.
///
/// Meme forme que celle de `ENS-06` : un choix quand il y a une valeur a
/// demander, un motif toujours, et une confirmation qui remplace le formulaire.
/// **Le motif est obligatoire de bout en bout** : la base refuse une demande
/// sans lui, et l'ecran le dit quand on presse sans (bouton jamais grise).
@visibleForTesting
class FeuilleDemandeTuteur extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleDemandeTuteur({
    required this.enfant,
    required this.sorte,
    required this.cle,
    super.key,
  });

  /// L'enfant concerne.
  final EleveDuFoyer enfant;

  /// Ce qui est demande.
  final SorteDemande sorte;

  /// La regle visee, quand la demande en vise une.
  final CleRegle? cle;

  @override
  ConsumerState<FeuilleDemandeTuteur> createState() =>
      _FeuilleDemandeTuteurEtat();
}

class _FeuilleDemandeTuteurEtat extends ConsumerState<FeuilleDemandeTuteur> {
  final TextEditingController _motif = TextEditingController();
  int? _valeur;

  /// Le choix de la duree et le champ du motif : le focus y revient quand
  /// c'est eux qui manquent (BOUTONS-GRISES-1, reserve SUPERPOS-1b).
  final FocusNode _focusValeur = FocusNode(debugLabel: 'demande-valeur');
  final GlobalKey<SelecteurMotifEtat> _selecteurMotif =
      GlobalKey<SelecteurMotifEtat>();

  bool _enCours = false;
  bool _motifManquant = false;
  String? _erreur;
  bool _envoyee = false;

  /// Les durees proposees, en minutes.
  ///
  /// Elles ne decident de rien : ce sont des raccourcis de saisie, et la carte
  /// « Autre » de `ChoiceCardGroup` accepte n'importe quelle autre valeur. La
  /// regle qui s'applique reste celle que l'administration tranchera.
  static const List<int> dureesProposees = <int>[30, 45, 60, 90];

  bool get _avecValeur => widget.sorte == SorteDemande.regle;

  @override
  void dispose() {
    _motif.dispose();
    _focusValeur.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    // Bouton jamais grise (K-56) : presse trop tot, il dit ce qui manque,
    // l'annonce au lecteur d'ecran et rend le focus au champ fautif
    // (BOUTONS-GRISES-1, reserve SUPERPOS-1b).
    if (_avecValeur && _valeur == null) {
      final String message = t.tuteur.reglages.demandeManqueValeur;
      setState(() => _erreur = message);
      signalerManque(context, message, champ: _focusValeur);
      return;
    }
    if (_motif.text.trim().isEmpty) {
      setState(() {
        _erreur = null;
        _motifManquant = true;
      });
      // Le focus va a la premiere puce, ou au champ libre si « Autre » est
      // ouvert : le geste qui manque.
      _selecteurMotif.currentState?.focaliser();
      signalerManque(context, t.formulaire.motif.manque);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceMatchingProvider)
          .demander(
            sorte: widget.sorte,
            sujetId: widget.enfant.id,
            motif: _motif.text.trim(),
            cle: widget.cle,
            valeur: _valeur,
          );
      if (mounted) {
        setState(() => _envoyee = true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final CleRegle? cle = widget.cle;
    // La valeur qui s'applique DEJA a cet enfant, lue par `regle_effective()`
    // et non par une constante : c'est elle que le parent veut voir avant de
    // demander autre chose (invariant I10).
    final AsyncValue<int>? actuelle = cle == null
        ? null
        : ref.watch(
            valeurRegleProvider((profilId: widget.enfant.id, cle: cle)),
          );

    // FORM-L1 : les puces de motifs allongent la feuille ; elle defile au
    // lieu de deborder (vue basse, texte agrandi).
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: metriques.marge,
          end: metriques.marge,
          top: metriques.marge,
          bottom: MediaQuery.viewInsetsOf(context).bottom + metriques.marge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TexteSansCoupure(_titre(), style: textes.titleMedium),
            Ecart.vMd,
            if (_envoyee)
              TexteSansCoupure(
                t.tuteur.reglages.demandeEnvoyee,
                style: textes.bodyMedium,
              )
            else ...<Widget>[
              if (actuelle?.value != null) ...<Widget>[
                TexteSansCoupure(
                  LibellesGroupe.insecable(
                    t.tuteur.reglages.demandeActuelle(
                      minutes: '${actuelle!.requireValue}',
                    ),
                  ),
                  style: textes.bodySmall,
                ),
                Ecart.vMd,
              ],
              if (_avecValeur) ...<Widget>[
                Focus(
                  focusNode: _focusValeur,
                  child: ChoiceCardGroup(
                    options: <OptionChoix>[
                      for (final int minutes in dureesProposees)
                        OptionChoix(
                          valeur: '$minutes',
                          libelle: LibellesGroupe.valeurSeule(
                            t.tuteur.reglages.demandeMinutes(
                              minutes: '$minutes',
                            ),
                          ),
                        ),
                    ],
                    onChange: (ReponseChoix reponse) => setState(() {
                      _erreur = null;
                      _valeur = int.tryParse(
                        reponse.valeurs.isEmpty
                            ? reponse.saisieLibre ?? ''
                            : reponse.valeurs.first,
                      );
                    }),
                  ),
                ),
                Ecart.vMd,
              ],
              // COUPE-MOTS-FOND-1 (6) : « changement ? » (espace insecable)
              // est un seul bloc ; en Interface guidee a 320 px texte x2, il
              // ne tenait qu'a 0,8 px pres, et le « ? » partait seul a la
              // ligne des que la feuille etait plus etroite. Le bloc se
              // reduit, borne, au lieu d'etre casse.
              TexteSansCoupure(
                t.tuteur.reglages.demandeMotif,
                style: textes.titleSmall,
              ),
              Ecart.vXs,
              Text(
                t.tuteur.reglages.demandeMotifRequis,
                style: textes.bodySmall,
              ),
              Ecart.vSm,
              SelecteurMotif(
                motifs: _motifsProposes(),
                controleur: _motif,
                key: _selecteurMotif,
                libelleChamp: t.tuteur.reglages.demandeMotif,
                erreur: _motifManquant ? t.formulaire.motif.manque : null,
                onChange: (String _) => setState(() => _motifManquant = false),
              ),
              if (_erreur != null) ...<Widget>[
                Ecart.vSm,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _erreur!,
                    style: palette.inkAlert.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
              Ecart.vMd,
              ActionPrincipale(
                libelle: t.tuteur.reglages.demandeEnvoyer,
                enCours: _enCours,
                onPress: _envoyer,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Les motifs proposes selon ce qui est demande (FORM-L1).
  List<String> _motifsProposes() => switch (widget.sorte) {
    SorteDemande.reaffectation => MotifsProposes.reglageEnseignant(),
    SorteDemande.plafond || SorteDemande.regle =>
      widget.cle == CleRegle.minimumPayable
          ? MotifsProposes.reglageMinimum()
          : MotifsProposes.reglageDuree(),
  };

  String _titre() => switch (widget.sorte) {
    SorteDemande.reaffectation => t.tuteur.reglages.demandeTitreReaffectation(
      dePrenom: deDevant(widget.enfant.prenom),
    ),
    SorteDemande.plafond || SorteDemande.regle =>
      widget.cle == CleRegle.minimumPayable
          ? t.tuteur.reglages.demandeTitreMinimum(prenom: widget.enfant.prenom)
          : t.tuteur.reglages.demandeTitreDuree(
              dePrenom: deDevant(widget.enfant.prenom),
            ),
  };
}

/// Le message metier d'une exception, sans son type.
String _message(Object erreur) {
  final String brut = erreur.toString();
  // Les exceptions Postgrest portent le message metier en clair : c'est lui
  // qu'il faut montrer, pas le type de l'exception.
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}
