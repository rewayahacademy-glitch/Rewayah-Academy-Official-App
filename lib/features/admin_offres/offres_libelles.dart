/// Les mots d'une offre vitrine, partages par la liste, la carte et le
/// formulaire (L2-05).
///
/// Un seul endroit pour dire un creneau : la carte et la phrase lue par le
/// lecteur d'ecran ne peuvent pas diverger.
library;

import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/offres/port_offres_admin.dart';
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute, libelleJours;

/// Les fuseaux proposes a la creation (liste courte : les villes des familles
/// visees, `commun.fuseaux`). Le serveur valide l'identifiant IANA.
const List<String> fuseauxProposes = <String>[
  'Europe/Paris',
  'Europe/London',
  'America/Toronto',
  'America/New_York',
  'America/Los_Angeles',
  'Africa/Conakry',
  'Africa/Casablanca',
  'Asia/Riyadh',
];

/// Le fuseau propose d'abord : celui de l'academie.
const String fuseauParDefaut = 'Europe/Paris';

/// L'heure par defaut : une heure de soiree pour les familles visees.
const int heureParDefaut = 18;

/// « Actuellement : Publiee », le nom d'un etat.
String nomEtatOffre(EtatOffreAdmin etat) => switch (etat) {
  EtatOffreAdmin.brouillon => t.admin.offres.etatBrouillon,
  EtatOffreAdmin.publiee => t.admin.offres.etatPubliee,
  EtatOffreAdmin.retiree => t.admin.offres.etatRetiree,
};

/// « 60 min ».
String libelleDuree(int minutes) => t.admin.offres.duree(minutes: '$minutes');

/// « Lundi, mercredi, vendredi, 18 h, Paris » : le creneau d'une offre, dit
/// une fois pour la carte (titre) et pour la phrase lue des actions.
String resumeOffre(OffreAdmin o) =>
    '${libelleJours(o.jours)}, ${libelleHeureMinute(o.heureLocale, 0)}, '
    '${villeDuFuseauLibelle(o.fuseauIana)}';
