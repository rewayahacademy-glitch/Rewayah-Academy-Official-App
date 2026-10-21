// « Ajouter ma famille » (EA-PL parcours) : l'adulte inscrit seul (« Moi
// uniquement ») passe vers une famille sans recreer son compte ni son
// identite eleve (doc section 4). Ouvert depuis la ligne famille de Mon
// espace.
//
// Le texte d'explication est celui du doc section 4, mot pour mot. Les deux
// actions menent aux ecrans existants de l'architecture familiale (doc
// section 4, K-51, rien de recree) : « Inscrire un enfant » ouvre le
// formulaire commun d'ajout d'un profil eleve (`FormulaireProfilEleve`),
// « Inviter ma conjointe » ou « Inviter mon conjoint » (doc section 2, selon
// le genre enregistre du titulaire) ouvre `InviterConjointPage`.
//
// Briques de la page d'invitation, partagees par `part` (rien de recopie) :
// `_Note`, `_Colonne`, `_Carte`, `_Actions` (contrat B : la sortie avant la poursuite,
// groupees au bord de fin).

part of 'invitation_conjoint.dart';

/// « Ajouter ma famille » : l'explication, puis inscrire un enfant (action
/// dominante) et inviter le second adulte (secondaire).
class AjouterMaFamillePage extends StatelessWidget {
  /// Cree la page.
  const AjouterMaFamillePage({
    required this.placeFeminine,
    required this.onRetour,
    this.onInscrireEnfant,
    this.onInviter,
    super.key,
  });

  /// Vrai pour un titulaire homme (« Inviter ma conjointe »), faux pour une
  /// titulaire femme (« Inviter mon conjoint ») : doc section 2.
  final bool placeFeminine;

  /// Retour a Mon espace.
  final VoidCallback onRetour;

  /// Ouvre le formulaire d'ajout d'un enfant ; `null` : aucune action.
  final VoidCallback? onInscrireEnfant;

  /// Ouvre l'invitation du second adulte ; `null` : aucune action.
  final VoidCallback? onInviter;

  /// « Inscrire un enfant ».
  static const Key inscrireEnfantKey = Key('ajouterMaFamille.inscrireEnfant');

  /// « Inviter ma conjointe » ou « Inviter mon conjoint ».
  static const Key inviterKey = Key('ajouterMaFamille.inviter');

  /// Le libelle de l'invitation, selon le genre du titulaire (doc section 2).
  static String libelleInviter({required bool placeFeminine}) => placeFeminine
      ? t.adulte.invitation.titreElle
      : t.adulte.invitation.titreLui;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? inscrire = onInscrireEnfant;
    final VoidCallback? inviter = onInviter;
    return PageShell(
      titre: t.adulte.famille.ajouter,
      onRetour: onRetour,
      // L'explication et ses actions groupees sur une carte, comme les autres
      // ecrans du Foyer (K-42 point 4).
      child: _Colonne(
        auBordDeDebut: true,
        child: _Carte(
          lignes: <Widget>[
            // Doc section 4, mot pour mot : l'espace eleve reste inchange.
            _Note(texte: t.adulte.famille.ajouterPhrase, attenuee: true),
            if (inscrire != null) ...<Widget>[
              // Contrat A : 16 sous l'objet.
              Ecart.vLg,
              _Actions(
                secondaire: inviter == null
                    ? null
                    : ActionPrincipale(
                        key: inviterKey,
                        libelle: libelleInviter(placeFeminine: placeFeminine),
                        onPress: inviter,
                        niveau: NiveauAction.secondaire,
                        pleineLargeur: false,
                      ),
                // « Inscrire un enfant » : libelle provisoire, lexique D4
                // (d'apres « Inscrivez vos enfants », doc section 19).
                principale: ActionPrincipale(
                  key: inscrireEnfantKey,
                  libelle: t.adulte.famille.inscrireEnfant,
                  onPress: inscrire,
                  fleche: true,
                  pleineLargeur: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
