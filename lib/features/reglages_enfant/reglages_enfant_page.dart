import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/regles/service_regles.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/setting_row.dart';

/// `TUT-05` : les reglages du tuteur, enfant par enfant.
///
/// **Un enfant par carte, trois reglages : photo, camera, mode d'interface.**
/// Le texte dit la consequence en clair, avec le prenom de l'enfant, jamais un
/// libelle abstrait : « Le bouton camera n'apparaitra pas pour Ibrahim » et non
/// « camera : desactivee » (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, ADR-009).
///
/// Ces reglages s'appliquent a la seance suivante, jamais pendant un cours :
/// l'ecran le dit une fois, en tete, plutot que de le repeter sur chaque carte.
///
/// C'est aussi d'ici que le tuteur **demande** : reaffectation, duree de seance
/// et minimum payable. Une demande n'a pas d'ecran a elle, elle part de l'ecran
/// ou la regle se constate (ADR-017, section 5 de `etape-4-dashboards.md`).
class ReglagesEnfantPage extends ConsumerWidget {
  /// Cree l'ecran des reglages.
  const ReglagesEnfantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveDuFoyer>> enfants = ref.watch(
      elevesDuFoyerProvider,
    );
    final List<EleveDuFoyer> foyer = enfants.value ?? const <EleveDuFoyer>[];

    return PageShell(
      titre: t.tuteur.reglages.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.tuteur.reglages.intro, style: textes.bodySmall),
          Ecart.vXl,
          SectionHeader(titre: t.compte.titre),
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
          Ecart.vXl,
          if (enfants.hasValue && foyer.isEmpty)
            EmptyState(
              message: t.tuteur.reglages.aucunEnfant,
              invitation: t.tuteur.reglages.aucunEnfantDetail,
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

/// Une carte par enfant : sa photo, sa camera, son affichage, ses demandes.
class _CarteEnfant extends ConsumerStatefulWidget {
  const _CarteEnfant({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  ConsumerState<_CarteEnfant> createState() => _CarteEnfantEtat();
}

class _CarteEnfantEtat extends ConsumerState<_CarteEnfant> {
  bool _photoEnCours = false;
  bool _reglageEnCours = false;
  String? _erreur;

  EleveDuFoyer get _enfant => widget.enfant;

  /// Ecrit un reglage, puis relit le foyer.
  ///
  /// L'ecran ne garde aucune copie locale de la valeur : ce que la base a
  /// accepte est ce qui s'affiche. Un etat local optimiste montrerait une
  /// camera autorisee la ou la policy vient de refuser l'ecriture.
  Future<void> _ecrire({
    InterfaceMode? mode,
    CameraPolicy? camera,
    String? cleAvatar,
  }) async {
    setState(() {
      _reglageEnCours = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceAppairageProvider)
          .majReglages(
            eleveId: _enfant.id,
            mode: mode,
            camera: camera,
            cleAvatar: cleAvatar,
          );
      ref.invalidate(elevesDuFoyerProvider);
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _reglageEnCours = false);
      }
    }
  }

  Future<void> _changerPhoto() async {
    setState(() {
      _photoEnCours = true;
      _erreur = null;
    });
    try {
      final PhotoEnfant? photo = await ref
          .read(selecteurPhotoProvider)
          .choisirPhoto();
      if (photo == null) {
        return;
      }
      if (photo.octets.lengthInBytes > ServiceAvatar.tailleMaximaleOctets) {
        // Le refus se dit AVANT l'envoi : le seau refuserait aussi, mais apres
        // avoir fait monter quatre mega-octets sur une connexion de telephone.
        if (mounted) {
          setState(
            () => _erreur = t.tuteur.reglages.photoTropLourde(
              taille: '${ServiceAvatar.tailleMaximaleOctets ~/ (1024 * 1024)}',
            ),
          );
        }
        return;
      }

      final String cle = await ref
          .read(serviceAvatarProvider)
          .televerser(eleveId: _enfant.id, photo: photo);
      await _ecrire(cleAvatar: cle);
      // La photo remplacee ne doit pas rester servie par l'URL precedente.
      ref.invalidate(avatarUrlProvider);
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _photoEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool cameraAutorisee = _enfant.camera == CameraPolicy.allowed;
    final bool modeEnfant = _enfant.mode == InterfaceMode.enfant;

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Photo(enfant: _enfant),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_enfant.prenom, style: textes.titleLarge),
                    Text(_enfant.identifiantImmuable, style: textes.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          Ecart.vMd,

          // 1. La photo.
          Text(t.tuteur.reglages.photo, style: textes.titleMedium),
          Text(
            _enfant.cleAvatar == null
                ? t.tuteur.reglages.photoAucune(prenom: _enfant.prenom)
                : t.tuteur.reglages.photoPresente(prenom: _enfant.prenom),
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: _enfant.cleAvatar == null
                ? t.tuteur.reglages.photoAjouter
                : t.tuteur.reglages.photoChanger,
            // Tertiaire, pas secondaire : la photo se change rarement, et la
            // carte porte deja deux secondaires (camera, mode). Au dela de
            // deux, `02-regles-ux.md` section 4 est violee -- constat du
            // 11 septembre 2026, six secondaires empiles sur cette carte.
            niveau: NiveauAction.tertiaire,
            enCours: _photoEnCours,
            onPress: _changerPhoto,
          ),
          Ecart.vLg,

          // 2. La camera. Le texte dit la CONSEQUENCE, avec le prenom.
          Text(t.tuteur.reglages.camera, style: textes.titleMedium),
          Text(
            cameraAutorisee
                ? t.tuteur.reglages.cameraAutorisee(prenom: _enfant.prenom)
                : t.tuteur.reglages.cameraInterdite(prenom: _enfant.prenom),
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: cameraAutorisee
                ? t.tuteur.reglages.cameraRetirer(prenom: _enfant.prenom)
                : t.tuteur.reglages.cameraAutoriser(prenom: _enfant.prenom),
            niveau: NiveauAction.secondaire,
            enCours: _reglageEnCours,
            onPress: () => _ecrire(
              camera: cameraAutorisee
                  ? CameraPolicy.forbidden
                  : CameraPolicy.allowed,
            ),
          ),
          Ecart.vLg,

          // 3. Le mode d'interface.
          Text(t.tuteur.reglages.mode, style: textes.titleMedium),
          Text(
            modeEnfant
                ? t.tuteur.reglages.modeEnfant(prenom: _enfant.prenom)
                : t.tuteur.reglages.modeStandard(prenom: _enfant.prenom),
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: modeEnfant
                ? t.tuteur.reglages.modePasserStandard(prenom: _enfant.prenom)
                : t.tuteur.reglages.modePasserEnfant(prenom: _enfant.prenom),
            niveau: NiveauAction.secondaire,
            enCours: _reglageEnCours,
            onPress: () => _ecrire(
              mode: modeEnfant ? InterfaceMode.standard : InterfaceMode.enfant,
            ),
          ),

          if (_erreur != null) ...<Widget>[
            Ecart.vSm,
            Text(
              t.tuteur.reglages.erreur(message: _erreur!),
              // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
              // blanc, illisible sur la page.
              style: palette.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],

          Ecart.vLg,
          _Demandes(enfant: _enfant),
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
      diametre: AppSpacing.xxxl * 2,
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
        Text(t.tuteur.reglages.demandes, style: textes.titleMedium),
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
          Text(
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
/// sans lui, et l'ecran ne rend pas le bouton tant qu'il manque.
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
  bool _enCours = false;
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
    super.dispose();
  }

  Future<void> _envoyer() async {
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

    return Padding(
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
          Text(_titre(), style: textes.titleMedium),
          Ecart.vMd,
          if (_envoyee)
            Text(t.tuteur.reglages.demandeEnvoyee, style: textes.bodyMedium)
          else ...<Widget>[
            if (actuelle?.value != null) ...<Widget>[
              Text(
                t.tuteur.reglages.demandeActuelle(
                  minutes: '${actuelle!.requireValue}',
                ),
                style: textes.bodySmall,
              ),
              Ecart.vMd,
            ],
            if (_avecValeur) ...<Widget>[
              ChoiceCardGroup(
                options: <OptionChoix>[
                  for (final int minutes in dureesProposees)
                    OptionChoix(
                      valeur: '$minutes',
                      libelle: t.tuteur.reglages.demandeMinutes(
                        minutes: '$minutes',
                      ),
                    ),
                ],
                onChange: (ReponseChoix reponse) => setState(() {
                  _valeur = int.tryParse(
                    reponse.valeurs.isEmpty
                        ? reponse.saisieLibre ?? ''
                        : reponse.valeurs.first,
                  );
                }),
              ),
              Ecart.vMd,
            ],
            TextField(
              controller: _motif,
              decoration: InputDecoration(
                labelText: t.tuteur.reglages.demandeMotif,
              ),
              // Sans ceci, le bouton ne se reconstruit pas a la frappe et reste
              // inerte alors que le motif est saisi (piege de l'etape 3).
              onChanged: (String _) => setState(() {}),
              maxLines: 2,
            ),
            if (_erreur != null) ...<Widget>[
              Ecart.vSm,
              Text(
                _erreur!,
                style: palette.inkAlert.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
            if (_motif.text.trim().isEmpty) ...<Widget>[
              Ecart.vSm,
              Text(
                t.tuteur.reglages.demandeMotifRequis,
                style: textes.bodySmall,
              ),
            ],
            Ecart.vMd,
            ActionPrincipale(
              libelle: t.tuteur.reglages.demandeEnvoyer,
              enCours: _enCours,
              onPress: _pret ? _envoyer : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Vrai quand la demande peut aboutir : un motif, et une valeur si la sorte
  /// en attend une.
  bool get _pret =>
      _motif.text.trim().isNotEmpty && (!_avecValeur || _valeur != null);

  String _titre() => switch (widget.sorte) {
    SorteDemande.reaffectation => t.tuteur.reglages.demandeTitreReaffectation(
      prenom: widget.enfant.prenom,
    ),
    SorteDemande.plafond || SorteDemande.regle =>
      widget.cle == CleRegle.minimumPayable
          ? t.tuteur.reglages.demandeTitreMinimum(prenom: widget.enfant.prenom)
          : t.tuteur.reglages.demandeTitreDuree(prenom: widget.enfant.prenom),
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
