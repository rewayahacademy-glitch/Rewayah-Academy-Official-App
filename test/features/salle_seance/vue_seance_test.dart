// La matrice des roles de la salle en tests purs : un test par ligne
// « jamais » (pilotage 10_classe/V/01_MATRICE_ROLES.md section 6).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

VueSeance _vue(RoleSeance r, [EtatDemoSalle e = EtatDemoSalle.visite]) =>
    DonneesSeanceDemo.vue(r, e);

/// Tous les textes qu'une vue peut produire, dans tous les etats et gabarits.
List<String> _textes(RoleSeance r) => <String>[
  for (final EtatDemoSalle e in EtatDemoSalle.values)
    ...<String?>[
      _vue(r, e).titre,
      _vue(r, e).ligneEtat,
      _vue(r, e).texteMention,
      _vue(r, e).texteNotice,
      _vue(r, e).compteurEleves,
      _vue(r, e).compte.nom,
      _vue(r, e).texteConnexion,
    ].whereType<String>(),
];

const List<RoleSeance> _eleves = <RoleSeance>[
  RoleSeance.eleve,
  RoleSeance.guidee,
];

void main() {
  group('RoleSeance.resoudre', () {
    test('eleve standard, guidee, enseignant', () {
      expect(
        RoleSeance.resoudre(RoleSalle.eleve, InterfaceMode.standard),
        RoleSeance.eleve,
      );
      expect(
        RoleSeance.resoudre(RoleSalle.eleve, InterfaceMode.enfant),
        RoleSeance.guidee,
      );
      expect(
        RoleSeance.resoudre(RoleSalle.enseignant, InterfaceMode.standard),
        RoleSeance.enseignant,
      );
    });

    test('les autres roles du jeton gardent l ancien rendu (null)', () {
      for (final RoleSalle r in <RoleSalle>[
        RoleSalle.tuteurObservateur,
        RoleSalle.controleur,
        RoleSalle.administrateurIncognito,
        RoleSalle.administrateurVisible,
        RoleSalle.inconnu,
      ]) {
        for (final InterfaceMode m in InterfaceMode.values) {
          expect(RoleSeance.resoudre(r, m), isNull, reason: '$r / $m');
        }
      }
    });
  });

  group('Eleve standard et guidee : jamais', () {
    for (final RoleSeance r in _eleves) {
      test('$r : aucun compteur ni liste d eleves', () {
        for (final EtatDemoSalle e in EtatDemoSalle.values) {
          expect(_vue(r, e).voitCompteurEleves, isFalse);
          expect(_vue(r, e).compteurEleves, isNull);
          expect(_vue(r, e).panneau, PanneauOuvert.aucun);
        }
      });

      test('$r : aucun bouton Eleves, Supports ni outil', () {
        for (final EtatDemoSalle e in EtatDemoSalle.values) {
          expect(_vue(r, e).voitBoutonsPanneaux, isFalse);
          expect(_vue(r, e).voitOutils, isFalse);
        }
      });

      test('$r : aucun bouton Reseau, aucun signal', () {
        expect(_vue(r).commandesDock, isNot(contains(CommandeDock.reseau)));
        expect(_vue(r).voitSignalVideo, isFalse);
      });

      test('$r : aucune pagination active, a aucune largeur', () {
        for (final Gabarit g in Gabarit.values) {
          expect(_vue(r).voitPaginationActive(g), isFalse, reason: '$g');
        }
      });

      test('$r : aucune duree restante', () {
        expect(_vue(r).voitDureeRestante, isFalse);
        for (final String s in _textes(r)) {
          expect(s, isNot(contains('restantes')));
        }
      });

      test('$r : jamais « Tuteur de »', () {
        for (final String s in _textes(r)) {
          expect(s.toLowerCase(), isNot(contains('tuteur de')));
        }
      });

      test('$r : le compte est le sien, jamais celui de l enseignante', () {
        expect(_vue(r).compte.nom, DonneesSeanceDemo.eleveCourant);
      });
    }

    test('guidee : ni zoom, ni indicateur de page, ni sous-titre', () {
      final VueSeance v = _vue(RoleSeance.guidee);
      for (final Gabarit g in Gabarit.values) {
        expect(v.voitZoomLocal(g), isFalse);
        expect(v.voitIndicateurPage(g), isFalse);
      }
      expect(v.ligneEtat, isNull);
      expect(v.voitReglagesEnTete, isFalse);
    });

    test('guidee : jamais « La seance se poursuit. »', () {
      final VueSeance v = _vue(RoleSeance.guidee)
          .copyWith(horloge: const HorlogeDepassee());
      expect(v.ligneEtat, isNull);
    });

    test('eleve : indicateur en lecture seule et zoom local, desktop seul', () {
      final VueSeance v = _vue(RoleSeance.eleve);
      expect(v.voitIndicateurPage(Gabarit.desktop), isTrue);
      expect(v.voitIndicateurPage(Gabarit.mobile), isFalse);
      expect(v.voitZoomLocal(Gabarit.desktop), VueSeance.optionQ6);
      expect(v.voitZoomLocal(Gabarit.tablette), isFalse);
    });
  });

  group('Enseignant : jamais', () {
    const RoleSeance r = RoleSeance.enseignant;

    test('jamais « Votre parent » ni « Ton parent »', () {
      for (final String s in _textes(r)) {
        expect(
          s,
          isNot(anyOf(contains('Votre parent'), contains('Ton parent'))),
        );
      }
    });

    test('jamais « Mariam » comme compte : le sien, SI Sayyid Ibrahim', () {
      for (final EtatDemoSalle e in EtatDemoSalle.values) {
        expect(_vue(r, e).compte.nom, 'Sayyid Ibrahim');
        expect(_vue(r, e).compte.initiales, 'SI');
      }
    });

    test('jamais Agrandir au dock ; dock compact EN-10', () {
      expect(_vue(r).commandesDock, <CommandeDock>[
        CommandeDock.supports,
        CommandeDock.micro,
        CommandeDock.camera,
        CommandeDock.partager,
        CommandeDock.outils,
        CommandeDock.reseau,
        CommandeDock.quitter,
      ]);
    });

    test('la ligne d etat ne porte pas son propre nom', () {
      expect(_vue(r).ligneEtat, isNot(contains('Sayyida')));
      expect(_vue(r).ligneEtat, 'Classe An-Nour · La séance se poursuit.');
      expect(
        _vue(r, EtatDemoSalle.repos).ligneEtat,
        'Classe An-Nour · \u200E32\u00A0min restantes',
      );
    });

    test('pagination active et zoom sur desktop seulement (I-7)', () {
      expect(_vue(r).voitPaginationActive(Gabarit.desktop), isTrue);
      expect(_vue(r).voitPaginationActive(Gabarit.mobile), isFalse);
      expect(_vue(r).voitPaginationActive(Gabarit.tablette), isFalse);
    });
  });

  group('Personne ne voit', () {
    for (final RoleSeance r in RoleSeance.values) {
      test(
        '$r : ni « Foyer », ni « present », ni « absent », ni controleur',
        () {
          for (final String s in _textes(r)) {
            final String bas = s.toLowerCase();
            expect(bas, isNot(contains('foyer')));
            expect(bas, isNot(contains('présent')));
            expect(bas, isNot(contains('absent')));
            expect(bas, isNot(contains('contrôleur')));
          }
        },
      );
    }
  });

  group('Notice de visite (I-2)', () {
    test(
      'eleve concerne : « Votre parent observe la seance. », point clignotant',
      () {
        final VueSeance v = _vue(RoleSeance.eleve);
        expect(v.texteNotice, 'Votre parent observe la séance.');
        expect(v.pointClignote, isTrue);
        expect(v.voitOeilNotice, isFalse);
      },
    );

    test('guidee concernee : « Ton parent… », point fixe et oeil', () {
      final VueSeance v = _vue(RoleSeance.guidee);
      expect(v.texteNotice, 'Ton parent observe la séance.');
      expect(v.pointClignote, isFalse);
      expect(v.voitOeilNotice, isTrue);
    });

    for (final RoleSeance r in _eleves) {
      test('$r non concerne : ni notice, ni clignotement', () {
        final VueSeance v = _vue(r).copyWith(
          visite: const VisiteSeance(prenomEnfant: 'Yusuf', concerneMoi: false),
        );
        expect(v.texteNotice, isNull);
        expect(v.pointClignote, isFalse);
        expect(v.texteMention, t.salle.bandeauPermanent);
      });
    }

    test('enseignant : toujours « Un parent observe cette séance » (EN-9)', () {
      final VueSeance v = _vue(RoleSeance.enseignant).copyWith(
        visite: const VisiteSeance(prenomEnfant: 'Yusuf', concerneMoi: false),
      );
      expect(v.texteNotice, 'Un parent observe cette séance');
      expect(v.pointClignote, isTrue);
    });

    test('au repos : mention seule, aucune notice', () {
      for (final RoleSeance r in RoleSeance.values) {
        final VueSeance v = _vue(r, EtatDemoSalle.repos);
        expect(v.texteNotice, isNull);
        expect(v.texteMention, t.salle.bandeauPermanent);
      }
    });

    test('enregistrement non confirme ou fin : aucune mention', () {
      for (final RoleSeance r in RoleSeance.values) {
        expect(_vue(r, EtatDemoSalle.fin).texteMention, isNull);
        expect(
          _vue(r).copyWith(enregistrementConfirme: false).texteMention,
          isNull,
        );
        expect(
          _vue(r).copyWith(enregistrementConfirme: false).texteNotice,
          isNull,
        );
      }
    });
  });

  group('Compteur derive de la liste (I-6)', () {
    test('« Eleves 1/3 » = nombre de « Connecte »', () {
      final VueSeance v = _vue(RoleSeance.enseignant);
      final int connectes = v.eleves
          .where((EleveSeance e) => e.statut == StatutEleveSeance.connecte)
          .length;
      expect(v.connectes, connectes);
      expect(v.compteurEleves, 'Élèves 1/3');
    });

    test('le compteur suit la liste quand elle change', () {
      final VueSeance v = _vue(RoleSeance.enseignant).copyWith(
        eleves: const <EleveSeance>[
          EleveSeance(prenom: 'A', statut: StatutEleveSeance.connecte),
          EleveSeance(prenom: 'B', statut: StatutEleveSeance.connecte),
        ],
      );
      expect(v.compteurEleves, 'Élèves 2/2');
    });

    test('fin : 2 connectes au moins une fois sur 3 inscrits', () {
      final VueSeance v = _vue(RoleSeance.enseignant, EtatDemoSalle.fin);
      expect(v.connectesAuMoinsUneFois, 2);
      expect(v.inscrits, 3);
    });
  });

  group('Titres et dock (I-4, I-9)', () {
    test('titres', () {
      expect(_vue(RoleSeance.eleve).titre, 'Séance en direct');
      expect(_vue(RoleSeance.guidee).titre, 'Ma séance');
      expect(_vue(RoleSeance.enseignant).titre, 'Séance en direct');
      expect(
        _vue(RoleSeance.eleve).ligneEtat,
        'Classe An-Nour · Sayyid Ibrahim',
      );
    });

    test('camera non autorisee : aucun bouton Camera pour l eleve', () {
      for (final RoleSeance r in _eleves) {
        final VueSeance v = _vue(r).copyWith(cameraAutorisee: false);
        expect(v.commandesDock, <CommandeDock>[
          CommandeDock.micro,
          CommandeDock.agrandir,
          CommandeDock.quitter,
        ]);
      }
    });

    test('rien partage : pas d Agrandir au dock de l eleve', () {
      for (final RoleSeance r in _eleves) {
        final VueSeance v = _vue(r).copyWith(sansSupport: true);
        expect(v.commandesDock, isNot(contains(CommandeDock.agrandir)));
        expect(v.commandesDock, contains(CommandeDock.quitter));
      }
    });
  });
}
