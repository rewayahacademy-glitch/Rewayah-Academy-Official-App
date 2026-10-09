// EA-HL-DOUBLE-1 (decision du 04/10 deleguee par le directeur, K-42) : hors
// ligne se dit une seule fois. Le bandeau de `PageShell` est le signal ; une
// lecture deja faite reste affichee ; un bloc ne vient que si rien ne peut
// l'etre, et il dit ce qui manque.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

import '../../support/hors_ligne_une_fois.dart';

/// Les cles dont le texte peut encore dire « hors ligne » : des ecrans sans
/// `PageShell`, donc sans bandeau (la salle, `PageImmersive`), le bandeau
/// lui-meme, l'etat par defaut de la nature (galerie), et les etiquettes du
/// selecteur d'etats des demonstrations.
const Set<String> _permises = <String>{
  'reseau.horsLigne',
  'commun.etats.horsLigne.titre',
  'commun.etats.horsLigne.phrase',
  'salle.secours.horsLigne',
  'salle.preparation.eleve.demo.horsLigne',
  'salle.seance.demo.etats.horsLigne',
  'classe.entree.demo.etats.horsLigne',
  'enseignant.demo.etatHorsLigne',
  'adulte.demo.reseauCoupe',
  'tc.bibliotheque.offline.indisponible',
  'tc.bibliotheque.action.telecharger',
  'tc.bibliotheque.message.telechargementImpossible',
  // La salle et la classe en direct (`PageImmersive`, sans bandeau) disent
  // elles-memes l'etat de leur lien.
  'salle.secours.reconnexion',
  'salle.seance.statut.connexionInterrompue',
  'salle.lienPerdu',
  'tc.classe.reseau.perdu',
  'tc.classe.lien.echec',
  'tc.observation.visite.reconnexionDetail',
  'salle.refusReseauDetail',
  'salle.preparation.eleve.guidee.horsLigne',
  'salle.secours.echecGuidee',
  'salle.seance.demo.etats.echec',
  // La qualite du lien de la salle et de la classe en direct (« Connexion
  // instable », « Reseau faible »), dite par la salle elle-meme, sans
  // bandeau (EA-HL-DOUBLE-1e : la garde cherche desormais ces formes
  // partout ailleurs, sans exception).
  'salle.preparation.connexionInstable',
  'salle.preparation.reseauFaible',
  'salle.secours.reseauFaible',
  'salle.secours.reseauFaibleGuidee',
  'salle.lienMediocre',
  'tc.classe.reseau.mediocre',
  'tc.classe.lien.instable',
  // Etiquettes du selecteur d'etats des demonstrations de la salle.
  'salle.preparation.demo.reseauFaible',
  'salle.seance.demo.etats.reseauFaible',
  // Une cause passee, pas l'etat de l'appareil qui lit : la visite a pris
  // fin, ou le releve d'une seance terminee manque.
  'tc.observation.fin.deconnexion',
  'controleur.historique.faitsIndisponibles',
  'controleur.compteRendu.faitsAbsents',
  // Textes du cahier sources « commentaire du directeur, LIB-CAHIER-1 »
  // (tool/libelles_sources.json) : non reecrits par l'agent. Ils redisent le
  // reseau sous le bandeau ; l'arbitrage est remonte au directeur
  // (EA-HL-DOUBLE-1, reprise).
  'enseignant.cahier.enFileDetailHorsLigne',
  'enseignant.cahier.exceptionHorsLigne',
};

void _aplatir(Object? noeud, String chemin, Map<String, String> sortie) {
  if (noeud is Map<String, Object?>) {
    noeud.forEach(
      (String cle, Object? v) =>
          _aplatir(v, chemin.isEmpty ? cle : '$chemin.$cle', sortie),
    );
  } else if (noeud is String) {
    sortie[chemin] = noeud;
  }
}

void main() {
  group('lectureHorsLigne', () {
    // Un echec qui garde sa derniere valeur, tel que Riverpod le rend apres
    // une relecture ratee.
    late AsyncValue<int> echecAvecValeur;
    setUp(() async {
      int lectures = 0;
      final FutureProvider<int> source = FutureProvider<int>(
        (Ref _) => ++lectures == 1
            ? Future<int>.value(7)
            : Future<int>.error(StateError('reseau')),
        retry: (int _, Object _) => null,
      );
      final ProviderContainer conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);
      final ProviderSubscription<AsyncValue<int>> abonnement = conteneur.listen(
        source,
        (AsyncValue<int>? _, AsyncValue<int> _) {},
      );
      await conteneur.read(source.future);
      conteneur.invalidate(source);
      await expectLater(conteneur.read(source.future), throwsStateError);
      echecAvecValeur = abonnement.read();
    });

    test('hors ligne, un echec qui garde sa valeur rend la valeur', () {
      expect(echecAvecValeur.hasError, isTrue);
      final AsyncValue<int> vue = lectureHorsLigne(
        echecAvecValeur,
        horsLigne: true,
      );
      expect(vue.hasError, isFalse);
      expect(vue.requireValue, 7);
    });

    test('en ligne, l echec reste un echec', () {
      expect(
        lectureHorsLigne(echecAvecValeur, horsLigne: false).hasError,
        isTrue,
      );
    });

    test('sans valeur, l echec reste un echec', () {
      final AsyncValue<int> nu = AsyncError<int>(
        StateError('reseau'),
        StackTrace.empty,
      );
      expect(lectureHorsLigne(nu, horsLigne: true).hasError, isTrue);
    });
  });

  group('sansDonneesHorsLigne', () {
    test('hors ligne, en echec, sans valeur : vrai', () {
      expect(
        sansDonneesHorsLigne(
          AsyncError<int>(StateError('reseau'), StackTrace.empty),
          horsLigne: true,
        ),
        isTrue,
      );
    });

    test('en ligne : faux ; capacite absente : faux ; valeur : faux', () {
      final AsyncValue<int> echec = AsyncError<int>(
        StateError('reseau'),
        StackTrace.empty,
      );
      expect(sansDonneesHorsLigne(echec, horsLigne: false), isFalse);
      expect(
        sansDonneesHorsLigne(
          const AsyncError<int>(CapaciteIndisponible('X'), StackTrace.empty),
          horsLigne: true,
        ),
        isFalse,
      );
      expect(
        sansDonneesHorsLigne(const AsyncData<int>(1), horsLigne: true),
        isFalse,
      );
    });
  });

  testWidgets('EtatSansDonnees : dit ce qui manque, jamais « hors ligne »', (
    WidgetTester tester,
  ) async {
    int relectures = 0;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: EtatSansDonnees(
              quoi: t.adulte.maClasse.sansDonnees,
              onAction: () => relectures++,
            ),
          ),
        ),
      ),
    );
    final EtatSysteme etat = tester.widget<EtatSysteme>(
      find.byType(EtatSysteme),
    );
    expect(etat.nature, NatureEtat.horsLigne);
    expect(find.text(t.adulte.maClasse.sansDonnees), findsOneWidget);
    expect(signauxHorsLigne(), findsNothing);
    // La phrase par defaut du hors ligne redit le bandeau : jamais rendue.
    expect(phraseHorsLigneParDefaut(), findsNothing);
    expect(etat.phrase, isEmpty);
    await tester.tap(find.text(t.commun.etats.actions.reessayer));
    expect(relectures, 1);
  });

  test('catalogue : aucun texte ne redit « hors ligne » hors des cles '
      'permises (le bandeau, la salle sans bandeau, les demonstrations)', () {
    final Map<String, String> textes = <String, String>{};
    _aplatir(
      jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync()),
      '',
      textes,
    );
    final List<String> fautifs = <String>[
      for (final MapEntry<String, String> e in textes.entries)
        if (!_permises.contains(e.key) && motifHorsLigne.hasMatch(e.value))
          '${e.key} = ${e.value}',
    ];
    expect(fautifs, isEmpty);
  });

  // EA-HL-DOUBLE-1e (K-59, decide par delegation le 05/10, DIR-REP-1) :
  // « Rewayah n'a pas repondu » est inexact quand c'est l'appareil qui est
  // hors ligne. Un envoi ou une lecture restes sans reponse disent la cause
  // probable sans l'affirmer, en une seule formulation.
  test('catalogue : jamais « Rewayah n a pas repondu », une seule '
      'formulation de la cause probable', () {
    final Map<String, String> textes = <String, String>{};
    _aplatir(
      jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync()),
      '',
      textes,
    );
    expect(<String>[
      for (final MapEntry<String, String> e in textes.entries)
        if (RegExp(
          r'(Rewayah|le serveur) n.a pas répondu|'
          r'(Rewayah|le serveur) ne répond pas',
          caseSensitive: false,
        ).hasMatch(e.value))
          '${e.key} = ${e.value}',
    ], isEmpty);
    final RegExp formulation = RegExp(
      r'il est possible qu(.il|.elle|e la demande) ne soit pas parvenue? '
      r'jusqu.à Rewayah',
    );
    for (final String cle in <String>[
      'ficheEleve.interface.echec',
      'controleur.complement.echec',
      'controleur.compteRendu.echec',
      'controleur.compteRendu.echecRien',
      'controleur.compteRendu.visiteEchec',
      'controleur.observation.echec',
      'controleur.echanges.echec',
      'enseignant.journee.erreurPartielle',
      'enseignant.journee.erreurPartielleCahiers',
      'enseignant.journee.erreurPartielleTout',
      'adulte.accueil.echec',
      'adulte.historique.echec',
    ]) {
      expect(textes[cle], matches(formulation), reason: cle);
      expect(motifHorsLigne.hasMatch(textes[cle]!), isFalse, reason: cle);
    }
    // Les trois echecs partiels de la Journee, poses sous le bandeau, ne
    // nomment ni la connexion ni le reseau, sous aucune forme (pas meme
    // « connexion instable »).
    for (final String cle in <String>[
      'enseignant.journee.erreurPartielle',
      'enseignant.journee.erreurPartielleCahiers',
      'enseignant.journee.erreurPartielleTout',
    ]) {
      expect(
        RegExp('connexion|réseau', caseSensitive: false).hasMatch(textes[cle]!),
        isFalse,
        reason: cle,
      );
    }
  });

  // EA-HL-DOUBLE-1f (K-59, decide par delegation le 09/10, DIR-REP-1) : au
  // dela de « Rewayah n'a pas repondu », aucune autre cause cote service
  // n'est affirmee (« n'a pas repondu », « Service indisponible »,
  // « momentanement indisponible »), et les textes reecrits disent la cause
  // probable dans la formulation unique de EA-HL-DOUBLE-1e.
  test('catalogue : aucune cause cote service affirmee, formulation '
      'unique pour l agent, la salle et la bibliotheque', () {
    final Map<String, String> textes = <String, String>{};
    _aplatir(
      jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync()),
      '',
      textes,
    );
    // Une personne qui n'a pas repondu dans un delai, fait enregistre par
    // le serveur : ce n'est pas une cause supposee d'un echec de l'appareil.
    //
    // Une fonction que le serveur dit fermee (`CapaciteIndisponible`, ou le
    // code `indisponibleTemporairement` de la revue des dossiers), hors
    // ligne traite a part avant l'appel : fait annonce par le serveur, pas
    // cause supposee. Chacune est nommee ; aucune autre ne passe.
    const Set<String> faits = <String>{
      'adulte.reprise.phrases.attenteAdministration',
      // Acces de l'eleve ferme par le serveur (FI-9a) : copie du guide
      // §1.7, mot pour mot (JONCTION-LIGNES-1).
      'argent.acces.enfantTitre',
      'dossiers.file.indisponible',
      'dossiers.revue.pieceIndisponible',
      'dossiers.revue.etats.decisionIndisponible',
      'dossiers.refus.indisponible',
      'dossiers.validation.indisponible',
    };
    expect(<String>[
      for (final MapEntry<String, String> e in textes.entries)
        if (!faits.contains(e.key) && motifCauseAffirmee.hasMatch(e.value))
          '${e.key} = ${e.value}',
    ], isEmpty);
    for (final String cle in <String>[
      'agent.indisponibleDetail',
      'salle.refusReseauDetail',
      'tc.bibliotheque.indisponible.invitation',
      'tc.observation.refus.indisponibleInvitation',
      'classe.entree.indisponible',
      'adulte.accueil.echec',
      'adulte.historique.echec',
    ]) {
      expect(textes[cle], matches(formulationCauseProbable), reason: cle);
    }
    // L'entree d'agent et la bibliotheque sont sous le bandeau : ni la
    // connexion ni le reseau n'y sont redits.
    for (final String cle in <String>[
      'agent.indisponible',
      'agent.indisponibleDetail',
      'tc.bibliotheque.indisponible.message',
      'tc.bibliotheque.indisponible.invitation',
      'tc.observation.refus.indisponible',
      'tc.observation.refus.indisponibleInvitation',
      'classe.entree.indisponible',
      'tc.bibliotheque.message.copieImpossible',
      'compte.tuteur.pageInformations.fuseauIndisponible',
    ]) {
      expect(
        RegExp('connexion|réseau', caseSensitive: false).hasMatch(textes[cle]!),
        isFalse,
        reason: cle,
      );
    }
  });
}
