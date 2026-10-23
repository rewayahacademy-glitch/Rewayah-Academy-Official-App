// Les textes de « Vos autres talents » (`CAND-07`), retrouves par le code du
// serveur.
//
// Le serveur rend des codes (`comptabilite`, `metier`, `mi_temps`...), jamais
// des libelles de l'application. Pour un code que l'application connait, l'ecran
// affiche **son propre texte** (`assets/i18n`, sous `recrutement.talents`, en
// francais et en arabe) ; pour tout autre code, le libelle et l'exemple du
// catalogue de la direction (en francais). Un code sans aucun texte ne
// s'affiche jamais tel quel (CONS section 9).
library;

import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/choice_card_group.dart';

/// Un texte de `recrutement.talents`, ou `null` s'il manque.
String? texteTalents(String chemin) {
  final Object? valeur = t.$meta.getTranslation('recrutement.talents.$chemin');
  return valeur is String && valeur.isNotEmpty ? valeur : null;
}

/// Les textes d'une competence : ce que c'est et un cas concret.
class TextesCompetence {
  /// Cree les textes.
  const TextesCompetence({
    required this.libelle,
    this.description,
    this.exemple,
  });

  /// Le nom de la competence.
  final String libelle;

  /// Ce que c'est, en une phrase.
  final String? description;

  /// Un cas concret, sans le « Par exemple » que la carte ajoute.
  final String? exemple;
}

/// Les textes de l'application pour un code du catalogue, ou `null` quand elle
/// ne le connait pas.
TextesCompetence? textesCompetenceConnue(String code) {
  final String? libelle = texteTalents('c.$code.libelle');
  if (libelle == null) {
    return null;
  }
  return TextesCompetence(
    libelle: libelle,
    description: texteTalents('c.$code.description'),
    exemple: texteTalents('c.$code.exemple'),
  );
}

/// Les textes d'une competence du catalogue : ceux de l'application pour un
/// code qu'elle connait, sinon ceux de la direction.
TextesCompetence textesCompetence(EntreeCatalogue entree) =>
    textesCompetenceConnue(entree.code) ??
    TextesCompetence(libelle: entree.libelle, exemple: entree.exemple);

/// Le nom d'une competence par son code : le texte de l'application, sinon le
/// libelle de [entree] (le catalogue), sinon `null`.
String? libelleCompetence(String code, {EntreeCatalogue? entree}) =>
    texteTalents('c.$code.libelle') ?? entree?.libelle;

/// Le titre d'une famille.
String titreFamille(FamilleCompetence famille) {
  final f = t.recrutement.talents.competences.familles;
  return switch (famille) {
    FamilleCompetence.communication => f.communication,
    FamilleCompetence.administration => f.administration,
    FamilleCompetence.financesDroit => f.financesDroit,
    FamilleCompetence.pedagogie => f.pedagogie,
    FamilleCompetence.technique => f.technique,
    FamilleCompetence.autre => f.autre,
  };
}

/// Le libelle d'un niveau, a la premiere personne (« Je debute »).
String libelleNiveau(NiveauCompetence niveau) {
  final n = t.recrutement.talents.niveaux;
  return switch (niveau) {
    NiveauCompetence.debutant => n.debutant.libelle,
    NiveauCompetence.experience => n.experience.libelle,
    NiveauCompetence.metier => n.metier.libelle,
  };
}

/// Ce que veut dire un niveau.
String descriptionNiveau(NiveauCompetence niveau) {
  final n = t.recrutement.talents.niveaux;
  return switch (niveau) {
    NiveauCompetence.debutant => n.debutant.description,
    NiveauCompetence.experience => n.experience.description,
    NiveauCompetence.metier => n.metier.description,
  };
}

/// Le niveau lu par la direction, a la troisieme personne et sans accord de
/// genre (« Debute », « A de l'experience »).
String libelleNiveauDirection(NiveauCompetence niveau) {
  final n = t.admin.candidatures.detail.talents.niveaux;
  return switch (niveau) {
    NiveauCompetence.debutant => n.debutant,
    NiveauCompetence.experience => n.experience,
    NiveauCompetence.metier => n.metier,
  };
}

/// Le libelle d'une disponibilite.
String libelleDisponibilite(DisponibiliteMission dispo) {
  final d = t.recrutement.talents.disponibilite;
  return switch (dispo) {
    DisponibiliteMission.quelquesHeures => d.quelques_heures.libelle,
    DisponibiliteMission.miTemps => d.mi_temps.libelle,
    DisponibiliteMission.plus => d.plus.libelle,
    DisponibiliteMission.pasMaintenant => d.pas_maintenant.libelle,
  };
}

/// Ce que veut dire une disponibilite.
String descriptionDisponibilite(DisponibiliteMission dispo) {
  final d = t.recrutement.talents.disponibilite;
  return switch (dispo) {
    DisponibiliteMission.quelquesHeures => d.quelques_heures.description,
    DisponibiliteMission.miTemps => d.mi_temps.description,
    DisponibiliteMission.plus => d.plus.description,
    DisponibiliteMission.pasMaintenant => d.pas_maintenant.description,
  };
}

/// L'icone d'une famille, sur ses cartes.
AppIcon iconeFamille(FamilleCompetence famille) => switch (famille) {
  FamilleCompetence.communication => AppIcons.annonce,
  FamilleCompetence.administration => AppIcons.dossiers,
  FamilleCompetence.financesDroit => AppIcons.finance,
  FamilleCompetence.pedagogie => AppIcons.pedagogie,
  FamilleCompetence.technique => AppIcons.appareil,
  FamilleCompetence.autre => AppIcons.autreChoix,
};

/// L'illustration d'une famille sur grand ecran : son icone, entouree de trois
/// icones qui racontent ce qu'on y fait.
IllustrationChoix illustrationFamille(FamilleCompetence famille) =>
    switch (famille) {
      FamilleCompetence.communication => const IllustrationChoix(
        AppIcons.annonce,
        autour: <AppIcon>[AppIcons.image, AppIcons.camera, AppIcons.discussion],
      ),
      FamilleCompetence.administration => const IllustrationChoix(
        AppIcons.dossiers,
        autour: <AppIcon>[AppIcons.journal, AppIcons.cahier, AppIcons.horloge],
      ),
      FamilleCompetence.financesDroit => const IllustrationChoix(
        AppIcons.finance,
        autour: <AppIcon>[
          AppIcons.paiements,
          AppIcons.contractuel,
          AppIcons.coffre,
        ],
      ),
      FamilleCompetence.pedagogie => const IllustrationChoix(
        AppIcons.pedagogie,
        autour: <AppIcon>[
          AppIcons.cahier,
          AppIcons.livreOuvert,
          AppIcons.eleves,
        ],
      ),
      FamilleCompetence.technique => const IllustrationChoix(
        AppIcons.appareil,
        autour: <AppIcon>[
          AppIcons.reseau,
          AppIcons.tabletteOuOrdinateur,
          AppIcons.camera,
        ],
      ),
      FamilleCompetence.autre => const IllustrationChoix(AppIcons.autreChoix),
    };

/// Le nom d'un domaine de filtre : une famille (« Communication et image ») ou
/// une competence (« Comptabilite »). Jamais le code. Une competence sans texte
/// ni entree de catalogue se dit par une phrase neutre.
String nomDomaineFiltre(String valeur, {CatalogueCompetences? catalogue}) {
  final FamilleCompetence? famille = FamilleCompetence.depuisSql(valeur);
  if (famille != null && valeur != EntreeCatalogue.codeAutre) {
    return titreFamille(famille);
  }
  return libelleCompetence(valeur, entree: catalogue?.entree(valeur)) ??
      t.admin.candidatures.detail.talents.competenceInconnue;
}
