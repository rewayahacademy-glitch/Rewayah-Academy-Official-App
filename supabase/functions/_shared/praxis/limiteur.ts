// PX-OAUTH 2c : une limite de debit GROSSIERE, en memoire, par fenetre fixe. Une instance de fonction Edge vit peu et plusieurs peuvent
// tourner en meme temps : cette limite ne remplace pas celle de la base (10 clients par heure, 30 demandes par client et par heure) ;
// elle coupe seulement le bruit d'une seule source avant d'atteindre la base. Aucune donnee de personne n'y est gardee que l'adresse
// reseau de l'appelant, et seulement le temps d'une fenetre.

export interface Limiteur {
  /// Rend 0 si la requete passe ; sinon le nombre de secondes a attendre.
  essayer(cle: string, max: number, fenetreMs: number): number
}

export function creerLimiteur(maintenant: () => number = () => Date.now(), tailleMax = 5000): Limiteur {
  const fenetres = new Map<string, { debut: number; n: number }>()
  return {
    essayer(cle, max, fenetreMs) {
      const t = maintenant()
      if (fenetres.size > tailleMax) {
        // Elagage : les fenetres echues partent d'abord ; si la table reste trop grande, elle est videe (borne de memoire).
        for (const [k, f] of fenetres) if (t - f.debut >= fenetreMs) fenetres.delete(k)
        if (fenetres.size > tailleMax) fenetres.clear()
      }
      const f = fenetres.get(cle)
      if (!f || t - f.debut >= fenetreMs) {
        fenetres.set(cle, { debut: t, n: 1 })
        return 0
      }
      if (f.n >= max) return Math.max(1, Math.ceil((f.debut + fenetreMs - t) / 1000))
      f.n += 1
      return 0
    },
  }
}
