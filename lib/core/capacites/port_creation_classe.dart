import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/service_groupes.dart';
import '../planning/service_planning.dart' show Creneau;
import 'creation_classe_supabase.dart';
import 'port_enseignants_classe.dart' show GenreClasse;

/// Le fuseau que le serveur retient quand on ne lui en transmet aucun :
/// `coalesce(p_timezone_iana, 'Europe/Paris')` dans `creer_groupe`
/// (`supabase/migrations/0033_tc_vues_rpc.sql`). Le formulaire l'affiche tel
/// quel tant que l'adaptateur ne transmet pas le fuseau ([PortCreationClasse.
/// retientFuseau] faux) : il ne pretend pas un autre fuseau.
const String fuseauServeurParDefaut = 'Europe/Paris';

/// La creation d'une classe (CLASSE-FORM-1, decision D1).
///
/// Un port a part parce que `ServiceGroupes.creer` est un contrat fige : il ne
/// prend ni le genre ni le fuseau. L'ecran demande tout ; l'adaptateur dit ce
/// qu'il retient vraiment, et l'ecran le dit a son tour (aucune simulation
/// d'enregistrement).
abstract interface class PortCreationClasse {
  /// Vrai quand le genre est enregistre avec la classe.
  bool get retientGenre;

  /// Vrai quand le fuseau du creneau est transmis au serveur.
  bool get retientFuseau;

  /// Cree la classe et rend son identifiant. [creneau] est le premier
  /// creneau de la semaine (l'ancre) ; [autresCreneaux], les suivants
  /// (classe a plusieurs creneaux, decision D2 du 29/10/2026).
  /// [durees] : la duree en minutes de chaque creneau, dans l'ordre
  /// ([creneau] puis [autresCreneaux]) ; nulle ou absente, la duree de la
  /// classe (30/10/2026).
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
    List<int?> durees = const <int?>[],
  });
}

/// L'adaptateur reel : delegue a [ServiceGroupes.creer] avec les champs que
/// la RPC `creer_groupe` accepte aujourd'hui (enseignant, public, libelle,
/// jour, heure, seuil). Le genre et le fuseau ne partent pas : lignes
/// Backend/Contrats de CLASSE-FORM-1.
class CreationClasseParServiceGroupes implements PortCreationClasse {
  /// Cree l'adaptateur.
  const CreationClasseParServiceGroupes(this._service);

  final ServiceGroupes _service;

  @override
  bool get retientGenre => false;

  @override
  bool get retientFuseau => false;

  /// Un seul creneau : [autresCreneaux] et [durees] ne partent pas avec
  /// `creer_groupe`.
  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
    List<int?> durees = const <int?>[],
  }) => _service.creer(
    teacherId: teacherId,
    type: type,
    libelle: libelle,
    creneau: creneau,
    seuilMax: seuilMax,
  );
}

/// La creation employee par l'application : `creer_classe_creneaux_admin`
/// (29/10/2026), qui retient le genre, le fuseau et tous les creneaux.
final Provider<PortCreationClasse> portCreationClasseProvider =
    Provider<PortCreationClasse>((Ref ref) {
      try {
        return CreationClasseSupabase(Supabase.instance.client);
      } on Object {
        // Hors du demarrage applicatif (tests, apercu isole) : l'ancien
        // chemin, qui dit lui-meme ne retenir ni genre ni fuseau.
        return CreationClasseParServiceGroupes(
          ref.watch(serviceGroupesProvider),
        );
      }
    });
