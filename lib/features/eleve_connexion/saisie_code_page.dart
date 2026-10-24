import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/accessibilite/texte_sans_coupure.dart'
    show sansCoupureAuTrait;
import '../../core/appairage/lecteur_qr.dart';
import '../../core/appairage/profils_locaux.dart';
import '../../core/appairage/service_enfant.dart';
import '../../core/cache/secure/stockage_securise.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/zone_saisie.dart' show ZoneSaisie;

/// Le titre et la phrase d'un refus, dits simplement, jamais le texte brut du
/// serveur (DB-APP-06). Partages par la saisie et le scanner.
({String titre, String phrase}) libellesRefusAppairage(
  MotifRefusAppairage motif,
) {
  final r = t.eleveConnexion.refus;
  return switch (motif) {
    MotifRefusAppairage.inconnu => (titre: r.inconnuTitre, phrase: r.inconnu),
    MotifRefusAppairage.expire => (titre: r.expireTitre, phrase: r.expire),
    MotifRefusAppairage.dejaUtilise => (
      titre: r.dejaUtiliseTitre,
      phrase: r.dejaUtilise,
    ),
    MotifRefusAppairage.revoque => (titre: r.revoqueTitre, phrase: r.revoque),
    MotifRefusAppairage.plafond => (titre: r.plafondTitre, phrase: r.plafond),
    MotifRefusAppairage.tropDEssais => (
      titre: r.tropDEssaisTitre,
      phrase: r.tropDEssais,
    ),
    MotifRefusAppairage.horsLigne => (
      titre: r.horsLigneTitre,
      phrase: r.horsLigne,
    ),
    MotifRefusAppairage.nonEnregistre => (
      titre: r.nonEnregistreTitre,
      phrase: r.nonEnregistre,
    ),
    MotifRefusAppairage.generique => (
      titre: r.generiqueTitre,
      phrase: r.generique,
    ),
  };
}

/// Connecte l'appareil avec [code] (deja normalise), puis passe au code
/// personnel sur `/connexion/eleve`, le profil en `extra` (jamais dans
/// l'adresse). Leve [AppairageRefuse].
///
/// Partage par la saisie et le scanner : une seule facon de connecter un
/// appareil.
Future<ProfilLocal> connecterDepuisEcran(WidgetRef ref, String code) =>
    connecterCetAppareil(
      service: ref.read(serviceEnfantProvider),
      coffre: ref.read(stockageSecuriseProvider),
      profils: profilsLocauxSiDisponibles(ref),
      code: code,
    );

/// La memoire des profils de cet appareil, ou `null` si la base locale ne
/// s'ouvre pas (D7). Elle n'est qu'un confort : sa panne ne bloque jamais
/// l'appairage, dont le jeton est range dans le coffre.
ProfilsLocaux? profilsLocauxSiDisponibles(WidgetRef ref) {
  try {
    return ref.read(profilsLocauxProvider);
  } on Object catch (erreur) {
    journalDev('memoire des profils indisponible : $erreur');
    return null;
  }
}

/// La composition tablette et bureau des trois taches focalisees de
/// l'appareil eleve (saisie du code, scanner, choix du profil et code
/// personnel) : un panneau centre de 560 au plus (manifeste section 2, D1
/// #24), dont l'en-tete (disque retour 48 et titre) est aligne sur le
/// panneau, jamais laisse en haut a gauche de la page (REVUE R-07).
///
/// Une seule composition pour les trois ecrans : la page n'a alors ni titre ni
/// retour propres (`PageShell` sans `titre` ni `onRetour`).
class PanneauAppareilEleve extends StatelessWidget {
  /// Cree le panneau.
  const PanneauAppareilEleve({
    required this.child,
    super.key,
    this.titre,
    this.onRetour,
  });

  /// La cle du panneau, pour les tests et les captures.
  static const Key panneauKey = ValueKey<String>('panneau-appareil-eleve');

  /// Le titre de la tache, au-dessus de la carte.
  final String? titre;

  /// Le retour ; sans lui, pas de disque retour.
  final VoidCallback? onRetour;

  /// Le contenu de la carte.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? titrePanneau = titre;
    final VoidCallback? retour = onRetour;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        key: panneauKey,
        constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (titrePanneau != null)
              EntetePage(titre: titrePanneau, onRetour: retour)
            else if (retour != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DisqueRetour(onPress: retour),
              ),
            if (titrePanneau != null || retour != null) Ecart.vXl,
            AppCard(child: child),
          ],
        ),
      ),
    );
  }
}

/// `/connexion/eleve/code` : la saisie du code d'appairage, sur l'appareil de
/// l'eleve (sans session).
///
/// L'ecran s'adresse a l'adulte qui prepare l'appareil (la feuille
/// « Connecter l'appareil d'un eleve » de la connexion le dit « reserve aux
/// tuteurs »). Un seul champ, en chiffres tabulaires, qui n'accepte que
/// l'alphabet du serveur ; les refus sont dits sous le champ ; le scanner est
/// propose la ou la plateforme sait lire un QR code.
///
/// Etats : vide (action active : l'appui dit sous le champ qu'un code compte
/// six caractères, l'annonce et rend le focus au champ), saisie, erreur sous
/// le champ (format ou refus du serveur), verification (action en cours,
/// champ fige, double envoi bloque), hors ligne (action non rendue, phrase
/// sous le champ), succes (passage au code personnel). Jamais de bouton
/// grise (BOUTONS-GRISES-1).
class SaisieCodePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const SaisieCodePage({super.key});

  /// La cle du champ, pour les tests et les captures.
  static const Key champKey = ValueKey<String>('saisie-code-champ');

  @override
  ConsumerState<SaisieCodePage> createState() => _SaisieCodePageState();
}

class _SaisieCodePageState extends ConsumerState<SaisieCodePage> {
  final TextEditingController _champ = TextEditingController();
  final FocusNode _focusChamp = FocusNode(debugLabel: 'code-appairage');
  bool _enCours = false;
  String? _erreur;
  int _generation = 0;

  @override
  void dispose() {
    // Le code quitte la memoire avec l'ecran.
    _champ.clear();
    _champ.dispose();
    _focusChamp.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_enCours) {
      return;
    }
    final String? code = FormatCodeAppairage.normaliser(_champ.text);
    if (code == null) {
      // Code incomplet : la phrase sous le champ, annoncee, et le focus au
      // champ (BOUTONS-GRISES-1).
      final String message = t.eleveConnexion.refus.format;
      setState(() => _erreur = message);
      signalerManque(context, message, champ: _focusChamp);
      return;
    }
    final int generation = ++_generation;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final ProfilLocal profil = await connecterDepuisEcran(ref, code);
      if (!mounted || generation != _generation) {
        return;
      }
      _champ.clear();
      GoRouter.of(context).go(Routes.connexionEleve, extra: profil);
    } on AppairageRefuse catch (refus) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _erreur = libellesRefusAppairage(refus.motif).phrase);
    } on Object {
      // Filet : tout autre echec est dit sous le champ, jamais tu.
      if (!mounted || generation != _generation) {
        return;
      }
      setState(
        () =>
            _erreur = libellesRefusAppairage(MotifRefusAppairage.generique)
                .phrase,
      );
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  /// Le retour : au choix des profils quand on en vient (`?depuis=profils`,
  /// appareil partage), sinon a la connexion. Sans profil, `/connexion/eleve`
  /// renverrait ici : ce serait une impasse.
  void _retour() {
    String? depuis;
    try {
      depuis = GoRouterState.of(context).uri.queryParameters['depuis'];
    } on Object {
      depuis = null;
    }
    GoRouter.of(context)
        .go(depuis == 'profils' ? Routes.connexionEleve : Routes.connexion);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> reseau = ref.watch(horsLigneProvider);
    final bool horsLigne = reseau.hasValue && reseau.requireValue;
    final bool scanner = ref.watch(lecteurQrDisponibleProvider);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;

    // Hors ligne, la verification ne peut pas aboutir : l'action n'est pas
    // rendue, la phrase sous le champ dit quand elle le pourra. Code
    // incomplet : l'action reste active et dit ce qui manque.
    final Widget? action = horsLigne
        ? null
        : ActionPrincipale(
            libelle: t.eleveConnexion.saisie.valider,
            enCours: _enCours,
            fleche: true,
            onPress: () => unawaited(_valider()),
          );

    final Widget formulaire = _Formulaire(
      champ: _champ,
      focusChamp: _focusChamp,
      enCours: _enCours,
      erreur: _erreur,
      horsLigne: horsLigne,
      onChange: () => setState(() => _erreur = null),
      onValider: horsLigne ? null : () => unawaited(_valider()),
      actionDansLeCorps: mobile ? null : action,
      scanner: scanner && !_enCours
          ? () => GoRouter.of(context).go(Routes.connexionEleveScanner)
          : null,
    );

    // Telephone : l'action est ancree en bas (champ E3, manifeste #14).
    // Tablette et bureau : le panneau centre commun, qui porte son en-tete et
    // son action, jamais une feuille mobile etiree.
    if (mobile) {
      return PageShell(
        titre: t.eleveConnexion.saisie.titre,
        onRetour: _retour,
        actions: action,
        child: formulaire,
      );
    }
    return PageShell(
      child: PanneauAppareilEleve(
        titre: t.eleveConnexion.saisie.titre,
        onRetour: _retour,
        child: formulaire,
      ),
    );
  }
}

class _Formulaire extends StatelessWidget {
  const _Formulaire({
    required this.champ,
    required this.focusChamp,
    required this.enCours,
    required this.erreur,
    required this.horsLigne,
    required this.onChange,
    required this.onValider,
    required this.actionDansLeCorps,
    required this.scanner,
  });

  final TextEditingController champ;
  final FocusNode focusChamp;
  final bool enCours;
  final String? erreur;
  final bool horsLigne;
  final VoidCallback onChange;
  final VoidCallback? onValider;
  final Widget? actionDansLeCorps;
  final VoidCallback? scanner;

  /// [erreur] telle qu'elle se rend sous le champ sans couper un mot apres
  /// son trait d'union (SUPERPOS-1b : « Demandez- / lui » a 320 en texte
  /// double). L'erreur d'un champ est posee par `InputDecorator`, sur la
  /// largeur du champ moins ses marges interieures et l'ecart du filet
  /// (`AppSpacing.xs` de chaque cote, champ rempli) : un gluon invisible
  /// n'est ajoute que si la ligne s'y coupait vraiment, a cette largeur ou
  /// un peu moins (arrondis). Sinon, le texte donne, tel quel.
  String _erreurEntiere(BuildContext context, String erreur, double largeur) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = (theme.textTheme.bodySmall ?? const TextStyle())
        .merge(theme.inputDecorationTheme.errorStyle);
    final TextDirection sens = Directionality.of(context);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double utile =
        largeur -
        (theme.inputDecorationTheme.contentPadding?.horizontal ?? 0) -
        AppSpacing.xs * 2;
    for (final double l in <double>[utile, utile - AppSpacing.sm]) {
      final String rendu = sansCoupureAuTrait(erreur, style, sens, echelle, l);
      if (!identical(rendu, erreur)) {
        return rendu;
      }
    }
    return erreur;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.eleveConnexion.saisie.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => TextField(
            key: SaisieCodePage.champKey,
            controller: champ,
            focusNode: focusChamp,
            enabled: !enCours,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            style: palette.inkStrong.applyTo(AppTypography.chiffre(taille: 28)),
            inputFormatters: <TextInputFormatter>[
              const MajusculesFormatter(),
              FilteringTextInputFormatter.allow(FormatCodeAppairage.caractere),
              LengthLimitingTextInputFormatter(FormatCodeAppairage.longueur),
            ],
            onChanged: (String _) => onChange(),
            onSubmitted: (String _) => onValider?.call(),
            decoration: InputDecoration(
              labelText: t.eleveConnexion.saisie.champ,
              helperText: erreur == null ? t.eleveConnexion.saisie.aide : null,
              helperMaxLines: ZoneSaisie.lignesAideMax,
              errorText: erreur == null
                  ? null
                  : _erreurEntiere(context, erreur!, c.maxWidth),
              errorMaxLines: ZoneSaisie.lignesAideMax,
            ),
          ),
        ),
        if (horsLigne) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              t.eleveConnexion.saisie.horsLigne,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
        if (actionDansLeCorps != null) ...<Widget>[
          Ecart.vXxl,
          actionDansLeCorps!,
        ],
        if (scanner != null) ...<Widget>[
          Ecart.vLg,
          // Une autre facon de se connecter n'est pas l'action principale :
          // une ligne de lien (K-56).
          LienFleche(
            libelle: t.eleveConnexion.saisie.scanner,
            icone: AppIcons.qr,
            onPress: scanner,
          ),
        ],
      ],
    );
  }
}

/// Met la saisie en majuscules : le code est affiche en majuscules chez le
/// tuteur, et la base le compare en majuscules.
class MajusculesFormatter extends TextInputFormatter {
  /// Cree le formateur.
  const MajusculesFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue _,
    TextEditingValue apres,
  ) => TextEditingValue(
    text: apres.text.toUpperCase(),
    selection: apres.selection,
  );
}
