// N1 (02/11/2026) : la matrice de portee des annonces servie par le serveur
// (`com_regles_audience`, migration 20261105400000), a la place de
// `ReglesAudienceIndisponibles`.
//
// Le serveur rend des codes (auteurs, portee) ; les mots sont rediges ici,
// dans slang. La matrice redit les regles de `com_annonce_publier`, qui reste
// la seule barriere. Un refus (une personne qui n'est pas de la direction) ou
// une fonction pas encore installee se lit comme une capacite indisponible.

import '../../core/communications/communications_supabase.dart';
import '../../core/i18n/strings.g.dart';
import 'port_regles_audience.dart';

/// Les regles lues par `com_regles_audience()`.
class ReglesAudienceSupabase implements PortReglesAudience {
  /// Cree l'adaptateur sur un appel RPC.
  const ReglesAudienceSupabase(this._appel);

  final AppelRpc _appel;

  @override
  Future<ReglesAudience> regles() async {
    final Object? brut;
    try {
      brut = await _appel('com_regles_audience', <String, dynamic>{});
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw ReglesAudienceIndisponibles.manque;
      rethrow;
    }
    return ReglesAudience(
      regles: <RegleAudience>[
        for (final Map<String, dynamic> l in listeJson(brut))
          regleAudienceJson(l),
      ],
    );
  }
}

/// Une ligne de la matrice, redigee depuis ses codes. Un code inconnu est une
/// erreur de format : jamais un libelle invente.
RegleAudience regleAudienceJson(Map<String, dynamic> m) {
  final r = t.n1.regles;
  final String auteurs = switch (texteJson(m, 'auteurs')) {
    'direction' => r.auteurs.direction,
    'enseignants' => r.auteurs.enseignants,
    'familles' => r.auteurs.familles,
    'eleves' => r.auteurs.eleves,
    'comptables' => r.auteurs.comptables,
    'controleurs' => r.auteurs.controleurs,
    final String autre => throw FormatException('Auteurs inconnus : $autre.'),
  };
  final String audiences = switch (texteJson(m, 'portee')) {
    'toute_audience' => r.portee.touteAudience,
    'sa_classe' => r.portee.saClasse,
    'aucune' => '',
    final String autre => throw FormatException('Portee inconnue : $autre.'),
  };
  return RegleAudience(
    id: texteJson(m, 'id'),
    auteurs: auteurs,
    peutPublier: m['peut_publier'] == true,
    audiences: audiences,
  );
}
