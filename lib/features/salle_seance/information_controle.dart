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

  /// Le contact confidentialite (`{contact_confidentialite}`) : une seule
  /// constante, citee par le texte E-2 de l'eleve et par la section 10 de la
  /// politique de controle des enseignants (`politique_controle.dart`).
  ///
  /// Valeur du pilotage `14_controleur/juridique/COORDONNEES_LEGALES.md`
  /// (choix du directeur du 05/10/2026, porte par delegation le 05/10/2026).
  /// L'alias support@rewayahacademy.com est cree depuis le 05/10/2026
  /// (`docs/current/JUR-APP-1_RESTES.md`, « Conditions restantes »).
  static const String contactConfidentialite = 'support@rewayahacademy.com';

  /// Le bouton « Signaler » de l'eleve n'existe pas encore dans la salle
  /// (ecart E16) : la phrase de E-1 qui le cite reste cachee (principe 10 : le
  /// texte suit la realite).
  static const bool boutonSignalerEleve = false;

  /// La largeur de fenetre sous laquelle le lien n'est pas affiche (Q-3 = b,
  /// decision du directeur du 05/10/2026 : « cacher le lien sous 385
  /// environ »). Seuil exact : **388**.
  ///
  /// Mesures du 05/10/2026, polices du depot :
  ///
  /// - texte x1, salle guidee : le lien tient sur la ligne de la mention a
  ///   partir de 388 de large (387 : il passe dessous et le cours descend de
  ///   16 ; dans la salle du Mode Accessibilite il tient des 385). Sous 388,
  ///   le lien ne peut donc que pousser le cours ;
  /// - texte x2 (salle du Mode Accessibilite, telephone de hauteur
  ///   proportionnelle a 390 x 844) : le lien passe sous la mention (+32) et
  ///   en-tete + commandes depassent 30 % de l'ecran sous 375 (30,8 % a 360,
  ///   30,0 % a 370, 29,6 % a 375 ; sans lien 26,7 %, 26,0 %, 25,6 %) ; a
  ///   375 x 667, 36 % avec le lien ;
  /// - texte x1,5 : 31,3 % a 320 x 690 avec le lien, 27,8 % sans.
  ///
  /// A 390 x 844 le lien reste (texte x2 : 28,8 %, MA-CMD-1).
  ///
  /// Sous ce seuil, l'information reste accessible : la mention elle-meme
  /// ouvre la meme lecture ([MentionSeance]), sans hauteur ni ecran nouveaux.
  static const double largeurMinimaleLien = 388;

  /// Vrai si un texte existe pour ce role, avec ses valeurs : E-1 pour
  /// l'interface guidee, E-2 pour l'eleve (avec un contact). L'enseignant n'a
  /// pas de texte sur le bandeau.
  ///
  /// L'enseignant lit sa politique de controle depuis son contrat et son
  /// profil (`politique_controle.dart`), pas depuis le bandeau.
  static bool texteDisponible(RoleSeance role, {String? contact}) =>
      switch (role) {
        RoleSeance.guidee => true,
        RoleSeance.eleve => contact != null,
        RoleSeance.enseignant => false,
      };
}

/// Le texte, avec des points de coupure possibles dans une adresse e-mail.
///
/// Une adresse est un seul « mot » plus large que l'ecran a 320 et texte
/// 200 % : sans aide, le moteur la couperait n'importe ou. Une espace sans
/// chasse (U+200B, invisible, rien n'est ajoute a la lecture) est posee apres
/// « @ » et avant chaque point interieur de l'adresse : elle ne passe a la
/// ligne qu'a ces endroits, comme le veut l'usage typographique pour les
/// adresses (decide par delegation le 05/10/2026). Le reste du texte n'est
/// pas touche.
String coupuresAdresse(String texte) => texte.replaceAllMapped(
  RegExp(r'[^\s@]+@[^\s@]*[^\s@.]'),
  (Match m) => m[0]!
      .replaceAll('@', '@\u200B')
      .replaceAllMapped(RegExp(r'\.(?=[^.])'), (Match _) => '\u200B.'),
);

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
    // La surface de lecture donne au corps la hauteur restante (plein ecran
    // sous 840) : le texte y defile, jusqu'a sa derniere phrase, a 320 et a
    // 200 % comme sur un grand ecran.
    constructeur: (BuildContext _) => SingleChildScrollView(
      child: TexteInformationControle(
        role: role,
        contact: contact,
        signaler: signaler,
      ),
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
    return <String>[
      i.e2.p1,
      i.e2.p2,
      i.e2.p3,
      coupuresAdresse(i.e2.p4(contact: contact ?? '')),
    ];
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
