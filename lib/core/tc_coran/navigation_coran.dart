import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coran/service_coran.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../tc_bibliotheque/content_position.dart';
import '../tc_etat_partage/port_etat_partage.dart';
import '../tc_etat_partage/shared_content_state.dart';
import 'corpus_service_coran.dart';
import 'port_corpus_coran.dart';
import 'port_navigation_coran.dart';

/// La navigation du mushaf, posee au-dessus du corpus et de l'etat partage.
///
/// Elle ne lit **aucune** table elle-meme : le corpus passe par
/// [PortCorpusCoran], la position personnelle par le `ServiceCoran` existant,
/// et la position de groupe par [PortEtatPartage]. Trois sources, trois
/// responsabilites, et surtout **deux stockages de position qui ne se touchent
/// jamais** (invariant J2 de la migration `0007`).
class NavigationCoran implements PortNavigationCoran {
  /// Cree la navigation.
  const NavigationCoran({
    required this.corpus,
    required this.service,
    required this.profilCourant,
    this.etatPartage,
  });

  /// L'acces au corpus, en lecture seule.
  final PortCorpusCoran corpus;

  /// Le service existant, pour la position personnelle uniquement.
  final ServiceCoran service;

  /// Le profil du lecteur courant, ou `null` s'il n'y a pas de session.
  final String? Function() profilCourant;

  /// `null` tant qu'Agent F n'a pas livre son implementation.
  ///
  /// Le moteur fonctionne sans : hors classe, il n'y a pas d'etat partage, et
  /// c'est le cas nominal. Un `null` ici ne se traduit donc pas en erreur, mais
  /// en « aucune position de groupe », ce qui est exact.
  final PortEtatPartage? etatPartage;

  @override
  Future<int?> pageDe(CibleCoran cible) async {
    switch (cible) {
      case CiblePage(page: final int page):
        return page >= 1 && page <= pagesMushafMedine ? page : null;
      case CibleSourate(sourate: final int sourate):
        return corpus.pageDeDebutDeSourate(sourate);
      case CibleJuz(juz: final int juz):
        return corpus.pageDeDebutDeJuz(juz);
      case CibleAyah(sourate: final int sourate, ayah: final int ayah):
        final PageCorpus? page = await corpus.pageDeAyah(
          sourate: sourate,
          ayah: ayah,
        );
        return page?.numero;
    }
  }

  @override
  Future<PositionLecture?> dernierePositionPersonnelle() async {
    final String? profil = profilCourant();
    if (profil == null) {
      return null;
    }
    return service.position(profil);
  }

  @override
  Future<bool> memoriserPositionPersonnelle(
    PositionLecture position, {
    required OrigineNavigation origine,
  }) async {
    // La barriere, et elle est ici plutot que dans l'ecran : un ecran se
    // reecrit, une regle posee au point d'ecriture ne se contourne pas par
    // distraction.
    if (origine != OrigineNavigation.personnelle) {
      return false;
    }
    final String? profil = profilCourant();
    if (profil == null) {
      return false;
    }
    return service.enregistrerPosition(profil, position);
  }

  @override
  Future<PositionLecture?> positionDeGroupe(String sessionId) async {
    final PortEtatPartage? partage = etatPartage;
    if (partage == null) {
      return null;
    }
    final SharedContentState? etat = await partage.etatCourant(sessionId);
    final ContentPosition? reprise = etat?.groupResumePosition;
    if (reprise == null) {
      return null;
    }
    return _versPositionLecture(reprise);
  }

  @override
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete) =>
      corpus.rechercher(requete);

  /// Traduit une position canonique en position de mushaf.
  ///
  /// L'ancrage semantique a besoin d'une lecture pour retrouver sa page : la
  /// pagination appartient a l'edition, et aucune formule ne la donne.
  Future<PositionLecture?> _versPositionLecture(
    ContentPosition position,
  ) async {
    switch (position.typeAncrage) {
      case TypeAncrage.ayah:
        final int? sourate = position.sourate;
        final int? ayah = position.ayah;
        if (sourate == null || ayah == null) {
          return null;
        }
        final PageCorpus? page = await corpus.pageDeAyah(
          sourate: sourate,
          ayah: ayah,
        );
        if (page == null) {
          return null;
        }
        return PositionLecture(
          page: page.numero,
          sourate: sourate,
          verset: ayah,
        );
      case TypeAncrage.page:
        final int? numero = position.page;
        if (numero == null) {
          return null;
        }
        final PageCorpus? page = await corpus.page(numero);
        final VersetCorpus? premier = page == null || page.vide
            ? null
            : page.versets.first;
        return PositionLecture(
          page: numero,
          sourate: premier?.sourate ?? 1,
          verset: premier?.numero ?? 1,
        );
      case TypeAncrage.section:
      case TypeAncrage.fraction:
        // Le Coran n'a ni section ni fraction : une position de ce type ne
        // designe pas le mushaf, et l'arrondir a la page 1 serait un mensonge.
        return null;
    }
  }
}

/// La navigation employee par l'application.
final Provider<PortNavigationCoran> portNavigationCoranProvider =
    Provider<PortNavigationCoran>(
      (Ref ref) => NavigationCoran(
        corpus: ref.watch(portCorpusCoranProvider),
        service: ref.watch(serviceCoranProvider),
        profilCourant: () => ref.read(sessionProvider).profileId,
        etatPartage: ref.watch(portEtatPartageCoranProvider),
      ),
    );

/// L'etat partage, vu par le moteur Coran.
///
/// **Surcharge par Agent Z a l'integration**, quand `PortEtatPartage` d'Agent F
/// existera. `null` par defaut, et c'est le comportement correct hors classe :
/// il n'y a alors aucun etat partage a suivre.
final Provider<PortEtatPartage?> portEtatPartageCoranProvider =
    Provider<PortEtatPartage?>((Ref ref) => null);

/// La derniere position personnelle du lecteur.
final FutureProvider<PositionLecture?> dernierePositionCoranProvider =
    FutureProvider<PositionLecture?>((Ref ref) {
      final SessionState session = ref.watch(sessionProvider);
      if (session.profileId == null) {
        return Future<PositionLecture?>.value();
      }
      return ref
          .watch(portNavigationCoranProvider)
          .dernierePositionPersonnelle();
    });
