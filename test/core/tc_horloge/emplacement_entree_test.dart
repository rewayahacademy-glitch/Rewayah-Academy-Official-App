// CL-4.2 : le modele d'etats de l'emplacement d'entree unique (R4 a R6).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';

void main() {
  final DateTime t0 = DonneesClasseDemo.debutUtc;
  final DateTime ouverture = DonneesClasseDemo.ouvertureUtc;
  final DateTime fin = DonneesClasseDemo.finPrevueUtc;
  final DateTime fermeture = DonneesClasseDemo.fermetureUtc;

  SessionClockVM horloge(
    DateTime maintenant, {
    bool connecte = false,
    NoticeDst? dst,
  }) => SessionClockVM.depuisFenetre(
    fenetre: DonneesClasseDemo.fenetre,
    maintenantServeurUtc: maintenant,
    horlogeUtilisateur: DonneesClasseDemo.horlogeUtilisateur,
    connecte: connecte,
    noticeDst: dst,
  );

  EmplacementEntree a(
    DateTime maintenant, {
    RoleEntree role = RoleEntree.eleve,
    bool connecte = false,
    bool preparation = false,
    NoticeDst? dst,
  }) => EmplacementEntree.pour(
    role: role,
    horloge: horloge(maintenant, connecte: connecte, dst: dst),
    nomClasse: DonneesClasseDemo.classe,
    preparationEnCours: preparation,
  );

  group('transitions', () {
    test('a venir : ligne d etat « Cours dans ... », pas de bouton', () {
      final EmplacementEntree e = a(t0.subtract(const Duration(hours: 3)));
      expect(e.etat, EtatEntree.aVenir);
      expect(e.forme, FormeEntree.ligne);
      expect(e.estBouton, isFalse);
      expect(e.libelle, 'Cours dans 3 h');
      expect(e.libelleLecteur, isNull);
    });

    test(
      'fenetre ouverte : Rejoindre (eleve, guidee), Preparer (enseignant)',
      () {
        final DateTime m = t0.subtract(const Duration(minutes: 8));
        for (final RoleEntree role in <RoleEntree>[
          RoleEntree.eleve,
          RoleEntree.eleveGuide,
        ]) {
          final EmplacementEntree e = a(m, role: role);
          expect(e.etat, EtatEntree.fenetreOuverte);
          expect(e.forme, FormeEntree.bouton);
          expect(e.libelle, 'Rejoindre');
          expect(e.libelleLecteur, 'Rejoindre la séance de Classe An-Nour');
          expect(
            e.detail,
            'La salle est ouverte. La séance commence dans 8 min.',
          );
        }
        final EmplacementEntree ens = a(m, role: RoleEntree.enseignant);
        expect(ens.libelle, "Préparer l'entrée");
        expect(ens.forme, FormeEntree.bouton);
      },
    );

    test('preparation en cours : ligne d etat', () {
      final EmplacementEntree e = a(
        t0.subtract(const Duration(minutes: 5)),
        role: RoleEntree.enseignant,
        preparation: true,
      );
      expect(e.etat, EtatEntree.preparation);
      expect(e.forme, FormeEntree.ligne);
      expect(e.libelle, 'Préparation en cours');
    });

    test('attente avant le debut : deja dans la salle', () {
      final EmplacementEntree e = a(
        t0.subtract(const Duration(minutes: 3)),
        connecte: true,
      );
      expect(e.etat, EtatEntree.attente);
      expect(e.estBouton, isTrue);
      expect(
        e.detail,
        'Vous êtes dans la salle. La séance commence dans 3 min.',
      );
    });

    test('en direct puis temps prevu ecoule, jamais negatif (R6)', () {
      final EmplacementEntree direct = a(t0.add(const Duration(minutes: 10)));
      expect(direct.etat, EtatEntree.enDirect);
      expect(direct.detail, 'Séance en direct');
      final EmplacementEntree ecoule = a(fin.add(const Duration(minutes: 5)));
      expect(ecoule.etat, EtatEntree.enDirect);
      expect(ecoule.detail, 'Séance en direct · Temps prévu écoulé');
      expect(ecoule.detail, isNot(contains('-')));
    });

    test('terminee, annulee, aucune : lignes d etat', () {
      expect(
        a(fermeture.add(const Duration(minutes: 1))).etat,
        EtatEntree.terminee,
      );
      final EmplacementEntree annulee = EmplacementEntree.pour(
        role: RoleEntree.eleve,
        horloge: horloge(t0),
        nomClasse: 'X',
        annulee: true,
      );
      expect(annulee.etat, EtatEntree.annulee);
      expect(annulee.forme, FormeEntree.ligne);
      final EmplacementEntree aucune = EmplacementEntree.pour(
        role: RoleEntree.enseignant,
        horloge: null,
        nomClasse: 'X',
      );
      expect(aucune.etat, EtatEntree.aucune);
    });

    test('hors ligne et lecture echouee : indisponible, Reessayer', () {
      for (final bool horsLigne in <bool>[true, false]) {
        final EmplacementEntree e = EmplacementEntree.pour(
          role: RoleEntree.eleve,
          horloge: horloge(t0.subtract(const Duration(minutes: 5))),
          nomClasse: 'X',
          horsLigne: horsLigne,
          lectureEchouee: !horsLigne,
        );
        expect(e.etat, EtatEntree.indisponible);
        expect(e.forme, FormeEntree.ligne);
        expect(e.reessayer, isTrue);
      }
    });
  });

  group('bornes', () {
    test('T-20 exact : la fenetre est ouverte, une seconde avant non', () {
      expect(t0.difference(ouverture), const Duration(minutes: 20));
      expect(a(ouverture).etat, EtatEntree.fenetreOuverte);
      final EmplacementEntree avant = a(
        ouverture.subtract(const Duration(seconds: 1)),
      );
      expect(avant.etat, EtatEntree.aVenir);
      expect(avant.libelle, 'Cours dans 20 min');
    });

    test('T0 exact : en direct', () {
      expect(a(t0).etat, EtatEntree.enDirect);
      final EmplacementEntree juste = a(
        t0.subtract(const Duration(seconds: 30)),
      );
      expect(juste.etat, EtatEntree.fenetreOuverte);
      expect(
        juste.detail,
        "La salle est ouverte. La séance commence dans moins d'une minute.",
      );
    });

    test('fin prevue exacte : temps ecoule ; fermeture : terminee', () {
      expect(a(fin).detail, contains('Temps prévu écoulé'));
      expect(a(fermeture).etat, EtatEntree.terminee);
    });

    test('aucun temps negatif, meme avec un restant negatif injecte', () {
      final SessionClockVM h = horloge(t0.subtract(const Duration(hours: 2)));
      final SessionClockVM faux = SessionClockVM(
        debutUtc: h.debutUtc,
        finPrevueUtc: h.finPrevueUtc,
        joinOpensAtUtc: h.joinOpensAtUtc,
        fenetreAcces: h.fenetreAcces,
        graceApresFin: h.graceApresFin,
        horlogeUtilisateur: h.horlogeUtilisateur,
        phase: PhaseSeance.avantFenetre,
        rejoindreOuvert: false,
        calculeeAUtc: h.calculeeAUtc,
      );
      final EmplacementEntree e = EmplacementEntree.pour(
        role: RoleEntree.eleve,
        horloge: faux,
        nomClasse: 'X',
      );
      expect(e.libelle, "Cours dans moins d'une minute");
      for (int s = -7200; s <= 7200; s += 97) {
        final EmplacementEntree x = a(t0.add(Duration(seconds: s)));
        expect(x.libelle, isNot(contains('-')));
        expect(x.detail ?? '', isNot(contains('-')));
      }
    });

    test(
      'saut d horloge : recalcul depuis le nouvel instant, sans compteur',
      () {
        final EmplacementEntree avant = a(
          t0.subtract(const Duration(hours: 1)),
        );
        expect(avant.etat, EtatEntree.aVenir);
        // Retour d'arriere-plan 70 min plus tard : l'etat saute sans etape.
        final EmplacementEntree apres = a(t0.add(const Duration(minutes: 10)));
        expect(apres.etat, EtatEntree.enDirect);
        // Correction d'horloge en arriere : on revient a l'etat de l'instant.
        final EmplacementEntree recul = a(
          t0.subtract(const Duration(hours: 1)),
        );
        expect(recul.libelle, avant.libelle);
        expect(recul.etat, EtatEntree.aVenir);
      },
    );
  });

  group('annonces et DST', () {
    test('annonce seulement aux changements d etat, jamais le decompte', () {
      final EmplacementEntree e1 = a(t0.subtract(const Duration(hours: 2)));
      final EmplacementEntree e2 = a(t0.subtract(const Duration(hours: 1)));
      expect(e1.annonceDepuis(null), 'Séance à venir');
      expect(e2.annonceDepuis(e1), isNull);
      final EmplacementEntree e3 = a(t0.subtract(const Duration(minutes: 5)));
      expect(e3.annonceDepuis(e2), 'La salle est ouverte');
      expect(e3.annonce, isNot(contains('min')));
    });

    test('avis DST quand l heure bouge, rien sinon', () {
      final EmplacementEntree avec = a(
        t0.subtract(const Duration(hours: 3)),
        dst: DonneesClasseDemo.noticeDst,
      );
      expect(
        avec.avisDst,
        "Changement d'heure : le cours passera de 18:00 à 17:00.",
      );
      expect(avec.etat, EtatEntree.aVenir);
      final EmplacementEntree sans = a(
        t0.subtract(const Duration(hours: 3)),
        dst: NoticeDst(
          transitionUtc: DateTime.utc(2026, 10, 25, 1),
          fuseauConcerne: 'Africa/Conakry',
          heureAvantRendue: '16:00',
          heureApresRendue: '16:00',
          echeance: EcheanceDst.j7,
        ),
      );
      expect(sans.avisDst, isNull);
    });
  });

  test('chaque situation de demonstration se resout pour chaque role', () {
    for (final RoleEntree role in RoleEntree.values) {
      for (final EtatDemoClasse etat in EtatDemoClasse.values) {
        final EmplacementEntree e = DonneesClasseDemo.emplacement(role, etat);
        expect(e.libelle, isNotEmpty);
      }
    }
    expect(DonneesClasseDemo.actions.length, lessThanOrEqualTo(3));
    expect(DonneesClasseDemo.ressources, hasLength(3));
    expect(DonneesClasseDemo.enseignante.photoUrlOuCle, isNull);
  });
}
