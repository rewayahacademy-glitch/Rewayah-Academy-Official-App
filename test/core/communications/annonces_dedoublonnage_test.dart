// L2-10 : une annonce generale de l'academie figure une seule fois dans la
// liste d'un tuteur qui a deux Classes. Faux client : deux Classes, une
// annonce generale A (renvoyee deux fois par la RPC, comme un doublon
// serveur), une annonce de Classe par Classe.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';

const String _classe1 = '66666666-6666-4666-8666-666666666661';
const String _classe2 = '66666666-6666-4666-8666-666666666662';
const String _generale = '77777777-7777-4777-8777-777777777770';
const String _b1 = '77777777-7777-4777-8777-777777777771';
const String _b2 = '77777777-7777-4777-8777-777777777772';

Map<String, dynamic> _annonce(
  String id,
  String le, {
  required String? classeId,
  required String libelle,
}) => <String, dynamic>{
  'id': id,
  'titre': 'Titre $id',
  'texte': 'Texte',
  'publiee_le': le,
  'classe': classeId == null
      ? null
      : <String, dynamic>{'id': classeId, 'libelle': libelle},
  'auteur': <String, dynamic>{
    'id': 'administration',
    'nature': 'equipe',
    'fonction': 'administration',
  },
  'lue': false,
};

class _Libelles implements LibellesCommunication {
  const _Libelles();
  @override
  String classe(String libelle) => 'Classe $libelle';
  @override
  String administration() => 'Administration';
  @override
  String famille() => 'Famille';
  @override
  String enseignant({required String prenom, String? nom, String? titre}) =>
      prenom;
  @override
  String objet(TypeObjetLie type) => type.name;
  @override
  String publicAnnonce(String code) => 'public:$code';
}

void main() {
  // Le serveur rend l'annonce generale deux fois (doublon) et les annonces
  // de Classe telles quelles ; le compteur dit combien d'appels partent.
  late List<String> appels;
  Future<Object?> serveur(String f, Map<String, dynamic> p) async {
    appels.add('$f ${p['p_groupe_id']}');
    if (f == 'com_annonces_de_classe') {
      final bool c1 = p['p_groupe_id'] == _classe1;
      return <String, dynamic>{
        'annonces': <Object>[
          c1
              ? _annonce(
                  _b1,
                  '2026-10-15T08:00:00Z',
                  classeId: _classe1,
                  libelle: 'An-Nour',
                )
              : _annonce(
                  _b2,
                  '2026-10-14T08:00:00Z',
                  classeId: _classe2,
                  libelle: 'Al-Fatiha',
                ),
        ],
        'peut_publier': false,
      };
    }
    // com_annonces_academie : A deux fois, dans le contexte de la Classe
    // demandee.
    final String? contexte = p['p_groupe_id'] as String?;
    final String libelle = contexte == _classe1 ? 'An-Nour' : 'Al-Fatiha';
    return <String, dynamic>{
      'annonces': <Object>[
        _annonce(
          _generale,
          '2026-10-16T08:00:00Z',
          classeId: contexte,
          libelle: libelle,
        ),
        _annonce(
          _generale,
          '2026-10-16T08:00:00Z',
          classeId: contexte,
          libelle: libelle,
        ),
      ],
    };
  }

  setUp(() => appels = <String>[]);

  test('deux Classes : l annonce generale A figure une fois par liste, '
      'avec les annonces de chaque Classe', () async {
    final AnnoncesSupabase port = AnnoncesSupabase(
      serveur,
      libelles: const _Libelles(),
    );

    final AnnoncesDeLaClasse premiere = await port.annoncesDeClasse(_classe1);
    final AnnoncesDeLaClasse seconde = await port.annoncesDeClasse(_classe2);

    // Une liste sans doublon, la plus recente d'abord : A, puis l'annonce
    // de la Classe.
    expect(premiere.annonces.map((AnnonceClasse a) => a.id), <String>[
      _generale,
      _b1,
    ]);
    expect(seconde.annonces.map((AnnonceClasse a) => a.id), <String>[
      _generale,
      _b2,
    ]);
    // A est rendue dans le contexte de la Classe demandee.
    expect(premiere.annonces.first.classe.id, _classe1);
    expect(seconde.annonces.first.classe.id, _classe2);
  });

  test('une seule RPC de l academie par lecture de Classe', () async {
    await AnnoncesSupabase(
      serveur,
      libelles: const _Libelles(),
    ).annoncesDeClasse(_classe1);
    expect(appels, <String>[
      'com_annonces_de_classe $_classe1',
      'com_annonces_academie $_classe1',
    ]);
  });

  test('une annonce generale presente deux fois ne se rend qu une fois, '
      'sans perdre les annonces de Classe', () async {
    final AnnoncesDeLaClasse v = await AnnoncesSupabase(
      serveur,
      libelles: const _Libelles(),
    ).annoncesDeClasse(_classe2);
    final List<String> ids = v.annonces
        .map((AnnonceClasse a) => a.id)
        .toList();
    expect(ids.where((String id) => id == _generale), hasLength(1));
    expect(ids, contains(_b2));
    expect(ids.toSet(), hasLength(ids.length));
  });
}
