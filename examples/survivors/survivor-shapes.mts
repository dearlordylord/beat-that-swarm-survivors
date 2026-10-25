// Shared character geometry for SVG, Canvas and the generated native renderer.
import { at } from "./host-values.mts"
export type SurvivorLayers = readonly (readonly [string, string])[]
const survivors: readonly SurvivorLayers[] = [
  [
    // Mira: round hair, cropped blue jacket, forward-pointing spark wand.
    ["#111b22", "M9 3h12v2h3v4h2v10h-3v4h3v6h-4v8h-6v-7h-3v7H7V22H5V10h2V5h2z"],
    ["#684335", "M10 5h10v2h3v10h-3v3H9v-3H7V9h3z"],
    ["#a86843", "M10 5h9v3h-7v4H8V9h2z"],
    ["#edc6a0", "M12 10h9v8h-3v3h-5v-4h-2v-5h1z"],
    ["#684335", "M11 9h10v3h-6v3h-4z"],
    ["#202a31", "M18 13h2v2h-2z"],
    ["#335e91", "M9 20h12v4h5v4h-9v-2H8v-3H6v-3z"],
    ["#608db5", "M9 20h4v6H9zm10 1h3v3h-3z"],
    ["#e4d4b5", "M14 20h3v7h-3z"],
    ["#263844", "M9 27h12v6h-5v-3h-3v3H9z"],
    ["#39322f", "M8 32h5v5H7v-3h1zm9 0h5v3h2v2h-7z"],
    ["#edc6a0", "M23 23h4v4h-4z"],
    ["#b98c4a", "M25 17h3v9h-3z"],
    ["#fff1b3", "M25 14h3v3h2v3h-5v-2h-2v-2h2z"]
  ],
  [
    // Corvin: narrow fugitive, silver scarf and twin knives.
    ["#131c23", "M11 4h11v3h2v11h-3v4h3v9h-4v6h-5v-8h-2v8H8V24H6v-6h4V8h1z"],
    ["#d0a98f", "M12 11h8v7h-3v3h-4v-5h-1z"],
    ["#33343c", "M12 6h9v3h2v6h-3v-4h-4v3h-2v2h-2v-5h-1V8h1z"],
    ["#18232a", "M17 12h2v2h-2z"],
    ["#384b4e", "M10 20h10v10H9V24H7v-4z"],
    ["#607271", "M10 21h3v7h-3zm9 2h3v6h-3z"],
    ["#c1cbd0", "M11 17h10v4H11zm-5 3h5v4H6zm-3 3h4v4H3z"],
    ["#f0ebe0", "M12 17h8v2h-8z"],
    ["#232c36", "M10 29h10v5h-4v-3h-3v3h-3z"],
    ["#4a3734", "M8 33h5v4H7v-2h1zm8 0h4v2h3v2h-7z"],
    ["#d0a98f", "M6 26h4v4H6zm15-2h4v4h-4z"],
    ["#a8834f", "M4 28h7v2H4zm16-2h7v2h-7z"],
    ["#d9e6e6", "M6 30h3v5H7v-2H6zm16-13h2v4h1v5h-3z"]
  ],
  [
    // Agatha: broad wormwood witch; the only pointed hat in the set.
    ["#182322", "M14 1h4v4h3v5h3v4h4v4h-6v4h3v7h3v8H5v-8h2v-7h3v-4H3v-4h7V8h4z"],
    ["#52664b", "M15 3h2v4h3v5h3v3H8v-3h4V9h3z"],
    ["#8b9a67", "M15 7h2v5h-3v3h-4v-3h3V9h2z"],
    ["#b09759", "M8 13h16v3H8z"],
    ["#d3b89c", "M11 18h10v6H11z"],
    ["#d2d5bd", "M8 18h4v10H8zm12 0h4v10h-4z"],
    ["#26392e", "M13 20h2v2h-2zm5 0h2v2h-2z"],
    ["#637552", "M10 25h12v3h3v7H7v-6h3z"],
    ["#a4ad78", "M13 25h6v9h-6z"],
    ["#414e3c", "M7 30h5v5H7zm13 0h5v5h-5z"],
    ["#423932", "M8 35h7v2H8zm11 0h6v2h-6z"],
    ["#d3b89c", "M5 27h4v4H5zm18 0h4v4h-4z"],
    ["#91a95f", "M3 22h3v3h3v4H6v-2H3zm24-2h2v3h-2zm-3 3h3v4h-3z"],
    ["#c2c98c", "M4 21h2v2H4zm22 2h2v2h-2z"]
  ],
  [
    // Seraph: rectangular amber armor, returning cross held upright.
    ["#202025", "M10 4h13v3h2v12h-3v2h5v10h-5v6h-6v-6h-2v6H7V22H5v-5h5z"],
    ["#b68139", "M11 6h11v3h2v8H11z"],
    ["#e0b65e", "M12 6h9v3h-7v4h-2z"],
    ["#34333c", "M11 12h11v4H11z"],
    ["#efd4a0", "M13 13h7v2h-7z"],
    ["#856034", "M10 17h12v4H10z"],
    ["#bc8841", "M9 21h15v10H9zm-3-1h6v7H6zm16 0h5v7h-5z"],
    ["#e3b564", "M9 21h4v7H9zm8 1h5v3h-5z"],
    ["#eee0b0", "M15 21h3v10h-3zm-2 3h7v3h-7z"],
    ["#5e4540", "M10 31h5v6H8v-3h2zm8 0h5v3h2v3h-7z"],
    ["#a7763b", "M9 32h5v3H9zm10 0h4v3h-4z"],
    ["#34333c", "M3 17h4v15H3z"],
    ["#d4b06d", "M3 16h3v15H3zM0 20h9v3H0z"],
    ["#f0d9a0", "M3 17h2v5H3z"]
  ],
  [
    // Bran: bald, broad butcher with an ochre apron and a heavy axe.
    ["#231f1f", "M10 4h11v3h3v10h3v5h3v9h-6v6h-8v-5h-1v5H6v-6H2V20h4v-5h3V7h1z"],
    ["#ce9f7b", "M11 6h9v2h3v8H9V9h2z"],
    ["#e6ba91", "M12 6h7v4h-7z"],
    ["#312a29", "M10 12h3v2h-3zm8 0h3v2h-3z"],
    ["#80563d", "M10 16h11v4H10z"],
    ["#c09470", "M5 19h7v10H4v-7h1zm16 0h6v4h2v6h-8z"],
    ["#594739", "M10 19h12v13H9V22h1z"],
    ["#c19142", "M10 20h3v5h7v-5h3v14H8v-9h2z"],
    ["#e0b15f", "M11 26h9v3h-9z"],
    ["#85602e", "M12 30h7v4h-7z"],
    ["#4e3d32", "M7 34h7v3H6v-2h1zm11 0h6v1h2v2h-8z"],
    ["#68472e", "M26 12h3v20h-3z"],
    ["#a6b2af", "M22 8h7v2h3v10h-5v-4h-5z"],
    ["#d6ded2", "M30 10h2v10h-2z"]
  ],
  [
    // Eira: slender frost weaver, fur collar and long side braid.
    ["#172730", "M11 3h10v3h3v13h-3v3h3v10h-4v5h-5v-7h-2v7H8V22H6v-4h3V7h2z"],
    ["#bed6d6", "M12 5h8v2h2v8H10V8h2z"],
    ["#f2e6d6", "M12 10h8v8h-7v-3h-1z"],
    ["#346171", "M17 12h2v2h-2z"],
    ["#d8ebdf", "M10 7h11v4h-7v3h-4z"],
    ["#60a2ae", "M10 21h10v5h2v7H8v-7h2z"],
    ["#95c8cb", "M11 23h4v9h-4zm8 1h4v5h-4z"],
    ["#e2e4d5", "M7 18h5v2h7v-2h5v6h-5v-1h-7v1H7z"],
    ["#acc9c9", "M21 13h3v7h-3zm1 7h3v5h-3zm1 5h3v5h-3zm-1 5h3v4h-3z"],
    ["#50768a", "M22 19h3v2h-3zm1 8h3v2h-3z"],
    ["#3c4b51", "M9 33h4v4H8v-2h1zm7 0h4v2h2v2h-6z"],
    ["#f2e6d6", "M5 24h4v4H5zm15 1h3v3h-3z"],
    ["#b9ebed", "M3 18h1v12H3zm2-2h1v13H5zm2 2h1v11H7z"]
  ],
  [
    // Nox: tall funeral mask and a broad crescent scythe.
    ["#191b29", "M11 3h10v3h3v12h-3v4h2v8h2v7H7v-8h2V17H7V8h4z"],
    ["#59476f", "M12 5h8v2h2v11H9V9h3z"],
    ["#99849e", "M12 6h3v3h-3v7h-2V9h2z"],
    ["#e1dcc9", "M12 9h8v10h-2v3h-4v-3h-2z"],
    ["#252837", "M13 12h2v3h-2zm4 0h2v3h-2zm-2 5h2v3h-2z"],
    ["#534465", "M11 22h10v8h2v5H9v-7h2z"],
    ["#80638c", "M12 22h3v11h-5v-4h2z"],
    ["#2b293c", "M17 23h3v12h-3z"],
    ["#b7a4ad", "M13 23h6v2h-6z"],
    ["#34313d", "M8 35h7v2H8zm10 0h6v2h-6z"],
    ["#afa6a1", "M21 24h4v4h-4z"],
    ["#786d6b", "M25 7h2v30h-2z"],
    ["#a9b4ba", "M23 2h7v3h2v9h-3v4h-3v-3h2V6h-5V4h-4V2z"],
    ["#e1dfe0", "M29 5h3v9h-2V7h-1z"]
  ],
  [
    // Lumen: small round hood, cage lantern backpack and one wisp.
    ["#182725", "M6 10h10v2h4v4h2v10h-2v5h1v6h-6v-4h-2v4H6v-6H3V17h1v-4h2z"],
    ["#477c6c", "M7 12h9v2h3v4h1v7h-3v3H6v-3H4v-7h1v-3h2z"],
    ["#79ae91", "M7 13h8v3H9v3H6v-3h1z"],
    ["#293e38", "M9 18h8v8H8v-6h1z"],
    ["#e1caa4", "M10 19h6v6h-6z"],
    ["#273b35", "M13 21h2v2h-2z"],
    ["#72a68b", "M7 28h10v6H6v-4h1z"],
    ["#b6d0aa", "M9 28h3v5H9z"],
    ["#524b39", "M6 34h6v3H5v-2h1zm9 0h5v1h2v2h-7z"],
    ["#293d34", "M21 15h7v4h3v13H19V19h2z"],
    ["#b29757", "M22 16h5v2h-5zm-1 4h8v10h-8z"],
    ["#dce5a0", "M22 21h6v8h-6z"],
    ["#53634c", "M24 20h2v10h-2zm-4 4h10v2H20zm-1 6h12v2H19z"],
    ["#bfe4b8", "M24 5h4v2h2v4h-2v2h-4v-3h-2V7h2z"],
    ["#f1f2c9", "M25 7h3v3h-3z"]
  ]
]

export function survivorLayers(id = 0) {
  return at(survivors, Number.isInteger(id) && id >= 0 && id < 8 ? id : 0)
}
