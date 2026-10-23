import 'dart:js_interop';
import 'dart:typed_data';

import 'port_partage_offre.dart';

// L'API Web Share du navigateur (`navigator.share`, `navigator.canShare`),
// reduite a ce qui sert. `package:web` n'est qu'une dependance transitive du
// projet : on ne l'importe pas, comme `ouvreur_onglet_web.dart`.

/// `File`, le fichier que le menu de partage emporte.
@JS('File')
extension type _Fichier._(JSObject _) implements JSObject {
  external factory _Fichier(
    JSArray<JSAny> morceaux,
    String nom,
    _OptionsFichier options,
  );
}

/// Les options d'un `File` : son type MIME.
extension type _OptionsFichier._(JSObject _) implements JSObject {
  external factory _OptionsFichier({required String type});
}

/// `ShareData` : ce que `navigator.share` recoit. Une propriete absente n'est
/// pas posee (le navigateur refuse un `url` ou un `files` nul).
extension type _DonneesPartage._(JSObject _) implements JSObject {
  external factory _DonneesPartage({
    String? title,
    String? text,
    String? url,
    JSArray<_Fichier>? files,
  });
}

/// `navigator`, ses deux fonctions de partage lues comme des proprietes : un
/// navigateur qui n'en a pas rend `null`, au lieu de lever a l'appel.
@JS('navigator')
external _Navigateur get _navigateur;

extension type _Navigateur._(JSObject _) implements JSObject {
  external JSFunction? get share;
  external JSFunction? get canShare;
}

/// Le niveau de partage de ce navigateur, d'apres `canShare` : un fichier
/// d'abord, sinon du texte seulement, sinon rien.
NiveauPartage _niveauDuNavigateur() {
  try {
    final _Navigateur nav = _navigateur;
    final JSFunction? partage = nav.share;
    if (partage == null) {
      return NiveauPartage.aucun;
    }
    final JSFunction? peut = nav.canShare;
    if (peut == null) {
      // Un navigateur ancien qui partage mais ne sait pas dire quoi : du texte
      // seulement, le seul cas sur.
      return NiveauPartage.lien;
    }
    final _Fichier essai = _Fichier(
      <JSAny>[Uint8List(1).toJS].toJS,
      'carte.png',
      _OptionsFichier(type: 'image/png'),
    );
    final JSAny? fichier = peut.callAsFunction(
      nav,
      _DonneesPartage(files: <_Fichier>[essai].toJS),
    );
    return (fichier as JSBoolean?)?.toDart ?? false
        ? NiveauPartage.image
        : NiveauPartage.lien;
  } on Object {
    return NiveauPartage.aucun;
  }
}

/// Vrai quand l'erreur est la fermeture du menu par la personne
/// (`AbortError`, jamais une panne).
bool _estUneFermeture(Object erreur) =>
    erreur.toString().contains('AbortError');

/// Le menu de partage du navigateur.
class PartageNavigateur implements PortPartageOffre {
  /// Cree le port ; [niveau] est lu une fois, au premier acces.
  PartageNavigateur();

  @override
  late final NiveauPartage niveau = _niveauDuNavigateur();

  @override
  Future<IssuePartage> partager({
    required Uint8List png,
    required String nomFichier,
    required String titre,
    required String texte,
    required Uri lien,
  }) async {
    if (niveau == NiveauPartage.aucun) {
      throw const PartageImpossible();
    }
    try {
      final _Navigateur nav = _navigateur;
      final JSFunction? partage = nav.share;
      if (partage == null) {
        throw const PartageImpossible();
      }
      final _DonneesPartage donnees = niveau == NiveauPartage.image
          ? _DonneesPartage(
              title: titre,
              text: texte,
              url: lien.toString(),
              files: <_Fichier>[
                _Fichier(
                  <JSAny>[png.toJS].toJS,
                  nomFichier,
                  _OptionsFichier(type: 'image/png'),
                ),
              ].toJS,
            )
          : _DonneesPartage(title: titre, text: texte, url: lien.toString());
      // Appele dans le geste de la personne : aucun `await` avant lui.
      final JSAny? promesse = partage.callAsFunction(nav, donnees);
      await (promesse as JSPromise<JSAny?>).toDart;
      return IssuePartage.partage;
    } on PartageImpossible {
      rethrow;
    } on Object catch (erreur) {
      if (_estUneFermeture(erreur)) {
        return IssuePartage.annule;
      }
      throw const PartageImpossible();
    }
  }
}

/// Le port de cette plateforme.
PortPartageOffre partageAppareil() => PartageNavigateur();
