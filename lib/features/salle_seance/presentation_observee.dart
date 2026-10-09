// TB-11a (plan V2 §5, UX-21) : la presentation de l'enseignant, telle que
// la suivent le tuteur observateur et le controleur, en lecture seule.
//
// Une donnee pure (le support presente, sa page, l'affichage partage, le
// tableau libre) et son fournisseur. **Aucune source serveur a ce jour** :
// l'etat partage de la seance n'arrive pas encore jusqu'a `/salle`
// (TB-BR) ; le fournisseur rend `null` et la salle des observateurs garde
// son rendu. La demonstration le surcharge (`/demo/salle?obs=`).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import 'vue_seance.dart';

/// Ce que l'enseignant presente a la classe, lu par un observateur.
@immutable
class PresentationObservee {
  const PresentationObservee({
    this.supportPresente,
    this.affichage = AffichagePartage.avecNotes,
    this.tableauLibre,
  });

  /// Le support a page fixe presente, sa page comprise, ou `null`.
  final SupportPageFixe? supportPresente;

  /// L'affichage partage (Support, Avec notes, Tableau).
  final AffichagePartage affichage;

  /// Le tableau libre de la seance, ou `null` : non connu.
  final TableauLibre? tableauLibre;

  /// Vrai quand il y a quelque chose a montrer : un support presente, ou le
  /// tableau libre. Sinon, la salle garde son rendu (la scene).
  bool get aMontrer => supportPresente != null || tableauLibre != null;
}

/// La presentation suivie dans la seance [String] (son identifiant).
/// **`null` = non branchee** : aucune source serveur avant TB-BR ; la
/// demonstration la surcharge.
final ProviderFamily<PresentationObservee?, String>
presentationObserveeProvider = Provider.family<PresentationObservee?, String>(
  (Ref ref, String _) => null,
);
