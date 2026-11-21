// Les annonces de l'academie, telles que la cloche les lit (CLOCHE-C,
// decision du directeur du 21/11/2026, `DECISION-ANNONCES-NOTIFS-2026-11-21`
// §2 : 20 a la fois, annonces qu'on ferme, texte traduit et original).
//
// Le contrat serveur (`com_mes_annonces` pagine, `com_annonce_fermer`,
// `com_annonce_rouvrir`, champs de traduction) est porte par le lot
// ANNONCES-SERVEUR (PR 694), dans `PortAnnoncesDirection`. Les ecrans ne
// lisent que cette source ; une source qui ne sait pas fermer
// ([SourceAnnoncesCloche.fermetureServie] faux) ne montre aucune croix (un
// bouton qui ne peut pas aboutir n'est pas rendu, `lib/CLAUDE.md`).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// L'annonce telle que le port la rend (contrat du 21/11).
  factory AnnonceCloche.depuis(AnnonceRecue a) => AnnonceCloche(
    id: a.id,
    titre: a.titre,
    texte: a.texte,
    publieeLe: a.publieeLe,
    vue: a.vue,
    fermee: a.fermee,
    traduite: a.traduite,
    titreOriginal: a.titreOriginal,
    texteOriginal: a.texteOriginal,
    langueOriginale: a.langueOriginale,
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

/// La source de production : le port des annonces (pagination, fermeture et
/// traduction au serveur). Sans source (mineur, migration absente), le port
/// refuse par `CapaciteIndisponible` : la cloche montre alors ses
/// notifications seules.
class SourceAnnoncesDepuisPort implements SourceAnnoncesCloche {
  /// Cree la source sur [port].
  const SourceAnnoncesDepuisPort(this.port);

  /// Le port des annonces de la direction.
  final PortAnnoncesDirection port;

  @override
  bool get fermetureServie => port is! AnnoncesDirectionIndisponibles;

  @override
  Future<PageAnnoncesCloche> page({
    int limite = SourceAnnoncesCloche.taillePage,
    DateTime? avant,
    bool fermees = false,
  }) async {
    final PageAnnonces lue = await port.mesAnnonces(
      limite: limite,
      avant: avant,
      fermees: fermees,
    );
    return PageAnnoncesCloche(
      annonces: List<AnnonceCloche>.unmodifiable(<AnnonceCloche>[
        for (final AnnonceRecue a in lue.annonces) AnnonceCloche.depuis(a),
      ]),
      suite: lue.suite,
    );
  }

  @override
  Future<void> fermer(String id) => port.fermer(id);

  @override
  Future<void> rouvrir(String id) => port.rouvrir(id);

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
