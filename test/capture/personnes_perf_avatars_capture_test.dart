// PERSONNES-PERF (21/11/2026) : une liste de personnes avec leurs avatars, servie
// par le VRAI adaptateur `PhotosSupabase` (le serveur est simule). Ce qui change
// dans ce lot ne se voit pas : 24 avatars de la meme image partent desormais en
// UN appel `photos_personnes` (au lieu de 24). La capture prouve que la liste se
// rend a l'identique ; le test compte les appels.
//
// CAPTURE_DIR=docs/current/captures/E2E/PERSONNES-PERF \
//   flutter test --no-pub test/capture/personnes_perf_avatars_capture_test.dart
//
// Donnees fictives : des prenoms faits de syllabes.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/photos/photos_supabase.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/carte_lignes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'outil_capture.dart';

const List<String> _prenoms = <String>[
  'Barin',
  'Dimal',
  'Kolen',
  'Musir',
  'Sakun',
  'Tesid',
  'Lirav',
  'Ranok',
  'Notel',
  'Fejam',
  'Zupig',
  'Hagon',
  'Bakun',
  'Dilor',
  'Kosin',
  'Muvad',
  'Satek',
  'Tejal',
  'Lipon',
  'Ragil',
  'Noram',
  'Felos',
  'Zunek',
  'Harim',
];

String _id(int n) => '9e9c0000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  for (final (Size taille, String nom) in const <(Size, String)>[
    (Size(390, 844), '390'),
    (Size(1440, 900), '1440'),
  ]) {
    testWidgets(
      'liste de 24 personnes, $nom : un seul appel photos_personnes',
      (WidgetTester tester) async {
        int appels = 0;
        final SupabaseClient client = SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          // Aucune minuterie de renouvellement de session dans un test.
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((http.Request r) async {
            if (r.url.pathSegments.last == 'photos_personnes') appels += 1;
            // Aucune photo visible : le serveur ne rend personne, la liste
            // montre les initiales (la meme image avant et apres le lot).
            return http.Response(
              jsonEncode(<Object?>[]),
              200,
              headers: <String, String>{'content-type': 'application/json'},
              request: r,
            );
          }),
        );
        final PhotosSupabase photos = PhotosSupabase(client);
        fixerVueCapture(tester, taille, taille.width < 600 ? 2 : 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CarteLignes(
                  lignes: <Widget>[
                    for (int i = 0; i < _prenoms.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: AvatarNom(
                          prenom: _prenoms[i],
                          nom: 'Exemple',
                          personneId: _id(i + 1),
                          disposition: DispositionAvatar.enLigne,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            surcharges: <Override>[
              portPhotosProvider.overrideWithValue(photos),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(appels, 1);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'liste_avatars_$nom')}');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
