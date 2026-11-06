import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import '../theme/app_gabarit.dart';
import 'formulaire_paiement.dart';

/// Stripe.js, version alignee sur l'API du serveur (`npm:stripe@22.6.2`,
/// `2026-08-26.dahlia`). Stripe exige qu'il soit charge depuis js.stripe.com,
/// jamais copie ni empaquete (conformite PCI).
const String _scriptStripe = 'https://js.stripe.com/dahlia/stripe.js';

/// Le delai au-dela duquel Stripe.js est tenu pour injoignable.
const Duration _delaiChargement = Duration(seconds: 20);

Future<void>? _chargement;

/// PAY-UX : charge Stripe.js en avance (ouverture de la recharge), sans
/// attendre ni rien dire ; le formulaire le retrouvera deja la. Un echec se
/// retente a l'ouverture du formulaire, qui le dit alors.
void prechargerStripe() {
  unawaited(_chargerStripe().then<void>((_) {}, onError: (Object _) {}));
}

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
///
/// WEB-BUREAU (c), repris par LINK-CHOIX (garde-cap, 06/11/2026) : la sortie
/// est en haut et reste visible quand la page defile, la touche Echap sort
/// aussi ; a partir de 1200 px, deux colonnes comme la connexion (le texte a
/// gauche, le formulaire a droite). La page couvre la zone de contenu de la
/// route, jamais la barre laterale du role (DEFINITION-PAGE-ORDINATEUR B1,
/// B9) : un clic dans la barre change de route et ferme la page.
///
/// LINK-CHOIX (directeur, 06/11/2026 : « donner le choix aux users ») : en
/// [FormeFormulaire.elements], les boutons de Link et des portefeuilles en
/// haut (Express Checkout Element), puis la carte (Payment Element) et le
/// bouton « Payer » ; aucune adresse n'est donnee a Stripe avant le paiement.
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
    required this.rassurance,
    required this.libellePayer,
    required this.libelleOuCarte,
    required this.libelleEnCours,
    required this.libelleRefus,
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

  /// PAY-UX : la ligne sous le formulaire (le paiement est traite par
  /// Stripe ; Rewayah ne voit ni ne garde le numero de carte), deja traduite.
  final String rassurance;

  /// LINK-CHOIX : le bouton de paiement par carte, la ligne entre les
  /// boutons et la carte, l'etat pendant le paiement et le refus, traduits.
  final String libellePayer;
  final String libelleOuCarte;
  final String libelleEnCours;
  final String libelleRefus;

  @override
  State<FormulaireStripe> createState() => _FormulaireStripeState();
}

class _FormulaireStripeState extends State<FormulaireStripe>
    with WidgetsBindingObserver {
  JSObject? _checkout;
  JSObject? _page;
  JSObject? _style;
  JSFunction? _echap;
  bool _ferme = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) unawaited(_ouvrir());
    });
  }

  static String _css(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static JSObject get _document => globalContext['document']! as JSObject;

  static JSObject _element(String balise, String style, [String? texte]) {
    final JSObject e = _document.callMethod<JSObject>(
      'createElement'.toJS,
      balise.toJS,
    );
    (e['style']! as JSObject)['cssText'] = style.toJS;
    if (texte != null) e['textContent'] = texte.toJS;
    return e;
  }

  static void _ajouter(JSObject parent, List<JSObject> enfants) {
    for (final JSObject e in enfants) {
      parent.callMethod<JSAny?>('appendChild'.toJS, e);
    }
  }

  static double _maintenant() => (globalContext['performance']! as JSObject)
      .callMethod<JSNumber>('now'.toJS)
      .toDartDouble;

  /// La zone de contenu de la route : celle du navigateur qui la porte (dans
  /// la coquille du role, la barre laterale reste a cote), en pixels CSS.
  String _cadre() {
    final RenderObject? boite = Navigator.maybeOf(context)?.context
        .findRenderObject();
    if (boite is! RenderBox || !boite.hasSize) return 'inset:0;';
    final Offset o = boite.localToGlobal(Offset.zero);
    return 'left:${o.dx}px;top:${o.dy}px;'
        'width:${boite.size.width}px;height:${boite.size.height}px;';
  }

  String _styleCadre(ColorScheme couleurs) =>
      'position:fixed;${_cadre()}z-index:2147483000;overflow-y:auto;'
      '-webkit-overflow-scrolling:touch;overscroll-behavior:contain;'
      'background:${_css(couleurs.surface)};'
      'color:${_css(couleurs.onSurface)};'
      'font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;';

  @override
  void didChangeMetrics() {
    // La fenetre change de taille : la page suit la zone de contenu.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final JSObject? page = _page;
      if (page == null || !mounted) return;
      (page['style']! as JSObject)['cssText'] = _styleCadre(
        couleursFormulairePaiement(),
      ).toJS;
    });
  }

  void _revenir() {
    if (!_ferme) widget.onRevenir();
  }

  Future<void> _ouvrir() async {
    final double debut = _maintenant();
    // PAY-UX : le fond clair du formulaire, dans tous les themes ; le
    // serveur a donne le meme fond au formulaire de Stripe (plus de cadre).
    final ColorScheme couleurs = couleursFormulairePaiement();
    final bool droiteAGauche = Directionality.of(context) == TextDirection.rtl;
    final bool elements = widget.formulaire.forme == FormeFormulaire.elements;
    final String langue = Localizations.localeOf(context).languageCode;

    // Les deux colonnes a partir de 1200 px : une regle de la page seule,
    // nommee pour ne rien toucher d'autre.
    final JSObject style = _element('style', '')
      ..['textContent'] =
          // Au telephone, une colonne : titre, phrase, formulaire, puis la
          // ligne rassurante sous le formulaire (PAY-UX).
          '.rwy-paiement-grille{display:grid;grid-template-columns:minmax(0,1fr);'
                  'max-width:640px;margin:0 auto;}'
                  '.rwy-paiement-texte{display:contents;}'
                  '.rwy-paiement-zone{order:2;margin-top:24px;}'
                  '.rwy-paiement-rassurance{order:3;}'
                  '@media (min-width:${AppGabarit.seuilDesktop.round()}px){'
                  '.rwy-paiement-grille{grid-template-columns:minmax(0,5fr) '
                  'minmax(0,7fr);gap:48px;max-width:1120px;align-items:start;}'
                  '.rwy-paiement-texte{display:block;position:sticky;top:96px;}'
                  '.rwy-paiement-zone{order:0;margin-top:0;}}'
                  '.rwy-paiement-retour:focus-visible,.rwy-paiement-payer:'
                  'focus-visible{outline:2px solid ${_css(couleurs.primary)};'
                  'outline-offset:2px;}'
                  '[dir=rtl] .rwy-paiement-fleche{transform:scaleX(-1);}'
              .toJS;
    (_document['head']! as JSObject).callMethod<JSAny?>(
      'appendChild'.toJS,
      style,
    );
    _style = style;

    final JSObject page = _element('div', _styleCadre(couleurs));
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

    // La sortie, en haut, collee au haut de la page quand elle defile.
    final JSObject barre = _element(
      'div',
      'position:sticky;top:0;z-index:1;'
          'background:${_css(couleurs.surface)};'
          'border-bottom:1px solid ${_css(couleurs.outlineVariant)};'
          'padding:max(8px,env(safe-area-inset-top)) '
          'max(16px,env(safe-area-inset-right)) 8px '
          'max(16px,env(safe-area-inset-left));',
    );
    final JSObject retour =
        _element(
            'button',
            'display:inline-flex;align-items:center;gap:8px;'
                'min-height:48px;padding:8px 12px;margin-inline-start:-12px;'
                'background:none;border:0;border-radius:12px;'
                'font:inherit;font-size:15px;font-weight:600;cursor:pointer;'
                'color:${_css(couleurs.primary)};',
          )
          ..['type'] = 'button'.toJS
          ..['className'] = 'rwy-paiement-retour'.toJS
          ..['innerHTML'] =
              '<svg class="rwy-paiement-fleche" aria-hidden="true" '
                      'width="20" height="20" viewBox="0 0 256 256" '
                      'fill="currentColor"><path d="M224 128a8 8 0 0 1-8 8H59.31'
                      'l58.35 58.34a8 8 0 0 1-11.32 11.32l-72-72a8 8 0 0 1 0-'
                      '11.32l72-72a8 8 0 0 1 11.32 11.32L59.31 120H216a8 8 0 '
                      '0 1 8 8Z"/></svg>'
                  .toJS;
    retour.callMethod<JSAny?>(
      'appendChild'.toJS,
      _element('span', '', widget.libelleRetour),
    );
    retour.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'click'.toJS,
      ((JSAny _) => _revenir()).toJS,
    );
    barre.callMethod<JSAny?>('appendChild'.toJS, retour);

    final JSObject corps = _element(
      'div',
      'box-sizing:border-box;'
          'padding:24px max(16px,env(safe-area-inset-right)) '
          'max(32px,env(safe-area-inset-bottom)) '
          'max(16px,env(safe-area-inset-left));',
    );
    final JSObject grille = _element('div', '')
      ..['className'] = 'rwy-paiement-grille'.toJS;
    final JSObject texte = _element('div', '')
      ..['className'] = 'rwy-paiement-texte'.toJS;
    final JSObject titre = _element(
      'h1',
      'font-size:20px;font-weight:600;line-height:1.3;margin:0 0 8px;',
      widget.titre,
    )..['tabIndex'] = (-1).toJS;
    final JSObject phrase = _element(
      'p',
      'font-size:15px;line-height:1.5;margin:0;'
          'color:${_css(couleurs.onSurfaceVariant)};',
      widget.phrase,
    );
    final JSObject rassurance =
        _element(
            'p',
            'font-size:14px;line-height:1.5;margin:16px 0 0;'
                'color:${_css(couleurs.onSurfaceVariant)};',
            widget.rassurance,
          )
          ..['id'] = 'paiement-rassurance'.toJS
          ..['className'] = 'rwy-paiement-rassurance'.toJS;
    _ajouter(texte, <JSObject>[titre, phrase, rassurance]);

    final JSObject zone = _element('div', 'min-height:320px;')
      ..['className'] = 'rwy-paiement-zone'.toJS;
    _ajouter(grille, <JSObject>[texte, zone]);
    corps.callMethod<JSAny?>('appendChild'.toJS, grille);
    _ajouter(page, <JSObject>[barre, corps]);
    (_document['body']! as JSObject).callMethod<JSAny?>(
      'appendChild'.toJS,
      page,
    );
    _page = page;

    final JSFunction echap = ((JSObject e) {
      if ((e['key'] as JSString?)?.toDart == 'Escape') _revenir();
    }).toJS;
    _document.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'keydown'.toJS,
      echap,
    );
    _echap = echap;
    titre.callMethod<JSAny?>('focus'.toJS);

    try {
      await _chargerStripe();
      if (_ferme) return;
      final JSFunction constructeur = globalContext['Stripe']! as JSFunction;
      if (elements) {
        final JSObject stripe =
            constructeur.callAsFunction(
                  null,
                  widget.formulaire.clePublique.toJS,
                  JSObject()..['locale'] = (langue == 'ar' ? 'ar' : 'fr').toJS,
                )!
                as JSObject;
        await _monterElements(stripe, zone, couleurs, page, debut);
      } else {
        final JSObject stripe =
            constructeur.callAsFunction(
                  null,
                  widget.formulaire.clePublique.toJS,
                )!
                as JSObject;
        await _monterIntegre(stripe, zone);
        _noterPret(page, debut);
      }
    } on Object {
      if (_ferme) return;
      _fermerPage();
      widget.onEchec();
    }
  }

  /// Le temps jusqu'au formulaire utilisable, lisible par le robot et dans
  /// la console du navigateur (consigne du garde-cap du 06/11 : le mesurer).
  void _noterPret(JSObject page, double debut) {
    if (_ferme) return;
    final int ms = (_maintenant() - debut).round();
    page.callMethod<JSAny?>(
      'setAttribute'.toJS,
      'data-pret-ms'.toJS,
      '$ms'.toJS,
    );
    (globalContext['console']! as JSObject).callMethod<JSAny?>(
      'info'.toJS,
      'paiement : formulaire utilisable en $ms ms'.toJS,
    );
  }

  Future<void> _monterIntegre(JSObject stripe, JSObject zone) async {
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
  }

  /// LINK-CHOIX : les boutons (Link, portefeuilles), puis la carte et
  /// « Payer ». Les deux chemins confirment la meme session ; Stripe n'en
  /// laisse passer qu'un.
  Future<void> _monterElements(
    JSObject stripe,
    JSObject zone,
    ColorScheme couleurs,
    JSObject page,
    double debut,
  ) async {
    final JSObject apparence = JSObject()
      ..['theme'] = 'stripe'.toJS
      ..['variables'] = (JSObject()
        ..['colorPrimary'] = _css(couleurs.primary).toJS
        ..['colorBackground'] = _css(couleurs.surface).toJS
        ..['colorText'] = _css(couleurs.onSurface).toJS
        ..['colorDanger'] = _css(couleurs.error).toJS
        ..['fontFamily'] =
            'system-ui,-apple-system,"Segoe UI",Roboto,sans-serif'.toJS
        ..['borderRadius'] = '12px'.toJS);
    final JSObject checkout = stripe.callMethod<JSObject>(
      'initCheckoutElementsSdk'.toJS,
      JSObject()
        ..['clientSecret'] = widget.formulaire.secretClient.toJS
        ..['elementsOptions'] = (JSObject()..['appearance'] = apparence),
    );
    if (_ferme) return;
    _checkout = checkout;

    final JSObject rapide = _element('div', '');
    final JSObject separateur = _element(
      'p',
      'display:none;font-size:14px;line-height:1.5;margin:16px 0;'
          'text-align:center;color:${_css(couleurs.onSurfaceVariant)};',
      widget.libelleOuCarte,
    );
    final JSObject carte = _element('div', '');
    final JSObject erreur = _element(
      'p',
      'display:none;font-size:14px;line-height:1.5;margin:16px 0 0;'
          'color:${_css(couleurs.error)};',
    )..callMethod<JSAny?>('setAttribute'.toJS, 'role'.toJS, 'alert'.toJS);
    final JSObject payer =
        _element(
            'button',
            'display:block;width:100%;min-height:48px;margin-top:24px;'
                'padding:12px 24px;border:0;border-radius:12px;'
                'font:inherit;font-size:16px;font-weight:600;cursor:pointer;'
                'text-align:center;'
                'background:${_css(couleurs.primary)};'
                'color:${_css(couleurs.onPrimary)};',
            widget.libellePayer,
          )
          ..['type'] = 'button'.toJS
          ..['className'] = 'rwy-paiement-payer'.toJS;
    _ajouter(zone, <JSObject>[rapide, separateur, carte, erreur, payer]);

    final JSObject elementRapide = checkout.callMethod<JSObject>(
      'createExpressCheckoutElement'.toJS,
    );
    elementRapide.callMethod<JSAny?>(
      'on'.toJS,
      'ready'.toJS,
      ((JSObject e) {
        // Le separateur seulement si un bouton s'affiche vraiment.
        final JSAny? dispo = e['availablePaymentMethods'];
        final bool aucun =
            dispo == null ||
            (globalContext['Object']! as JSObject)
                .callMethod<JSArray<JSAny?>>('values'.toJS, dispo)
                .toDart
                .every(
                  (JSAny? v) =>
                      v.isUndefinedOrNull ||
                      (v.isA<JSBoolean>() && !(v! as JSBoolean).toDart),
                );
        (separateur['style']! as JSObject)['display'] =
            (aucun ? 'none' : 'block').toJS;
      }).toJS,
    );
    elementRapide.callMethod<JSAny?>(
      'on'.toJS,
      'confirm'.toJS,
      ((JSObject evenement) {
        unawaited(
          _confirmer(
            checkout,
            JSObject()..['expressCheckoutConfirmEvent'] = evenement,
            erreur,
            payer,
          ),
        );
      }).toJS,
    );
    elementRapide.callMethod<JSAny?>('mount'.toJS, rapide);

    final JSObject elementCarte = checkout.callMethod<JSObject>(
      'createPaymentElement'.toJS,
    );
    elementCarte.callMethod<JSAny?>(
      'on'.toJS,
      'ready'.toJS,
      ((JSAny _) => _noterPret(page, debut)).toJS,
    );
    elementCarte.callMethod<JSAny?>('mount'.toJS, carte);

    payer.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'click'.toJS,
      ((JSAny _) {
        final String? email = widget.formulaire.email;
        unawaited(
          _confirmer(
            checkout,
            JSObject()
              ..['redirect'] = 'if_required'.toJS
              ..['email'] = email?.toJS,
            erreur,
            payer,
          ),
        );
      }).toJS,
    );
  }

  bool _enCours = false;

  Future<void> _confirmer(
    JSObject checkout,
    JSObject options,
    JSObject erreur,
    JSObject payer,
  ) async {
    if (_enCours || _ferme) return;
    _enCours = true;
    (erreur['style']! as JSObject)['display'] = 'none'.toJS;
    payer
      ..['textContent'] = widget.libelleEnCours.toJS
      ..callMethod<JSAny?>('setAttribute'.toJS, 'aria-busy'.toJS, 'true'.toJS);
    try {
      options['redirect'] ??= 'if_required'.toJS;
      if (options['email'].isUndefinedOrNull) options.delete('email'.toJS);
      final JSObject chargees = await checkout
          .callMethod<JSPromise<JSObject>>('loadActions'.toJS)
          .toDart;
      final JSObject actions = chargees['actions']! as JSObject;
      final JSObject resultat = await actions
          .callMethod<JSPromise<JSObject>>('confirm'.toJS, options)
          .toDart;
      if (_ferme) return;
      if ((resultat['type'] as JSString?)?.toDart == 'success') {
        _fermerPage();
        widget.onTermine();
        return;
      }
      final String? message =
          ((resultat['error'] as JSObject?)?['message'] as JSString?)?.toDart;
      _montrerRefus(erreur, message);
    } on Object {
      if (!_ferme) _montrerRefus(erreur, null);
    } finally {
      _enCours = false;
      if (!_ferme) {
        payer
          ..['textContent'] = widget.libellePayer.toJS
          ..callMethod<JSAny?>('removeAttribute'.toJS, 'aria-busy'.toJS);
      }
    }
  }

  /// Le message de Stripe (deja dans la langue de la page), sinon le notre.
  void _montrerRefus(JSObject erreur, String? message) {
    erreur['textContent'] =
        ((message == null || message.isEmpty) ? widget.libelleRefus : message)
            .toJS;
    (erreur['style']! as JSObject)['display'] = 'block'.toJS;
  }

  /// Stripe n'admet qu'un formulaire a la fois : il se detruit avec la page.
  void _fermerPage() {
    final JSObject? checkout = _checkout;
    if (checkout != null && checkout.has('destroy')) {
      checkout.callMethod<JSAny?>('destroy'.toJS);
    }
    _checkout = null;
    _page?.callMethod<JSAny?>('remove'.toJS);
    _page = null;
    _style?.callMethod<JSAny?>('remove'.toJS);
    _style = null;
    final JSFunction? echap = _echap;
    if (echap != null) {
      _document.callMethod<JSAny?>(
        'removeEventListener'.toJS,
        'keydown'.toJS,
        echap,
      );
    }
    _echap = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ferme = true;
    _fermerPage();
    super.dispose();
  }

  // La page de paiement vit hors de l'arbre Flutter, au-dessus de lui.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
