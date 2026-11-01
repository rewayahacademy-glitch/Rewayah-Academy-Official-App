import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import 'formulaire_paiement.dart';

/// Stripe.js, version alignee sur l'API du serveur (`npm:stripe@22.6.2`,
/// `2026-08-26.dahlia`). Stripe exige qu'il soit charge depuis js.stripe.com,
/// jamais copie ni empaquete (conformite PCI).
const String _scriptStripe = 'https://js.stripe.com/dahlia/stripe.js';

/// Le delai au-dela duquel Stripe.js est tenu pour injoignable.
const Duration _delaiChargement = Duration(seconds: 20);

Future<void>? _chargement;

/// Charge Stripe.js une seule fois ; un echec se retente au prochain appel.
Future<void> _chargerStripe() {
  if (globalContext.has('Stripe')) return Future<void>.value();
  return _chargement ??= _injecter().catchError((Object e, StackTrace pile) {
    _chargement = null;
    Error.throwWithStackTrace(e, pile);
  });
}

Future<void> _injecter() {
  final Completer<void> fini = Completer<void>();
  final JSObject document = globalContext['document']! as JSObject;
  final JSObject script =
      document.callMethod<JSObject>('createElement'.toJS, 'script'.toJS)
        ..['src'] = _scriptStripe.toJS
        ..['async'] = true.toJS;
  script
    ..callMethod<JSAny?>(
      'addEventListener'.toJS,
      'load'.toJS,
      ((JSAny _) {
        if (!fini.isCompleted) fini.complete();
      }).toJS,
    )
    ..callMethod<JSAny?>(
      'addEventListener'.toJS,
      'error'.toJS,
      ((JSAny _) {
        if (!fini.isCompleted) {
          fini.completeError(StateError('Stripe.js injoignable'));
        }
      }).toJS,
    );
  (document['head']! as JSObject).callMethod<JSAny?>(
    'appendChild'.toJS,
    script,
  );
  return fini.future.timeout(_delaiChargement);
}

/// Le formulaire de Stripe, dans une page de l'application qui defile
/// d'elle-meme.
///
/// Pourquoi une page du navigateur et non un cadre dans l'arbre Flutter : le
/// moteur de Flutter ne recoit ni la molette ni le doigt poses sur le cadre
/// de Stripe ; un formulaire plus haut que l'ecran y laissait le bouton de
/// paiement hors d'atteinte (banc E2E du 01/11/2026). Ici, la page de
/// paiement est un element natif plein ecran dont le defilement est celui de
/// la page : une seule barre, celle de la page (DECISION-DEFILEMENT-2026-11-01),
/// la meme adresse, sans quitter l'application. Le retour du navigateur ferme
/// l'ecran, donc cette page.
class FormulaireStripe extends StatefulWidget {
  /// Cree le formulaire.
  const FormulaireStripe({
    required this.formulaire,
    required this.onTermine,
    required this.onEchec,
    required this.onRevenir,
    required this.titre,
    required this.phrase,
    required this.libelleRetour,
    super.key,
  });

  /// La session a payer.
  final FormulairePaiement formulaire;

  /// Le paiement est passe dans le formulaire : la page relit l'etat.
  final VoidCallback onTermine;

  /// Le formulaire n'a pas pu se monter.
  final VoidCallback onEchec;

  /// Revenir aux soldes sans payer.
  final VoidCallback onRevenir;

  /// Le titre, la phrase et la sortie, deja traduits.
  final String titre;
  final String phrase;
  final String libelleRetour;

  @override
  State<FormulaireStripe> createState() => _FormulaireStripeState();
}

class _FormulaireStripeState extends State<FormulaireStripe> {
  JSObject? _checkout;
  JSObject? _page;
  bool _ferme = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) unawaited(_ouvrir());
    });
  }

  static String _css(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Future<void> _ouvrir() async {
    final ColorScheme couleurs = Theme.of(context).colorScheme;
    final bool droiteAGauche = Directionality.of(context) == TextDirection.rtl;
    final JSObject document = globalContext['document']! as JSObject;
    JSObject element(String balise, String style, [String? texte]) {
      final JSObject e = document.callMethod<JSObject>(
        'createElement'.toJS,
        balise.toJS,
      );
      (e['style']! as JSObject)['cssText'] = style.toJS;
      if (texte != null) e['textContent'] = texte.toJS;
      return e;
    }

    final JSObject page = element(
      'div',
      'position:fixed;inset:0;z-index:2147483000;overflow-y:auto;'
          '-webkit-overflow-scrolling:touch;overscroll-behavior:contain;'
          'background:${_css(couleurs.surface)};'
          'color:${_css(couleurs.onSurface)};'
          'font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;',
    );
    page
      ..callMethod<JSAny?>('setAttribute'.toJS, 'role'.toJS, 'dialog'.toJS)
      ..callMethod<JSAny?>('setAttribute'.toJS, 'aria-modal'.toJS, 'true'.toJS)
      ..callMethod<JSAny?>(
        'setAttribute'.toJS,
        'aria-label'.toJS,
        widget.titre.toJS,
      )
      ..callMethod<JSAny?>(
        'setAttribute'.toJS,
        'dir'.toJS,
        (droiteAGauche ? 'rtl' : 'ltr').toJS,
      );
    final JSObject colonne = element(
      'div',
      'max-width:640px;margin:0 auto;box-sizing:border-box;'
          'padding:max(24px,env(safe-area-inset-top)) '
          'max(16px,env(safe-area-inset-right)) '
          'max(32px,env(safe-area-inset-bottom)) '
          'max(16px,env(safe-area-inset-left));',
    );
    final JSObject titre = element(
      'h1',
      'font-size:20px;font-weight:600;line-height:1.3;margin:0 0 8px;',
      widget.titre,
    )..['tabIndex'] = (-1).toJS;
    final JSObject phrase = element(
      'p',
      'font-size:15px;line-height:1.5;margin:0 0 20px;'
          'color:${_css(couleurs.onSurfaceVariant)};',
      widget.phrase,
    );
    final JSObject zone = element('div', 'min-height:320px;');
    final JSObject retour = element(
      'button',
      'display:block;margin-block-start:24px;margin-inline-start:auto;'
          'min-height:48px;padding:12px 0;background:none;border:0;'
          'font:inherit;font-size:15px;font-weight:600;cursor:pointer;'
          'color:${_css(couleurs.primary)};',
      widget.libelleRetour,
    )..['type'] = 'button'.toJS;
    retour.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'click'.toJS,
      ((JSAny _) {
        if (!_ferme) widget.onRevenir();
      }).toJS,
    );
    for (final JSObject e in <JSObject>[titre, phrase, zone, retour]) {
      colonne.callMethod<JSAny?>('appendChild'.toJS, e);
    }
    page.callMethod<JSAny?>('appendChild'.toJS, colonne);
    (document['body']! as JSObject).callMethod<JSAny?>(
      'appendChild'.toJS,
      page,
    );
    _page = page;
    titre.callMethod<JSAny?>('focus'.toJS);

    try {
      await _chargerStripe();
      if (_ferme) return;
      final JSObject stripe =
          (globalContext['Stripe']! as JSFunction).callAsFunction(
                null,
                widget.formulaire.clePublique.toJS,
              )!
              as JSObject;
      // `createEmbeddedCheckoutPage` depuis la version dahlia ;
      // `initEmbeddedCheckout` avant elle.
      final String methode = stripe.has('createEmbeddedCheckoutPage')
          ? 'createEmbeddedCheckoutPage'
          : 'initEmbeddedCheckout';
      final String secret = widget.formulaire.secretClient;
      final JSObject options = JSObject()
        ..['fetchClientSecret'] = (() => Future<JSString>.value(
          secret.toJS,
        ).toJS).toJS
        ..['onComplete'] = (() {
          if (_ferme) return;
          _fermerPage();
          widget.onTermine();
        }).toJS;
      final JSObject checkout = await stripe
          .callMethod<JSPromise<JSObject>>(methode.toJS, options)
          .toDart;
      if (_ferme) {
        checkout.callMethod<JSAny?>('destroy'.toJS);
        return;
      }
      _checkout = checkout;
      checkout.callMethod<JSAny?>('mount'.toJS, zone);
    } on Object {
      if (_ferme) return;
      _fermerPage();
      widget.onEchec();
    }
  }

  /// Stripe n'admet qu'un formulaire a la fois : il se detruit avec la page.
  void _fermerPage() {
    _checkout?.callMethod<JSAny?>('destroy'.toJS);
    _checkout = null;
    _page?.callMethod<JSAny?>('remove'.toJS);
    _page = null;
  }

  @override
  void dispose() {
    _ferme = true;
    _fermerPage();
    super.dispose();
  }

  // La page de paiement vit hors de l'arbre Flutter, au-dessus de lui.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
