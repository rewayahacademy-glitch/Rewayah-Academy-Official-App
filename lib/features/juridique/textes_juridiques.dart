// Les textes juridiques lisibles dans l'application (mentions legales,
// conditions d'utilisation et de vente, annulation et remboursement,
// confidentialite, cookies, protection des enfants).
//
// Source des textes : `t.juridique.*` (fr de base, ar obligatoire), ecrits
// d'apres `docs/current/DECISION-TARIFS-2026-10-18.md`, `JUR-APP-1_RESTES.md`,
// `01`, `02`, `06` et `DECISION-ENTREE-2026-10-17.md`. Rien n'y est invente :
// ce que seule la direction peut donner est un [ChampJuridique], rendu comme
// un repere « [a completer par la direction : ...] » tant qu'il n'est pas
// renseigne. Depuis le 19/10/2026, les sept valeurs sont donnees par le
// directeur et vivent dans `t.juridique.valeurs.*` (fr, ar).
//
// Aucun montant n'est ecrit : les textes renvoient aux Tarifs.
//
// Pas d'etat de chargement, d'erreur ni de hors ligne : le texte est compile
// dans l'application, aucun reseau n'est en jeu. Fiche d'ecran :
// `docs/current/CATALOGUE_ECRANS_JURIDIQUE.md` (JUR-3, JUR-4).

import '../../core/conformite/representant_ue.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/protection_enfants/responsable_protection.dart';
import '../../core/router/routes.dart';
import '../dossier/politique_controle.dart' show SectionPolitique;
import '../salle_seance/information_controle.dart';

/// Les six textes, dans l'ordre de la liste.
enum TexteJuridique {
  /// Mentions legales.
  mentions('mentions-legales'),

  /// Conditions d'utilisation et de vente.
  conditions('conditions'),

  /// Annulation et remboursement.
  annulation('annulation-remboursement'),

  /// Confidentialite.
  confidentialite('confidentialite'),

  /// Cookies.
  cookies('cookies'),

  /// Protection des enfants.
  enfants('protection-des-enfants');

  const TexteJuridique(this.slug);

  /// Le dernier segment de l'adresse (`/juridique/<slug>`).
  final String slug;

  /// L'adresse du texte.
  String get chemin => '${Routes.juridique}/$slug';

  /// Le texte d'un [slug], ou `null`.
  static TexteJuridique? depuisSlug(String slug) {
    for (final TexteJuridique x in values) {
      if (x.slug == slug) return x;
    }
    return null;
  }

  /// Le titre du texte.
  String get titre => switch (this) {
    mentions => t.juridique.mentions.titre,
    conditions => t.juridique.conditions.titre,
    annulation => t.juridique.annulation.titre,
    confidentialite => t.juridique.confidentialite.titre,
    cookies => t.juridique.cookies.titre,
    enfants => t.juridique.enfants.titre,
  };

  /// Une ligne qui dit de quoi parle le texte.
  String get resume => switch (this) {
    mentions => t.juridique.mentions.resume,
    conditions => t.juridique.conditions.resume,
    annulation => t.juridique.annulation.resume,
    confidentialite => t.juridique.confidentialite.resume,
    cookies => t.juridique.cookies.resume,
    enfants => t.juridique.enfants.resume,
  };

  /// La phrase d'ouverture du texte.
  String get intro => switch (this) {
    mentions => t.juridique.mentions.intro,
    conditions => t.juridique.conditions.intro,
    annulation => t.juridique.annulation.intro,
    confidentialite => t.juridique.confidentialite.intro,
    cookies => t.juridique.cookies.intro,
    enfants => t.juridique.enfants.intro,
  };
}

/// La version et la date des textes. Une seule pour les six : ils se
/// publient et se relisent ensemble. Meme version sur le site public
/// (`docs/orchestration/site-public/juridique-2026-10-18.json`).
abstract final class VersionsJuridiques {
  /// La version affichee.
  static const String version = '2026-10-v1';

  /// La date du texte.
  static final DateTime date = DateTime(2026, 10, 18);
}

/// Ce que seule la direction peut donner.
enum ChampJuridique {
  /// Hebergeur legal et ses coordonnees.
  hebergeur,

  /// Pays d'hebergement des informations.
  lieuxHebergement,

  /// Duree de conservation par type d'information.
  dureesConservation,

  /// Droit applicable et juridiction competente.
  droitApplicable,

  /// Relecture par un conseil juridique (droit de retractation compris).
  confirmationConseil,

  /// Moyen et delai du remboursement.
  remboursementModalites,

  /// Responsable de la protection des enfants.
  responsableEnfants;

  /// Ce qu'il faut donner, en mots.
  String get etiquette => switch (this) {
    hebergeur => t.juridique.quoi.hebergeur,
    lieuxHebergement => t.juridique.quoi.lieuxHebergement,
    dureesConservation => t.juridique.quoi.dureesConservation,
    droitApplicable => t.juridique.quoi.droitApplicable,
    confirmationConseil => t.juridique.quoi.confirmationConseil,
    remboursementModalites => t.juridique.quoi.remboursementModalites,
    responsableEnfants => t.juridique.quoi.responsableEnfants,
  };
}

/// Les valeurs donnees par le directeur (19/10/2026), lues dans
/// `t.juridique.valeurs.*` : le texte suit la langue choisie. Un champ absent
/// de la table redevient un repere « a completer ». (Pas de lecture en base :
/// ces valeurs changent une fois, avec une nouvelle version des textes.)
abstract final class CoordonneesJuridiques {
  /// Les champs renseignes, dans la langue courante.
  static Map<ChampJuridique, String> get renseignes => <ChampJuridique, String>{
    ChampJuridique.hebergeur: t.juridique.valeurs.hebergeur,
    ChampJuridique.lieuxHebergement: t.juridique.valeurs.lieuxHebergement,
    ChampJuridique.dureesConservation: t.juridique.valeurs.dureesConservation,
    ChampJuridique.droitApplicable: t.juridique.valeurs.droitApplicable,
    ChampJuridique.confirmationConseil: t.juridique.valeurs.confirmationConseil,
    ChampJuridique.remboursementModalites:
        t.juridique.valeurs.remboursementModalites,
    ChampJuridique.responsableEnfants: responsable(null),
  };

  /// La phrase du responsable de la protection des enfants. Le nom et le
  /// courriel viennent du reglage de la direction ; sans reglage (vide, non
  /// connecte, lecture en erreur, `null`), le nom est celui de l'academie et
  /// l'adresse est le contact existant. Jamais de repere « a completer ».
  static String responsable(ResponsableProtection? lu) =>
      t.juridique.valeurs.responsableEnfants(
        nom: lu != null && lu.estNomme
            ? lu.nom
            : t.juridique.valeurs.responsableDefaut,
        contact: lu != null && lu.aUnCourriel
            ? lu.courriel
            : InformationControle.contactConfidentialite,
      );

  /// Les champs encore a donner.
  static List<ChampJuridique> aCompleter([
    Map<ChampJuridique, String>? renseignes,
  ]) {
    final Map<ChampJuridique, String> donnes =
        renseignes ?? CoordonneesJuridiques.renseignes;
    return <ChampJuridique>[
      for (final ChampJuridique c in ChampJuridique.values)
        if (!donnes.containsKey(c)) c,
    ];
  }
}

/// Une valeur donnee se lit seule : ce sont des phrases entieres, qui
/// portent deja leur sujet.
String _champ(ChampJuridique c, Map<ChampJuridique, String> renseignes) =>
    renseignes[c] ?? t.juridique.aCompleter(quoi: c.etiquette);

/// Les sections d'un texte, dans l'ordre, avec les lignes de coordonnees et
/// les reperes a completer a la place prevue. [responsable] est la lecture
/// du reglage de la direction (`null` : le defaut). [representantUe] est celle
/// du representant dans l'Union europeenne (vide ou `null` : « Rewayah
/// Academy »).
List<SectionPolitique> sectionsJuridiques(
  TexteJuridique texte, {
  String contact = InformationControle.contactConfidentialite,
  Map<ChampJuridique, String>? renseignes,
  ResponsableProtection? responsable,
  String? representantUe,
}) {
  final Map<ChampJuridique, String> donnes =
      renseignes ??
      <ChampJuridique, String>{
        ...CoordonneesJuridiques.renseignes,
        ChampJuridique.responsableEnfants: CoordonneesJuridiques.responsable(
          responsable,
        ),
      };
  final String ecrire = t.juridique.contact(contact: contact);
  List<String> plus(List<String> blocs, List<String> en) => <String>[
    ...blocs,
    ...en,
  ];
  switch (texte) {
    case TexteJuridique.mentions:
      final j = t.juridique.mentions;
      return <SectionPolitique>[
        (
          titre: j.s1.titre,
          blocs: plus(j.s1.blocs, <String>[
            t.juridique.coord.societe,
            t.juridique.coord.numero,
            t.juridique.coord.adresse,
          ]),
        ),
        (titre: j.s2.titre, blocs: plus(j.s2.blocs, <String>[ecrire])),
        (
          titre: j.s3.titre,
          blocs: plus(j.s3.blocs, <String>[
            _champ(ChampJuridique.hebergeur, donnes),
            _champ(ChampJuridique.lieuxHebergement, donnes),
          ]),
        ),
        (titre: j.s4.titre, blocs: j.s4.blocs),
      ];
    case TexteJuridique.conditions:
      final j = t.juridique.conditions;
      return <SectionPolitique>[
        (titre: j.s1.titre, blocs: j.s1.blocs),
        (titre: j.s2.titre, blocs: j.s2.blocs),
        (titre: j.s3.titre, blocs: j.s3.blocs),
        (titre: j.s4.titre, blocs: j.s4.blocs),
        (titre: j.s5.titre, blocs: j.s5.blocs),
        (titre: j.s6.titre, blocs: j.s6.blocs),
        (
          titre: j.s7.titre,
          blocs: plus(j.s7.blocs, <String>[
            _champ(ChampJuridique.droitApplicable, donnes),
            _champ(ChampJuridique.confirmationConseil, donnes),
          ]),
        ),
      ];
    case TexteJuridique.annulation:
      final j = t.juridique.annulation;
      return <SectionPolitique>[
        (titre: j.s1.titre, blocs: j.s1.blocs),
        (titre: j.s2.titre, blocs: j.s2.blocs),
        (titre: j.s3.titre, blocs: j.s3.blocs),
        (titre: j.s4.titre, blocs: j.s4.blocs),
        (titre: j.s5.titre, blocs: j.s5.blocs),
        (
          titre: j.s6.titre,
          blocs: plus(j.s6.blocs, <String>[
            ecrire,
            _champ(ChampJuridique.remboursementModalites, donnes),
            _champ(ChampJuridique.confirmationConseil, donnes),
          ]),
        ),
      ];
    case TexteJuridique.confidentialite:
      final j = t.juridique.confidentialite;
      return <SectionPolitique>[
        (
          titre: j.s1.titre,
          blocs: plus(j.s1.blocs, <String>[
            j.s1.representant(nom: representantUeAffiche(representantUe)),
            ecrire,
          ]),
        ),
        (titre: j.s2.titre, blocs: j.s2.blocs),
        (titre: j.s3.titre, blocs: j.s3.blocs),
        (titre: j.s4.titre, blocs: j.s4.blocs),
        (titre: j.s5.titre, blocs: j.s5.blocs),
        (
          titre: j.s6.titre,
          blocs: plus(j.s6.blocs, <String>[
            _champ(ChampJuridique.lieuxHebergement, donnes),
          ]),
        ),
        (
          titre: j.s7.titre,
          blocs: plus(j.s7.blocs, <String>[
            _champ(ChampJuridique.dureesConservation, donnes),
          ]),
        ),
        (titre: j.s8.titre, blocs: j.s8.blocs),
        (titre: j.s9.titre, blocs: j.s9.blocs),
        (titre: j.s10.titre, blocs: j.s10.blocs),
      ];
    case TexteJuridique.cookies:
      final j = t.juridique.cookies;
      return <SectionPolitique>[
        (titre: j.s1.titre, blocs: j.s1.blocs),
        (titre: j.s2.titre, blocs: j.s2.blocs),
        (titre: j.s3.titre, blocs: j.s3.blocs),
        (titre: j.s4.titre, blocs: j.s4.blocs),
        (titre: j.s5.titre, blocs: j.s5.blocs),
        (titre: j.s6.titre, blocs: j.s6.blocs),
      ];
    case TexteJuridique.enfants:
      final j = t.juridique.enfants;
      return <SectionPolitique>[
        (titre: j.s1.titre, blocs: j.s1.blocs),
        (titre: j.s2.titre, blocs: j.s2.blocs),
        (titre: j.s3.titre, blocs: j.s3.blocs),
        (titre: j.s4.titre, blocs: j.s4.blocs),
        (
          titre: j.s5.titre,
          blocs: plus(j.s5.blocs, <String>[
            ecrire,
            _champ(ChampJuridique.responsableEnfants, donnes),
          ]),
        ),
      ];
  }
}
