// Ligne 7 de la fiche du 27/10/2026 : une classe supprimee pendant que son
// ecran est ouvert dit « Cette classe n'existe plus. » et ramene a l'accueil
// du role. Partage par la Classe du tuteur et la fiche de classe de
// l'enseignante : la regle vit une fois.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../router/routes.dart';
import '../session/session_controleur.dart';
import 'avis_ephemere.dart';

/// Vrai quand une lecture qui montrait la classe vient de la perdre : lue
/// avant avec la classe ([presente] vraie), relue sans elle, la relecture
/// finie et sans echec. Un chargement en cours ou un echec de reseau ne
/// valent jamais « n'existe plus ». Pure.
bool classeDisparue<T>(
  AsyncValue<T>? avant,
  AsyncValue<T> apres, {
  required bool Function(T valeur) presente,
}) =>
    avant != null &&
    avant.hasValue &&
    presente(avant.requireValue) &&
    apres.hasValue &&
    !apres.isLoading &&
    !apres.hasError &&
    !presente(apres.requireValue);

/// Dit « Cette classe n'existe plus. » et revient a l'accueil du role de la
/// personne connectee.
void revenirApresClasseDisparue(BuildContext context, WidgetRef ref) {
  ref.read(avisEphemereProvider.notifier).dire(t.classe.disparue);
  final AppRole role = ref.read(sessionProvider).role ?? AppRole.guardian;
  GoRouter.of(context).go(Routes.racinePour(role));
}
