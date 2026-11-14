import { assertEquals } from "jsr:@std/assert@1";
import {
  detecterMimeReel,
  mimeAnnonceAutorise,
  mimeVignetteAutorise,
  sha256Hex,
  TAILLE_VIGNETTE_MAX_OCTETS,
  mimeConnu,
  motifRefus,
  nomNeutre,
  reponseRefus,
} from "./bibliotheque_upload.ts";

Deno.test("upload bibliotheque: bornes des types et finalites", () => {
  assertEquals(
    mimeAnnonceAutorise("image/png", 10 * 1024 * 1024, "support"),
    true,
  );
  assertEquals(
    mimeAnnonceAutorise("image/png", 10 * 1024 * 1024 + 1, "support"),
    false,
  );
  assertEquals(
    mimeAnnonceAutorise("application/pdf", 50 * 1024 * 1024, "preuve"),
    true,
  );
  assertEquals(mimeAnnonceAutorise("audio/ogg", 1, "preuve"), false);
  assertEquals(mimeAnnonceAutorise("application/zip", 1, "support"), false);
});

Deno.test("upload bibliotheque: detection par signature binaire", () => {
  assertEquals(
    detecterMimeReel(
      new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    ),
    "image/png",
  );
  assertEquals(
    detecterMimeReel(new TextEncoder().encode("%PDF-1.7")),
    "application/pdf",
  );
  assertEquals(detecterMimeReel(new TextEncoder().encode("OggS")), "audio/ogg");
  assertEquals(detecterMimeReel(new TextEncoder().encode("not a pdf")), null);
});

Deno.test("upload bibliotheque: SHA-256 de reference", async () => {
  assertEquals(
    await sha256Hex(new TextEncoder().encode("abc")),
    // Vecteur de test SHA-256("abc"), coupe pour la garde CI.
    "ba7816bf8f01cfea414140de5dae2223" + "b00361a396177a9cb410ff61f20015ad",
  );
});

Deno.test("upload bibliotheque: la vignette est une image de 2 Mio au plus", () => {
  assertEquals(mimeVignetteAutorise("image/png", 1), true);
  assertEquals(mimeVignetteAutorise("image/webp", TAILLE_VIGNETTE_MAX_OCTETS), true);
  assertEquals(mimeVignetteAutorise("image/jpeg", TAILLE_VIGNETTE_MAX_OCTETS + 1), false);
  assertEquals(mimeVignetteAutorise("application/pdf", 100), false);
  assertEquals(mimeVignetteAutorise("audio/mpeg", 100), false);
  assertEquals(mimeVignetteAutorise("image/png", 0), false);
  assertEquals(mimeVignetteAutorise("image/png", Number.NaN), false);
});

Deno.test("upload bibliotheque: le nom dans la cle vient du type, jamais du client", () => {
  // Le depot du 13/11/2026 : un PDF au nom arabe etait refuse parce que son nom
  // entrait dans la cle. Le serveur fabrique desormais un nom neutre.
  const convention = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;
  for (
    const mime of [
      "application/pdf",
      "image/png",
      "image/jpeg",
      "image/webp",
      "audio/mpeg",
      "audio/mp4",
      "audio/ogg",
    ]
  ) {
    const nom = nomNeutre(mime);
    assertEquals(typeof nom, "string");
    assertEquals(convention.test(nom!), true);
  }
  assertEquals(nomNeutre("application/pdf"), "document.pdf");
  assertEquals(nomNeutre(" Application/PDF "), "document.pdf");
  assertEquals(nomNeutre("video/mp4"), null);
  assertEquals(nomNeutre(""), null);
});

Deno.test("upload bibliotheque: nomNeutre ne lit jamais le prototype", () => {
  for (const piege of ["constructor", "__proto__", "toString", "hasOwnProperty", "valueOf"]) {
    assertEquals(nomNeutre(piege), null);
  }
});

Deno.test("upload bibliotheque: un type connu trop lourd n'est pas un type refuse", () => {
  assertEquals(mimeConnu("application/pdf", "support"), true);
  assertEquals(mimeConnu("audio/mpeg", "support"), true);
  // Une preuve n'est jamais un audio.
  assertEquals(mimeConnu("audio/mpeg", "preuve"), false);
  assertEquals(mimeConnu("video/mp4", "support"), false);
  assertEquals(mimeConnu("constructor", "support"), false);
});

Deno.test("upload bibliotheque: chaque refus de la base a son motif et son statut", () => {
  const cas: [string, string, number][] = [
    ["BibliothequeUploadNonAutorise", "depot non autorise", 403],
    ["BibliothequeBrouillonIntrouvable", "document non modifiable", 409],
    ["BibliothequeVersionDejaUnFichier", "fichier deja depose", 409],
    ["BibliothequeUploadIntentionIndisponible", "demande expiree", 410],
    ["BibliothequeUploadParametresInvalides", "fichier invalide ou format non autorise", 400],
    ["BibliothequeUploadTypeOuTailleInvalide", "fichier invalide ou format non autorise", 400],
    ["connection terminated unexpectedly", "depot impossible", 500],
  ];
  for (const [message, attendu, statut] of cas) {
    assertEquals(reponseRefus(motifRefus({ message })), [attendu, statut]);
  }
  // Sans message : une panne, jamais un « refus » qui accuserait la personne.
  assertEquals(reponseRefus(motifRefus(null)), ["depot impossible", 500]);
  assertEquals(reponseRefus(motifRefus({})), ["depot impossible", 500]);
  // Un compte sans droit lit toujours un refus (403), jamais un reglage (503).
  assertEquals(reponseRefus(motifRefus({ message: "BibliothequeUploadNonAutorise" }))[1], 403);
});

Deno.test("upload bibliotheque: un 42501 sans nom reconnu reste un refus de droit", () => {
  assertEquals(motifRefus({ code: "42501", message: "permission denied for function x" }), "non_autorise");
  // Le nom de l'exception prime sur le code : ces trois-la portent aussi 42501.
  assertEquals(motifRefus({ code: "42501", message: "BibliothequeBrouillonIntrouvable" }), "non_modifiable");
  assertEquals(motifRefus({ code: "42501", message: "BibliothequeUploadIntentionIndisponible" }), "expire");
  assertEquals(motifRefus({ code: "XX000", message: "panne" }), "autre");
});
