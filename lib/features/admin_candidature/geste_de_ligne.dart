// Le geste d'une ligne, en un seul endroit (PERSONNES-UNE-PAGE, etape b2).
//
// La file des candidatures, la liste des enseignants et l'apercu de la page
// « Personnes » offrent les memes gestes sur un dossier dont ils ne portent
// ni la version ni les reponses. Tous font donc la meme chose : **lire le
// dossier**, **rappeler la table des gestes sur ce qu'on vient de lire**,
// puis ouvrir **la meme feuille** que la fiche (`feuille_geste.dart`). Cette
// suite vivait en double, privee, dans deux pages ; elle est ici, une fois.
//
// Aucune regle ici : la table est `gestes_proposes.dart`, le serveur decide.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../admin_candidatures/libelles_candidatures.dart' show nomAffiche;
import 'feuille_geste.dart';
import 'gestes_proposes.dart';
import 'libelles_candidature.dart';
import 'synthese_tete_dossier.dart' show elementsComplementManquants;

/// Comment le geste d'une ligne a fini.
enum IssueGesteDeLigne {
  /// Le dossier n'a pas pu etre lu : rien n'a ete fait.
  illisible,

  /// Le dossier a change : le geste n'est plus permis, rien n'a ete fait.
  plusPermis,

  /// La personne a ferme la feuille sans rien faire.
  renonce,

  /// Le serveur a fait le geste.
  fait,

  /// La feuille demande une relecture (le dossier a change pendant le geste).
  relire,
}

/// Ce que le geste d'une ligne rend a la page.
@immutable
class ResultatGesteDeLigne {
  /// Cree le resultat.
  const ResultatGesteDeLigne(this.issue, {this.message});

  /// L'issue.
  final IssueGesteDeLigne issue;

  /// La phrase a montrer (retour ou echec), ou `null`.
  final String? message;

  /// Vrai quand la liste doit se relire (tout sauf illisible et renonce).
  bool get aRelire =>
      issue == IssueGesteDeLigne.plusPermis ||
      issue == IssueGesteDeLigne.fait ||
      issue == IssueGesteDeLigne.relire;

  /// Vrai quand [message] dit un echec.
  bool get echec =>
      issue == IssueGesteDeLigne.illisible ||
      issue == IssueGesteDeLigne.plusPermis;
}

/// Lance [geste] sur le dossier de [ligne] : lecture neuve du dossier,
/// controle du geste sur ce qui vient d'etre lu, puis la feuille de la fiche.
///
/// [onLu] est rappele des que la lecture est finie (la page retire alors son
/// indication « ouverture »). [cocherManquants] : « Demander un complement »
/// s'ouvre avec les elements manquants deja coches (PE-C10).
Future<ResultatGesteDeLigne> lancerGesteDeLigne(
  BuildContext context,
  WidgetRef ref, {
  required LigneCandidature ligne,
  required GesteCandidature geste,
  required CapacitesCandidatures capacites,
  VoidCallback? onLu,
  bool cocherManquants = false,
}) async {
  final DemandeDossier demande = DemandeDossier(ligne.reference, id: ligne.id);
  // Une lecture neuve : la version lue est celle d'aujourd'hui, jamais celle
  // d'un dossier garde en memoire.
  ref.invalidate(detailCandidatureProvider(demande));
  final ProviderSubscription<AsyncValue<DetailCandidature>> garde = ref
      .listenManual(
        detailCandidatureProvider(demande),
        (AsyncValue<DetailCandidature>? _, AsyncValue<DetailCandidature> _) {},
      );
  DetailCandidature? detail;
  try {
    detail = await ref.read(detailCandidatureProvider(demande).future);
  } on Object {
    detail = null;
  } finally {
    garde.close();
  }
  final r = t.admin.candidatures.liste;
  if (!context.mounted) {
    return const ResultatGesteDeLigne(IssueGesteDeLigne.renonce);
  }
  onLu?.call();
  if (detail == null) {
    return ResultatGesteDeLigne(
      IssueGesteDeLigne.illisible,
      message: r.dossierIllisible,
    );
  }
  if (!gestePermis(geste, detail)) {
    final LigneCandidature lu = detail.ligne;
    return ResultatGesteDeLigne(
      IssueGesteDeLigne.plusPermis,
      message: r.gestePlusPossible(
        etat: libelleEtatCourant(
          issue: lu.issue,
          enPause: lu.enPause,
          etape: lu.etape,
          etat: lu.etat,
        ),
      ),
    );
  }
  final SortieFeuille? sortie = await ouvrirFeuilleGeste(
    context,
    geste: geste,
    detail: detail,
    capacites: capacites,
    elementsInitiaux:
        cocherManquants && geste == GesteCandidature.demanderComplement
        ? elementsComplementManquants(detail)
        : const <String>{},
  );
  if (sortie == null) {
    return const ResultatGesteDeLigne(IssueGesteDeLigne.renonce);
  }
  if (sortie.issue != IssueFeuille.fait) {
    return const ResultatGesteDeLigne(IssueGesteDeLigne.relire);
  }
  return ResultatGesteDeLigne(
    IssueGesteDeLigne.fait,
    message: r.retourLigne(
      nom: nomAffiche(ligne),
      retour: sortie.rejoue
          ? t.admin.candidatures.retours.rejoue
          : libelleRetour(geste),
    ),
  );
}
