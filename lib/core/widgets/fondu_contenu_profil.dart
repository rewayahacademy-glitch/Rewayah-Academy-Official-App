// PROFILS-EFFET (directeur, 12/11/2026, 07:11 UTC) : « On abandonne la goutte
// entre profils, on ajoute un simple effet pour le contenu du profil et un
// autre qui montre le profil selectionne. »
//
// Cet effet-ci est celui du contenu : quand le profil change, le contenu
// change par un fondu court, avec un leger glissement (une translation d'un
// ajout de liste au plus). L'autre effet, le profil selectionne, est le rond
// de `CercleSelectionnable` : il grandit au ressort et son anneau prend
// l'accent en douceur.
//
// La selection n'attend jamais l'effet : le rond est pris des le toucher, le
// contenu suit. Durees et courbes viennent de `AppMouvement` ; sous
// « reduire les animations », le changement est instantane ; jamais de boucle.

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';

/// Le contenu d'un profil, qui change par un fondu quand [profilId] change.
class FonduContenuProfil extends StatelessWidget {
  /// Cree l'effet.
  const FonduContenuProfil({
    required this.profilId,
    required this.child,
    super.key,
  });

  /// Le profil dont le contenu est montre : un autre, et le contenu change.
  final String profilId;

  /// Le contenu du profil.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Duration duree = AppMouvement.duree(
      context,
      AppMouvement.fonduContenuProfil,
    );
    final double glissement = AppMouvement.translation(
      context,
      AppMouvement.translationAjout,
    );
    return AnimatedSwitcher(
      duration: duree,
      reverseDuration: duree,
      switchInCurve: AppMouvement.courbeContenuProfil,
      switchOutCurve: AppMouvement.courbeContenuProfil,
      layoutBuilder: (Widget? courant, List<Widget> precedents) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[...precedents, ?courant],
      ),
      transitionBuilder: (Widget enfant, Animation<double> animation) =>
          FadeTransition(
            opacity: animation,
            child: AnimatedBuilder(
              animation: animation,
              builder: (BuildContext _, Widget? contenu) => Transform.translate(
                offset: Offset(0, (1 - animation.value) * glissement),
                child: contenu,
              ),
              child: enfant,
            ),
          ),
      child: KeyedSubtree(key: ValueKey<String>(profilId), child: child),
    );
  }
}
