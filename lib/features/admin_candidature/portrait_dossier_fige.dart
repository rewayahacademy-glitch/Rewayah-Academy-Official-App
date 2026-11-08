import 'package:flutter/material.dart';

import '../../core/widgets/avatar_tile.dart';

/// Le portrait de la photo FIGEE du dossier de candidature (PHOTO-CANDIDATURE-FIGEE).
///
/// Ce n'est pas la photo d'une personne, c'est un objet précis du dossier : la
/// photo envoyée avec la candidature, qui ne suit jamais la photo d'affichage
/// de la personne. Elle ne se lit donc pas par `photoPersonneProvider(id)`
/// (qui rendrait la photo du jour, le défaut que ce lot corrige) : l'URL signée
/// vient de `photoDossierProvider`, source unique de cette photo.
///
/// Ce composant est le seul de l'écran à transmettre une URL à un portrait ;
/// `test/tool/photos_par_id_test.dart` le nomme parmi les composants.
class PortraitDossierFige extends StatelessWidget {
  /// Crée le portrait.
  const PortraitDossierFige({
    required this.nomComplet,
    required this.urlSignee,
    super.key,
  });

  /// Le nom, pour le repli sur les initiales.
  final String nomComplet;

  /// L'URL signée de courte durée de la photo figée.
  final String urlSignee;

  @override
  Widget build(BuildContext context) => AvatarTile(
    prenom: nomComplet,
    urlSignee: urlSignee,
    diametre: AppAvatar.grand,
  );
}
