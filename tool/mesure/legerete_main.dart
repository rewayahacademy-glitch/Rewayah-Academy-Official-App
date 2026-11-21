// CHIFFRES-ACADEMIE : banc de mesure de legerete, pour un vrai navigateur.
//
//   flutter build web --release -t tool/mesure/legerete_main.dart
//   puis servir build/web et ouvrir index.html.
//
// La page est posee seule, avec des chiffres fictifs et sans serveur. Le banc
// compte les trames que Flutter dessine reellement (un rappel persistant de
// trame, qui n'en demande aucune) et ecrit le compte dans le titre de
// l'onglet : a 5 s (page posee), puis a 65 s. Page immobile, l'ecart doit
// rester a une ou deux trames (la relecture de la minute).
//
// Ce fichier n'est pas dans l'application : rien de `lib/` ne l'importe.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/port_chiffres_academie.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_chiffres/chiffres_academie_page.dart';
import 'package:rewayah_academy/features/demo/chiffres_academie_demo.dart';

int _trames = 0;
String _erreur = '';

void _titre(String texte) => unawaited(
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(label: '$texte$_erreur'),
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addPersistentFrameCallback((_) => _trames++);
  int? aCinq;
  Timer(const Duration(seconds: 5), () {
    aCinq = _trames;
    _titre('mesure page=chiffres t5=$aCinq');
  });
  Timer(const Duration(seconds: 65), () {
    _titre(
      'mesure page=chiffres t5=$aCinq t65=$_trames '
      'ecart60s=${_trames - (aCinq ?? 0)} FIN',
    );
  });
  // Une erreur du montage se lit dans le titre, pas dans une page blanche.
  FlutterError.onError = (FlutterErrorDetails d) =>
      _erreur = ' ERREUR ${d.exceptionAsString().split('\n').first}';
  PlatformDispatcher.instance.onError = (Object e, StackTrace _) {
    _erreur = ' ERREUR $e';
    return true;
  };
  runApp(
    ProviderScope(
      overrides: <Override>[
        portChiffresAcademieProvider.overrideWithValue(
          const ChiffresAcademieDemo(maintenant: DateTime.now),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: const ChiffresAcademiePage(),
        ),
      ),
    ),
  );
}
