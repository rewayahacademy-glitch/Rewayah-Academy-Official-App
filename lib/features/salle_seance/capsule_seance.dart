// La capsule compacte et le contexte de la seance (TB-3 : UI-01, CTX-01,
// CTX-02 ; plan V2 §4.3, §19.6, §20).
//
// Pendant le partage, l'en-tete porte une capsule a la place de la vignette
// video : avatar statique de l'enseignant, temoin d'enregistrement s'il est
// REELLEMENT actif, oeil du controle si la donnee existe. Ni nom, ni reseau,
// ni video. Chaque element est une cible de 48 qui porte un nom du §20.
//
// Toucher l'avatar deplie le contexte (nom, reseau, enregistrement,
// controle) dans le panneau de personnes existant ; l'oeil le deplie a la
// section du controle ; « Reduire » revient a la capsule. Assemblage de
// composants existants : `AvatarNom`, `PointEnregistrement`, l'icone de
// l'observation (`IndicateurObservation`), `StatusPill`, `ActionPrincipale`.

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import 'actions_seance.dart';
import 'vue_seance.dart';

/// La capsule de l'en-tete pendant le partage (UI-01). Rien hors partage.
class CapsuleSeance extends StatelessWidget {
  /// Cree la capsule.
  const CapsuleSeance({
    required this.vue,
    required this.actions,
    this.focusAvatar,
    super.key,
  });

  /// La cle de la capsule.
  static const Key cle = ValueKey<String>('capsule-seance');

  /// La cle de l'avatar touchable.
  static const Key cleAvatar = ValueKey<String>('capsule-avatar');

  /// La cle du temoin d'enregistrement.
  static const Key clePoint = ValueKey<String>('capsule-enregistrement');

  /// La cle de l'oeil du controle.
  static const Key cleOeil = ValueKey<String>('capsule-oeil');

  final VueSeance vue;
  final ActionsSeance actions;

  /// Le noeud de l'avatar : le focus y revient quand le contexte se reduit.
  final FocusNode? focusAvatar;

  @override
  Widget build(BuildContext context) {
    if (!vue.voitCapsule) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final ValueChanged<ContexteOuvert>? ouvrir = actions.onContexte;
    // L'avatar est decoratif (AvatarNom l'exclut) : le nom lu est porte par
    // la cible qui l'entoure.
    final Widget cercle = SizedBox.square(
      dimension: AppTouchTarget.standard,
      child: Center(
        child: AvatarNom.vertical(
          prenom: vue.nomEnseignant,
          afficherNom: false,
          diametre: AppAvatar.petit,
        ),
      ),
    );
    final Widget avatar = ouvrir == null
        ? Semantics(
            key: cleAvatar,
            container: true,
            image: true,
            label: vue.nomEnseignant,
            child: cercle,
          )
        // TB-RC (revue TB-R, m27) : une icone seule porte son infobulle
        // (comme `BoutonIcone`), muette au lecteur d'ecran qui lit deja le
        // nom.
        : Tooltip(
            message: vue.libelleAvatarCapsule,
            excludeFromSemantics: true,
            child: Pressable(
              key: cleAvatar,
              onPress: () => ouvrir(ContexteOuvert.enseignant),
              libelleSemantique: vue.libelleAvatarCapsule,
              selectionne: vue.contexte == ContexteOuvert.enseignant,
              arrondiFocus: AppRadius.arrondiFull,
              focusNode: focusAvatar,
              child: cercle,
            ),
          );
    final String? oeil = vue.libelleOeilCapsule;
    final Widget icone = SizedBox.square(
      dimension: AppTouchTarget.standard,
      child: Center(
        child: IconTheme(
          data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
          child: Icon(AppIcons.observationEnCours.repos),
        ),
      ),
    );
    return DecoratedBox(
      key: cle,
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiFull,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          avatar,
          // UX-12 : le point seulement si l'enregistrement est ACTIF ;
          // inactif ou inconnu, rien (jamais un voyant qui pretend). Fixe :
          // l'etat ne depend d'aucune animation, et le nom le dit.
          if (vue.voitPointEnregistrement)
            Semantics(
              key: clePoint,
              container: true,
              label: t.salle.seance.capsule.enregistrementActif,
              child: const SizedBox.square(
                dimension: AppTouchTarget.standard,
                child: Center(child: PointEnregistrement()),
              ),
            ),
          if (oeil != null)
            ouvrir == null
                ? Semantics(
                    key: cleOeil,
                    container: true,
                    label: oeil,
                    child: icone,
                  )
                : Tooltip(
                    message: oeil,
                    excludeFromSemantics: true,
                    child: Pressable(
                      key: cleOeil,
                      onPress: () => ouvrir(ContexteOuvert.controle),
                      libelleSemantique: oeil,
                      selectionne: vue.contexte == ContexteOuvert.controle,
                      arrondiFocus: AppRadius.arrondiFull,
                      child: icone,
                    ),
                  ),
        ],
      ),
    );
  }
}

/// Le contexte deplie (CTX-01, CTX-02) : l'enseignant nomme, le reseau,
/// l'enregistrement s'il est actif, le controle si la donnee existe, puis
/// « Reduire ». Pose en tete du panneau de personnes (enseignant) ou dans
/// le panneau des informations (eleve).
class SectionContexte extends StatefulWidget {
  /// Cree la section.
  const SectionContexte({required this.vue, required this.actions, super.key});

  /// La cle de la section.
  static const Key cle = ValueKey<String>('contexte-seance');

  /// La cle de la section du controle.
  static const Key cleControle = ValueKey<String>('contexte-controle');

  /// La cle de « Reduire ».
  static const Key cleReduire = ValueKey<String>('contexte-reduire');

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  State<SectionContexte> createState() => _SectionContexteState();
}

class _SectionContexteState extends State<SectionContexte> {
  final GlobalKey _controle = GlobalKey(debugLabel: 'contexte-controle');

  @override
  void initState() {
    super.initState();
    _amenerControle();
  }

  @override
  void didUpdateWidget(SectionContexte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.vue.contexte != widget.vue.contexte) _amenerControle();
  }

  /// L'oeil ouvre le panneau A LA SECTION du controle (CTX-02) : elle est
  /// amenee en haut de la liste du panneau. Seule la liste la plus proche
  /// defile : `Scrollable.ensureVisible` ferait aussi defiler les ancetres
  /// (le panneau entier quand il defile a 320 px a 200 %), et la tete du
  /// panneau (poignee, titre) sortirait de l'ecran.
  void _amenerControle() {
    if (widget.vue.contexte != ContexteOuvert.controle) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? section = _controle.currentContext;
      if (!mounted || section == null) return;
      final ScrollableState? liste = Scrollable.maybeOf(section);
      final RenderObject? cible = section.findRenderObject();
      if (liste == null || cible == null) return;
      liste.position.ensureVisible(cible);
    });
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle intitule = palette.inkMuted.applyTo(
      textes.labelLarge ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final VoidCallback? reseau = widget.actions.onReseau;
    final ValueChanged<ContexteOuvert>? contexte = widget.actions.onContexte;
    final String? controle = vue.texteControle;
    final String? explication = vue.explicationControle;
    // Chaque element garde son propre noeud : le lecteur d'ecran ne fond pas
    // le nom, le reseau et « Reduire » en un seul bouton.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: SectionContexte.cle,
        decoration: palette.surfaceOverlay.decoration(
          borderRadius: AppRadius.arrondiMd,
          side: palette.borderHairline.asBorderSide(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // L'enseignant, a taille normale (Sayyid ou Sayyida, §19.6).
              AvatarNom.enLigne(
                prenom: vue.nomEnseignant,
                styleNom: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
              Ecart.vMd,
              // Le reseau : l'etat de la connexion, et pour l'enseignant le
              // detail existant (la feuille de Classe Live), sorti du dock a
              // TB-2.
              TexteSansCoupure(t.salle.seance.contexte.reseau, style: intitule),
              Ecart.vXs,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  libelle: vue.texteConnexion,
                  ton: vue.connexion.etablie
                      ? TonEtat.succes
                      : TonEtat.avertissement,
                ),
              ),
              if (reseau != null) ...<Widget>[
                Ecart.vXs,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionPrincipale(
                    key: const ValueKey<String>('contexte-detail-reseau'),
                    libelle: t.salle.seance.contexte.detailReseau,
                    onPress: reseau,
                    niveau: NiveauAction.tertiaire,
                    pleineLargeur: false,
                  ),
                ),
              ],
              // L'enregistrement : seulement s'il est actif (§19.6).
              if (vue.voitPointEnregistrement) ...<Widget>[
                Ecart.vMd,
                Row(
                  key: const ValueKey<String>('contexte-enregistrement'),
                  children: <Widget>[
                    const PointEnregistrement(),
                    Ecart.hSm,
                    Expanded(
                      child: TexteSansCoupure(
                        t.salle.seance.contexte.enregistrementActif,
                        style: corps,
                      ),
                    ),
                  ],
                ),
              ],
              // Le controle : l'etat lu, jamais fabrique ; un controle
              // possible ne dit pas qu'une personne observe maintenant.
              if (controle != null) ...<Widget>[
                Ecart.vMd,
                KeyedSubtree(
                  key: _controle,
                  child: Semantics(
                    key: SectionContexte.cleControle,
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: TexteSansCoupure(
                            t.salle.seance.contexte.controle,
                            style: intitule,
                          ),
                        ),
                        Ecart.vXs,
                        Row(
                          children: <Widget>[
                            IconTheme(
                              data: palette.inkStrong.asIconTheme(
                                size: AppSpacing.xl,
                              ),
                              child: Icon(AppIcons.observationEnCours.repos),
                            ),
                            Ecart.hSm,
                            Expanded(
                              child: TexteSansCoupure(controle, style: corps),
                            ),
                          ],
                        ),
                        if (explication != null) ...<Widget>[
                          Ecart.vXs,
                          TexteSansCoupure(
                            explication,
                            style: palette.inkMuted.applyTo(
                              textes.bodySmall ?? const TextStyle(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (contexte != null) ...<Widget>[
                Ecart.vMd,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ActionPrincipale(
                    key: SectionContexte.cleReduire,
                    libelle: t.salle.seance.contexte.reduire,
                    libelleSemantique: vue.libelleReduireContexte,
                    onPress: () => contexte(ContexteOuvert.aucun),
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
