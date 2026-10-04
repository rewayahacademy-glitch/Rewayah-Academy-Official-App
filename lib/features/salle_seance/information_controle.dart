// Le lien « En savoir plus » du bandeau de la salle et les textes
// d'information des eleves sur les visites de controle (E-1, E-2), valides
// par le directeur le 02/10/2026 (pilotage
// `14_controleur/juridique/INFO_ELEVES_PARENTS.md`).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import 'vue_seance.dart';

/// Le reglage du lien, en un seul endroit.
///
/// Le lien est **refusable** (point 2 de `INFO_ELEVES_PARENTS.md`) : si le
/// directeur le refuse, [lienAccepte] passe a `false` et le bandeau redevient
/// la seule ligne de la mention ; les textes restent alors a l'inscription et
/// dans la politique de confidentialite.
abstract final class InformationControle {
  /// Le lien « En savoir plus » est affiche sur le bandeau (decision B12 :
  /// c'est le seul ajout a l'ecran, discret).
  static const bool lienAccepte = true;

  /// Le contact confidentialite que cite le texte E-2
  /// (`{contact_confidentialite}`). **Pas encore fourni** (referent donnees
  /// non nomme au 02/10) : tant qu'il manque, le texte E-2 n'est pas affiche,
  /// plutot qu'affiche avec un trou ou une adresse inventee.
  static const String? contactConfidentialite = null;

  /// Le bouton « Signaler » de l'eleve n'existe pas encore dans la salle
  /// (ecart E16) : la phrase de E-1 qui le cite reste cachee (principe 10 : le
  /// texte suit la realite).
  static const bool boutonSignalerEleve = false;

  /// Vrai si un texte existe pour ce role, avec ses valeurs : E-1 pour
  /// l'interface guidee, E-2 pour l'eleve (avec un contact). L'enseignant n'a
  /// pas de texte sur le bandeau : sa politique de controle vit dans son
  /// espace.
  static bool texteDisponible(RoleSeance role, {String? contact}) =>
      switch (role) {
        RoleSeance.guidee => true,
        RoleSeance.eleve => contact != null,
        RoleSeance.enseignant => false,
      };
}

/// Ouvre la lecture du texte d'information propre au role. Elle se ferme
/// d'un geste ; rien n'est a accepter.
Future<void> ouvrirInformationControle(
  BuildContext context,
  RoleSeance role, {
  String? contact,
  bool signaler = InformationControle.boutonSignalerEleve,
}) {
  final bool guidee = role == RoleSeance.guidee;
  return AppBottomSheet.ouvrirLecture<void>(
    context,
    titre: guidee
        ? t.salle.informationControle.e1.titre
        : t.salle.informationControle.e2.titre,
    libelleFermer: t.commun.fermer,
    constructeur: (BuildContext _) => TexteInformationControle(
      role: role,
      contact: contact,
      signaler: signaler,
    ),
  );
}

/// Les paragraphes du texte E-1 ou E-2, mot pour mot.
class TexteInformationControle extends StatelessWidget {
  /// Cree le texte.
  const TexteInformationControle({
    required this.role,
    this.contact,
    this.signaler = InformationControle.boutonSignalerEleve,
    super.key,
  });

  /// Le role qui lit : guidee (E-1) ou eleve (E-2).
  final RoleSeance role;

  /// Le contact confidentialite de E-2.
  final String? contact;

  /// Vrai si le bouton « Signaler » existe : la phrase de E-1 est ajoutee.
  final bool signaler;

  /// Les paragraphes, dans l'ordre du texte valide.
  List<String> get paragraphes {
    final Traductions$salle$informationControle$fr i =
        t.salle.informationControle;
    if (role == RoleSeance.guidee) {
      return <String>[
        i.e1.p1,
        i.e1.p2,
        i.e1.p3,
        i.e1.p4,
        if (signaler) '${i.e1.p5} ${i.e1.signaler}' else i.e1.p5,
      ];
    }
    return <String>[i.e2.p1, i.e2.p2, i.e2.p3, i.e2.p4(contact: contact ?? '')];
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyLarge;
    final List<String> textes = paragraphes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int n = 0; n < textes.length; n++) ...<Widget>[
          if (n > 0) Ecart.vMd,
          Text(textes[n], style: style),
        ],
      ],
    );
  }
}
