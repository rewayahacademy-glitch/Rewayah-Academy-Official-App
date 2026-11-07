// WEB-BUREAU, etape (a) : le garde-fou permanent de la page d'ordinateur
// (PLAN-LOTS §7 rang 22 n, methode (c) ; definition validee le 06/11/2026,
// `docs/current/DEFINITION-PAGE-ORDINATEUR-2026-11-06.md`).
//
// Pour chaque role, chaque route que ce role peut ouvrir (`cheminsDeclares`
// du vrai routeur, filtre par `deciderRedirection`) est rendue a 1440 x 900
// sur le routeur reel, avec les faux de `support_routeur.dart`, et mesuree :
//   B1  la barre laterale du role est la, jamais la barre du bas ;
//   B2  une sortie visible : barre laterale, fil, ou disque retour ;
//   B3  le fil (`FilAriane`) est la sur une page de niveau 2 ou plus ;
//   B4  aucun texte suivi (plus de 68 caracteres) de plus de 800 px ;
//   B5  aucun bouton plein (`ActionPrincipale`) de plus de 640 px ;
//   B6  la tete fixe de `PageShell` mesure au plus 160 px ;
//   B7  la zone d'action collee mesure au plus 96 px.
//
// Chaque infraction connue est ecrite dans `exceptions_bureau.txt`. Le test
// echoue sur une infraction NOUVELLE (une regression) et sur une exception
// qui n'a plus lieu d'etre (la liste ne fait que retrecir, comme
// `tool/branchement_tolere.txt`). Pour reecrire la liste apres une correction :
//   flutter test test/web_bureau/garde_bureau_test.dart \
//     --dart-define=GARDE_BUREAU_ECRIRE=true

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_ariane.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

/// Un Coran sans corpus : le garde mesure la page, pas sa lecture.
class _CoranMuet implements ServiceCoran {
  @override
  Future<String?> editionCourante() async => null;
  @override
  Future<List<Sourate>?> sourates() async => null;
  @override
  Future<PageCoran?> page(int numero) async => null;
  @override
  Future<int?> pageDe(int sourate, int verset) async => null;
  @override
  Future<PositionLecture?> position(String profilId) async => null;
  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => false;
  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;
  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => null;
}

/// Les valeurs mesurees de la page courante (journal seulement).
final List<String> _details = <String>[];

const String _fichier = 'test/web_bureau/exceptions_bureau.txt';
const bool _ecrire = bool.fromEnvironment('GARDE_BUREAU_ECRIRE');

/// Les exceptions ecrites de la definition (§7) : ni barre laterale ni fil
/// attendus. Elles ne sont pas rendues (porte, salle, pages d'entree).
bool _horsDefinition(String modele) =>
    modele == Routes.racine ||
    modele == Routes.salle ||
    // La salle d'observation (§7, exception permanente, plein ecran).
    modele.startsWith('/tc/observation') ||
    modele.startsWith('/connexion') ||
    modele.startsWith('/commencer') ||
    modele.startsWith('/inscription') ||
    modele.startsWith('/attente') ||
    modele.startsWith('/juridique') ||
    modele.startsWith('/avis') ||
    modele == Routes.bienvenue ||
    modele == Routes.accesRefuse ||
    modele == Routes.horsLigne ||
    modele == Routes.agentEntree ||
    modele == Routes.mfaControleur ||
    modele.startsWith(Routes.galerie) ||
    // Les demonstrations n'existent qu'en developpement (`Env`), jamais en
    // production : hors du garde.
    modele.startsWith('/demo');

String _remplir(String modele) =>
    modele.replaceAllMapped(RegExp(r':(\w+)'), (Match m) => 'id-${m[1]}');

const Map<AppRole, String> _nomRole = <AppRole, String>{
  AppRole.guardian: 'famille',
  AppRole.student: 'eleve',
  AppRole.teacher: 'enseignant',
  AppRole.admin: 'direction',
  AppRole.controller: 'controle',
  AppRole.accountant: 'comptabilite',
};

/// Les infractions mesurees sur la page courante.
List<String> _mesurer(WidgetTester tester, PlanFil? plan, String chemin) {
  final List<String> infractions = <String>[];
  final bool barreLaterale =
      find.byKey(NavShell.barreLateraleKey).evaluate().isNotEmpty ||
      find.byKey(AdminShell.barreLateraleKey).evaluate().isNotEmpty;
  final bool barreBasse = find
      .byKey(NavShell.barreBasseKey)
      .evaluate()
      .isNotEmpty;
  final bool fil = find.byType(FilAriane).evaluate().isNotEmpty;
  final bool retour = find.byType(DisqueRetour).evaluate().isNotEmpty;
  if (!barreLaterale) infractions.add('B1');
  if (barreBasse) infractions.add('B1-barre-basse');
  if (!barreLaterale && !fil && !retour) infractions.add('B2');
  final bool racine =
      plan == null ||
      plan.racines.containsKey(chemin) ||
      plan.accueil.chemin == chemin;
  if (!racine && !fil) infractions.add('B3');
  // B4 : un texte suivi (plus de 68 caracteres) ne depasse pas 800 px.
  for (final Element e in find.byType(RichText).evaluate()) {
    final RenderObject? r = e.renderObject;
    if (r is RenderParagraph &&
        r.hasSize &&
        r.size.width > 800 &&
        r.text.toPlainText().length > 68) {
      infractions.add('B4');
      break;
    }
  }
  // B6 : la tete FIXE de la page mesure au plus 160 px. Une tete qui defile
  // avec le corps (elle est sous un `Scrollable` de la page) n'est pas collee
  // au-dessus du contenu : elle n'est pas concernee.
  for (final Element e in find.byKey(PageShell.teteKey).evaluate()) {
    final RenderObject? r = e.renderObject;
    if (r is RenderBox &&
        r.hasSize &&
        r.size.height > 160 &&
        !_defileAvecLeCorps(e)) {
      infractions.add('B6');
      _details.add('B6=${r.size.height.round()}');
      break;
    }
  }
  // B7 : la zone d'action collee mesure au plus 96 px.
  for (final Element e in find.byKey(PageShell.zoneActionKey).evaluate()) {
    final RenderObject? r = e.renderObject;
    if (r is RenderBox && r.hasSize && r.size.height > 96) {
      infractions.add('B7');
      break;
    }
  }
  // B5 : le bouton dessine (sa boite peinte), pas la rangee qui le porte.
  for (final Element e in find.byType(ActionPrincipale).evaluate()) {
    final Finder peint = find.descendant(
      of: find.byWidget(e.widget),
      matching: find.byType(DecoratedBox),
    );
    final Element? boite = peint.evaluate().firstOrNull;
    final RenderObject? r = boite?.renderObject;
    if (r is RenderBox && r.hasSize && r.size.width > 640) {
      infractions.add('B5');
      break;
    }
  }
  return infractions;
}

/// Vrai quand [tete] est sous un `Scrollable` de sa page : elle defile.
bool _defileAvecLeCorps(Element tete) {
  bool defile = false;
  tete.visitAncestorElements((Element a) {
    if (a.widget is PageShell) return false;
    if (a.widget is Scrollable) {
      defile = true;
      return false;
    }
    return true;
  });
  return defile;
}

Set<String> _lireExceptions() {
  final File f = File(_fichier);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((String l) => l.split('#').first.trim())
      .where((String l) => l.isNotEmpty)
      .toSet();
}

void main() {
  final Set<String> mesurees = <String>{};
  final List<String> journal = <String>[];

  for (final AppRole role in _nomRole.keys) {
    testWidgets('garde bureau : ${_nomRole[role]} a 1440', (
      WidgetTester tester,
    ) async {
      final SessionState session = sessionActive(role);
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: FausseSourceSession(session),
        taille: const Size(1440, 900),
        planFil: planFilPour(session),
        surcharges: <Override>[
          serviceCoranProvider.overrideWithValue(_CoranMuet()),
        ],
      );
      final PlanFil? plan = planFilPour(session);
      final Set<String> duRole = <String>{};
      final DateTime maintenant = DateTime.now();
      for (final String modele in cheminsDeclares(routeur)) {
        if (_horsDefinition(modele)) continue;
        if (!Env.galerieActive && modele.startsWith(Routes.galerie)) continue;
        final String chemin = _remplir(modele);
        if (deciderRedirection(
              session: session,
              cheminDemande: chemin,
              maintenant: maintenant,
            ) !=
            null) {
          continue;
        }
        routeur.go(chemin);
        await stabiliser(tester);
        // Un ecran qui leve sur des faux n'est pas l'objet de ce garde : il
        // est note, pas bloquant.
        final Object? erreur = tester.takeException();
        final String obtenu =
            routeur.routerDelegate.currentConfiguration.uri.path;
        final List<String> infractions = erreur != null
            ? <String>['rendu']
            : _mesurer(tester, plan, obtenu);
        for (final String regle in infractions) {
          duRole.add('${_nomRole[role]} $modele $regle');
        }
        journal.add(
          '${_nomRole[role]} $modele -> $obtenu : '
          '${infractions.isEmpty ? 'vert' : infractions.join(',')}'
          '${_details.isEmpty ? '' : ' (${_details.join(' ')})'}',
        );
        _details.clear();
      }
      mesurees.addAll(duRole);
      if (_ecrire) return;
      final Set<String> connues = _lireExceptions()
          .where((String l) => l.startsWith('${_nomRole[role]} '))
          .toSet();
      final List<String> nouvelles = duRole.difference(connues).toList()
        ..sort();
      final List<String> perimees = connues.difference(duRole).toList()..sort();
      expect(
        nouvelles,
        isEmpty,
        reason:
            'Regression de la page d ordinateur (infraction absente de '
            '$_fichier) :\n${nouvelles.join('\n')}',
      );
      expect(
        perimees,
        isEmpty,
        reason:
            'Exception qui n a plus lieu d etre : la retirer de $_fichier '
            '(la liste ne fait que retrecir) :\n${perimees.join('\n')}',
      );
    });
  }

  tearDownAll(() {
    if (!_ecrire) return;
    final List<String> lignes = mesurees.toList()..sort();
    File(_fichier).writeAsStringSync(
      '# WEB-BUREAU : infractions connues a 1440 (garde_bureau_test.dart).\n'
      '# Cette liste ne fait que retrecir. Format : role route regle.\n'
      '# Regles : B1 barre laterale, B1-barre-basse, B2 sortie, B3 fil,\n'
      '# B4 texte suivi de plus de 800 px, B5 bouton plein de plus de 640 px,\n'
      '# B6 tete de plus de 160 px, B7 pied de plus de 96 px,\n'
      '# rendu (ecran qui leve sur des faux).\n'
      '${lignes.join('\n')}\n',
    );
    File('test/web_bureau/journal_bureau.txt')
        .writeAsStringSync('${journal.join('\n')}\n');
  });
}
