// Les annonces de l'academie, telles que la cloche les lit (CLOCHE-C,
// decision du directeur du 21/11/2026, `DECISION-ANNONCES-NOTIFS-2026-11-21`
// §2 : 20 a la fois, annonces qu'on ferme, texte traduit et original).
//
// Le contrat serveur (`com_mes_annonces` pagine, `com_annonce_fermer`,
// `com_annonce_rouvrir`, champs de traduction) est porte par le lot
// ANNONCES-SERVEUR, qui etend `PortAnnoncesDirection`. Tant qu'il n'est pas
// dans `main`, la source de production lit le fil actuel (`mesAnnonces()`),
// pagine ici, et **ne sait pas fermer** : la croix n'est pas rendue (un bouton
// qui ne peut pas aboutir n'est pas rendu, `lib/CLAUDE.md`). Les ecrans ne
// lisent que cette source : le jour ou le port gagne le contrat, seule
// [SourceAnnoncesDepuisPort] change.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../com_annonces/port_annonces_direction.dart';

/// Une annonce de l'academie, vue par la cloche.
@immutable
class AnnonceCloche {
  /// Cree l'annonce.
  const AnnonceCloche({
    required this.id,
    required this.titre,
    required this.texte,
    required this.publieeLe,
    this.vue = false,
    this.fermee = false,
    this.traduite = false,
    this.titreOriginal,
    this.texteOriginal,
    this.langueOriginale,
  });

  /// L'annonce du fil actuel, sans traduction ni fermeture.
  factory AnnonceCloche.depuis(AnnonceRecue a) => AnnonceCloche(
    id: a.id,
    titre: a.titre,
    texte: a.texte,
    publieeLe: a.publieeLe,
    vue: a.vue,
  );

  /// Identifiant.
  final String id;

  /// Le titre, dans la langue du compte (ou l'original).
  final String titre;

  /// Le texte, dans la langue du compte (ou l'original).
  final String texte;

  /// L'instant de diffusion (UTC).
  final DateTime publieeLe;

  /// Vrai si la personne l'a deja vue.
  final bool vue;

  /// Vrai si la personne l'a fermee : elle quitte « Tout » et l'accueil, et
  /// reste lisible dans « Annonces ».
  final bool fermee;

  /// Vrai si [titre] et [texte] sont une traduction.
  final bool traduite;

  /// Le titre original, quand l'annonce est traduite.
  final String? titreOriginal;

  /// Le texte original, quand l'annonce est traduite.
  final String? texteOriginal;

  /// La langue de l'original (`fr`, `en`, `ar`), quand elle est connue.
  final String? langueOriginale;

  /// Vrai quand « Voir le texte original » a quelque chose a montrer.
  bool get aUnOriginal => traduite && (texteOriginal ?? '').trim().isNotEmpty;

  /// La meme annonce, vue.
  AnnonceCloche vueOui() => _copie(vue: true);

  /// La meme annonce, fermee ou rouverte.
  AnnonceCloche avecFermee(bool f) => _copie(fermee: f);

  AnnonceCloche _copie({bool? vue, bool? fermee}) => AnnonceCloche(
    id: id,
    titre: titre,
    texte: texte,
    publieeLe: publieeLe,
    vue: vue ?? this.vue,
    fermee: fermee ?? this.fermee,
    traduite: traduite,
    titreOriginal: titreOriginal,
    texteOriginal: texteOriginal,
    langueOriginale: langueOriginale,
  );
}

/// Une page d'annonces : au plus [SourceAnnoncesCloche.taillePage], et le
/// curseur de la suivante ([suite], nul a la fin).
@immutable
class PageAnnoncesCloche {
  /// Cree la page.
  const PageAnnoncesCloche({required this.annonces, this.suite});

  /// Les annonces, de la plus recente a la plus ancienne.
  final List<AnnonceCloche> annonces;

  /// Le curseur de la page suivante, ou nul.
  final DateTime? suite;
}

/// Ce que la cloche demande aux annonces.
abstract interface class SourceAnnoncesCloche {
  /// La taille d'une page (decision du 21/11, regle 5).
  static const int taillePage = 20;

  /// Vrai quand le serveur sait fermer et rouvrir une annonce : sinon, la
  /// croix n'est pas rendue.
  bool get fermetureServie;

  /// Une page d'annonces, avant [avant] ; [fermees] : toutes (onglet
  /// « Annonces »), sinon seulement celles qui ne sont pas fermees.
  Future<PageAnnoncesCloche> page({
    int limite = taillePage,
    DateTime? avant,
    bool fermees = false,
  });

  /// Ferme l'annonce [id] pour la personne.
  Future<void> fermer(String id);

  /// Rouvre l'annonce [id] (« Annuler » pendant 5 secondes).
  Future<void> rouvrir(String id);

  /// Compte l'annonce [id] « vue ».
  Future<void> marquerVue(String id);
}

/// La source de production : le fil actuel du port, pagine ici.
///
/// Le fil actuel rend toutes les annonces des 90 derniers jours d'un coup ;
/// la page est decoupee ici, par instant de diffusion. Il ne connait ni la
/// fermeture ni la traduction.
class SourceAnnoncesDepuisPort implements SourceAnnoncesCloche {
  /// Cree la source sur [port].
  const SourceAnnoncesDepuisPort(this.port);

  /// Le port des annonces de la direction.
  final PortAnnoncesDirection port;

  @override
  bool get fermetureServie => false;

  @override
  Future<PageAnnoncesCloche> page({
    int limite = SourceAnnoncesCloche.taillePage,
    DateTime? avant,
    bool fermees = false,
  }) async {
    final List<AnnonceRecue> toutes = await port.mesAnnonces();
    return decouperPage(
      <AnnonceCloche>[
        for (final AnnonceRecue a in toutes) AnnonceCloche.depuis(a),
      ],
      limite: limite,
      avant: avant,
    );
  }

  @override
  Future<void> fermer(String id) =>
      Future<void>.error(const CapaciteIndisponible('com_annonce_fermer'));

  @override
  Future<void> rouvrir(String id) =>
      Future<void>.error(const CapaciteIndisponible('com_annonce_rouvrir'));

  @override
  Future<void> marquerVue(String id) => port.marquerVue(id);
}

/// Decoupe [toutes] en une page : les plus recentes avant [avant], au plus
/// [limite], et le curseur de la suivante. Pure et testee.
PageAnnoncesCloche decouperPage(
  List<AnnonceCloche> toutes, {
  required int limite,
  DateTime? avant,
}) {
  final List<AnnonceCloche> triees =
      toutes
          .where(
            (AnnonceCloche a) => avant == null || a.publieeLe.isBefore(avant),
          )
          .toList()
        ..sort(
          (AnnonceCloche a, AnnonceCloche b) =>
              b.publieeLe.compareTo(a.publieeLe),
        );
  final List<AnnonceCloche> page = triees.take(limite).toList();
  return PageAnnoncesCloche(
    annonces: List<AnnonceCloche>.unmodifiable(page),
    suite: triees.length > limite ? page.last.publieeLe : null,
  );
}

/// La source employee par la cloche ; surchargee par les tests et la galerie.
final Provider<SourceAnnoncesCloche> sourceAnnoncesClocheProvider =
    Provider<SourceAnnoncesCloche>(
      (Ref ref) =>
          SourceAnnoncesDepuisPort(ref.watch(portAnnoncesDirectionProvider)),
    );
