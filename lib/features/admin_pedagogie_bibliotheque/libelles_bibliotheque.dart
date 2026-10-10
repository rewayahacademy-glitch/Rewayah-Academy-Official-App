/// CAP-29 : les mots de la bibliotheque d'administration, en fonctions pures
/// partagees par le catalogue, la fiche, l'import, la publication et
/// l'attribution : un meme etat dit la meme chose partout.
///
/// Trois vocabulaires distincts (spec §3.3), jamais melanges : la version
/// (Brouillon / Publie / Archive), la revue des droits (A verifier /
/// Approuve / Refuse / Expire) et le retrait (un fait, « Retire »).
library;

import '../../core/admin/modeles_bibliotheque_admin.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/status_pill.dart';

/// Le mot d'un type de support.
String libelleType(TypeRessource type) => switch (type) {
  TypeRessource.quran => t.admin.bibliotheque.libelles.type.quran,
  TypeRessource.texteStructure =>
    t.admin.bibliotheque.libelles.type.texteStructure,
  TypeRessource.pdf => t.admin.bibliotheque.libelles.type.pdf,
  TypeRessource.image => t.admin.bibliotheque.libelles.type.image,
  TypeRessource.lecon => t.admin.bibliotheque.libelles.type.lecon,
};

/// Le mot d'une langue (code court) ; le code lui-meme pour une langue
/// inconnue de l'application.
String libelleLangue(String code) => switch (code) {
  'fr' => t.admin.bibliotheque.libelles.langue.fr,
  'ar' => t.admin.bibliotheque.libelles.langue.ar,
  'en' => t.admin.bibliotheque.libelles.langue.en,
  _ => code,
};

/// L'etat de publication d'un support : « Retire » prime sur l'etat de la
/// version (le retrait est un fait distinct).
String libelleEtatSupport(SupportAdmin s) => s.retire
    ? t.admin.bibliotheque.libelles.version.retire
    : libelleStatutVersion(s.statutVersion);

/// Le mot d'une version.
String libelleStatutVersion(StatutVersionRessource statut) => switch (statut) {
  StatutVersionRessource.brouillon =>
    t.admin.bibliotheque.libelles.version.brouillon,
  StatutVersionRessource.publiee =>
    t.admin.bibliotheque.libelles.version.publiee,
  StatutVersionRessource.archivee =>
    t.admin.bibliotheque.libelles.version.archivee,
};

/// Le ton de la pastille d'un support (jamais la couleur seule : le mot reste).
TonEtat tonEtatSupport(SupportAdmin s) {
  if (s.retire) return TonEtat.neutre;
  return switch (s.statutVersion) {
    StatutVersionRessource.brouillon => TonEtat.avertissement,
    StatutVersionRessource.publiee => TonEtat.succes,
    StatutVersionRessource.archivee => TonEtat.neutre,
  };
}

/// Le mot d'une revue des droits.
String libelleRevue(RevueDroits revue) => switch (revue) {
  RevueDroits.aVerifier => t.admin.bibliotheque.libelles.droits.aVerifier,
  RevueDroits.approuve => t.admin.bibliotheque.libelles.droits.approuve,
  RevueDroits.refuse => t.admin.bibliotheque.libelles.droits.refuse,
  RevueDroits.expire => t.admin.bibliotheque.libelles.droits.expire,
};

/// Le ton de la pastille d'une revue des droits.
TonEtat tonRevue(RevueDroits revue) => switch (revue) {
  RevueDroits.aVerifier => TonEtat.avertissement,
  RevueDroits.approuve => TonEtat.succes,
  RevueDroits.refuse => TonEtat.alerte,
  RevueDroits.expire => TonEtat.alerte,
};

/// Le mot d'une politique d'acces.
String libelleVisibilite(PolitiqueAcces p) => switch (p) {
  PolitiqueAcces.publique => t.admin.bibliotheque.libelles.visibilite.publique,
  PolitiqueAcces.inscrits => t.admin.bibliotheque.libelles.visibilite.inscrits,
  PolitiqueAcces.groupeAssigne =>
    t.admin.bibliotheque.libelles.visibilite.groupeAssigne,
  PolitiqueAcces.enseignantSeul =>
    t.admin.bibliotheque.libelles.visibilite.enseignantSeul,
  PolitiqueAcces.admin => t.admin.bibliotheque.libelles.visibilite.admin,
};

/// Le mot d'un usage autorise par les droits.
String libelleUsage(UsageDroit usage) => switch (usage) {
  UsageDroit.application => t.admin.bibliotheque.libelles.usage.application,
  UsageDroit.classe => t.admin.bibliotheque.libelles.usage.classe,
  UsageDroit.telechargement =>
    t.admin.bibliotheque.libelles.usage.telechargement,
  UsageDroit.horsLigne => t.admin.bibliotheque.libelles.usage.horsLigne,
};

/// Le mot d'un segment du catalogue.
String libelleSegment(EtatCatalogue etat) => switch (etat) {
  EtatCatalogue.tous => t.admin.bibliotheque.catalogue.segments.tous,
  EtatCatalogue.brouillons =>
    t.admin.bibliotheque.catalogue.segments.brouillons,
  EtatCatalogue.aVerifier => t.admin.bibliotheque.catalogue.segments.aVerifier,
  EtatCatalogue.publies => t.admin.bibliotheque.catalogue.segments.publies,
  EtatCatalogue.retires => t.admin.bibliotheque.catalogue.segments.retires,
  EtatCatalogue.droitsExpires =>
    t.admin.bibliotheque.catalogue.segments.droitsExpires,
};

/// Le mot d'une ligne d'audit.
String libelleAudit(ActionAudit action) => switch (action) {
  ActionAudit.creation => t.admin.bibliotheque.fiche.audit.creation,
  ActionAudit.depot => t.admin.bibliotheque.fiche.audit.depot,
  ActionAudit.revueDroits => t.admin.bibliotheque.fiche.audit.revueDroits,
  ActionAudit.publication => t.admin.bibliotheque.fiche.audit.publication,
  ActionAudit.attribution => t.admin.bibliotheque.fiche.audit.attribution,
  ActionAudit.retrait => t.admin.bibliotheque.fiche.audit.retrait,
  ActionAudit.restauration => t.admin.bibliotheque.fiche.audit.restauration,
};

/// Le mot d'une politique de hors ligne.
String libelleHorsLigne(PolitiqueOffline p) => switch (p) {
  PolitiqueOffline.jamais => t.admin.bibliotheque.libelles.horsLigne.jamais,
  PolitiqueOffline.surDemande =>
    t.admin.bibliotheque.libelles.horsLigne.surDemande,
  PolitiqueOffline.automatique =>
    t.admin.bibliotheque.libelles.horsLigne.automatique,
};
