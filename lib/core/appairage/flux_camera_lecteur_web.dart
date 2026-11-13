import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../observabilite/journal_dev.dart';
import 'flux_camera_lecteur.dart';

@JS('Object.getOwnPropertyDescriptor')
external JSObject? _descripteurDe(JSObject cible, JSString nom);

@JS('Object.defineProperty')
external void _definir(JSObject cible, JSString nom, JSObject descripteur);

/// Dans un navigateur : l'ecoute de `HTMLMediaElement.prototype.srcObject`
/// pendant le demarrage du lecteur.
PriseFluxCamera priseFluxCameraDeLaPlateforme() => _PriseWeb();

/// Un flux retenu et l'element `<video>` qui le montre.
class _Retenu {
  const _Retenu(this.element, this.flux);

  final JSObject element;
  final JSObject flux;
}

class _PriseWeb implements PriseFluxCamera {
  static final JSString _srcObject = 'srcObject'.toJS;

  JSObject? _prototype;
  JSObject? _origine;
  int _fenetres = 0;
  final List<_Retenu> _captures = <_Retenu>[];

  @override
  void ouvrirCapture() {
    _fenetres++;
    if (_fenetres > 1) {
      return;
    }
    try {
      final JSObject? classe = globalContext.getProperty<JSObject?>(
        'HTMLMediaElement'.toJS,
      );
      final JSObject? prototype = classe?.getProperty<JSObject?>(
        'prototype'.toJS,
      );
      if (prototype == null) {
        return;
      }
      final JSObject? origine = _descripteurDe(prototype, _srcObject);
      final JSFunction? setOrigine = origine?.getProperty<JSFunction?>(
        'set'.toJS,
      );
      if (origine == null || setOrigine == null) {
        return;
      }
      final JSFunction ecoute = ((JSObject element, JSAny? valeur) {
        setOrigine.callAsFunction(element, valeur);
        _peutEtreRetenir(element, valeur);
      }).toJSCaptureThis;
      final JSObject descripteur = JSObject()
        ..setProperty('configurable'.toJS, true.toJS)
        ..setProperty(
          'enumerable'.toJS,
          origine.getProperty<JSAny?>('enumerable'.toJS),
        )
        ..setProperty('get'.toJS, origine.getProperty<JSAny?>('get'.toJS))
        ..setProperty('set'.toJS, ecoute);
      _definir(prototype, _srcObject, descripteur);
      _prototype = prototype;
      _origine = origine;
    } catch (e) {
      journalDev('camera du lecteur : ecoute impossible ($e)');
    }
  }

  /// Ne retient que l'element cree par `mobile_scanner` : style pose par
  /// `_createVideoElement` (`pointer-events: none`, `object-fit: cover`) et
  /// parent `<div>` en `object-fit: cover`. La visio de la salle n'a pas
  /// cette signature : elle n'est jamais retenue.
  void _peutEtreRetenir(JSObject element, JSAny? valeur) {
    if (valeur == null || !valeur.instanceOfString('MediaStream')) {
      return;
    }
    if (_signatureDuLecteur(element)) {
      _captures.add(_Retenu(element, valeur as JSObject));
    }
  }

  static bool _signatureDuLecteur(JSObject element) {
    final String? balise = element
        .getProperty<JSString?>('tagName'.toJS)
        ?.toDart;
    if (balise != 'VIDEO') {
      return false;
    }
    final JSObject? style = element.getProperty<JSObject?>('style'.toJS);
    if (_propriete(style, 'pointerEvents') != 'none' ||
        _propriete(style, 'objectFit') != 'cover') {
      return false;
    }
    final JSObject? parent = element.getProperty<JSObject?>(
      'parentElement'.toJS,
    );
    if (parent == null ||
        parent.getProperty<JSString?>('tagName'.toJS)?.toDart != 'DIV') {
      return false;
    }
    return _propriete(
          parent.getProperty<JSObject?>('style'.toJS),
          'objectFit',
        ) ==
        'cover';
  }

  static String? _propriete(JSObject? style, String nom) =>
      style?.getProperty<JSString?>(nom.toJS)?.toDart;

  @override
  List<Object> fermerCapture() {
    if (_fenetres > 0) {
      _fenetres--;
    }
    if (_fenetres == 0) {
      final JSObject? prototype = _prototype;
      final JSObject? origine = _origine;
      if (prototype != null && origine != null) {
        try {
          _definir(prototype, _srcObject, origine);
        } catch (e) {
          journalDev('camera du lecteur : remise en place imparfaite ($e)');
        }
      }
      _prototype = null;
      _origine = null;
    }
    final List<Object> rendus = List<Object>.of(_captures);
    _captures.clear();
    return rendus;
  }

  @override
  void fermer(Iterable<Object> flux) {
    for (final Object jeton in flux) {
      if (jeton is! _Retenu) {
        continue;
      }
      try {
        final JSArray<JSObject> pistes = jeton.flux
            .callMethod<JSArray<JSObject>>('getTracks'.toJS);
        for (final JSObject piste in pistes.toDart) {
          piste.callMethod<JSAny?>('stop'.toJS);
        }
        jeton.element.setProperty(_srcObject, null);
      } catch (e) {
        journalDev('camera du lecteur : fermeture imparfaite ($e)');
      }
    }
  }
}
