// Ma famille du titulaire adulte (EA-5, planches 2.1 et 3.1, colonne gauche
// de 6, UX_REVIEW_07 lignes 6 et 7) : ce que le Foyer existant ajoute quand
// la personne connectee est titulaire d'un foyer avec une place adulte.
//
// Aucun ecran neuf (K-51) : le Foyer du tuteur (`FoyerPage`) garde toute sa
// composition ; il lit en plus [foyerTitulaireProvider] et, quand une valeur
// est rendue, pose la carte du titulaire (`CarteIdentiteCompte` du Compte, avec
// `PhotoEleve`, K-44), la ligne de la place adulte (un `GroupeReglages`, F21)
// et la ligne « Paiements du foyer ». Sans valeur, le Foyer du tuteur ne
// change pas.
//
// **Aucune source serveur a ce jour** (EA-BR-14) : le provider rend
// `CapaciteIndisponible`, la demonstration le surcharge (K-28). La ligne du
// second adulte ne porte que son prenom et l'etat de la place : ni Classe, ni
// niveau, ni seance, ni photo (F6, Q4 : les initiales). La date d'un delai est
// une donnee rendue, jamais un calcul (F17).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import 'ligne_membre.dart' show dateEcheance;

/// L'etat de la place adulte du foyer, tel que le serveur le rend (F21).
sealed class EtatPlaceAdulte {
  const EtatPlaceAdulte();
}

/// Comment la derniere invitation a pris fin, quand le serveur le rend
/// (doc section 5.2, EA-6).
enum FinInvitation {
  /// Elle a expire sans reponse.
  expiree,

  /// Le titulaire l'a annulee : une reponse tardive ne rattache personne.
  annulee,
}

/// La place est libre : la ligne est l'action « Ajouter une conjointe » ou
/// « Ajouter un conjoint ». Une invitation expiree ou annulee la rend libre,
/// sans delai (F5) ; sa fin se lit alors sur la ligne (F21).
final class PlaceDisponible extends EtatPlaceAdulte {
  /// Cree l'etat.
  const PlaceDisponible({this.precedente});

  /// La fin de la derniere invitation, `null` s'il n'y en a pas eu.
  final FinInvitation? precedente;
}

/// Une invitation est envoyee et attend sa reponse. Le prenom et l'adresse
/// sont ceux que le titulaire a saisis, rendus par le serveur (EA-BR-15) ;
/// rien ne dit si l'adresse a deja un compte (F4).
final class InvitationEnvoyee extends EtatPlaceAdulte {
  /// Cree l'etat.
  const InvitationEnvoyee({this.prenom, this.courriel});

  /// Le prenom saisi pour l'invitation.
  final String? prenom;

  /// L'adresse a laquelle l'invitation est partie.
  final String? courriel;
}

/// La place est occupee par le second adulte, dont seul le prenom est rendu.
final class PlaceOccupee extends EtatPlaceAdulte {
  /// Cree l'etat.
  const PlaceOccupee(this.prenom);

  /// Le prenom du second adulte.
  final String prenom;
}

/// Un rattachement attend la validation de l'administration (F17).
final class ValidationEnAttente extends EtatPlaceAdulte {
  /// Cree l'etat.
  const ValidationEnAttente();
}

/// La direction a refuse le rattachement : aucun compte a rebours (F17). Une
/// nouvelle demande reste possible (doc section 10.3, decision E5) : elle
/// relance l'invitation (EA-6, EA-BR-18).
final class ValidationRefusee extends EtatPlaceAdulte {
  /// Cree l'etat.
  const ValidationRefusee();
}

/// Un delai de remplacement court : la date est rendue, jamais calculee, et
/// aucune action d'invitation n'est proposee (F17, R4).
final class DelaiEnCours extends EtatPlaceAdulte {
  /// Cree l'etat.
  const DelaiEnCours(this.possibleLe);

  /// La date a partir de laquelle une nouvelle invitation est possible.
  final DateTime possibleLe;
}

/// Ce que Ma famille lit en plus du Foyer du tuteur.
@immutable
class FoyerTitulaireVM {
  /// Cree la vue.
  const FoyerTitulaireVM({
    required this.placeFeminine,
    required this.place,
    this.cleAvatar,
  });

  /// Vrai quand la place est celle d'une conjointe (titulaire homme), faux
  /// pour un conjoint (titulaire femme). Le genre vient de l'inscription
  /// (F3).
  final bool placeFeminine;

  /// L'etat de la place adulte.
  final EtatPlaceAdulte place;

  /// La cle de la photo du titulaire, `null` sans photo (initiales).
  final String? cleAvatar;
}

/// Le titulaire et sa place adulte. **Aucune source serveur a ce jour**
/// (EA-BR-14) : `CapaciteIndisponible`, et le Foyer reste celui du tuteur.
/// Levee tout de suite (pas un futur) : le Foyer du tuteur ne passe pas par
/// un squelette pour une reponse connue d'avance.
final FutureProvider<FoyerTitulaireVM> foyerTitulaireProvider =
    FutureProvider<FoyerTitulaireVM>(
      (Ref _) => throw const CapaciteIndisponible('foyer_titulaire'),
    );

/// La cle de la ligne de la place adulte.
const Key lignePlaceAdulteKey = Key('foyer.placeAdulte');

/// La cle de la ligne « Paiements du foyer ».
const Key paiementsFoyerKey = Key('foyer.paiementsFoyer');

/// La cle du bouton « Faire une nouvelle demande » (validation refusee, E5).
const Key nouvelleDemandeKey = Key('foyer.nouvelleDemande');

/// Vrai quand la place permet une nouvelle demande : la direction a refuse
/// la validation (doc section 10.3, decision E5). La demande relance
/// l'invitation ; le serveur garde le delai tel quel (EA-BR-18).
bool placePermetNouvelleDemande(EtatPlaceAdulte place) =>
    place is ValidationRefusee;

/// Vrai quand la ligne de la place est une action : inviter quand la place
/// est libre, ouvrir l'invitation envoyee (pour l'annuler, EA-6) ou la place
/// occupee. Les autres etats se lisent sur la ligne, sans bouton qui
/// echouerait (F17, R4) ; leur detail vient avec EA-8.
bool placeActionnable(EtatPlaceAdulte place) =>
    place is PlaceDisponible ||
    place is InvitationEnvoyee ||
    place is PlaceOccupee;

/// La legende de la ligne de la place : l'invitation a envoyer, la fin de la
/// precedente, ou l'adresse de celle qui attend (F21).
String? legendePlace(FoyerTitulaireVM vue) => switch (vue.place) {
  PlaceDisponible(precedente: FinInvitation.expiree) =>
    t.adulte.famille.place.expiree,
  PlaceDisponible(precedente: FinInvitation.annulee) =>
    t.adulte.famille.place.annulee,
  PlaceDisponible() =>
    vue.placeFeminine
        ? t.adulte.famille.place.inviterConjointe
        : t.adulte.famille.place.inviterConjoint,
  InvitationEnvoyee(:final String courriel?) => t.adulte.famille.place.envoyeeA(
    courriel: courriel,
  ),
  _ => null,
};

/// Le libelle de la ligne de la place, selon l'etat et le genre (F3, F21).
///
/// Chaque libelle est une phrase entiere, prenom en parametre, jamais deux
/// morceaux joints par un point median (K-41) : « {prenom}, votre
/// conjointe » est un libelle provisoire, lexique D4. « Validation refusee
/// par la direction » suit la decision E5 (jamais le mot « admin », K-53.6).
String libellePlace(FoyerTitulaireVM vue) {
  final bool f = vue.placeFeminine;
  return switch (vue.place) {
    PlaceDisponible() =>
      f
          ? t.adulte.famille.place.ajouterConjointe
          : t.adulte.famille.place.ajouterConjoint,
    InvitationEnvoyee() => t.adulte.famille.place.invitationEnvoyee,
    PlaceOccupee(:final String prenom) =>
      f
          ? t.adulte.famille.place.maConjointe(prenom: prenom)
          : t.adulte.famille.place.monConjoint(prenom: prenom),
    ValidationEnAttente() => t.adulte.famille.place.validationEnAttente,
    ValidationRefusee() => t.adulte.famille.place.validationRefusee,
    DelaiEnCours(:final DateTime possibleLe) =>
      t.adulte.famille.place.nouvelleInvitation(date: dateEcheance(possibleLe)),
  };
}

/// La ligne de la place adulte : un seul emplacement d'etat (F21), qui
/// devient l'action quand elle est possible et que [onPress] est donne.
LigneRubrique lignePlaceAdulte(FoyerTitulaireVM vue, {VoidCallback? onPress}) {
  final EtatPlaceAdulte place = vue.place;
  return LigneRubrique(
    icone: switch (place) {
      PlaceDisponible() => AppIcons.ajouter,
      PlaceOccupee() => null,

      DelaiEnCours() || ValidationEnAttente() => AppIcons.horloge,
      InvitationEnvoyee() || ValidationRefusee() => AppIcons.foyer,
    },
    // Le second adulte : ses initiales, jamais sa photo (Q4).
    meneur: place is PlaceOccupee
        ? AvatarTile(prenom: place.prenom, diametre: AppSpacing.section)
        : null,
    libelle: libellePlace(vue),
    legende: legendePlace(vue),
    onPress: placeActionnable(place) ? onPress : null,
  );
}

/// La cle de la ligne « A propos du forfait famille ».
const Key aProposForfaitKey = Key('foyer.aProposForfait');

/// « A propos du forfait famille » (planche 2.1 P, decision E6) : une page
/// d'information, sans action.
///
/// Le texte est celui du document du directeur, mot pour mot
/// (`specs/07_eleves_adultes/REWAYAH_DECISIONS_FOYER_FAMILLE_V1.md`,
/// section 3, « Explication secondaire possible ») : rien d'invente, aucun
/// prix, aucune remise (F12, doc section 8).
class AProposForfaitFamillePage extends StatelessWidget {
  /// Cree la page.
  const AProposForfaitFamillePage({required this.onRetour, super.key});

  /// Revient a Ma famille.
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PageShell(
      titre: t.adulte.famille.aProposForfait,
      onRetour: onRetour,
      // Largeur de lecture (K-42) : jamais une ligne de 1100 en bureau.
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
          child: Text(
            t.adulte.famille.aProposForfaitPhrase,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}
