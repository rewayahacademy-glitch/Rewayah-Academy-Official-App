/// CADRE-ECRAN (pilote, 07/11/2026) : la page ou le candidat enseignant lit
/// et accepte le cadre religieux et pedagogique.
///
/// Avant elle, aucun candidat ne pouvait envoyer sa candidature : le portail
/// et la carte du recapitulatif menaient a la page des accords, qui ne
/// presente pas le cadre ; on tournait en rond.
///
/// - Le texte et sa version sont lus sur le serveur ([texteCadreProvider]),
///   jamais ecrits ici. Le texte ne s'affiche que si sa version est celle que
///   le serveur exige (`cadreReligieux.versionRequise` du dossier).
/// - L'acceptation passe par le mecanisme des consentements existant
///   (`PortConsentements.accepter`, comme le code de conduite), donc par la
///   policy `contract_acceptances_cadre_religieux_candidat` : le serveur
///   decide, l'ecran relit le dossier et dit ce que le serveur rend.
/// - Accepte, la page propose « Completer ma candidature ».
///
/// Les cinq etats : chargement (squelette), contenu (le texte, la case et le
/// bouton), vide (rien de publie : une phrase, aucun bouton), erreur (lecture
/// impossible, « Reessayer »), hors ligne (le bloc de ce qui manque, sous le
/// bandeau de la coquille).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/texte_cadre.dart';
import '../../core/capacites/port_consentements.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../consentements/texte_observation.dart';
import 'lecture_page.dart';

/// La page du cadre religieux et pedagogique.
class CadreReligieuxPage extends ConsumerWidget {
  /// Cree la page.
  const CadreReligieuxPage({super.key});

  /// La cle de la page.
  static const Key pageKey = ValueKey<String>('cadre-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) => lecturePage<EtatDossier>(
    ref: ref,
    key: pageKey,
    titre: t.recrutement.cadre.titre,
    valeur: ref.watch(etatDossierProvider),
    titreEchec: t.recrutement.portail.nonCharge,
    onReessayer: () => ref.invalidate(etatDossierProvider),
    construire: (EtatDossier lu) {
      // Une adresse tapee sans candidature : le portail dit ou on en est.
      if (!lu.profilExiste || !lu.candidature.existe) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) GoRouter.of(context).go(Routes.attente);
        });
        return PageSimple(
          titre: t.recrutement.cadre.titre,
          corps: const Skeleton.liste(lignes: 3),
        );
      }
      return PageSimple(
        key: pageKey,
        titre: t.recrutement.cadre.titre,
        corps: ContenuCadre(candidature: lu.candidature),
      );
    },
  );
}

/// Le contenu : selon ce que le serveur rend du cadre.
class ContenuCadre extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const ContenuCadre({required this.candidature, super.key});

  /// La candidature lue dans le dossier.
  final CandidatureDossier candidature;

  /// L'etat « pas encore publie ».
  static const Key nonPublieKey = ValueKey<String>('cadre-non-publie');

  /// Le texte publie.
  static const Key texteKey = ValueKey<String>('cadre-texte');

  /// La case d'acceptation.
  static const Key caseKey = ValueKey<String>('cadre-case');

  /// Le bouton d'acceptation.
  static const Key accepterKey = ValueKey<String>('cadre-accepter');

  /// La phrase « Vous avez accepte ».
  static const Key accepteKey = ValueKey<String>('cadre-accepte');

  /// Le bouton « Completer ma candidature ».
  static const Key completerKey = ValueKey<String>('cadre-completer');

  /// L'etat d'erreur de lecture du texte.
  static const Key erreurLectureKey = ValueKey<String>('cadre-erreur-lecture');

  @override
  ConsumerState<ContenuCadre> createState() => _ContenuCadreEtat();
}

class _ContenuCadreEtat extends ConsumerState<ContenuCadre> {
  bool _cochee = false;
  bool _envoi = false;
  bool _horsLigne = false;
  String? _erreur;

  Future<void> _accepter(String version) async {
    if (!_cochee) {
      setState(() => _erreur = t.contrat.caseRequise);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portConsentementsProvider)
          .accepter(
            sorte: SorteContrat.cadreReligieuxEnseignant,
            version: version,
          );
      ref
        ..invalidate(acceptationsProvider)
        ..invalidate(etatDossierProvider);
    } on Object catch (e) {
      if (!mounted) return;
      final bool refuse =
          e is PostgrestException && (e.code == '42501' || e.code == '23514');
      setState(
        () => _erreur = _horsLigne
            ? t.contrat.horsLigne
            : refuse
            ? t.recrutement.cadre.refuse
            : t.recrutement.cadre.erreurAccord,
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EtatCadre cadre = widget.candidature.cadre;
    _horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();

    // Rien de publie : une phrase, aucun bouton.
    Widget nonPublie() => EtatSysteme(
      key: ContenuCadre.nonPublieKey,
      nature: NatureEtat.indisponible,
      phrase: t.accords.cadreNonPublie,
    );

    if (!cadre.publie) return nonPublie();

    // Accepte (le serveur le dit) : la suite de la candidature.
    if (cadre.accepte) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            key: ContenuCadre.accepteKey,
            liveRegion: true,
            child: TexteSansCoupure(
              t.recrutement.questionnaire.cadreAccepte,
              style: palette.inkStrong.applyTo(corps),
            ),
          ),
          Ecart.vLg,
          // Un seul bouton plein par ecran (K-56) : la suite est un lien.
          LienFleche(
            key: ContenuCadre.completerKey,
            alignerEnDebut: true,
            libelle: widget.candidature.questionnaireOuvert
                ? t.recrutement.portail.completer
                : t.commun.retour,
            onPress: () => GoRouter.of(context).go(
              widget.candidature.questionnaireOuvert
                  ? Routes.attenteCandidature
                  : Routes.attente,
            ),
          ),
        ],
      );
    }

    final String langue = LocaleSettings.currentLocale.languageCode;
    final AsyncValue<TexteCadre?> lecture = lectureHorsLigne(
      ref.watch(texteCadreProvider(langue)),
      horsLigne: _horsLigne,
    );
    void relire() => ref.invalidate(texteCadreProvider(langue));

    if (!lecture.hasValue) {
      if (lecture.hasError) {
        if (sansDonneesHorsLigne(lecture, horsLigne: _horsLigne)) {
          return EtatSansDonnees(
            key: ContenuCadre.erreurLectureKey,
            quoi: t.recrutement.cadre.erreurLecture,
            onAction: relire,
          );
        }
        return EtatSysteme(
          key: ContenuCadre.erreurLectureKey,
          nature: NatureEtat.echecServeur,
          phrase: t.recrutement.cadre.erreurLecture,
          libelleAction: t.commun.reessayer,
          onAction: relire,
        );
      }
      return const Skeleton.texte(lignes: 8);
    }

    final TexteCadre? texte = lecture.requireValue;
    // Un texte absent, ou d'une autre version que celle exigee : rien a
    // accepter ici, jamais un faux bouton.
    if (texte == null || texte.version != cadre.versionRequise) {
      return nonPublie();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Directionality(
          textDirection: texte.langue == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: TexteCadrePublie(
            key: ContenuCadre.texteKey,
            texte: texte.texte,
          ),
        ),
        Ecart.vXl,
        CaseAccordTexte(
          key: ContenuCadre.caseKey,
          libelle: t.recrutement.cadre.caseAccord,
          cochee: _cochee,
          onChanged: _envoi
              ? null
              : (bool v) => setState(() {
                  _cochee = v;
                  _erreur = null;
                }),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(_erreur!, style: palette.inkAlert.applyTo(corps)),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          key: ContenuCadre.accepterKey,
          libelle: t.recrutement.cadre.accepter,
          enCours: _envoi,
          onPress: _envoi ? null : () => unawaited(_accepter(texte.version)),
        ),
      ],
    );
  }
}

/// Le texte publie, affiche TEL QUEL (arbitrage du garde-cap, 07/11/2026 :
/// texte brut en base, aucun Markdown). Les paragraphes sont separes par une
/// ligne vide ; le premier est le titre du texte, lu comme un en-tete ; les
/// puces « • » sont dans le texte lui-meme. Aucun mot n'est change, ajoute ni
/// retire, aucun caractere n'est interprete.
class TexteCadrePublie extends StatelessWidget {
  /// Cree le texte.
  const TexteCadrePublie({required this.texte, super.key});

  /// Le texte publie.
  final String texte;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();
    final List<String> paragraphes = texte
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n[ \t]*\n'))
        .where((String p) => p.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < paragraphes.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          if (i == 0)
            Semantics(
              header: true,
              child: Text(paragraphes[i], style: textes.titleMedium ?? corps),
            )
          else
            Text(paragraphes[i], style: corps),
        ],
      ],
    );
  }
}
