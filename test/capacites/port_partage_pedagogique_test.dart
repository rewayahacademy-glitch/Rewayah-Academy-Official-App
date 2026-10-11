// PED-APRES-1 : le port de partage pedagogique (contrat frontend, aucun
// adaptateur Supabase). La production dit « indisponible » pour chaque
// methode ; la demonstration n'existe que derriere le drapeau de demo ; la
// projection familiale ne sait porter ni note interne ni autre eleve ; les
// ecrans n'atteignent jamais `lesson_reports`.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/partage_pedagogique_demonstration.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';

void main() {
  group(
    'production : chaque methode dit ce qui manque, jamais un faux succes',
    () {
      const PortPartagePedagogique p = PartagePedagogiqueIndisponible();
      final Map<String, Future<Object?> Function()> methodes =
          <String, Future<Object?> Function()>{
            'compteRenduFamille': () =>
                p.compteRenduFamille(seanceId: 's', eleveId: 'e'),
            'partageClasse': () => p.partageClasse(classeId: 'c'),
            'definirPartageClasse': () => p.definirPartageClasse(
              classeId: 'c',
              actif: false,
              versionAttendue: 'v',
              cleIdempotence: 'k',
            ),
            'definirRegleEleve': () => p.definirRegleEleve(
              classeId: 'c',
              eleveId: 'e',
              regle: ReglePartageEleve.jamais,
              versionAttendue: 'v',
              cleIdempotence: 'k',
            ),
            'comptesRendusEleve': () =>
                p.comptesRendusEleve(classeId: 'c', eleveId: 'e'),
            'apercuFamilial': () =>
                p.apercuFamilial(seanceId: 's', eleveId: 'e'),
            'publier': () => p.publier(
              seanceId: 's',
              eleveId: 'e',
              versionAttendue: 'v',
              cleIdempotence: 'k',
            ),
            'revoquer': () => p.revoquer(
              seanceId: 's',
              eleveId: 'e',
              versionAttendue: 'v',
              cleIdempotence: 'k',
            ),
          };
      for (final MapEntry<String, Future<Object?> Function()> m
          in methodes.entries) {
        test(m.key, () {
          expect(
            m.value(),
            throwsA(
              isA<CapaciteIndisponible>().having(
                (CapaciteIndisponible e) => e.dependance,
                'dependance',
                PartagePedagogiqueIndisponible.dependance,
              ),
            ),
          );
        });
      }

      test('le provider de production est le port indisponible', () {
        final ProviderContainer c = ProviderContainer();
        addTearDown(c.dispose);
        expect(
          c.read(portPartagePedagogiqueProvider),
          isA<PartagePedagogiqueIndisponible>(),
        );
      });

      test('la demonstration ne sort que derriere le drapeau de demo', () {
        expect(
          portPartagePedagogiqueSelon(demo: false),
          isA<PartagePedagogiqueIndisponible>(),
        );
        expect(
          portPartagePedagogiqueSelon(demo: true),
          isA<PartagePedagogiqueDemonstration>(),
        );
      });
    },
  );

  group('la projection familiale', () {
    test('sans champ : aDuContenu est faux, jamais un contenu invente', () {
      expect(
        const CompteRenduFamille(etat: EtatCompteRendu.partage).aDuContenu,
        isFalse,
      );
      expect(
        const CompteRenduFamille(
          etat: EtatCompteRendu.partage,
          appreciation: '',
        ).aDuContenu,
        isFalse,
      );
      expect(
        const CompteRenduFamille(
          etat: EtatCompteRendu.partage,
          aPreparer: <String>['x'],
        ).aDuContenu,
        isTrue,
      );
    });

    test('ne porte que les cinq champs partageables et la correction', () {
      // Le type n'a aucun champ pour une note interne, un autre eleve ou la
      // paie : on le fige par l'ecriture de son constructeur.
      final String source = File(
        'lib/core/capacites/port_partage_pedagogique.dart',
      ).readAsStringSync();
      final int debut = source.indexOf('class CompteRenduFamille');
      final int fin = source.indexOf('/// La regle appliquee a un eleve.');
      final String classe = source.substring(debut, fin);
      final Iterable<String> champs = RegExp(r'final [^;]+? (\w+);')
          .allMatches(classe)
          .map((RegExpMatch m) => m.group(1)!);
      expect(champs.toList(), <String>[
        'etat',
        'travaille',
        'appreciation',
        'aRenforcer',
        'aPreparer',
        'commentairePartage',
        'corrigeLe',
      ]);
    });
  });

  group('l apercu et les decisions', () {
    ApercuAdmin apercu(EtatDiffusion e, {bool contenu = true}) => ApercuAdmin(
      seanceId: 's',
      eleveId: 'e',
      elevePrenom: 'Yusuf',
      classeLibelle: 'Classe',
      seanceLe: DateTime(2026, 10, 8),
      etat: e,
      regleEffective: true,
      version: 'v',
      apercu: contenu
          ? const CompteRenduFamille(
              etat: EtatCompteRendu.partage,
              travaille: 'x',
            )
          : const CompteRenduFamille(etat: EtatCompteRendu.aucunChamp),
    );

    test('publiable et revocable ne sont jamais vrais ensemble', () {
      for (final EtatDiffusion e in EtatDiffusion.values) {
        final ApercuAdmin a = apercu(e);
        expect(a.publiable && a.revocable, isFalse, reason: '$e');
      }
    });

    test('sans contenu partageable : jamais publiable', () {
      for (final EtatDiffusion e in EtatDiffusion.values) {
        expect(apercu(e, contenu: false).publiable, isFalse, reason: '$e');
      }
    });

    test('cahier non valide : ni publiable ni revocable', () {
      final ApercuAdmin a = apercu(EtatDiffusion.nonValide);
      expect(a.publiable, isFalse);
      expect(a.revocable, isFalse);
    });
  });

  group('la demonstration suit la priorite du contrat', () {
    test(
      'exception eleve > classe ; ecriture sur version perimee = conflit',
      () async {
        final PartagePedagogiqueDemonstration d =
            PartagePedagogiqueDemonstration();
        final PartageClasse lu = await d.partageClasse(classeId: 'c');
        final PartageEleve forcee = lu.eleves.firstWhere(
          (PartageEleve e) => e.eleveId == 'demo-eleve-3',
        );
        expect(forcee.regle, ReglePartageEleve.jamais);
        expect(forcee.visible, isFalse);
        expect(forcee.source, SourceRegle.exceptionEleve);
        await d.definirPartageClasse(
          classeId: 'c',
          actif: false,
          versionAttendue: lu.version,
          cleIdempotence: 'k1',
        );
        // Une seconde ecriture sur la meme version lue : conflit.
        expect(
          d.definirPartageClasse(
            classeId: 'c',
            actif: true,
            versionAttendue: lu.version,
            cleIdempotence: 'k2',
          ),
          throwsA(isA<ConflitPartage>()),
        );
      },
    );
  });

  group('frontend seul : aucun acces direct aux cahiers', () {
    test('les ecrans de partage ne lisent ni lesson_reports ni Supabase', () {
      for (final String chemin in <String>[
        'lib/core/capacites/port_partage_pedagogique.dart',
        'lib/core/capacites/partage_pedagogique_demonstration.dart',
        'lib/features/suivi_foyer/bloc_compte_rendu.dart',
        'lib/features/admin_groupes/reglage_partage.dart',
        'lib/features/admin_groupes/apercu_familial.dart',
        'lib/features/admin_groupes/partage_commun.dart',
      ]) {
        // Le code seulement : un commentaire peut nommer ce qu'il interdit.
        final String source = File(chemin)
            .readAsLinesSync()
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        expect(source, isNot(contains('lesson_reports')), reason: chemin);
        expect(source, isNot(contains('supabase')), reason: chemin);
        expect(source, isNot(contains('service_enseignant')), reason: chemin);
      }
    });
  });
}
