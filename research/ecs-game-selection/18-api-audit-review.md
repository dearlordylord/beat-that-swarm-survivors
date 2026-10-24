# 18 — независимая проверка аудита межсущностного доступа

**Дата:** 2026-10-20. Прочитаны report 12 и текущие публичные декларации/потребители в Bendvy. Проверка read-only: приложения, тесты и сборки не запускались. Цель — проверить формулировки API, а не повторить execution evidence.

## Результат

Основной вывод report 12 о generic relation join подтверждается, если сузить его до прямого перехода из текущей entity к компонентам произвольного outgoing target в теле одной стандартной query. Обычный setter пишет текущую строку; relation row отдаёт detached handles через read-only capability; штатный relation provider читает inverse для уже переданного target и ставит relate/unrelate в очередь.

Есть две существенные оговорки. Во-первых, стандартный hierarchy helper умеет взять root, пройти descendants, а затем запустить обычную component query по ним как по текущим строкам. Это специальный tree traversal с заранее заданным root, не generic source-row → outgoing-target join. Во-вторых, report 12 слишком широко описывает совместный доступ к entity component и ресурсу: публичный `recognized-query-declaration` уже даёт `write + resource_write + pair`, а `recognized-app-component.add` регистрирует этот callback через обычный App runner. Это узкий canonical surface для component writes и целого owned resource; custom Ops и разнесение по фазам для такой комбинации не нужны. Отдельный selected-resource-field factory остаётся самостоятельным путём, и это не доказывает удобство любых произвольных query/resource комбинаций.

## Основания и пределы проверки

Подтверждён узкий вывод: обычный row writer не является универсальным
outgoing-target join. Специальный hierarchy traversal не следует скрывать этим
обобщением. Широкая претензия о невозможности component + global resource через
ordinary App была исправлена; Sparse является source-level контрпримером.

Определения и тела consumers остаются в источниках:

- [ordinary declarations](../../../bendvy/src/ecs/ordinary-query-declaration.bend),
  [Compose](../../../bendvy/src/ecs/compose.bend),
  [recognized declaration](../../../bendvy/src/ecs/recognized-query-declaration.bend).
- [Relation query](../../../bendvy/src/ecs/relation-query.bend),
  [relation App](../../../bendvy/src/ecs/ordinary-app-relation.bend),
  [hierarchy query](../../../bendvy/src/ecs/ordinary-app-hierarchy-query.bend).
- [Scheduled health](../../../bendvy/examples/scheduled-health/README.md),
  [user simulation](../../../bendvy/examples/user-simulation/README.md),
  [Sparse](../../../bendvy/test-fixtures/connected-performance/sparse-motion64/README.md).

Аудит не хранит копию сигнатур, алгоритмов регистрации или call graph.
Прочитанный arena source имел SHA-256
`45e8845e68489094dd2707d45ee437f07325646ed28fbfc82f955432bddd5730`,
отличавшийся от опубликованного digest в
[CHECKS.md](../../../bendvy/examples/arena/CHECKS.md).
Несовпадение ограничивает свежесть receipt и само по себе не доказывает поломку.

## Уточнение отчёта

[Report 12](12-cross-entity-access-audit.md) должен сохранять узкую границу:
supported component + whole-resource composition не является пробелом,
hierarchy traversal является специальным исключением, а generic outgoing-target
join и поздний structural barrier требуют отдельного рассмотрения.
Несовпадение digest ограничивает свидетельство исполнения, а не доказывает
неисполнимость исходника.

**Ограничения аудита:** не запускались компилятор, тесты, fixture или игра. Поэтому здесь подтверждены контракты по типам, реализациям и описанию consumers; не подтверждаются заново их актуальная компиляция, runtime результат или производительность. Raw/custom Ops и произвольные query adapters допускают более широкое поведение, поэтому вывод об отсутствии относится к стандартным закрытым surface, а не к абсолютной выразимости языка.
