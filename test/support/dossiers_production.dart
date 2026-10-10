import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';

/// Tape la premiere ligne de la file `ADM-02A` (panneau unique), comme
/// l'administrateur, pour ouvrir la revue du dossier. Rend vrai si une ligne
/// a ete ouverte, faux si la file est vide ou en erreur (AD-NETTOYAGE-2, n11) :
/// des tests montent volontairement une file vide, donc le helper ne peut pas
/// echouer lui-meme ; tout test qui ATTEND un dossier ouvert asserte le
/// retour (`expect(await ouvrirPremierDossier(tester), isTrue, ...)`) au lieu
/// de compter sur une assertion plus loin.
Future<bool> ouvrirPremierDossier(WidgetTester tester) async {
  final Finder lignes = find.bySemanticsLabel(RegExp('^Ouvrir le dossier'));
  if (lignes.evaluate().isEmpty) {
    return false;
  }
  await tester.tap(lignes.first);
  await tester.pumpAndSettle();
  return true;
}

/// L'adaptateur de production tel que BR-1 le rebranchera : signature de la
/// piece, `decider_dossier` et relecture de la file sur `ServiceValidation`.
/// AD-M3-PROD ferme ces trois capacites dans `surchargeRevueDossiersProduction`
/// jusqu'a BR-1 ; les tests du refus et de la visionneuse passent par ici.
final Override surchargeRevueDossiersBrancheeBR1 = portRevueDossiersProvider
    .overrideWith(
      (Ref ref) => RevueDossiersDepuisValidation(
        () => ref.read(dossiersEnAttenteProvider.future),
        apercu: (String cle) => ref.read(serviceValidationProvider).apercu(cle),
        deciderExistant: ref.read(serviceValidationProvider).decider,
        relire: () {
          ref.invalidate(dossiersEnAttenteProvider);
          return ref.read(dossiersEnAttenteProvider.future);
        },
      ),
    );
