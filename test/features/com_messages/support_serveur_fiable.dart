// PE-D1 MESSAGERIE-FIABLE : un faux serveur de messagerie qui garde ses
// messages, deduplique par cle d'envoi (comme `com_messages_idempotence`), lit
// par pages de 50 (comme `com_lire_fil_page`) et sait couper, perdre une
// reponse ou refuser. Donnees fictives seulement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/communications_supabase.dart'
    show cleServeur;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_messages/fil_en_place.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../../support/demo/communications/com_messages_demo.dart';
import '../../support/harnais.dart';
import 'support_messages.dart';

/// Ce que fait le faux serveur d'un appel d'envoi.
enum IssueEnvoi {
  /// Le message est enregistre et l'accuse revient.
  ok,

  /// Coupure avant le serveur : rien n'est enregistre.
  coupe,

  /// Le message est enregistre, mais la reponse se perd en route.
  coupeApres,

  /// Le serveur refuse : plus le droit d'ecrire.
  refus,
}

class ServeurFiable
    with SansImagesMessages
    implements PortMessagesMetier, PortPagesFil {
  ServeurFiable(this.demo);

  final MessagesMetierDemo demo;
  static const String filId = 'fil-adam';

  late final FilMetier _modele;
  late final Participant soi;
  late final Participant autre;
  final List<MessageCommunication> messages = <MessageCommunication>[];
  final List<String> clesRecues = <String>[];
  final List<IssueEnvoi> issues = <IssueEnvoi>[];
  int lecturesFil = 0;
  int pagesLues = 0;

  /// Quand il est pose, une page precedente ne revient qu'a sa completion.
  Completer<void>? pageSuspendue;

  /// Vrai : la lecture d'une page precedente echoue.
  bool pageEnEchec = false;

  /// Prepare le fil, avec [anciens] messages fictifs deja echanges.
  Future<void> preparer({
    int anciens = 0,
    AppLocale langue = AppLocale.fr,
  }) async {
    _modele = (await demo.fil(filId))!;
    soi = _modele.participants.firstWhere((Participant p) => p.estSoi);
    autre = _modele.participants.firstWhere((Participant p) => !p.estSoi);
    for (int i = 1; i <= anciens; i++) {
      messages.add(
        MessageCommunication(
          id: 'ancien-$i',
          auteur: i.isEven ? soi : autre,
          texte: langue == AppLocale.ar
              ? 'رسالة تجريبية $i'
              : 'Message fictif $i',
          envoyeLe: maintenantTest.subtract(Duration(minutes: 400 - i)),
          cleIdempotence: i.isEven ? 'cle-ancienne-$i' : null,
        ),
      );
    }
  }

  FilMetier _fil(List<MessageCommunication> page, bool plus) => FilMetier(
    id: _modele.id,
    contexte: _modele.contexte,
    participants: _modele.participants,
    messages: page,
    capacites: _modele.capacites,
    plusAnciens: plus,
  );

  @override
  Future<FilMetier?> fil(String id) async {
    lecturesFil++;
    final int debut = messages.length > PortPagesFil.taillePage
        ? messages.length - PortPagesFil.taillePage
        : 0;
    return _fil(messages.sublist(debut), debut > 0);
  }

  @override
  Future<PageMessagesFil> messagesAvant(
    String id,
    String avantId, {
    int limite = PortPagesFil.taillePage,
  }) async {
    pagesLues++;
    final Completer<void>? suspendue = pageSuspendue;
    if (suspendue != null) await suspendue.future;
    if (pageEnEchec) throw const EnvoiCoupe('page coupee');
    final int rang = messages.indexWhere(
      (MessageCommunication m) => m.id == avantId,
    );
    if (rang < 0) {
      return PageMessagesFil(
        messages: const <MessageCommunication>[],
        plusAnciens: false,
      );
    }
    final int debut = rang > limite ? rang - limite : 0;
    return PageMessagesFil(
      messages: messages.sublist(debut, rang),
      plusAnciens: debut > 0,
    );
  }

  @override
  Future<void> envoyer(String id, String texte, String cle) async {
    clesRecues.add(cle);
    final IssueEnvoi issue = issues.isEmpty
        ? IssueEnvoi.ok
        : issues.removeAt(0);
    if (issue == IssueEnvoi.coupe) throw const EnvoiCoupe('reseau coupe');
    if (issue == IssueEnvoi.refus) {
      throw EnvoiRefuse(t.com.messages.fil.refusFerme);
    }
    final String cleBase = cleServeur(cle);
    if (!messages.any(
      (MessageCommunication m) => m.cleIdempotence == cleBase,
    )) {
      messages.add(
        MessageCommunication(
          id: 'serveur-${messages.length + 1}',
          auteur: soi,
          texte: texte,
          envoyeLe: maintenantTest.add(Duration(seconds: messages.length)),
          cleIdempotence: cleBase,
        ),
      );
    }
    if (issue == IssueEnvoi.coupeApres) {
      throw const EnvoiCoupe('reponse perdue');
    }
  }

  @override
  Future<List<ResumeFil>> fils() => demo.fils();

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) =>
      demo.filPourObjet(type, objetId);

  @override
  Future<FilMetier?> ouvrirConversation(ConversationPossible c) =>
      demo.ouvrirConversation(c);

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) => demo.conversationsPourObjet(type, objetId);

  @override
  Future<void> marquerLu(String id) async {}
}

/// Monte le fil plein ecran (`FilEnPlace`, la page du telephone) sur [port].
Future<void> monterFilPleinEcran(
  WidgetTester tester, {
  required PortMessagesMetier port,
  Size taille = const Size(390, 844),
  AppLocale langue = AppLocale.fr,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portMessagesMetierProvider.overrideWithValue(port),
        capaciteEcrireOuverteTest,
      ],
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SafeArea(
              child: FilEnPlace(filId: ServeurFiable.filId, onReplier: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// La liste des messages du fil (pour la faire defiler).
Finder listeDesMessages() => find
    .descendant(
      of: find.byKey(FilDiscussion.cleMessages),
      matching: find.byType(Scrollable),
    )
    .first;
