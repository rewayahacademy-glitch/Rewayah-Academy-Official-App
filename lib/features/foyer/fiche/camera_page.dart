import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appairage/service_appairage.dart';
import '../../../core/domain/enums.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../fiche_eleve_page.dart';

/// La camera en cours d'un profil eleve (`/tuteur/foyer/:eleveId/camera`).
///
/// Rendu des lignes a interrupteur de l'Apparence haute fidelite (« Confort
/// visuel », manifeste visuel section 2) : titre, legende qui dit la
/// consequence avec le prenom, interrupteur. La valeur est
/// `student_profiles.camera_policy`, lue par le serveur a chaque entree en
/// seance (`autoriser_jeton_video`, `0033_tc_vues_rpc.sql:1723-1730`) : le
/// changement compte donc a la prochaine entree, et l'ecran le dit.
///
/// **Distinct de la permission camera de l'appareil** (celle que le scanner
/// de QR code demande, lot D) : l'ecran le dit aussi.
///
/// **Aucun etat optimiste** : l'interrupteur montre ce que la relecture du
/// foyer rend ; pendant l'ecriture il ne se presse plus.
class CameraElevePage extends StatelessWidget {
  /// Cree la page.
  const CameraElevePage({required this.eleveId, super.key});

  /// L'eleve concerne.
  final String eleveId;

  /// L'interrupteur.
  static const Key interrupteurKey = Key('ficheEleve.camera.interrupteur');

  @override
  Widget build(BuildContext context) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.camera.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _ReglageCamera(profil: profil),
    );
  }
}

class _ReglageCamera extends ConsumerStatefulWidget {
  const _ReglageCamera({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  ConsumerState<_ReglageCamera> createState() => _ReglageCameraState();
}

class _ReglageCameraState extends ConsumerState<_ReglageCamera> {
  bool _enCours = false;
  bool _echec = false;

  Future<void> _basculer(bool autoriser) async {
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(serviceAppairageProvider)
          .majReglages(
            eleveId: widget.profil.eleveId,
            camera: autoriser ? CameraPolicy.allowed : CameraPolicy.forbidden,
          );
      ref.invalidate(elevesDuFoyerProvider);
    } on Object {
      if (mounted) {
        setState(() => _echec = true);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ProfilEleveFoyer profil = widget.profil;
    final bool autorisee = profil.camera == CameraPolicy.allowed;

    return ColonnesFiche(
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.camera,
                libelle: t.ficheEleve.camera.ligne,
                legende: autorisee
                    ? t.ficheEleve.camera.autorisee(prenom: profil.prenom)
                    : t.ficheEleve.camera.interdite(prenom: profil.prenom),
                controle: Switch.adaptive(
                  key: CameraElevePage.interrupteurKey,
                  value: autorisee,
                  onChanged: _enCours ? null : _basculer,
                ),
              ),
            ],
          ),
          if (_echec) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                t.ficheEleve.camera.echec,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ],
      ),
      annexe: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NoteFiche(t.ficheEleve.camera.application(prenom: profil.prenom)),
          NoteFiche(t.ficheEleve.camera.distincte),
        ],
      ),
    );
  }
}
