// Defaut 1.8 (robot pieges_1, 06/11/2026) : apres un rechargement, le prenom
// saisi pendant l'inscription etait perdu. Le brouillon se garde sur
// l'appareil le temps de l'inscription, puis s'efface.
//
// Un rechargement est simule par un nouveau conteneur : la memoire de
// l'application repart de zero, celle de l'appareil reste.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/brouillon_persistant.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/memoire_appareil.dart';

ProviderContainer _conteneur({bool persistant = true}) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      persistanceBrouillonProvider.overrideWithValue(persistant),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(oublierBrouillonInscription);
  tearDown(oublierBrouillonInscription);

  test('le prenom saisi survit a un rechargement', () {
    _conteneur().read(brouillonInscriptionProvider.notifier)
      ..choisirUsage(UsageInscription.moi)
      ..saisirIdentite(prenom: ' Amina ', nom: 'Diallo')
      ..choisirGenre(Genre.femme);
    final BrouillonInscription b = _conteneur().read(
      brouillonInscriptionProvider,
    );
    expect(b.usage, UsageInscription.moi);
    expect(b.prenom, 'Amina');
    expect(b.nom, 'Diallo');
    expect(b.genre, Genre.femme);
  });

  test('le candidat : telephone et « sans code » reviennent, pas la case', () {
    _conteneur().read(brouillonInscriptionProvider.notifier)
      ..deposerSansCode()
      ..saisirIdentite(prenom: 'Ibrahima', nom: 'Keita')
      ..saisirTelephone(pays: 'GN', numero: '622 12 34 56')
      ..accepterConfidentialite(acceptee: true);
    final BrouillonInscription b = _conteneur().read(
      brouillonInscriptionProvider,
    );
    expect(b.usage, UsageInscription.enseignant);
    expect(b.sansCode, isTrue);
    expect(b.paysTelephone, 'GN');
    expect(b.numeroTelephone, '622 12 34 56');
    // La case se recoche, a la version affichee.
    expect(b.confidentialiteAcceptee, isFalse);
  });

  test('le profil cree efface le brouillon garde', () {
    _conteneur().read(brouillonInscriptionProvider.notifier)
      ..choisirUsage(UsageInscription.moi)
      ..saisirIdentite(prenom: 'Amina', nom: 'Diallo')
      ..noterProfilCree();
    expect(lireMemoireAppareil(clefBrouillonInscription), isNull);
    expect(_conteneur().read(brouillonInscriptionProvider).prenom, isEmpty);
  });

  test('l inscription du candidat acceptee efface le brouillon garde', () {
    _conteneur().read(brouillonInscriptionProvider.notifier)
      ..deposerSansCode()
      ..saisirIdentite(prenom: 'Ibrahima', nom: 'Keita')
      ..noterInscriptionEnvoyee();
    expect(lireMemoireAppareil(clefBrouillonInscription), isNull);
  });

  test('au-dela de deux jours, le brouillon est oublie', () {
    ecrireBrouillonInscription(
      const BrouillonInscription(prenom: 'Amina'),
      maintenant: DateTime.now().subtract(const Duration(days: 3)),
    );
    expect(lireBrouillonInscription(), isNull);
    expect(lireMemoireAppareil(clefBrouillonInscription), isNull);
  });

  test('sans persistance (tests, autres usages), rien n est ecrit', () {
    _conteneur(persistant: false)
        .read(brouillonInscriptionProvider.notifier)
        .saisirIdentite(prenom: 'Amina', nom: 'Diallo');
    expect(lireMemoireAppareil(clefBrouillonInscription), isNull);
  });

  test('une valeur illisible est ignoree', () {
    ecrireMemoireAppareil(clefBrouillonInscription, '{pas du json');
    expect(_conteneur().read(brouillonInscriptionProvider).prenom, isEmpty);
  });
}
