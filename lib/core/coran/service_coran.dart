import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le code de l'edition de reference, pose par la migration `0007`.
///
/// **Un code, jamais un uuid en dur.** L'identifiant de la ligne `mushaf` est
/// genere par la base, donc different sur chaque environnement : une constante
/// uuid marcherait en production et nulle part ailleurs.
const String codeMushafReference = 'madina-hafs-604';

/// Le nombre de pages du Mushaf de Medine.
///
/// Il est aussi en base, dans `mushaf.nombre_pages`, et c'est cette valeur-la
/// qui fait foi a l'ecran : celle-ci ne sert qu'a borner une navigation avant
/// que l'edition ne soit chargee.
const int pagesMushafMedine = 604;

/// Une sourate, telle que la table `sourate` l'expose.
@immutable
class Sourate {
  /// Cree une sourate.
  const Sourate({
    required this.numero,
    required this.nomArabe,
    required this.nomTranslittere,
    required this.lieuRevelation,
    required this.nombreVersets,
  });

  /// Lit une ligne de `sourate`.
  factory Sourate.depuisJson(Map<String, dynamic> json) => Sourate(
    numero: json['numero'] as int? ?? 0,
    nomArabe: json['nom_arabe'] as String? ?? '',
    nomTranslittere: json['nom_translittere'] as String? ?? '',
    lieuRevelation: json['lieu_revelation'] as String? ?? '',
    nombreVersets: json['nombre_versets'] as int? ?? 0,
  );

  /// Son rang, de 1 a 114.
  final int numero;

  /// Son nom en arabe.
  final String nomArabe;

  /// Son nom translittere, pour un lecteur qui ne lit pas encore l'arabe.
  final String nomTranslittere;

  /// `mecque` ou `medine`.
  final String lieuRevelation;

  /// Le nombre de versets qu'elle compte.
  final int nombreVersets;

  /// Vrai pour une sourate revelee a La Mecque.
  bool get mecquoise => lieuRevelation == 'mecque';
}

/// Un verset, tel que la table `verset` l'expose.
///
/// **Aucun champ ne porte d'identifiant de fichier**, et c'est l'invariant J6
/// de l'etape 5 : le Coran n'est pas un PDF pagine, c'est un contenu structure
/// adressable au verset. Le jour ou le rendu passerait aux glyphes d'une
/// edition, il gagnerait une colonne de plus ici -- pas un chemin de fichier.
@immutable
class VersetCoran {
  /// Cree un verset.
  const VersetCoran({
    required this.sourateNumero,
    required this.numero,
    required this.texte,
    required this.pageNumero,
  });

  /// Lit une ligne de `verset`.
  factory VersetCoran.depuisJson(Map<String, dynamic> json) => VersetCoran(
    sourateNumero: json['sourate_numero'] as int? ?? 0,
    numero: json['numero'] as int? ?? 0,
    texte: json['texte'] as String? ?? '',
    pageNumero: json['page_numero'] as int? ?? 0,
  );

  /// La sourate a laquelle il appartient.
  final int sourateNumero;

  /// Son rang dans la sourate.
  final int numero;

  /// Le texte, tel quel. **Il ne se modifie jamais** : la licence du corpus
  /// l'interdit explicitement, et le bon sens avant elle.
  final String texte;

  /// La page du mushaf ou il commence.
  final int pageNumero;

  /// La reference courte, « 2:255 ».
  String get reference => '$sourateNumero:$numero';
}

/// Une page du mushaf : son numero, son juz, et les versets qui s'y trouvent.
@immutable
class PageCoran {
  /// Cree une page.
  const PageCoran({
    required this.numero,
    required this.versets,
    this.juzNumero,
  });

  /// Le numero de page, de 1 a 604.
  final int numero;

  /// Les versets de la page, dans l'ordre du texte.
  final List<VersetCoran> versets;

  /// Le juz auquel la page appartient, quand il est connu.
  final int? juzNumero;

  /// Les numeros de sourate presents sur la page, dans l'ordre.
  ///
  /// Une page en porte souvent une, parfois deux, et l'ecran doit alors poser
  /// un en-tete au bon endroit plutot qu'un seul titre en haut.
  List<int> get souratesPresentes {
    final List<int> vus = <int>[];
    for (final VersetCoran verset in versets) {
      if (vus.isEmpty || vus.last != verset.sourateNumero) {
        vus.add(verset.sourateNumero);
      }
    }
    return vus;
  }
}

/// La position de lecture personnelle d'un eleve.
///
/// **Elle n'appartient qu'a lui.** Aucune policy n'autorise un enseignant a
/// l'ecrire, et c'est l'invariant J2 : une page tournee par l'enseignant pour
/// toute la classe ne doit jamais ecraser silencieusement l'endroit ou l'eleve
/// en etait.
@immutable
class PositionLecture {
  /// Cree une position.
  const PositionLecture({
    required this.page,
    required this.sourate,
    required this.verset,
    this.zoom = 1,
    this.misAJourLe,
  });

  /// Lit une ligne de `student_reading_position`.
  factory PositionLecture.depuisJson(Map<String, dynamic> json) =>
      PositionLecture(
        page: json['page_mushaf'] as int? ?? 1,
        sourate: json['sourate'] as int? ?? 1,
        verset: json['verset'] as int? ?? 1,
        zoom: (json['zoom_level'] as num?)?.toDouble() ?? 1,
        misAJourLe: DateTime.tryParse(
          json['updated_at'] as String? ?? '',
        )?.toLocal(),
      );

  /// La page ou l'eleve en etait.
  final int page;

  /// La sourate ou il en etait.
  final int sourate;

  /// Le verset ou il en etait.
  final int verset;

  /// Le grossissement choisi pour le texte.
  ///
  /// **Une preference, pas un etat metier** : elle voyage avec la position
  /// parce que la base lui a reserve une colonne des `0007`, et parce qu'un
  /// lecteur qui grossit le texte sur son telephone veut le retrouver grossi.
  /// La base la borne entre 0,5 et 4 ; [zoomMin] et [zoomMax] disent la meme
  /// chose ici pour que l'ecran n'envoie jamais une valeur qu'elle refusera.
  final double zoom;

  /// Quand cette position a ete enregistree.
  final DateTime? misAJourLe;

  /// Grossissement minimal accepte par `student_reading_position`.
  static const double zoomMin = 0.5;

  /// Grossissement maximal accepte par `student_reading_position`.
  static const double zoomMax = 4;

  /// La meme position, ailleurs.
  PositionLecture versPage(int page, int sourate, int verset) =>
      PositionLecture(
        page: page,
        sourate: sourate,
        verset: verset,
        zoom: zoom,
        misAJourLe: misAJourLe,
      );

  /// La meme position, a un autre grossissement, borne comme la base le veut.
  PositionLecture avecZoom(double valeur) => PositionLecture(
    page: page,
    sourate: sourate,
    verset: verset,
    zoom: valeur.clamp(zoomMin, zoomMax),
    misAJourLe: misAJourLe,
  );
}

/// La lecture du corpus coranique et de la position personnelle.
abstract interface class ServiceCoran {
  /// L'identifiant de l'edition de reference, ou `null` si elle est absente.
  Future<String?> editionCourante();

  /// Les 114 sourates.
  ///
  /// Rend `null` quand la lecture echoue -- ce qui n'est pas une liste vide :
  /// une liste vide dirait « ce mushaf n'a aucune sourate », ce qui serait faux
  /// et affichable, alors que `null` dit « je ne sais pas » (meme regle que J3
  /// pour la presence).
  Future<List<Sourate>?> sourates();

  /// Une page du mushaf, versets compris.
  Future<PageCoran?> page(int numero);

  /// La page du mushaf ou se trouve un verset donne.
  ///
  /// **C'est la seule facon d'atteindre « 2:255 ».** Une page ne s'ouvre que par
  /// son numero, et rien dans le corpus ne le donnait a partir d'une reference :
  /// un enseignant qui voulait presenter un verset n'avait aucune API, et une
  /// conversion faite a l'ecran aurait demande de charger les 604 pages.
  ///
  /// La reponse se LIT dans `verset.page_numero`, la colonne que la migration
  /// `0007` a posee et que `0013` a remplie depuis Tanzil. Elle ne se calcule
  /// pas : la pagination appartient a une edition, et une formule la ferait
  /// mentir des le premier mushaf different.
  ///
  /// Rend `null` quand le verset n'existe pas ou que la lecture echoue -- « je
  /// ne sais pas », jamais « page 1 » : presenter la premiere page a une classe
  /// parce qu'une requete a echoue serait pire que ne rien presenter.
  Future<int?> pageDe(int sourate, int verset);

  /// La position de lecture de l'eleve, ou `null` s'il n'en a aucune.
  Future<PositionLecture?> position(String profilId);

  /// Enregistre la position de lecture de l'eleve.
  ///
  /// Rend `false` quand l'ecriture a echoue, et l'ecran n'en fait rien de
  /// visible : perdre un marque-page n'interrompt pas une lecture.
  Future<bool> enregistrerPosition(String profilId, PositionLecture position);

  /// Le verset ou commence un juz, ou `null` si le juz n'existe pas.
  ///
  /// Ajoute a la demande d'Agent C (`TC_CONTRACT_REQUEST_C.md` §4) : la table
  /// `public.juz` (migration `0007`) porte deja `sourate_depart` et
  /// `verset_depart` pour les trente juz, remplis par `0013`. Aucune donnee
  /// nouvelle n'est demandee, seulement une lecture.
  Future<({int sourate, int verset})?> debutDeJuz(int juz);

  /// Les versets dont le texte contient [requete].
  ///
  /// Rend `null` quand la lecture echoue, comme [sourates] : une liste vide
  /// dirait « ce mot n'est pas dans le Coran », ce qui serait faux.
  Future<List<VersetCoran>?> rechercher(String requete, {int limite = 50});
}

/// L'implementation reelle, au-dessus de PostgREST.
class ServiceCoranSupabase implements ServiceCoran {
  /// Cree le service.
  ServiceCoranSupabase(this._client);

  final SupabaseClient _client;

  /// L'edition, resolue une seule fois par session.
  ///
  /// La table n'a qu'une ligne et ne change jamais en cours d'usage : la
  /// relire a chaque tour de page ajouterait un aller-retour par page.
  String? _editionEnCache;

  @override
  Future<String?> editionCourante() async {
    if (_editionEnCache != null) {
      return _editionEnCache;
    }
    try {
      final Map<String, dynamic>? ligne = await _client
          .from('mushaf')
          .select('id')
          .eq('code', codeMushafReference)
          .isFilter('deleted_at', null)
          .maybeSingle();
      _editionEnCache = ligne?['id'] as String?;
      return _editionEnCache;
    } catch (erreur) {
      debugPrint('edition du mushaf indisponible : $erreur');
      return null;
    }
  }

  @override
  Future<List<Sourate>?> sourates() async {
    try {
      final List<Map<String, dynamic>> lignes = await _client
          .from('sourate')
          .select()
          .order('numero');
      return lignes.map(Sourate.depuisJson).toList();
    } catch (erreur) {
      debugPrint('sourates indisponibles : $erreur');
      return null;
    }
  }

  @override
  Future<PageCoran?> page(int numero) async {
    final String? edition = await editionCourante();
    if (edition == null) {
      return null;
    }
    try {
      final List<Map<String, dynamic>> lignes = await _client
          .from('verset')
          .select()
          .eq('mushaf_id', edition)
          .eq('page_numero', numero)
          .order('sourate_numero')
          .order('numero');
      final List<Map<String, dynamic>> pages = await _client
          .from('page_mushaf')
          .select('juz_numero')
          .eq('mushaf_id', edition)
          .eq('numero', numero)
          .limit(1);
      return PageCoran(
        numero: numero,
        versets: lignes.map(VersetCoran.depuisJson).toList(),
        juzNumero: pages.isEmpty ? null : pages.first['juz_numero'] as int?,
      );
    } catch (erreur) {
      debugPrint('page $numero indisponible : $erreur');
      return null;
    }
  }

  @override
  Future<int?> pageDe(int sourate, int verset) async {
    final String? edition = await editionCourante();
    if (edition == null) {
      return null;
    }
    try {
      // `maybeSingle` et non `limit(1)` : la contrainte `verset_unique` porte
      // exactement ce triplet, donc deux lignes signifieraient un corpus
      // corrompu -- et il vaut mieux le voir que l'arrondir a la premiere.
      final Map<String, dynamic>? ligne = await _client
          .from('verset')
          .select('page_numero')
          .eq('mushaf_id', edition)
          .eq('sourate_numero', sourate)
          .eq('numero', verset)
          .maybeSingle();
      return ligne?['page_numero'] as int?;
    } catch (erreur) {
      debugPrint('page de $sourate:$verset indisponible : $erreur');
      return null;
    }
  }

  @override
  Future<PositionLecture?> position(String profilId) async {
    final String? edition = await editionCourante();
    if (edition == null) {
      return null;
    }
    try {
      final Map<String, dynamic>? ligne = await _client
          .from('student_reading_position')
          .select()
          .eq('student_profile_id', profilId)
          .eq('mushaf_id', edition)
          .maybeSingle();
      return ligne == null ? null : PositionLecture.depuisJson(ligne);
    } catch (erreur) {
      debugPrint('position de lecture indisponible : $erreur');
      return null;
    }
  }

  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async {
    final String? edition = await editionCourante();
    if (edition == null) {
      return false;
    }
    try {
      await _client.from('student_reading_position').upsert(<String, dynamic>{
        'student_profile_id': profilId,
        'mushaf_id': edition,
        'page_mushaf': position.page,
        'sourate': position.sourate,
        'verset': position.verset,
        'zoom_level': position.zoom.clamp(
          PositionLecture.zoomMin,
          PositionLecture.zoomMax,
        ),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'student_profile_id,mushaf_id');
      return true;
    } catch (erreur) {
      // Perdre un marque-page n'interrompt pas une lecture : l'echec se tait a
      // l'ecran et se dit seulement au journal de developpement.
      debugPrint('position de lecture non enregistree : $erreur');
      return false;
    }
  }

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async {
    try {
      final Map<String, dynamic>? ligne = await _client
          .from('juz')
          .select('sourate_depart, verset_depart')
          .eq('numero', juz)
          .maybeSingle();
      if (ligne == null) {
        return null;
      }
      return (
        sourate: ligne['sourate_depart'] as int,
        verset: ligne['verset_depart'] as int,
      );
    } catch (erreur) {
      debugPrint('debut du juz $juz indisponible : $erreur');
      return null;
    }
  }

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async {
    final String? edition = await editionCourante();
    if (edition == null) {
      return null;
    }
    try {
      final List<Map<String, dynamic>> lignes = await _client
          .from('verset')
          .select()
          .eq('mushaf_id', edition)
          .ilike('texte', '%$requete%')
          .order('sourate_numero')
          .order('numero')
          .limit(limite);
      return lignes.map(VersetCoran.depuisJson).toList();
    } catch (erreur) {
      debugPrint('recherche "$requete" indisponible : $erreur');
      return null;
    }
  }
}

/// Le service de lecture employe par l'application.
final Provider<ServiceCoran> serviceCoranProvider = Provider<ServiceCoran>(
  (Ref ref) => ServiceCoranSupabase(Supabase.instance.client),
);

/// Les 114 sourates, chargees une fois.
final FutureProvider<List<Sourate>?> souratesProvider =
    FutureProvider<List<Sourate>?>(
      (Ref ref) => ref.watch(serviceCoranProvider).sourates(),
    );

/// Une page du mushaf.
///
/// **Une famille par numero de page, et rien de plus gourmand** : un lecteur
/// ouvre une page a la fois, et charger les 604 d'avance ferait transiter tout
/// le corpus pour lire une ligne.
final FutureProviderFamily<PageCoran?, int> pageCoranProvider =
    FutureProvider.family<PageCoran?, int>(
      (Ref ref, int numero) => ref.watch(serviceCoranProvider).page(numero),
    );

/// La page du mushaf ou se trouve une reference « sourate:verset ».
///
/// La cle de famille est un **enregistrement nomme** et non une classe : un
/// enregistrement compare ses champs tout seul, ce qu'une famille Riverpod
/// exige, et cela evite un modele de deux entiers dont personne d'autre
/// n'aurait besoin. Lecture : `ref.watch(pageDuVersetProvider((sourate: 2,
/// verset: 255)))`.
///
/// C'est par la que l'enseignant transforme « 2:255 » en page presentable, sans
/// jamais toucher a la position de lecture de qui que ce soit (invariant J2).
final FutureProviderFamily<int?, ({int sourate, int verset})>
pageDuVersetProvider = FutureProvider.family<int?, ({int sourate, int verset})>(
  (Ref ref, ({int sourate, int verset}) reference) => ref
      .watch(serviceCoranProvider)
      .pageDe(reference.sourate, reference.verset),
);
