/// C1 (02/11/2026, UX-019) : la phrase d'un echec venu du serveur dans les
/// feuilles de la page des classes (ajouter ou retirer un eleve, cloturer,
/// changer le seuil).
///
/// Avant, l'ecran montrait le texte brut de l'exception (« cet eleve
/// appartient deja a un groupe actif, code: P0001, details: Bad Request ») :
/// mot interne, code technique, sans accents, en francais meme dans
/// l'interface arabe. Desormais : une phrase par refus connu, qui dit quoi
/// faire (K-59) ; une phrase generique pour un refus inconnu ; jamais un
/// code, jamais le texte SQL.
library;

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/i18n/strings.g.dart';

/// Les debuts des messages leves par `ajouter_eleve_groupe`,
/// `retirer_eleve_groupe` et `cloturer_groupe` (0019, 0067,
/// 20261024150000), avec leur phrase. Compares sans casse ; le prefixe
/// suffit.
List<(String, String Function())> get _refusConnus {
  final c1 = t.admin.groupes.c1;
  return <(String, String Function())>[
    ('cet eleve appartient deja a un groupe actif', () => c1.eleveDejaEnClasse),
    ('cet eleve n\'existe pas', () => c1.eleveInvalide),
    ('cet eleve n\'est pas membre actif', () => c1.eleveNonMembre),
    ('groupe introuvable ou deja cloture', () => c1.classeDejaClose),
    ('un motif est requis', () => c1.motifManquant),
    ('ajout d\'un eleve a un groupe reserve', () => c1.reservee),
    ('retrait d\'un eleve d\'un groupe reserve', () => c1.reservee),
    ('cloture de groupe reservee', () => c1.reservee),
  ];
}

/// La phrase de l'echec [erreur], a poser apres « L'ajout n'a pas abouti : ».
/// Un refus du serveur connu a sa phrase ; un refus inconnu, la phrase
/// generique ; toute autre erreur (reseau, delai) dit que le serveur n'a pas
/// repondu. Jamais le texte de l'exception.
String phraseEchecServeurClasse(Object erreur) {
  final c1 = t.admin.groupes.c1;
  if (erreur is PostgrestException) {
    if (erreur.code == '42501') return c1.reservee;
    final String m = erreur.message.trim().toLowerCase();
    for (final (String prefixe, String Function() phrase) in _refusConnus) {
      if (m.startsWith(prefixe)) return phrase();
    }
    return c1.refusInconnu;
  }
  return c1.connexion;
}
