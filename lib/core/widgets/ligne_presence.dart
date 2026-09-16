import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../presence/service_presence.dart';
import '../presence/vue_presence.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

/// Un etat de presence, avec tout ce qu'il faut pour le comprendre.
///
/// **C'est le composant de l'invariant J7**, et il le tient par construction :
/// l'etat ne peut pas s'afficher sans son mot, puisque `StatusPill` n'accepte
/// pas de pastille sans libelle, et le contexte -- « en salle depuis 12 min »,
/// « sans nouvelles depuis 3 min » -- vient avec, parce que la Bible section
/// 29.3 interdit de reduire une presence a une couleur. Un lecteur d'ecran lit
/// donc la meme chose qu'un oeil : un nom, un etat, une duree.
///
/// **Et c'est le composant de l'invariant J3.** Quand la presence n'a pas pu
/// etre lue, [vue] porte [EtatPresence.inconnu] et l'etat s'affiche « Etat
/// inconnu », **jamais « Absence »**. Les deux ne disent pas la meme chose :
/// une absence compte pour le suivi et pour la paie, ne pas savoir ne compte
/// pour rien.
///
/// Le provisoire ne s'ecrit pas, le consolide si. Pendant un cours, tout etat
/// est evidemment provisoire, et le dire sur chaque ligne serait du bruit ;
/// l'etat de cloture qui attend, lui, se nomme deja « A confirmer ». Seule la
/// decision humaine ajoute un mot, parce qu'elle seule fige.
class LignePresence extends StatelessWidget {
  /// Cree une ligne de presence.
  const LignePresence({
    required this.nom,
    required this.vue,
    super.key,
    this.role,
    this.afficherConsolide = true,
  });

  /// Le prenom de la personne, ou ce qui la designe -- « Vous » pour soi-meme.
  final String nom;

  /// Ce qu'il faut montrer de son etat.
  final VuePresence vue;

  /// Son role dans la seance, en clair. Absent quand la ligne se lit seule.
  final String? role;

  /// Masque la mention de consolidation dans les vues qui ne doivent pas
  /// exposer une decision administrative.
  final bool afficherConsolide;

  /// Le libelle d'un etat, dans la langue de l'application.
  ///
  /// **Des formes nominales, et c'est un choix** : « En salle » plutot que
  /// « Present », « Absence » plutot que « Absent ». La vue ne porte pas le
  /// genre des personnes -- elle ne le porte pas parce qu'un tableau de
  /// presence n'en a pas besoin -- et un libelle accorde au masculin par
  /// defaut se tromperait une fois sur deux dans un produit dont la moitie des
  /// eleves sont des filles.
  static String libelle(EtatPresence etat) => switch (etat) {
    EtatPresence.planifiee => t.presence.planifiee,
    EtatPresence.enAttente => t.presence.enAttente,
    EtatPresence.enConnexion => t.presence.enConnexion,
    EtatPresence.presente => t.presence.presente,
    EtatPresence.enRetard => t.presence.enRetard,
    EtatPresence.deconnectee => t.presence.deconnectee,
    EtatPresence.enReconnexion => t.presence.enReconnexion,
    EtatPresence.reconnectee => t.presence.reconnectee,
    EtatPresence.sortie => t.presence.sortie,
    EtatPresence.absente => t.presence.absente,
    EtatPresence.excusee => t.presence.excusee,
    EtatPresence.confirmationEnAttente => t.presence.confirmationEnAttente,
    EtatPresence.corrigeeManuel => t.presence.corrigeeManuel,
    EtatPresence.finalisee => t.presence.finalisee,
    EtatPresence.inconnu => t.presence.inconnu,
  };

  /// La phrase de contexte, ou `null` quand l'etat ne date rien.
  ///
  /// La duree se dit en minutes, comme partout ailleurs dans le produit, et la
  /// premiere minute se dit autrement : afficher « depuis 0 min » serait faux
  /// dans les deux sens, ni zero ni une minute.
  static String? contexte(VuePresence vue) {
    final Duration? ecoule = vue.ecoule;
    if (ecoule == null) {
      return null;
    }
    final int minutes = ecoule.inMinutes;
    return switch (vue.repere) {
      RepereTemps.entree =>
        minutes <= 0
            ? t.presence.entreeInstant
            : t.presence.entreeMinutes(minutes: '$minutes'),
      // Un retard sous la minute n'existe pas : le seuil est de cinq minutes
      // par defaut, et il se regle en base, jamais ici.
      RepereTemps.retard => t.presence.retardMinutes(minutes: '$minutes'),
      RepereTemps.silence =>
        minutes <= 0
            ? t.presence.silenceInstant
            : t.presence.silenceMinutes(minutes: '$minutes'),
      RepereTemps.attente =>
        minutes <= 0
            ? t.presence.attenteInstant
            : t.presence.attenteMinutes(minutes: '$minutes'),
      RepereTemps.aucun => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String? dit = contexte(vue);

    // Les parties basses se lisent d'un trait : le role, la duree, et le mot
    // qui dit qu'une decision a fige l'etat. Trois `Text` separes feraient
    // trois annonces pour une seule personne.
    final String detail = <String>[
      if (role case final String r when r.isNotEmpty) r,
      ?dit,
      if (afficherConsolide && vue.consolide) t.presence.consolide,
    ].join(' · ');

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // **Un `Wrap`, pas un `Row`, et la raison a ete mesuree** : la salle
          // pose cette ligne dans une colonne de 208 points utiles, et « Nour »
          // suivi de « Reconnexion en cours » y deborde de vingt-six pixels.
          // Un `Row` aurait alors coupe le mot d'un etat critique -- exactement
          // ce que l'invariant J7 interdit, puisqu'il ne resterait que la
          // couleur. Le `Wrap` passe la pastille a la ligne quand il le faut,
          // et la garde a cote du nom quand il y a la place : la meme ligne
          // sert donc la colonne etroite et la feuille large, sans que rien
          // n'ait a mesurer la fenetre.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(nom, style: textes.labelLarge ?? const TextStyle()),
              StatusPill(libelle: libelle(vue.etat), ton: vue.ton),
            ],
          ),
          if (detail.isNotEmpty) ...<Widget>[
            Ecart.vXs,
            // **Aucune couleur posee, et c'est delibere** : la ligne sert la
            // salle, en registre inverse, et servira le suivi eleve, sur fond
            // creme. `encreSecondaireSur` ne rend que des encres sombres --
            // elle ecrirait du gris fonce sur du sombre. La hierarchie tient
            // donc par la taille, jamais par la teinte, et l'encre vient du
            // registre de la coquille.
            Text(detail, style: textes.bodySmall ?? const TextStyle()),
          ],
        ],
      ),
    );
  }
}
