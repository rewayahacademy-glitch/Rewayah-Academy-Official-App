import 'package:flutter/material.dart';

import '../../core/tc_classe/libelles_tc_classe.dart';
import '../../core/tc_classe/ports_externes/port_annonce_observation.dart';
import '../../core/tc_classe/ports_externes/session_clock_vm.dart';
import '../../core/tc_classe/ports_externes/titre_enseignant.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/status_pill.dart';
import 'roster_classe.dart';
import 'vue_classe_live.dart';

/// Le temps restant, tel que l'en-tete l'ecrit.
///
/// **Fonction pure, et elle ne calcule aucune duree.** Elle met en mots ce que
/// `SessionClockVM.restant` contient deja : cette duree est derivee de
/// `calculeeAUtc`, l'instant serveur de reference, et non de l'horloge de
/// l'appareil. Un en-tete qui ferait la soustraction lui-meme afficherait le
/// decalage de la machine de l'enseignant.
///
/// Rend `null` quand il n'y a rien a dire : pas d'horloge, ou une seance
/// terminee. Une prolongation, elle, se dit -- **sans compte a rebours**, parce
/// qu'il serait negatif (invariant 3 de `SessionClockVM`).
String? libelleTempsRestant(SessionClockVM? horloge) {
  if (horloge == null) {
    return null;
  }
  if (horloge.phase == PhaseSeance.prolongee) {
    return LibellesClasse.coursToujoursEnCours;
  }
  final Duration? restant = horloge.restant;
  if (restant == null) {
    return null;
  }
  final int heures = restant.inHours;
  final int minutes = restant.inMinutes % Duration.minutesPerHour;
  return heures == 0
      ? LibellesClasse.resteMinutes(restant.inMinutes)
      : LibellesClasse.resteHeuresMinutes(heures, minutes);
}

/// Le nom de l'enseignant, precede de son titre.
///
/// **Sayyid / Sayyida, jamais Ustaz** (decision D-02). Le titre manquant n'est
/// pas une faute : la base ne le porte pas encore, et l'ecrire au hasard serait
/// pire que de ne pas l'ecrire.
String nomAvecTitre(EnseignantDeClasse enseignant) =>
    switch (enseignant.titre) {
      TitreEnseignant.sayyid =>
        '${LibellesClasse.titreSayyid} ${enseignant.nomAffichage}',
      TitreEnseignant.sayyida =>
        '${LibellesClasse.titreSayyida} ${enseignant.nomAffichage}',
      null => enseignant.nomAffichage,
    };

/// L'en-tete de la Classe Live (spec section 9.1).
///
/// Groupe, titre et nom de l'enseignant, temps restant. Puis, sur une seconde
/// ligne et seulement quand il y a quelque chose a dire : l'etat du lien,
/// l'avertissement d'arriere-plan, et les annonces d'observation.
///
/// **Discret par construction** : c'est le contenu pedagogique qui domine, et
/// `PageImmersive` pose deja cet en-tete au-dessus du contenu, jamais par-dessus.
class EnteteClasse extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteClasse({
    required this.session,
    required this.vue,
    required this.roster,
    super.key,
    this.annonces = const <AnnonceObservation>[],
    this.onVoirRoster,
  });

  /// La seance live.
  final SessionLiveVM session;

  /// La composition de l'ecran.
  final VueClasseLive vue;

  /// Le roster, pour le compteur compact.
  final RosterClasseVM roster;

  /// Les observateurs annonces. Vide = personne n'observe.
  final List<AnnonceObservation> annonces;

  /// Ouvre la feuille de roster. `null` quand le roster est deja en colonne.
  final VoidCallback? onVoirRoster;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String? restant = libelleTempsRestant(session.horloge);
    final String? compteur = vue.compteurCompact;
    final VoidCallback? voirRoster = onVoirRoster;
    final String? mot = _motDuLien(vue.motLien);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // La photo enseignant est OBLIGATOIRE (decision D-01). Quand elle
            // manque, on ne pose pas un avatar generique : cela masquerait une
            // donnee absente au lieu de la signaler. On ecrit qu'elle manque.
            if (session.enseignant.photoCleOuUrl case final String photo)
              ...<Widget>[
              AvatarTile(
                prenom: session.enseignant.nomAffichage,
                urlSignee: photo,
              ),
              Ecart.hSm,
            ],
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      session.libelleGroupe,
                      overflow: TextOverflow.ellipsis,
                      style: textes.titleSmall ?? const TextStyle(),
                    ),
                    Text(
                      nomAvecTitre(session.enseignant),
                      overflow: TextOverflow.ellipsis,
                      style: textes.labelMedium ?? const TextStyle(),
                    ),
                  ],
                ),
              ),
            ),
            if (restant != null) ...<Widget>[
              Ecart.hSm,
              Text(restant, style: textes.labelLarge ?? const TextStyle()),
            ],
            if (compteur != null && voirRoster != null) ...<Widget>[
              Ecart.hSm,
              BoutonRoster(
                compteur: compteur,
                presents: roster.presents,
                attendus: roster.attendus,
                onOuvrir: voirRoster,
              ),
            ],
          ],
        ),
        if (session.enseignant.photoCleOuUrl == null) ...<Widget>[
          Ecart.vSm,
          const StatusPill(
            libelle: LibellesClasse.photoEnseignantManquante,
            ton: TonEtat.avertissement,
          ),
        ],
        if (mot != null) ...<Widget>[
          Ecart.vSm,
          StatusPill(libelle: mot, ton: _tonDuLien(vue.motLien)),
        ],
        if (vue.avertitSuspension) ...<Widget>[
          Ecart.vSm,
          // **On ne promet rien.** Quand la plateforme suspend le processus,
          // aucune machine de reconnexion ne peut tenir parole : la phrase dit
          // le risque, elle n'annonce pas une coupure qui n'a pas eu lieu.
          Text(
            LibellesClasse.lienArrierePlan,
            style: textes.labelMedium ?? const TextStyle(),
          ),
        ],
        for (final AnnonceObservation annonce in annonces) ...<Widget>[
          Ecart.vSm,
          _Annonce(annonce: annonce),
        ],
      ],
    );
  }

  /// Le mot de l'etat du lien. `null` quand il n'y a rien a dire.
  ///
  /// « Connexion excellente » n'apporte rien pendant un cours et occuperait la
  /// place que le Coran prendra. Seuls les etats qui changent quelque chose se
  /// disent.
  static String? _motDuLien(MotLien mot) => switch (mot) {
    MotLien.aucun => null,
    MotLien.instable => LibellesClasse.lienInstable,
    MotLien.reconnexion => LibellesClasse.lienReconnexion,
    MotLien.retabli => LibellesClasse.lienRetabli,
    MotLien.echec => LibellesClasse.lienEchec,
  };

  static TonEtat _tonDuLien(MotLien mot) => switch (mot) {
    MotLien.retabli => TonEtat.succes,
    MotLien.echec => TonEtat.alerte,
    MotLien.aucun ||
    MotLien.instable ||
    MotLien.reconnexion => TonEtat.avertissement,
  };
}

/// Une observation annoncee : « Tuteur d'Amina observe », et le temps restant.
///
/// **Pas de notification de sortie** (decision D-14) : la ligne disparait, et
/// c'est tout. Les autres eleves ne sont pas interrompus.
class _Annonce extends StatelessWidget {
  const _Annonce({required this.annonce});

  final AnnonceObservation annonce;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Duration? restant = annonce.tempsRestant;

    return MergeSemantics(
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              annonce.libelle,
              overflow: TextOverflow.ellipsis,
              style: textes.labelMedium ?? const TextStyle(),
            ),
          ),
          if (restant != null) ...<Widget>[
            Ecart.hSm,
            Text(
              LibellesClasse.observationRestant(restant.inSeconds),
              style: textes.labelMedium ?? const TextStyle(),
            ),
          ],
        ],
      ),
    );
  }
}
