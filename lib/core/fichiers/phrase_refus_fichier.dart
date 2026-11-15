import '../i18n/strings.g.dart';
import 'formats_admis.dart';

/// La phrase d'un fichier refuse au depot : ce qui ne va pas, et quoi faire
/// maintenant (K-59). Une seule source pour la piece et les photos.
String phraseRefusFichier(FichierRefuse refus) {
  final f = t.fichiers;
  return switch (refus.cause) {
    CauseRefusFichier.heicNonConverti => f.heicNonConverti,
    CauseRefusFichier.tropLourd => f.tropLourd(
      taille: '${refus.sorte.tailleMaxMo}',
    ),
    CauseRefusFichier.format => switch (refus.sorte) {
      SorteFichier.piece => f.pieceFormat,
      SorteFichier.photo => f.photoFormat,
    },
  };
}
