# 12 — аудит доступа между сущностями в текущем Bendvy

**Дата проверки:** 2026-10-20. Проверял исходники и сохранённые отчёты read-only; код и тесты не запускал.

## Вывод

Bendvy поддерживает пакетную запись по нескольким строкам одного компонентного семейства и отдельный публичный recognized-App путь, который в одной query-транзакции сочетает writer текущей сущности с записью глобального ресурса. Но обычный component writer адресует только текущую сущность строки. Relation-query может вернуть detached target/source handles, однако его view read-only; явная запись в другой handle идёт через deferred command и барьер. Поэтому штатный App API всё ещё не даёт короткого канонического пути «найти связанный объект, прочитать его компоненты и атомарно изменить обе стороны».

Граница проходит не между «resource API есть» и «resource API отсутствует», а между канонической закрытой композицией и произвольными query-комбинациями. `recognized-query-declaration` предоставляет `write`, `resource_write` и `pair`, а `recognized-app-component.add` регистрирует такой runner в executable App. Этот узкий маршрут покрывает компонент + общий ресурс; он не обещает все ordinary query combinators или адаптеры для произвольных selectors. Для relation target joins и иных custom grants по-прежнему нужен отдельный, проверяемый путь.

Самые прямые для имеющегося API сценарии из исследованных кандидатов — пакетное попадание Magicka-подобного заклинания по нескольким сущностям здоровья и push-chain Baba Is You по одному семейству `GridPosition`. FTL-подобный общий power не является пробелом: его можно сочетать с компонентом crew через recognized pair; dynamic crew→room lookup и запись компонентов связанной комнаты остаются фазовым/custom-query вопросом. Взаимодействие SS14-подобных actor + tool + door сильнее всего выявляет нехватку штатного межсущностного join-а.

## Источники границ API

Определения и алгоритмы доступа не дублируются в этом отчёте. Источники:

- [Component/query capabilities](../../../bendvy/src/ecs/capabilities.bend),
  [Compose](../../../bendvy/src/ecs/compose.bend) и
  [recognized declarations](../../../bendvy/src/ecs/recognized-query-declaration.bend).
- [Relation query](../../../bendvy/src/ecs/relation-query.bend),
  [ordinary relation entry](../../../bendvy/src/ecs/ordinary-app-relation.bend) и
  [hierarchy query](../../../bendvy/src/ecs/ordinary-app-hierarchy-query.bend).
- [Обычный App](../../../bendvy/docs/reference/ordinary-app.md) и
  [transaction implementation](../../../bendvy/src/ecs/transaction.bend).

Вывод аудита — различать same-row composition, специальные traversal adapters
и общий outgoing-target join. Нельзя выводить общую atomicity последующего
structural barrier из существования транзакции immediate writes. Для выбора
игрового среза важна именно требуемая граница действия, а не число factories.

## Применение к четырём срезам

| Сценарий из кандидатов | Реалистичный шаблон в Bendvy | Оценка текущего API |
|---|---|---|
| **SS14-подобное actor → tool → door** ([гипотеза 07](07-space-station.md)) | До обновления разрешить взаимодействие в план: actor/tool/door handles, проверка доступности и выбранный результат. Для повторяемых изменений одного семейства использовать batch query. Для отсутствующего компонента двери — explicit-target deferred insert и barrier; для door/actor/tool разных типов нужны отдельные typed passes либо пользовательский composite adapter. | Самая неудобная из четырёх связок: и связь/containment, и доступ к target components, и межсемейная atomicity. Утверждение, что эти вещи невозможны, было бы слишком сильным: детали можно собрать на низком уровне; штатный ordinary row query их не поставляет. |
| **FTL-подобный crew → room + общий power** ([гипотеза 08](08-modular-ships.md)) | Изменение component-ов по семейству crew вместе с общим power resource укладывается в recognized `pair(write, resource_write)` как один App runner/transaction. Но closed selector не выбирает произвольного crew по handle из команды. Для известной комнаты incoming inverse даёт экипаж; outgoing assignment можно получить из detached relation view/плана. Если действие также меняет компонент комнаты, target row всё ещё надо подготовить/обновить другим typed pass или custom relation adapter; relation changes становятся видимы на barrier. | Хорошее соответствие для семейного crew update + global power; среднее для полного crew→room цикла. Ограничитель здесь — не ресурс, а выбор одного target crew/room через динамическую relation и запись другого компонентного семейства. Фазность подходит, если правила игры допускают этот commit/barrier порядок. |
| **Magicka-подобный AoE spell → несколько Health/Wet целей** ([гипотеза 04](04-systemic-sandbox.md)) | Контактная фаза заранее строит `Args`-список поражённых handles/эффектов; один `Health` query применяет damage ко всем подходящим целям транзакционно. Установка нового optional `Wet`/`Burning` компонента идёт structural command/barrier после вычисления эффекта. | Хорошо для самого ECS-среза при разделении hit-plan и structural phase. Связь projectile→caster для attribution может быть read-only snapshot или заранее вложена в plan; динамический target-follow внутри `Health` callback остаётся неудобным. Нельзя обещать all-or-none между damage и поздним отказом insertion. |
| **Baba Is You push-chain → много GridPosition** ([гипотеза 10](10-rule-puzzles.md)) | На начале хода вычислить полный допустимый push chain и новый `GridPosition` каждого handle. Применить его одним traversal над `GridPosition`-семейством с планом в `Args`; если цепь заблокирована, не создавать план изменений. Производные `Stop/Push/Win` trait additions/removals — отдельная structural фаза после сканирования правил. | Наиболее естественный multi-entity direct-write пример: связь не нужна, а все immediate row writes одного семейства. Нужен handle access для планового сопоставления и отдельная barrier-фаза для изменения состава компонентов. |

Magicka и Baba иллюстрируют важное различие. Пакетная транзакция подходит для однотипных immediate данных (`Health`, `GridPosition`). Если каждый target требует вставки/удаления разных optional components, это уже structural batch с barrier semantics, а не тот же atomic operation.

## Потребители и свежесть свидетельств

[Scheduled health](../../../bendvy/examples/scheduled-health/README.md),
[user simulation](../../../bendvy/examples/user-simulation/README.md),
[arena](../../../bendvy/examples/arena/README.md) и
[Sparse](../../../bendvy/test-fixtures/connected-performance/sparse-motion64/README.md)
были прочитаны как исходники. Их тела и планы не пересказываются здесь; этот
аудит не запускал их повторно.

Историческое свидетельство user simulation фиксировало 23 JS checkpoints от
2026-10-17. У arena опубликованный digest `game.bend`
`d53f351e3b8b53df5d84489458a087de228eee505a276285b450711dab0762b8`
не совпадал с прочитанным
`45e8845e68489094dd2707d45ee437f07325646ed28fbfc82f955432bddd5730`.
Это ограничение свежести evidence, а не доказательство ошибки исполнения.
[Записанные проверки](../../../bendvy/examples/arena/CHECKS.md).
Relation delivery artifact отсутствовал в прочитанном checkout; его прошлую
qualification нельзя приравнивать к новому executed consumer.

## Конкретное ограничение и критерий остановки

Ключевой недостающий стандартный ergonomic unit — не «relation API» вообще, а композиция: *текущая entity → outgoing relation target → query target components → journaled target write в той же транзакции*. Вторая недостающая часть — принятие результатов structural barrier в одну all-or-nothing операцию с immediate entity/resource writes. Источники подтверждают deferred commands и notices, но не такую общую commit transaction.

Для первого clone Baba-подобное ядро остаётся самым прямым способом показать multi-row write одного семейства; Magicka также хорошо подходит и может в том же recognized query транзакционно обновлять общий ресурс. FTL становится заметно жизнеспособнее, если срез ограничен обработкой crew-family + global power и конкретный relation-driven target update можно вынести в фазу. Если основной ввод — приказ выбранному crew member, а главный результат меняет связанную room entity, до фиксации выбора нужно прототипировать selector/relation adapter. Считать этот срез blocker-ом только если такое требование определяет результат игры либо поздний отказ barrier должен отменять уже committed значения.

## Пересмотр после проверки recognized API

Первоначальная версия слишком широко объявляла component + global resource
пробелом ordinary App. Sparse опровергает этот вывод для поддержанной закрытой
композиции. Уточнение не устраняет отдельный вопрос произвольного target join и
не превращает последовательные регистрации в одну all-or-nothing операцию.
Конкретный supported surface следует проверять по связанным исходникам, а не по
историческому перечню функций в Markdown.
