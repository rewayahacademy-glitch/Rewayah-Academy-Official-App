import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/schedule_option.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../support/harnais.dart';

void _ignore() {}

void main() {
  testWidgets('les primitives R1 tiennent aux largeurs de référence', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final largeur in <double>[360, 390, 768, 1024, 1440]) {
      tester.view.physicalSize = Size(largeur, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        hote(
          MediaQuery(
            data: MediaQueryData(
              size: Size(largeur, 900),
              textScaler: TextScaler.linear(largeur == 360 ? 2 : 1),
            ),
            child: const SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SettingRow(
                    title: 'Notifications de changement de planning',
                    description: 'Recevez les informations importantes',
                    icon: AppIcons.reglages,
                    onPress: _ignore,
                  ),
                  ScheduleOption(
                    day: 'Mardi',
                    hours: '17:00 - 17:45',
                    timeZone: 'Europe/Paris',
                    recurrence: 'Chaque semaine',
                    onSelected: _ignore,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'largeur $largeur');
    }
  });
}
