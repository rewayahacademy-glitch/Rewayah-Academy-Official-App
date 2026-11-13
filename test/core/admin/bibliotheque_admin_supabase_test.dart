// CAP-29 : decodage du catalogue et de la fiche rendus par les RPC
// `library_get_catalogue` et `library_get_detail` (aucun reseau).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/bibliotheque_admin_supabase.dart';
import 'package:rewayah_academy/core/admin/bibliotheque_upload_supabase.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';

void main() {
  test('une ligne du catalogue se decode, dates en UTC', () {
    final SupportAdmin s = supportCatalogueJson(<String, dynamic>{
      'id': 'r1',
      'titre': 'Tajwid',
      'type': 'pdf',
      'langue': 'fr',
      'categorie': 'tajwid',
      'niveau': null,
      'numeroVersion': 2,
      'statutVersion': 'brouillon',
      'revueDroits': 'aVerifier',
      'visibilite': 'groupe_assigne',
      'modifieLeUtc': '2026-10-11T10:00:00+02:00',
      'retire': false,
    });
    expect(s.type, TypeRessource.pdf);
    expect(s.statutVersion, StatutVersionRessource.brouillon);
    expect(s.visibilite, PolitiqueAcces.groupeAssigne);
    expect(s.modifieLeUtc, DateTime.utc(2026, 10, 11, 8));
  });

  test('la fiche lit versions, droits, historique et capacites', () {
    final FicheSupport f = ficheSupportJson(<String, dynamic>{
      'support': <String, dynamic>{
        'id': 'r1',
        'titre': 'Tajwid',
        'titreCourt': 'Taj',
        'type': 'pdf',
        'langue': 'fr',
        'categorie': 'tajwid',
        'niveaux': <String>['debutant'],
        'politiqueAcces': 'admin',
        'politiqueHorsLigne': 'sur_demande',
        'retire': false,
        'modifieLeUtc': '2026-10-11T08:00:00Z',
      },
      'revision': 3,
      'versions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'v2',
          'numeroVersion': 2,
          'statut': 'brouillon',
          'droits': <String, dynamic>{
            'sourceTitre': 'Source',
            'titulaire': 'Editeur',
            'preuveFournie': true,
            'usages': <String>['application', 'hors_ligne'],
            'attribution': 'Avec mention',
            'approuve': true,
            'expireLeUtc': null,
          },
        },
      ],
      'historique': <Map<String, dynamic>>[
        <String, dynamic>{
          'action': 'library_rights_review',
          'creeLeUtc': '2026-10-11T08:00:00Z',
        },
        <String, dynamic>{'action': 'inconnue', 'creeLeUtc': 'x'},
      ],
      'capacites': <String, dynamic>{'peutModifier': false},
    }, acteur: 'Administration');
    expect(f.revision, 3);
    expect(f.support.niveau, 'debutant');
    expect(f.support.revueDroits, RevueDroits.approuve);
    expect(f.politiqueHorsLigne, PolitiqueOffline.surDemande);
    expect(f.droits.usages, <UsageDroit>{
      UsageDroit.application,
      UsageDroit.horsLigne,
    });
    expect(f.historique, hasLength(1));
    expect(f.historique.single.action, ActionAudit.revueDroits);
    expect(f.capacites.peutPublier, isFalse);
  });

  test('la fiche lit tranches, lecture du Coran et ecole suivie (D1, D2)', () {
    FicheSupport lire(Map<String, dynamic> extra) =>
        ficheSupportJson(<String, dynamic>{
          'support': <String, dynamic>{
            'id': 'r1',
            'titre': 'Les ablutions',
            'type': 'external_link',
            'langue': 'fr',
            'categorie': 'priere',
            'modifieLeUtc': '2026-10-11T08:00:00Z',
            ...extra,
          },
          'revision': 1,
          'versions': <Map<String, dynamic>>[],
          'historique': <Map<String, dynamic>>[],
        }, acteur: 'Administration');
    final FicheSupport pleine = lire(<String, dynamic>{
      'tranches': <String>['enfant_10_13', 'adulte_18_plus'],
      'lectureCoran': 'warsh',
      'ecolePriere': 'Malikite',
    });
    expect(pleine.tranches, <String>['enfant_10_13', 'adulte_18_plus']);
    expect(pleine.lectureCoran, 'warsh');
    expect(pleine.ecolePriere, 'Malikite');
    // Rien de renseigne : les quatre tranches, ni lecture ni ecole.
    final FicheSupport vide = lire(const <String, dynamic>{});
    expect(vide.tranches, tranchesToutes);
    expect(vide.lectureCoran, isNull);
    expect(vide.ecolePriere, isNull);
  });

  test('l\'ecriture envoie tranches, lecture et ecole ; vide les retire', () {
    final Map<String, dynamic> j = modificationJson(
      const ModificationSupport(
        tranches: <String>['ado_14_17'],
        lectureCoran: 'hafs',
        ecolePriere: '',
      ),
    );
    expect(j['tranches'], <String>['ado_14_17']);
    expect(j['lectureCoran'], 'hafs');
    // Une chaine vide part telle quelle : le serveur la remet a null.
    expect(j['ecolePriere'], '');
    expect(
      modificationJson(const ModificationSupport()).containsKey('tranches'),
      isFalse,
    );
  });

  test('un depot refuse par un 503 est « pas encore active » (C2)', () {
    expect(
      BibliothequeUploadSupabase.erreurPourStatut(503, null),
      ErreurUpload.nonActive,
    );
    expect(
      BibliothequeUploadSupabase.erreurPourStatut(500, null),
      ErreurUpload.reseau,
    );
    expect(
      BibliothequeUploadSupabase.erreurPourStatut(403, null),
      ErreurUpload.refuse,
    );
  });
}
