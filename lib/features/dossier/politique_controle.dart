// La politique de controle des enseignants (partie B de
// `POLITIQUE_CONTROLE_ENSEIGNANTS.md`, pilotage `14_controleur/juridique/`),
// validee par le directeur le 02/10/2026 et portee mot pour mot. Sa section
// 10 porte les valeurs de `COORDONNEES_LEGALES.md` (05/10/2026, decide par
// delegation le 05/10/2026).
//
// C'est la piece que la clause du contrat enseignant fait « confirmer avoir
// recue » (`t.contrat.clauseControle`). Elle se lit depuis la clause
// (`ContratPage`) et depuis l'espace enseignant (profil, section des
// contrats). Une seule lecture, la surface de lecture partagee : aucune route
// propre.
//
// Choix faits par delegation le 05/10/2026 :
// - le renvoi interne « (voir `RGPD_UE.md`) » de la section 10 n'est pas
//   porte : c'est un document du pilotage, que l'enseignant ne peut pas
//   ouvrir ; tout le reste est mot pour mot ;
// - la mise en forme du texte valide est gardee : listes (numerotees ou a
//   puces) et passages en gras.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../salle_seance/information_controle.dart';

/// Une section de la politique : son titre et ses blocs, dans l'ordre.
typedef SectionPolitique = ({String titre, List<String> blocs});

/// Les dix sections de la partie B, mot pour mot.
///
/// Un bloc qui commence par « - » est un point de liste a puce ; un bloc qui
/// commence par un numero (« 1. ») est un point de liste numerotee ; le reste
/// est un paragraphe. Les passages entre `**` sont en gras dans le texte
/// valide.
///
/// [contact] : le contact confidentialite de la section 10, la meme constante
/// que le texte E-2 de l'eleve ([InformationControle.contactConfidentialite]).
List<SectionPolitique> sectionsPolitiqueControle({
  String contact = InformationControle.contactConfidentialite,
}) {
  final Traductions$contrat$politique$fr p = t.contrat.politique;
  return <SectionPolitique>[
    (titre: p.s1.titre, blocs: p.s1.blocs),
    (titre: p.s2.titre, blocs: p.s2.blocs),
    (titre: p.s3.titre, blocs: p.s3.blocs),
    (titre: p.s4.titre, blocs: p.s4.blocs),
    (titre: p.s5.titre, blocs: p.s5.blocs),
    (titre: p.s6.titre, blocs: p.s6.blocs),
    (titre: p.s7.titre, blocs: p.s7.blocs),
    (titre: p.s8.titre, blocs: p.s8.blocs),
    (titre: p.s9.titre, blocs: p.s9.blocs),
    (titre: p.s10.titre, blocs: <String>[p.s10.texte(contact: contact)]),
  ];
}

/// Le texte d'un bloc sans ses marques (`- `, `**`) : ce que l'on lit.
String textePlatBloc(String bloc) => _decouper(bloc).texte.replaceAll('**', '');

/// Ouvre la politique de controle en lecture. Elle se ferme d'un geste ; rien
/// n'est a accepter ici (la confirmation de reception est dans le contrat).
Future<void> ouvrirPolitiqueControle(BuildContext context) =>
    AppBottomSheet.ouvrirLecture<void>(
      context,
      titre: t.contrat.politique.titre,
      libelleFermer: t.commun.fermer,
      // La surface de lecture donne au corps la hauteur restante : le texte y
      // defile jusqu'a sa derniere phrase, a 320 et a 200 %.
      constructeur: (BuildContext _) =>
          const SingleChildScrollView(child: TextePolitiqueControle()),
    );

/// Les dix sections de la politique, rendues.
class TextePolitiqueControle extends StatelessWidget {
  /// Cree le texte.
  const TextePolitiqueControle({
    super.key,
    this.contact = InformationControle.contactConfidentialite,
  });

  /// Le contact confidentialite de la section 10.
  final String contact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final List<SectionPolitique> sections = sectionsPolitiqueControle(
      contact: contact,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int n = 0; n < sections.length; n++) ...<Widget>[
          if (n > 0) Ecart.vXl,
          Semantics(
            header: true,
            child: Text(sections[n].titre, style: textes.titleMedium),
          ),
          Ecart.vSm,
          for (int b = 0; b < sections[n].blocs.length; b++) ...<Widget>[
            if (b > 0) Ecart.vMd,
            _Bloc(bloc: sections[n].blocs[b]),
          ],
        ],
      ],
    );
  }
}

/// Un bloc decoupe : sa marque de liste (nulle pour un paragraphe), si elle
/// est decorative (puce) ou lue (numero), et son texte.
typedef _BlocDecoupe = ({String? marque, bool puce, String texte});

final RegExp _numero = RegExp(r'^(\d+\.)\s(.*)$', dotAll: true);

_BlocDecoupe _decouper(String bloc) {
  if (bloc.startsWith('- ')) {
    return (
      marque: t.contrat.politique.puce,
      puce: true,
      texte: bloc.substring(2),
    );
  }
  final RegExpMatch? m = _numero.firstMatch(bloc);
  if (m != null) {
    return (marque: m.group(1), puce: false, texte: m.group(2)!);
  }
  return (marque: null, puce: false, texte: bloc);
}

class _Bloc extends StatelessWidget {
  const _Bloc({required this.bloc});

  final String bloc;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final _BlocDecoupe d = _decouper(bloc);
    // L'adresse de contact (section 10) ne se coupe qu'a ses points de
    // coupure ([coupuresAdresse]) : aucun mot coupe a 320 et texte 200 %.
    final Widget texte = Text.rich(
      _spans(coupuresAdresse(d.texte), style),
      style: style,
    );
    final String? marque = d.marque;
    if (marque == null) return texte;
    final Widget repere = Text(marque, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // La puce est decorative ; le numero d'une liste numerotee est lu.
        if (d.puce) ExcludeSemantics(child: repere) else repere,
        Ecart.hSm,
        Expanded(child: texte),
      ],
    );
  }

  /// Les passages entre `**` en gras, le reste dans le style du corps.
  static TextSpan _spans(String texte, TextStyle style) {
    final List<String> morceaux = texte.split('**');
    final TextStyle gras = AppTypography.graisse(style, FontWeight.w700);
    return TextSpan(
      children: <InlineSpan>[
        for (int i = 0; i < morceaux.length; i++)
          if (morceaux[i].isNotEmpty)
            TextSpan(text: morceaux[i], style: i.isOdd ? gras : null),
      ],
    );
  }
}
