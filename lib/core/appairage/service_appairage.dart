import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// Un code d'appairage, tel que le tuteur le voit.
///
/// Il n'existe qu'ici et a l'ecran : la base n'en garde que l'empreinte, et
/// aucune requete ne peut le relire. Fermer l'ecran le perd, ce qui est le
/// comportement voulu pour un code a duree de vie courte.
@immutable
class CodeAppairage {
  /// Cree un code.
  const CodeAppairage({required this.code, required this.expireA});

  /// Le code a six caracteres, affiche et lu a voix haute.
  final String code;

  /// Le moment ou il cesse d'etre valable.
  final DateTime expireA;

  /// Le temps restant a un instant donne.
  Duration restantA(DateTime maintenant) {
    final Duration reste = expireA.difference(maintenant);
    return reste.isNegative ? Duration.zero : reste;
  }
}

/// Un appareil appaire, tel que `mes_appareils_v` l'expose.
@immutable
class AppareilAppaire {
  /// Cree la description d'un appareil.
  const AppareilAppaire({
    required this.id,
    required this.profilId,
    required this.prenom,
    required this.plateforme,
    required this.appaireA,
    this.derniereUtilisation,
    this.revoqueA,
  });

  /// Lit une ligne de la vue.
  factory AppareilAppaire.depuisJson(Map<String, dynamic> json) {
    DateTime? quand(String cle) {
      final Object? valeur = json[cle];
      return valeur is String ? DateTime.tryParse(valeur)?.toLocal() : null;
    }

    return AppareilAppaire(
      id: json['id'] as String,
      profilId: json['profile_id'] as String,
      prenom: json['first_name'] as String? ?? '',
      plateforme: json['platform'] as String? ?? '',
      appaireA: quand('paired_at') ?? DateTime.now(),
      derniereUtilisation: quand('last_used_at'),
      revoqueA: quand('revoked_at'),
    );
  }

  /// Identifiant de l'appareil.
  final String id;

  /// Le profil auquel il est appaire.
  final String profilId;

  /// Le prenom de l'enfant, pour reconnaitre la ligne.
  final String prenom;

  /// Windows, Android, iOS ou Web.
  final String plateforme;

  /// Date d'appairage.
  final DateTime appaireA;

  /// Derniere entree constatee.
  final DateTime? derniereUtilisation;

  /// Date de revocation, quand il y en a une.
  final DateTime? revoqueA;

  /// Vrai tant que l'appareil compte dans le plafond.
  bool get actif => revoqueA == null;
}

/// Un eleve du foyer, tel que `profils_du_foyer_v` l'expose.
@immutable
class EleveDuFoyer {
  /// Cree la description d'un eleve.
  const EleveDuFoyer({
    required this.id,
    required this.prenom,
    required this.identifiantImmuable,
    required this.mode,
    required this.camera,
    this.cleAvatar,
    this.finAcces,
  });

  /// Lit une ligne de la vue.
  factory EleveDuFoyer.depuisJson(Map<String, dynamic> json) => EleveDuFoyer(
    id: json['id'] as String,
    prenom: json['first_name'] as String? ?? '',
    identifiantImmuable: json['immutable_id'] as String? ?? '',
    mode: InterfaceMode.depuisSql(json['interface_mode'] as String?),
    camera: CameraPolicy.depuisSql(json['camera_policy'] as String?),
    cleAvatar: json['avatar_storage_key'] as String?,
    finAcces: DateTime.tryParse(json['access_until'] as String? ?? '')
        ?.toLocal(),
  );

  /// Identifiant du profil.
  final String id;

  /// Prenom.
  final String prenom;

  /// Identifiant immuable, celui qu'un enseignant voit.
  final String identifiantImmuable;

  /// Mode d'interface.
  final InterfaceMode mode;

  /// Politique camera.
  final CameraPolicy camera;

  /// Cle de l'avatar dans le stockage.
  final String? cleAvatar;

  /// Date de fin d'acces, quand le compte en porte une (ADR-014).
  ///
  /// `null` est le cas ordinaire : un compte valide n'a pas d'echeance. Elle ne
  /// vaut que pour les foyers importes, dont le profil reste a completer, et
  /// c'est ce que `TUT-01` affiche en MVP-0 a la place d'un portefeuille.
  final DateTime? finAcces;
}

/// L'appairage, cote tuteur.
abstract interface class ServiceAppairage {
  /// Les eleves du foyer.
  Future<List<EleveDuFoyer>> eleves();

  /// Les appareils du foyer, revoques compris.
  Future<List<AppareilAppaire>> appareils();

  /// Demande un code d'appairage pour un eleve.
  ///
  /// Le plafond d'appareils est verifie **en base**, pas ici : deux ecrans
  /// ouverts en meme temps ne doivent pas pouvoir en creer un troisieme.
  Future<CodeAppairage> creerCode(String eleveId);

  /// Retire un appareil, et son jeton avec lui.
  Future<void> revoquer(String appareilId);

  /// Cree le profil d'un enfant du foyer.
  Future<void> creerEnfant({
    required String prenom,
    required String nom,
    required int age,
    String? niveau,
  });

  /// Ecrit les trois reglages de `TUT-05` pour un enfant du foyer.
  ///
  /// **Trois colonnes, pas une de plus.** Ce que la base autorise ici est un
  /// `GRANT UPDATE (interface_mode, camera_policy, avatar_storage_key)` :
  /// le niveau, la riwaya et le type d'eleve sont des donnees pedagogiques, et
  /// la porte de l'administration pour les changer est ailleurs. Une RLS borne
  /// les lignes, pas les colonnes, d'ou ce grant (invariant I6, defaut 3.3).
  ///
  /// Chaque parametre laisse a `null` ce qui ne change pas : cet ecran regle un
  /// reglage a la fois, et envoyer les trois a chaque fois ecraserait ce qu'un
  /// autre appareil du foyer vient de poser.
  Future<void> majReglages({
    required String eleveId,
    InterfaceMode? mode,
    CameraPolicy? camera,
    String? cleAvatar,
  });

  /// Le plafond d'appareils affiche a l'ecran.
  ///
  /// La valeur qui fait foi est celle de `app_config`, lue en base au moment de
  /// l'appairage. Celle-ci ne sert qu'a remplacer le bouton d'ajout par un
  /// message avant que l'utilisateur ne le presse.
  static const int appareilsParEleve = 2;
}

/// L'implementation reelle.
class ServiceAppairageSupabase implements ServiceAppairage {
  /// Cree le service.
  const ServiceAppairageSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('profils_du_foyer_v')
        .select();
    return lignes.map(EleveDuFoyer.depuisJson).toList();
  }

  /// Plus recent d'abord, ecrit en toutes lettres (demandes B-2 et D-2 ;
  /// `03` section 1 ter bis-2) : sans `ascending`, PostgREST trie deja en
  /// decroissant, mais un sens implicite est celui qui a mis le Coran a
  /// l'envers. Un ecran qui veut un autre ordre le pose lui-meme.
  @override
  Future<List<AppareilAppaire>> appareils() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_appareils_v')
        .select()
        .order('paired_at', ascending: false);
    return lignes.map(AppareilAppaire.depuisJson).toList();
  }

  @override
  Future<CodeAppairage> creerCode(String eleveId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'creer_code_appairage',
      params: <String, dynamic>{'p_student_profile_id': eleveId},
    );
    if (reponse.isEmpty) {
      throw StateError('aucun code rendu');
    }
    final Map<String, dynamic> ligne = reponse.first as Map<String, dynamic>;
    return CodeAppairage(
      code: ligne['code'] as String,
      expireA:
          DateTime.tryParse(ligne['expires_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  @override
  Future<void> revoquer(String appareilId) => _client.rpc<void>(
    'revoquer_appareil',
    params: <String, dynamic>{'p_device_id': appareilId},
  );

  @override
  Future<void> creerEnfant({
    required String prenom,
    required String nom,
    required int age,
    String? niveau,
  }) async {
    // La creation de l'utilisateur d'authentification demande la cle de
    // service : elle ne peut donc pas se faire ici. La fonction Edge la detient
    // et revérifie que l'appelant est bien le tuteur du foyer vise.
    await _client.functions.invoke(
      'creer-profil-enfant',
      body: <String, dynamic>{
        'first_name': prenom,
        'last_name': nom,
        'age': age,
        'level': ?niveau,
      },
    );
  }

  @override
  Future<void> majReglages({
    required String eleveId,
    InterfaceMode? mode,
    CameraPolicy? camera,
    String? cleAvatar,
  }) async {
    final Map<String, dynamic> champs = <String, dynamic>{
      'interface_mode': ?mode?.valeurSql,
      'camera_policy': ?camera?.valeurSql,
      'avatar_storage_key': ?cleAvatar,
    };
    if (champs.isEmpty) {
      return;
    }

    // Sans `.select()` : la ligne modifiee n'est pas relue, et une lecture de
    // retour demanderait un droit que ce chemin n'a pas besoin d'avoir.
    await _client
        .from('student_profiles')
        .update(champs)
        .eq('profile_id', eleveId);
  }
}

/// Le service d'appairage employe par l'application.
final Provider<ServiceAppairage> serviceAppairageProvider =
    Provider<ServiceAppairage>(
      (Ref ref) => ServiceAppairageSupabase(Supabase.instance.client),
    );

/// Les eleves du foyer.
final FutureProvider<List<EleveDuFoyer>> elevesDuFoyerProvider =
    FutureProvider<List<EleveDuFoyer>>(
      (Ref ref) => ref.watch(serviceAppairageProvider).eleves(),
    );

/// Les appareils du foyer.
final FutureProvider<List<AppareilAppaire>> appareilsDuFoyerProvider =
    FutureProvider<List<AppareilAppaire>>(
      (Ref ref) => ref.watch(serviceAppairageProvider).appareils(),
    );
