import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_partage_pedagogique.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart' show horsLigneProvider;
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../classe_tuteur/contexte_classe.dart' show nomClasseInsecable;
import '../compte/carte_rubriques.dart';
import '../suivi_foyer/bloc_compte_rendu.dart';
import '../suivi_foyer/filtres_historique.dart' show dateCourte, heureMinute;
import 'partage_commun.dart';

/// Les comptes rendus d'un eleve dans une classe.
final comptesRendusEleveProvider = FutureProvider.autoDispose
    .family<List<LigneCompteRendu>, ({String classeId, String eleveId})>((
      Ref ref,
      ({String classeId, String eleveId}) cle,
    ) {
      ref.watch(sessionProvider.select((s) => (s.profileId, s.role)));
      return ref
          .watch(portPartagePedagogiqueProvider)
          .comptesRendusEleve(classeId: cle.classeId, eleveId: cle.eleveId);
    });

/// L'apercu familial d'un compte rendu (une seance, un eleve).
final apercuFamilialProvider = FutureProvider.autoDispose
    .family<ApercuAdmin, CleCompteRendu>((Ref ref, CleCompteRendu cle) {
      ref.watch(sessionProvider.select((s) => (s.profileId, s.role)));
      return ref
          .watch(portPartagePedagogiqueProvider)
          .apercuFamilial(seanceId: cle.seanceId, eleveId: cle.eleveId);
    });

/// Ouvre la liste des comptes rendus d'un eleve, dans le contexte de la classe.
void ouvrirComptesRendusEleve(
  BuildContext context, {
  required String classeId,
  required String eleveId,
  required String prenom,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.partage.comptesRendusTitre(prenom: prenom),
    constructeur: (BuildContext contexte) =>
        FeuilleComptesRendusEleve(classeId: classeId, eleveId: eleveId),
  );
}

/// Ouvre l'apercu familial et le partage manuel d'**un** compte rendu.
void ouvrirApercuFamilial(
  BuildContext context, {
  required String seanceId,
  required String eleveId,
}) {
  AppBottomSheet.ouvrir<void>(
    context,
    titre: t.admin.groupes.partage.apercuTitre,
    constructeur: (BuildContext contexte) =>
        FeuilleApercuFamilial(seanceId: seanceId, eleveId: eleveId),
  );
}

String _etatDiffusion(EtatDiffusion etat) {
  final l = t.admin.groupes.partage;
  return switch (etat) {
    EtatDiffusion.nonValide => l.etatNonValide,
    EtatDiffusion.confirmeNonPartage => l.etatConfirmeNonPartage,
    EtatDiffusion.partageAuto => l.etatPartageAuto,
    EtatDiffusion.partageManuel => l.etatPartageManuel,
    EtatDiffusion.revoque => l.etatRevoque,
    EtatDiffusion.corrigeApresPartageManuel => l.etatCorrige,
  };
}

TonEtat _tonDiffusion(EtatDiffusion etat) => switch (etat) {
  EtatDiffusion.partageAuto || EtatDiffusion.partageManuel => TonEtat.succes,
  EtatDiffusion.corrigeApresPartageManuel => TonEtat.avertissement,
  EtatDiffusion.revoque => TonEtat.alerte,
  _ => TonEtat.neutre,
};

String _quand(DateTime quand) => '${dateCourte(quand)} ${heureMinute(quand)}';

/// La liste des comptes rendus d'un eleve (les seances, du plus recent au plus
/// ancien). **Point d'entree provisoire d'ADM-PED-APR-03** : aucune lecture
/// administrative d'un cahier confirme n'existe ailleurs (voir
/// `docs/current/PED-APRES/AUDIT_ETAPE0.md`, section 6).
class FeuilleComptesRendusEleve extends ConsumerWidget {
  /// Cree la feuille.
  const FeuilleComptesRendusEleve({
    required this.classeId,
    required this.eleveId,
    super.key,
  });

  /// La classe.
  final String classeId;

  /// L'eleve.
  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.groupes.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final cle = (classeId: classeId, eleveId: eleveId);
    final AsyncValue<List<LigneCompteRendu>> lecture = ref.watch(
      comptesRendusEleveProvider(cle),
    );
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    if (lecture.hasValue && !lecture.hasError) {
      final List<LigneCompteRendu> lignes = lecture.requireValue;
      if (lignes.isEmpty) {
        return phrase(l.aucunCompteRendu);
      }
      return GroupeReglages(
        lignes: <LigneRubrique>[
          for (final LigneCompteRendu c in lignes)
            LigneRubrique(
              libelle: dateCourte(c.seanceLe),
              legende: _etatDiffusion(c.etat),
              pastille: StatusPill(
                libelle: _etatDiffusion(c.etat),
                ton: _tonDiffusion(c.etat),
              ),
              onPress: () => ouvrirApercuFamilial(
                context,
                seanceId: c.seanceId,
                eleveId: eleveId,
              ),
            ),
        ],
      );
    }
    if (lecture.hasError) {
      final Object erreur = lecture.error!;
      final bool definitif =
          erreur is CapaciteIndisponible || erreur is PermissionInsuffisante;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          phrase(switch (erreur) {
            CapaciteIndisponible() => l.indisponible,
            PermissionInsuffisante() => l.refuse,
            _ => l.illisible,
          }),
          if (!definitif) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.commun.reessayer,
              alignerEnDebut: true,
              onPress: () => ref.invalidate(comptesRendusEleveProvider(cle)),
            ),
          ],
        ],
      );
    }
    return const Skeleton.liste(lignes: 3);
  }
}

/// ADM-PED-APR-03 : l'apercu **exact** du compte rendu que la famille recevra,
/// et la decision de la direction pour **un seul eleve, une seule seance**.
///
/// - Le rendu de l'apercu est [CarteCompteRendu], celui-la meme du detail du
///   tuteur : memes intitules, meme ordre, memes exclusions. Aucune note
///   interne n'existe dans le type : elle ne peut pas s'y glisser.
/// - **Une seule action a la fois**, la seule coherente avec l'etat : « Publier
///   pour la famille » ou « Revoquer l'acces », jamais les deux.
/// - Un seul envoi a la fois ; le succes n'est annonce qu'apres la reponse du
///   serveur ; un echec garde l'etat precedent ; un conflit relit et le dit.
/// - Aucun historique n'est invente : il n'apparait que si la source le donne.
class FeuilleApercuFamilial extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleApercuFamilial({
    required this.seanceId,
    required this.eleveId,
    super.key,
  });

  /// La seance.
  final String seanceId;

  /// L'eleve.
  final String eleveId;

  @override
  ConsumerState<FeuilleApercuFamilial> createState() =>
      _FeuilleApercuFamilialEtat();
}

class _FeuilleApercuFamilialEtat extends ConsumerState<FeuilleApercuFamilial> {
  bool _envoi = false;
  String? _retour;
  bool _retourDefinitif = false;
  int _essai = 0;

  CleCompteRendu get _cle =>
      (seanceId: widget.seanceId, eleveId: widget.eleveId);

  void _dire(String message, {required bool definitif}) {
    setState(() {
      _retour = message;
      _retourDefinitif = definitif;
      _essai++;
    });
  }

  Future<void> _decider(ApercuAdmin a, {required bool publier}) async {
    if (_envoi) {
      return;
    }
    final l = t.admin.groupes.partage;
    if (ref.read(horsLigneProvider).value ?? false) {
      _dire(l.horsLigne, definitif: true);
      return;
    }
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: publier
          ? l.confirmerPublier(prenom: a.elevePrenom)
          : l.confirmerRevoquer,
      consequence: publier ? l.consequencePublier : l.consequenceRevoquer,
      libelleConfirmer: publier ? l.publier : l.revoquer,
    );
    if (!confirme || !mounted || _envoi) {
      return;
    }
    setState(() {
      _envoi = true;
      _retour = null;
    });
    ResultatPartage resultat = ResultatPartage.ok;
    try {
      final port = ref.read(portPartagePedagogiqueProvider);
      if (publier) {
        await port.publier(
          seanceId: a.seanceId,
          eleveId: a.eleveId,
          versionAttendue: a.version,
          cleIdempotence: nouvelleCleGeste(),
        );
      } else {
        await port.revoquer(
          seanceId: a.seanceId,
          eleveId: a.eleveId,
          versionAttendue: a.version,
          cleIdempotence: nouvelleCleGeste(),
        );
      }
    } on Object catch (erreur) {
      resultat = resultatDe(erreur);
    }
    if (!mounted) {
      return;
    }
    // Relire dans tous les cas : l'etat affiche est celui du serveur.
    ref.invalidate(apercuFamilialProvider(_cle));
    setState(() => _envoi = false);
    final String? phrase = phraseDe(resultat);
    if (phrase == null) {
      _dire(publier ? l.publie : l.revoque, definitif: true);
    } else if (resultat == ResultatPartage.conflit) {
      _dire(l.conflitApercu, definitif: true);
    } else {
      _dire(phrase, definitif: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.groupes.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<ApercuAdmin> lecture = ref.watch(
      apercuFamilialProvider(_cle),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    if (lecture.hasError && !lecture.hasValue) {
      final Object erreur = lecture.error!;
      final bool definitif =
          erreur is CapaciteIndisponible || erreur is PermissionInsuffisante;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          phrase(switch (erreur) {
            CapaciteIndisponible() => l.indisponible,
            PermissionInsuffisante() => l.refuse,
            _ => horsLigne ? l.horsLigne : l.illisible,
          }),
          if (!definitif) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.commun.reessayer,
              alignerEnDebut: true,
              onPress: () => ref.invalidate(apercuFamilialProvider(_cle)),
            ),
          ],
        ],
      );
    }
    if (!lecture.hasValue) {
      return const Skeleton.liste(lignes: 4);
    }
    final ApercuAdmin a = lecture.requireValue;
    final bool revocable = a.revocable;
    final bool publiable = a.publiable;
    final String? raison = revocable || publiable
        ? null
        : (a.etat == EtatDiffusion.nonValide
              ? l.etatNonValide
              : l.nonPubliable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            l.entete(
              eleve: a.elevePrenom,
              classe: nomClasseInsecable(a.classeLibelle),
              date: dateCourte(a.seanceLe),
            ),
            style: textes.titleMedium,
          ),
        ),
        Ecart.vMd,
        SurfaceCarte(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (a.enseignant != null)
                  LigneCleValeur(cle: l.enseignant, valeur: a.enseignant!),
                LigneCleValeur(
                  cle: l.regleEffective,
                  valeur: a.regleEffective ? l.regleActive : l.regleInactive,
                ),
              ],
            ),
          ),
        ),
        Ecart.vLg,
        phrase(l.apercuAide),
        Ecart.vMd,
        CarteCompteRendu(
          compteRendu: a.apercu.aDuContenu
              ? a.apercu
              : const CompteRenduFamille(etat: EtatCompteRendu.aucunChamp),
        ),
        Ecart.vMd,
        phrase(l.notesInternes),
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(l.diffusion, style: textes.titleMedium),
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: _etatDiffusion(a.etat),
            ton: _tonDiffusion(a.etat),
          ),
        ),
        if (raison != null && a.etat != EtatDiffusion.nonValide) ...<Widget>[
          Ecart.vSm,
          phrase(raison),
        ],
        Ecart.vLg,
        // Une seule action, la seule coherente avec l'etat. Aucune n'est
        // rendue quand rien ne peut aboutir : la phrase explique la limite.
        if (publiable)
          ActionPrincipale(
            libelle: l.publier,
            enCours: _envoi,
            onPress: () => _decider(a, publier: true),
          )
        else if (revocable)
          ActionPrincipale(
            libelle: l.revoquer,
            niveau: NiveauAction.destructive,
            enCours: _envoi,
            onPress: () => _decider(a, publier: false),
          ),
        if (publiable || revocable) ...<Widget>[Ecart.vSm, phrase(l.portee)],
        if (horsLigne) ...<Widget>[Ecart.vSm, phrase(l.horsLigne)],
        Ecart.vSm,
        LocalFeedback(
          key: ValueKey<int>(_essai),
          message: _retour,
          persistant: _retourDefinitif,
        ),
        if (a.historique != null && a.historique!.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          Semantics(
            header: true,
            child: Text(l.historique, style: textes.titleMedium),
          ),
          Ecart.vSm,
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final ActionPartage h in a.historique!)
                LigneRubrique(
                  libelle: switch (h.type) {
                    'publication' => l.actionPublication,
                    'revocation' => l.actionRevocation,
                    _ => l.actionAuto,
                  },
                  legende: '${_quand(h.quand)} · ${h.auteur ?? l.parSysteme}',
                ),
            ],
          ),
        ],
        if (a.misAJourLe != null) ...<Widget>[
          Ecart.vMd,
          phrase(l.miseAJour(date: _quand(a.misAJourLe!))),
        ],
      ],
    );
  }
}
