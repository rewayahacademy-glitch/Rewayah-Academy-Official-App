// Le nom d'un compte officiel (directeur, 16/11/2026 ; 17/11/2026 : « il
// s'appelle Ra_Praxis, Ra = Rewayah Academy », « supprime l'effet italique ») :
// le nom affiche est « #Ra_Praxis », avec le « # » devant, SANS italique. Il est
// rendu par l'application a partir de l'indicateur `officiel` du compte, comme
// « #Ra_staff » (`MarqueStaff`) : jamais range dans le nom en base.
//
// **Seule regle** : la ligne de conversation, l'en-tete du fil, l'auteur d'une
// bulle et la fiche du profil passent par ce fichier.
//
// Le nom et le « # » sont isoles de gauche a droite (\u2066 ... \u2069) : en
// arabe, sans isolement, le « # » passait a la fin (« Ra_Praxis# »).

import '../i18n/strings.g.dart';

/// Le nom affiche d'un compte officiel : « #Ra_Praxis », isole pour le sens
/// de lecture. Le nom en base ne sert pas.
String nomOfficielMarque() =>
    '\u2066#${t.com.messages.panneau.officiel.nom}\u2069';

/// Le nom a afficher : celui du compte officiel si [officiel], [nom] sinon.
String nomAvecMarque(String nom, {required bool officiel}) =>
    officiel ? nomOfficielMarque() : nom;
