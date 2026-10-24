// CAND-07 : le parcours « Vos autres talents », sans ecran. Ce que le test
// prouve : les etapes (l'introduction saute quand on modifie), ce qui manque pour
// continuer a chaque etape, ce qui part au serveur (jamais un niveau presume,
// le texte « autre » seulement avec « autre »), et la cle d'idempotence (la meme
// tant que rien ne change, neuve des qu'une reponse change).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/features/talents/controleur_talents.dart';

import '../../fixtures/candidature/faux_autres_competences.dart';

AutresCompetences _lecture({Map<String, Object?>? reponses, int version = 0}) =>
    AutresCompetences.depuisJson(
      autresCompetencesJsonDeTest(reponses: reponses, version: version),
    );

ControleurTalents _controleur({
  Map<String, Object?>? reponses,
  int version = 0,
  bool avecIntroduction = true,
}) => ControleurTalents(
  lecture: _lecture(reponses: reponses, version: version),
  avecIntroduction: avecIntroduction,
);

void main() {
  group('les etapes', () {
    test('quatre etapes, l introduction d abord', () {
      final ControleurTalents c = _controleur();
      expect(c.etapes, <EtapeTalents>[
        EtapeTalents.introduction,
        EtapeTalents.competences,
        EtapeTalents.niveaux,
        EtapeTalents.disponibilite,
      ]);
      expect(c.courante, EtapeTalents.introduction);
      expect(c.estPremiere, isTrue);
    });

    test('qui modifie ses reponses saute l introduction', () {
      final ControleurTalents c = _controleur(
        reponses: reponsesJsonDeTest(),
        version: 2,
        avecIntroduction: false,
      );
      expect(c.etapes.first, EtapeTalents.competences);
      expect(c.etapes, hasLength(3));
    });

    test('avancer et reculer ne depassent pas les bornes', () {
      final ControleurTalents c = _controleur();
      c.reculer();
      expect(c.index, 0);
      for (int i = 0; i < 10; i++) {
        c.avancer();
      }
      expect(c.estDerniere, isTrue);
      expect(c.courante, EtapeTalents.disponibilite);
      c.reculer();
      expect(c.courante, EtapeTalents.niveaux);
    });
  });

  group('ce qui manque pour continuer', () {
    test('l introduction ne bloque jamais', () {
      expect(_controleur().manque(EtapeTalents.introduction), isNull);
    });

    test('aucune competence : on ne continue pas', () {
      expect(
        _controleur().manque(EtapeTalents.competences),
        ManqueTalents.aucuneCompetence,
      );
    });

    test('« Autre domaine » sans texte, ou avec des blancs : manque', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['autre'], <String>{'autre'});
      expect(c.manque(EtapeTalents.competences), ManqueTalents.autreVide);
      c.definirAutreTexte('   ');
      expect(c.manque(EtapeTalents.competences), ManqueTalents.autreVide);
      c.definirAutreTexte('Secrétariat médical');
      expect(c.manque(EtapeTalents.competences), isNull);
    });

    test('un texte plus long que la borne du serveur : trop long', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['autre'], <String>{'autre'});
      c.definirAutreTexte('a' * 200);
      expect(c.manque(EtapeTalents.competences), isNull);
      c.definirAutreTexte('a' * 201);
      expect(c.manque(EtapeTalents.competences), ManqueTalents.autreTropLong);
    });

    test('un niveau manque : le premier sans niveau est nomme', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      c.definirFamille(<String>['assistanat'], <String>{'assistanat'});
      c.definirNiveau('comptabilite', NiveauCompetence.metier);
      expect(c.manque(EtapeTalents.niveaux), ManqueTalents.niveau);
      expect(c.premierSansNiveau, 'assistanat');
      c.definirNiveau('assistanat', NiveauCompetence.debutant);
      expect(c.manque(EtapeTalents.niveaux), isNull);
    });

    test('la disponibilite manque tant qu aucune n est choisie', () {
      final ControleurTalents c = _controleur();
      expect(c.manque(EtapeTalents.disponibilite), ManqueTalents.disponibilite);
      c.definirDisponibilite(DisponibiliteMission.miTemps);
      expect(c.manque(EtapeTalents.disponibilite), isNull);
    });

    test(
      'rien n est presume : aucun niveau, aucune disponibilite, aucun accord',
      () {
        final ControleurTalents c = _controleur();
        expect(c.disponibilite, isNull);
        expect(c.accord, isFalse);
        c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
        expect(c.niveau('comptabilite'), isNull);
      },
    );
  });

  group('les choix d une famille', () {
    test('retirer une competence oublie son niveau, la garder le conserve', () {
      final ControleurTalents c = _controleur();
      const List<String> famille = <String>[
        'comptabilite',
        'gestion_financiere',
      ];
      c.definirFamille(famille, <String>{'comptabilite', 'gestion_financiere'});
      c.definirNiveau('comptabilite', NiveauCompetence.metier);
      c.definirNiveau('gestion_financiere', NiveauCompetence.debutant);
      c.definirFamille(famille, <String>{'comptabilite'});
      expect(c.estChoisie('gestion_financiere'), isFalse);
      expect(c.niveau('gestion_financiere'), isNull);
      expect(c.niveau('comptabilite'), NiveauCompetence.metier);
    });

    test('un choix dans une famille ne touche pas les autres', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      c.definirFamille(<String>['assistanat'], <String>{});
      expect(c.estChoisie('comptabilite'), isTrue);
    });

    test('les competences choisies suivent l ordre du catalogue', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      c.definirFamille(
        <String>['reseaux_sociaux'],
        <String>{'reseaux_sociaux'},
      );
      expect(
        <String>[for (final EntreeCatalogue e in c.competencesChoisies) e.code],
        <String>['reseaux_sociaux', 'comptabilite'],
      );
    });

    test(
      'des reponses enregistrees repartent : choix, niveaux, texte, accord',
      () {
        final ControleurTalents c = _controleur(
          reponses: reponsesJsonDeTest(
            domaines: const <String, String>{
              'autre': 'experience',
              'comptabilite': 'metier',
            },
            autreTexte: 'Secrétariat médical',
            disponibilite: 'plus',
            accord: false,
          ),
          version: 4,
          avecIntroduction: false,
        );
        expect(c.autreChoisi, isTrue);
        expect(c.autreTexte, 'Secrétariat médical');
        expect(c.niveau('comptabilite'), NiveauCompetence.metier);
        expect(c.disponibilite, DisponibiliteMission.plus);
        expect(c.accord, isFalse);
        expect(c.nombreChoisies, 2);
      },
    );
  });

  group('ce qui part au serveur', () {
    test('les domaines avec leur niveau, le texte « autre » nettoye', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(
        <String>['comptabilite', 'autre'],
        <String>{'comptabilite', 'autre'},
      );
      c.definirNiveau('comptabilite', NiveauCompetence.metier);
      c.definirNiveau('autre', NiveauCompetence.experience);
      c.definirAutreTexte('  Secrétariat médical  ');
      expect(c.domainesAEnvoyer, <String, NiveauCompetence>{
        'comptabilite': NiveauCompetence.metier,
        'autre': NiveauCompetence.experience,
      });
      expect(c.autreTexteAEnvoyer, 'Secrétariat médical');
    });

    test('sans « autre », aucun texte ne part, meme saisi puis decoche', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['autre'], <String>{'autre'});
      c.definirAutreTexte('Un texte');
      c.definirFamille(<String>['autre'], <String>{});
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      expect(c.autreTexteAEnvoyer, isNull);
    });

    test('un niveau jamais choisi ne part pas', () {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      expect(c.domainesAEnvoyer, isEmpty);
    });
  });

  group('la cle d idempotence', () {
    ControleurTalents pret() {
      final ControleurTalents c = _controleur();
      c.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      c.definirNiveau('comptabilite', NiveauCompetence.metier);
      c.definirDisponibilite(DisponibiliteMission.miTemps);
      return c;
    }

    test(
      'la meme tant que rien ne change : une issue incertaine se rejoue',
      () {
        final ControleurTalents c = pret();
        expect(c.cleIdempotence(), c.cleIdempotence());
        expect(c.cleIdempotence().length, inInclusiveRange(8, 200));
      },
    );

    test('neuve des qu une reponse change', () {
      final ControleurTalents c = pret();
      final String avant = c.cleIdempotence();
      c.definirNiveau('comptabilite', NiveauCompetence.experience);
      expect(c.cleIdempotence(), isNot(avant));
    });

    test('neuve apres une reponse definitive du serveur', () {
      final ControleurTalents c = pret();
      final String avant = c.cleIdempotence();
      c.oublierCle();
      expect(c.cleIdempotence(), isNot(avant));
    });

    test('l accord change la demande : une cle neuve', () {
      final ControleurTalents c = pret();
      final String avant = c.cleIdempotence();
      c.definirAccord(accord: true);
      expect(c.cleIdempotence(), isNot(avant));
    });
  });

  group('la reprise d un brouillon (une competence retiree du catalogue)', () {
    ControleurTalents brouillonDeTrois() {
      final ControleurTalents c = _controleur();
      c.definirFamille(
        <String>['comptabilite', 'reseaux_sociaux', 'autre'],
        <String>{'comptabilite', 'reseaux_sociaux', 'autre'},
      );
      c.definirNiveau('comptabilite', NiveauCompetence.metier);
      c.definirNiveau('reseaux_sociaux', NiveauCompetence.experience);
      c.definirAutreTexte('Secretariat medical');
      c.definirDisponibilite(DisponibiliteMission.miTemps);
      c.definirAccord(accord: true);
      return c;
    }

    ControleurTalents repris(
      BrouillonTalents brouillon, {
      Set<String> desactivees = const <String>{},
    }) => ControleurTalents(
      lecture: AutresCompetences.depuisJson(
        autresCompetencesJsonDeTest(desactivees: desactivees),
      ),
      avecIntroduction: false,
      reprise: brouillon,
    );

    test('le brouillon dit tout ce qui est choisi', () {
      final BrouillonTalents b = brouillonDeTrois().brouillon();
      expect(b.choisies, <String>{'comptabilite', 'reseaux_sociaux', 'autre'});
      expect(b.niveaux['comptabilite'], NiveauCompetence.metier);
      expect(b.autreTexte, 'Secretariat medical');
      expect(b.disponibilite, DisponibiliteMission.miTemps);
      expect(b.accord, isTrue);
    });

    test('sans changement du catalogue, tout est repris', () {
      final ControleurTalents c = repris(brouillonDeTrois().brouillon());
      expect(c.nombreChoisies, 3);
      expect(c.niveau('comptabilite'), NiveauCompetence.metier);
      expect(c.niveau('reseaux_sociaux'), NiveauCompetence.experience);
      expect(c.autreTexte, 'Secretariat medical');
      expect(c.disponibilite, DisponibiliteMission.miTemps);
      expect(c.accord, isTrue);
    });

    test('une competence que la lecture ne propose plus s en va, tout le '
        'reste est garde', () {
      final ControleurTalents c = repris(
        brouillonDeTrois().brouillon(),
        desactivees: <String>{'comptabilite'},
      );
      expect(c.estChoisie('comptabilite'), isFalse);
      expect(c.niveau('comptabilite'), isNull);
      expect(c.estChoisie('reseaux_sociaux'), isTrue);
      expect(c.niveau('reseaux_sociaux'), NiveauCompetence.experience);
      expect(c.autreChoisi, isTrue);
      expect(c.autreTexte, 'Secretariat medical');
      expect(c.disponibilite, DisponibiliteMission.miTemps);
      expect(c.accord, isTrue);
      expect(c.domainesAEnvoyer.keys, isNot(contains('comptabilite')));
    });

    test('une competence desactivee mais deja enregistree reste choisie '
        '(la personne la garde ou la decoche)', () {
      final ControleurTalents c = ControleurTalents(
        lecture: AutresCompetences.depuisJson(
          autresCompetencesJsonDeTest(
            version: 1,
            reponses: reponsesJsonDeTest(
              domaines: const <String, String>{'comptabilite': 'metier'},
            ),
            desactivees: <String>{'comptabilite'},
          ),
        ),
        avecIntroduction: false,
        reprise: brouillonDeTrois().brouillon(),
      );
      expect(c.estChoisie('comptabilite'), isTrue);
      expect(c.niveau('comptabilite'), NiveauCompetence.metier);
    });

    test('sans rien d autre, une competence retiree laisse « aucune '
        'competence » : Continuer le dit', () {
      final ControleurTalents source = _controleur();
      source.definirFamille(<String>['comptabilite'], <String>{'comptabilite'});
      final ControleurTalents c = repris(
        source.brouillon(),
        desactivees: <String>{'comptabilite'},
      );
      expect(c.nombreChoisies, 0);
      expect(
        c.manque(EtapeTalents.competences),
        ManqueTalents.aucuneCompetence,
      );
    });
  });
}
