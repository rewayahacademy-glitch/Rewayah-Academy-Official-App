// Le controle `bouton-grise-conditionnel` (BOUTONS-GRISES-1) doit voir la
// vraie forme d'un bouton grise : l'action d'un widget d'action qui vaut
// `null` selon l'etat, ecrite en ternaire, en litteral ou par une variable.
// Il ne doit pas confondre une ligne sans action (contenu), un envoi deja
// parti ou le relais d'un composant du core.
import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_revue.dart';

List<String> _vus(String code, {String chemin = 'lib/features/x/page.dart'}) =>
    boutonsGrisesConditionnels(
      chemin,
      code,
    ).map((Violation v) => v.regle).toList();

void main() {
  group('bouton-grise-conditionnel : ce qu il voit', () {
    const Map<String, String> vus = <String, String>{
      'ternaire, branche nulle en premier':
          'ActionPrincipale(libelle: l, onPress: _piece == null ? null : '
          '() => unawaited(_envoyer()))',
      'ternaire, branche nulle en second':
          'ActionPrincipale(libelle: l, onPress: _complet && !horsLigne '
          '? () => unawaited(_valider()) : null, enCours: e)',
      'retour a la ligne':
          'LienFleche(\n  libelle: l,\n  onPress: _type == null\n'
          '      ? null\n      : () => unawaited(_choisir()),\n)',
      'bouton Material, onPressed': 'FilledButton(onPressed: ok ? f : null)',
      'bouton Material nomme':
          'FilledButton.tonal(onPressed: ok ? f : null, child: c)',
      'IconButton': 'IconButton(icon: i, onPressed: pret ? f : null)',
      'litteral null': 'ActionPrincipale(libelle: l, onPress: null)',
      'bouton prive qui enveloppe':
          '_BoutonZoom(icone: i, onPress: _peutReduire ? _reduire : null)',
      'variable posee nulle sous condition':
          'final VoidCallback? action = pret ? _envoyer : null;\n'
          'return ActionPrincipale(libelle: l, onPress: action);',
      'imbrique dans un autre widget':
          'Align(child: Column(children: <Widget>[ActionPrincipale('
          'libelle: l, onPress: x ? null : f)]))',
    };
    vus.forEach((String nom, String code) {
      test('detecte : $nom', () {
        expect(_vus(code), <String>['bouton-grise-conditionnel']);
      });
    });
  });

  group('bouton-grise-conditionnel : ce qu il laisse', () {
    const Map<String, String> laisses = <String, String>{
      'action toujours presente':
          'ActionPrincipale(libelle: l, onPress: () => unawaited(_envoyer()))',
      'ligne sans action (contenu, pas un bouton)':
          'LigneRubrique(libelle: l, onPress: ouvrable ? f : null)',
      'carte sans action': 'AppCard(onPress: ouvrir == null ? null : f)',
      'envoi deja parti': 'ActionPrincipale(onPress: _envoi ? null : f)',
      'travail en cours fige':
          'ActionPrincipale(libelle: l, enCours: true, onPress: null)',
      'fermeture qui teste dedans':
          'ActionPrincipale(onPress: () => ok ? f() : null)',
      'barre precedent suivant (la fleche disparait)':
          'BarrePrecedentSuivant(onPress: page > 1 ? f : null)',
    };
    laisses.forEach((String nom, String code) {
      test('laisse : $nom', () {
        expect(_vus(code), isEmpty);
      });
    });

    test('relais d un composant du core : son propre champ', () {
      expect(
        _vus(
          'Pressable.selon(onPress: enabled ? onSelected : null)',
          chemin: 'lib/core/widgets/schedule_option.dart',
        ),
        isEmpty,
      );
      // Le meme relais dans un ecran est une decision d'ecran : vu.
      expect(
        _vus('ActionPrincipale(onPress: actives ? onBibliotheque : null)'),
        <String>['bouton-grise-conditionnel'],
      );
    });

    test('voie TB, communications, finance, comptable : comptes a part', () {
      for (final String chemin in <String>[
        'lib/features/salle/salle_page.dart',
        'lib/features/tc_classe_live/classe_live_page.dart',
        'lib/features/tc_dock/barre_stylet.dart',
        'lib/features/com_messages/x.dart',
        'lib/features/admin_finance/x.dart',
        'lib/features/comptable/x.dart',
      ]) {
        expect(
          _vus('ActionPrincipale(onPress: ok ? f : null)', chemin: chemin),
          <String>['bouton-grise-conditionnel-exclu'],
          reason: chemin,
        );
      }
    });
  });

  test('estActionConditionnelleNulle : la forme seule', () {
    expect(estActionConditionnelleNulle('null'), isTrue);
    expect(estActionConditionnelleNulle('a ? null : b'), isTrue);
    expect(estActionConditionnelleNulle('a ? b : null'), isTrue);
    expect(estActionConditionnelleNulle('b'), isFalse);
    expect(estActionConditionnelleNulle('() => a ? b() : null'), isFalse);
  });
}
