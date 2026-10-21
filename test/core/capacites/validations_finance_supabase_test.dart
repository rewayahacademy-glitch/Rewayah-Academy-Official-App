// FAC-D-01 : l'adaptateur des validations de la direction. Les JSON de
// reference sont ceux que rendent reellement `finance_validations_lister`,
// `finance_validation_decider` et `finance_validation_journal` sur une base
// rejouee (migration 20261018090000, fixtures de
// `scenarios_fac_d_validation_paiements.sql`) : decodage strict, parametres
// envoyes, refus de decision et fonction absente.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/paiements_saisis_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/port_validations_finance.dart';
import 'package:rewayah_academy/core/capacites/validations_finance_supabase.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une demande en attente, lue par la comptable qui l'a faite.
const String _enAttenteServeur =
    '{"id": "8427efc8-ffb8-49ff-bc1e-f98087319628", "date": '
    '"2026-10-18T03:19:59.958581+00:00", "etat": "en_attente", "motif": '
    'null, "objet": "Yasmine F1 (FD-ELV-0001)", "nature": "paiement_recu", '
    '"raison": "paiement_hors_application", "actions": [], "montant": '
    '{"devise": "USD", "mineur": 5000}, "objetId": '
    '"fd000000-0000-4000-8000-0000000000e1", "blocages": {"approuver": '
    '"auto_paiement"}, "decideur": null, "demandeur": "Compta FD", '
    '"reference": "VIR-1", "dateDecision": null}';

/// La meme demande, lue par la direction.
const String _aDeciderServeur =
    '{"id": "8427efc8-ffb8-49ff-bc1e-f98087319628", "date": '
    '"2026-10-18T03:19:59.958581+00:00", "etat": "en_attente", "motif": '
    'null, "objet": "Yasmine F1 (FD-ELV-0001)", "nature": "paiement_recu", '
    '"raison": "paiement_hors_application", "actions": ["approuver"], '
    '"montant": {"devise": "USD", "mineur": 5000}, "objetId": '
    '"fd000000-0000-4000-8000-0000000000e1", "blocages": {}, "decideur": '
    'null, "demandeur": "Compta FD", "reference": "VIR-1", "dateDecision": '
    'null}';

/// Une demande refusee, avec son motif.
const String _refuseeServeur =
    '{"id": "b11b24f0-ba4d-413e-8354-999232e91331", "date": '
    '"2026-10-18T03:19:59.979216+00:00", "etat": "refusee", "motif": '
    '"Montant a verifier a la source", "objet": "Bilal F1 (FD-ELV-0002)", '
    '"nature": "paiement_recu", "raison": "paiement_hors_application", '
    '"actions": [], "montant": {"devise": "USD", "mineur": 5000}, '
    '"objetId": "fd000000-0000-4000-8000-0000000000e2", "blocages": {}, '
    '"decideur": "Direction FD", "demandeur": "Compta FD", "reference": '
    'null, "dateDecision": "2026-10-18T03:20:00.013635+00:00"}';

/// La decision de valider.
const String _valideeServeur =
    '{"id": "8427efc8-ffb8-49ff-bc1e-f98087319628", "date": '
    '"2026-10-18T03:19:59.958581+00:00", "etat": "validee", "motif": null, '
    '"objet": "Yasmine F1 (FD-ELV-0001)", "nature": "paiement_recu", '
    '"raison": "paiement_hors_application", "actions": [], "montant": '
    '{"devise": "USD", "mineur": 5000}, "objetId": '
    '"fd000000-0000-4000-8000-0000000000e1", "blocages": {}, "decideur": '
    '"Direction FD", "demandeur": "Compta FD", "reference": "VIR-1", '
    '"dateDecision": "2026-10-18T03:20:00.028591+00:00"}';

const String _journalServeur =
    '[{"id": "8427efc8-ffb8-49ff-bc1e-f98087319628:demande", "date": '
    '"2026-10-18T03:19:59.958581+00:00", "action": "demandee", "montant": '
    '{"devise": "USD", "mineur": 5000}, "reference": "VIR-1", "initiateur": '
    '"Compta FD"}, {"id": "8427efc8-ffb8-49ff-bc1e-f98087319628:decision", '
    '"date": "2026-10-18T03:20:00.028591+00:00", "action": "validee", '
    '"montant": null, "reference": null, "initiateur": "Direction FD"}]';

/// La saisie de la comptabilite : une demande, rien de credite.
const String _soumisServeur =
    '{"etat": "validation_demandee", "motif": null, "finance": {"age": null, '
    '"etat": "essai", "solde": {"devise": "USD", "mineur": 0}, "classe": '
    '"An-Nour FD", "manque": null, "prenom": "Yasmine", "periode": null, '
    '"profilId": "fd000000-0000-4000-8000-0000000000e1", "cleAccent": '
    '"fd000000-0000-4000-8000-0000000000e1", "cleAvatar": null, '
    '"estAdulte": false, "mensualite": {"devise": "USD", "mineur": 0}, '
    '"prochainDebit": null, "essaisUtilises": 0, "finConservation": null, '
    '"lignesMensualite": []}, "nouveau": true, "validation": '
    '"8427efc8-ffb8-49ff-bc1e-f98087319628"}';

ValidationsFinanceSupabase _port(Object? reponse) =>
    ValidationsFinanceSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async => reponse,
    );

void main() {
  test('lister : les parametres du filtre, la demande decodee', () async {
    final List<(String, Map<String, dynamic>?)> appels =
        <(String, Map<String, dynamic>?)>[];
    final ValidationsFinanceSupabase port =
        ValidationsFinanceSupabase.avecAppel((
          String f,
          Map<String, dynamic>? p,
        ) async {
          appels.add((f, p));
          return jsonDecode('[$_enAttenteServeur, $_refuseeServeur]');
        });
    final List<DemandeValidation> liste = await port.demandes(
      const FiltreDemandesValidation(
        etat: EtatDemandeValidation.enAttente,
        nature: NatureDemandeValidation.paiementRecu,
        objetId: 'e1',
      ),
    );
    expect(appels.single.$1, 'finance_validations_lister');
    expect(appels.single.$2, <String, dynamic>{
      'p_etat': 'en_attente',
      'p_nature': 'paiement_recu',
      'p_objet': 'e1',
    });
    expect(liste, hasLength(2));
    final DemandeValidation d = liste.first;
    expect(d.id, '8427efc8-ffb8-49ff-bc1e-f98087319628');
    expect(d.nature, NatureDemandeValidation.paiementRecu);
    expect(d.etat, EtatDemandeValidation.enAttente);
    expect(d.objet, 'Yasmine F1 (FD-ELV-0001)');
    expect(d.objetId, 'fd000000-0000-4000-8000-0000000000e1');
    expect(d.demandeur, 'Compta FD');
    expect(d.montant, const Montant(5000, 'USD'));
    expect(d.raison, RaisonBlocage.paiementHorsApplication);
    expect(d.precision, t.comptable.validation.reference(reference: 'VIR-1'));
    expect(d.decideur, isNull);
    expect(d.dateDecision, isNull);
    // Sa propre demande : elle ne la decide pas, la source le dit.
    expect(d.permissions.permet(ActionFinance.approuver), isFalse);
    expect(
      d.permissions.raisonDe(ActionFinance.approuver),
      RaisonBlocage.autoPaiement,
    );
    final DemandeValidation r = liste.last;
    expect(r.etat, EtatDemandeValidation.refusee);
    expect(r.motifDecision, 'Montant a verifier a la source');
    expect(r.decideur, 'Direction FD');
    expect(r.dateDecision, isNotNull);
    expect(r.precision, isNull);
  });

  test('lister sans filtre : aucun parametre impose', () async {
    Map<String, dynamic>? envoye;
    final ValidationsFinanceSupabase port =
        ValidationsFinanceSupabase.avecAppel((
          String _,
          Map<String, dynamic>? p,
        ) async {
          envoye = p;
          return jsonDecode('[$_aDeciderServeur]');
        });
    final List<DemandeValidation> liste = await port.demandes(
      FiltreDemandesValidation.tout,
    );
    expect(envoye, <String, dynamic>{
      'p_etat': null,
      'p_nature': null,
      'p_objet': null,
    });
    expect(liste.single.permissions.permet(ActionFinance.approuver), isTrue);
  });

  test('une nature inconnue de cette version reste a la source', () async {
    final List<DemandeValidation> liste = await _port(
      jsonDecode(
        '[${_aDeciderServeur.replaceAll('paiement_recu', 'autre_nature')}]',
      ),
    ).demandes(FiltreDemandesValidation.tout);
    expect(liste, isEmpty);
  });

  test('decider : les parametres exacts, la demande rendue', () async {
    Map<String, dynamic>? envoye;
    final ValidationsFinanceSupabase port =
        ValidationsFinanceSupabase.avecAppel((
          String f,
          Map<String, dynamic>? p,
        ) async {
          expect(f, 'finance_validation_decider');
          envoye = p;
          return jsonDecode(_valideeServeur);
        });
    final DemandeValidation d = await port.decider(
      demandeId: '8427efc8-ffb8-49ff-bc1e-f98087319628',
      decision: DecisionValidation.valider,
      cleIdempotence: 'fd000000-0000-4000-8000-00000000e001',
    );
    expect(envoye, <String, dynamic>{
      'p_demande': '8427efc8-ffb8-49ff-bc1e-f98087319628',
      'p_decision': 'valider',
      'p_motif': null,
      'p_cle': 'fd000000-0000-4000-8000-00000000e001',
    });
    expect(d.etat, EtatDemandeValidation.validee);
    expect(d.decideur, 'Direction FD');
  });

  for (final (String code, MotifRefusDecision motif)
      in <(String, MotifRefusDecision)>[
        ('RV001', MotifRefusDecision.demandeurNePeutPasValider),
        ('RV002', MotifRefusDecision.motifObligatoire),
        ('RV003', MotifRefusDecision.dejaDecidee),
      ]) {
    test('refus $code : RefusDecision(${motif.name})', () async {
      final ValidationsFinanceSupabase port =
          ValidationsFinanceSupabase.avecAppel(
            (String _, Map<String, dynamic>? _) async =>
                throw PostgrestException(message: 'refus', code: code),
          );
      await expectLater(
        port.decider(
          demandeId: 'd',
          decision: DecisionValidation.refuser,
          cleIdempotence: 'c',
          motif: 'm',
        ),
        throwsA(
          isA<RefusDecision>().having(
            (RefusDecision r) => r.motif,
            'motif',
            motif,
          ),
        ),
      );
    });
  }

  test('une autre erreur de decision remonte : issue inconnue', () async {
    final ValidationsFinanceSupabase port =
        ValidationsFinanceSupabase.avecAppel(
          (String _, Map<String, dynamic>? _) async =>
              throw const PostgrestException(message: 'droits', code: '42501'),
        );
    await expectLater(
      port.decider(
        demandeId: 'd',
        decision: DecisionValidation.valider,
        cleIdempotence: 'c',
      ),
      throwsA(isA<PostgrestException>()),
    );
  });

  test('journal : la demande puis la decision, en phrases', () async {
    final List<EntreeJournal> journal = await _port(jsonDecode(_journalServeur))
        .journal('8427efc8-ffb8-49ff-bc1e-f98087319628');
    final v = t.comptable.validation.journal;
    expect(journal, hasLength(2));
    expect(journal.first.objet, v.demandee);
    expect(journal.first.initiateur, 'Compta FD');
    expect(journal.first.montant, const Montant(5000, 'USD'));
    expect(journal.first.reference, 'VIR-1');
    expect(journal.last.objet, v.validee);
    expect(journal.last.initiateur, 'Direction FD');
    expect(journal.last.montant, isNull);
  });

  test('fonction absente : capacite indisponible', () async {
    final ValidationsFinanceSupabase port =
        ValidationsFinanceSupabase.avecAppel(
          (String _, Map<String, dynamic>? _) async =>
              throw const PostgrestException(
                message: 'absente',
                code: 'PGRST202',
              ),
        );
    await expectLater(
      port.demandes(FiltreDemandesValidation.tout),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('forme inattendue : FormatException, jamais une valeur inventee', () {
    expect(
      () => demandeValidationJson(
        jsonDecode(_aDeciderServeur.replaceAll('"en_attente"', '"autre"')),
      ),
      throwsFormatException,
    );
  });

  test('la saisie de la comptabilite : validation demandee, rien de '
      'credite', () async {
    final PaiementEnregistre r =
        await PaiementsSaisisSupabase.avecAppel(
          (String _, Map<String, dynamic>? _) async =>
              jsonDecode(_soumisServeur),
        ).enregistrer(
          profilId: 'fd000000-0000-4000-8000-0000000000e1',
          montant: const Montant(5000, 'USD'),
          cle: 'fd000000-0000-4000-8000-00000000d001',
        );
    expect(r.issue, IssuePaiement.validationDemandee);
    expect(r.nouveau, isTrue);
    expect(r.paiementId, isNull);
    expect(r.motifRefus, isNull);
  });

  test('une saisie refusee : le motif rendu', () {
    final PaiementEnregistre r = paiementEnregistreJson(
      jsonDecode(
        _soumisServeur
            .replaceAll('"validation_demandee"', '"refusee"')
            .replaceAll('"motif": null', '"motif": "Justificatif manquant"')
            .replaceAll('"nouveau": true', '"nouveau": false'),
      ),
    );
    expect(r.issue, IssuePaiement.refuse);
    expect(r.motifRefus, 'Justificatif manquant');
  });
}
