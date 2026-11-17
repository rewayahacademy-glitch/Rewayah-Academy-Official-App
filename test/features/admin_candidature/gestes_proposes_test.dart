// ADM-21 : les gestes que la page propose, selon l'etat que le serveur a rendu.
//
// Une table de presentation (sources permises de CAND-L2A1), jamais une regle :
// le serveur refuse tout ce qui est interdit. Ce que le test prouve : un geste
// que le serveur n'ouvre pas n'est jamais propose ; chaque etat propose ce que
// sa source permet, et rien d'autre ; la prochaine action est au plus une.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/features/admin_candidature/gestes_proposes.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';
import 'package:rewayah_academy/features/admin_candidatures/menu_ligne_candidature.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';

typedef _Cas = ({
  String nom,
  List<GesteCandidature> permis,
  GesteCandidature? principal,
  DetailCandidature detail,
});

GestesProposes _pour(
  DetailCandidature detail, {
  CapacitesCandidatures capacites = capacitesGestes,
}) => gestesProposes(detail, capacites);

void main() {
  const GesteCandidature c = GesteCandidature.demanderComplement;
  final List<_Cas> cas = <_Cas>[
    (
      nom: 'examen, versement a verifier',
      detail: detailTest(),
      principal: GesteCandidature.confirmerMoyenPaiement,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.confirmerMoyenPaiement,
        GesteCandidature.infirmerMoyenPaiement,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'examen, versement confirme',
      detail: detailTest(paiement: EtatVersement.compatible),
      principal: GesteCandidature.admettreVerifications,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.infirmerMoyenPaiement,
        GesteCandidature.admettreVerifications,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'examen, versement inconnu : rien a confirmer',
      detail: detailTest(paiement: EtatVersement.inconnu),
      principal: null,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'a completer : on attend la personne',
      detail: detailTest(etat: EtatCandidature.aCompleter),
      principal: null,
      permis: <GesteCandidature>[
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'a completer, complement en cours : modifier ou annuler',
      detail: detailTest(
        etat: EtatCandidature.aCompleter,
        complementEnCours: true,
      ),
      principal: null,
      permis: <GesteCandidature>[
        GesteCandidature.modifierComplement,
        GesteCandidature.annulerComplement,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'versement pas encore possible',
      detail: detailTest(
        etat: EtatCandidature.paiementNonDisponible,
        paiement: EtatVersement.incompatible,
      ),
      principal: null,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'en pause : lever, refuser, retrait',
      detail: detailTest(enPause: true),
      principal: GesteCandidature.leverPause,
      permis: <GesteCandidature>[
        GesteCandidature.leverPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
      ],
    ),
    (
      nom: 'salle de verification, complement en cours : clore est propose',
      detail: detailTest(
        etape: EtapeCandidature.verifications,
        etat: EtatCandidature.entretienAPlanifier,
        paiement: EtatVersement.compatible,
        complementEnCours: true,
      ),
      principal: null,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.cloreComplement,
        GesteCandidature.dispenserEntretien,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'salle de verification',
      detail: detailTest(
        etape: EtapeCandidature.verifications,
        etat: EtatCandidature.decisionEnAttente,
        paiement: EtatVersement.compatible,
      ),
      principal: GesteCandidature.validerPiece,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.validerPiece,
        GesteCandidature.refaireEntretien,
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
    (
      nom: 'salle des prets : pause et responsable seulement',
      detail: detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        paiement: EtatVersement.compatible,
      ),
      principal: null,
      permis: <GesteCandidature>[
        GesteCandidature.mettreEnPause,
        GesteCandidature.definirResponsable,
        GesteCandidature.restreindre,
        GesteCandidature.demanderVerificationPiece,
        GesteCandidature.demanderVerificationVersement,
      ],
    ),
    (
      nom: 'confirmee restreinte pour le versement a verifier',
      detail: detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        restreinte: true,
        restrictionCause: 'paiement',
      ),
      principal: GesteCandidature.confirmerMoyenPaiement,
      permis: <GesteCandidature>[
        GesteCandidature.confirmerMoyenPaiement,
        GesteCandidature.mettreEnPause,
        GesteCandidature.definirResponsable,
        GesteCandidature.leverRestriction,
      ],
    ),
    (
      nom: 'confirmee restreinte pour une autre cause',
      detail: detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        restreinte: true,
        restrictionCause: 'manuelle',
      ),
      principal: null,
      permis: <GesteCandidature>[
        GesteCandidature.mettreEnPause,
        GesteCandidature.definirResponsable,
        GesteCandidature.leverRestriction,
      ],
    ),
    (
      nom: 'refusee : rouvrir seulement',
      detail: detailTest(issue: IssueCandidature.refusee),
      principal: null,
      permis: <GesteCandidature>[GesteCandidature.rouvrir],
    ),
    (
      nom: 'retiree : rouvrir seulement',
      detail: detailTest(issue: IssueCandidature.retiree),
      principal: null,
      permis: <GesteCandidature>[GesteCandidature.rouvrir],
    ),
    (
      nom: 'gardee pour suivi (recue) : pas de geste de ce lot',
      detail: detailTest(etape: EtapeCandidature.recue, etat: null),
      principal: null,
      permis: <GesteCandidature>[
        GesteCandidature.mettreEnPause,
        GesteCandidature.refuser,
        GesteCandidature.consignerRetrait,
        GesteCandidature.definirResponsable,
      ],
    ),
  ];

  for (final _Cas x in cas) {
    test(x.nom, () {
      final GestesProposes g = _pour(x.detail);
      expect(g.principal, x.principal);
      final Set<GesteCandidature> tous = <GesteCandidature>{
        if (g.principal != null) g.principal!,
        ...g.autres,
      };
      expect(tous, x.permis.toSet());
      // La prochaine action n'est jamais aussi dans le menu.
      expect(g.autres, isNot(contains(g.principal)));
    });
  }

  test('sans le droit de decider, rien n\'est propose', () {
    expect(_pour(detailTest(), capacites: capacitesQuiLit).vide, isTrue);
    expect(
      _pour(detailTest(), capacites: CapacitesCandidatures.aucune).vide,
      isTrue,
    );
  });

  test('un geste que le serveur n\'ouvre pas n\'est jamais propose', () {
    for (final GesteCandidature ferme in GesteCandidature.values) {
      final CapacitesCandidatures caps = CapacitesCandidatures(
        peutDecider: true,
        gestes: <String, bool>{
          for (final GesteCandidature g in GesteCandidature.values)
            g.capacite: g != ferme,
        },
      );
      for (final DetailCandidature d in <DetailCandidature>[
        detailTest(),
        detailTest(paiement: EtatVersement.compatible),
        detailTest(enPause: true),
        detailTest(issue: IssueCandidature.refusee),
        detailTest(etape: EtapeCandidature.verifications, etat: null),
      ]) {
        final GestesProposes g = _pour(d, capacites: caps);
        expect(
          <GesteCandidature>[?g.principal, ...g.autres],
          isNot(contains(ferme)),
          reason: ferme.name,
        );
      }
    }
  });

  group('Accueillir dans l\'equipe (valider la piece)', () {
    const CapacitesCandidatures ouvert = CapacitesCandidatures(
      peutDecider: true,
      gestes: <String, bool>{'validerPiece': true},
    );

    test('la prochaine action quand la decision est attendue en Salle de '
        'verification', () {
      final GestesProposes g = _pour(
        detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
        ),
        capacites: ouvert,
      );
      expect(g.principal, GesteCandidature.validerPiece);
    });

    test('jamais proposee ailleurs : examen, entretien a planifier, pause, '
        'issue close, ou serveur qui ne l\'ouvre pas', () {
      final List<DetailCandidature> ailleurs = <DetailCandidature>[
        detailTest(),
        detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
        ),
        detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
          enPause: true,
        ),
        detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
          issue: IssueCandidature.refusee,
        ),
        detailTest(
          etape: EtapeCandidature.confirmee,
          etat: EtatCandidature.decisionEnAttente,
        ),
      ];
      for (final DetailCandidature d in ailleurs) {
        final GestesProposes g = _pour(d, capacites: ouvert);
        expect(<GesteCandidature>[
          ?g.principal,
          ...g.autres,
        ], isNot(contains(GesteCandidature.validerPiece)));
      }
      final GestesProposes ferme = _pour(
        detailTest(
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.decisionEnAttente,
        ),
        capacites: const CapacitesCandidatures(
          peutDecider: true,
          gestes: <String, bool>{'validerPiece': false},
        ),
      );
      expect(<GesteCandidature>[
        ?ferme.principal,
        ...ferme.autres,
      ], isNot(contains(GesteCandidature.validerPiece)));
    });
  });

  test('lever la pause n\'est propose qu\'en pause, mettre en pause jamais deux fois', () {
    expect(
      _pour(detailTest()).autres,
      isNot(contains(GesteCandidature.leverPause)),
    );
    expect(
      _pour(detailTest(enPause: true)).autres,
      isNot(contains(GesteCandidature.mettreEnPause)),
    );
  });

  group('la meme table pour une ligne de la file (LISTES-1)', () {
    final List<DetailCandidature> details = <DetailCandidature>[
      detailTest(),
      detailTest(paiement: EtatVersement.compatible),
      detailTest(enPause: true),
      detailTest(issue: IssueCandidature.refusee),
      detailTest(issue: IssueCandidature.retiree),
      detailTest(etape: EtapeCandidature.verifications, etat: null),
      detailTest(etape: EtapeCandidature.recue, etat: null),
      detailTest(etape: EtapeCandidature.confirmee, etat: null),
      detailTest(etat: EtatCandidature.aCompleter),
    ];

    test('une ligne propose exactement ce que son dossier propose, sans la cause de restriction', () {
      for (final DetailCandidature d in details) {
        final GestesProposes dossier = gestesProposes(d, capacitesGestes);
        final GestesProposes ligne = gestesProposesPourLigne(
          d.ligne,
          capacitesGestes,
        );
        expect(ligne.principal, dossier.principal);
        expect(ligne.autres.toSet(), dossier.autres.toSet());
        for (final GesteCandidature g in GesteCandidature.values) {
          expect(
            gestePermisPourLigne(g, d.ligne),
            gestePermis(g, d),
            reason: '${g.name} / ${d.ligne.etape} ${d.ligne.etat}',
          );
        }
      }
    });

    test(
      'le menu d\'une ligne range les destructifs a la fin, en un groupe',
      () {
        for (final DetailCandidature d in details) {
          final List<GesteCandidature> autres = gestesDuMenuLigne(
            d.ligne,
            capacitesGestes,
          );
          final int premier = autres.indexWhere(
            (GesteCandidature g) => g.destructif,
          );
          if (premier < 0) continue;
          expect(
            autres.sublist(premier).every((GesteCandidature g) => g.destructif),
            isTrue,
            reason: '$autres',
          );
        }
      },
    );

    test('sansResponsable masque seulement « Choisir le responsable »', () {
      final DetailCandidature d = detailTest();
      final GestesProposes avec = gestesProposesPourLigne(
        d.ligne,
        capacitesGestes,
      );
      final GestesProposes sans = gestesProposesPourLigne(
        d.ligne,
        capacitesGestes,
        sansResponsable: true,
      );
      expect(avec.autres, contains(GesteCandidature.definirResponsable));
      expect(sans.autres, isNot(contains(GesteCandidature.definirResponsable)));
      expect(
        sans.autres.toSet(),
        avec.autres.toSet()..remove(GesteCandidature.definirResponsable),
      );
    });

    test('confirmer un moyen d\'une confirmee sous restriction : le serveur le sert, la ligne le dit', () {
      // La cause de la restriction n'est plus lue par l'ecran : le serveur la lit
      // et sert (ou non) le geste dans la cle `gestes` de la ligne.
      final DetailCandidature d = detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        restreinte: true,
        restrictionCause: 'paiement',
        paiement: EtatVersement.aVerifier,
      );
      expect(gestePermis(GesteCandidature.confirmerMoyenPaiement, d), isTrue);
      expect(
        gestePermisPourLigne(GesteCandidature.confirmerMoyenPaiement, d.ligne),
        isTrue,
      );
      final DetailCandidature autreCause = detailTest(
        etape: EtapeCandidature.confirmee,
        etat: null,
        restreinte: true,
        restrictionCause: 'conduite',
        paiement: EtatVersement.aVerifier,
      );
      expect(
        gestePermisPourLigne(
          GesteCandidature.confirmerMoyenPaiement,
          autreCause.ligne,
        ),
        isFalse,
      );
    });
  });

  group(
    'GESTES-DU-SERVEUR : l\'ecran ne montre que ce que le serveur sert',
    () {
      test('une ligne sans la cle gestes (serveur d\'avant) : aucun geste', () {
        final DetailCandidature d = detailTest(gestes: const <String>[]);
        final GestesProposes p = _pour(d);
        expect(p.vide, isTrue);
        expect(gestePermis(GesteCandidature.refuser, d), isFalse);
      });

      test(
        'la cle gestes lue du serveur : noms, ordre libre, inconnus ignores',
        () {
          final LigneCandidature l = LigneCandidature.depuisJson(
            <String, Object?>{
              'id': 'c1',
              'reference': 'CAND-000001',
              'gestes': <Object?>[
                'refuser',
                'annuler_admission',
                'indisponibilite',
                'mettre_en_pause',
                42,
                '',
              ],
            },
          )!;
          expect(l.gestes, <String>[
            'refuser',
            'annuler_admission',
            'indisponibilite',
            'mettre_en_pause',
          ]);
          expect(l.gestesInconnusDeLEcran, <String>[
            'annuler_admission',
            'indisponibilite',
          ]);
        },
      );

      test(
        'un nom du serveur que l\'ecran ne sait pas faire n\'est pas montre',
        () {
          final DetailCandidature d = detailTest(
            gestes: const <String>['annuler_admission', 'refuser', 'inconnu_x'],
          );
          final GestesProposes p = _pour(d);
          final Set<GesteCandidature> montres = <GesteCandidature>{
            ?p.principal,
            ...p.autres,
          };
          expect(montres, <GesteCandidature>{GesteCandidature.refuser});
          expect(d.ligne.gestesInconnusDeLEcran, <String>[
            'annuler_admission',
            'inconnu_x',
          ]);
        },
      );

      test(
        'chaque nom du serveur que l\'ecran sait faire se retrouve par son nom',
        () {
          // Une seule exception, COMPLEMENT-SALLE-EXAMEN : « modifier le
          // complement » porte le nom `demander_complement` (variante 3 du
          // moteur) ; l'ecran la distingue par l'etat de la ligne.
          final List<GesteCandidature> aNomPropre = <GesteCandidature>[
            for (final GesteCandidature g in GesteCandidature.values)
              if (g != GesteCandidature.modifierComplement) g,
          ];
          for (final GesteCandidature g in aNomPropre) {
            expect(GesteCandidature.depuisNomServeur(g.nomServeur), g);
          }
          expect(
            GesteCandidature.depuisNomServeur('demander_complement'),
            GesteCandidature.demanderComplement,
          );
          expect(GesteCandidature.depuisNomServeur('inviter'), isNull);
          // Aucun nom en double : un nom du serveur designe un seul geste.
          expect(
            aNomPropre.map((GesteCandidature g) => g.nomServeur).toSet(),
            hasLength(aNomPropre.length),
          );
        },
      );

      test(
        'le faux serveur des tests ne sert que des noms que l\'ecran connait',
        () {
          for (final EtapeCandidature e in EtapeCandidature.values) {
            for (final EtatCandidature? s in <EtatCandidature?>[
              null,
              ...EtatCandidature.values,
            ]) {
              for (final IssueCandidature i in IssueCandidature.values) {
                final LigneCandidature l = ligneTest(
                  etape: e,
                  etat: s,
                  issue: i,
                );
                expect(l.gestesInconnusDeLEcran, isEmpty, reason: '$e $s $i');
              }
            }
          }
        },
      );

      test('un porteur de mission : le serveur ne sert que ses gestes, l\'ecran n\'en ajoute aucun', () {
        // Le serveur rend ici les seuls gestes COCHES de la mission (definir le
        // responsable, demander un complement) ; l'ecran n'a ni refuser ni la
        // pause, meme si l'etat les permettrait pour la direction.
        final DetailCandidature d = detailTest(
          gestes: const <String>['definir_responsable', 'demander_complement'],
        );
        final GestesProposes p = _pour(d);
        final Set<GesteCandidature> montres = <GesteCandidature>{
          ?p.principal,
          ...p.autres,
        };
        expect(montres, <GesteCandidature>{
          GesteCandidature.definirResponsable,
          GesteCandidature.demanderComplement,
        });
      });

      test('Admettre garde la garde « versement compatible » (GESTES-RAISON) tant que le serveur ne sert pas les controles', () {
        // Le serveur sert admettre_verifications des qu'on est en examen.
        final DetailCandidature incompatible = detailTest(
          paiement: EtatVersement.inconnu,
          gestes: const <String>['admettre_verifications'],
        );
        expect(
          gestePermis(GesteCandidature.admettreVerifications, incompatible),
          isFalse,
        );
        final DetailCandidature compatible = detailTest(
          paiement: EtatVersement.compatible,
          gestes: const <String>['admettre_verifications'],
        );
        expect(
          gestePermis(GesteCandidature.admettreVerifications, compatible),
          isTrue,
        );
      });
    },
  );

  group('Debloquer le versement : la regle debloquer_versement du serveur', () {
    const GesteCandidature g = GesteCandidature.debloquerVersement;
    bool propose(DetailCandidature d, {CapacitesCandidatures? caps}) {
      final GestesProposes p = _pour(
        d,
        capacites: caps ?? capacitesAvecDeblocage,
      );
      return p.principal == g || p.autres.contains(g);
    }

    test('en examen, quel que soit le versement : propose', () {
      for (final EtatVersement v in EtatVersement.values) {
        expect(propose(detailTest(paiement: v)), isTrue, reason: v.name);
      }
    });

    test('versement impossible (paiement_non_disponible) : propose', () {
      expect(
        propose(
          detailTest(
            etat: EtatCandidature.paiementNonDisponible,
            paiement: EtatVersement.incompatible,
          ),
        ),
        isTrue,
      );
    });

    test('le serveur ne l\'ouvre pas (cle absente) : jamais propose', () {
      expect(propose(detailTest(), caps: capacitesGestes), isFalse);
    });

    test('ailleurs qu\'en Salle d\'examen ou hors des deux etats : refuse', () {
      expect(propose(detailTest(enPause: true)), isFalse);
      expect(propose(detailTest(issue: IssueCandidature.refusee)), isFalse);
      expect(
        propose(detailTest(etape: EtapeCandidature.verifications, etat: null)),
        isFalse,
      );
      expect(
        propose(
          detailTest(
            etat: EtatCandidature.aCompleter,
            paiement: EtatVersement.inconnu,
          ),
        ),
        isFalse,
      );
    });

    test(
      'le menu d\'une ligne suit la meme table, avec son icone et son libelle',
      () {
        final DetailCandidature d = detailTest(paiement: EtatVersement.inconnu);
        expect(gestePermisPourLigne(g, d.ligne), isTrue);
        expect(iconeDuGeste(g), isNotNull);
        expect(libelleGeste(g), isNotEmpty);
      },
    );
  });
}
