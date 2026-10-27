import Base
import ./model.bend as M
import ./accessories.bend as Old

def ink() -> String:
  "#101729"

def rj16() -> String:
  M.polygon([M.Point{5n, 9n}, M.Point{11n, 9n}, M.Point{12n, 11n}, M.Point{13n, 12n}, M.Point{13n, 15n}, M.Point{12n, 16n}, M.Point{12n, 18n}, M.Point{9n, 18n}, M.Point{8n, 17n}, M.Point{7n, 18n}, M.Point{4n, 18n}, M.Point{4n, 16n}, M.Point{3n, 15n}, M.Point{3n, 12n}, M.Point{4n, 11n}], ink()) ++
  M.rect(5n, 10n, 6n, 6n, "#fff8e6") ++ M.rect(4n, 12n, 8n, 3n, "#fff8e6") ++
  M.rect(5n, 16n, 2n, 1n, "#ae8050") ++ M.rect(9n, 16n, 2n, 1n, "#ae8050") ++
  M.rect(5n, 13n, 1n, 2n, "#d5cbb7") ++ M.rect(10n, 13n, 1n, 2n, "#d5cbb7") ++
  M.rect(1n, 1n, 3n, 3n, ink()) ++ M.rect(12n, 1n, 3n, 3n, ink()) ++
  M.rect(2n, 2n, 1n, 1n, "#fff8e6") ++ M.rect(13n, 2n, 1n, 1n, "#fff8e6") ++
  M.polygon([M.Point{4n, 0n}, M.Point{7n, 0n}, M.Point{8n, 1n}, M.Point{9n, 0n}, M.Point{12n, 0n}, M.Point{13n, 2n}, M.Point{14n, 2n}, M.Point{14n, 4n}, M.Point{15n, 4n}, M.Point{15n, 7n}, M.Point{14n, 7n}, M.Point{14n, 9n}, M.Point{12n, 10n}, M.Point{4n, 10n}, M.Point{2n, 9n}, M.Point{2n, 7n}, M.Point{1n, 7n}, M.Point{1n, 4n}, M.Point{2n, 4n}, M.Point{2n, 2n}, M.Point{3n, 2n}], ink()) ++
  M.rect(5n, 1n, 2n, 2n, "#fff8e6") ++ M.rect(10n, 1n, 2n, 2n, "#fff8e6") ++
  M.rect(4n, 2n, 9n, 6n, "#fff8e6") ++ M.rect(3n, 3n, 10n, 5n, "#fff8e6") ++
  M.rect(2n, 5n, 12n, 2n, "#fff8e6") ++ M.rect(4n, 8n, 8n, 1n, "#fff8e6") ++
  M.rect(5n, 5n, 1n, 1n, ink()) ++ M.rect(11n, 5n, 1n, 1n, ink()) ++
  M.rect(8n, 6n, 1n, 1n, ink()) ++ M.rect(8n, 7n, 1n, 1n, ink()) ++
  M.rect(6n, 7n, 1n, 1n, ink()) ++ M.rect(10n, 7n, 1n, 1n, ink()) ++
  M.rect(7n, 8n, 1n, 1n, ink()) ++ M.rect(9n, 8n, 1n, 1n, ink()) ++
  M.rect(4n, 6n, 1n, 1n, "#e99695") ++ M.rect(12n, 6n, 1n, 1n, "#e99695") ++
  M.polygon([M.Point{4n, 10n}, M.Point{12n, 9n}, M.Point{10n, 11n}, M.Point{5n, 12n}], "#e55751") ++
  M.rect(10n, 11n, 2n, 2n, "#e55751")

def koya16() -> String:
  M.rect(5n, 11n, 7n, 6n, ink()) ++
  M.rect(6n, 12n, 5n, 4n, "#94d9ed") ++
  M.rect(7n, 12n, 3n, 3n, "#fff8e6") ++
  M.polygon([M.Point{1n, 1n}, M.Point{5n, 1n}, M.Point{6n, 3n}, M.Point{10n, 3n}, M.Point{11n, 1n}, M.Point{15n, 1n}, M.Point{16n, 2n}, M.Point{16n, 6n}, M.Point{15n, 7n}, M.Point{15n, 10n}, M.Point{13n, 12n}, M.Point{3n, 12n}, M.Point{1n, 10n}, M.Point{1n, 7n}, M.Point{0n, 6n}, M.Point{0n, 2n}], ink()) ++
  M.rect(1n, 2n, 4n, 4n, "#94d9ed") ++ M.rect(11n, 2n, 4n, 4n, "#94d9ed") ++
  M.rect(2n, 3n, 2n, 2n, "#e0f6fa") ++ M.rect(12n, 3n, 2n, 2n, "#e0f6fa") ++
  M.rect(4n, 4n, 8n, 7n, "#94d9ed") ++ M.rect(2n, 6n, 12n, 4n, "#94d9ed") ++
  M.rect(3n, 8n, 3n, 1n, ink()) ++ M.rect(11n, 8n, 3n, 1n, ink()) ++
  M.rect(7n, 6n, 3n, 4n, "#8768e9") ++
  M.rect(7n, 11n, 3n, 1n, ink())

def mang16() -> String:
  M.rect(5n, 11n, 6n, 6n, ink()) ++ M.rect(6n, 12n, 4n, 4n, "#ac79d3") ++
  M.polygon([M.Point{3n, 0n}, M.Point{6n, 0n}, M.Point{7n, 2n}, M.Point{10n, 2n}, M.Point{12n, 4n}, M.Point{12n, 6n}, M.Point{15n, 6n}, M.Point{16n, 7n}, M.Point{16n, 10n}, M.Point{13n, 13n}, M.Point{8n, 13n}, M.Point{6n, 12n}, M.Point{3n, 12n}, M.Point{1n, 10n}, M.Point{1n, 3n}, M.Point{3n, 2n}], ink()) ++
  M.rect(3n, 1n, 2n, 3n, "#ad7bd6") ++ M.rect(2n, 4n, 3n, 7n, "#ad7bd6") ++
  M.rect(5n, 3n, 5n, 8n, "#7cdae4") ++ M.rect(4n, 5n, 7n, 5n, "#7cdae4") ++
  M.rect(7n, 4n, 3n, 3n, "#fff8e6") ++ M.rect(9n, 5n, 1n, 2n, ink()) ++
  M.rect(9n, 7n, 6n, 3n, "#f2a0d5") ++ M.rect(10n, 10n, 4n, 1n, "#f2a0d5") ++ M.rect(11n, 11n, 2n, 1n, "#f2a0d5") ++
  M.rect(11n, 7n, 1n, 1n, "#7cdae4") ++ M.rect(14n, 8n, 1n, 1n, "#b560a8")

def chimmy16() -> String:
  M.rect(5n, 11n, 7n, 6n, ink()) ++ M.rect(6n, 12n, 5n, 4n, "#ffdc42") ++
  M.rect(7n, 12n, 3n, 2n, "#fff8e6") ++
  M.polygon([M.Point{5n, 0n}, M.Point{11n, 0n}, M.Point{14n, 2n}, M.Point{15n, 5n}, M.Point{15n, 10n}, M.Point{13n, 12n}, M.Point{4n, 12n}, M.Point{1n, 10n}, M.Point{1n, 5n}, M.Point{2n, 2n}], ink()) ++
  M.polygon([M.Point{5n, 1n}, M.Point{11n, 1n}, M.Point{13n, 3n}, M.Point{14n, 5n}, M.Point{14n, 9n}, M.Point{12n, 11n}, M.Point{4n, 11n}, M.Point{2n, 9n}, M.Point{2n, 5n}, M.Point{3n, 3n}], "#ffdc42") ++
  M.polygon([M.Point{6n, 3n}, M.Point{10n, 3n}, M.Point{12n, 5n}, M.Point{12n, 9n}, M.Point{10n, 11n}, M.Point{6n, 11n}, M.Point{4n, 9n}, M.Point{4n, 5n}], "#fff8e6") ++
  M.rect(1n, 4n, 3n, 7n, ink()) ++ M.rect(0n, 6n, 2n, 4n, ink()) ++
  M.rect(1n, 6n, 1n, 3n, "#393b48") ++
  M.rect(13n, 4n, 2n, 6n, ink()) ++ M.rect(14n, 6n, 2n, 3n, ink()) ++ M.rect(14n, 5n, 1n, 2n, "#393b48") ++
  M.rect(6n, 6n, 1n, 1n, ink()) ++ M.rect(10n, 6n, 1n, 1n, ink()) ++
  M.rect(8n, 7n, 2n, 1n, ink()) ++ M.rect(8n, 8n, 1n, 1n, ink()) ++ M.rect(9n, 9n, 2n, 2n, "#ed879e")

def icon(id: Nat) -> String:
  match id:
    case 0n: koya16()
    case 1n: rj16()
    case 3n: mang16()
    case 4n: chimmy16()
    case _: "<g transform=\"scale(1.25)\">" ++ Old.icon(id, 1n) ++ "</g>"
