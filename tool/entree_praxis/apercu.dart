// ENTREE-PRAXIS : un apercu de la page d'entree, pour la comparer a la
// maquette « Praxis vous accueille » etat par etat. Outil de verification,
// hors de l'application : aucun serveur n'est contacte, l'adresse est un
// exemple. Parametres d'adresse : `etat` (arrivee, saisie, adresse, envoi,
// envoye, serveur, trop, horsLigne, session, sansInvitation, candidat),
// `theme` (clair, sombre), `langue` (fr, en, ar), `reduit=1`.
//
// Construire : flutter build web --release -t tool/entree_praxis/apercu.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/auth/anti_robot.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

const String _adresse = 'amina.b@exemple.com';

class _Auth implements ServiceAuth {
  _Auth(this.etat);
  final String etat;

  @override
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) {
    switch (etat) {
      case 'envoi':
        return Completer<void>().future;
      case 'serveur':
        throw const AuthException('panne', statusCode: '500');
      case 'trop':
        throw const AuthException('trop', statusCode: '429');
      case 'sansInvitation':
        throw const AuthException(
          'Signups not allowed for otp',
          code: 'otp_disabled',
        );
    }
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Reseau implements ServiceReseau {
  _Reseau(this.hors);
  final bool hors;
  @override
  Stream<bool> horsLigne() async* {
    yield false;
    if (hors) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      yield true;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> q = Uri.base.queryParameters;
  final String etat = q['etat'] ?? 'arrivee';
  await LocaleSettings.setLocaleRaw(q['langue'] ?? 'fr');
  if (etat == 'session') sessionTermineeParLeServeur.value = true;
  runApp(
    ProviderScope(
      overrides: <Override>[
        serviceAuthProvider.overrideWithValue(_Auth(etat)),
        serviceReseauProvider.overrideWithValue(_Reseau(etat == 'horsLigne')),
        cleTurnstileProvider.overrideWith((Ref ref) async => null),
      ],
      child: TranslationProvider(child: _Apercu(etat: etat, q: q)),
    ),
  );
}

class _Apercu extends StatefulWidget {
  const _Apercu({required this.etat, required this.q});
  final String etat;
  final Map<String, String> q;
  @override
  State<_Apercu> createState() => _ApercuState();
}

class _ApercuState extends State<_Apercu> {
  @override
  void initState() {
    super.initState();
    const Set<String> saisis = <String>{
      'saisie',
      'adresse',
      'envoi',
      'envoye',
      'serveur',
      'trop',
      'sansInvitation',
    };
    if (saisis.contains(widget.etat)) {
      Future<void>.delayed(const Duration(milliseconds: 400), _agir);
    }
  }

  Future<void> _agir() async {
    final String texte = widget.etat == 'adresse'
        ? _adresse.replaceAll('@', '.')
        : _adresse;
    EditableTextState? champ;
    void chercher(Element e) {
      if (champ != null) return;
      if (e is StatefulElement && e.state is EditableTextState) {
        champ = e.state as EditableTextState;
        return;
      }
      e.visitChildren(chercher);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(chercher);
    final EditableTextState? c = champ;
    if (c == null) return;
    final bool lent = widget.etat == 'saisie';
    for (int i = lent ? 1 : texte.length; i <= texte.length; i++) {
      c.userUpdateTextEditingValue(
        TextEditingValue(
          text: texte.substring(0, i),
          selection: TextSelection.collapsed(offset: i),
        ),
        SelectionChangedCause.keyboard,
      );
      if (lent) await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    if (lent) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    ActionPrincipale? bouton;
    void trouver(Element e) {
      final Widget w = e.widget;
      if (bouton == null &&
          w is ActionPrincipale &&
          w.niveau == NiveauAction.principale) {
        bouton = w;
        return;
      }
      e.visitChildren(trouver);
    }

    WidgetsBinding.instance.rootElement!.visitChildren(trouver);
    bouton?.onPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> q = widget.q;
    final bool rtl = (q['langue'] ?? 'fr') == 'ar';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: q['theme'] == 'sombre' ? ThemeMode.dark : ThemeMode.light,
      locale: TranslationProvider.of(context).flutterLocale,
      builder: (BuildContext context, Widget? enfant) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: q['reduit'] == '1'),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: enfant!,
        ),
      ),
      home: ConnexionPage(
        urlRetour: Uri.parse(
          widget.etat == 'candidat'
              ? 'https://exemple.test/connexion?mode=creer&candidature=1'
              : 'https://exemple.test/connexion',
        ),
      ),
    );
  }
}
