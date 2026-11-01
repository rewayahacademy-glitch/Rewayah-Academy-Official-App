import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

import '../widgets/skeleton.dart';
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

/// Le formulaire de Stripe, monte dans un element de la page.
class FormulaireStripe extends StatefulWidget {
  /// Cree le formulaire.
  const FormulaireStripe({
    required this.formulaire,
    required this.onTermine,
    required this.onEchec,
    super.key,
  });

  /// La session a payer.
  final FormulairePaiement formulaire;

  /// Le paiement est passe dans le formulaire : la page relit l'etat.
  final VoidCallback onTermine;

  /// Le formulaire n'a pas pu se monter.
  final VoidCallback onEchec;

  @override
  State<FormulaireStripe> createState() => _FormulaireStripeState();
}

class _FormulaireStripeState extends State<FormulaireStripe> {
  JSObject? _checkout;
  bool _monte = false;
  bool _ferme = false;

  Future<void> _monter(Object element) async {
    final JSObject conteneur = element as JSObject;
    (conteneur['style']! as JSObject)
      ..['overflowY'] = 'auto'.toJS
      ..['width'] = '100%'.toJS
      ..['height'] = '100%'.toJS;
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
          if (!_ferme) widget.onTermine();
        }).toJS;
      final JSObject checkout = await stripe
          .callMethod<JSPromise<JSObject>>(methode.toJS, options)
          .toDart;
      if (_ferme) {
        checkout.callMethod<JSAny?>('destroy'.toJS);
        return;
      }
      _checkout = checkout;
      checkout.callMethod<JSAny?>('mount'.toJS, conteneur);
      if (mounted) setState(() => _monte = true);
    } on Object {
      if (!_ferme) widget.onEchec();
    }
  }

  @override
  void dispose() {
    _ferme = true;
    // Stripe n'admet qu'un formulaire a la fois : il se detruit avec l'ecran.
    _checkout?.callMethod<JSAny?>('destroy'.toJS);
    _checkout = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le formulaire defile dans son propre cadre, haut d'au moins une carte
    // et d'au plus l'ecran.
    final double hauteur = (MediaQuery.sizeOf(context).height * 0.75).clamp(
      460,
      820,
    );
    return SizedBox(
      height: hauteur,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: HtmlElementView.fromTagName(
              tagName: 'div',
              onElementCreated: _monter,
            ),
          ),
          if (!_monte) const Skeleton.liste(),
        ],
      ),
    );
  }
}
