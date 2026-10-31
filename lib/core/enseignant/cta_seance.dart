/// CTA-FIN-1 : le bouton principal d'une seance selon son moment.
///
/// **Fonctions pures, sans widget, sans horloge propre** : le temps arrive en
/// parametre, la fenetre d'acces et la grace viennent de la base (jamais de
/// valeur redeclaree ici, ADR-005). Le bouton d'une seance n'est jamais grise :
/// il change de sens selon le moment (regle K-56).
///
/// | Moment                                         | Etat            |
/// |------------------------------------------------|-----------------|
/// | avant l'ouverture de la salle                  | [preparer]      |
/// | salle ouverte, jusqu'a la fin (et au-dela tant  | [rejoindre]     |
/// | que la salle est ouverte : le cours deborde)   |                 |
/// | salle fermee, cahier non depose                | [remplirCahier] |
/// | salle fermee, cahier depose                    | [voirCahier]    |
/// | seance annulee ou enseignant absent            | [voirClasse]    |
library;

import '../domain/enums.dart';
import '../tc_horloge/fenetre_seance.dart';
import 'modeles_enseignant.dart';

/// Le sens du bouton principal d'une seance.
enum EtatCtaSeance {
  /// Avant l'heure : « Preparer la seance ».
  preparer,

  /// Pendant le creneau, et tant que la salle est ouverte : « Rejoindre la
  /// salle ».
  rejoindre,

  /// Temps ecoule, cahier non depose : « Remplir le cahier de transmission »
  /// (obligatoire).
  remplirCahier,

  /// Cahier depose : « Voir le cahier », en lien discret.
  voirCahier,

  /// La seance n'aura pas lieu : « Voir la Classe ».
  voirClasse,
}

/// L'etat du bouton, avec ce qu'il faut pour la pastille.
class CtaSeance {
  /// Cree un etat de bouton.
  const CtaSeance({required this.etat, required this.enDirect});

  /// Le sens du bouton.
  final EtatCtaSeance etat;

  /// Vrai quand la seance se tient (de T0 a la fermeture de la salle,
  /// prolongation comprise) : la pastille « En direct » se montre.
  final bool enDirect;
}

/// Ce que la base dit de la salle, a partir du statut de la seance.
///
/// `true` : la salle est ouverte. `false` : la seance est close. `null` :
/// information absente, la grace de [FenetreSeance] tranche.
bool? salleOuverteSelon(StatutSeance? statut) => switch (statut) {
  StatutSeance.enCours => true,
  StatutSeance.terminee ||
  StatutSeance.eleveAbsent ||
  StatutSeance.incidentTechnique => false,
  _ => null,
};

/// L'etat du bouton principal d'une seance a [maintenant].
///
/// [fenetreAcces] et [graceApresFin] sont les bornes de la base. [statut] est
/// celui que la base a decide : il l'emporte sur l'heure quand il dit que la
/// salle est ouverte (un cours qui deborde garde « Rejoindre la salle ») ou
/// close (un cours termine en avance passe au cahier).
CtaSeance ctaSeance({
  required DateTime maintenant,
  required DateTime debut,
  required DateTime fin,
  required bool cahierDepose,
  required Duration fenetreAcces,
  required Duration graceApresFin,
  StatutSeance? statut,
}) {
  if ((statut?.estAnnulee ?? false) ||
      statut == StatutSeance.enseignantAbsent) {
    return const CtaSeance(etat: EtatCtaSeance.voirClasse, enDirect: false);
  }
  final FenetreSeance fenetre = FenetreSeance(
    debutUtc: debut.toUtc(),
    finPrevueUtc: fin.toUtc(),
    fenetreAcces: fenetreAcces,
    graceApresFin: graceApresFin,
  );
  final bool? ouverte = salleOuverteSelon(statut);
  final DateTime instant = maintenant.toUtc();
  // Close par la base apres le debut : le temps prevu ne change plus rien.
  final bool close = ouverte == false && !instant.isBefore(fenetre.debutUtc);
  final PhaseSeance phase = close
      ? PhaseSeance.terminee
      : fenetre.phaseA(instant, seanceOuverte: ouverte);
  return switch (phase) {
    PhaseSeance.avantFenetre => const CtaSeance(
      etat: EtatCtaSeance.preparer,
      enDirect: false,
    ),
    PhaseSeance.salleOuverte || PhaseSeance.attenteAvantT0 => const CtaSeance(
      etat: EtatCtaSeance.rejoindre,
      enDirect: false,
    ),
    PhaseSeance.enCours || PhaseSeance.prolongee => const CtaSeance(
      etat: EtatCtaSeance.rejoindre,
      enDirect: true,
    ),
    PhaseSeance.terminee => CtaSeance(
      etat: cahierDepose
          ? EtatCtaSeance.voirCahier
          : EtatCtaSeance.remplirCahier,
      enDirect: false,
    ),
  };
}

/// Le meme calcul, depuis une [SeanceEnseignant].
CtaSeance ctaDeSeance(
  SeanceEnseignant seance,
  DateTime maintenant, {
  required Duration fenetreAcces,
  required Duration graceApresFin,
}) => ctaSeance(
  maintenant: maintenant,
  debut: seance.debut,
  fin: seance.fin,
  cahierDepose: seance.cahierDepose,
  statut: seance.statut,
  fenetreAcces: fenetreAcces,
  graceApresFin: graceApresFin,
);

/// La seance que la carte « Prochaine seance » doit montrer.
///
/// Dans l'ordre :
/// 1. la seance dont la salle est ouverte (en cours, ou qui deborde) ;
/// 2. la seance du jour dont le temps est ecoule et dont le cahier manque
///    (obligatoire : il passe avant la suivante, tant que la salle de la
///    suivante n'est pas ouverte) ;
/// 3. la prochaine seance a venir ;
/// 4. a defaut de seance a venir, la derniere seance du jour dont le cahier
///    est depose (« Voir le cahier »).
///
/// Une seance annulee n'est jamais retenue, ni un cours sans seance en base
/// ([SeanceEnseignant.aCreer]) dont le temps est ecoule.
SeanceEnseignant? seanceDeLaCarte(
  List<SeanceEnseignant> seances,
  DateTime maintenant, {
  required Duration fenetreAcces,
  required Duration graceApresFin,
}) {
  final List<SeanceEnseignant> retenues =
      <SeanceEnseignant>[
        for (final SeanceEnseignant s in seances)
          if (!(s.statut?.estAnnulee ?? false) &&
              s.statut != StatutSeance.enseignantAbsent &&
              // Un cours sans seance en base, fini sans que personne n'y
              // entre, n'a ni cahier ni salle : il quitte la carte.
              !(s.aCreer && !maintenant.isBefore(s.fin.add(graceApresFin))))
            s,
      ]..sort(
        (SeanceEnseignant a, SeanceEnseignant b) => a.debut.compareTo(b.debut),
      );

  CtaSeance cta(SeanceEnseignant s) => ctaDeSeance(
    s,
    maintenant,
    fenetreAcces: fenetreAcces,
    graceApresFin: graceApresFin,
  );
  bool memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  for (final SeanceEnseignant s in retenues) {
    if (cta(s).etat == EtatCtaSeance.rejoindre) return s;
  }
  SeanceEnseignant? derniereTerminee;
  SeanceEnseignant? cahierManquant;
  SeanceEnseignant? prochaine;
  for (final SeanceEnseignant s in retenues) {
    final EtatCtaSeance etat = cta(s).etat;
    if (etat == EtatCtaSeance.preparer) {
      prochaine ??= s;
    } else if (memeJour(s.debut, maintenant)) {
      if (etat == EtatCtaSeance.remplirCahier) cahierManquant = s;
      if (etat == EtatCtaSeance.voirCahier) derniereTerminee = s;
    }
  }
  return cahierManquant ?? prochaine ?? derniereTerminee;
}
