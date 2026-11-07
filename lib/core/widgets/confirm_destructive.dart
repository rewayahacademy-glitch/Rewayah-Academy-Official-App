import 'package:flutter/material.dart';

import '../accessibilite/signaler_manque.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'app_bottom_sheet.dart';
import 'zone_saisie.dart';

/// Les trois temps du destructif : question, consequence, deux actions.
///
/// **Seul point d'entree d'une confirmation destructive.** Jamais
/// `clic vers suppression`, et jamais une `AlertDialog` posee dans un ecran :
/// `docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 6 interdit tout autre
/// chemin.
///
/// Trois regles portees par l'API elle-meme, et non par la relecture
/// (`02-regles-ux.md` section 5) :
///
/// 1. [consequence] est **obligatoire**, et s'ecrit en langage humain : « Son
///    acces sera desactive et ses cahiers ne seront plus consultables depuis ce
///    foyer », jamais « supprimer la ligne ? » ;
/// 2. [libelleConfirmer] **nomme l'objet et l'acte** : « Retirer Aicha », jamais
///    « Supprimer » ni « OK » ;
/// 3. le bouton destructif n'est **ni le premier atteint au doigt ni le premier
///    au clavier** : « Annuler » vient avant lui dans l'ordre de lecture, donc
///    dans l'ordre de tabulation.
class ConfirmDestructive extends StatelessWidget {
  /// Cree le corps d'une confirmation.
  ///
  /// Rendu directement plutot que par [demander] dans la galerie : c'est le
  /// seul moyen de montrer ses etats sans ouvrir une vraie feuille.
  const ConfirmDestructive({
    required this.question,
    required this.consequence,
    required this.libelleConfirmer,
    required this.onConfirmer,
    required this.onAnnuler,
    super.key,
    this.irreversible = false,
    this.libelleAnnuler,
    this.saisie,
    this.etatSaisie,
  });

  /// La cle du champ de saisie, quand [saisie] est posee.
  static const Key champSaisieKey = ValueKey<String>(
    'confirmDestructive.saisie',
  );

  /// Une saisie exigee avant le destructif (prenom d'un enfant, par exemple).
  ///
  /// SUPPRIMER-PRENOM (pilote et garde-cap, 07/11/2026) : deux appuis rapides
  /// ne suffisent plus a supprimer. Le bouton n'est **jamais grise** (K-56) :
  /// une saisie fausse met le champ en rouge, le dit et lui rend le focus.
  final SaisieConfirmation? saisie;

  /// L'etat du champ, partage avec les actions de la feuille ([demander]).
  /// Sans lui, le corps cree le sien (galerie).
  final EtatSaisieConfirmation? etatSaisie;

  /// La question, qui nomme l'objet : « Retirer Aicha du foyer ? »
  final String question;

  /// Ce qui arrivera, en langage humain. Jamais un terme technique.
  final String consequence;

  /// Le libelle de l'action destructive : un verbe et son objet.
  final String libelleConfirmer;

  /// Ce qui se passe quand la personne confirme.
  final VoidCallback onConfirmer;

  /// Ce qui se passe quand la personne renonce.
  final VoidCallback onAnnuler;

  /// Vrai quand l'acte ne se defait pas.
  ///
  /// **Ce qui n'est pas reversible le dit.** Ce qui l'est propose plutot une
  /// annulation de quelques secondes dans le retour local, et n'a alors pas
  /// besoin de cette feuille du tout.
  final bool irreversible;

  /// Le libelle du renoncement, quand un texte exact le nomme (« Rester »).
  /// Par defaut : « Annuler ».
  final String? libelleAnnuler;

  /// Ouvre la confirmation et rend `true` si la personne a confirme.
  ///
  /// Rend `false` en cas d'annulation **comme en cas de fermeture par le
  /// glissement ou par `Echap`** : une feuille fermee n'a rien confirme.
  ///
  /// Sur bureau, la meme confirmation s'ouvre en boite de dialogue centree
  /// (`AppBottomSheet.ouvrir`, `FormeModale.dialogue`) : memes actions, meme
  /// ordre de lecture et de tabulation, « Annuler » toujours avant le
  /// destructif au clavier.
  static Future<bool> demander(
    BuildContext context, {
    required String question,
    required String consequence,
    required String libelleConfirmer,
    bool irreversible = false,
    String? libelleAnnuler,
    bool annulerParDefaut = false,
    SaisieConfirmation? saisie,
  }) async {
    // L'etat du champ vit avec le corps de la feuille, qui le libere quand il
    // disparait ; les actions le lisent seulement.
    final EtatSaisieConfirmation? etat = saisie == null
        ? null
        : EtatSaisieConfirmation();
    void confirmer(BuildContext contexte) {
      if (saisie != null && etat != null && !saisie.correspond(etat.texte)) {
        etat.signaler();
        signalerManque(contexte, saisie.erreur, champ: etat.noeud);
        return;
      }
      Navigator.of(contexte).pop(true);
    }

    final bool? reponse = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: question,
      constructeur: (BuildContext contexte) => ConfirmDestructive(
        question: question,
        consequence: consequence,
        libelleConfirmer: libelleConfirmer,
        irreversible: irreversible,
        libelleAnnuler: libelleAnnuler,
        saisie: saisie,
        etatSaisie: etat,
        onConfirmer: () => confirmer(contexte),
        onAnnuler: () => Navigator.of(contexte).pop(false),
      ),
      // La feuille porte deja la question en titre : le corps n'affiche donc
      // que la consequence, et les deux actions vivent dans la zone collee.
      actions: (BuildContext contexte) => _Actions(
        libelleConfirmer: libelleConfirmer,
        libelleAnnuler: libelleAnnuler,
        annulerParDefaut: annulerParDefaut,
        onConfirmer: () => confirmer(contexte),
        onAnnuler: () => Navigator.of(contexte).pop(false),
      ),
    );
    return reponse ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          consequence,
          style: palette.surfaceRaised.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (irreversible) ...<Widget>[
          Ecart.vMd,
          Text(
            t.destructif.irreversible,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        if (saisie case final SaisieConfirmation demande) ...<Widget>[
          Ecart.vLg,
          _ChampConfirmation(
            saisie: demande,
            etat: etatSaisie,
            onValider: onConfirmer,
          ),
        ],
      ],
    );
  }
}

/// Ce que la personne doit ecrire avant le destructif.
class SaisieConfirmation {
  /// Cree la demande.
  const SaisieConfirmation({
    required this.attendu,
    required this.libelle,
    required this.erreur,
  });

  /// Le texte attendu (un prenom).
  final String attendu;

  /// Le nom du champ, qui dit quoi ecrire.
  final String libelle;

  /// La phrase rouge sous le champ quand la saisie ne correspond pas.
  final String erreur;

  /// Vrai quand [saisi] est [attendu], sans tenir compte de la casse ni des
  /// espaces en trop.
  bool correspond(String saisi) => _normal(saisi) == _normal(attendu);

  static String _normal(String texte) =>
      texte.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// L'etat du champ de [SaisieConfirmation] : le texte, le focus, l'erreur.
class EtatSaisieConfirmation extends ChangeNotifier {
  /// Le texte saisi.
  final TextEditingController controleur = TextEditingController();

  /// Le focus du champ, rendu apres une saisie fausse.
  final FocusNode noeud = FocusNode(debugLabel: 'confirmDestructive.saisie');

  bool _enErreur = false;

  /// Vrai apres une saisie fausse, jusqu'a la frappe suivante.
  bool get enErreur => _enErreur;

  /// Le texte du champ.
  String get texte => controleur.text;

  /// Marque la saisie comme fausse.
  void signaler() {
    _enErreur = true;
    notifyListeners();
  }

  /// Efface l'erreur a la frappe.
  void effacer() {
    if (!_enErreur) return;
    _enErreur = false;
    notifyListeners();
  }

  @override
  void dispose() {
    controleur.dispose();
    noeud.dispose();
    super.dispose();
  }
}

/// Le champ de [SaisieConfirmation], avec la zone de saisie partagee.
class _ChampConfirmation extends StatefulWidget {
  const _ChampConfirmation({
    required this.saisie,
    required this.onValider,
    this.etat,
  });

  final SaisieConfirmation saisie;
  final EtatSaisieConfirmation? etat;
  final VoidCallback onValider;

  @override
  State<_ChampConfirmation> createState() => _ChampConfirmationState();
}

class _ChampConfirmationState extends State<_ChampConfirmation> {
  late final EtatSaisieConfirmation _etat =
      widget.etat ?? EtatSaisieConfirmation();

  @override
  void dispose() {
    // Le corps de la feuille est le dernier a lire l'etat : il le libere.
    _etat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _etat,
      builder: (BuildContext context, Widget? _) => ZoneSaisie(
        controleur: _etat.controleur,
        cleChamp: ConfirmDestructive.champSaisieKey,
        noeud: _etat.noeud,
        libelle: widget.saisie.libelle,
        erreur: _etat.enErreur ? widget.saisie.erreur : null,
        maxLignes: 1,
        // Le clavier s'ouvre : la feuille change de place, et le bouton de
        // confirmation n'est plus la ou etait la ligne qui l'a ouverte.
        autofocus: true,
        majuscules: TextCapitalization.words,
        actionClavier: TextInputAction.done,
        onChanged: (String _) => _etat.effacer(),
        onSubmitted: (String _) => widget.onValider(),
      ),
    );
  }
}

/// Les deux actions, asymetriques et dans cet ordre.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.libelleConfirmer,
    required this.onConfirmer,
    required this.onAnnuler,
    this.libelleAnnuler,
    this.annulerParDefaut = false,
  });

  /// Mode du remboursement : « Annuler » a le focus des l'ouverture ; Entree
  /// au clavier renonce, jamais ne confirme. Garde-fou demande par le
  /// directeur le 02/11/2026 contre un remboursement par accident ; la seconde
  /// fenetre est un choix du pilote.
  final bool annulerParDefaut;

  final String libelleConfirmer;
  final String? libelleAnnuler;
  final VoidCallback onConfirmer;
  final VoidCallback onAnnuler;

  @override
  Widget build(BuildContext context) {
    // La feuille est ancree au bas de l'ecran : le bas est la zone du pouce.
    // Le destructif n'y est donc **jamais** le premier atteint au doigt, et
    // l'ordre de clavier est force pour qu'il ne le soit pas non plus la
    // (`02-regles-ux.md` section 5). D'ou la dissociation : le destructif est
    // physiquement en haut, « Annuler » en bas et au rang de tabulation 1.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: ActionPrincipale(
              libelle: libelleConfirmer,
              onPress: onConfirmer,
              niveau: NiveauAction.destructive,
            ),
          ),
          Ecart.vMd,
          // Le plus bas au pouce, le premier au clavier : c'est le renoncement
          // qui est a portee, pas la suppression.
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: ActionPrincipale(
              libelle: libelleAnnuler ?? t.commun.annuler,
              onPress: onAnnuler,
              niveau: NiveauAction.secondaire,
              autofocus: annulerParDefaut,
            ),
          ),
        ],
      ),
    );
  }
}
