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

  test('un statut de la fonction, une cause : jamais « reseau » (DEPOT-SIMPLE)', () {
    ErreurUpload cause(int statut, [String? motif]) =>
        BibliothequeUploadSupabase.erreurPourStatut(
          statut,
          motif == null ? null : <String, dynamic>{'error': motif},
        );
    // Le secret de confirmation n'est pas pose cote fonction (C2).
    expect(cause(503, 'confirmation indisponible'), ErreurUpload.nonActive);
    // Le secret n'est pas le meme des deux cotes : un reglage, pas un refus.
    expect(cause(503, 'confirmation mal reglee'), ErreurUpload.reglage);
    // Les variables du stockage manquent, ou le stockage a repondu non.
    expect(cause(503, 'stockage indisponible'), ErreurUpload.stockage);
    expect(cause(503), ErreurUpload.service);
    expect(cause(500), ErreurUpload.service);
    expect(cause(404), ErreurUpload.service);
    expect(cause(546), ErreurUpload.delai);
    expect(cause(504), ErreurUpload.delai);
    expect(cause(401), ErreurUpload.session);
    expect(cause(403, 'depot refuse'), ErreurUpload.refuse);
    // Chaque refus de la base a son motif : un compte sans droit lit un refus,
    // jamais un reglage ; un document publie ou retire n'est pas « refuse ».
    expect(cause(403, 'depot non autorise'), ErreurUpload.refuse);
    expect(cause(409, 'document non modifiable'), ErreurUpload.nonModifiable);
    expect(cause(409, 'fichier deja depose'), ErreurUpload.dejaDepose);
    expect(cause(410, 'demande expiree'), ErreurUpload.expire);
    expect(cause(413, 'fichier trop lourd'), ErreurUpload.taille);
    expect(cause(400, 'fichier vide'), ErreurUpload.vide);
    expect(cause(400, 'action inconnue'), ErreurUpload.service);
    expect(
      cause(422, 'contenu different du type annonce'),
      ErreurUpload.contenu,
    );
    expect(cause(422, 'objet depose introuvable'), ErreurUpload.introuvable);
    expect(cause(422, 'contenu depose invalide'), ErreurUpload.empreinte);
    expect(cause(422), ErreurUpload.empreinte);
    expect(
      cause(400, 'fichier invalide ou format non autorise'),
      ErreurUpload.type,
    );
    // Le serveur a repondu : ce n'est jamais « la connexion ».
    for (final int statut in <int>[
      400,
      401,
      403,
      404,
      413,
      422,
      500,
      502,
      503,
      504,
      546,
    ]) {
      expect(cause(statut), isNot(ErreurUpload.reseau), reason: '$statut');
    }
  });
}
