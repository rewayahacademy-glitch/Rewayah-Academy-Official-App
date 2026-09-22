import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import '../salle/vue_salle.dart';

/// Ce qu'un peripherique local est, ici et maintenant.
///
/// **Six etats, et ils ne se confondent jamais** (Bible V2 section 34, lot 2
/// section 12) : un micro ferme par choix, un micro que le systeme refuse et un
/// micro qui n'existe pas sont trois situations qui se reparent a trois
/// endroits differents. Un seul bouton grise les melangerait.
enum EtatPeripherique {
  /// Present, ferme par choix. C'est l'etat d'entree, pour tout le monde.
  ferme,

  /// Present, ouvert par choix.
  ouvert,

  /// Le pre-vol n'a trouve aucun peripherique de ce type.
  absent,

  /// Le systeme ou le navigateur refuse l'acces. Se repare dans les reglages
  /// de l'appareil, pas ici.
  permissionRefusee,

  /// Un reglage est en attente du moteur.
  enCours,

  /// Le moteur a refuse le dernier reglage.
  erreur,
}

/// Calcule l'etat d'un peripherique.
///
/// **Fonction pure**, verifiable sans ecran. L'ordre est celui de la verite :
/// un reglage en cours passe devant tout, une panne devant une permission, une
/// permission devant une absence, et l'etat publie par le moteur ne se lit
/// qu'en dernier.
EtatPeripherique etatPeripherique({
  required bool ouvert,
  required bool disponible,
  required bool permissionRefusee,
  required bool enCours,
  required bool erreur,
}) {
  if (enCours) {
    return EtatPeripherique.enCours;
  }
  if (erreur) {
    return EtatPeripherique.erreur;
  }
  if (permissionRefusee) {
    return EtatPeripherique.permissionRefusee;
  }
  if (!disponible) {
    return EtatPeripherique.absent;
  }
  return ouvert ? EtatPeripherique.ouvert : EtatPeripherique.ferme;
}

/// Vrai quand un appui aurait un effet.
bool peripheriqueReglable(EtatPeripherique etat) =>
    etat == EtatPeripherique.ferme || etat == EtatPeripherique.ouvert;

/// Une commande ronde : un cercle, une icone, un mot court, et l'acte pour qui
/// ecoute.
///
/// **Le mot visible est court** (« Micro ») parce que quatre libelles complets
/// ne tiennent pas sur 390 points. **Le libelle parle dit l'ACTE** (« Ouvrir le
/// micro »), parce qu'un bouton se lit par ce qu'il declenche. L'etat se lit par
/// la FORME -- l'icone change, le cercle se remplit -- jamais par la couleur
/// seule (invariant J7). Reprise de la salle du lot N3, dont c'etait la bonne
/// forme.
class CommandeRonde extends StatelessWidget {
  /// Cree une commande.
  const CommandeRonde({
    required this.icone,
    required this.libelle,
    required this.acte,
    required this.actif,
    required this.onPress,
    super.key,
  });

  /// L'icone, resolue selon [actif].
  final AppIcon icone;

  /// Le mot court, sous le cercle.
  final String libelle;

  /// L'acte, pour les technologies d'assistance.
  final String acte;

  /// Vrai quand le cercle se remplit.
  final bool actif;

  /// `null` rend la commande inerte, avec son mot : ce n'est pas une limite de
  /// droit (qui, elle, cache le bouton), c'est une panne locale a lire.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair ouverte = palette.surfaceRaised;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Pressable(
        onPress: onPress,
        libelleSemantique: acte,
        arrondiFocus: AppRadius.arrondiFull,
        child: SizedBox(
          // Assez pour deux lignes de mot court a 200 % de texte, et la meme
          // largeur pour les quatre commandes : l'oeil les compte d'un coup.
          width: AppSpacing.respiration + AppSpacing.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: metriques.cibleTactile,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: actif ? ouverte.background : null,
                    border: actif
                        ? null
                        : Border.fromBorderSide(
                            palette.borderStrong.asBorderSide(),
                          ),
                  ),
                  child: Center(
                    child: Icon(
                      icone.resoudre(selectionne: actif),
                      color: actif ? ouverte.onBackground : null,
                    ),
                  ),
                ),
              ),
              Ecart.vXs,
              Text(
                libelle,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: textes.labelSmall ?? const TextStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La barre basse de la Classe Live : micro, camera, Bibliotheque, Quitter.
///
/// **Le nombre de commandes decoule du jeton, jamais du mode d'interface.** Un
/// controle que le jeton refuse n'est PAS rendu, et n'est jamais grise. Un
/// peripherique absent ou refuse, lui, est rendu inerte **avec son mot** : ce
/// n'est pas une limite de droit, c'est une panne locale, et la cacher ferait
/// croire a l'enfant que sa camera n'existe pas.
///
/// L'etat reseau ne se dit ici que quand il change quelque chose : « instable »
/// et « perdu ». « Reseau bon » pendant un cours n'apporte rien et occuperait
/// la place que le Coran prendra (`VueSalle.lienADire`).
class CommandesClasse extends StatelessWidget {
  /// Cree la barre.
  const CommandesClasse({
    required this.salle,
    required this.preVol,
    required this.microEnCours,
    required this.cameraEnCours,
    required this.microErreur,
    required this.cameraErreur,
    required this.peutOuvrirBibliotheque,
    required this.onBibliotheque,
    required this.onMicro,
    required this.onCamera,
    required this.onQuitter,
    super.key,
  });

  /// La salle, lue du jeton.
  final VueSalle salle;

  /// La derniere mesure du materiel. `null` avant la premiere.
  final ResultatPreVol? preVol;

  /// Un reglage de micro attend le moteur.
  final bool microEnCours;

  /// Un reglage de camera attend le moteur.
  final bool cameraEnCours;

  /// Le moteur a refuse le dernier reglage de micro.
  final bool microErreur;

  /// Le moteur a refuse le dernier reglage de camera.
  final bool cameraErreur;

  /// Le jeton permet de presenter, donc d'ouvrir la Bibliotheque.
  final bool peutOuvrirBibliotheque;

  /// Ouvre la Bibliotheque, sans quitter la room.
  final VoidCallback onBibliotheque;

  /// Bascule le micro. Recoit l'etat courant.
  final Future<void> Function(bool ouvert) onMicro;

  /// Bascule la camera. Recoit l'etat courant.
  final Future<void> Function(bool ouverte) onCamera;

  /// La sortie volontaire.
  final VoidCallback onQuitter;

  @override
  Widget build(BuildContext context) {
    final bool enSalle = salle.dansLaSalle;
    final EtatPeripherique micro = etatPeripherique(
      ouvert: salle.moi?.micro ?? false,
      disponible: preVol?.microDisponible ?? true,
      permissionRefusee: preVol?.permissionRefusee ?? false,
      enCours: microEnCours,
      erreur: microErreur,
    );
    final EtatPeripherique camera = etatPeripherique(
      ouvert: salle.moi?.camera ?? false,
      disponible: preVol?.cameraDisponible ?? true,
      permissionRefusee: preVol?.permissionRefusee ?? false,
      enCours: cameraEnCours,
      erreur: cameraErreur,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (salle.peutParler)
          CommandeRonde(
            icone: micro == EtatPeripherique.ouvert
                ? AppIcons.micro
                : AppIcons.microCoupe,
            libelle: _motMicro(micro),
            acte: micro == EtatPeripherique.ouvert
                ? t.tc.classe.commandes.microFermer
                : t.tc.classe.commandes.micro,
            actif: micro == EtatPeripherique.ouvert,
            onPress: enSalle && peripheriqueReglable(micro)
                ? () => unawaited(onMicro(micro == EtatPeripherique.ouvert))
                : null,
          ),
        if (salle.peutMontrer)
          CommandeRonde(
            icone: camera == EtatPeripherique.ouvert
                ? AppIcons.camera
                : AppIcons.cameraCoupee,
            libelle: _motCamera(camera),
            acte: camera == EtatPeripherique.ouvert
                ? t.tc.classe.commandes.cameraFermer
                : t.tc.classe.commandes.camera,
            actif: camera == EtatPeripherique.ouvert,
            onPress: enSalle && peripheriqueReglable(camera)
                ? () => unawaited(onCamera(camera == EtatPeripherique.ouvert))
                : null,
          ),
        if (peutOuvrirBibliotheque)
          CommandeRonde(
            icone: AppIcons.bibliotheque,
            libelle: t.tc.classe.support.bibliotheque,
            acte: t.tc.classe.commandes.ouvrirBibliotheque,
            actif: false,
            onPress: enSalle ? onBibliotheque : null,
          ),
        // La sortie : evidente, mais moins dominante qu'une action
        // pedagogique. Sa place en dernier et son mot la distinguent ; aucun
        // aplat rouge (regle de la zone pleine unique).
        CommandeRonde(
          icone: AppIcons.sortie,
          libelle: t.tc.classe.commandes.quitter,
          acte: t.tc.classe.commandes.quitterQuestion,
          actif: false,
          onPress: onQuitter,
        ),
        if (salle.lienADire)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: StatusPill(
              libelle: salle.qualite == QualiteLien.perdue
                  ? t.tc.classe.reseau.perdu
                  : t.tc.classe.reseau.mediocre,
              ton: salle.qualite == QualiteLien.perdue
                  ? TonEtat.alerte
                  : TonEtat.avertissement,
            ),
          ),
      ],
    );
  }

  static String _motMicro(EtatPeripherique etat) => switch (etat) {
    EtatPeripherique.ferme ||
    EtatPeripherique.ouvert => t.tc.classe.commandes.microCourt,
    EtatPeripherique.absent => t.tc.classe.commandes.microAbsent,
    EtatPeripherique.permissionRefusee =>
      t.tc.classe.commandes.permissionRefusee,
    EtatPeripherique.enCours => t.tc.classe.commandes.reglageEnCours,
    EtatPeripherique.erreur => t.tc.classe.commandes.indisponible,
  };

  static String _motCamera(EtatPeripherique etat) => switch (etat) {
    EtatPeripherique.ferme ||
    EtatPeripherique.ouvert => t.tc.classe.commandes.cameraCourt,
    EtatPeripherique.absent => t.tc.classe.commandes.cameraAbsente,
    EtatPeripherique.permissionRefusee =>
      t.tc.classe.commandes.permissionRefusee,
    EtatPeripherique.enCours => t.tc.classe.commandes.reglageEnCours,
    EtatPeripherique.erreur => t.tc.classe.commandes.indisponible,
  };
}
