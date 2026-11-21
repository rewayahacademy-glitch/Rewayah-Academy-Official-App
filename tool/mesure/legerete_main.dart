// CHIFFRES-ACADEMIE : banc de mesure de legerete, pour un vrai navigateur.
//
//   flutter build web --release -t tool/mesure/legerete_main.dart
//   puis ouvrir build/web/index.html?page=chiffres (ou ?page=tableau).
//
// La page est posee seule, avec des chiffres fictifs et sans serveur. Le banc
// compte les trames que Flutter dessine reellement (un rappel persistant de
// trame, qui n'en demande aucune) et ecrit le compte dans le titre de
// l'onglet : a 5 s (page posee), puis a 65 s. Page immobile, l'ecart doit
// rester a une ou deux trames (la relecture de la minute). `?page=tableau`
// pose le tableau de bord de la direction en demonstration, pour comparer.
//
// Ce fichier n'est pas dans l'application : rien de `lib/` ne l'importe.
import 'dart:async';

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
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/demo/chiffres_academie_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

int _trames = 0;

void _titre(String texte) => unawaited(
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(label: texte),
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final bool tableau = Uri.base.queryParameters['page'] == 'tableau';
  SchedulerBinding.instance.addPersistentFrameCallback((_) => _trames++);
  int? aCinq;
  Timer(const Duration(seconds: 5), () {
    aCinq = _trames;
    _titre('mesure page=${tableau ? 'tableau' : 'chiffres'} t5=$aCinq');
  });
  Timer(const Duration(seconds: 65), () {
    _titre(
      'mesure page=${tableau ? 'tableau' : 'chiffres'} t5=$aCinq '
      't65=$_trames ecart60s=${_trames - (aCinq ?? 0)} FIN',
    );
  });
  runApp(
    ProviderScope(
      overrides: <Override>[
        if (tableau)
          ...surchargesDemoAdmin(environnement: 'staging')
        else
          portChiffresAcademieProvider.overrideWithValue(
            const ChiffresAcademieDemo(maintenant: DateTime.now),
          ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: tableau
              ? const TableauDeBordPage()
              : const ChiffresAcademiePage(),
        ),
      ),
    ),
  );
}
