import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une photo choisie par le tuteur, prete a partir.
///
/// Volontairement distincte de `PieceAEnvoyer` : une piece d'identite porte un
/// `TypePiece` et part vers le seau `kyc`, dont l'administration seule relit le
/// contenu. Une photo d'enfant n'a pas de type de piece et part ailleurs, sous
/// des policies qui ne sont pas les memes. Un seul type pour les deux ferait
/// croire, tot ou tard, que les deux chemins se valent.
@immutable
class PhotoEnfant {
  /// Cree une photo.
  const PhotoEnfant({required this.octets, required this.nomFichier});

  /// Le contenu du fichier.
  final Uint8List octets;

  /// Le nom d'origine, dont on ne garde que l'extension.
  final String nomFichier;

  /// Taille en mega-octets, pour le message de refus.
  double get tailleMo => octets.lengthInBytes / (1024 * 1024);

  /// L'extension retenue, en minuscules et sans point.
  String get extension {
    final int point = nomFichier.lastIndexOf('.');
    if (point < 0 || point == nomFichier.length - 1) {
      return 'jpg';
    }
    return nomFichier.substring(point + 1).toLowerCase();
  }

  /// Le type de contenu annonce au stockage, deduit de l'extension.
  ///
  /// Sans lui, le seau range la photo en `application/octet-stream` et un
  /// navigateur la telecharge au lieu de l'afficher. Une extension inconnue
  /// garde ce type generique plutot que d'en inventer un.
  String get typeMime => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'application/octet-stream',
  };
}

/// D'ou vient la photo d'un enfant.
///
/// Une interface, pour la meme raison que `SelecteurFichier` : aucun test ne
/// peut ouvrir une boite de dialogue native.
abstract interface class SelecteurPhoto {
  /// Demande une photo a l'utilisateur. `null` quand il renonce.
  Future<PhotoEnfant?> choisirPhoto();
}

/// Le selecteur reel, par la boite de dialogue du systeme.
class SelecteurPhotoNatif implements SelecteurPhoto {
  /// Cree le selecteur.
  const SelecteurPhotoNatif();

  /// Ce qu'une photo de profil peut etre. Aucun PDF, contrairement au KYC :
  /// c'est un visage, pas un document.
  static const List<String> extensionsAcceptees = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
  ];

  @override
  Future<PhotoEnfant?> choisirPhoto() async {
    final PlatformFile? fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensionsAcceptees,
    );
    if (fichier == null) {
      return null;
    }
    return PhotoEnfant(
      octets: await fichier.readAsBytes(),
      nomFichier: fichier.name,
    );
  }
}

/// La photo de profil d'un enfant, cote tuteur (ADR-012).
///
/// Le seau `avatars` et ses quatre policies existent depuis la migration 0004 :
/// le tuteur ecrit dans le dossier de son enfant, le foyer et l'enfant lisent,
/// ni l'enseignant ni les autres eleves. Ce service n'ouvre donc aucune porte
/// nouvelle, il emprunte celle qui attendait son ecran.
abstract interface class ServiceAvatar {
  /// Depose une photo pour un enfant et rend la cle de stockage.
  ///
  /// L'ecriture de cette cle dans `student_profiles` reste a l'appelant :
  /// `ServiceAppairage.majReglages` est le seul chemin qui touche a ces trois
  /// colonnes, et un second en ferait deux.
  Future<String> televerser({
    required String eleveId,
    required PhotoEnfant photo,
  });

  /// Une URL signee de courte duree pour afficher une photo.
  ///
  /// Jamais une URL publique stable : c'est le visage d'un enfant, et une
  /// adresse permanente circulerait aussi longtemps que quelqu'un la garde
  /// (ADR-012).
  Future<String> urlSignee(String cleAvatar);

  /// Taille maximale acceptee pour une photo de profil.
  ///
  /// Plus basse que celle d'une piece d'identite : une piece doit rester
  /// lisible a l'agrandissement, un visage rond de cent pixels n'en a pas
  /// besoin.
  static const int tailleMaximaleOctets = 4 * 1024 * 1024;
}

/// L'implementation reelle.
class ServiceAvatarSupabase implements ServiceAvatar {
  /// Cree le service.
  const ServiceAvatarSupabase(this._client);

  final SupabaseClient _client;

  /// Le seau prive des photos de profil, cree par la migration 0004.
  static const String seauAvatars = 'avatars';

  /// Duree de vie d'une URL de photo, en secondes.
  ///
  /// Plus longue que l'apercu d'une piece d'identite : cette URL sert a
  /// afficher une liste d'enfants qu'un parent laisse ouverte, et la
  /// regenerer toutes les minutes ferait clignoter les visages.
  static const int dureeUrlSecondes = 600;

  @override
  Future<String> televerser({
    required String eleveId,
    required PhotoEnfant photo,
  }) async {
    // Le premier segment du chemin est l'identifiant de l'ENFANT, pas celui du
    // tuteur : c'est lui que `profil_de_mon_foyer()` compare dans la policy de
    // stockage. Un nom horodate evite qu'une photo remplacee reste servie par
    // un cache qui n'a pas encore vu passer l'evenement de purge.
    final String cle =
        '$eleveId/${DateTime.now().toUtc().millisecondsSinceEpoch}'
        '.${photo.extension}';

    await _client.storage
        .from(ServiceAvatarSupabase.seauAvatars)
        .uploadBinary(
          cle,
          photo.octets,
          fileOptions: FileOptions(contentType: photo.typeMime),
        );

    return cle;
  }

  @override
  Future<String> urlSignee(String cleAvatar) => _client.storage
      .from(ServiceAvatarSupabase.seauAvatars)
      .createSignedUrl(cleAvatar, dureeUrlSecondes);
}

/// Le service de photos employe par l'application.
final Provider<ServiceAvatar> serviceAvatarProvider = Provider<ServiceAvatar>(
  (Ref ref) => ServiceAvatarSupabase(Supabase.instance.client),
);

/// Le selecteur de photo employe par l'application.
final Provider<SelecteurPhoto> selecteurPhotoProvider =
    Provider<SelecteurPhoto>((Ref ref) => const SelecteurPhotoNatif());

/// L'URL signee d'une photo, par sa cle de stockage.
///
/// `AvatarTile` se replie sur les initiales quand elle est absente ou qu'elle
/// echoue : un enfant qui voit un triangle rouge a la place de son visage
/// comprend qu'il a casse quelque chose.
final FutureProviderFamily<String, String> avatarUrlProvider =
    FutureProvider.family<String, String>(
      (Ref ref, String cleAvatar) =>
          ref.watch(serviceAvatarProvider).urlSignee(cleAvatar),
    );
