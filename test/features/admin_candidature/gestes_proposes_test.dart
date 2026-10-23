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
        GesteCandidature.admettreVerifications,
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
        GesteCandidature.admettreVerifications,
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
      nom: 'versement pas encore possible',
      detail: detailTest(
        etat: EtatCandidature.paiementNonDisponible,
        paiement: EtatVersement.incompatible,
      ),
      principal: null,
      permis: <GesteCandidature>[
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
      nom: 'salle de verification',
      detail: detailTest(
        etape: EtapeCandidature.verifications,
        etat: EtatCandidature.decisionEnAttente,
        paiement: EtatVersement.compatible,
      ),
      principal: null,
      permis: <GesteCandidature>[
        c,
        GesteCandidature.cloreComplement,
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
}
