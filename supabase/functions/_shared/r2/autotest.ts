// Les connexions R2 repondent-elles ? Oui ou non, domaine par domaine.
//
// Remplace la fonction `r2-selftest` neutralisee le 21/09/2026, dont la source
// n'a jamais ete versionnee. L'ancienne ecrivait, relisait, comparait et
// supprimait un objet dans chaque seau. Celle-ci n'ecrit RIEN (decision de la
// direction du 03/11/2026) : pour chaque domaine, elle verifie que ses secrets
// sont poses et valides (`stockageConfigure`), puis demande a R2, par un HEAD,
// une cle qui n'existe pas. Un 404 prouve a la fois que le point d'acces
// repond, que la signature est acceptee et que le seau existe -- R2 rend 403
// pour un seau absent ou une cle refusee. Aucun objet n'est cree, lu ni
// supprime.
//
// Ce que la reponse ne porte JAMAIS : une valeur de secret, un nom de seau, un
// point d'acces, un identifiant de compte, un message d'erreur de R2. Seulement
// le nom du domaine metier et deux booleens.

import { DOMAINES, type DomaineStockage, type LecteurEnvironnement, stockageConfigure } from './domaines.ts'
import { objetExiste } from './signature.ts'

/// Cle sondee. Elle n'est jamais ecrite : un 404 est la reponse attendue.
export const CLE_SONDE = 'autotest/absent-par-construction'

export interface EtatConnexion {
  /// Les secrets du domaine sont poses et passent les controles de forme.
  readonly configuree: boolean
  /// R2 a repondu 404 a un HEAD signe sur la cle sondee.
  readonly joignable: boolean
}

export type Sonde = (domaine: DomaineStockage, cle: string) => Promise<boolean>

export async function etatConnexions(
  env?: LecteurEnvironnement,
  sonde: Sonde = (domaine, cle) => objetExiste(domaine, cle, env),
): Promise<Record<DomaineStockage, EtatConnexion>> {
  const resultat = {} as Record<DomaineStockage, EtatConnexion>
  await Promise.all(DOMAINES.map(async (domaine) => {
    const configuree = env === undefined ? stockageConfigure(domaine) : stockageConfigure(domaine, env)
    let joignable = false
    if (configuree) {
      try {
        // `false` = 404 franc. `true` voudrait dire que la cle sondee existe :
        // la connexion marche, mais quelqu'un a ecrit la ou rien ne devrait
        // etre ; on le compte comme joignable, sans rien en dire de plus.
        await sonde(domaine, CLE_SONDE)
        joignable = true
      } catch {
        joignable = false
      }
    }
    resultat[domaine] = { configuree, joignable }
  }))
  return resultat
}
