import 'package:flutter/foundation.dart';

/// Etapes serveur d'une demande familiale. Aucune ne signifie qu'une place est reservee.
enum EtatDemandeHoraire {
  envoyee('envoyee'),
  classeValidee('classe_validee'),
  enseignantAffecte('enseignant_affecte'),
  refusee('refusee'),
  retiree('retiree');

  const EtatDemandeHoraire(this.valeurSql);
  final String valeurSql;

  static EtatDemandeHoraire depuisSql(String? valeur) =>
      EtatDemandeHoraire.values.firstWhere(
        (EtatDemandeHoraire e) => e.valeurSql == valeur,
        orElse: () => throw FormatException('Etat de demande inconnu: $valeur'),
      );
}

/// Etat visible par le foyer; ne contient ni effectif ni identite tierce.
@immutable
class DemandeHoraireFamille {
  const DemandeHoraireFamille({
    required this.id,
    required this.etat,
    required this.prochaineEtape,
    required this.motif,
    required this.updatedAt,
  });

  factory DemandeHoraireFamille.depuisJson(Map<String, dynamic> json) =>
      DemandeHoraireFamille(
        id: json['id'] as String,
        etat: EtatDemandeHoraire.depuisSql(json['etat'] as String?),
        prochaineEtape: json['prochaine_etape'] as String? ?? 'aucune',
        motif: json['motif'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      );

  final String id;
  final EtatDemandeHoraire etat;
  final String prochaineEtape;
  final String? motif;
  final DateTime updatedAt;
}

/// Demande de créneau libre. Le serveur canonicalise et vérifie le planning.
@immutable
class DemandeCreneauPersonnalise {
  const DemandeCreneauPersonnalise({
    required this.membreId,
    required this.fuseauIana,
    required this.joursIso,
    required this.heureLocale,
  });

  final String membreId;
  final String fuseauIana;
  final List<int> joursIso;
  final int heureLocale;
}

/// Regroupement admin, sans identité de famille avant création de classe.
@immutable
class RegroupementDemandesHoraires {
  const RegroupementDemandesHoraires({
    required this.id,
    required this.typePublic,
    required this.langueCode,
    required this.fuseauIana,
    required this.jours,
    required this.heuresLocales,
    required this.nombreEleves,
    required this.quota,
    required this.pret,
  });

  factory RegroupementDemandesHoraires.depuisJson(Map<String, dynamic> json) =>
      RegroupementDemandesHoraires(
        id: json['regroupement_id'] as String,
        typePublic: json['type_public'] as String,
        langueCode: json['langue_code'] as String,
        fuseauIana: json['fuseau_iana'] as String,
        jours: (json['jours'] as List<dynamic>).cast<int>(),
        heuresLocales: (json['heures_locales'] as List<dynamic>).cast<int>(),
        nombreEleves: (json['nombre_eleves'] as num).toInt(),
        quota: (json['quota'] as num).toInt(),
        pret: json['pret'] as bool,
      );

  final String id;
  final String typePublic;
  final String langueCode;
  final String fuseauIana;
  final List<int> jours;
  final List<int> heuresLocales;
  final int nombreEleves;
  final int quota;
  final bool pret;
}

/// API famille et administration pour les demandes horaires.
abstract interface class PortDemandesHorairesFamille {
  Future<DemandeHoraireFamille> demanderCreneauPersonnalise(
    DemandeCreneauPersonnalise demande,
  );

  Future<List<DemandeHoraireFamille>> mesDemandes(String membreId);
}

/// API de regroupement réservée à l'administration. Aucune donnée individuelle.
abstract interface class PortRegroupementsDemandesHoraires {
  Future<List<RegroupementDemandesHoraires>> charger();
}
