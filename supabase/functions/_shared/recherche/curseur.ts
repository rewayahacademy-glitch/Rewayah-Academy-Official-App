export type DomaineCurseurRecherche = "classes" | "enseignants";

export interface CurseurRecherche {
  readonly version: 1;
  readonly domaine: DomaineCurseurRecherche;
  readonly sujet: string;
  readonly espace: string;
  readonly ordre: "groupe_id_asc";
  readonly requeteTag: string;
  readonly apres: string;
  readonly expireLe: number;
}

export interface ChargeCurseurRecherche {
  readonly version: 1;
  readonly domaine: DomaineCurseurRecherche;
  readonly sujet: string;
  readonly espace: string;
  readonly ordre: "groupe_id_asc";
  readonly requete: string;
  readonly apres: string;
  readonly expireLe: number;
}

export type ContexteCurseurRecherche = Omit<
  ChargeCurseurRecherche,
  "apres" | "expireLe"
>;

const encodeur = new TextEncoder();
const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function bufferSource(bytes: Uint8Array): ArrayBuffer {
  return bytes.slice().buffer as ArrayBuffer;
}

function base64url(bytes: Uint8Array): string {
  let binaire = "";
  for (const octet of bytes) binaire += String.fromCharCode(octet);
  return btoa(binaire).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

function debase64url(valeur: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]+$/.test(valeur)) throw new Error("base64url invalide");
  const base64 = valeur.replaceAll("-", "+").replaceAll("_", "/");
  const binaire = atob(base64 + "=".repeat((4 - base64.length % 4) % 4));
  return Uint8Array.from(binaire, (caractere) => caractere.charCodeAt(0));
}

async function cleHmac(secret: string): Promise<CryptoKey> {
  if (new TextEncoder().encode(secret).length < 32) {
    throw new Error("RECHERCHE_CURSOR_SECRET doit contenir au moins 32 octets");
  }
  return await crypto.subtle.importKey(
    "raw",
    encodeur.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

function domaineValide(value: unknown): value is DomaineCurseurRecherche {
  return value === "classes" || value === "enseignants";
}

function chargeValide(charge: CurseurRecherche): boolean {
  return charge.version === 1 && domaineValide(charge.domaine) &&
    charge.ordre === "groupe_id_asc" &&
    UUID.test(charge.sujet) && UUID.test(charge.apres) &&
    charge.espace.length > 0 &&
    /^[A-Za-z0-9_-]{43}$/.test(charge.requeteTag) &&
    Number.isSafeInteger(charge.expireLe);
}

function entreeRequete(requete: string): Uint8Array {
  return encodeur.encode(`rewayah-search-cursor-v1\0${requete}`);
}

async function tagRequete(cle: CryptoKey, requete: string): Promise<string> {
  return base64url(
    new Uint8Array(
      await crypto.subtle.sign(
        "HMAC",
        cle,
        bufferSource(entreeRequete(requete)),
      ),
    ),
  );
}

export async function signerCurseur(
  charge: ChargeCurseurRecherche,
  secret: string,
): Promise<string> {
  if (
    charge.version !== 1 || !domaineValide(charge.domaine) ||
    !UUID.test(charge.sujet) || !UUID.test(charge.apres) ||
    charge.espace.length === 0 || charge.ordre !== "groupe_id_asc" ||
    charge.requete.length === 0 ||
    !Number.isSafeInteger(charge.expireLe)
  ) throw new Error("charge de curseur invalide");

  const cle = await cleHmac(secret);
  const chargeSignee: CurseurRecherche = {
    version: charge.version,
    domaine: charge.domaine,
    sujet: charge.sujet,
    espace: charge.espace,
    ordre: charge.ordre,
    requeteTag: await tagRequete(cle, charge.requete),
    apres: charge.apres,
    expireLe: charge.expireLe,
  };
  const contenu = base64url(encodeur.encode(JSON.stringify(chargeSignee)));
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "HMAC",
      cle,
      bufferSource(encodeur.encode(contenu)),
    ),
  );
  return `${contenu}.${base64url(signature)}`;
}

export async function lireCurseur(
  token: string,
  secret: string,
  contexte: ContexteCurseurRecherche,
  maintenantSecondes = Math.floor(Date.now() / 1000),
): Promise<CurseurRecherche | null> {
  try {
    if (token.length > 2048) return null;
    const parties = token.split(".");
    if (parties.length !== 2) return null;
    const [contenu, signature] = parties;
    const cle = await cleHmac(secret);
    if (
      !await crypto.subtle.verify(
        "HMAC",
        cle,
        bufferSource(debase64url(signature)),
        bufferSource(encodeur.encode(contenu)),
      )
    ) return null;
    const brut: unknown = JSON.parse(
      new TextDecoder().decode(debase64url(contenu)),
    );
    if (typeof brut !== "object" || brut === null) return null;
    const charge = brut as CurseurRecherche;
    if (!chargeValide(charge) || charge.expireLe <= maintenantSecondes) {
      return null;
    }
    if (
      charge.version !== contexte.version ||
      charge.domaine !== contexte.domaine ||
      charge.sujet !== contexte.sujet || charge.espace !== contexte.espace ||
      charge.ordre !== contexte.ordre
    ) return null;
    if (
      !await crypto.subtle.verify(
        "HMAC",
        cle,
        bufferSource(debase64url(charge.requeteTag)),
        bufferSource(entreeRequete(contexte.requete)),
      )
    ) return null;
    return charge;
  } catch {
    return null;
  }
}
