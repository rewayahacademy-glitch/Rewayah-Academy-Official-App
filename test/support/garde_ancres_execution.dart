// DUREE-FOND-1 : garde A L'EXECUTION des ancres de sens.
//
// Changement de methode decide par delegation le 09/10 (fiche
// DUREE-INSECABLE-5, trois relectures refusees) : une garde statique qui lit
// le source ne peut pas, par nature, suivre toutes les formes Dart (litteraux
// colles, `this.`, record en liste puis destructuration, champ statique...).
// Cette garde-ci regarde ce que l'ecran REND, quelle que soit la forme du
// code qui l'a produit : a la fin de chaque `testWidgets` de la suite
// (`test/flutter_test_config.dart`), elle parcourt
// - les textes rendus : `RenderParagraph` (Text, Text.rich, RichText, et
//   leurs TextSpan, libelles semantiques des spans compris) et
//   `RenderEditable` (EditableText, TextField) ;
// - la configuration semantique propre de chaque objet rendu : label, value,
//   hint, tooltip, increasedValue, decreasedValue (Semantics, Tooltip,
//   Image.semanticLabel, Text.semanticsLabel...) ;
// et echoue si une ancre de sens (U+200E ou U+200F) se trouve ailleurs
// qu'en tete d'une chaine. « En tete » : seuls des caracteres de controle de
// sens (isolats U+2066 a U+2069, plongements U+202A a U+202E, marques U+200E,
// U+200F, U+061C) la precedent, comme `isolerSens(valeurSeule(...))`.
//
// Seule exception, decidee par delegation le 10/10 : une marque droite a
// gauche (U+200F) collee DEVANT une ponctuation (« Samira\u200F، 0:12 »).
// C'est l'usage voulu des traductions arabes (assets/i18n/ar.i18n.json,
// COM-RC tour 7, lot L) : la virgule arabe reste a gauche du nom latin qui
// la precede. Elle n'ancre aucune valeur ; une marque devant un chiffre ou
// une lettre reste une faute.
//
// La garde statique `test/support/garde_ancres.dart` reste en place comme
// filet complementaire : elle voit aussi le code qu'aucun test n'exerce.

import 'dart:io' show HttpOverrides;

import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les deux ancres de sens que la garde surveille.
const String ancreGauche = '\u200E';

/// Marque droite a gauche.
const String ancreDroite = '\u200F';

/// Une ancre trouvee au milieu d'une chaine rendue.
typedef AncreRendue = ({String origine, String texte, int position});

bool _controleDeSens(int c) =>
    c == 0x200E ||
    c == 0x200F ||
    c == 0x061C ||
    (c >= 0x2066 && c <= 0x2069) ||
    (c >= 0x202A && c <= 0x202E);

/// La position de la premiere ancre de [texte] qui n'est pas en tete, ou -1.
int ancreHorsTete(String texte) {
  bool enTete = true;
  for (int i = 0; i < texte.length; i++) {
    final int c = texte.codeUnitAt(i);
    final bool ancre = c == 0x200E || c == 0x200F;
    if (enTete) {
      if (_controleDeSens(c)) continue;
      enTete = false;
      continue;
    }
    if (!ancre) continue;
    if (c == 0x200F &&
        i + 1 < texte.length &&
        _ponctuation.contains(texte[i + 1])) {
      continue;
    }
    return i;
  }
  return -1;
}

/// Les ponctuations qu'une marque U+200F peut coller a gauche d'un nom latin
/// en interface arabe : virgule, point-virgule, point d'interrogation arabes,
/// et la ponctuation latine.
const String _ponctuation = '\u060C\u061B\u061F,.;:!?';

void _examiner(List<AncreRendue> fautes, String origine, String? texte) {
  if (texte == null || texte.isEmpty) return;
  final int p = ancreHorsTete(texte);
  if (p >= 0) fautes.add((origine: origine, texte: texte, position: p));
}

void _examinerSpan(List<AncreRendue> fautes, String origine, InlineSpan span) {
  // La chaine affichee entiere : une ancre en tete d'un span qui suit un
  // autre texte est au milieu de la ligne.
  _examiner(
    fautes,
    origine,
    span.toPlainText(includeSemanticsLabels: false, includePlaceholders: false),
  );
  // Les libelles parles portes par les spans, chacun une chaine.
  span.visitChildren((InlineSpan enfant) {
    if (enfant is TextSpan) {
      _examiner(fautes, '$origine (semanticsLabel)', enfant.semanticsLabel);
    }
    return true;
  });
}

void _examinerSemantique(
  List<AncreRendue> fautes,
  String origine,
  RenderObject objet,
) {
  final SemanticsConfiguration config = SemanticsConfiguration();
  try {
    // La configuration propre de l'objet, sans fusion avec ses voisins : une
    // fusion (MergeSemantics) joint des chaines distinctes par un retour a la
    // ligne, et chacune garde le droit a son ancre de tete.
    // ignore: invalid_use_of_protected_member
    objet.describeSemanticsConfiguration(config);
  } on Object {
    // Un objet qui ne sait pas se decrire hors d'une passe semantique n'a
    // rien a nous apprendre ; ses textes sont lus par ailleurs.
    return;
  }
  _examiner(fautes, '$origine semantique label', config.label);
  _examiner(fautes, '$origine semantique value', config.value);
  _examiner(fautes, '$origine semantique hint', config.hint);
  _examiner(fautes, '$origine semantique tooltip', config.tooltip);
  _examiner(
    fautes,
    '$origine semantique increasedValue',
    config.increasedValue,
  );
  _examiner(
    fautes,
    '$origine semantique decreasedValue',
    config.decreasedValue,
  );
}

/// Toutes les ancres hors tete dans l'arbre rendu sous [racine] (par defaut,
/// tout l'arbre de l'application de test).
List<AncreRendue> ancresRendues([Element? racine]) {
  final List<AncreRendue> fautes = <AncreRendue>[];
  final Element? depart = racine ?? WidgetsBinding.instance.rootElement;
  if (depart == null) return fautes;

  void visiter(Element e) {
    final Widget w = e.widget;
    if (w is Tooltip) {
      _examiner(fautes, 'Tooltip.message', w.message);
    }
    if (e is RenderObjectElement) {
      final RenderObject objet = e.renderObject;
      final String origine = w.runtimeType.toString();
      if (objet is RenderParagraph) {
        _examinerSpan(fautes, '$origine (texte rendu)', objet.text);
      } else if (objet is RenderEditable) {
        final InlineSpan? texte = objet.text;
        if (texte != null) {
          _examinerSpan(fautes, '$origine (texte saisi)', texte);
        }
      }
      _examinerSemantique(fautes, origine, objet);
    }
    e.visitChildren(visiter);
  }

  visiter(depart);
  return fautes;
}

String _visible(String texte) => texte
    .replaceAll(ancreGauche, '<U+200E>')
    .replaceAll(ancreDroite, '<U+200F>')
    .replaceAll('\u2068', '<FSI>')
    .replaceAll('\u2069', '<PDI>')
    .replaceAll('\u00A0', '<NBSP>');

/// Le message d'echec de la garde pour [fautes].
String decrireAncres(List<AncreRendue> fautes) {
  final StringBuffer b = StringBuffer(
    'Garde des ancres (DUREE-FOND-1) : ${fautes.length} chaine(s) rendue(s) '
    'portent une ancre de sens (U+200E / U+200F) ailleurs qu\'en tete. '
    'Une valeur ancree pour s\'afficher seule perd son ancre quand elle '
    'suit un autre texte (sansAncre, enchainer, dureeLisible).\n',
  );
  for (final AncreRendue f in fautes.take(12)) {
    b.writeln(
      '  - ${f.origine}, position ${f.position} : « ${_visible(f.texte)} »',
    );
  }
  if (fautes.length > 12) b.writeln('  ... et ${fautes.length - 12} autre(s).');
  return b.toString();
}

/// Echoue si l'arbre rendu porte une ancre hors tete. Appelee a la fin de
/// chaque `testWidgets` par [BindingGardeAncres].
void verifierAncresRendues([Element? racine]) {
  final List<AncreRendue> fautes = ancresRendues(racine);
  if (fautes.isNotEmpty) {
    throw TestFailure(decrireAncres(fautes));
  }
}

/// Le binding de test de toute la suite : celui de `flutter test`, plus la
/// garde des ancres a la fin du corps de chaque `testWidgets`, quand l'ecran
/// est encore monte (le binding le demonte juste apres).
class BindingGardeAncres extends AutomatedTestWidgetsFlutterBinding {
  BindingGardeAncres._();

  /// Installe le binding (une fois, avant toute declaration de test).
  static void installer() {
    if (_installe) return;
    // Le binding de `flutter test` remplace les clients HTTP par un faux qui
    // repond 400. Sans cette configuration, il n'etait cree qu'au premier
    // `testWidgets` : un fichier de purs `test` qui parle a un faux serveur
    // local gardait le vrai client. On garde ce comportement : le faux client
    // n'est pose qu'au premier `testWidgets`.
    final HttpOverrides? avant = HttpOverrides.current;
    BindingGardeAncres._();
    _fauxHttp = HttpOverrides.current;
    HttpOverrides.global = avant;
    _installe = true;
  }

  static bool _installe = false;
  static HttpOverrides? _fauxHttp;

  @override
  Future<void> runTest(
    Future<void> Function() testBody,
    VoidCallback invariantTester, {
    String description = '',
  }) {
    if (_fauxHttp != null) {
      HttpOverrides.global = _fauxHttp;
      _fauxHttp = null;
    }
    return super.runTest(
      () async {
        await testBody();
        verifierAncresRendues();
      },
      invariantTester,
      description: description,
    );
  }
}
