import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/jour_du_mois.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/theme/accent_profil.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/identite_profil.dart';
import 'finances_foyer.dart';
import 'photo_eleve.dart';

/// Ce que le Foyer sait de la classe d'un membre.
///
/// Une lecture en cours ou sans service ne dit **rien** de la classe sur la
/// ligne : jamais « pas de classe » faute de savoir. La page dit une seule
/// fois, sous le groupe, que l'information manque
/// ([ClasseMembre.indisponible]). Une lecture **en echec** n'est ni l'une ni
/// l'autre : elle se dit comme un echec, avec un moyen de relire
/// ([ClasseMembre.echec]).
sealed class ClasseMembre {
  const ClasseMembre();

  /// La lecture n'a pas encore abouti.
  static const ClasseMembre inconnue = _Inconnue();

  /// Le port des classes n'a pas de service (contrat K5).
  static const ClasseMembre indisponible = _Indisponible();

  /// Le port a un service, mais la lecture a echoue.
  static const ClasseMembre echec = _Echec();

  /// Ce que rend le port pour un membre.
  static ClasseMembre depuis(List<ClasseFoyer> classes) => classes.isEmpty
      ? const _SansClasse()
      : _Classes(<String>[
          for (final ClasseFoyer c in classes) c.classe.libelle,
        ]);
}

final class _Inconnue extends ClasseMembre {
  const _Inconnue();
}

final class _Indisponible extends ClasseMembre {
  const _Indisponible();
}

final class _Echec extends ClasseMembre {
  const _Echec();
}

final class _SansClasse extends ClasseMembre {
  const _SansClasse();
}

final class _Classes extends ClasseMembre {
  const _Classes(this.libelles);

  final List<String> libelles;
}

/// La date d'une echeance d'acces, en toutes lettres : « 30 octobre 2026 »,
/// « 1er novembre 2026 » (R8-05).
String dateEcheance(DateTime date) {
  final DateTime locale = date.toLocal();
  return t.foyer.membre.date(
    jour: jourDuMois(locale.day),
    mois: t.commun.dates.mois[locale.month - 1],
    annee: locale.year.toString(),
  );
}

/// Le statut d'acces d'un membre, en texte (jamais la couleur seule).
///
/// Le calcul « expire » est un calcul **d'affichage** (`etatAccesAffiche`,
/// contrat K6) : le serveur fait deja foi, et une date passee ne se dit
/// jamais valide.
String statutAcces(ProfilEleveFoyer profil, DateTime maintenant) {
  final DateTime? fin = profil.finAcces;
  return switch (etatAccesAffiche(
    finAcces: fin,
    maintenantUtc: maintenant.toUtc(),
  )) {
    EtatAccesAffiche.sansEcheance => t.foyer.membre.accesSansEcheance,
    EtatAccesAffiche.actif => t.foyer.membre.accesJusquau(
      date: dateEcheance(fin!),
    ),
    EtatAccesAffiche.expire => t.foyer.membre.accesExpire(
      date: dateEcheance(fin!),
    ),
  };
}

/// Ce que l'ecran dit d'une etape du parcours d'inscription : « A remplir »,
/// « Classe en cours de constitution ». Partage par le Foyer et la page
/// « Parcours et inscription » de la fiche : les deux disent la meme chose du
/// meme eleve.
String libelleEtapeFiche(EtapeParcours etape) => switch (etape) {
  EtapeParcours.aPersonnaliser => t.ficheEleve.inscription.aRemplir,
  EtapeParcours.horaireAChoisir => t.ficheEleve.inscription.horaireAChoisir,
  EtapeParcours.offreIndisponible => t.ficheEleve.inscription.horaireRetire,
  EtapeParcours.diagnosticRequis => t.ficheEleve.inscription.echangeAPrevoir,
  EtapeParcours.diagnosticEnAttente => t.ficheEleve.inscription.echangePrevu,
  EtapeParcours.groupeEnFormation =>
    t.ficheEleve.inscription.classeEnConstitution,
  EtapeParcours.groupeConfirme => t.ficheEleve.inscription.classeConfirmee,
};

/// L'etape d'inscription d'un eleve lue dans `v_parcours_onboarding`, ou
/// `null` quand la lecture n'a pas abouti ou ne connait pas l'eleve.
EtapeParcours? etapeInscriptionLue(
  AsyncValue<List<ParcoursApprenant>> parcours,
  String eleveId,
) {
  if (!parcours.hasValue || parcours.hasError) {
    return null;
  }
  for (final ParcoursApprenant p in parcours.requireValue) {
    if (p.eleveId == eleveId) {
      return etapeParcours(p);
    }
  }
  return null;
}

/// La legende d'un membre : sa classe quand on la connait, sinon son
/// inscription en cours quand on la connait, puis son acces.
///
/// [avecAcces] faux : l'acces n'est pas repete, la carte le dit deja par la
/// pastille de periode financee a la meme date (revue FI-VAGUE-R R1-11).
String legendeMembre({
  required ProfilEleveFoyer profil,
  required ClasseMembre classe,
  required DateTime maintenant,
  EtapeParcours? inscription,
  bool avecAcces = true,
}) {
  final String? classeLue = classe is _Classes || inscription == null
      ? texteClasse(classe)
      : libelleEtapeFiche(inscription);
  if (!avecAcces) return classeLue ?? '';
  final String acces = statutAcces(profil, maintenant);
  return classeLue == null ? acces : '$classeLue · $acces';
}

/// Vrai quand la fin de la periode financee et l'echeance d'acces tombent le
/// meme jour (heure locale) : une seule echeance, dite une seule fois.
bool memeEcheance(DateTime? finPeriode, DateTime? finAcces) {
  if (finPeriode == null || finAcces == null) return false;
  final DateTime a = finPeriode.toLocal();
  final DateTime b = finAcces.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Ce que la lecture du port des classes dit d'un membre.
ClasseMembre classeMembreLue(AsyncValue<List<ClasseFoyer>> lecture) {
  if (lecture.hasValue && !lecture.hasError) {
    return ClasseMembre.depuis(lecture.requireValue);
  }
  if (lecture.error is CapaciteIndisponible) {
    return ClasseMembre.indisponible;
  }
  if (lecture.hasError) {
    return ClasseMembre.echec;
  }
  return ClasseMembre.inconnue;
}

/// Vrai quand le port des classes n'a pas de service (contrat K5).
bool classeIndisponible(ClasseMembre classe) => classe is _Indisponible;

/// Vrai quand la lecture des classes a echoue alors que le port a un service.
bool classeEnEchec(ClasseMembre classe) => classe is _Echec;

/// Ce que l'ecran dit de la classe d'un membre, ou `null` quand il n'en sait
/// rien (lecture en cours ou sans service) : jamais « pas de classe » faute
/// de savoir. Une lecture en echec se dit « classe non lue ». Partage par le
/// Foyer et la fiche eleve.
String? texteClasse(ClasseMembre classe) => switch (classe) {
  _Classes(:final List<String> libelles) => libelles.join(', '),
  _SansClasse() => t.foyer.membre.sansClasse,
  _Echec() => t.foyer.membre.classeEchec,
  _Inconnue() || _Indisponible() => null,
};

/// La carte d'un membre du foyer (maquette 11 « Foyer », decision du
/// directeur du 04/10/2026, K-62) : une carte par enfant, sa photo en cercle
/// en haut a gauche, et derriere elle le bandeau de la couleur choisie par le
/// tuteur, **colle au bord haut de la carte** ([marge] de la carte = la
/// remontee du bandeau). Sans couleur choisie, le cercle seul. Toute la carte
/// ouvre la fiche.
class CarteMembre extends StatelessWidget {
  /// Cree la carte.
  const CarteMembre({
    required this.profil,
    required this.legende,
    required this.onPress,
    super.key,
    this.accent,
    this.finance,
  });

  /// La marge interne de la carte, donc la remontee du bandeau.
  static const double marge = AppSpacing.xl;

  /// Le membre.
  final ProfilEleveFoyer profil;

  /// La ligne sous le prenom (classe, acces, inscription).
  final String legende;

  /// Ouvre la fiche.
  final VoidCallback onPress;

  /// La couleur choisie par le tuteur, `null` sans bandeau.
  final AccentProfil? accent;

  /// La finance rendue du profil (FI-4) : son etat, son solde et son
  /// prochain debit sous l'identite ; `null` sans source, la carte d'avant.
  final FinancesProfil? finance;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget identite = AvatarNom.enLigne(
      prenom: profil.prenom,
      diametre: AppAvatar.grand,
      cercleEnHaut: true,
      // La fleche au bout de la carte, a toute largeur (revue FI-2-R M1).
      texteEtire: true,
      avatar: PhotoEleve(
        prenom: profil.prenom,
        cleAvatar: profil.cleAvatar,
        diametre: AppAvatar.grand,
      ),
      enveloppeAvatar: BandeauProfil.enveloppe(
        diametre: AppAvatar.grand,
        accent: accent,
        remontee: marge,
      ),
      role: legende,
      styleNom: palette.inkStrong.applyTo(
        textes.titleMedium ?? const TextStyle(),
      ),
      styleRole: palette.inkMuted.applyTo(
        textes.bodyMedium ?? const TextStyle(),
      ),
      fin: IconTheme(
        data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
        child: Icon(AppIcons.chevron.repos),
      ),
    );
    final FinancesProfil? f = finance;
    return AppCard(
      marge: marge,
      onPress: onPress,
      child: f == null
          ? identite
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                identite,
                Ecart.vMd,
                BlocFinanceMembre(finance: f),
              ],
            ),
    );
  }
}
