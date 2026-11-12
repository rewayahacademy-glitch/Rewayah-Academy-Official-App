// GOUTTE D'HUILE DES PROFILS : mesure par image (travail fait a CHAQUE image
// de l'animation), sans seuil de temps (un chrono dans un test est instable).
// Ce que la mesure dit : pendant le cou et la chute, le contenu de la page et
// le reste de l'ecran ne sont PAS reconstruits a chaque image ; seul le peintre
// de la goutte travaille. Ce qu'elle ne dit pas : le ressenti, ni le temps reel
// d'une image sur un telephone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/goutte_profils.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'a', prenom: 'Amina', etat: 'Dans 3 h'),
  ProfilSelectionnable(id: 'b', prenom: 'Bilal', etat: 'Aucune seance'),
  ProfilSelectionnable(id: 'c', prenom: 'Chaima', etat: 'Aucune seance'),
];

/// Un enfant qui compte ses constructions.
class _Sonde extends StatelessWidget {
  const _Sonde(this.compteur);

  final List<int> compteur;

  @override
  Widget build(BuildContext context) {
    compteur[0]++;
    return const SizedBox(height: 200, child: Center(child: Text('contenu')));
  }
}

void main() {
  mesureSousLePlafond();

  testWidgets('apres le changement de profil, ni le contenu ni le reste de '
      'l ecran ne sont reconstruits a chaque image (goutte coupee)', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String> selection = ValueNotifier<String>('a');
    final ValueNotifier<String> affiche = ValueNotifier<String>('a');
    final List<int> contenu = <int>[0];
    final List<int> reste = <int>[0];
    BuildContext? ctx;
    final Widget sondeContenu = _Sonde(contenu);
    final Widget sondeReste = _Sonde(reste);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[selection, affiche]),
              builder: (BuildContext context, Widget? _) => GoutteProfils(
                selectionId: selection.value,
                matiere: const Color(0xFF6B3FD0),
                matiereContenu: const Color(0xFFFFFFFF),
                rayonContenu: 16,
                child: Builder(
                  builder: (BuildContext c) {
                    ctx = c;
                    return Column(
                      children: <Widget>[
                        SelecteurProfils(
                          profils: _profils,
                          selectionId: selection.value,
                          onSelection: (String id) => selection.value = id,
                        ),
                        // Hors de la portee mouvante : un voisin.
                        sondeReste,
                        ContenuGoutte(
                          profilId: affiche.value,
                          child: sondeContenu,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Le toucher : une seule reconstruction de l'hote, puis l'animation.
    final int contenuAvant = contenu[0];
    final int resteAvant = reste[0];
    selection.value = 'c';
    affiche.value = 'c';
    await tester.pump();
    final int contenuAuToucher = contenu[0] - contenuAvant;
    final int resteAuToucher = reste[0] - resteAvant;

    // GOUTTE-COUPEE (11/11/2026) : plus aucune animation ; 40 images de 16 ms,
    // sans goutte ni chute a aucune.
    int images = 0;
    final int contenuDebut = contenu[0];
    final int resteDebut = reste[0];
    while (images < 40) {
      await tester.pump(const Duration(milliseconds: 16));
      images++;
      expect(GoutteProfils.goutteDe(ctx!), isNull);
      expect(GoutteProfils.chuteDe(ctx!), isNull);
    }
    final int contenuPendant = contenu[0] - contenuDebut;
    final int restePendant = reste[0] - resteDebut;
    // Le contenu est reconstruit a la bascule de phase (tombe, repos), jamais a chaque image ; le voisin jamais.
    expect(
      contenuPendant,
      lessThanOrEqualTo(6),
      reason:
          '$contenuPendant constructions du contenu sur $images images '
          '(au toucher : $contenuAuToucher)',
    );
    expect(
      restePendant,
      lessThanOrEqualTo(1),
      reason:
          '$restePendant constructions du voisin sur $images images '
          '(au toucher : $resteAuToucher)',
    );
    debugPrint(
      'CADENCE images=$images contenu_pendant=$contenuPendant '
      'voisin_pendant=$restePendant contenu_au_toucher=$contenuAuToucher '
      'voisin_au_toucher=$resteAuToucher',
    );
  });
}

// GARDE-CAP (11/11/2026) : choisir un profil est une action « instantanee »
// (DECISION-FLUIDITE §1) ; le mouvement ENTIER (cou entre les ronds, chute du
// contenu) tient sous `AppMouvement.plafond`. Mesure en images, de pump a pump ;
// la duree vient du plafond, jamais d'un nombre ecrit a la main.
void mesureSousLePlafond() {
  testWidgets('le mouvement entier tient sous le plafond de mouvement', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<String> selection = ValueNotifier<String>('a');
    final ValueNotifier<String> affiche = ValueNotifier<String>('a');
    BuildContext? ctx;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[selection, affiche]),
              builder: (BuildContext context, Widget? _) => GoutteProfils(
                selectionId: selection.value,
                matiere: const Color(0xFF6B3FD0),
                matiereContenu: const Color(0xFFFFFFFF),
                rayonContenu: 16,
                child: Builder(
                  builder: (BuildContext c) {
                    ctx = c;
                    return Column(
                      children: <Widget>[
                        SelecteurProfils(
                          profils: _profils,
                          selectionId: selection.value,
                          onSelection: (String id) => selection.value = id,
                        ),
                        ContenuGoutte(
                          profilId: affiche.value,
                          child: const Text('contenu'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    // Le toucher : selection et donnees (deja en memoire) dans la meme image.
    selection.value = 'c';
    affiche.value = 'c';
    await tester.pump();
    const Duration image = Duration(milliseconds: 8);
    Duration ecoule = Duration.zero;
    bool encore = true;
    while (encore && ecoule <= AppMouvement.plafond * 3) {
      await tester.pump(image);
      ecoule += image;
      encore =
          GoutteProfils.goutteDe(ctx!) != null ||
          GoutteProfils.chuteDe(ctx!) != null;
    }
    debugPrint('PLAFOND mouvement entier = ${ecoule.inMilliseconds} ms');
    expect(
      ecoule,
      lessThanOrEqualTo(AppMouvement.plafond),
      reason:
          'le mouvement entier dure ${ecoule.inMilliseconds} ms, '
          'au-dela du plafond ${AppMouvement.plafond.inMilliseconds} ms',
    );
  });
}
