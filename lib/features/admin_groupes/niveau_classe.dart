import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_plan_classe.dart';
import '../../core/admin/service_programme.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_motif.dart';
import '../../core/widgets/selecteur_niveau_programme.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_pedagogie_programmes/feuille_contenu_niveau.dart'
    show messageMetier;

/// PLAN-DE-CLASSE A : la ligne « Etape » de la fiche d'une classe, cote
/// direction. Le serveur dit l'etape de la classe et combien de ses membres
/// n'en ont pas encore ; l'ecran ne calcule rien.
class LigneEtapeClasse extends ConsumerWidget {
  /// Cree la ligne de la classe [groupeId].
  const LigneEtapeClasse({required this.groupeId, super.key});

  /// L'identifiant de la classe.
  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtapeClasse?> etape = ref.watch(
      etapeClasseProvider(groupeId),
    );
    final TextTheme textes = Theme.of(context).textTheme;
    return switch (etape) {
      AsyncValue<EtapeClasse?>(hasValue: true, value: final EtapeClasse? e)
          when e != null =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LigneCleValeur(
              cle: t.admin.planClasse.etapeCle,
              valeur: e.etapeNom ?? t.admin.planClasse.aucuneEtape,
            ),
            if (e.membresSansEtape > 0) ...<Widget>[
              Ecart.vSm,
              Text(
                t.admin.planClasse.sansEtapeMembres(n: e.membresSansEtape),
                style: textes.bodySmall,
              ),
            ],
          ],
        ),
      AsyncValue<EtapeClasse?>(hasError: true) => LigneCleValeur(
        cle: t.admin.planClasse.etapeCle,
        valeur: t.admin.planClasse.programmeErreur,
      ),
      AsyncValue<EtapeClasse?>(hasValue: true) => const SizedBox.shrink(),
      _ => const Skeleton.liste(lignes: 1),
    };
  }
}

/// Le texte d'un refus du serveur, en mots simples : ce qui s'est passe et ce
/// qu'il reste a faire (K-59). Le message brut n'est repris que pour un refus
/// inconnu.
String refusPlanClasse(Object erreur, String Function(String brut) generique) {
  final String message = messageMetier(erreur).trim();
  final r = t.admin.planClasse.refus;
  if (message.startsWith('date_future')) return r.dateFuture;
  if (message.startsWith('date_avant_inscription')) {
    final int i = message.indexOf(': ');
    final DateTime? jour = i < 0
        ? null
        : DateTime.tryParse(message.substring(i + 2));
    return r.dateAvantInscription(
      date: jour == null ? '' : ChampDate.ecrire(jour),
    );
  }
  if (message.startsWith('eleve_sans_etape')) return r.eleveSansEtape;
  if (message.startsWith('niveau_non_publie')) return r.niveauNonPublie;
  if (message.startsWith('classe_close')) return r.classeClose;
  if (message.startsWith('aucun_programme_publie')) {
    return r.aucunProgrammePublie;
  }
  if (message.startsWith('motif_obligatoire')) return r.motif;
  return generique(message);
}

/// La coque commune des deux gestes : un texte d'introduction, les champs du
/// geste, le motif (jamais pre-choisi), l'erreur du serveur, puis le bouton.
///
/// Le bouton n'est jamais grise (K-56) : presse trop tot, il dit ce qui manque.
class FeuilleGesteDirection extends StatefulWidget {
  /// Cree la feuille.
  const FeuilleGesteDirection({
    required this.intro,
    required this.champs,
    required this.manque,
    required this.motifs,
    required this.libelleEnvoyer,
    required this.onEnvoyer,
    required this.messageErreur,
    required this.onSucces,
    super.key,
  });

  /// La phrase de contexte, en tete.
  final String intro;

  /// Les champs propres au geste (etape a choisir, jour a choisir).
  final List<Widget> champs;

  /// Ce qui manque avant d'envoyer, dit en une phrase ; nul quand tout y est.
  final String? Function() manque;

  /// Les motifs proposes en puces, « Autre » en dernier.
  final List<String> motifs;

  /// Le texte du bouton.
  final String libelleEnvoyer;

  /// Le geste serveur.
  final Future<void> Function(String motif) onEnvoyer;

  /// Le texte d'un refus du serveur.
  final String Function(Object erreur) messageErreur;

  /// Appele apres un succes, avant la fermeture.
  final VoidCallback onSucces;

  @override
  State<FeuilleGesteDirection> createState() => _FeuilleGesteDirectionEtat();
}

class _FeuilleGesteDirectionEtat extends State<FeuilleGesteDirection> {
  final TextEditingController _motif = TextEditingController();
  final GlobalKey<SelecteurMotifEtat> _cleMotifs =
      GlobalKey<SelecteurMotifEtat>();
  bool _envoi = false;
  bool _motifManquant = false;
  String? _manque;
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final String? absent = widget.manque();
    if (absent != null) {
      setState(() {
        _manque = absent;
        _motifManquant = false;
      });
      return;
    }
    if (_motif.text.trim().isEmpty) {
      setState(() {
        _manque = null;
        _motifManquant = true;
      });
      _cleMotifs.currentState?.focaliser();
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _manque = null;
    });
    try {
      await widget.onEnvoyer(_motif.text.trim());
      widget.onSucces();
      if (mounted) Navigator.of(context).pop();
    } catch (erreur) {
      if (mounted) setState(() => _erreur = widget.messageErreur(erreur));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Color alerte = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.intro, style: textes.bodyMedium),
        Ecart.vLg,
        ...widget.champs,
        Ecart.vLg,
        Text(t.admin.planClasse.motifRequis, style: textes.bodySmall),
        Ecart.vSm,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.arrondiSm,
            border: _motifManquant
                ? Border.fromBorderSide(
                    AppPalette.of(context).inkAlert
                        .asBorderSide(width: Pressable.epaisseurFocus),
                  )
                : null,
          ),
          child: Padding(
            padding: _motifManquant
                ? const EdgeInsets.all(AppSpacing.sm)
                : EdgeInsets.zero,
            child: SelecteurMotif(
              key: _cleMotifs,
              motifs: widget.motifs,
              controleur: _motif,
              libelleChamp: t.admin.planClasse.motifChamp,
              erreur: _motifManquant ? t.formulaire.motif.manque : null,
              onChange: (String _) => setState(() => _motifManquant = false),
            ),
          ),
        ),
        if (_manque != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(_manque!, style: TextStyle(color: alerte)),
          ),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(_erreur!, style: TextStyle(color: alerte)),
          ),
        ],
        Ecart.vLg,
        ActionPrincipale(
          libelle: widget.libelleEnvoyer,
          enCours: _envoi,
          onPress: () => unawaited(_envoyer()),
        ),
      ],
    );
  }
}

/// Ouvre « Donner une etape a la classe » : les etapes de la version publiee,
/// le motif, puis le geste. Sans version publiee, la feuille le dit et mene a
/// Programmes ; en cas d'echec de lecture, elle propose de reessayer.
void ouvrirDonnerEtapeClasse(
  BuildContext context,
  WidgetRef ref, {
  required String groupeId,
  required String nomClasse,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.planClasse.donnerTitre,
    constructeur: (BuildContext contexte) =>
        _FeuilleDonnerEtape(groupeId: groupeId, nomClasse: nomClasse),
  );
}

class _FeuilleDonnerEtape extends ConsumerStatefulWidget {
  const _FeuilleDonnerEtape({required this.groupeId, required this.nomClasse});

  final String groupeId;
  final String nomClasse;

  @override
  ConsumerState<_FeuilleDonnerEtape> createState() => _FeuilleDonnerEtapeEtat();
}

class _FeuilleDonnerEtapeEtat extends ConsumerState<_FeuilleDonnerEtape> {
  String? _niveauId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<VersionProgramme?> version = ref.watch(
      versionActiveProgrammeProvider,
    );
    if (version.hasError) {
      return _Echec(
        onReessayer: () => ref.invalidate(versionsProgrammeProvider),
      );
    }
    if (!version.hasValue) return const Skeleton.liste(lignes: 3);
    final VersionProgramme? publiee = version.requireValue;
    if (publiee == null) {
      return Text(
        t.admin.planClasse.aucunProgramme,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final AsyncValue<List<NiveauProgramme>> niveaux = ref.watch(
      niveauxProgrammeProvider(publiee.id),
    );
    if (niveaux.hasError) {
      return _Echec(
        onReessayer: () => ref.invalidate(niveauxProgrammeProvider(publiee.id)),
      );
    }
    if (!niveaux.hasValue) return const Skeleton.liste(lignes: 3);
    return FeuilleGesteDirection(
      intro: t.admin.planClasse.donnerIntro,
      champs: <Widget>[
        Text(
          t.admin.planClasse.donnerChamp,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Ecart.vMd,
        SelecteurNiveauProgramme(
          niveaux: niveaux.requireValue,
          selectionne: _niveauId,
          onSelectionner: (String id) => setState(() => _niveauId = id),
        ),
      ],
      manque: () => _niveauId == null ? t.admin.planClasse.donnerManque : null,
      motifs: <String>[
        t.admin.planClasse.motifs.classe,
        t.admin.planClasse.motifs.reprise,
        t.admin.planClasse.motifs.correction,
      ],
      libelleEnvoyer: t.admin.planClasse.donnerEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(servicePlanClasseProvider)
          .donnerNiveauClasse(
            groupeId: widget.groupeId,
            niveauId: _niveauId!,
            motif: motif,
          ),
      messageErreur: (Object e) => refusPlanClasse(
        e,
        (String brut) => t.admin.planClasse.donnerErreur(message: brut),
      ),
      onSucces: () {
        ref
          ..invalidate(etapeClasseProvider(widget.groupeId))
          ..invalidate(placementsAFaireProvider);
      },
    );
  }
}

class _Echec extends StatelessWidget {
  const _Echec({required this.onReessayer});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.admin.planClasse.programmeErreur,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vMd,
        LienFleche(libelle: t.commun.reessayer, onPress: onReessayer),
      ],
    );
  }
}

/// Ouvre « Dire quand il a commence » pour un eleve deja en cours : un jour
/// passe, apres l'inscription ; le serveur refuse le reste et la feuille dit
/// pourquoi.
void ouvrirDaterEntreeEtape(
  BuildContext context,
  WidgetRef ref, {
  required String studentId,
  required String libelleEleve,
  DateTime? inscritLe,
  String? groupeId,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.planClasse.dateTitre,
    constructeur: (BuildContext contexte) => _FeuilleDater(
      studentId: studentId,
      libelleEleve: libelleEleve,
      inscritLe: inscritLe,
      groupeId: groupeId,
    ),
  );
}

class _FeuilleDater extends ConsumerStatefulWidget {
  const _FeuilleDater({
    required this.studentId,
    required this.libelleEleve,
    required this.inscritLe,
    required this.groupeId,
  });

  final String studentId;
  final String libelleEleve;
  final DateTime? inscritLe;
  final String? groupeId;

  @override
  ConsumerState<_FeuilleDater> createState() => _FeuilleDaterEtat();
}

class _FeuilleDaterEtat extends ConsumerState<_FeuilleDater> {
  DateTime? _jour;

  @override
  Widget build(BuildContext context) {
    final DateTime aujourdhui = ref.read(horlogeFormulairesProvider)();
    final DateTime inscrit =
        widget.inscritLe ??
        DateTime(aujourdhui.year - 3, aujourdhui.month, aujourdhui.day);
    return FeuilleGesteDirection(
      intro: '${widget.libelleEleve}\n${t.admin.planClasse.dateIntro}',
      champs: <Widget>[
        ChampDate(
          libelle: t.admin.planClasse.dateChamp,
          aide: t.admin.planClasse.dateAide,
          valeur: _jour,
          aujourdhui: aujourdhui,
          premier: inscrit,
          dernier: aujourdhui,
          onChoix: (DateTime j) => setState(() => _jour = j),
        ),
      ],
      manque: () => _jour == null ? t.admin.planClasse.dateManque : null,
      motifs: <String>[
        t.admin.planClasse.dateMotifs.avant,
        t.admin.planClasse.dateMotifs.correction,
        t.admin.planClasse.dateMotifs.confirme,
      ],
      libelleEnvoyer: t.admin.planClasse.dateEnvoyer,
      onEnvoyer: (String motif) => ref
          .read(servicePlanClasseProvider)
          .daterEntreeEtape(
            studentId: widget.studentId,
            jour: _jour!,
            motif: motif,
          ),
      messageErreur: (Object e) => refusPlanClasse(
        e,
        (String brut) => t.admin.planClasse.dateErreur(message: brut),
      ),
      onSucces: () {
        final String? g = widget.groupeId;
        if (g != null) ref.invalidate(etapeClasseProvider(g));
      },
    );
  }
}
