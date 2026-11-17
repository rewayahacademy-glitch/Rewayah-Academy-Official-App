// PX-2 : les propositions de Praxis pour UN dossier, sous la barre de decision.
// Praxis prepare, il n'execute jamais : « Valider » appelle la porte publique du
// geste sous l'identite de la direction (le moteur decide comme pour un geste
// fait a la main, avec la version du dossier que Praxis a vue) ; « Ecarter » ne
// fait rien sur le dossier. Le texte de Praxis (et le motif dit au candidat) est
// montre MOT POUR MOT avant « Valider » : rien n'est resume ni reformule.
//
// Aucune proposition, ou une lecture qui echoue : rien n'est rendu (la barre de
// decision reste celle d'avant). Une proposition dont le dossier a change n'a plus
// de « Valider » (le serveur la refuserait) : une phrase le dit, « Ecarter » reste.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/agent/propositions_praxis.dart';
import '../../core/candidature/entretiens_direction_supabase.dart'
    show refusEntretien;
import '../../core/candidature/modeles_entretien_direction.dart';
import '../../core/candidature/port_entretiens_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/case_a_cocher.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import '../mfa_controleur/double_verification.dart';
import 'bloc_entretien.dart' show messageRefusEntretien;

/// Les cles du bloc, pour les tests.
abstract final class ClesPropositionsPraxis {
  /// Le bloc entier.
  static const Key bloc = ValueKey<String>('propositions-praxis-bloc');

  /// Le squelette de chargement.
  static const Key chargement = ValueKey<String>(
    'propositions-praxis-chargement',
  );

  /// L'etat d'erreur ou hors ligne.
  static const Key erreur = ValueKey<String>('propositions-praxis-erreur');

  /// La carte d'une proposition.
  static Key carte(String id) => ValueKey<String>('proposition-praxis-$id');

  /// « Valider ».
  static Key valider(String id) =>
      ValueKey<String>('proposition-praxis-valider-$id');

  /// « Ecarter ».
  static Key ecarter(String id) =>
      ValueKey<String>('proposition-praxis-ecarter-$id');

  /// La case d'un participant.
  static Key participant(String id, String profil) =>
      ValueKey<String>('proposition-praxis-participant-$id-$profil');
}

/// Le refus d'une validation ou d'un ecart, en mots : les refus propres aux
/// propositions, puis ceux du moteur (les memes phrases que pour un geste fait
/// a la main), puis une phrase generique. Jamais un code.
String phraseRefusProposition(ResultatProposition r) {
  final p = t.admin.praxis.propositions;
  switch (r.erreur) {
    case 'proposition_perimee':
      return p.perimee;
    case 'proposition_validee':
    case 'proposition_ecartee':
    case 'proposition_expiree':
    case 'proposition_inconnue':
      return p.close;
  }
  final Map<String, dynamic>? brut = r.brut;
  if (brut != null) {
    try {
      refusEntretien(brut);
    } on Object catch (refus) {
      return messageRefusEntretien(refus);
    }
  }
  return p.generique;
}

/// Les propositions ouvertes du dossier [reference].
class PropositionsPraxisDossier extends ConsumerWidget {
  /// Cree le bloc.
  const PropositionsPraxisDossier({
    required this.reference,
    required this.candidatureId,
    super.key,
    this.onTraitee,
  });

  /// La reference du dossier (`CAND-...`).
  final String reference;

  /// L'identifiant du dossier (le personnel qu'on peut choisir en depend).
  final String candidatureId;

  /// Une proposition est validee ou ecartee : le dossier se relit.
  final VoidCallback? onTraitee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.admin.praxis.propositions;
    final AsyncValue<List<PropositionPraxis>> lues = ref.watch(
      propositionsPraxisProvider,
    );
    // Les cinq etats : chargement, erreur, hors ligne, vide (rien), contenu.
    // Une lecture qui echoue se DIT : se taire ferait croire qu'il n'y a aucune
    // proposition.
    if (!lues.hasValue) {
      if (lues.isLoading) {
        return const Padding(
          key: ClesPropositionsPraxis.chargement,
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: Skeleton(hauteur: 96),
        );
      }
      void relire() => ref.invalidate(propositionsPraxisProvider);
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return Padding(
        key: ClesPropositionsPraxis.erreur,
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: horsLigne
            ? EtatSansDonnees(quoi: p.horsLigne, onAction: relire)
            : EmptyState(
                message: p.erreur,
                icone: AppIcons.avertissement,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              ),
      );
    }
    final List<PropositionPraxis> liste = <PropositionPraxis>[
      for (final PropositionPraxis x in lues.requireValue)
        if (x.reference == reference) x,
    ];
    if (liste.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: ClesPropositionsPraxis.bloc,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(p.titre, style: textes.titleMedium),
          Ecart.vXs,
          Text(p.intro, style: textes.bodySmall),
          for (final PropositionPraxis x in liste) ...<Widget>[
            Ecart.vLg,
            _CarteProposition(
              key: ClesPropositionsPraxis.carte(x.id),
              proposition: x,
              candidatureId: candidatureId,
              onTraitee: onTraitee,
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteProposition extends ConsumerStatefulWidget {
  const _CarteProposition({
    required this.proposition,
    required this.candidatureId,
    required this.onTraitee,
    super.key,
  });

  final PropositionPraxis proposition;
  final String candidatureId;
  final VoidCallback? onTraitee;

  @override
  ConsumerState<_CarteProposition> createState() => _EtatCarteProposition();
}

class _EtatCarteProposition extends ConsumerState<_CarteProposition> {
  final Set<String> _participants = <String>{};
  final TextEditingController _motifEcart = TextEditingController();

  /// La cle d'idempotence du geste en cours : la meme a chaque essai.
  final String _cle = const Uuid().v4();

  bool _enCours = false;
  String? _retour;
  String? _refus;

  @override
  void dispose() {
    _motifEcart.dispose();
    super.dispose();
  }

  String _nomGeste(GestePrepare g) {
    final x = t.admin.praxis.propositions.geste;
    return switch (g) {
      GestePrepare.demanderComplement => x.demanderComplement,
      GestePrepare.planifierEntretien => x.planifierEntretien,
      GestePrepare.admettreVerifications => x.admettreVerifications,
    };
  }

  Future<void> _valider() async {
    if (_enCours) return;
    final PropositionPraxis x = widget.proposition;
    setState(() {
      _enCours = true;
      _refus = null;
      _retour = null;
    });
    ResultatProposition? resultat;
    String? refus;
    try {
      resultat = await avecDoubleVerification<ResultatProposition>(
        context,
        ref,
        () => ref
            .read(servicePropositionsPraxisProvider)
            .valider(
              id: x.id,
              version: x.versionProposee,
              cle: _cle,
              participants: x.geste == GestePrepare.planifierEntretien
                  ? (<String>[..._participants]..sort())
                  : null,
            ),
      );
      if (!resultat.fait) refus = phraseRefusProposition(resultat);
    } on Object catch (e) {
      refus = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.propositions.generique;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _refus = refus;
      _retour = refus == null
          ? t.admin.praxis.propositions.fait(geste: _nomGeste(x.geste))
          : null;
    });
    if (refus == null) {
      ref.invalidate(propositionsPraxisProvider);
      widget.onTraitee?.call();
    }
  }

  Future<void> _ecarter() async {
    if (_enCours) return;
    final PropositionPraxis x = widget.proposition;
    setState(() {
      _enCours = true;
      _refus = null;
      _retour = null;
    });
    ResultatProposition? resultat;
    String? refus;
    try {
      resultat = await avecDoubleVerification<ResultatProposition>(
        context,
        ref,
        () => ref
            .read(servicePropositionsPraxisProvider)
            .ecarter(
              id: x.id,
              cle: _cle,
              motif: _motifEcart.text.trim().isEmpty
                  ? null
                  : _motifEcart.text.trim(),
            ),
      );
      if (!resultat.fait) refus = phraseRefusProposition(resultat);
    } on Object catch (e) {
      refus = estRefusDeDroit(e)
          ? t.admin.praxis.doubleVerification
          : t.admin.praxis.propositions.generique;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _refus = refus;
      _retour = refus == null ? t.admin.praxis.propositions.ecartee : null;
    });
    if (refus == null) {
      ref.invalidate(propositionsPraxisProvider);
      widget.onTraitee?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PropositionPraxis x = widget.proposition;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final p = t.admin.praxis.propositions;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool planifie = x.geste == GestePrepare.planifierEntretien;
    final DateTime? debut = x.debut;
    final bool peutValider =
        !x.perimee && (!planifie || _participants.isNotEmpty);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(_nomGeste(x.geste), style: textes.titleSmall),
          Ecart.vSm,
          Text(p.note, style: attenue),
          Ecart.vXs,
          // Mot pour mot : le texte de Praxis n'est ni coupe ni reformule.
          SelectableText(x.texte, style: textes.bodyMedium),
          if (x.geste == GestePrepare.demanderComplement) ...<Widget>[
            Ecart.vMd,
            Text(p.elements, style: attenue),
            Ecart.vXs,
            Text(x.elements.join(', '), style: textes.bodyMedium),
            if (x.motif case final String motif) ...<Widget>[
              Ecart.vMd,
              Text(p.motif, style: attenue),
              Ecart.vXs,
              SelectableText(motif, style: textes.bodyMedium),
            ],
          ],
          if (planifie && debut != null) ...<Widget>[
            Ecart.vMd,
            Text(
              p.quand(
                date: dateCourteCandidature(jourChezMoi(debut)),
                heure: heureChezMoi(debut),
              ),
              style: textes.bodyMedium,
            ),
            if (x.dureeMinutes case final int minutes)
              Text(
                LibellesGroupe.insecable(p.duree(minutes: '$minutes')),
                style: attenue,
              ),
          ],
          if (planifie) ...<Widget>[
            Ecart.vMd,
            Text(p.participants, style: textes.titleSmall),
            Ecart.vXs,
            Text(p.participantsAide, style: attenue),
            Ecart.vSm,
            _Participants(
              proposition: x,
              candidatureId: widget.candidatureId,
              choisis: _participants,
              onChange: (Set<String> v) => setState(() {
                _participants
                  ..clear()
                  ..addAll(v);
              }),
            ),
          ],
          Ecart.vMd,
          Text(
            p.expire(date: dateCourteCandidature(jourChezMoi(x.expireLe))),
            style: attenue,
          ),
          if (x.perimee) ...<Widget>[
            Ecart.vMd,
            Text(
              p.perimee,
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (_refus != null) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                _refus!,
                style: textes.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          if (_retour != null) ...<Widget>[
            Ecart.vMd,
            LocalFeedback(message: _retour),
          ],
          Ecart.vMd,
          ChampEtiquete(
            libelle: p.motifEcart,
            controller: _motifEcart,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(300),
            ],
          ),
          Ecart.vLg,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              // Un bouton qui ne peut pas aboutir n'est pas rendu : le dossier
              // a change, ou aucun participant n'est choisi (la phrase le dit).
              if (peutValider)
                ActionPrincipale(
                  key: ClesPropositionsPraxis.valider(x.id),
                  libelle: p.valider,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                  enCours: _enCours,
                  onPress: () => unawaited(_valider()),
                ),
              ActionPrincipale(
                key: ClesPropositionsPraxis.ecarter(x.id),
                libelle: p.ecarter,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: () => unawaited(_ecarter()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Le personnel qu'on peut choisir pour l'entretien (la lecture existante
/// `personnel_pour_entretien`, du cote du dossier) : on coche, Praxis ne choisit
/// personne.
class _Participants extends ConsumerWidget {
  const _Participants({
    required this.proposition,
    required this.candidatureId,
    required this.choisis,
    required this.onChange,
  });

  final PropositionPraxis proposition;
  final String candidatureId;
  final Set<String> choisis;
  final ValueChanged<Set<String>> onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.admin.praxis.propositions;
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<PersonnelEntretien>> lu = ref.watch(
      personnelEntretienProvider(candidatureId),
    );
    if (lu.isLoading) return const Skeleton(hauteur: 48);
    if (lu.hasError) {
      return Text(p.participantsErreur, style: textes.bodyMedium);
    }
    final List<PersonnelEntretien> personnel =
        lu.value ?? const <PersonnelEntretien>[];
    if (personnel.isEmpty) {
      return Text(p.participantsAucun, style: textes.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final PersonnelEntretien x in personnel)
          Row(
            children: <Widget>[
              CaseACocher(
                key: ClesPropositionsPraxis.participant(
                  proposition.id,
                  x.profilId,
                ),
                valeur: choisis.contains(x.profilId),
                libelle: '${x.prenom} ${x.nom}'.trim(),
                onChange: (bool v) {
                  final Set<String> suite = <String>{...choisis};
                  if (v) {
                    suite.add(x.profilId);
                  } else {
                    suite.remove(x.profilId);
                  }
                  onChange(suite);
                },
              ),
              Expanded(
                child: Text(
                  '${x.prenom} ${x.nom}'.trim(),
                  style: textes.bodyMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
