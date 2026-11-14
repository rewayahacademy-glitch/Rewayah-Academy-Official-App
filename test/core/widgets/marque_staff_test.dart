// #Ra_staff (decision du directeur, 14/11/2026) : l'equipe s'affiche partout
// avec l'icone de l'application et le nom exact « #Ra_staff », identique dans
// toutes les langues, jamais le nom d'une personne ni « Administration ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/libelles_communication_slang.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/marque_staff.dart';
import 'package:rewayah_academy/features/com_messages/avatar_participant.dart';

import '../../support/harnais.dart';

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  test('le nom est « #Ra_staff » dans toutes les langues', () async {
    for (final AppLocale langue in AppLocale.values) {
      await LocaleSettings.setLocale(langue);
      expect(t.commun.staff.designation, '#Ra_staff', reason: langue.name);
      // Isole de gauche a droite : jamais « Ra_staff# » en arabe.
      expect(MarqueStaff.designation, '\u2066#Ra_staff\u2069');
    }
  });

  test('l\'equipe rendue par le serveur : #Ra_staff, jamais un nom', () async {
    for (final AppLocale langue in AppLocale.values) {
      await LocaleSettings.setLocale(langue);
      final Participant p = participantJson(<String, dynamic>{
        'id': 'equipe',
        'nature': 'equipe',
        'prenom': 'Amina',
      }, const LibellesCommunicationSlang());
      expect(p.equipe, isTrue);
      expect(p.nomAffiche, MarqueStaff.designation);
      expect(p.profilId, isNull);
    }
    final Participant personne = participantJson(<String, dynamic>{
      'id': 'p-1',
      'nature': 'profil',
      'prenom': 'Salma',
    }, const LibellesCommunicationSlang());
    expect(personne.equipe, isFalse);
  });

  testWidgets('MarqueStaff : l\'icone (BrandLogo) et le nom', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(const Scaffold(body: MarqueStaff())));
    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text(MarqueStaff.designation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l\'avatar d\'un participant de l\'equipe est l\'icone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: AvatarParticipant(
            participant: Participant(
              id: 'equipe',
              nomAffiche: '#Ra_staff',
              equipe: true,
            ),
            repli: 'x',
            diametre: 48,
          ),
        ),
      ),
    );
    expect(find.byType(MarqueStaff), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
  });
}
