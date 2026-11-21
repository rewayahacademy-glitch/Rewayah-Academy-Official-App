// Ce qui reste de NOTIFS-L6 apres CLOCHE-C (decision du directeur du
// 21/11/2026) : le mot du geste attendu sur une ligne « A faire », et la
// lecture de l'adaptateur Supabase (geste requis, ecartee, faite, cle de
// regroupement). Les sections, le regroupement a l'ecran et « Ecarter » de la
// page sont remplaces par la grammaire de la cloche (`cloche_c_test.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

void main() {
  test('le mot du geste, par evenement', () {
    String mot(String e) => LigneNotification.libelleGeste(
      NotificationTuteur(
        id: 'x',
        titre: 'x',
        date: DateTime.utc(2026, 11, 21),
        gesteEnAttente: true,
        evenement: e,
      ),
    );
    final m = t.notifications;
    expect(mot('paiement_relance'), m.gesteRecharger);
    expect(mot('acces_suspendu_paiement'), m.gesteRecharger);
    expect(mot('remplacement_propose'), m.gestePrendreSeance);
    expect(mot('remplacement_pre_alerte'), m.gestePrendreSeance);
    expect(mot('demande_presentation'), m.gesteRepondre);
    expect(mot('controle_mission_attribuee'), m.gesteObserver);
    expect(mot('litige_ouvert'), m.gesteTraiterContestation);
    expect(mot('classe_creee'), m.sectionAFaire);
  });

  group('NOTIFS-L6 : l adaptateur Supabase', () {
    Map<String, dynamic> ligne({
      Object? gesteRequis,
      Object? ecartee,
      Object? fait,
    }) => <String, dynamic>{
      'id': 'x',
      'evenement': 'paiement_relance',
      'params': <String, dynamic>{'classe': 'Classe A'},
      'destination': '/tuteur/foyer/recharge',
      'cree_le': '2026-11-02T08:00:00Z',
      'lu_le': '2026-11-02T09:00:00Z',
      'geste_requis': ?gesteRequis,
      'ecartee_le': ?ecartee,
      'geste_fait_le': ?fait,
    };

    test('geste requis, ni fait ni ecarte : « A faire », meme lue', () {
      final NotificationTuteur n = notificationDepuis(
        ligne(gesteRequis: true),
        titrePour: contenuNotificationPour,
      );
      expect(n.lue, isTrue);
      expect(n.gesteEnAttente, isTrue);
      expect(n.aFaire, isTrue);
      expect(
        n.cleRegroupement,
        'paiement_relance|/tuteur/foyer/recharge|Classe A',
      );
    });

    test('ecartee, ou geste fait, ou colonnes absentes : pas « A faire »', () {
      for (final Map<String, dynamic> l in <Map<String, dynamic>>[
        ligne(gesteRequis: true, ecartee: '2026-11-02T10:00:00Z'),
        ligne(gesteRequis: true, fait: '2026-11-02T10:00:00Z'),
        ligne(),
      ]) {
        expect(
          notificationDepuis(l, titrePour: contenuNotificationPour).aFaire,
          isFalse,
        );
      }
    });
  });
}
