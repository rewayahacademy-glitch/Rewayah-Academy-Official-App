// IMAGES-MESSAGERIE : une phrase vraie par cause d'echec d'un depot d'image
// (K-59 : quoi, pourquoi, quoi faire). Jamais « connexion » pour un refus du
// serveur : seul [RefusImage.reseau] (aucune reponse) la dit.

import '../i18n/strings.g.dart';
import 'image_message.dart';

/// Le texte d'un message qui ne porte qu'une image : le serveur n'accepte
/// aucun message sans texte (contrat §1). La bulle ne l'ecrit pas.
const String texteImageSeule = 'Image';

/// La phrase d'un refus de depot d'image.
String phraseRefusImage(RefusImage refus) {
  final r = t.com.messages.images.refus;
  return switch (refus) {
    RefusImage.demandeInvalide => r.demandeInvalide,
    RefusImage.typeRefuse => r.typeRefuse,
    RefusImage.imageTropLourde ||
    RefusImage.miniatureTropLourde => r.imageTropLourde,
    RefusImage.nonAutorise => r.nonAutorise,
    RefusImage.mineurRefuse => r.mineurRefuse,
    RefusImage.limiteHoraire => r.limiteHoraire,
    RefusImage.dejaUneImage => r.dejaUneImage,
    RefusImage.depotIndisponible => r.depotIndisponible,
    RefusImage.contenuDifferent => r.contenuDifferent,
    RefusImage.objetIntrouvable => r.objetIntrouvable,
    RefusImage.stockageIndisponible => r.stockageIndisponible,
    RefusImage.confirmationIndisponible => r.confirmationIndisponible,
    RefusImage.depotImpossible => r.depotImpossible,
    RefusImage.envoiStockage => r.envoiStockage,
    RefusImage.reseau => r.reseau,
    RefusImage.imageTropGrosse => r.imageTropGrosse,
    RefusImage.imageIllisible => r.imageIllisible,
  };
}
