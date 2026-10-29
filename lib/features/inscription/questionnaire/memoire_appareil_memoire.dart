final Map<String, String> _valeurs = <String, String>{};

/// Lit [clef], ou `null`.
String? lireMemoireAppareil(String clef) => _valeurs[clef];

/// Ecrit [valeur] sous [clef].
void ecrireMemoireAppareil(String clef, String valeur) =>
    _valeurs[clef] = valeur;

/// Efface [clef].
void effacerMemoireAppareil(String clef) => _valeurs.remove(clef);
