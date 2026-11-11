// PROFILS P4 (pilote, 11/11/2026) : les lignes du Compte partage, posees
// dans `PageCompte`. Chaque ligne se lit sur une capacite servie, jamais sur
// un role, et **une ligne qui ne marche pas n'est pas fournie** (directeur,
// 11/11/2026, « 100 % operationnel ») : aucune ligne grisee, aucune valeur
// « Non disponible ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_support.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/push/reglages_push.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../notifications/reglages_push.dart';
import '../salle_seance/libelles_salle_b.dart';

/// Le serveur autorise-t-il les notifications sur cet appareil pour ce compte
/// (`serveur.autorise`, PUSH-1) ? Une capacite absente ou une lecture qui
/// echoue vaut « non » : la ligne n'est pas fournie. Sans nouvelle tentative
/// automatique, comme la lecture du prenom du Compte.
final FutureProvider<bool> notificationsAutoriseesProvider =
    FutureProvider.autoDispose<bool>((Ref ref) async {
      try {
        return (await ref.watch(reglagesPushProvider.future)).serveur.autorise;
      } on Object {
        return false;
      }
    }, retry: (int _, Object _) => null);

/// Le canal d'aide publie par l'academie, ou `null` (aucun canal, capacite
/// absente, lecture en echec). Sans nouvelle tentative automatique.
final FutureProvider<CanalSupport?> canalAideCompteProvider =
    FutureProvider.autoDispose<CanalSupport?>((Ref ref) async {
      try {
        return await ref.watch(portSupportProvider).canal();
      } on Object {
        return null;
      }
    }, retry: (int _, Object _) => null);

/// La langue de l'interface en ce moment, francais ou arabe : celle qui
/// s'affiche, meme quand la preference suit l'appareil (« Systeme »).
PreferenceLangue langueEffective(BuildContext context) =>
    TranslationProvider.of(context).locale == AppLocale.ar
    ? PreferenceLangue.arabe
    : PreferenceLangue.francais;

/// Le nom d'une langue du compte, ecrit dans cette langue.
String nomLangueCompte(PreferenceLangue langue) =>
    langue == PreferenceLangue.arabe
    ? t.commun.langue.arabe
    : t.commun.langue.francais;

/// « Langue » : la langue du compte, pour l'interface ET les e-mails
/// (garde-cap, 11/11/2026). Ouvre le choix entre le francais et l'arabe.
LigneRubrique ligneLangueCompte(BuildContext context) => LigneRubrique(
  icone: AppIcons.langue,
  libelle: t.compte.langue,
  legende: t.compte.page.langue.legende,
  valeur: nomLangueCompte(langueEffective(context)),
  onPress: () => unawaited(ouvrirLangueCompte(context)),
);

/// Ouvre le choix de la langue du compte.
Future<void> ouvrirLangueCompte(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.compte.langue,
      constructeur: (BuildContext _) => const FeuilleLangueCompte(),
    );

/// Le choix de la langue du compte : francais ou arabe, rien d'autre tant que
/// le lot LANGUES n'est pas lance. L'interface change tout de suite ; la
/// langue des e-mails part au serveur (`choisirLangueCompte`, lot
/// PREFERENCES-PAR-COMPTE de A). Un refus du serveur est dit ici.
class FeuilleLangueCompte extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLangueCompte({super.key});

  /// La cle du choix de la langue.
  static const Key choixKey = ValueKey<String>('langue-compte-choix');

  /// La cle du message de refus.
  static const Key refusKey = ValueKey<String>('langue-compte-refus');

  @override
  ConsumerState<FeuilleLangueCompte> createState() =>
      _FeuilleLangueCompteState();
}

class _FeuilleLangueCompteState extends ConsumerState<FeuilleLangueCompte> {
  bool _refus = false;

  Future<void> _choisir(PreferenceLangue langue) async {
    setState(() => _refus = false);
    final bool ok = await choisirLangueCompte(ref, langue);
    if (!mounted) return;
    setState(() => _refus = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final PreferenceLangue actuelle = langueEffective(context);
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.compte.page.langue.legende,
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        // Le meme choix en ligne que le theme (ControleSegmente) : la langue
        // choisie se voit, sans chevron qui promettrait une autre page.
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: t.compte.langue,
          child: ControleSegmente<PreferenceLangue>(
            key: FeuilleLangueCompte.choixKey,
            rectangle: true,
            valeur: actuelle,
            segments: <Segment<PreferenceLangue>>[
              for (final PreferenceLangue langue in languesDuCompte)
                Segment<PreferenceLangue>(
                  valeur: langue,
                  libelle: nomLangueCompte(langue),
                ),
            ],
            onChange: (PreferenceLangue langue) => unawaited(_choisir(langue)),
          ),
        ),
        if (_refus) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              t.compte.page.langue.refus,
              key: FeuilleLangueCompte.refusKey,
              style: palette.inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// « Notifications » : les reglages des notifications de cet appareil
/// (PUSH-1), les memes que depuis la page Notifications.
LigneRubrique ligneNotificationsCompte(BuildContext context) => LigneRubrique(
  icone: AppIcons.notifications,
  libelle: t.compte.tuteur.pagePreferences.notifications,
  legende: t.compte.tuteur.pagePreferences.notificationsDetail,
  onPress: () => unawaited(ouvrirReglagesPush(context)),
);

/// « Accessibilite » : seulement les reglages qui agissent vraiment
/// (mouvement reduit, lu par `mode_accessibilite.dart` ; reduction des
/// effets, qui coupe les lumieres, `EffetsReduits` ; raccourcis de la salle,
/// lus par `salle_seance.dart`).
LigneRubrique ligneAccessibiliteCompte(BuildContext context) => LigneRubrique(
  icone: AppIcons.profil,
  libelle: t.compte.accessibilite,
  legende: t.compte.page.accessibiliteLegende,
  onPress: () => unawaited(
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.compte.accessibilite,
      constructeur: (BuildContext _) => const FeuilleAccessibiliteCompte(),
    ),
  ),
);

/// Les deux interrupteurs de l'accessibilite.
class FeuilleAccessibiliteCompte extends ConsumerWidget {
  /// Cree la feuille.
  const FeuilleAccessibiliteCompte({super.key});

  /// L'interrupteur du mouvement reduit.
  static const Key animationsKey = ValueKey<String>('compte-animations');

  /// L'interrupteur de la reduction des effets.
  static const Key effetsKey = ValueKey<String>('compte-effets');

  /// L'interrupteur des raccourcis de la salle.
  static const Key raccourcisKey = ValueKey<String>('reglage-raccourcis-salle');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreferencesLocales preferences = ref.watch(
      preferencesLocalesProvider,
    );
    final PreferencesLocalesControleur controleur = ref.read(
      preferencesLocalesProvider.notifier,
    );
    return GroupeReglages(
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.journee,
          libelle: t.compte.animations,
          legende: t.compte.animationsDetail,
          controle: Switch.adaptive(
            key: animationsKey,
            value: preferences.animationsReduites,
            onChanged: controleur.animations,
          ),
        ),
        // Coupe les lumieres (EffetsReduits, garde-cap, 11/11/2026).
        LigneRubrique(
          icone: AppIcons.reglages,
          libelle: t.compte.effets,
          legende: t.compte.effetsDetail,
          controle: Switch.adaptive(
            key: effetsKey,
            value: preferences.effetsReduits,
            onChanged: controleur.effets,
          ),
        ),
        LigneRubrique(
          icone: AppIcons.reglages,
          libelle: LibellesSalleB.raccourcisTitre,
          legende: LibellesSalleB.raccourcisDetail,
          controle: Switch.adaptive(
            key: raccourcisKey,
            value: preferences.raccourcisSalle,
            onChanged: controleur.raccourcisSalle,
          ),
        ),
      ],
    );
  }
}

/// « Aide et contact » : le canal publie par l'academie, ecrit tel quel. Rien
/// tant qu'aucun canal n'est publie ou lisible : jamais « aucun canal ».
LigneRubrique? ligneAideCompte(WidgetRef ref) {
  final CanalSupport? valeur = ref.watch(canalAideCompteProvider).value;
  if (valeur == null) return null;
  return LigneRubrique(
    icone: AppIcons.lecon,
    libelle: valeur.nature == NatureCanalSupport.courriel
        ? t.compte.tuteur.pageAide.canalCourriel
        : t.compte.tuteur.pageAide.canalLien,
    legende: valeur.adresse,
  );
}

/// « Informations legales » : les textes juridiques, lisibles par tous.
LigneRubrique ligneInformationsLegales(BuildContext context) => LigneRubrique(
  icone: AppIcons.fichierPdf,
  libelle: t.compte.tuteur.aide.legal,
  legende: t.compte.tuteur.pageLegal.textes,
  onPress: () => unawaited(context.push(Routes.juridique)),
);
