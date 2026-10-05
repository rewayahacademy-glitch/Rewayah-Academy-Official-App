// COM-RC tour 3 (derniers restes de la revue COM-R), cote Communaute : rendu
// dans la VRAIE coquille de l'enseignant, avec les polices du depot (comme
// les captures).
//
// Chaque test verifie le PREMIER ECRAN, sans rien faire defiler, et dit sa
// contre-preuve : ce qui echouait a e0b9f890.
//
// - flux a 320 x 640, texte x2 : au moins une publication se voit au
//   premier ecran (la phrase de l'en-tete se replie) ;
// - publication a 320 x 640, texte x2 : le bloc de l'auteur ne prend plus
//   pres de 30 % de l'ecran (« Il y a 2 / h ») : sa ligne passe sous le nom,
//   sur une ligne, lue en entier par le lecteur d'ecran ;
// - RTL : une publication et ses reponses ecrites en francais gardent leur
//   sens de lecture dans l'interface arabe (le point final n'est plus en
//   tete de ligne) ; les textes de l'interface restent de droite a gauche.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import 'banc_communaute.dart';

const String _ouverte = DonneesCommunauteDemo.publicationOuverte;
const Size _petit = Size(320, 640);

PublicationCommunaute _publication() => DonneesCommunauteDemo.publications()
    .firstWhere((PublicationCommunaute p) => p.id == _ouverte);

/// La zone ou [cible] peut se voir sans defiler : l'ecran au-dessus de la
/// barre basse, coupe par chaque zone qui defile au-dessus d'elle.
Rect _zoneVisible(WidgetTester tester, Element cible) {
  Rect zone = Offset.zero & _petit;
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  if (barre.evaluate().isNotEmpty) {
    zone = Rect.fromLTRB(
      zone.left,
      zone.top,
      zone.right,
      tester.getRect(barre).top,
    );
  }
  cible.visitAncestorElements((Element a) {
    if (a.widget is Scrollable) {
      final RenderBox boite = a.findRenderObject()! as RenderBox;
      zone = zone.intersect(boite.localToGlobal(Offset.zero) & boite.size);
    }
    return true;
  });
  return zone;
}

/// La hauteur de [cible] qui se voit au premier ecran.
double _hauteurVisible(WidgetTester tester, Element cible) {
  final RenderBox b = cible.renderObject! as RenderBox;
  final Rect r = b.localToGlobal(Offset.zero) & b.size;
  final Rect vue = r.intersect(_zoneVisible(tester, cible));
  return vue.height <= 0 || vue.width <= 0 ? 0 : vue.height;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('flux, 320 x 640, texte x2 : une publication se voit au '
      'premier ecran', (WidgetTester tester) async {
    // Contre-preuve : a e0b9f890, la phrase de l'en-tete prenait quatre
    // lignes a cote du retour ; aucune publication au premier ecran.
    await monterCommunaute(tester, taille: _petit, echelleTexte: 2);
    expect(tester.takeException(), isNull);
    final Iterable<Element> cartes = find
        .byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'communaute-carte-',
              ),
        )
        .evaluate();
    expect(cartes, isNotEmpty);
    final double meilleure = cartes
        .map((Element e) => _hauteurVisible(tester, e))
        .fold<double>(0, (double a, double b) => a > b ? a : b);
    expect(
      meilleure,
      greaterThanOrEqualTo(64),
      reason: 'une carte de publication se voit sans defiler',
    );
  });

  testWidgets('publication, 320 x 640, texte x2 : le bloc de l auteur reste '
      'compact, sa ligne est lue en entier', (WidgetTester tester) async {
    // Contre-preuve : a e0b9f890, la fonction et le moment tenaient dans la
    // colonne etroite du nom, entre l'avatar, (i) et le menu : quatre
    // lignes (« Il y a 2 / h »), pres de 30 % de l'ecran.
    await monterCommunaute(
      tester,
      taille: _petit,
      echelleTexte: 2,
      publicationId: _ouverte,
    );
    expect(tester.takeException(), isNull);
    final Finder auteur = find.descendant(
      of: find.byKey(PublicationDetail.cleDefilement),
      matching: find.byType(AvatarNom),
    );
    final Rect bloc = tester.getRect(auteur.first);
    final Rect titre = tester.getRect(find.byKey(PublicationDetail.cleTitre));
    // Du haut du bloc de l'auteur au titre de la publication.
    final double hauteur = titre.top - bloc.top;
    expect(
      hauteur,
      lessThanOrEqualTo(_petit.height * 0.22),
      reason: 'le bloc de l auteur prend $hauteur sur ${_petit.height}',
    );
    // Le moment n'est jamais coupe dans un mot (« Il y a 2 / h »).
    final PublicationCommunaute p = _publication();
    final Finder ligne = find.byKey(PublicationDetail.cleLigneAuteur);
    expect(ligne, findsOneWidget);
    final Semantics s = tester.widget<Semantics>(ligne);
    expect(s.properties.label, contains(p.auteur.fonction));
    final Rect r = tester.getRect(ligne);
    expect(r.height, lessThan(48), reason: 'une seule ligne');
    expect(r.top, greaterThanOrEqualTo(bloc.top));
  });

  testWidgets('RTL : la publication et ses reponses en francais gardent leur '
      'sens de lecture', (WidgetTester tester) async {
    // Contre-preuve : a e0b9f890, le contenu prenait le sens de l'interface
    // arabe et son point final passait en tete de ligne (« .eleves »).
    await monterCommunaute(tester, publicationId: _ouverte, arabe: true);
    expect(tester.takeException(), isNull);
    final PublicationCommunaute p = _publication();
    RenderParagraph paragraphe(String texte) =>
        tester.renderObject<RenderParagraph>(
          find
              .descendant(
                of: find.text(texte, skipOffstage: false),
                matching: find.byType(RichText, skipOffstage: false),
              )
              .first,
        );
    expect(paragraphe(p.titre).textDirection, TextDirection.ltr);
    expect(paragraphe(p.texte).textDirection, TextDirection.ltr);
    for (final ReponseCommunaute r
        in DonneesCommunauteDemo.reponses()[_ouverte]!) {
      expect(
        paragraphe(r.texte).textDirection,
        TextDirection.ltr,
        reason: r.texte,
      );
    }
    // L'interface reste de droite a gauche.
    expect(
      Directionality.of(tester.element(find.byKey(PublicationDetail.cleTitre))),
      TextDirection.rtl,
    );
  });
}
