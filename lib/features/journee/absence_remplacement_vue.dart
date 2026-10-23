/// Les vues d'`ENS-13` (absence sur une seance) et d'`ENS-13B` (offre de
/// remplacement), posees dans Aujourd'hui (EN-8).
///
/// - La feuille d'absence est elle-meme l'etape de relecture (UX_REVIEW_04
///   ligne 14, a) : la seance rappelee en haut, la notice, puis « Annuler » au
///   bord de debut et « Declarer mon absence » au bord de fin. Pas de seconde
///   fenetre de confirmation.
/// - La feuille « Assurer ce remplacement ? » montre la Classe, la date,
///   l'heure locale, la duree et le nombre d'eleves avant le bouton (ligne 15,
///   a). « Pas cette fois » en secondaire.
/// - Pendant l'envoi, le bouton porte son etat de chargement ; la feuille ne
///   se ferme que sur la reponse. Sans reponse, elle le dit et rien ne change
///   (E7) : aucun etat n'est suppose.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/enseignant/absence_remplacement.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/status_pill.dart';

/// Le libelle d'un etat d'absence, mot pour mot du doc 04 §17.2.
String libelleEtatAbsence(EtatAbsence etat) => switch (etat) {
  EtatAbsence.enregistree => t.enseignant.journee.absence.etats.enregistree,
  EtatAbsence.recherche => t.enseignant.journee.absence.etats.recherche,
  EtatAbsence.remplacantConfirme =>
    t.enseignant.journee.absence.etats.remplacantConfirme,
  EtatAbsence.aucunRemplacant =>
    t.enseignant.journee.absence.etats.aucunRemplacant,
  EtatAbsence.seanceAnnulee => t.enseignant.journee.absence.etats.seanceAnnulee,
  EtatAbsence.demandeAnnulee =>
    t.enseignant.journee.absence.etats.demandeAnnulee,
};

/// Le ton de la pastille d'un etat d'absence : le mot porte le sens, la
/// couleur ne fait que l'accompagner.
TonEtat tonEtatAbsence(EtatAbsence etat) => switch (etat) {
  EtatAbsence.remplacantConfirme => TonEtat.succes,
  EtatAbsence.aucunRemplacant || EtatAbsence.seanceAnnulee => TonEtat.alerte,
  EtatAbsence.recherche => TonEtat.avertissement,
  EtatAbsence.enregistree || EtatAbsence.demandeAnnulee => TonEtat.neutre,
};

/// La pastille d'etat d'une absence, annoncee une fois a son apparition.
class PastilleAbsence extends StatelessWidget {
  /// Cree la pastille.
  const PastilleAbsence({required this.etat, super.key});

  /// L'etat rendu par le serveur.
  final EtatAbsence etat;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    // « Seance annulee » est un etat de seance : la pastille partagee, avec
    // l'icone d'annulation (ANNUL-VIS-1). Les autres etats sont ceux de
    // l'absence.
    child: etat == EtatAbsence.seanceAnnulee
        ? PastilleEtatSeance(
            key: const ValueKey<String>('journee-etat-absence'),
            etat: EtatPastilleSeance.annulee,
            libelle: libelleEtatAbsence(etat),
          )
        : StatusPill(
            key: const ValueKey<String>('journee-etat-absence'),
            libelle: libelleEtatAbsence(etat),
            ton: tonEtatAbsence(etat),
          ),
  );
}

/// Ouvre la feuille « Vous ne pourrez pas assurer cette seance ? » et rend
/// l'etat que le serveur a enregistre, ou `null` (annulee, ou sans reponse).
Future<EtatAbsence?> ouvrirFeuilleAbsence(
  BuildContext context, {
  required DeclarationAbsence port,
  required String seanceId,
  required String classe,
  required DateTime debut,
  required DateTime fin,
  required String date,
}) => AppBottomSheet.ouvrir<EtatAbsence>(
  context,
  titre: t.enseignant.journee.absence.titre,
  constructeur: (BuildContext feuille) => _Resume(
    lignes: <LigneCleValeur>[
      LigneCleValeur(cle: t.enseignant.journee.classe, valeur: classe),
      LigneCleValeur(cle: t.enseignant.journee.absence.cleDate, valeur: date),
      LigneCleValeur(
        cle: t.enseignant.journee.heure,
        valeur: t.enseignant.journee.plage(
          debut: hhmmAbsence(debut),
          fin: hhmmAbsence(fin),
        ),
        chiffres: true,
      ),
      LigneCleValeur(
        cle: LibellesGroupe.dureeLibelle,
        valeur: LibellesGroupe.dureeSeule(fin.difference(debut)),
        chiffres: true,
      ),
    ],
    notice: t.enseignant.journee.absence.notice,
  ),
  actions: (BuildContext feuille) => _ActionsEnvoi<EtatAbsence>(
    cle: 'absence',
    secondaire: t.commun.annuler,
    principale: t.enseignant.journee.absence.declarer,
    envoyer: () => port.declarer(seanceId),
  ),
);

/// Ouvre la feuille « Assurer ce remplacement ? » et rend vrai seulement si
/// le serveur a confirme le remplacant (E7).
Future<bool> ouvrirFeuilleRemplacement(
  BuildContext context, {
  required ReponseRemplacement port,
  required OffreRemplacement offre,
  required String date,
}) async {
  final bool? confirme = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.enseignant.journee.remplacement.titre,
    constructeur: (BuildContext feuille) => _Resume(
      lignes: lignesRemplacement(offre, date: date, heureLocale: true),
    ),
    actions: (BuildContext feuille) => _ActionsEnvoi<bool>(
      cle: 'remplacement',
      secondaire: t.enseignant.journee.remplacement.pasCetteFois,
      principale: t.enseignant.journee.remplacement.assurer,
      envoyer: () async => await port.assurer(offre) ? true : null,
    ),
  );
  return confirme ?? false;
}

/// Les lignes d'une seance de remplacement : Classe, date, heure, duree,
/// eleves (UX_REVIEW_04 ligne 15, a ; E12).
List<LigneCleValeur> lignesRemplacement(
  OffreRemplacement offre, {
  required String date,
  bool heureLocale = false,
}) => <LigneCleValeur>[
  LigneCleValeur(
    cle: t.enseignant.journee.classe,
    valeur: offre.classeDistincte,
  ),
  LigneCleValeur(cle: t.enseignant.journee.absence.cleDate, valeur: date),
  LigneCleValeur(
    cle: heureLocale
        ? t.enseignant.creneaux.cleHeureLocale
        : t.enseignant.journee.heure,
    valeur: t.enseignant.journee.plage(
      debut: hhmmAbsence(offre.debut),
      fin: hhmmAbsence(offre.fin),
    ),
    chiffres: true,
  ),
  LigneCleValeur(
    cle: LibellesGroupe.dureeLibelle,
    valeur: LibellesGroupe.dureeSeule(offre.fin.difference(offre.debut)),
    chiffres: true,
  ),
  LigneCleValeur(
    cle: t.enseignant.journee.eleves,
    valeur: offre.nbEleves == 1
        ? t.enseignant.journee.effectifUn
        : t.enseignant.journee.effectif(nombre: offre.nbEleves),
    chiffres: true,
  ),
];

/// La carte « Remplacement » d'Aujourd'hui (doc 04 §17.3) : le mot sur la
/// pastille, pas une couleur seule (UX_REVIEW_04 ligne 15, c).
class CarteRemplacement extends StatelessWidget {
  /// Cree la carte.
  const CarteRemplacement({required this.offre, required this.date, super.key});

  /// Le remplacement confirme par le serveur.
  final OffreRemplacement offre;

  /// La date, en toutes lettres.
  final String date;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final List<LigneCleValeur> lignes = lignesRemplacement(offre, date: date);
    final String? groupe = offre.groupeId;
    return AppCard(
      key: ValueKey<String>('journee-carte-remplacement-${offre.seanceId}'),
      // E11 et doc 04 §17.3 : le remplacant ouvre la Classe remplacee, ou le
      // bloc « A preparer » donne l'objectif, le support et la reprise.
      // `push` : le retour se referme sur Aujourd'hui (R1).
      actions: groupe == null
          ? null
          : ActionPrincipale(
              key: ValueKey<String>(
                'journee-carte-remplacement-voir-${offre.seanceId}',
              ),
              libelle: t.enseignant.journee.voirClasse,
              niveau: NiveauAction.secondaire,
              onPress: () =>
                  GoRouter.of(context).push<void>(Routes.groupePour(groupe)),
            ),
      // COUPE-MOTS-1 point 5 : le nom et la pastille partagent la ligne tant
      // qu'ils y tiennent entiers (pastille au bord de fin) ; sinon la
      // pastille passe dessous, au bord de debut. Avant, la pastille a sa
      // largeur naturelle ecrasait le nom (« Al- / Fatiha ») et debordait a
      // 320 px, texte a 200 %.
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              offre.classeDistincte,
              style: textes.titleLarge ?? const TextStyle(),
            ),
          ),
          StatusPill(
            libelle: t.enseignant.classes.remplacement,
            ton: TonEtat.accent,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Le nom est deja le titre de la carte.
          for (int i = 1; i < lignes.length; i++) ...<Widget>[
            if (i > 1) Ecart.vSm,
            lignes[i],
          ],
        ],
      ),
    );
  }
}

/// Le resume d'une feuille : les lignes, puis la notice eventuelle.
class _Resume extends StatelessWidget {
  const _Resume({required this.lignes, this.notice});

  final List<LigneCleValeur> lignes;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? texte = notice;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < lignes.length; i++) ...<Widget>[
          if (i > 0) Ecart.vSm,
          lignes[i],
        ],
        if (texte != null) ...<Widget>[
          Ecart.vLg,
          Text(
            texte,
            key: const ValueKey<String>('absence-notice'),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Les deux actions d'une feuille : la secondaire au bord de debut, la
/// principale au bord de fin. La feuille ne se ferme que sur la reponse ;
/// sans reponse (`null`), elle le dit et reste ouverte.
class _ActionsEnvoi<T> extends StatefulWidget {
  const _ActionsEnvoi({
    required this.cle,
    required this.secondaire,
    required this.principale,
    required this.envoyer,
  });

  final String cle;
  final String secondaire;
  final String principale;
  final Future<T?> Function() envoyer;

  @override
  State<_ActionsEnvoi<T>> createState() => _ActionsEnvoiEtat<T>();
}

class _ActionsEnvoiEtat<T> extends State<_ActionsEnvoi<T>> {
  bool _enCours = false;
  bool _echec = false;

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _echec = false;
    });
    T? reponse;
    try {
      reponse = await widget.envoyer();
    } on Object {
      reponse = null;
    }
    if (!mounted) return;
    if (reponse == null) {
      setState(() {
        _enCours = false;
        _echec = true;
      });
      return;
    }
    Navigator.of(context).pop(reponse);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_echec) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.enseignant.journee.absence.echec,
              key: ValueKey<String>('${widget.cle}-echec'),
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vLg,
        ],
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            ActionPrincipale(
              key: ValueKey<String>('${widget.cle}-secondaire'),
              libelle: widget.secondaire,
              niveau: NiveauAction.secondaire,
              onPress: _enCours ? null : () => Navigator.of(context).pop(),
            ),
            ActionPrincipale(
              key: ValueKey<String>('${widget.cle}-principale'),
              libelle: widget.principale,
              enCours: _enCours,
              onPress: _envoyer,
            ),
          ],
        ),
      ],
    );
  }
}

/// L'heure locale d'un instant, sur deux chiffres.
String hhmmAbsence(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';
