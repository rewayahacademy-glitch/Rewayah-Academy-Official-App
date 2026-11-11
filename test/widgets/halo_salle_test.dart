// NAV-REFONTE 2b (directeur, 10/11/2026) : le halo vert de la salle ouverte,
// lu dans le calcul unique « salle rejoignable » (condition du garde-cap).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/carte_seance.dart';
import 'package:rewayah_academy/core/enseignant/cta_seance.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/ancre_horloge_serveur.dart';
import 'package:rewayah_academy/features/accueil_famille/salle_rejoignable.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart'
    show maintenantJourneeProvider;
import 'package:rewayah_academy/features/notifications/halo_salle.dart';

import '../fixtures/tuteur/faux_seances_famille.dart';
import '../support/harnais.dart';

const ProfilEleveFoyer _yasmine = ProfilEleveFoyer(
  eleveId: 'e1',
  prenom: 'Yasmine',
  nature: NatureProfilEleve.membreDuFoyer,
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

const ProfilEleveFoyer _adam = ProfilEleveFoyer(
  eleveId: 'e2',
  prenom: 'Adam',
  nature: NatureProfilEleve.membreDuFoyer,
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

/// Ni periode financee ni essai restant : seances fermees (FIN4-13).
const AccesBeneficiaire _ferme = AccesBeneficiaire(
  eleveId: 'e1',
  prenom: 'Yasmine',
  etatAffiche: EtatAccesAffiche.sansEcheance,
  seancesPayantesOuvertes: false,
  essaisUtilises: 2,
  essaisMax: 2,
);

// Le cours de Yasmine commence a 18:00 UTC ; la salle ouvre a 17:40.
final DateTime _debut = DateTime.utc(2026, 11, 11, 18);

EtatHaloCompte _salle({void Function(BuildContext)? agir}) =>
    EtatHaloCompte.salle(
      action: t.classe.seance.rejoindreAvec(prenom: 'Yasmine'),
      chemin: Routes.tuteurAccueil,
      agir: agir ?? (BuildContext _) {},
    );

/// Un conteneur ou Yasmine a sa seance a [_debut] et Adam aucune ; aucune
/// Classe (pas d'horloge de Classe), acces ouvert sauf [ferme].
ProviderContainer _foyer({bool ferme = false}) {
  final ProviderContainer conteneur = ProviderContainer(
    overrides: <Override>[
      profilsElevesFoyerProvider.overrideWith(
        (Ref _) async => <ProfilEleveFoyer>[_adam, _yasmine],
      ),
      prochaineSeanceProvider('e1').overrideWith(
        (Ref _) async =>
            seanceFictive(eleveId: 'e1', debutUtc: _debut, statut: null),
      ),
      prochaineSeanceProvider('e2').overrideWith((Ref _) async => null),
      classeDeLEleveProvider('e1').overrideWith((Ref _) async => null),
      classeDeLEleveProvider('e2').overrideWith((Ref _) async => null),
      accesEleveProvider('e1').overrideWith(
        (Ref _) => ferme
            ? const AsyncData<AccesBeneficiaire?>(_ferme)
            : const AsyncData<AccesBeneficiaire?>(null),
      ),
      accesEleveProvider('e2')
          .overrideWith((Ref _) => const AsyncData<AccesBeneficiaire?>(null)),
    ],
  );
  addTearDown(conteneur.dispose);
  return conteneur;
}

Future<void> _lire(ProviderContainer c) async {
  await c.read(profilsElevesFoyerProvider.future);
  await c.read(prochaineSeanceProvider('e1').future);
  await c.read(prochaineSeanceProvider('e2').future);
  await c.read(classeDeLEleveProvider('e1').future);
  await c.read(classeDeLEleveProvider('e2').future);
}

void main() {
  group('haloPrioritaire : un seul halo, Urgent puis salle puis Nouveau', () {
    final EtatHaloCompte urgent = EtatHaloCompte.urgent(
      titre: 'Alerte',
      chemin: Routes.tuteurFoyer,
    );
    final EtatHaloCompte nouveau = EtatHaloCompte.nouveau(
      nombre: 2,
      chemin: Routes.tuteurNotifications,
    );
    test('urgent l emporte sur la salle ouverte', () {
      expect(
        haloPrioritaire(notifications: urgent, salle: _salle()),
        same(urgent),
      );
    });
    test('la salle ouverte l emporte sur Nouveau', () {
      expect(
        haloPrioritaire(notifications: nouveau, salle: _salle())?.nature,
        NatureHalo.salle,
      );
    });
    test('sans salle : la cloche ; sans rien : aucun halo', () {
      expect(haloPrioritaire(notifications: nouveau, salle: null), nouveau);
      expect(haloPrioritaire(notifications: null, salle: null), isNull);
    });
  });

  group('salleDeLEleveProvider : la seule source cote tuteur', () {
    test(
      'avant l ouverture : fermee ; a 17:40 : ouverte par la seance',
      () async {
        final ProviderContainer c = _foyer();
        await _lire(c);
        final SalleDeLEleve avant = c.read(
          salleDeLEleveProvider((
            eleveId: 'e1',
            maintenantServeurUtc: _debut.subtract(const Duration(minutes: 30)),
          )),
        );
        expect(avant.rejoignable, isFalse);
        final SalleDeLEleve ouverte = c.read(
          salleDeLEleveProvider((
            eleveId: 'e1',
            maintenantServeurUtc: _debut.subtract(const Duration(minutes: 20)),
          )),
        );
        expect(ouverte.parSeance, isTrue);
        expect(ouverte.seance?.seanceId, 's1');
      },
    );

    test('sans horloge serveur : jamais ouverte par la seance', () async {
      final ProviderContainer c = _foyer();
      await _lire(c);
      expect(
        c
            .read(
              salleDeLEleveProvider((
                eleveId: 'e1',
                maintenantServeurUtc: null,
              )),
            )
            .rejoignable,
        isFalse,
      );
    });

    test('seances fermees (paiement) : jamais ouverte', () async {
      final ProviderContainer c = _foyer(ferme: true);
      await _lire(c);
      expect(
        c
            .read(
              salleDeLEleveProvider((
                eleveId: 'e1',
                maintenantServeurUtc: _debut,
              )),
            )
            .rejoignable,
        isFalse,
      );
    });

    test('le foyer : le premier profil dont la salle est ouverte', () async {
      final ProviderContainer c = _foyer();
      await _lire(c);
      expect(c.read(salleOuverteDuFoyerProvider(null)), isNull);
      final ({ProfilEleveFoyer eleve, SalleDeLEleve salle})? ouverte = c.read(
        salleOuverteDuFoyerProvider(_debut),
      );
      expect(ouverte?.eleve.eleveId, 'e1');
    });
  });

  group('carteSeanceEnseignantProvider : la seule source cote enseignant', () {
    SeanceEnseignant seance(DateTime debut) => SeanceEnseignant(
      id: 's1',
      debut: debut,
      fin: debut.add(const Duration(minutes: 45)),
      statut: StatutSeance.planifiee,
      nbParticipants: 3,
      cahierDepose: false,
      groupeId: 'g1',
    );
    test('salle ouverte : le bouton est Rejoindre', () async {
      final DateTime debut = DateTime(2026, 11, 11, 18);
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          seancesEnseignantProvider.overrideWith(
            (Ref _) async => <SeanceEnseignant>[seance(debut)],
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(seancesEnseignantProvider.future);
      expect(
        c
            .read(carteSeanceEnseignantProvider(DateTime(2026, 11, 11, 17)))
            ?.cta
            .etat,
        EtatCtaSeance.preparer,
      );
      expect(
        c
            .read(carteSeanceEnseignantProvider(DateTime(2026, 11, 11, 17, 50)))
            ?.cta
            .etat,
        EtatCtaSeance.rejoindre,
      );
    });
  });

  group('EtatHaloCompte.salle : jamais la couleur seule', () {
    test('nom lu, mot court, pastille, duree sous 5 s', () {
      final EtatHaloCompte h = _salle();
      expect(h.nomAccessible('Compte'), 'Compte, la salle est ouverte');
      expect(h.motCourt, t.tc.groupe.temps.salleOuverteCourt);
      expect(h.titre, t.classe.entree.annonce.fenetreOuverte);
      expect(h.couleurs, CouleursHalo.salle);
      // WCAG 2.2.2 : l'animation s'arrete avant cinq secondes.
      expect(h.dureeTour * h.tours <= const Duration(seconds: 5), isTrue);
    });

    test('rouge et vert se distinguent par la clarte (daltonisme)', () {
      final double vert = CouleursHalo.salle.pastille.background
          .computeLuminance();
      final double rouge = CouleursHalo.urgent.pastille.background
          .computeLuminance();
      // Une pastille claire face a une sombre : au moins 3:1 entre elles.
      expect((vert + 0.05) / (rouge + 0.05), greaterThanOrEqualTo(3));
      // L'icone de chaque pastille reste lisible (3:1, objet graphique).
      for (final AppHaloColor c in <AppHaloColor>[
        CouleursHalo.salle,
        CouleursHalo.urgent,
      ]) {
        final double a = c.pastille.background.computeLuminance();
        final double b = c.pastille.onBackground.computeLuminance();
        final double ratio =
            (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
        expect(ratio, greaterThanOrEqualTo(3));
      }
    });
  });

  group('HaloCompte vert : respire, puis lueur fixe', () {
    Widget halo({bool reduit = false}) => hote(
      Builder(
        builder: (BuildContext contexte) => MediaQuery(
          data: MediaQuery.of(contexte).copyWith(disableAnimations: reduit),
          child: Center(
            child: HaloCompte(
              etat: _salle(),
              diametre: 48,
              child: const SizedBox.square(dimension: 48),
            ),
          ),
        ),
      ),
    );

    testWidgets('la lumiere respire puis devient une lueur fixe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(halo());
      await tester.pump(AppMouvement.respirationHalo ~/ 2);
      expect(find.byKey(HaloCompte.lumiereKey), findsOneWidget);
      expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
      await tester.pump(
        AppMouvement.respirationHalo * AppMouvement.respirationsHalo,
      );
      await tester.pump();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
    });

    testWidgets('mouvement reduit : la lueur fixe d emblee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(halo(reduit: true));
      await tester.pump();
      expect(find.byKey(HaloCompte.lumiereKey), findsNothing);
      expect(find.byKey(HaloCompte.lueurKey), findsOneWidget);
      expect(find.byKey(HaloCompte.pastilleKey), findsOneWidget);
    });
  });

  testWidgets(
    'la feuille « En ce moment » : le bouton fait le geste de la salle',
    (WidgetTester tester) async {
      int gestes = 0;
      final List<String> chemins = <String>[];
      await tester.pumpWidget(
        hote(
          Builder(
            builder: (BuildContext contexte) => Center(
              child: TextButton(
                onPressed: () => ouvrirFeuilleEnCeMoment(
                  contexte,
                  etat: _salle(agir: (BuildContext _) => gestes++),
                  cheminCompte: Routes.tuteurCompte,
                  onAller: chemins.add,
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text(t.classe.entree.annonce.fenetreOuverte), findsOneWidget);
      await tester.tap(
        find.text(t.classe.seance.rejoindreAvec(prenom: 'Yasmine')),
      );
      await tester.pumpAndSettle();
      expect(gestes, 1);
      expect(chemins, isEmpty);
    },
  );

  group('aucun ecart entre le cercle et le bouton de l ecran', () {
    testWidgets('tuteur : sous HorlogeServeurPartagee, l ecran lit l instant '
        'de la coquille, pas le sien', (WidgetTester tester) async {
      final DateTime ancre = DateTime.utc(2026, 11, 11, 17, 40);
      final List<DateTime?> lus = <DateTime?>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ancreServeurProvider.overrideWith((Ref _) async => ancre),
          ],
          child: HorlogeServeurPartagee(
            // L'horloge de la coquille, figee : son instant reste l'ancre.
            horlogeAppareil: () => DateTime.utc(2026),
            child: _LecteurInstant(
              // Une autre horloge d'appareil, en avance de 25 s : sans
              // partage, l'ecran dirait un autre instant que la coquille.
              horloge: () => DateTime.now().add(const Duration(seconds: 25)),
              lus: lus,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(lus.last, ancre);
    });

    testWidgets('enseignant : le halo vert s allume a T-20 pile, avec la '
        'cadence de la Journee', (WidgetTester tester) async {
      final DateTime debut = DateTime(2026, 11, 11, 18);
      DateTime maintenant = debut.subtract(const Duration(minutes: 21));
      EtatHaloCompte? vu;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            maintenantJourneeProvider.overrideWithValue(() => maintenant),
            seancesEnseignantProvider.overrideWith(
              (Ref _) async => <SeanceEnseignant>[
                SeanceEnseignant(
                  id: 's1',
                  debut: debut,
                  fin: debut.add(const Duration(minutes: 45)),
                  statut: StatutSeance.planifiee,
                  nbParticipants: 3,
                  cahierDepose: false,
                  groupeId: 'g1',
                ),
              ],
            ),
          ],
          child: HaloVivant(
            role: AppRole.teacher,
            notifications: null,
            construire: (BuildContext _, EtatHaloCompte? halo) {
              vu = halo;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      expect(vu, isNull);
      // Une minute plus tard, a 17:40 pile : la Journee passe a
      // « Rejoindre », le cercle aussi, dans la meme image.
      maintenant = maintenant.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(vu?.nature, NatureHalo.salle);
    });
  });
}

/// Un ecran qui lit l'instant serveur par le meme mixin que l'Accueil.
class _LecteurInstant extends ConsumerStatefulWidget {
  const _LecteurInstant({required this.horloge, required this.lus});

  final DateTime Function() horloge;
  final List<DateTime?> lus;

  @override
  ConsumerState<_LecteurInstant> createState() => _EtatLecteurInstant();
}

class _EtatLecteurInstant extends ConsumerState<_LecteurInstant>
    with AncreHorlogeServeur<_LecteurInstant> {
  @override
  DateTime Function() get horlogeAppareil => widget.horloge;

  @override
  Widget build(BuildContext context) {
    widget.lus.add(maintenantServeur());
    return const SizedBox();
  }
}
