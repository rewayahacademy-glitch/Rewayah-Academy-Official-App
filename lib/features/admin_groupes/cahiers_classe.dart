import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_partage_pedagogique.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart' show horsLigneProvider;
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/carte_rubriques.dart';
import '../suivi_foyer/filtres_historique.dart' show dateCourte, heureMinute;
import 'apercu_familial.dart';

/// Le cahier brut d'un eleve pour une seance, lu par la direction.
///
/// `autoDispose` et lie a la session : aucun cahier ne survit a la sortie de la
/// feuille ni a un changement de compte.
final cahierAdminProvider = FutureProvider.autoDispose
    .family<CahierAdmin, ({String seanceId, String eleveId})>((
      Ref ref,
      ({String seanceId, String eleveId}) cle,
    ) {
      ref.watch(sessionProvider.select((s) => (s.profileId, s.role)));
      return ref
          .watch(portPartagePedagogiqueProvider)
          .lireCahierAdmin(seanceId: cle.seanceId, eleveId: cle.eleveId);
    });

/// ADM-CAHIER-LECTURE : l'acces aux cahiers d'une classe, depuis la fiche de la
/// classe (inspecteur de bureau et feuille mobile), **sans nouvelle route**.
class LienCahiersClasse extends StatelessWidget {
  /// Cree le lien.
  const LienCahiersClasse({required this.classeId, super.key});

  /// La classe.
  final String classeId;

  @override
  Widget build(BuildContext context) => LienFleche(
    libelle: t.admin.groupes.cahiers.lien,
    alignerEnDebut: true,
    onPress: () => AppBottomSheet.ouvrir<void>(
      context,
      titre: t.admin.groupes.cahiers.titre,
      constructeur: (BuildContext contexte) =>
          FeuilleCahiersClasse(classeId: classeId),
    ),
  );
}

/// La phrase d'une erreur de lecture, sans cause technique.
String _phraseErreur(Object erreur, {required bool horsLigne}) {
  final p = t.admin.groupes.partage;
  return switch (erreur) {
    CapaciteIndisponible() => p.indisponible,
    PermissionInsuffisante() => p.refuse,
    _ => horsLigne ? p.horsLigne : p.illisible,
  };
}

bool _definitive(Object erreur) =>
    erreur is CapaciteIndisponible || erreur is PermissionInsuffisante;

/// La liste des cahiers d'une classe : paginee et filtree cote serveur, lecture
/// seule. Etats : chargement, contenu, vide, erreur, hors ligne, indisponible,
/// refuse.
class FeuilleCahiersClasse extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleCahiersClasse({required this.classeId, super.key});

  /// La classe.
  final String classeId;

  @override
  ConsumerState<FeuilleCahiersClasse> createState() =>
      _FeuilleCahiersClasseEtat();
}

class _FeuilleCahiersClasseEtat extends ConsumerState<FeuilleCahiersClasse> {
  final Map<String, LigneCahierClasse> _lignes = <String, LigneCahierClasse>{};
  EtatDiffusion? _filtre;
  Object? _erreur;
  bool _chargement = true;
  bool _plus = false;
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_lire());
  }

  String _cle(LigneCahierClasse l) => '${l.seanceId}/${l.eleveId}';

  Future<void> _lire() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final PageCahiersClasse p = await ref
          .read(portPartagePedagogiqueProvider)
          .comptesRendusClasse(classeId: widget.classeId, filtreEtat: _filtre);
      if (!mounted) {
        return;
      }
      setState(() {
        _lignes
          ..clear()
          ..addEntries(
            p.lignes.map((LigneCahierClasse l) => MapEntry(_cle(l), l)),
          );
        _total = p.total;
        _page = 1;
        _chargement = false;
      });
    } on Object catch (erreur) {
      if (mounted) {
        setState(() {
          _erreur = erreur;
          _chargement = false;
        });
      }
    }
  }

  Future<void> _lirePlus() async {
    if (_plus) {
      return;
    }
    setState(() => _plus = true);
    try {
      final PageCahiersClasse p = await ref
          .read(portPartagePedagogiqueProvider)
          .comptesRendusClasse(
            classeId: widget.classeId,
            page: _page + 1,
            filtreEtat: _filtre,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        for (final LigneCahierClasse l in p.lignes) {
          _lignes[_cle(l)] = l;
        }
        _page++;
        _plus = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _plus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.groupes.cahiers;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    final Widget corps;
    if (_chargement && _lignes.isEmpty) {
      corps = const Skeleton.liste(lignes: 4);
    } else if (_erreur != null) {
      final Object erreur = _erreur!;
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          phrase(_phraseErreur(erreur, horsLigne: horsLigne)),
          if (!_definitive(erreur)) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.commun.reessayer,
              alignerEnDebut: true,
              onPress: () => unawaited(_lire()),
            ),
          ],
        ],
      );
    } else if (_lignes.isEmpty) {
      corps = phrase(l.vide);
    } else {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final LigneCahierClasse c in _lignes.values)
                LigneRubrique(
                  libelle: c.elevePrenom,
                  legende: l.seanceDu(date: dateCourte(c.seanceLe)),
                  pastille: StatusPill(
                    libelle: libelleEtatDiffusion(c.etat),
                    ton: tonEtatDiffusion(c.etat),
                  ),
                  onPress: () => AppBottomSheet.ouvrir<void>(
                    context,
                    titre: l.titreCahier(dePrenom: deDevant(c.elevePrenom)),
                    constructeur: (BuildContext contexte) => FeuilleCahierAdmin(
                      seanceId: c.seanceId,
                      eleveId: c.eleveId,
                    ),
                  ),
                ),
            ],
          ),
          if (_lignes.length < _total) ...<Widget>[
            Ecart.vMd,
            LienFleche(
              libelle: l.plus,
              alignerEnDebut: true,
              onPress: _plus ? () {} : () => unawaited(_lirePlus()),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        phrase(l.aide),
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MenuFiltre<EtatDiffusion>(
            libelle: l.filtre,
            valeur: _filtre,
            entrees: <EntreeFiltre<EtatDiffusion>>[
              EntreeFiltre<EtatDiffusion>(valeur: null, libelle: l.filtreTous),
              for (final EtatDiffusion e in EtatDiffusion.values)
                EntreeFiltre<EtatDiffusion>(
                  valeur: e,
                  libelle: libelleEtatDiffusion(e),
                ),
            ],
            onChoix: (EtatDiffusion? e) {
              _filtre = e;
              unawaited(_lire());
            },
          ),
        ),
        Ecart.vLg,
        corps,
      ],
    );
  }
}

/// Le cahier d'un eleve pour une seance, **en lecture seule** : l'evaluation de
/// l'enseignant, puis les details internes sous l'etiquette « Interne, jamais
/// montre a la famille ». Aucune modification, aucun bouton plein. L'apercu
/// familial et la decision de publier ou revoquer sont ceux d'ADM-PED-APR-03.
class FeuilleCahierAdmin extends ConsumerWidget {
  /// Cree la feuille.
  const FeuilleCahierAdmin({
    required this.seanceId,
    required this.eleveId,
    super.key,
  });

  /// La seance.
  final String seanceId;

  /// L'eleve.
  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = t.admin.groupes.cahiers;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final cle = (seanceId: seanceId, eleveId: eleveId);
    final AsyncValue<CahierAdmin> lecture = ref.watch(cahierAdminProvider(cle));
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    Widget phrase(String texte) =>
        Text(texte, style: palette.inkMuted.applyTo(textes.bodyMedium!));

    if (lecture.hasError && !lecture.hasValue) {
      final Object erreur = lecture.error!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          phrase(_phraseErreur(erreur, horsLigne: horsLigne)),
          if (!_definitive(erreur)) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.commun.reessayer,
              alignerEnDebut: true,
              onPress: () => ref.invalidate(cahierAdminProvider(cle)),
            ),
          ],
        ],
      );
    }
    if (!lecture.hasValue) {
      return const Skeleton.liste(lignes: 4);
    }
    final CahierAdmin c = lecture.requireValue;

    Widget rubriques(List<RubriqueInterne> liste) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final RubriqueInterne r in liste)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    r.libelle,
                    style: palette.inkMuted.applyTo(textes.bodySmall!),
                  ),
                  Ecart.vXs,
                  Text(
                    r.texte,
                    style: palette.inkStrong.applyTo(textes.bodyMedium!),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(libelle: l.lectureSeule, ton: TonEtat.neutre),
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
                LigneCleValeur(
                  cle: t.historique.seance.date,
                  valeur:
                      '${dateCourte(c.seanceLe)} ${heureMinute(c.seanceLe)}',
                ),
                if (c.enseignant != null)
                  LigneCleValeur(cle: l.enseignant, valeur: c.enseignant!),
              ],
            ),
          ),
        ),
        if (!c.confirme) ...<Widget>[Ecart.vMd, phrase(l.nonValide)],
        if (c.corrigeLe != null) ...<Widget>[
          Ecart.vSm,
          phrase(l.corrigeLe(date: dateCourte(c.corrigeLe!))),
        ],
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(l.evaluation, style: textes.titleMedium),
        ),
        Ecart.vSm,
        if (c.evaluation.isEmpty)
          phrase(l.aucuneEvaluation)
        else
          rubriques(c.evaluation),
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(l.detailsInternes, style: textes.titleMedium),
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(libelle: l.interne, ton: TonEtat.avertissement),
        ),
        Ecart.vMd,
        if (c.detailsInternes.isEmpty)
          phrase(l.aucunInterne)
        else
          rubriques(c.detailsInternes),
        Ecart.vMd,
        LienFleche(
          libelle: l.apercu,
          alignerEnDebut: true,
          onPress: () => ouvrirApercuFamilial(
            context,
            seanceId: seanceId,
            eleveId: eleveId,
          ),
        ),
      ],
    );
  }
}
