// Mot de passe aleatoire du compte d'un profil enfant. Personne ne le saisit
// jamais : l'enfant entre par le code de l'appareil. Il doit pourtant
// satisfaire la politique d'Auth (une minuscule, une majuscule, un chiffre et
// un symbole), sans quoi la creation du compte repond 422 (incident du
// 08/11/2026, creer-profil-enfant en 500).
//
// Tirage par crypto.getRandomValues, jamais Math.random ; jamais journalise ni
// renvoye.

const MINUSCULES = 'abcdefghijklmnopqrstuvwxyz'
const MAJUSCULES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const CHIFFRES = '0123456789'
const SYMBOLES = '!@#$%^&*()_+-=[]{};:,.?'
const TOUT = MINUSCULES + MAJUSCULES + CHIFFRES + SYMBOLES

/** Longueur du mot de passe (au moins 32). */
export const LONGUEUR_MOT_DE_PASSE = 40

/** Un entier uniforme dans [0, n), sans biais (rejet). */
function entierAlea(n: number): number {
  const limite = Math.floor(0x100000000 / n) * n
  const tampon = new Uint32Array(1)
  for (;;) {
    crypto.getRandomValues(tampon)
    if (tampon[0] < limite) return tampon[0] % n
  }
}

function caractere(alphabet: string): string {
  return alphabet[entierAlea(alphabet.length)]
}

/** Un mot de passe de 40 caracteres avec les quatre classes, toujours. */
export function motDePasseAleatoire(): string {
  const c: string[] = [
    caractere(MINUSCULES),
    caractere(MAJUSCULES),
    caractere(CHIFFRES),
    caractere(SYMBOLES),
  ]
  while (c.length < LONGUEUR_MOT_DE_PASSE) c.push(caractere(TOUT))
  for (let i = c.length - 1; i > 0; i--) {
    const j = entierAlea(i + 1)
    ;[c[i], c[j]] = [c[j], c[i]]
  }
  return c.join('')
}
