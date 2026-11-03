// Ícono de Operia Técnicos: la marca de Operia (tres fibras azul/naranja/verde que entran al conector, fondo azul marino)
// con una insignia verde de «orden culminada». Genera los PNG de Android (normal, adaptable y monocromo) y una vista previa.
import { Resvg } from "@resvg/resvg-js";
import { mkdirSync, writeFileSync } from "fs";
import { join } from "path";

const RES = process.argv[2]; // carpeta android/app/src/main/res
const OUT = process.argv[3]; // carpeta de vistas previas

const defs = `
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1A2D57"/><stop offset="1" stop-color="#060D20"/></linearGradient>
<linearGradient id="sh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".10"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="b" gradientUnits="userSpaceOnUse" x1="9.5" y1="0" x2="28.5" y2="0"><stop offset="0" stop-color="#2563EB"/><stop offset="1" stop-color="#7CB4FF"/></linearGradient>
<linearGradient id="o" gradientUnits="userSpaceOnUse" x1="9.5" y1="0" x2="28.5" y2="0"><stop offset="0" stop-color="#EA580C"/><stop offset="1" stop-color="#FDBA4D"/></linearGradient>
<linearGradient id="g" gradientUnits="userSpaceOnUse" x1="9.5" y1="0" x2="28.5" y2="0"><stop offset="0" stop-color="#059669"/><stop offset="1" stop-color="#4ADE9F"/></linearGradient>
<linearGradient id="c" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C7D2DF"/></linearGradient>
<radialGradient id="l"><stop offset="0" stop-color="#F0F9FF"/><stop offset=".4" stop-color="#38BDF8" stop-opacity=".85"/><stop offset="1" stop-color="#38BDF8" stop-opacity="0"/></radialGradient>
<linearGradient id="ok" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#34D399"/><stop offset="1" stop-color="#059669"/></linearGradient>`;

// la marca en su caja original de 48 (fibras, conector y luz)
const marca = (mono = false) => `
<g fill="none" stroke-width="3.4" stroke-linecap="round">
  <path d="M9.5 14.5c9.5 0 12.5 9.5 19 9.5" stroke="${mono ? "#fff" : "url(#b)"}"/>
  <path d="M9.5 24h19" stroke="${mono ? "#fff" : "url(#o)"}"/>
  <path d="M9.5 33.5c9.5 0 12.5-9.5 19-9.5" stroke="${mono ? "#fff" : "url(#g)"}"/>
</g>
<rect x="27" y="20.1" width="12.8" height="7.8" rx="3.9" fill="${mono ? "#fff" : "url(#c)"}"/>
${mono ? "" : `<rect x="30.6" y="20.1" width="1.5" height="7.8" fill="#94A3B8" fill-opacity=".6"/><circle cx="41" cy="24" r="4.4" fill="url(#l)"/>`}`;

// insignia «culminada» (círculo verde con palomita), en la caja de 48
const insignia = (mono = false) => `
<circle cx="35.5" cy="35" r="6.6" fill="${mono ? "#fff" : "#060D20"}"/>
<circle cx="35.5" cy="35" r="5.4" fill="${mono ? "#fff" : "url(#ok)"}"/>
<path d="M32.9 35.1l1.8 1.8 3.5-3.6" fill="none" stroke="${mono ? "#000" : "#fff"}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>`;

// ícono normal (Android viejo y vista previa): cuadro redondeado como el logo de la web
const normal = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><defs>${defs}</defs>
<rect x="1" y="1" width="46" height="46" rx="13" fill="url(#bg)"/><rect x="1" y="1" width="46" height="46" rx="13" fill="url(#sh)"/>
<rect x="1.5" y="1.5" width="45" height="45" rx="12.5" fill="none" stroke="#fff" stroke-opacity=".14"/>${marca()}${insignia()}</svg>`;

// ícono adaptable (Android 8+): fondo a sangre y la marca dentro del círculo de 72 de 108 (zona segura y pantalla de arranque de Android 12)
const adaptable = (mono = false) => `<g transform="translate(12.75 15) scale(1.5)">${marca(mono)}${insignia(mono)}</g>`;
const fondo = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>${defs}</defs><rect width="108" height="108" fill="url(#bg)"/><rect width="108" height="108" fill="url(#sh)"/></svg>`;
const frente = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>${defs}</defs>${adaptable()}</svg>`;
// monocromo (íconos con el color del tema en Android 13+): solo la silueta
const mono = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>${defs}</defs>${adaptable(true)}</svg>`;

const png = (svg: string, px: number) => new Resvg(svg, { fitTo: { mode: "width", value: px } }).render().asPng();
const dens: [string, number][] = [["mdpi", 1], ["hdpi", 1.5], ["xhdpi", 2], ["xxhdpi", 3], ["xxxhdpi", 4]];
for (const [d, k] of dens) {
  const dir = join(RES, `mipmap-${d}`);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "ic_launcher.png"), png(normal, Math.round(48 * k)));
  writeFileSync(join(dir, "ic_launcher_background.png"), png(fondo, Math.round(108 * k)));
  writeFileSync(join(dir, "ic_launcher_foreground.png"), png(frente, Math.round(108 * k)));
  writeFileSync(join(dir, "ic_launcher_monochrome.png"), png(mono, Math.round(108 * k)));
}
mkdirSync(join(RES, "mipmap-anydpi-v26"), { recursive: true });
writeFileSync(
  join(RES, "mipmap-anydpi-v26", "ic_launcher.xml"),
  `<?xml version="1.0" encoding="utf-8"?>
<!-- Ícono adaptable: fondo azul marino, la marca de Operia (fibras y conector) con la insignia de orden culminada -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
`,
);
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, "icono-512.png"), png(normal, 512));
writeFileSync(join(OUT, "icono-normal.svg"), normal);
// vista previa del adaptable recortado en círculo, como lo muestran muchos teléfonos
writeFileSync(
  join(OUT, "vista-circulo.png"),
  png(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><defs>${defs}<clipPath id="k"><circle cx="54" cy="54" r="54"/></clipPath></defs><g clip-path="url(#k)"><rect width="108" height="108" fill="url(#bg)"/><rect width="108" height="108" fill="url(#sh)"/>${adaptable()}</g></svg>`, 432),
);
console.log("listo");
