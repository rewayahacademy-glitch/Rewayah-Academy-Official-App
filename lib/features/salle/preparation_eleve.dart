// PRE-ELV-01 et PRE-ERR-01 : la preparation de l'eleve (CL-4.6).
//
// Document du directeur §7, spec 02 P01 et P02, regles R8 a R13 et R19.
// Presque silencieuse : un etat calme pendant les verifications, un ecran
// minimal quand tout va bien, et un arret seulement sur un vrai blocage.
// Le blocage vient de `VuePreCours.depuis(role: eleve)`, seule source : il
// n'est pas recalcule ici. Aucune entree automatique (revue UX n° 13 a) : un
// seul appui sur « Entrer dans la classe ».

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../salle_seance/feuille_micro_bloque.dart';
import '../tc_classe_live/pre_vol_classe.dart';
import 'preparation_enseignant.dart';
import 'vue_salle.dart';

/// Ce que la preparation de l'eleve montre.
enum PhasePreparationEleve {
  /// Les verifications tournent : un seul etat calme.
  verification,

  /// Tout est pret : l'ecran minimal.
  pret,

  /// Le micro n'est pas accessible (PRE-ERR-01).
  microBloque,

  /// Aucune connexion.
  horsLigne,
}

/// Calcule la phase. Fonction pure : le blocage vient de [VuePreCours].
PhasePreparationEleve phasePreparationEleve({
  required ResultatPreVol? resultat,
  required ReseauPreparation? reseau,
}) {
  if (reseau == ReseauPreparation.horsLigne) {
    return PhasePreparationEleve.horsLigne;
  }
  final VuePreCours vue = VuePreCours.depuis(
    role: RoleSalle.eleve,
    resultat: resultat,
  );
  if (vue.bloque) return PhasePreparationEleve.microBloque;
  if (resultat == null || reseau == null) {
    return PhasePreparationEleve.verification;
  }
  return PhasePreparationEleve.pret;
}

/// Largeur a partir de laquelle le bouton garde la largeur de son libelle.
const double _seuilBoutonEtire = 600;

/// La preparation de l'eleve.
class PreparationEleve extends StatefulWidget {
  /// Cree la preparation.
  const PreparationEleve({
    required this.resultat,
    required this.reseau,
    required this.onEntrer,
    required this.onContinuerSansMicro,
    required this.onReessayer,
    required this.onRetour,
    super.key,
    this.guidee = false,
    this.onOuvrirReglages,
  });

  /// Le materiel mesure, `null` pendant la verification.
  final ResultatPreVol? resultat;

  /// La connexion, `null` pendant la verification.
  final ReseauPreparation? reseau;

  /// Interface guidee (`InterfaceMode.enfant`) : une question, une action.
  final bool guidee;

  /// Entre dans la classe, micro coupe (R8).
  final VoidCallback onEntrer;

  /// Entre sans micro : le micro reste coupe.
  final VoidCallback onContinuerSansMicro;

  /// Remesure le materiel et la connexion.
  final VoidCallback onReessayer;

  /// Revient a la Classe (ou a l'accueil en Interface guidee).
  final VoidCallback onRetour;

  /// Ouvre les reglages systeme, seulement si une vraie action existe
  /// (aucun paquet de permission avant BR-1).
  final VoidCallback? onOuvrirReglages;

  @override
  State<PreparationEleve> createState() => _PreparationEleveEtat();
}

class _PreparationEleveEtat extends State<PreparationEleve> {
  final FocusNode _focusAutoriser = FocusNode(debugLabel: 'autoriser-micro');

  @override
  void dispose() {
    _focusAutoriser.dispose();
    super.dispose();
  }

  /// « Autoriser le micro » : la feuille micro de CL-7. Elle prend le focus
  /// a l'ouverture ; il revient au bouton a la fermeture.
  Future<void> _autoriser() async {
    final VoidCallback? reglages = widget.onOuvrirReglages;
    final _Choix? choix = await AppBottomSheet.ouvrir<_Choix>(
      context,
      titre: t.salle.micro,
      constructeur: (BuildContext contexte) => Text(
        widget.guidee
            ? t.salle.secours.microBloqueGuidee
            : t.salle.secours.microBloque,
        key: const ValueKey<String>('texte-micro-bloque'),
        style: AppPalette.of(contexte).surfaceRaised.applyTo(
          Theme.of(contexte).textTheme.bodyLarge ?? const TextStyle(),
        ),
      ),
      actions: (BuildContext contexte) => ActionsMicroBloque(
        avecReglages: reglages != null,
        onContinuer: () => Navigator.of(contexte).pop(_Choix.continuer),
        onReglages: () => Navigator.of(contexte).pop(_Choix.reglages),
      ),
    );
    if (!mounted) return;
    switch (choix) {
      case _Choix.continuer:
        widget.onContinuerSansMicro();
        return;
      case _Choix.reglages:
        reglages?.call();
      case null:
        break;
    }
    // Le focus revient au bouton lui-meme, pas a son enveloppe.
    for (final FocusNode noeud in _focusAutoriser.descendants) {
      if (noeud.canRequestFocus) {
        noeud.requestFocus();
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final PhasePreparationEleve phase = phasePreparationEleve(
      resultat: widget.resultat,
      reseau: widget.reseau,
    );
    final double facteur = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool etire = contraintes.maxWidth / facteur < _seuilBoutonEtire;
        final double gouttiere = etire
            ? AppPage.gouttiereMobile
            : AppPage.gouttiereDesktop;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: gouttiere,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurFormulaire,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LienFleche(
                      key: const ValueKey<String>('preparation-retour'),
                      libelle: widget.guidee
                          ? t.salle.retourAccueil
                          : t.salle.preparation.retour,
                      icone: AppIcons.retour,
                      fleche: false,
                      onPress: widget.onRetour,
                    ),
                  ),
                  Ecart.vLg,
                  AppCard(
                    child: widget.guidee
                        ? _guidee(context, phase, etire)
                        : _standard(context, phase, etire),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Le titre d'etat. Seuls les etats finaux sont une region live : une
  /// seule annonce, a la fin des verifications (revue UX n° 13 b).
  Widget _titre(BuildContext context, String texte, {required bool annonce}) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      header: true,
      liveRegion: annonce,
      child: Text(
        texte,
        key: const ValueKey<String>('preparation-eleve-titre'),
        style: palette.inkStrong.applyTo(
          (annonce ? textes.titleLarge : textes.titleMedium) ??
              const TextStyle(),
        ),
      ),
    );
  }

  Widget _texte(BuildContext context, String texte) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(textes.bodyMedium ?? const TextStyle()),
    );
  }

  /// Le bouton principal, au bord de fin ; pleine largeur sur mobile.
  Widget _principal({
    required Key cle,
    required String libelle,
    required VoidCallback onPress,
    required bool etire,
    FocusNode? focus,
  }) {
    final Widget bouton = ActionPrincipale(
      key: cle,
      libelle: libelle,
      onPress: onPress,
      pleineLargeur: etire,
    );
    final Widget focalisable = focus == null
        ? bouton
        : Focus(focusNode: focus, skipTraversal: true, child: bouton);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      widthFactor: etire ? null : 1,
      child: etire ? focalisable : IntrinsicWidth(child: focalisable),
    );
  }

  Widget _actionsBlocage(bool etire, {required NiveauAction niveauContinuer}) {
    final bool autoriser =
        VuePreCours.depuis(
          role: RoleSalle.eleve,
          resultat: widget.resultat,
        ).motif ==
        MotifPreCours.permissionRefusee;
    final Widget continuer = ActionPrincipale(
      key: const ValueKey<String>('preparation-continuer-sans-micro'),
      libelle: t.salle.secours.continuerSansMicro,
      onPress: widget.onContinuerSansMicro,
      niveau: niveauContinuer,
      pleineLargeur: false,
    );
    final Widget principal = autoriser
        ? _principal(
            cle: const ValueKey<String>('preparation-autoriser-micro'),
            libelle: t.salle.preparation.eleve.autoriserMicro,
            onPress: _autoriser,
            etire: etire,
            focus: _focusAutoriser,
          )
        : _principal(
            cle: const ValueKey<String>('preparation-reessayer'),
            libelle: t.salle.preparation.reessayer,
            onPress: widget.onReessayer,
            etire: etire,
          );
    // Large : une rangee au bord de fin, le principal en dernier (contrat
    // B). Mobile : le principal en pleine largeur, le secondaire dessous.
    if (!etire) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          IntrinsicWidth(child: continuer),
          principal,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        principal,
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: IntrinsicWidth(child: continuer),
        ),
      ],
    );
  }

  Widget _standard(
    BuildContext context,
    PhasePreparationEleve phase,
    bool etire,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (phase) {
        PhasePreparationEleve.verification ||
        PhasePreparationEleve.pret => <Widget>[
          _titre(
            context,
            phase == PhasePreparationEleve.pret
                ? t.salle.preparation.eleve.pret
                : t.salle.preparation.eleve.verification,
            annonce: phase == PhasePreparationEleve.pret,
          ),
          Ecart.vLg,
          _Lignes(resultat: widget.resultat, reseau: widget.reseau),
          if (phase == PhasePreparationEleve.pret) ...<Widget>[
            Ecart.vLg,
            _texte(context, t.salle.preparation.eleve.microCoupe),
            Ecart.vXl,
            _principal(
              cle: const ValueKey<String>('preparation-entrer'),
              libelle: t.salle.preparation.entrer,
              onPress: widget.onEntrer,
              etire: etire,
            ),
          ],
        ],
        PhasePreparationEleve.microBloque => <Widget>[
          _titre(
            context,
            t.salle.preparation.eleve.microInaccessible,
            annonce: true,
          ),
          Ecart.vMd,
          _texte(context, t.salle.preparation.eleve.microInaccessibleDetail),
          Ecart.vXl,
          _actionsBlocage(etire, niveauContinuer: NiveauAction.secondaire),
        ],
        PhasePreparationEleve.horsLigne => <Widget>[
          _titre(context, t.salle.secours.horsLigne, annonce: true),
          Ecart.vXl,
          _principal(
            cle: const ValueKey<String>('preparation-reessayer'),
            libelle: t.salle.preparation.reessayer,
            onPress: widget.onReessayer,
            etire: etire,
          ),
        ],
      },
    );
  }

  /// Interface guidee (P02) : une phrase, une seule action principale, sans
  /// liste technique.
  Widget _guidee(
    BuildContext context,
    PhasePreparationEleve phase,
    bool etire,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (phase) {
        PhasePreparationEleve.verification => <Widget>[
          _titre(
            context,
            t.salle.preparation.eleve.guidee.verification,
            annonce: false,
          ),
        ],
        PhasePreparationEleve.pret => <Widget>[
          _titre(context, t.salle.preparation.eleve.guidee.pret, annonce: true),
          Ecart.vMd,
          _texte(context, t.salle.preparation.eleve.guidee.microCoupe),
          Ecart.vXl,
          _principal(
            cle: const ValueKey<String>('preparation-entrer'),
            libelle: t.salle.preparation.entrer,
            onPress: widget.onEntrer,
            etire: etire,
          ),
        ],
        PhasePreparationEleve.microBloque => <Widget>[
          _titre(
            context,
            t.salle.preparation.eleve.guidee.microQuestion,
            annonce: true,
          ),
          Ecart.vXl,
          _actionsBlocage(etire, niveauContinuer: NiveauAction.tertiaire),
        ],
        PhasePreparationEleve.horsLigne => <Widget>[
          _titre(
            context,
            t.salle.preparation.eleve.guidee.horsLigne,
            annonce: true,
          ),
          Ecart.vXl,
          _principal(
            cle: const ValueKey<String>('preparation-reessayer'),
            libelle: t.salle.preparation.reessayer,
            onPress: widget.onReessayer,
            etire: etire,
          ),
        ],
      },
    );
  }
}

enum _Choix { continuer, reglages }

/// Connexion, Audio, Acces a la classe : chaque ligne evolue seule (R19).
class _Lignes extends StatelessWidget {
  const _Lignes({required this.resultat, required this.reseau});

  final ResultatPreVol? resultat;
  final ReseauPreparation? reseau;

  @override
  Widget build(BuildContext context) {
    final String verif = t.salle.preparation.verification;
    final (String, TonPreparation) connexion = switch (reseau) {
      null => (verif, TonPreparation.verification),
      ReseauPreparation.bonne => (
        t.salle.preparation.connexionPrete,
        TonPreparation.ok,
      ),
      ReseauPreparation.instable => (
        t.salle.preparation.connexionInstable,
        TonPreparation.attention,
      ),
      ReseauPreparation.horsLigne => (
        t.salle.preparation.connexionInstable,
        TonPreparation.bloque,
      ),
    };
    final (String, TonPreparation) audio = resultat == null
        ? (verif, TonPreparation.verification)
        : (t.salle.preparation.microPret, TonPreparation.ok);
    final (String, TonPreparation) acces = switch (reseau) {
      null => (verif, TonPreparation.verification),
      ReseauPreparation.horsLigne => (
        t.salle.preparation.eleve.accesAttente,
        TonPreparation.attention,
      ),
      ReseauPreparation.bonne || ReseauPreparation.instable => (
        t.salle.preparation.eleve.accesOk,
        TonPreparation.ok,
      ),
    };

    LigneRubrique ligne(
      String cle,
      AppIcon icone,
      String libelle,
      (String, TonPreparation) etat,
    ) => LigneRubrique(
      icone: icone,
      libelle: libelle,
      legende: etat.$1,
      controle: KeyedSubtree(
        key: ValueKey<String>('etat-$cle-${etat.$2.name}'),
        child: IconeEtatPreparation(ton: etat.$2),
      ),
    );

    return GroupeReglages(
      lignes: <LigneRubrique>[
        ligne(
          'connexion',
          AppIcons.reseau,
          t.salle.preparation.connexion,
          connexion,
        ),
        ligne('audio', AppIcons.micro, t.salle.preparation.eleve.audio, audio),
        ligne('acces', AppIcons.succes, t.salle.preparation.eleve.acces, acces),
      ],
    );
  }
}
