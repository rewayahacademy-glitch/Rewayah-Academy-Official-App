// PE-B3 (directeur, 05/11 et 19/11/2026, PLAN §2.7) : dans « Votre
// candidature », le candidat relit son nom en lettres latines et sa ville. Les
// cinq etats du bloc : chargement, contenu, vide, erreur (et hors connexion par
// le meme chemin), et l'arabe de droite a gauche.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/lieu/lieu.dart';
import 'package:rewayah_academy/features/candidature/identite_candidature.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../fixtures/candidature/faux_nom_latin.dart';
import 'hote_candidature.dart';

/// Un port du lieu qui ne sert que `mon_lieu`.
class _Lieu extends LieuAbsent {
  _Lieu({this.lieu, this.panne, this.attente});

  final LieuChoisi? lieu;
  Exception? panne;
  final Completer<void>? attente;
  int lectures = 0;

  @override
  Future<LieuChoisi?> monLieu() async {
    lectures++;
    if (attente != null) await attente!.future;
    final Exception? p = panne;
    if (p != null) throw p;
    return lieu;
  }
}

const LieuChoisi _casablanca = LieuChoisi(
  ville: 'Casablanca',
  paysCode: 'MA',
  fuseau: 'Africa/Casablanca',
  verifie: false,
);

Future<void> _monter(
  WidgetTester tester, {
  required _Lieu lieu,
  FauxNomLatin? nom,
  TextDirection? direction,
  bool attendre = true,
}) => monterQuestionnaire(
  tester,
  port: FauxMaCandidature(
    questionnaireJson: questionnaireJsonDeTest(
      dernieresReponses: reponsesCompletesDeTest(),
      brouillon: false,
    ),
  ),
  etat: etatCandidat(
    candidature: CandidatureDossier(
      existe: true,
      etape: EtapeCandidature.prequalification,
      etat: EtatCandidature.enExamen,
      version: 4,
      paiement: EtatVersement.aVerifier,
      questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
    ),
  ),
  direction: direction,
  attendre: attendre,
  surchargesEnPlus: <Override>[
    portLieuProvider.overrideWithValue(lieu),
    portNomLatinProvider.overrideWithValue(
      nom ?? FauxNomLatin(nomComplet: 'أمينة ديالو', nomLatin: 'Amina Diallo'),
    ),
  ],
);

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('contenu : le nom latin et la ville, sous l etat de l envoi', (
    WidgetTester tester,
  ) async {
    await _monter(tester, lieu: _Lieu(lieu: _casablanca));
    expect(find.text(t.recrutement.questionnaire.identiteTitre), findsOne);
    expect(find.byKey(BlocIdentiteCandidature.cleNomLatin), findsOne);
    expect(find.text(isolerSens('Amina Diallo')), findsOne);
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsOne);
    expect(find.textContaining('Casablanca'), findsOne);
    // Les reponses du questionnaire sont toujours la.
    expect(find.byKey(const ValueKey<String>('recap-publics')), findsOne);
  });

  testWidgets('vide : un nom deja latin et aucune ville, aucun bloc', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      lieu: _Lieu(),
      nom: FauxNomLatin(nomComplet: 'Amina Diallo'),
    );
    expect(find.text(t.recrutement.questionnaire.identiteTitre), findsNothing);
    expect(find.byKey(const ValueKey<String>('lecture-envoyee')), findsOne);
  });

  testWidgets('seulement la ville quand le nom n a rien a confirmer', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      lieu: _Lieu(lieu: _casablanca),
      nom: FauxNomLatin(nomComplet: 'Amina Diallo'),
    );
    expect(find.byKey(BlocIdentiteCandidature.cleNomLatin), findsNothing);
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsOne);
  });

  testWidgets('chargement : un squelette, puis le contenu', (
    WidgetTester tester,
  ) async {
    final Completer<void> attente = Completer<void>();
    await _monter(
      tester,
      lieu: _Lieu(lieu: _casablanca, attente: attente),
      attendre: false,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsNothing);
    attente.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsOne);
  });

  testWidgets('erreur : la page reste, « Reessayer » relit', (
    WidgetTester tester,
  ) async {
    final _Lieu lieu = _Lieu(lieu: _casablanca, panne: Exception('reseau'));
    await _monter(tester, lieu: lieu);
    expect(find.byKey(const ValueKey<String>('lecture-envoyee')), findsOne);
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsNothing);
    final Finder reessayer = find.text(t.commun.reessayer);
    expect(reessayer, findsOne);
    lieu.panne = null;
    await tester.ensureVisible(reessayer);
    await tester.tap(reessayer);
    await tester.pumpAndSettle();
    expect(find.byKey(BlocIdentiteCandidature.cleVille), findsOne);
  });

  testWidgets('arabe : la page de droite a gauche, le nom latin isole', (
    WidgetTester tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await _monter(
      tester,
      lieu: _Lieu(lieu: _casablanca),
      direction: TextDirection.rtl,
    );
    expect(find.text(t.recrutement.questionnaire.identiteTitre), findsOne);
    expect(find.text(isolerSens('Amina Diallo')), findsOne);
    expect(
      Directionality.of(
        tester.element(find.byKey(BlocIdentiteCandidature.cleNomLatin)),
      ),
      TextDirection.rtl,
    );
  });
}
