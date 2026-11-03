// PHOTOS-2a : les photos des personnes, en memoire.
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/photos/photos_personnes.dart';

/// Un serveur de photos en memoire : il rend les sources de [sources] (les
/// personnes que l'appelant « voit »), et retient les depots et les poses.
class FauxPhotos implements PortPhotos {
  /// Cree le faux.
  FauxPhotos({
    Map<String, SourcePhoto>? sources,
    this.adulte = true,
    this.surPose,
  }) : sources = sources ?? <String, SourcePhoto>{};

  /// Ce que le serveur rend, par identifiant de profil.
  final Map<String, SourcePhoto> sources;

  /// Ce que rend `puisPoserMaPhoto`.
  bool adulte;

  /// Appele a chaque pose reussie (le faux d'un ecran peut y relire sa vue,
  /// comme la base qui ecrit la colonne lue par la vue du foyer).
  final void Function(String personneId, String? cle)? surPose;

  /// Les lectures, une liste d'identifiants par appel.
  final List<List<String>> lectures = <List<String>>[];

  /// Les fichiers deposes.
  final List<({String personneId, String seau, PhotoEnfant photo})> depots =
      <({String personneId, String seau, PhotoEnfant photo})>[];

  /// Les poses de « ma photo ».
  final List<String?> posesMoi = <String?>[];

  /// Les poses de la photo d'un enfant.
  final List<({String eleveId, String? cle})> posesEleve =
      <({String eleveId, String? cle})>[];

  /// Ce que la lecture doit jeter.
  Object? erreurLecture;

  /// Ce que la pose doit jeter.
  Object? erreurPose;

  /// L'identifiant de l'appelant, pour `poserMaPhoto`.
  String moi = 'moi';

  @override
  Future<Map<String, SourcePhoto>> lire(List<String> ids) async {
    lectures.add(List<String>.of(ids));
    final Object? erreur = erreurLecture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return <String, SourcePhoto>{
      for (final String id in ids)
        if (sources[id] case final SourcePhoto s) id: s,
    };
  }

  @override
  Future<String> urlSignee(SourcePhoto source) async =>
      'https://exemple.test/${source.seau}/${source.cle}';

  @override
  Future<String> televerser({
    required String personneId,
    required String seau,
    required PhotoEnfant photo,
  }) async {
    depots.add((personneId: personneId, seau: seau, photo: photo));
    return '$personneId/${depots.length}.${photo.extension}';
  }

  SourcePhoto _poser(String id, String? cle) {
    final Object? erreur = erreurPose;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    final SourcePhoto source = SourcePhoto(
      seau: sources[id]?.seau ?? ServiceAvatarSupabase.seauAvatars,
      cle: cle,
    );
    sources[id] = source;
    surPose?.call(id, cle);
    return source;
  }

  @override
  Future<SourcePhoto> poserMaPhoto(String? cle) async {
    final SourcePhoto s = _poser(moi, cle);
    posesMoi.add(cle);
    return s;
  }

  @override
  Future<SourcePhoto> poserPhotoEleve(String eleveId, String? cle) async {
    final SourcePhoto s = _poser(eleveId, cle);
    posesEleve.add((eleveId: eleveId, cle: cle));
    return s;
  }

  @override
  Future<bool> puisPoserMaPhoto() async => adulte;
}
