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

  group('envoi deja parti : exempte seulement quand il est la seule '
      'condition (revue du verificateur)', () {
    const Map<String, String> vus = <String, String>{
      'hors ligne ou envoi (photo_publique)':
          'ActionPrincipale(onPress: horsLigne || _phase == _Phase.envoi '
          '? null : _utiliser)',
      'envoi ou profil cree (recapitulatif)':
          'ActionPrincipale(onPress: _envoi || brouillon.profilCree ? null '
          ': () => _modifier(route))',
      'envoi ou autre': 'ActionPrincipale(onPress: _envoi || autre ? null : x)',
      'decision en envoi ou hors ligne':
          'ActionPrincipale(onPress: e is DecisionEnvoi || horsLigne ? null '
          ': () => _confirmer(e))',
      'pret et pas en cours':
          'ActionPrincipale(onPress: pret && !_enCours ? f : null)',
    };
    vus.forEach((String nom, String code) {
      test('detecte : $nom', () {
        expect(_vus(code), <String>['bouton-grise-conditionnel']);
      });
    });
    const Map<String, String> laisses = <String, String>{
      'phase d envoi seule':
          'ActionPrincipale(onPress: _phase == _Phase.envoi ? null : x)',
      'envoi seul': 'ActionPrincipale(onPress: _envoi ? null : x)',
      'l autre reponse en vol':
          'ActionPrincipale(onPress: _enCours == _Reponse.accepter ? null : f)',
      'un retrait deja en cours':
          '_BoutonRetirer(onPress: retraitEnCours == null ? f : null)',
      'decision en envoi seule':
          'ActionPrincipale(onPress: e is DecisionEnvoi ? null : f)',
    };
    laisses.forEach((String nom, String code) {
      test('laisse : $nom', () {
        expect(_vus(code), isEmpty);
      });
    });
  });

  group('relais : la valeur nulle passee a un widget d ecran qui la remet '
      'a un bouton', () {
    const String carte = '''
class CarteGroupe extends StatelessWidget {
  final VoidCallback? onRejoindre;
  Widget build(BuildContext context) =>
      ActionPrincipale(libelle: l, onPress: onRejoindre);
}
''';
    const String emplacement = '''
class Emplacement extends StatefulWidget {
  final VoidCallback? onEntrer;
}
class _EmplacementState extends State<Emplacement> {
  Widget build(BuildContext context) =>
      ActionPrincipale(libelle: l, onPress: widget.onEntrer);
}
class CarteSession extends StatelessWidget {
  final VoidCallback? onRejoindre;
  Widget build(BuildContext context) => Emplacement(onEntrer: onRejoindre);
}
''';
    const String garde = '''
class CarteGardee extends StatelessWidget {
  final VoidCallback? onRejoindre;
  Widget build(BuildContext context) => Column(children: <Widget>[
    if (onRejoindre != null) ActionPrincipale(onPress: onRejoindre),
  ]);
}
''';
    final Map<String, Set<String>> relais = relaisAction(<String, String>{
      'lib/features/a/carte.dart': carte,
      'lib/features/b/emplacement.dart': emplacement,
      'lib/features/c/garde.dart': garde,
    });

    List<String> vusAvecRelais(String code) => boutonsGrisesConditionnels(
      'lib/features/x/page.dart',
      code,
      relais: relais,
    ).map((Violation v) => v.regle).toList();

    test('les relais sont trouves, directs et en chaine', () {
      expect(relais['CarteGroupe'], <String>{'onRejoindre'});
      expect(relais['Emplacement'], <String>{'onEntrer'});
      expect(relais['CarteSession'], <String>{'onRejoindre'});
      expect(relais.containsKey('CarteGardee'), isFalse);
    });

    test('detecte : hors ligne passe au relais (mes_groupes)', () {
      expect(
        vusAvecRelais(
          'CarteGroupe(onRejoindre: horsLigne || rappel == null ? null '
          ': () => rappel(groupe))',
        ),
        <String>['bouton-grise-conditionnel'],
      );
    });

    test('detecte : acces en lecture passe au relais en chaine', () {
      expect(
        vusAvecRelais('CarteSession(onRejoindre: enLecture ? null : f)'),
        <String>['bouton-grise-conditionnel'],
      );
    });

    test('laisse : relais garde (nul, le bouton n est pas rendu)', () {
      expect(vusAvecRelais('CarteGardee(onRejoindre: x ? null : f)'), isEmpty);
    });

    test('laisse : propagation du nul (rien de branche)', () {
      expect(
        vusAvecRelais(
          'CarteGroupe(onRejoindre: rappel == null ? null '
          ': () => rappel(groupe))',
        ),
        isEmpty,
      );
    });

    test('laisse : un widget qui ne relaie pas', () {
      expect(vusAvecRelais('Autre(onRejoindre: x ? null : f)'), isEmpty);
    });
  });

  test('conditionTernaire : la condition avant le ? de premier niveau', () {
    expect(conditionTernaire('a || b ? null : c'), 'a || b');
    expect(conditionTernaire('x?.y == null ? f : null'), 'x?.y == null');
    expect(conditionTernaire('(a ?? b) ? null : c'), '(a ?? b)');
    expect(conditionTernaire('f'), isNull);
  });

  test('estActionConditionnelleNulle : la forme seule', () {
    expect(estActionConditionnelleNulle('null'), isTrue);
    expect(estActionConditionnelleNulle('a ? null : b'), isTrue);
    expect(estActionConditionnelleNulle('a ? b : null'), isTrue);
    expect(estActionConditionnelleNulle('b'), isFalse);
    expect(estActionConditionnelleNulle('() => a ? b() : null'), isFalse);
  });
}
