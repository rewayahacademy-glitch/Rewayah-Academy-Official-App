import 'package:flutter/material.dart';

import '../capacites/port_finance_foyer.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/apparition_douce.dart';
import 'groupe_reglages.dart';

/// L'issue d'une operation, profil par profil (S06 recharge, S11 annulation).
///
/// Une ligne par profil : prenom, puis l'issue rendue par le serveur,
/// **en mots et en icone** (confirmee, en attente, echouee), jamais a la
/// seule couleur. Le motif serveur n'est jamais affiche brut : l'ecran le
/// traduira quand la liste sera fixee (DB-FIN-04, DB-FIN-06).
class ResultatParProfil extends StatelessWidget {
  /// Cree la liste.
  const ResultatParProfil({
    required this.issues,
    required this.prenoms,
    super.key,
    this.titre,
  });

  /// Les issues, dans l'ordre rendu par le serveur.
  final List<IssueProfil> issues;

  /// Le prenom de chaque profil, par identifiant.
  final Map<String, String> prenoms;

  /// Le titre du groupe, facultatif.
  final String? titre;

  /// Le mot d'une issue.
  static String texteIssue(IssueServeur issue) => switch (issue) {
    IssueServeur.confirmee => t.finance.issues.confirmee,
    IssueServeur.enAttente => t.finance.issues.enAttente,
    IssueServeur.echouee => t.finance.issues.echouee,
  };

  static AppIcon _icone(IssueServeur issue) => switch (issue) {
    IssueServeur.confirmee => AppIcons.succes,
    IssueServeur.enAttente => AppIcons.attente,
    IssueServeur.echouee => AppIcons.avertissement,
  };

  @override
  Widget build(BuildContext context) => ApparitionDouce(
    child: GroupeReglages(
      titre: titre,
      lignes: <LigneRubrique>[
        for (final IssueProfil issue in issues)
          LigneRubrique(
            libelle: prenoms[issue.profilId] ?? t.finance.profilSansPrenom,
            icone: _icone(issue.issue),
            valeur: texteIssue(issue.issue),
          ),
      ],
    ),
  );
}
