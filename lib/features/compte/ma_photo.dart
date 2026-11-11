import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/service_avatar.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/photos/photo_personne.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';

/// Ou en est l'envoi de sa propre photo.
enum EtapeMaPhoto {
  /// Rien en cours.
  repos,

  /// La photo part.
  envoi,

  /// La photo est enregistree.
  enregistree,

  /// L'envoi a echoue.
  echec,
}

/// L'etat de l'envoi : l'etape, et un refus a dire (fichier illisible ou trop
/// lourd).
@immutable
class EtatMaPhoto {
  /// Cree l'etat.
  const EtatMaPhoto({this.etape = EtapeMaPhoto.repos, this.refus});

  /// L'etape.
  final EtapeMaPhoto etape;

  /// Le refus a dire, ou `null`.
  final String? refus;
}

/// Le choix et l'envoi de sa propre photo (PHOTOS-2a), partage par le lien
/// « Choisir une photo » et par la photo pressable de l'en-tete du Compte
/// (PROFILS P4) : une seule logique, deux gestes.
class EnvoiMaPhoto extends ValueNotifier<EtatMaPhoto> {
  /// Cree l'envoi, au repos.
  EnvoiMaPhoto() : super(const EtatMaPhoto());

  /// Ouvre le choix du fichier, puis envoie la photo de [moi].
  Future<void> choisir(WidgetRef ref, String moi) async {
    value = const EtatMaPhoto();
    final PhotoEnfant? photo;
    try {
      photo = await ref.read(selecteurPhotoProvider).choisirPhoto();
    } on Object {
      value = EtatMaPhoto(refus: t.ficheEleve.informations.selectionEchec);
      return;
    }
    if (photo == null) return;
    if (photo.octets.lengthInBytes > ServiceAvatar.tailleMaximaleOctets) {
      value = EtatMaPhoto(
        refus: t.ficheEleve.informations.tropLourde(
          taille: '${ServiceAvatar.tailleMaximaleOctets ~/ (1024 * 1024)}',
        ),
      );
      return;
    }
    value = const EtatMaPhoto(etape: EtapeMaPhoto.envoi);
    try {
      await envoyerMaPhoto(ref, moi: moi, photo: photo);
    } on Object {
      value = const EtatMaPhoto(etape: EtapeMaPhoto.echec);
      return;
    }
    value = const EtatMaPhoto(etape: EtapeMaPhoto.enregistree);
  }
}

/// Le retour de l'envoi : l'etape en cours ou finie, puis le refus. Rien au
/// repos. Hors ligne, la phrase qui dit que la photo attendra le reseau.
class RetourMaPhoto extends StatelessWidget {
  /// Cree le retour.
  const RetourMaPhoto({required this.etat, this.horsLigne = false, super.key});

  /// L'etat de l'envoi.
  final EtatMaPhoto etat;

  /// Le reseau est absent.
  final bool horsLigne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final String? message = switch (etat.etape) {
      EtapeMaPhoto.envoi => t.ficheEleve.informations.etapeEnvoi,
      EtapeMaPhoto.enregistree => t.ficheEleve.informations.photoPresente,
      EtapeMaPhoto.echec => t.ficheEleve.informations.echecEnvoi,
      EtapeMaPhoto.repos => null,
    };
    final String? refus = etat.refus;
    final List<Widget> morceaux = <Widget>[
      if (horsLigne)
        Text(
          t.ficheEleve.informations.horsLigne,
          style: palette.inkMuted.applyTo(corps),
        ),
      if (message != null)
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            style:
                (etat.etape == EtapeMaPhoto.echec
                        ? palette.inkAlert
                        : palette.inkMuted)
                    .applyTo(corps),
          ),
        ),
      if (refus != null) Text(refus, style: palette.inkAlert.applyTo(corps)),
    ];
    if (morceaux.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: morceaux,
    );
  }
}

/// « Choisir une photo » pour sa propre photo (PHOTOS-2a, PLAN-LOTS §11,
/// point 3) : le tuteur depuis son Compte, l'eleve adulte depuis Mon espace.
/// Le fichier part dans son propre dossier, `poser_ma_photo` l'enregistre, et
/// toutes les vues de sa photo sont relues (`photoPersonneProvider`). Une
/// action secondaire : un lien, jamais un bouton plein (K-56). Les textes sont
/// ceux de la photo d'un enfant.
class LienMaPhoto extends ConsumerStatefulWidget {
  /// Cree le lien.
  const LienMaPhoto({super.key});

  /// La cle du lien, pour les tests et le robot.
  static const Key choisirKey = Key('maPhoto.choisir');

  @override
  ConsumerState<LienMaPhoto> createState() => _LienMaPhotoState();
}

class _LienMaPhotoState extends ConsumerState<LienMaPhoto> {
  final EnvoiMaPhoto _envoi = EnvoiMaPhoto();

  @override
  void dispose() {
    _envoi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? moi = ref.watch(
      sessionProvider.select((SessionState e) => e.profileId),
    );
    if (moi == null) return const SizedBox.shrink();
    // PHOTO-CAPACITE (fiche §11, « Qui pose la photo » : l'enfant ne la
    // change pas) : le lien se lit sur la capacite servie par le serveur
    // (`photo_adulte_moi()`, la regle meme de `poser_ma_photo`), jamais sur
    // un role ni sur l'Interface guidee. Cache tant qu'elle n'est pas lue,
    // et en cas d'erreur.
    if (ref.watch(peutPoserMaPhotoProvider).value != true) {
      return const SizedBox.shrink();
    }
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return ValueListenableBuilder<EtatMaPhoto>(
      valueListenable: _envoi,
      builder: (BuildContext _, EtatMaPhoto etat, Widget? _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!horsLigne && etat.etape != EtapeMaPhoto.envoi) ...<Widget>[
            LienFleche(
              key: LienMaPhoto.choisirKey,
              libelle: t.ficheEleve.informations.choisir,
              onPress: () => _envoi.choisir(ref, moi),
            ),
            if (etat.etape != EtapeMaPhoto.repos || etat.refus != null)
              Ecart.vSm,
          ],
          RetourMaPhoto(etat: etat, horsLigne: horsLigne),
        ],
      ),
    );
  }
}
