// Le Studio, Mode focus : l'etat et la bascule (`StudioFocusToggle`,
// COM-STU-3 ; spec section 10.1, section 10.2, section 10.6, section 22
// « Focus », COM-W03F, COM-M05).
//
// Le Focus est un ETAT local de COM-W03, jamais une destination : aucune
// route, aucune adresse, aucun plein ecran du navigateur. Il est propre a
// l'appareil de la personne : il n'est transmis a personne, ne change aucun
// droit et ne modifie pas le canal (section 10.2). Il vit dans la coquille du
// Studio ([EtatFocusStudio], pose par `CoquilleStudio`) et se lit par
// [PorteeFocusStudio] : la coquille masque sa navigation, l'espace des canaux
// masque la liste, la recherche et le panneau, le canal garde son contenu et
// son champ.
//
// Le focus CLAVIER suit, sans jamais etre piege : en entrant, il passe a
// « Quitter le focus » (le lecteur d'ecran dit ou sortir) ; en sortant, il
// reste sur l'element qui l'avait (le champ, si l'on quitte par Echap en
// ecrivant), sinon il revient sur « Mode focus ». Aucune portee de focus n'est
// creee : la tabulation parcourt la page comme avant.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/action_principale.dart';
import 'restauration_focus.dart';

/// L'etat du Mode focus d'un Studio ouvert : actif ou non, la capture de ce
/// qu'il faut restaurer, et les deux points de focus clavier (la bascule du
/// canal, la sortie).
class EtatFocusStudio extends ChangeNotifier {
  /// Le restaurateur (`FocusStateRestorer`), aupres duquel l'espace et le
  /// canal inscrivent ce qu'il faut garder.
  final RestaurateurEtatFocus restaurateur = RestaurateurEtatFocus();

  /// Le focus clavier de « Mode focus », dans l'en-tete du canal.
  final FocusNode noeudBascule = FocusNode(debugLabel: 'studio-mode-focus');

  /// Le focus clavier de « Quitter le focus », dans le bandeau de sortie.
  final FocusNode noeudSortie = FocusNode(debugLabel: 'studio-quitter-focus');

  bool _actif = false;
  bool _libere = false;

  /// Le Focus est-il actif ?
  bool get actif => _actif;

  /// Entre dans le Focus : capture l'etat, masque le secondaire, puis donne
  /// le focus clavier a « Quitter le focus ».
  void entrer() {
    if (_actif || _libere) return;
    restaurateur.retenir();
    _actif = true;
    notifyListeners();
    _apresImage(noeudSortie.requestFocus);
  }

  /// Quitte le Focus. Avec [restaurer] (la sortie voulue : bouton, Echap,
  /// retour), l'etat d'avant revient, le texte saisi pendant le Focus garde,
  /// et le focus clavier retourne sur « Mode focus ». Sans (la personne est
  /// allee ailleurs : un autre canal, une autre vue), la capture est oubliee.
  void quitter({bool restaurer = true}) {
    if (!_actif || _libere) return;
    final InstantaneFocus sortie = restaurer
        ? restaurateur.capturer()
        : InstantaneFocus.vide;
    // Ou etait le focus clavier au moment de sortir (le champ, si l'on
    // quitte par Echap en ecrivant).
    final FocusNode? tenu = FocusManager.instance.primaryFocus;
    _actif = false;
    if (!restaurer) restaurateur.oublier();
    notifyListeners();
    if (!restaurer) return;
    _apresImage(() {
      restaurateur.restaurer(sortie);
      _rendreFocusClavier(tenu);
    });
  }

  /// Rend le focus clavier apres la sortie : a l'element qui l'avait (le
  /// champ du fil, un bouton du fil) s'il est encore a l'ecran, pour que la
  /// personne continue la ou elle etait ; sinon (la sortie elle-meme, la
  /// portee de la page apres un clic sur le fond, un element disparu) a
  /// « Mode focus ».
  void _rendreFocusClavier(FocusNode? tenu) {
    final BuildContext? contexte = tenu?.context;
    final bool garde =
        tenu != null &&
        tenu is! FocusScopeNode &&
        !identical(tenu, noeudSortie) &&
        contexte != null &&
        contexte.mounted &&
        tenu.canRequestFocus;
    if (garde) {
      // Deja tenu (le sous-arbre du canal est garde d'une disposition a
      // l'autre) : rien a demander, la selection reste celle restauree.
      if (!tenu.hasPrimaryFocus) tenu.requestFocus();
      return;
    }
    noeudBascule.requestFocus();
  }

  /// Quitte le Focus sans restaurer, a l'image suivante : appele pendant une
  /// construction (changement de canal ou de vue), ou un `notifyListeners`
  /// immediat est interdit.
  void quitterPlusTard() {
    if (!_actif) return;
    _apresImage(() => quitter(restaurer: false));
  }

  void _apresImage(VoidCallback action) {
    SchedulerBinding.instance
      ..addPostFrameCallback((Duration _) {
        if (!_libere) action();
      })
      ..ensureVisualUpdate();
  }

  @override
  void dispose() {
    _libere = true;
    noeudBascule.dispose();
    noeudSortie.dispose();
    super.dispose();
  }
}

/// Donne [EtatFocusStudio] aux descendants de la coquille du Studio, et les
/// reconstruit quand il change.
class PorteeFocusStudio extends InheritedNotifier<EtatFocusStudio> {
  /// Cree la portee.
  const PorteeFocusStudio({
    required EtatFocusStudio etat,
    required super.child,
    super.key,
  }) : super(notifier: etat);

  /// L'etat du Focus du Studio qui entoure [context], ou nul hors d'un
  /// Studio (un canal monte seul n'a pas de Focus). Inscrit [context] aux
  /// changements.
  static EtatFocusStudio? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PorteeFocusStudio>()?.notifier;

  /// Le Focus est-il actif autour de [context] ?
  static bool actif(BuildContext context) => de(context)?.actif ?? false;
}

/// La bascule du Focus (`StudioFocusToggle`) : « Mode focus » dans
/// l'en-tete du canal, « Quitter le focus » dans le bandeau de sortie.
///
/// Hors d'un Studio (aucune [PorteeFocusStudio]), elle n'est pas rendue : un
/// bouton qui ne peut pas aboutir n'existe pas.
class BasculeFocus extends StatelessWidget {
  /// Cree la bascule.
  const BasculeFocus({super.key});

  /// La cle de « Mode focus », pour les tests.
  static const ValueKey<String> cleEntrer = ValueKey<String>(
    'studio-focus-entrer',
  );

  /// La cle de « Quitter le focus », pour les tests.
  static const ValueKey<String> cleQuitter = ValueKey<String>(
    'studio-focus-quitter',
  );

  @override
  Widget build(BuildContext context) {
    final EtatFocusStudio? etat = PorteeFocusStudio.de(context);
    if (etat == null) return const SizedBox.shrink();
    final f = t.com.studio.focus;
    if (etat.actif) {
      return ActionPrincipale(
        key: cleQuitter,
        libelle: f.quitter,
        onPress: etat.quitter,
        niveau: NiveauAction.secondaire,
        pleineLargeur: false,
        compacte: true,
        focusNode: etat.noeudSortie,
      );
    }
    // L'aide (section 22) dit ce que fait le Focus, au survol et au lecteur
    // d'ecran.
    return Tooltip(
      message: f.aide,
      child: ActionPrincipale(
        key: cleEntrer,
        libelle: f.entrer,
        onPress: etat.entrer,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        compacte: true,
        // Lot K, point 3 : le libelle s'aligne sur le titre du canal.
        affleurant: true,
        focusNode: etat.noeudBascule,
      ),
    );
  }
}
