// COM-COMU-1 : la Communaute enseignants rendue dans la vraie coquille de
// l'enseignant, a 390, 768 et 1440 (spec section 23 : une surface a la fois,
// Flux | Publication, Flux | Publication | Aide/Regles), en clair et en
// sombre, a texte agrandi, en arabe (RTL) ; categories, recherche, etats
// (chargement, vide, erreur, indisponible, hors ligne), retour.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/com_communaute/communaute_page.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_communaute/publication_detail.dart';
import 'package:rewayah_academy/features/com_communaute/regles_communaute.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';

import '../../support/garde_interface.dart';
import 'banc_communaute.dart';

/// Les cartes du flux rendues.
int _cartes() => find
    .byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('communaute-carte-'),
    )
    .evaluate()
    .length;

bool _present(Key cle) => find.byKey(cle).evaluate().isNotEmpty;

/// Une Communaute dont la lecture ne repond jamais (etat de chargement).
class _CommunauteEnAttente implements PortCommunaute {
  final Completer<Never> _jamais = Completer<Never>();

  @override
  Future<CapacitesCommunaute> capacites() => _jamais.future;

  @override
  Future<List<CategorieCommunaute>> categories() => _jamais.future;

  @override
  Future<List<PublicationCommunaute>> publications({
    String? categorieId,
    String recherche = '',
  }) => _jamais.future;

  @override
  Future<PublicationCommunaute> publication(String publicationId) =>
      _jamais.future;

  @override
  Future<List<ReponseCommunaute>> reponses(String publicationId) =>
      _jamais.future;

  @override
  Future<PublicationCommunaute> publier(
    BrouillonPublication brouillon, {
    required String cleIdempotence,
  }) => _jamais.future;

  @override
  Future<ReponseCommunaute> repondre({
    required String publicationId,
    required String texte,
    required String cleIdempotence,
  }) => _jamais.future;
}

void main() {
  final c = t.com.communaute;

  group('disposition, dans la coquille Enseignant', () {
    testWidgets('390 : une surface a la fois, le flux de six publications', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester);

      // La vraie coquille de l'enseignant : Aujourd'hui est actif, jamais
      // « Foyer ».
      expect(find.byType(NavShell), findsOneWidget);
      expect(find.text(t.nav.enseignant.journee), findsWidgets);
      expect(find.text('Foyer'), findsNothing);
      expect(find.text(c.titre), findsOneWidget);

      expect(_cartes(), 6);
      expect(_present(SelecteurCategories.cle), isTrue);
      expect(_present(BandeauRegles.cle), isTrue);
      expect(_present(EntreeRechercheCommunaute.cle), isTrue);
      expect(_present(EntreeNouvellePublication.cle), isTrue);
      // Une seule surface : ni publication ouverte ni aide en colonne.
      expect(_present(EspaceTravailAdaptatif.cleContexte), isFalse);
      expect(find.byType(PublicationDetail), findsNothing);
      expect(_present(CommunautePage.cleBarreFiltres), isFalse);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('390 : ouvrir une publication, puis revenir au flux', (
      WidgetTester tester,
    ) async {
      final BancCommunaute banc = await monterCommunaute(tester);

      await taper(tester, find.byKey(FluxPublications.cleCarte('pub-niveaux')));
      expect(find.byType(PublicationDetail), findsOneWidget);
      expect(find.text('Gérer les différents niveaux ?'), findsOneWidget);
      // Le flux et son entree « Nouvelle publication » ont laisse la place.
      expect(_cartes(), 0);
      expect(_present(EntreeNouvellePublication.cle), isFalse);
      verifierUnSeulBoutonPlein(tester);

      // Le retour de la page ramene au flux, pas hors de la Communaute.
      await taper(tester, find.byType(DisqueRetour));
      expect(_cartes(), 6);
      expect(
        banc.routeur.routerDelegate.currentConfiguration.uri.path,
        '/enseignant/communaute',
      );

      // Depuis le flux, le retour quitte la Communaute vers Aujourd'hui.
      await taper(tester, find.byType(DisqueRetour));
      expect(find.text(texteJourneeBanc), findsOneWidget);
    });

    testWidgets('768 : dans la coquille Enseignant (rail a libelles), '
        'l espace recoit moins de 600 : une surface a la fois', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, taille: const Size(768, 1024));
      expect(
        colonnesPour(tester.getSize(find.byType(EspaceTravailAdaptatif)).width),
        1,
      );
      expect(_cartes(), 6);
      expect(_present(CommunautePage.cleBarreFiltres), isFalse);
      expect(_present(SelecteurCategories.cle), isTrue);
      expect(find.byType(PublicationDetail), findsNothing);
    });

    testWidgets('1024 : Flux | Publication, l aide en feuille', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, taille: const Size(1024, 1366));

      expect(_present(CommunautePage.cleBarreFiltres), isTrue);
      expect(_present(EspaceTravailAdaptatif.cleListe), isTrue);
      expect(_present(EspaceTravailAdaptatif.clePrincipal), isTrue);
      expect(_present(EspaceTravailAdaptatif.cleContexte), isFalse);
      expect(_present(CommunautePage.cleAucuneSelection), isTrue);
      // Sans colonne d'aide, le bandeau des regles reste dans le flux.
      expect(_present(BandeauRegles.cle), isTrue);

      await taper(
        tester,
        find.byKey(FluxPublications.cleCarte('pub-memorisation')),
      );
      expect(find.byType(PublicationDetail), findsOneWidget);
      expect(_cartes(), 6, reason: 'le flux reste a cote de la publication');

      // L'aide s'ouvre en feuille depuis le bouton du panneau.
      await taper(tester, find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte));
      expect(find.byKey(ReglesCommunaute.cle), findsOneWidget);
      expect(find.text(c.regles.titre), findsWidgets);
    });

    testWidgets('1440 : Flux | Publication/Reponses | Aide/Regles', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, taille: const Size(1440, 900));

      expect(_present(EspaceTravailAdaptatif.cleListe), isTrue);
      expect(_present(EspaceTravailAdaptatif.clePrincipal), isTrue);
      expect(_present(EspaceTravailAdaptatif.cleContexte), isTrue);
      expect(find.byKey(ReglesCommunaute.cle), findsOneWidget);
      // Les textes exacts de la politique (spec section 22).
      for (final String texte in <String>[
        'Partage pédagogique uniquement',
        'Cette communauté est réservée aux échanges professionnels entre '
            'enseignants.',
        'Aucune publicité',
        'Aucun lien affilié',
        'Aucune vente de produit ou de service',
        'Aucune sollicitation commerciale',
      ]) {
        expect(find.text(texte), findsOneWidget, reason: texte);
      }
      // L'aide est en colonne : pas de bandeau en double dans le flux.
      expect(_present(BandeauRegles.cle), isFalse);
      // Contrat A : pas de bouton pleine largeur sur ordinateur. Le bouton ne
      // depasse pas la colonne du flux ; le centrage sans `widthFactor`
      // d'`ActionPrincipale` (composant partage, revue COM-R, R-12) reste a
      // valider par le directeur.
      final double largeurBouton = tester
          .getSize(find.byKey(EntreeNouvellePublication.cle))
          .width;
      expect(
        largeurBouton,
        lessThanOrEqualTo(
          tester.getSize(find.byKey(EspaceTravailAdaptatif.cleListe)).width,
        ),
      );

      await taper(
        tester,
        find.byKey(FluxPublications.cleCarte('pub-memorisation')),
      );
      expect(find.text('Idées pour la mémorisation ?'), findsWidgets);
      expect(find.text(c.reponses.titre(nombre: 2)), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('sombre, texte a 200 % : rien ne deborde a 390', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        luminosite: Brightness.dark,
        echelleTexte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(_cartes(), greaterThan(0));
      // A 200 %, une carte depasse la hauteur visible : on touche son titre.
      await taper(tester, find.text('Idées pour la mémorisation ?'));
      expect(tester.takeException(), isNull);
      expect(find.byType(PublicationDetail), findsOneWidget);
    });

    testWidgets('arabe (RTL) a 390 et 1440 : miroir et textes traduits', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, arabe: true);
      final Finder page = find.byType(CommunautePage);
      expect(Directionality.of(tester.element(page)), TextDirection.rtl);
      expect(find.text('مجتمع المعلّمين'), findsOneWidget);
      expect(find.text('مشاركة تعليمية فقط'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await monterCommunaute(
        tester,
        arabe: true,
        taille: const Size(1440, 900),
      );
      // La colonne d'aide est au bord de fin : a gauche en arabe.
      final Rect flux = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleListe),
      );
      final Rect aide = tester.getRect(
        find.byKey(EspaceTravailAdaptatif.cleContexte),
      );
      expect(aide.left, lessThan(flux.left));
      expect(tester.takeException(), isNull);
    });
  });

  group('categories et recherche', () {
    testWidgets('une categorie filtre le flux ; « Toutes » le rend entier', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, taille: const Size(1440, 900));
      expect(_cartes(), 6);
      await choisirCategorie(tester, 'Gestion');
      expect(_cartes(), 2);
      expect(
        find.byKey(FluxPublications.cleCarte('pub-heure')),
        findsOneWidget,
      );
      await choisirCategorie(tester, c.toutes);
      expect(_cartes(), 6);
    });

    testWidgets('ordinateur : le champ persistant filtre, sans resultat dit '
        'quoi faire', (WidgetTester tester) async {
      await monterCommunaute(tester, taille: const Size(1440, 900));
      await tester.enterText(
        find.byKey(ClesRechercheCommunaute.champ),
        'cartes',
      );
      await tester.pumpAndSettle();
      expect(_cartes(), 1);
      await tester.enterText(
        find.byKey(ClesRechercheCommunaute.champ),
        'introuvable',
      );
      await tester.pumpAndSettle();
      expect(_cartes(), 0);
      expect(find.text(c.rechercheVide), findsOneWidget);
    });

    testWidgets('telephone : la recherche est une surface temporaire, la '
        'fermer rend le flux tel qu il etait', (WidgetTester tester) async {
      await monterCommunaute(tester);
      await choisirCategorie(tester, 'Ressources');
      expect(_cartes(), 2);

      await taper(tester, find.byKey(EntreeRechercheCommunaute.cle));
      expect(find.byKey(ClesRechercheCommunaute.champ), findsOneWidget);
      expect(_present(SelecteurCategories.cle), isFalse);
      expect(_present(EntreeNouvellePublication.cle), isFalse);
      await tester.enterText(find.byKey(ClesRechercheCommunaute.champ), 'fiche');
      await tester.pumpAndSettle();
      expect(_cartes(), 1);

      await taper(tester, find.byKey(ClesRechercheCommunaute.fermer));
      expect(find.byKey(ClesRechercheCommunaute.champ), findsNothing);
      // La categorie d'avant est restee : deux publications de Ressources.
      expect(_cartes(), 2);
    });
  });

  group('etats (spec section 25)', () {
    testWidgets('chargement : un squelette, aucune colonne inventee', (
      WidgetTester tester,
    ) async {
      fixerTaille(tester, const Size(390, 844));
      await monterCommunaute(tester, port: _CommunauteEnAttente());
      expect(_cartes(), 0);
      expect(find.byType(Skeleton), findsWidgets);
      await demonter(tester);
    });

    testWidgets('vide sur « Toutes » : « Aucune publication pour le '
        'moment. »', (WidgetTester tester) async {
      await monterCommunaute(tester, port: memoireDemo(vide: true));
      expect(_cartes(), 0);
      expect(find.text(c.videToutes), findsOneWidget);
      // On peut toujours publier la premiere.
      expect(_present(EntreeNouvellePublication.cle), isTrue);
    });

    testWidgets('erreur : « Reessayer » relit, puis le flux revient', (
      WidgetTester tester,
    ) async {
      final CommunauteMemoire memoire = memoireDemo();
      await monterCommunaute(tester, port: memoire);
      memoire.echecLecture = true;
      await choisirCategorie(tester, 'Pédagogie');
      expect(
        find.text(t.com.socle.composants.etats.erreurTitre),
        findsOneWidget,
      );
      expect(_present(EntreeNouvellePublication.cle), isFalse);
      memoire.echecLecture = false;
      await taper(tester, find.text(t.com.socle.composants.etats.reessayer));
      expect(_cartes(), 2);
    });

    testWidgets('port neutre de production : « Pas encore disponible », '
        'sans « Reessayer »', (WidgetTester tester) async {
      await monterCommunaute(tester, port: const CommunauteIndisponible());
      expect(
        find.text(t.com.socle.composants.etats.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.nature, NatureEtat.indisponible);
      expect(etat.dependance, 'COM-BR-05');
      expect(_cartes(), 0);
      expect(_present(EntreeNouvellePublication.cle), isFalse);
    });

    testWidgets('hors ligne : le bandeau, et la lecture en echec le dit', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(
        tester,
        port: memoireDemo(echecLecture: true),
        horsLigne: true,
      );
      // Les capacites n'ont pas pu etre lues : l'ecran le dit, sans colonne.
      expect(_cartes(), 0);
      expect(find.byType(EtatSysteme), findsWidgets);
    });

    testWidgets('hors ligne, contenu deja lu : le flux reste, le bandeau dit '
        'pourquoi rien ne s actualise', (WidgetTester tester) async {
      await monterCommunaute(tester, horsLigne: true);
      expect(_cartes(), 6);
      expect(find.byType(EtatSysteme), findsNothing);
    });

    testWidgets('une publication retiree se dit, et ramene au flux', (
      WidgetTester tester,
    ) async {
      await monterCommunaute(tester, publicationId: 'pub-retiree');
      expect(find.text(c.publication.introuvableTitre), findsOneWidget);
      await taper(tester, find.text(c.publication.revenir));
      expect(_cartes(), 6);
    });

    test('le port neutre leve CapaciteIndisponible COM-BR-05 partout', () {
      const CommunauteIndisponible port = CommunauteIndisponible();
      final List<Future<Object?>> appels = <Future<Object?>>[
        port.capacites(),
        port.categories(),
        port.publications(),
        port.publication('p'),
        port.reponses('p'),
        port.publier(
          const BrouillonPublication(categorieId: 'c', titre: 't', texte: 'x'),
          cleIdempotence: 'k',
        ),
        port.repondre(publicationId: 'p', texte: 'x', cleIdempotence: 'k'),
      ];
      for (final Future<Object?> appel in appels) {
        expect(
          appel,
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible e) => e.dependance,
              'dependance',
              'COM-BR-05',
            ),
          ),
        );
      }
      expect(
        const ChoixPieceIndisponible().choisir(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  testWidgets('la situation de demonstration « publication » ouvre la '
      'publication demandee', (WidgetTester tester) async {
    await monterCommunaute(
      tester,
      publicationId: DonneesCommunauteDemo.publicationOuverte,
    );
    expect(find.byType(PublicationDetail), findsOneWidget);
    expect(find.text('Idées pour la mémorisation ?'), findsOneWidget);
  });
}
