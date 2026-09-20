import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coran/service_coran.dart';
import 'port_corpus_coran.dart';

/// Les debuts de juz, en attendant que la base les expose.
///
/// **Double local declare, pas une donnee inventee.** La table `public.juz`
/// (migration `0007`) porte deja `sourate_depart` et `verset_depart` pour les
/// trente juz, et `0013` les a remplis. Mais `ServiceCoran` est **PROTECTED**
/// et n'expose aucune lecture de `juz` : le moteur ne peut donc pas les lire
/// aujourd'hui sans ouvrir une seconde voie d'acces au corpus, ce que
/// `TEACHING_CORE_EXISTING_MAPPING.md` section 9.3 interdit.
///
/// La demande `ServiceCoran.debutDeJuz(int)` est ecrite dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_C.md`. **Ce tableau disparait le
/// jour ou elle aboutit** : il n'est la que pour que la navigation par juz ne
/// soit pas absente du lot.
abstract final class DebutsDeJuz {
  /// Le verset d'ouverture de chaque juz, du premier au trentieme.
  ///
  /// Decoupage Hafs, celui de l'edition `madina-hafs-604`.
  static const List<({int sourate, int verset})> table =
      <({int sourate, int verset})>[
        (sourate: 1, verset: 1),
        (sourate: 2, verset: 142),
        (sourate: 2, verset: 253),
        (sourate: 3, verset: 92),
        (sourate: 4, verset: 24),
        (sourate: 4, verset: 148),
        (sourate: 5, verset: 82),
        (sourate: 6, verset: 111),
        (sourate: 7, verset: 88),
        (sourate: 8, verset: 41),
        (sourate: 9, verset: 93),
        (sourate: 11, verset: 6),
        (sourate: 12, verset: 53),
        (sourate: 15, verset: 1),
        (sourate: 17, verset: 1),
        (sourate: 18, verset: 75),
        (sourate: 21, verset: 1),
        (sourate: 23, verset: 1),
        (sourate: 25, verset: 21),
        (sourate: 27, verset: 56),
        (sourate: 29, verset: 46),
        (sourate: 33, verset: 31),
        (sourate: 36, verset: 28),
        (sourate: 39, verset: 32),
        (sourate: 41, verset: 47),
        (sourate: 46, verset: 1),
        (sourate: 51, verset: 31),
        (sourate: 58, verset: 1),
        (sourate: 67, verset: 1),
        (sourate: 78, verset: 1),
      ];

  /// Le nombre de juz du mushaf.
  static const int nombre = 30;
}

/// L'adaptateur LECTURE SEULE au-dessus de `ServiceCoran`.
///
/// **Il n'ouvre aucune seconde voie vers le corpus.** Tout passe par le service
/// existant, qui est PROTECTED : ce fichier traduit ses types en types de
/// contrat et rien d'autre. Un `SupabaseClient` n'apparait pas ici, et ne doit
/// jamais y apparaitre -- ce serait le second service de lecture du Coran que
/// `TEACHING_CORE_EXISTING_MAPPING.md` section 9.3 interdit.
class CorpusDepuisServiceCoran implements PortCorpusCoran {
  /// Cree l'adaptateur.
  CorpusDepuisServiceCoran(this._service);

  final ServiceCoran _service;

  /// Les sourates, resolues une fois : la liste ne change jamais en cours
  /// d'usage, et la recherche par nom la relit a chaque frappe.
  List<SourateVM>? _souratesEnCache;

  @override
  Future<List<SourateVM>> sourates() async {
    final List<SourateVM>? deja = _souratesEnCache;
    if (deja != null) {
      return deja;
    }
    final List<Sourate>? lues = await _service.sourates();
    if (lues == null) {
      // `null` cote service veut dire « je ne sais pas », pas « aucune
      // sourate ». Le contrat de port rend une liste non nullable : la seule
      // traduction honnete de l'ignorance est donc l'exception.
      throw const EchecCorpusCoran('liste des sourates illisible');
    }
    final List<SourateVM> converties = lues
        .map(
          (Sourate s) => SourateVM(
            numero: s.numero,
            nomArabe: s.nomArabe,
            nomTranslittere: s.nomTranslittere,
            mecquoise: s.mecquoise,
            nombreVersets: s.nombreVersets,
          ),
        )
        .toList(growable: false);
    _souratesEnCache = converties;
    return converties;
  }

  @override
  Future<PageCorpus?> page(int numeroPage) async {
    if (numeroPage < 1 || numeroPage > pagesMushafMedine) {
      return null;
    }
    final PageCoran? lue = await _service.page(numeroPage);
    if (lue == null) {
      throw EchecCorpusCoran('page $numeroPage illisible');
    }
    return _convertir(lue);
  }

  @override
  Future<PageCorpus?> pageDeAyah({
    required int sourate,
    required int ayah,
  }) async {
    final int? numero = await _service.pageDe(sourate, ayah);
    if (numero == null) {
      return null;
    }
    return page(numero);
  }

  @override
  Future<int?> pageDeDebutDeSourate(int sourate) {
    if (sourate < 1 || sourate > 114) {
      return Future<int?>.value();
    }
    // La page de debut d'une sourate, c'est la page de son premier verset.
    // Elle se LIT dans le corpus ; aucune formule ne la donne.
    return _service.pageDe(sourate, 1);
  }

  @override
  Future<int?> pageDeDebutDeJuz(int juz) {
    if (juz < 1 || juz > DebutsDeJuz.nombre) {
      return Future<int?>.value();
    }
    final ({int sourate, int verset}) debut = DebutsDeJuz.table[juz - 1];
    return _service.pageDe(debut.sourate, debut.verset);
  }

  @override
  Future<List<ResultatRechercheCoran>> rechercher(String requete) async {
    final String propre = requete.trim();
    if (propre.isEmpty) {
      return const <ResultatRechercheCoran>[];
    }

    final List<ResultatRechercheCoran> resultats = <ResultatRechercheCoran>[];

    final ({int sourate, int ayah})? reference = lireReference(propre);
    if (reference != null) {
      final int? page = await _service.pageDe(
        reference.sourate,
        reference.ayah,
      );
      if (page != null) {
        resultats.add(
          ResultatRechercheCoran(
            type: TypeResultatRecherche.reference,
            page: page,
            libelle: '${reference.sourate}:${reference.ayah}',
            sourate: reference.sourate,
            ayah: reference.ayah,
          ),
        );
      }
      return resultats;
    }

    final int? juz = lireNombreApresMot(propre, 'juz');
    if (juz != null && juz >= 1 && juz <= DebutsDeJuz.nombre) {
      final int? page = await pageDeDebutDeJuz(juz);
      if (page != null) {
        resultats.add(
          ResultatRechercheCoran(
            type: TypeResultatRecherche.juz,
            page: page,
            libelle: 'Juz $juz',
            juz: juz,
          ),
        );
      }
      return resultats;
    }

    final int? pageDemandee = lireNombreApresMot(propre, 'page');
    if (pageDemandee != null) {
      if (pageDemandee >= 1 && pageDemandee <= pagesMushafMedine) {
        resultats.add(
          ResultatRechercheCoran(
            type: TypeResultatRecherche.page,
            page: pageDemandee,
            libelle: 'Page $pageDemandee',
          ),
        );
      }
      return resultats;
    }

    final int? nombre = int.tryParse(propre);
    if (nombre != null) {
      // Un nombre nu est ambigu : « 18 » peut vouloir dire la sourate 18 ou la
      // page 18. On propose les deux plutot que de choisir a la place du
      // lecteur, dans l'ordre ou il les cherche le plus souvent.
      if (nombre >= 1 && nombre <= 114) {
        final int? page = await pageDeDebutDeSourate(nombre);
        final List<SourateVM> toutes = await sourates();
        final SourateVM? sourate = _sourateParNumero(toutes, nombre);
        if (page != null && sourate != null) {
          resultats.add(
            ResultatRechercheCoran(
              type: TypeResultatRecherche.sourate,
              page: page,
              libelle: '${sourate.numero}. ${sourate.nomTranslittere}',
              sourate: sourate.numero,
            ),
          );
        }
      }
      if (nombre >= 1 && nombre <= pagesMushafMedine) {
        resultats.add(
          ResultatRechercheCoran(
            type: TypeResultatRecherche.page,
            page: nombre,
            libelle: 'Page $nombre',
          ),
        );
      }
      return resultats;
    }

    // Reste le nom d'une sourate. Au dela, il faudrait un index texte, qui
    // n'existe pas : l'ecran le dit, il ne rend pas une liste vide muette.
    final String cle = normaliser(propre);
    if (cle.isEmpty) {
      return const <ResultatRechercheCoran>[];
    }
    final List<SourateVM> toutes = await sourates();
    for (final SourateVM s in toutes) {
      if (!normaliser(s.nomTranslittere).contains(cle)) {
        continue;
      }
      final int? page = await pageDeDebutDeSourate(s.numero);
      if (page == null) {
        continue;
      }
      resultats.add(
        ResultatRechercheCoran(
          type: TypeResultatRecherche.sourate,
          page: page,
          libelle: '${s.numero}. ${s.nomTranslittere}',
          sourate: s.numero,
        ),
      );
      if (resultats.length >= _maxResultats) {
        break;
      }
    }
    return resultats;
  }

  /// Au dela, la liste cesse d'aider et devient une seconde navigation.
  static const int _maxResultats = 12;

  static SourateVM? _sourateParNumero(List<SourateVM> toutes, int numero) {
    for (final SourateVM s in toutes) {
      if (s.numero == numero) {
        return s;
      }
    }
    return null;
  }

  static PageCorpus _convertir(PageCoran page) => PageCorpus(
    numero: page.numero,
    juzNumero: page.juzNumero,
    versets: page.versets
        .map(
          (VersetCoran v) => VersetCorpus(
            sourate: v.sourateNumero,
            numero: v.numero,
            texte: v.texte,
            pageNumero: v.pageNumero,
          ),
        )
        .toList(growable: false),
  );

  /// Lit une reference « 2:255 », « 2 255 » ou « 2.255 ».
  ///
  /// Publique parce qu'elle se teste seule : c'est la seule partie de la
  /// recherche qui n'a besoin ni de reseau ni de corpus.
  static ({int sourate, int ayah})? lireReference(String requete) {
    final RegExpMatch? m = _reference.firstMatch(requete.trim());
    if (m == null) {
      return null;
    }
    final int? sourate = int.tryParse(m.group(1) ?? '');
    final int? ayah = int.tryParse(m.group(2) ?? '');
    if (sourate == null || ayah == null) {
      return null;
    }
    if (sourate < 1 || sourate > 114 || ayah < 1) {
      return null;
    }
    return (sourate: sourate, ayah: ayah);
  }

  /// Lit « page 300 » ou « juz 5 », dans les deux ordres.
  static int? lireNombreApresMot(String requete, String mot) {
    final String cle = normaliser(requete);
    final String motNormalise = normaliser(mot);
    if (!cle.contains(motNormalise)) {
      return null;
    }
    final RegExpMatch? m = _premierNombre.firstMatch(cle);
    return m == null ? null : int.tryParse(m.group(1) ?? '');
  }

  /// Reduit une chaine a ses lettres et ses chiffres.
  ///
  /// Les noms translitteres du corpus viennent de `quran-data.xml` (Tanzil) et
  /// n'emploient que l'alphabet latin sans accent, des tirets et des
  /// apostrophes : retirer la ponctuation suffit, et une table d'accents
  /// n'aurait rien a faire. « al-faatiha », « Al Faatiha » et « ALFAATIHA »
  /// donnent donc la meme cle.
  static String normaliser(String valeur) =>
      valeur.toLowerCase().replaceAll(_nonAlphanumerique, '');

  static final RegExp _reference = RegExp(r'^(\d{1,3})\s*[:.\s]\s*(\d{1,3})$');
  static final RegExp _premierNombre = RegExp(r'(\d{1,3})');
  static final RegExp _nonAlphanumerique = RegExp('[^a-z0-9]');
}

/// L'acces au corpus employe par le moteur Coran.
final Provider<PortCorpusCoran> portCorpusCoranProvider =
    Provider<PortCorpusCoran>(
      (Ref ref) => CorpusDepuisServiceCoran(ref.watch(serviceCoranProvider)),
    );
