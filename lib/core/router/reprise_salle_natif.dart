/// Hors navigateur, rien ne se recharge : la memoire du processus suffit.
final Map<String, String> _memoire = <String, String>{};

/// Lit la valeur gardee pour [cle], ou `null`.
String? lireDansOnglet(String cle) => _memoire[cle];

/// Garde [valeur] pour [cle] ; `null` l'efface.
void ecrireDansOnglet(String cle, String? valeur) {
  if (valeur == null) {
    _memoire.remove(cle);
  } else {
    _memoire[cle] = valeur;
  }
}
