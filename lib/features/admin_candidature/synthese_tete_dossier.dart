// La synthese en tete du dossier (PE-C2, plan §3.2, A2 et A7) et les elements
// manquants du complement (PE-C10, plan §12.1).
//
// En haut du dossier : ce qui manque (de son cote), la piece d'identite
// verifiee ou non, la derniere connexion de la personne, l'anciennete de la
// candidature ; et, avant le geste, la phrase « Accueillir demande une piece
// verifiee » quand la piece ne l'est pas (le serveur le refuse deja :
// ACCUEIL-SEPARE, 20261129410000).
//
// **Une presentation, pas une regle.** Tout vient de `lire_candidature` :
// `manquants` (private.praxis_dossier_manques), `controles` (piece_validee),
// `derniereConnexion` (migration 20261130900000) et `recueLe`. Une cle que le
// serveur ne rend pas ne produit aucune ligne : jamais une valeur inventee.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../admin_candidatures/libelles_candidatures.dart'
    show dateCourteCandidature;
import 'libelles_candidature.dart';

/// Les codes de « Demander un complement » a cocher d'emblee : ce qui manque
/// au dossier de la personne (PE-C10). `pays_versement` devient `versement` ;
/// `compte` et `questionnaire` n'ont pas d'element de complement precis et ne
/// sont pas coches. La feuille ne garde ensuite que les codes que le serveur
/// permet a cette etape. Pure.
Set<String> elementsComplementManquants(DetailCandidature detail) {
  final List<String>? manquants = detail.manquants;
  if (manquants == null) return const <String>{};
  return <String>{
    for (final String code in manquants)
      if (code == 'pays_versement')
        'versement'
      else if (libelleElementComplement(code) != null)
        code,
  };
}

/// Le nom d'un code manquant, dans la langue de la direction. Pure.
String libelleManquant(String code) {
  final e = t.recrutement.dossier3.tete.elements;
  return switch (code) {
    'compte' => e.compte,
    'questionnaire' => e.questionnaire,
    'pays_versement' => e.pays_versement,
    _ => libelleElementComplement(code) ?? code,
  };
}

/// L'etat de la piece lu dans le controle `piece_validee`, ou `null` quand le
/// serveur ne le rend pas. Pure.
String? valeurPiece(DetailCandidature detail) {
  final v = t.recrutement.dossier3.tete.pieceValeurs;
  for (final ControleCandidature c
      in detail.controles ?? const <ControleCandidature>[]) {
    if (c.nom != 'piece_validee') continue;
    if (c.valeur) return v.verifiee;
    return switch (c.cause) {
      'piece_a_verifier' => v.aVerifier,
      'piece_a_redeposer' => v.aRedeposer,
      'compte_absent' => v.compteAbsent,
      _ => v.absente,
    };
  }
  return null;
}

/// Vrai quand la piece n'est pas (encore) verifiee, lu dans `controles`.
bool pieceNonVerifiee(DetailCandidature detail) =>
    (detail.controles ?? const <ControleCandidature>[]).any(
      (ControleCandidature c) => c.nom == 'piece_validee' && !c.valeur,
    );

/// Le nombre de jours pleins entre [instant] et [maintenant], dans le fuseau
/// de l'appareil. Pure.
int joursDepuis(DateTime instant, DateTime maintenant) {
  final DateTime a = instant.toLocal();
  final DateTime b = maintenant.toLocal();
  return DateTime(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime(a.year, a.month, a.day)).inDays;
}

String _arabe(String texte) =>
    LocaleSettings.currentLocale == AppLocale.ar ? isolerSens(texte) : texte;

/// La derniere connexion en mots : aujourd'hui, hier, ou la date. Pure.
String valeurConnexion(DateTime? derniere, DateTime maintenant) {
  final s = t.recrutement.dossier3.tete;
  if (derniere == null) return s.connexionAucune;
  final int jours = joursDepuis(derniere, maintenant);
  if (jours <= 0) return s.aujourdhui;
  if (jours == 1) return s.hier;
  return _arabe(dateCourteCandidature(derniere));
}

/// L'anciennete de la candidature : « il y a 12 jours (2 nov. 2026) ». Pure.
String valeurAnciennete(DateTime recueLe, DateTime maintenant) {
  final s = t.recrutement.dossier3.tete;
  final int jours = joursDepuis(recueLe, maintenant);
  if (jours <= 0) return s.aujourdhui;
  return _arabe(
    '${s.ilYa(n: jours)}${t.admin.candidatures.historique.separateur}'
    '${dateCourteCandidature(recueLe)}',
  );
}

/// La synthese en tete du dossier. Rien quand le serveur ne rend aucune des
/// quatre donnees.
class SyntheseTeteDossier extends StatelessWidget {
  /// Cree la synthese.
  const SyntheseTeteDossier({
    required this.detail,
    required this.accepter,
    super.key,
    this.maintenant,
  });

  /// Le dossier lu.
  final DetailCandidature detail;

  /// Le geste de la fente « accepter » de la barre de decision.
  final GesteCandidature accepter;

  /// L'instant de reference (les tests le fixent) ; l'horloge sinon.
  final DateTime? maintenant;

  /// La cle de la synthese.
  static const Key cle = ValueKey<String>('dossier-tete-synthese');

  /// La cle de la phrase « Accueillir demande une piece verifiee ».
  static const Key clePieceExigee = ValueKey<String>('dossier-tete-piece');

  @override
  Widget build(BuildContext context) {
    final s = t.recrutement.dossier3.tete;
    final DateTime ref = maintenant ?? DateTime.now();
    final List<String>? manquants = detail.manquants;
    final String? piece = valeurPiece(detail);
    final DateTime? recueLe = detail.ligne.recueLe;
    final List<LigneCleValeur> lignes = <LigneCleValeur>[
      if (manquants != null)
        LigneCleValeur(
          cle: s.manque,
          valeur: manquants.isEmpty
              ? s.manqueRien
              : manquants
                    .map(libelleManquant)
                    // Des noms propres a chaque element : un point median
                    // les separe (la virgule laissait une majuscule au milieu).
                    .join(t.admin.candidatures.historique.separateur),
        ),
      if (piece != null) LigneCleValeur(cle: s.piece, valeur: piece),
      if (detail.derniereConnexionServie)
        LigneCleValeur(
          cle: s.connexion,
          valeur: valeurConnexion(detail.derniereConnexion, ref),
        ),
      if (recueLe != null)
        LigneCleValeur(
          cle: s.anciennete,
          valeur: valeurAnciennete(recueLe, ref),
        ),
    ];
    // A7 : « Accueillir » exige une piece verifiee (le serveur refuse sinon) ;
    // l'ecran le dit avant le geste. « Admettre a l'entretien » ne l'exige pas
    // (Q4 du plan, sans reponse) : aucune phrase pour lui.
    final bool pieceExigee =
        accepter == GesteCandidature.validerPiece && pieceNonVerifiee(detail);
    if (lignes.isEmpty && !pieceExigee) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...lignes,
        if (pieceExigee) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            s.accueillirPiece(geste: libelleGeste(accepter)),
            key: clePieceExigee,
            style: palette.inkStrong.applyTo(base),
          ),
        ],
      ],
    );
  }
}
