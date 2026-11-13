// FUSEAUX, partie client : LE composant d'heure double (PLAN-LOTS §12, « un
// seul composant d'heure double, lu partout »).
//
// La sienne d'abord, puis celle de chaque interlocuteur :
//   famille : « Chez vous 08:00 Paris » puis « Chez Sayyid Karim 06:00
//   Abidjan » (titre enregistre, jamais deduit, et le drapeau du pays) ;
//   enseignant : « Chez vous 06:00 Abidjan » puis « 2 familles 08:00 Paris »,
//   jamais un nom ;
//   direction : les deux.
// Une heure qu'on ne sait pas rendre (apres un changement d'heure que le
// serveur n'a pas decrit) dit « Heure a confirmer », jamais une heure fausse.
// Sans lecture des interlocuteurs (chargement, panne, classe sans droit), la
// seconde ligne retombe sur l'heure de la classe rendue par le serveur, sous
// son vrai nom : « Heure de la classe », jamais « Chez Sayyid X ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import '../i18n/villes_fuseau.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/pastille_etat_seance.dart';
import '../widgets/pays_enseignant.dart';
import 'fuseaux_interlocuteurs.dart';
import 'mon_horloge.dart';
import 'port_interlocuteurs.dart';
import 'session_clock_vm.dart';

/// Une ligne d'heure : qui, quelle heure, ou, et le pays de l'enseignant.
@immutable
class LigneHeure {
  /// Cree la ligne.
  const LigneHeure({
    required this.libelle,
    required this.heure,
    required this.ville,
    this.pays,
    this.fuseau,
  });

  /// L'identifiant IANA de la ligne, quand on le connait : sert a ne jamais
  /// montrer deux fois la meme heure de La Mecque.
  final String? fuseau;

  /// « Chez vous », « Chez Sayyid Karim », « 2 familles ».
  final String libelle;

  /// « 08:00 », ou `null` quand l'heure n'est pas sure.
  final String? heure;

  /// La ville du fuseau, dans la langue de l'interface.
  final String ville;

  /// Le pays de l'enseignant (code ISO ou nom), sinon `null`.
  final String? pays;
}

/// Le nom de l'enseignant precede de son titre enregistre, ou ce qui en est
/// connu.
String _nommeEnseignant(EnseignantInterlocuteur e) {
  final String? titre = switch (e.titre) {
    TitreInterlocuteur.sayyid => LibellesGroupe.sayyid,
    TitreInterlocuteur.sayyida => LibellesGroupe.sayyida,
    null => null,
  };
  return <String>[?titre, ?e.prenom].join(' ');
}

/// « Heure de La Mecque » quand le fuseau de la classe est celui de l'academie
/// (toute classe l'est depuis HORLOGE-ET-LIEU), sinon « Heure de la classe »
/// (une classe pas encore convertie : jamais un faux nom).
String libelleHeureDeLaClasse(String? fuseauClasse) {
  final String? academie = horlogeAcademie?.fuseau;
  return academie != null && fuseauClasse == academie
      ? t.tc.groupe.horloges.heureMecque
      : LibellesGroupe.heureGroupe;
}

/// Les lignes des interlocuteurs a l'instant [instantUtc], sans celles qui
/// donneraient la meme heure que [moi], puis, en second et discretement,
/// « Heure de La Mecque » (l'horloge de l'academie, H2) quand elle differe de
/// celle de la personne et qu'aucune ligne ne la donne deja.
List<LigneHeure> lignesInterlocuteurs(
  InterlocuteursClasse lus,
  DateTime instantUtc,
) {
  final FuseauVu? moi = lus.moi;
  bool memeQueMoi(FuseauVu f) => moi != null && f.memeHeureQue(moi);
  final List<LigneHeure> lignes = <LigneHeure>[];
  final EnseignantInterlocuteur? e = lus.enseignant;
  final FuseauVu? fe = e?.fuseau;
  if (e != null && fe != null && !memeQueMoi(fe)) {
    final String nomme = _nommeEnseignant(e);
    lignes.add(
      LigneHeure(
        libelle: e.fuseauDeLaClasse
            ? libelleHeureDeLaClasse(fe.fuseau)
            : nomme.isEmpty
            ? t.tc.groupe.horloges.chezEnseignantAnonyme
            : LibellesGroupe.chezEnseignant(nomme),
        heure: fe.heureA(instantUtc),
        ville: villeDuFuseauLibelle(fe.fuseau),
        pays: e.fuseauDeLaClasse ? null : e.pays,
        fuseau: fe.fuseau,
      ),
    );
  }
  for (final FamillesDuFuseau g in lus.familles) {
    final FuseauVu? f = g.fuseau;
    if (f == null || memeQueMoi(f)) continue;
    lignes.add(
      LigneHeure(
        libelle: t.tc.groupe.horloges.familles(n: g.familles),
        heure: f.heureA(instantUtc),
        ville: villeDuFuseauLibelle(f.fuseau),
        fuseau: f.fuseau,
      ),
    );
  }
  final LigneHeure? mecque = _ligneMecque(
    instantUtc,
    moi: moi,
    dejaDonnees: lignes,
  );
  if (mecque != null) lignes.add(mecque);
  return lignes;
}

/// La ligne « Heure de La Mecque » a l'instant [instantUtc], ou `null` : pas
/// d'horloge d'academie lue, la personne vit deja a l'heure de l'academie, une
/// ligne de [dejaDonnees] la donne deja, ou l'heure n'est pas sure.
LigneHeure? _ligneMecque(
  DateTime instantUtc, {
  required FuseauVu? moi,
  required List<LigneHeure> dejaDonnees,
}) {
  final FuseauVu? a = horlogeAcademie;
  if (a == null) return null;
  if (moi != null && a.memeHeureQue(moi)) return null;
  if (dejaDonnees.any((LigneHeure l) => l.fuseau == a.fuseau)) return null;
  final String? heure = a.heureA(instantUtc);
  if (heure == null) return null;
  return LigneHeure(
    libelle: t.tc.groupe.horloges.heureMecque,
    heure: heure,
    ville: '',
    fuseau: a.fuseau,
  );
}

/// L'heure d'une seance (ou de maintenant) pour soi et pour chaque
/// interlocuteur de la classe [groupeId]. Un appel serveur par classe,
/// partage par toutes les instances ([interlocuteursClasseProvider]).
class HeureDouble extends StatelessWidget {
  /// Cree le bloc pour l'instant [instantUtc] (le debut d'une seance).
  const HeureDouble({
    required this.groupeId,
    required this.instantUtc,
    super.key,
    this.moi,
    this.classe,
    this.tutoiement = false,
    this.annulee = false,
    this.avecLaSienne = true,
  });

  /// Faux quand l'ecran affiche deja sa propre heure en grand (bloc seance
  /// de l'Accueil) : seules les lignes des interlocuteurs.
  final bool avecLaSienne;

  /// La classe dont on lit les interlocuteurs.
  final String groupeId;

  /// L'instant UTC dont on donne l'heure.
  final DateTime instantUtc;

  /// Sa propre heure deja rendue par le serveur (`horloge_seance`) ; a
  /// defaut, celle du fuseau lu ([InterlocuteursClasse.moi]).
  final HorlogeAffichee? moi;

  /// L'heure de la classe deja rendue, pour la seconde ligne tant que les
  /// interlocuteurs ne sont pas lus.
  final HorlogeAffichee? classe;

  /// « Ton heure » pour l'eleve en Interface guidee.
  final bool tutoiement;

  /// Vrai quand la seance est annulee : heures barrees.
  final bool annulee;

  /// Cle du bloc.
  static const Key cle = ValueKey<String>('heure-double');

  @override
  Widget build(BuildContext context) {
    // Une carte posee hors de toute ProviderScope (un test de composant) garde
    // l'heure de la classe rendue par le serveur : jamais une panne.
    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return _corps(context, null);
    }
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? _) => _corps(
        context,
        ref.watch(interlocuteursClasseProvider(groupeId)).value,
      ),
    );
  }

  Widget _corps(BuildContext context, InterlocuteursClasse? lus) {
    final String libelleMoi = tutoiement
        ? t.accessibilite.tutoiement.tonHeure
        : t.tc.groupe.horloges.chezVous;
    final FuseauVu? fm = lus?.moi;
    final LigneHeure? premiere = moi != null
        ? LigneHeure(
            libelle: libelleMoi,
            heure: moi!.heureLocaleRendue,
            ville: moi!.libelleVille,
          )
        : fm == null
        ? null
        : LigneHeure(
            libelle: libelleMoi,
            heure: fm.heureA(instantUtc),
            ville: villeDuFuseauLibelle(fm.fuseau),
          );
    final List<LigneHeure> autres = lus != null
        ? lignesInterlocuteurs(lus, instantUtc)
        : <LigneHeure>[
            if (classe != null && classe!.fuseauIana != moi?.fuseauIana)
              LigneHeure(
                libelle: libelleHeureDeLaClasse(classe!.fuseauIana),
                heure: classe!.heureLocaleRendue,
                ville: classe!.libelleVille,
                fuseau: classe!.fuseauIana,
              ),
          ];
    if (lus == null) {
      final LigneHeure? mecque = _ligneMecque(
        instantUtc,
        moi: null,
        dejaDonnees: autres,
      );
      // Sans fuseau de profil lu, la seule comparaison possible est celle du
      // fuseau de la sienne rendue par le serveur.
      if (mecque != null &&
          moi?.fuseauIana != horlogeAcademie?.fuseau &&
          !(horlogeAcademie != null &&
              fm != null &&
              fm.memeHeureQue(horlogeAcademie!))) {
        autres.add(mecque);
      }
    }
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        if (avecLaSienne && premiere != null)
          _Ligne(premiere, annulee: annulee),
        for (final LigneHeure l in autres)
          _Ligne(
            l,
            annulee: annulee,
            annoncer: !avecLaSienne && l == autres.first,
          ),
      ],
    );
  }
}

/// L'heure courante pour soi et pour chaque interlocuteur, qui avance a la
/// minute. L'instant vient du serveur (lu avec les interlocuteurs), avance du
/// temps ecoule sur l'appareil ; le chiffre qui change passe en fondu, sans
/// mouvement si l'appareil demande moins d'animations.
class HeureCouranteDouble extends StatelessWidget {
  /// Cree la ligne de l'heure courante de la classe [groupeId].
  const HeureCouranteDouble({
    required this.groupeId,
    super.key,
    this.horlogeAppareil = DateTime.now,
  });

  /// La classe.
  final String groupeId;

  /// L'horloge de l'appareil, **pour mesurer un ecoulement seulement**.
  final DateTime Function() horlogeAppareil;

  /// Cle du bloc.
  static const Key cle = ValueKey<String>('heure-courante-double');

  @override
  Widget build(BuildContext context) {
    // Hors ProviderScope (une carte posee seule) : rien a lire, rien a
    // montrer.
    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return const SizedBox.shrink();
    }
    return _HeureCourante(groupeId: groupeId, horlogeAppareil: horlogeAppareil);
  }
}

class _HeureCourante extends ConsumerStatefulWidget {
  const _HeureCourante({required this.groupeId, required this.horlogeAppareil});

  final String groupeId;
  final DateTime Function() horlogeAppareil;

  @override
  ConsumerState<_HeureCourante> createState() => _HeureCouranteState();
}

class _HeureCouranteState extends ConsumerState<_HeureCourante> {
  Timer? _minuteur;
  InterlocuteursClasse? _lus;
  DateTime? _appareilALaLecture;

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  DateTime _maintenant(InterlocuteursClasse lus) {
    if (!identical(lus, _lus) || _appareilALaLecture == null) {
      _lus = lus;
      _appareilALaLecture = widget.horlogeAppareil();
    }
    return lus.maintenantServeur.add(
      widget.horlogeAppareil().difference(_appareilALaLecture!),
    );
  }

  void _armer(DateTime maintenant) {
    _minuteur?.cancel();
    final DateTime minute = DateTime.utc(
      maintenant.year,
      maintenant.month,
      maintenant.day,
      maintenant.hour,
      maintenant.minute,
    ).add(const Duration(minutes: 1));
    _minuteur = Timer(minute.difference(maintenant), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final InterlocuteursClasse? lus = ref
        .watch(interlocuteursClasseProvider(widget.groupeId))
        .value;
    final FuseauVu? moi = lus?.moi;
    if (lus == null || moi == null) return const SizedBox.shrink();
    final List<LigneHeure> autres = lignesInterlocuteurs(
      lus,
      lus.maintenantServeur,
    );
    // Une seule heure, la sienne : rien de plus a montrer qu'une horloge.
    if (autres.isEmpty) return const SizedBox.shrink();
    final DateTime maintenant = _maintenant(lus);
    _armer(maintenant);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // Son ecart au-dessus vient avec elle : absente, elle ne laisse aucun
    // trou dans la carte.
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        key: HeureCouranteDouble.cle,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(
            t.tc.groupe.horloges.enCeMoment,
            style: palette.inkMuted.applyTo(
              textes.labelMedium ?? const TextStyle(),
            ),
          ),
          _Ligne(
            LigneHeure(
              libelle: t.tc.groupe.horloges.chezVous,
              heure: moi.heureA(maintenant),
              ville: villeDuFuseauLibelle(moi.fuseau),
            ),
            vivante: true,
          ),
          for (final LigneHeure l in lignesInterlocuteurs(lus, maintenant))
            _Ligne(l, vivante: true),
        ],
      ),
    );
  }
}

/// Un libelle et son heure, lus d'un bloc ; en paire qui s'empile a 320 de
/// large et a 200 % de texte, comme les heures de la carte de seance.
class _Ligne extends StatelessWidget {
  const _Ligne(
    this.ligne, {
    this.annulee = false,
    this.annoncer = true,
    this.vivante = false,
  });

  final LigneHeure ligne;
  final bool annulee;
  final bool annoncer;

  /// Vrai pour l'heure courante : le chiffre qui change passe en fondu.
  final bool vivante;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle styleLibelle = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String valeur = ligne.heure == null
        ? '${t.tc.groupe.horloges.aConfirmer} ${ligne.ville}'.trim()
        : ligne.ville.isEmpty
        ? ligne.heure!
        : LibellesGroupe.heureEtVille(heure: ligne.heure!, ville: ligne.ville);
    final Widget heure = TexteHeureSeance(
      key: vivante ? ValueKey<String>(valeur) : null,
      heure: valeur,
      annulee: annulee,
      annoncer: annoncer,
      style: AppTypography.tabulaire(textes.titleSmall ?? const TextStyle()),
    );
    final String? pays = ligne.pays;
    return MergeSemantics(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Un intitule francais ponctue reste dans son sens en arabe
              // (DUREE-INSECABLE-4, reprise 2).
              Text(
                isolerDansInterface(ligne.libelle, Directionality.of(context)),
                style: styleLibelle,
              ),
              if (pays != null)
                PaysEnseignant.codeValide(pays) != null
                    ? PaysEnseignant.parCode(codeIso: pays, style: styleLibelle)
                    : PaysEnseignant(pays: pays, style: styleLibelle),
            ],
          ),
          if (vivante)
            AnimatedSwitcher(
              duration: AppMouvement.duree(context, AppMouvement.apparition),
              child: heure,
            )
          else
            heure,
        ],
      ),
    );
  }
}
