// Le composer texte des communications (spec section 19 ; lexique
// section 22 : « Ce message n'a pas encore ete confirme »).
//
// Il n'y a PAS de second composer : c'est `FilDiscussion` (CT-6), avec ses
// emplacements optionnels (en-tete, piece jointe, vocal). Ce fichier ne
// fournit que les textes des communications, pour que les voies (Messages,
// Studio) n'aient pas a les recomposer. L'emplacement vocal reste vide tant
// que COM-VOC ne le remplit pas (branchement a COM-FUS).

import '../i18n/strings.g.dart';
import '../widgets/fil_discussion.dart';

/// Les textes du fil des communications : « Envoyer », « Envoi en cours »,
/// « Envoye » sur accuse seulement, « Ce message n'a pas encore ete
/// confirme » en cas d'echec (jamais « non envoye »), « Reessayer ».
TextesFilDiscussion textesFilCommunication() {
  final c = t.com.socle.composants.composer;
  return TextesFilDiscussion(
    aideChamp: c.aide,
    libelleChamp: c.message,
    envoyer: c.envoyer,
    champVide: c.champVide,
    enCours: c.enCours,
    envoye: c.envoye,
    echec: c.nonConfirme,
    reessayer: c.reessayer,
    auteurSoi: c.auteurSoi,
    annonce: (String auteur, String texte) =>
        c.annonce(auteur: auteur, texte: texte),
  );
}
