// Ce qui personnalise la carte a partager (CAND-06) : la langue de la carte et
// la variante de la personne qui partage.
//
// **Quatre langues, pas une de plus** (directeur, 22/10/2026 : « pas les langues
// vernaculaires, juste les internationales ; regarde la langue dans laquelle le
// candidat veut enseigner et utilise celle-la », puis « il va aussi avoir le
// portugais ») : le francais, l'anglais, le portugais et l'arabe. Une langue de
// cours qui n'est pas l'une des trois premieres (poular, wolof, bambara...) ne
// donne pas de carte : la carte reste alors dans la langue de l'application.
//
// **Langue par defaut** : la premiere langue d'enseignement de la personne (sa
// reponse `languesExplication`, lue par le port de sa candidature) qui est le
// francais, l'anglais ou le portugais ; sinon la langue de l'application
// (francais ou arabe). L'arabe n'est jamais une langue de cours (decision du
// 22/10), donc il ne vient que de la langue de l'application ou du choix de la
// personne, qui change la langue de la carte avant de partager.
//
// **Variante** : lue sur le profil de la personne (`profiles.gender`), jamais
// devinee. Un genre inconnu (profil illisible, hors ligne) donne la variante des
// hommes, qui n'a aucun personnage et dont les mots ne s'adressent a personne en
// particulier : c'est la variante neutre.
library;

import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../candidature/modeles_candidature.dart';
import '../candidature/port_ma_candidature.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import 'port_genre_partageur.dart';

/// Une langue de la carte, dans l'ordre des puces de la page de partage.
enum LangueCarte {
  /// Le francais.
  francais('fr', <String>['francais', 'fr']),

  /// L'anglais.
  anglais('en', <String>['english', 'en']),

  /// Le portugais. Le referentiel des langues de cours ne le porte pas encore
  /// (`poular`, `francais`, `english`) : il prendra le code ISO `pt`, comme les
  /// langues hors referentiel du questionnaire (`salle-examen-1`), ou un nom
  /// de referentiel du meme genre que `francais`.
  portugais('pt', <String>['pt', 'portugais', 'portugues', 'portuguese']),

  /// L'arabe : le texte de la carte se lit de droite a gauche. Jamais une
  /// langue de cours : aucun code du questionnaire ne mene a lui.
  arabe('ar', <String>[]);

  const LangueCarte(this.code, this.codesEnseignement);

  /// Le code court (`fr`, `en`, `pt`, `ar`).
  final String code;

  /// Les codes de la langue dans le questionnaire de la candidature
  /// (`languesExplication`) : le code du referentiel des langues de cours, ou
  /// le code ISO d'une langue ouverte plus tard. Vide pour l'arabe.
  final List<String> codesEnseignement;

  /// Vrai quand le texte de la carte se lit de droite a gauche.
  bool get droiteAGauche => this == LangueCarte.arabe;

  /// Le sens du texte de la carte.
  TextDirection get sens =>
      droiteAGauche ? TextDirection.rtl : TextDirection.ltr;

  /// La langue d'un code du questionnaire (`francais`, `english`, `pt`), ou
  /// `null` pour toute autre langue : poular, wolof, bambara... et l'arabe.
  static LangueCarte? depuisCodeEnseignement(String code) {
    for (final LangueCarte l in values) {
      if (l.codesEnseignement.contains(code)) {
        return l;
      }
    }
    return null;
  }

  /// La langue de la carte quand rien d'autre ne la decide : celle de
  /// l'application (francais ou arabe).
  static LangueCarte depuisLocale(AppLocale locale) =>
      locale == AppLocale.ar ? arabe : francais;
}

/// Les deux variantes de la carte.
enum VarianteCarte {
  /// Les hommes, et le genre inconnu : la composition sans personnage.
  hommes,

  /// Les femmes : une teinte plus douce et une fine branche fleurie ton sur ton,
  /// sans aucun personnage.
  femmes;

  /// La variante d'un genre lu sur le profil ; `null` (inconnu) donne la
  /// variante des hommes, la neutre.
  static VarianteCarte depuisGenre(Genre? genre) =>
      genre == Genre.femme ? femmes : hommes;
}

/// La langue par defaut de la carte, pure.
///
/// [languesEnseignement] est la reponse `languesExplication` de la personne,
/// dans l'ordre ou le serveur la range. [langueApp] est la langue de
/// l'application. La premiere langue d'enseignement qui est le francais,
/// l'anglais ou le portugais gagne ; sinon [langueApp].
LangueCarte langueCarteParDefaut({
  required Iterable<String> languesEnseignement,
  required LangueCarte langueApp,
}) {
  for (final String code in languesEnseignement) {
    final LangueCarte? l = LangueCarte.depuisCodeEnseignement(code);
    if (l != null) {
      return l;
    }
  }
  return langueApp;
}

/// Les langues d'enseignement de la personne (`languesExplication`), dans
/// l'ordre du serveur ; vide quand elles ne se lisent pas (aucune candidature,
/// serveur indisponible, hors ligne). Une lecture qui echoue ne bloque jamais la
/// carte : elle prend alors la langue de l'application.
final FutureProvider<List<String>> languesEnseignementCandidatProvider =
    FutureProvider.autoDispose<List<String>>((Ref ref) async {
      try {
        final Questionnaire q = await ref.watch(
          questionnaireCandidatProvider.future,
        );
        final Object? valeur =
            q.dernieresReponses?.reponses['languesExplication'];
        if (valeur is! List) {
          return const <String>[];
        }
        return <String>[
          for (final Object? code in valeur)
            if (code is String) code,
        ];
      } on Object {
        return const <String>[];
      }
    });

/// Ce qui personnalise la carte de la personne qui partage, lu une fois : sa
/// variante (son genre, jamais deviné) et ses langues d'enseignement.
@immutable
class ReglagesCarte {
  /// Cree les reglages.
  const ReglagesCarte({
    this.variante = VarianteCarte.hommes,
    this.languesEnseignement = const <String>[],
  });

  /// La variante : les femmes si le profil le dit, les hommes sinon.
  final VarianteCarte variante;

  /// Les langues d'enseignement de la personne, dans l'ordre du serveur.
  final List<String> languesEnseignement;

  /// La langue de la carte au depart, pour la langue [langueApp] de
  /// l'application.
  LangueCarte langueParDefaut(LangueCarte langueApp) => langueCarteParDefaut(
    languesEnseignement: languesEnseignement,
    langueApp: langueApp,
  );
}

/// Le temps que la page accorde a chaque lecture de personnalisation : la carte
/// est un geste facultatif, elle n'attend pas un serveur lent. Passe ce delai, la
/// lecture vaut « inconnu ».
const Duration delaiReglagesCarte = Duration(seconds: 5);

/// Les reglages de la carte : le genre (`genrePartageurProvider`) et les
/// langues d'enseignement (`languesEnseignementCandidatProvider`), lus
/// ensemble. Aucune des deux lectures n'echoue vers la page et aucune n'attend
/// plus de [delaiReglagesCarte] : une lecture manquante vaut « inconnu »
/// (variante des hommes, langue de l'application).
final FutureProvider<ReglagesCarte> reglagesCarteProvider =
    FutureProvider.autoDispose<ReglagesCarte>((Ref ref) async {
      final (Genre? genre, List<String> langues) = await (
        ref
            .watch(genrePartageurProvider.future)
            .timeout(delaiReglagesCarte, onTimeout: () => null),
        ref
            .watch(languesEnseignementCandidatProvider.future)
            .timeout(delaiReglagesCarte, onTimeout: () => const <String>[]),
      ).wait;
      return ReglagesCarte(
        variante: VarianteCarte.depuisGenre(genre),
        languesEnseignement: langues,
      );
    });

/// L'invitation a partager, dite a la personne (la tuile et le titre de la
/// page) : « une sœur » pour une femme, « une personne » sinon (directeur,
/// 22/10/2026). Une phrase, sans explication, jamais au nom de l'academie.
String invitationPartage(VarianteCarte variante) =>
    variante == VarianteCarte.femmes
    ? t.recrutement.partage.titreFemme
    : t.recrutement.partage.titre;
