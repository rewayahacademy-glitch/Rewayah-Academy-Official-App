// ANTI-ROBOT (03/11/2026) : le widget Turnstile monte dans la page web.
//
// Le script `challenges.cloudflare.com/turnstile/v0/api.js?render=explicit`
// est charge par web/index.html (aucun paquet nouveau : `dart:js_interop` et
// `dart:ui_web` du SDK). Le widget est en mode gere, `interaction-only` :
// invisible tant que Cloudflare ne demande rien ; quand il demande une
// interaction, la case apparait et l'ecran lui reserve sa place.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'anti_robot.dart';

/// Le delai au-dela duquel le script de Cloudflare est tenu pour injoignable.
const Duration _delaiScript = Duration(seconds: 15);

int _suivant = 0;

/// Le widget Turnstile, monte dans un element de la page.
class RenduTurnstile extends StatefulWidget {
  /// Cree le rendu.
  const RenduTurnstile({
    required this.cle,
    required this.langue,
    required this.controleur,
    required this.onVisible,
    super.key,
  });

  /// La cle publique du site.
  final String cle;

  /// La langue de l'ecran (`fr`, `ar`).
  final String langue;

  /// Le controleur qui recoit le jeton.
  final ControleurAntiRobot controleur;

  /// Appele quand Cloudflare demande une interaction (la case apparait).
  final ValueChanged<bool> onVisible;

  @override
  State<RenduTurnstile> createState() => _RenduTurnstileState();
}

class _RenduTurnstileState extends State<RenduTurnstile> {
  late final String _type = 'rewayah-turnstile-${_suivant++}';
  JSObject? _hote;
  JSAny? _widgetId;
  bool _monte = false;

  @override
  void initState() {
    super.initState();
    final JSObject document = globalContext['document']! as JSObject;
    final JSObject hote = document.callMethod<JSObject>(
      'createElement'.toJS,
      'div'.toJS,
    );
    (hote['style']! as JSObject)['cssText'] = 'width:100%;height:100%;display:flex;justify-content:center;align-items:center;'
        .toJS;
    _hote = hote;
    ui_web.platformViewRegistry.registerViewFactory(_type, (int _) => hote);
    widget.controleur.brancher(_relancer);
    unawaited(_monter());
  }

  @override
  void dispose() {
    widget.controleur.debrancher();
    final JSObject? turnstile = globalContext['turnstile'] as JSObject?;
    final JSAny? id = _widgetId;
    if (turnstile != null && id != null) {
      try {
        turnstile.callMethod<JSAny?>('remove'.toJS, id);
      } on Object {
        // Le widget est deja parti avec la page.
      }
    }
    super.dispose();
  }

  Future<JSObject?> _attendreScript() async {
    final DateTime limite = DateTime.now().add(_delaiScript);
    while (DateTime.now().isBefore(limite)) {
      final JSAny? turnstile = globalContext['turnstile'];
      if (turnstile != null) return turnstile as JSObject;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Future<void> _monter() async {
    final JSObject? turnstile = await _attendreScript();
    if (!mounted) return;
    if (turnstile == null) {
      // Le script ne s'est pas charge : le reseau, le plus souvent.
      widget.controleur.signalerErreur(horsLigne: true);
      return;
    }
    // L'element doit etre dans la page avant le rendu : la fin de l'image.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _monte) return;
    final JSObject options = JSObject()
      ..['sitekey'] = widget.cle.toJS
      ..['appearance'] = 'interaction-only'.toJS
      ..['language'] = widget.langue.toJS
      ..['theme'] = 'auto'.toJS
      ..['callback'] = ((JSString jeton) {
        widget.controleur.recevoirJeton(jeton.toDart);
      }).toJS
      ..['error-callback'] = (() {
        widget.controleur.signalerErreur();
      }).toJS
      ..['expired-callback'] = (() {
        widget.controleur.signalerExpiration();
        _relancer();
      }).toJS
      ..['before-interactive-callback'] = (() {
        widget.onVisible(true);
      }).toJS
      ..['after-interactive-callback'] = (() {
        widget.onVisible(false);
      }).toJS;
    try {
      _widgetId = turnstile.callMethod<JSAny?>('render'.toJS, _hote, options);
      _monte = true;
    } on Object {
      widget.controleur.signalerErreur();
    }
  }

  void _relancer() {
    final JSObject? turnstile = globalContext['turnstile'] as JSObject?;
    final JSAny? id = _widgetId;
    if (turnstile == null || id == null) {
      unawaited(_monter());
      return;
    }
    try {
      turnstile.callMethod<JSAny?>('reset'.toJS, id);
    } on Object {
      widget.controleur.signalerErreur();
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
