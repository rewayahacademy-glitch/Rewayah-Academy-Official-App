// UX-009 (FOYER-UX, 06/11/2026) : l'Accueil affichait « Rejoindre la salle
// avec Yanis » (horloge de la classe, serveur) au-dessus de « Ouverture de la
// salle non confirmée pour l'instant » (seance sans fenetre). Un seul message
// vrai : l'horloge de la classe, quand elle ouvre la porte de la meme
// occurrence, dit l'etat.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final DateTime debut = DateTime.utc(2026, 10, 31, 18);
  const HorlogeAffichee paris = HorlogeAffichee(
    fuseauIana: 'Europe/Paris',
    libelleVille: 'Paris',
    heureLocaleRendue: '19:00',
    dateLocaleRendue: 'Samedi 31 octobre',
  );

  SessionClockVM horloge(DateTime maintenant, {String? sessionId = 's1'}) =>
      SessionClockVM.depuisFenetre(
        fenetre: FenetreSeance(
          debutUtc: debut,
          finPrevueUtc: debut.add(const Duration(minutes: 45)),
          fenetreAcces: const Duration(minutes: 20),
          graceApresFin: const Duration(minutes: 15),
        ),
        maintenantServeurUtc: maintenant,
        horlogeUtilisateur: paris,
        sessionId: sessionId,
      );

  // La seance de l'Accueil, sans fenetre rendue : `horaireIncertain`.
  final SeanceFamille sansFenetre = seanceFictive(
    debutUtc: debut,
    avecHorloge: false,
  );

  test('sans horloge de classe : toujours « non confirmée »', () {
    final AffichageSeance a = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      maintenantAppareilUtc: debut.add(const Duration(minutes: 5)),
    );
    expect(a.etat, EtatSeanceFamille.horaireIncertain);
    expect(a.ligneEtat, t.tuteur.accueil.horaireIncertainPendant);
    expect(a.aRecharger, isTrue);
  });

  test('ouverture non verifiee avant l heure : quand le bouton parait, '
      'avec le delai lu, jamais ecrit en dur', () {
    final AffichageSeance a = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      maintenantAppareilUtc: debut.subtract(const Duration(hours: 2)),
    );
    expect(a.etat, EtatSeanceFamille.horaireIncertain);
    // Sans fenetre ni horloge de classe : la constante unique (20 min).
    expect(a.ligneEtat, t.tuteur.accueil.horaireIncertainAvant(n: 20));
    expect(a.aRecharger, isFalse);
    // La fenetre de l'horloge de la classe prime quand elle est lue.
    final AffichageSeance b = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      maintenantAppareilUtc: debut.subtract(const Duration(hours: 2)),
      horlogeClasse: SessionClockVM.depuisFenetre(
        fenetre: FenetreSeance(
          debutUtc: debut,
          finPrevueUtc: debut.add(const Duration(minutes: 45)),
          fenetreAcces: const Duration(minutes: 15),
          graceApresFin: const Duration(minutes: 15),
        ),
        maintenantServeurUtc: debut.subtract(const Duration(hours: 2)),
        horlogeUtilisateur: paris,
        sessionId: 's1',
      ),
    );
    expect(b.ligneEtat, t.tuteur.accueil.horaireIncertainAvant(n: 15));
  });

  test('seance en cours, porte ouverte par la classe : « en direct »', () {
    final AffichageSeance a = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      horlogeClasse: horloge(debut.add(const Duration(minutes: 10))),
    );
    expect(a.etat, EtatSeanceFamille.enDirect);
    expect(a.ligneEtat, isNot(t.tuteur.accueil.horaireIncertainPendant));
  });

  test('salle ouverte avant le debut : « Salle ouverte », jamais « non '
      'confirmée »', () {
    final AffichageSeance a = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      horlogeClasse: horloge(debut.subtract(const Duration(minutes: 5))),
    );
    expect(a.etat, EtatSeanceFamille.salleOuverte);
    expect(a.ligneEtat, isNot(t.tuteur.accueil.horaireIncertainPendant));
  });

  test('meme debut sans identifiant de seance : la porte vaut aussi', () {
    expect(
      horlogeConfirmeLaPorte(horloge(debut, sessionId: null), sansFenetre),
      isTrue,
    );
  });

  test('une autre occurrence ne change rien', () {
    final SeanceFamille autre = seanceFictive(
      seanceId: 's2',
      debutUtc: debut.add(const Duration(days: 7)),
      avecHorloge: false,
    );
    final AffichageSeance a = AffichageSeance.depuis(
      autre,
      maintenantServeurUtc: null,
      horlogeClasse: horloge(debut.add(const Duration(minutes: 10))),
    );
    expect(a.etat, EtatSeanceFamille.horaireIncertain);
  });

  test('porte fermee (avant la fenetre) : rien ne change', () {
    final AffichageSeance a = AffichageSeance.depuis(
      sansFenetre,
      maintenantServeurUtc: null,
      horlogeClasse: horloge(debut.subtract(const Duration(hours: 2))),
    );
    expect(a.etat, EtatSeanceFamille.horaireIncertain);
  });

  test('le statut du serveur prime toujours (annulee)', () {
    final AffichageSeance a = AffichageSeance.depuis(
      seanceFictive(
        debutUtc: debut,
        avecHorloge: false,
        statut: StatutSeance.annulee,
      ),
      maintenantServeurUtc: null,
      horlogeClasse: horloge(debut.add(const Duration(minutes: 10))),
    );
    expect(a.etat, EtatSeanceFamille.annulee);
  });
}
