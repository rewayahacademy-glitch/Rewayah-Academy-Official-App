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
enum _Etat { repos, envoi, enregistree, echec }

/// « Choisir une photo » pour sa propre photo (PHOTOS-2a, PLAN-LOTS §11,
/// point 3) : le tuteur depuis son Compte, l'eleve adulte depuis Mon espace,
/// la direction depuis son compte. Le fichier part dans son propre dossier,
/// `poser_ma_photo` l'enregistre, et toutes les vues de sa photo sont relues
/// (`photoPersonneProvider`). Une action secondaire : un lien, jamais un
/// bouton plein (K-56). Les textes sont ceux de la photo d'un enfant.
class LienMaPhoto extends ConsumerStatefulWidget {
  /// Cree le lien.
  const LienMaPhoto({super.key});

  /// La cle du lien, pour les tests et le robot.
  static const Key choisirKey = Key('maPhoto.choisir');

  @override
  ConsumerState<LienMaPhoto> createState() => _LienMaPhotoState();
}

class _LienMaPhotoState extends ConsumerState<LienMaPhoto> {
  _Etat _etat = _Etat.repos;
  String? _refus;

  Future<void> _choisir(String moi) async {
    setState(() {
      _refus = null;
      _etat = _Etat.repos;
    });
    final PhotoEnfant? photo;
    try {
      photo = await ref.read(selecteurPhotoProvider).choisirPhoto();
    } on Object {
      if (mounted) {
        setState(() => _refus = t.ficheEleve.informations.selectionEchec);
      }
      return;
    }
    if (!mounted || photo == null) return;
    if (photo.octets.lengthInBytes > ServiceAvatar.tailleMaximaleOctets) {
      setState(
        () => _refus = t.ficheEleve.informations.tropLourde(
          taille: '${ServiceAvatar.tailleMaximaleOctets ~/ (1024 * 1024)}',
        ),
      );
      return;
    }
    setState(() => _etat = _Etat.envoi);
    try {
      await envoyerMaPhoto(ref, moi: moi, photo: photo);
    } on Object {
      if (mounted) setState(() => _etat = _Etat.echec);
      return;
    }
    if (mounted) setState(() => _etat = _Etat.enregistree);
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
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? message = switch (_etat) {
      _Etat.envoi => t.ficheEleve.informations.etapeEnvoi,
      _Etat.enregistree => t.ficheEleve.informations.photoPresente,
      _Etat.echec => t.ficheEleve.informations.echecEnvoi,
      _Etat.repos => null,
    };
    final String? refus = _refus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (horsLigne)
          Text(
            t.ficheEleve.informations.horsLigne,
            style: palette.inkMuted.applyTo(corps),
          )
        else if (_etat != _Etat.envoi)
          LienFleche(
            key: LienMaPhoto.choisirKey,
            libelle: t.ficheEleve.informations.choisir,
            onPress: () => _choisir(moi),
          ),
        if (message != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style:
                  (_etat == _Etat.echec ? palette.inkAlert : palette.inkMuted)
                      .applyTo(corps),
            ),
          ),
        ],
        if (refus != null) ...<Widget>[
          Ecart.vSm,
          Text(refus, style: palette.inkAlert.applyTo(corps)),
        ],
      ],
    );
  }
}
