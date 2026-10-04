# Random Forest

## Назначение и охват

Это карта проекта: что запускает игру, как устроены механики, где находятся неявные контракты и что опасно менять без проверки.

Для навигации ниже есть полный индекс исходников. Ресурсные файлы комнат, объектов и настроек также сверены с [проектом GameMaker](../RandomForest/RandomForest.yyp).

Проект — пиксельный 2D-платформер GameMaker Studio 2. Базовая частота — 60 кадров/с в [главных настройках](../RandomForest/options/main/options_main.yy); почти все числовые времена в коде выражены в кадрах.

## Быстрое ориентирование

### Основной маршрут по комнатам

| Этап | Переход и ответственный код |
| --- | --- |
| Старт | [rLoading](../RandomForest/rooms/rLoading/rLoading.yy) создаёт [oLoading](../RandomForest/objects/oLoading/oLoading.yy); его [Create](../RandomForest/objects/oLoading/Create_0.gml) грузит сохранение и конфигурацию, а [Alarm](../RandomForest/objects/oLoading/Alarm_0.gml) открывает [rMenu](../RandomForest/rooms/rMenu/rMenu.yy). |
| Главное меню | [oMenu](../RandomForest/objects/oMenu/oMenu.yy) выбирает обработчик из [scriptMenuFunctions](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml). «Начать играть» открывает первый уровень, а «Продолжить» — единый [rLevelSelect](../RandomForest/rooms/rLevelSelect/rLevelSelect.yy). |
| Выбор уровня | [oLevelSelect](../RandomForest/objects/oLevelSelect/oLevelSelect.yy) показывает всю последовательность страницами по 10. При входе открывается страница `global.current_level div 10`, поэтому для текущего уровня 11+ сразу виден и выделен именно он. |
| Игровые уровни | [funOpenLevel](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml) открывает обычную комнату для индексов 0–9 или выбранный JSON в [rGeneratedLevel](../RandomForest/rooms/rGeneratedLevel/rGeneratedLevel.yy) для индексов 10+. |
| Завершение | Дверь сохраняет общий рекорд и открывает следующий абсолютный индекс. Перед статистикой может открыться ещё не просмотренная ЧК; включены сцены до 40 включительно. Уровень 10 переходит к `challenge_levels/01.json`. |
| Финал | После последней записи текущего каталога кнопка «Перейти дальше» открывает [rVictory](../RandomForest/rooms/rVictory/rVictory.yy). Его [RoomCreationCode](../RandomForest/rooms/rVictory/RoomCreationCode.gml) выставляет глобальный флаг завершения. [oVictory](../RandomForest/objects/oVictory/oVictory.yy) по двойному нажатию возвращает в меню. |

Первые десять абсолютных индексов сопоставлены комнатам в [funOpenLevel](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml) и [funGetRoomIndex](../RandomForest/scripts/funGetRoomIndex/funGetRoomIndex.gml). Все последующие индексы вычисляются из порядка `challenge_levels/catalog.json`; порядок комнат проекта для перехода между игровыми уровнями не используется.

### Игровые комнаты и их содержимое

| № прогресса | Комната | Назначение/особенности по составу |
| --- | --- | --- |
| 0 | [rTutorial01](../RandomForest/rooms/rTutorial01/rTutorial01.yy) | Движение, сбор ягод и открытие портала; подсказка от [oHelpTutorial01](../RandomForest/objects/oHelpTutorial01/oHelpTutorial01.yy). |
| 1 | [rTutorial02](../RandomForest/rooms/rTutorial02/rTutorial02.yy) | Обычный удар X; один [oSkeleton](../RandomForest/objects/oSkeleton/oSkeleton.yy), подсказка от [oHelpTutorial02](../RandomForest/objects/oHelpTutorial02/oHelpTutorial02.yy). |
| 2 | [rTutorial03](../RandomForest/rooms/rTutorial03/rTutorial03.yy) | Бросок и отзыв меча, ловушки; [oHelpTutorial03](../RandomForest/objects/oHelpTutorial03/oHelpTutorial03.yy). |
| 3 | [rTutorial04](../RandomForest/rooms/rTutorial04/rTutorial04.yy) | Выбор направления броска, слизень и ловушки; [oHelpTutorial04](../RandomForest/objects/oHelpTutorial04/oHelpTutorial04.yy). |
| 4 | [rTutorial05](../RandomForest/rooms/rTutorial05/rTutorial05.yy) | Бросок слабее удара и телепорт к мечу; [oHelpTutorial05](../RandomForest/objects/oHelpTutorial05/oHelpTutorial05.yy). |
| 5 | [rTutorial06](../RandomForest/rooms/rTutorial06/rTutorial06.yy) | Один бросок в воздухе до приземления; [oHelpTutorial06](../RandomForest/objects/oHelpTutorial06/oHelpTutorial06.yy). |
| 6 | [rLevel01](../RandomForest/rooms/rLevel01/rLevel01.yy) | Два [oSlime](../RandomForest/objects/oSlime/oSlime.yy), ловушки и прыжковые платформы. |
| 7 | [rLevel02](../RandomForest/rooms/rLevel02/rLevel02.yy) | Один [oBungalo](../RandomForest/objects/oBungalo/oBungalo.yy), ловушки. |
| 8 | [rLevel03](../RandomForest/rooms/rLevel03/rLevel03.yy) | Платформенно-ловушечный уровень без врагов. |
| 9 | [rLevel04](../RandomForest/rooms/rLevel04/rLevel04.yy) | Десятый обычный уровень: шесть слизней, два скелета, два бунгало, 14 ловушек и восемь ягод. |
| 10+ | [rGeneratedLevel](../RandomForest/rooms/rGeneratedLevel/rGeneratedLevel.yy) | Универсальная рантайм-комната для уровней 11+; семантическая карта задаёт размеры, геометрию, ловушки и сущности, а стилизатор выводит точные тайлы платформ, травы и шипов. |

[rTemplate](../RandomForest/rooms/rTemplate/rTemplate.yy) — заготовка со стандартными управляющими объектами, но без игрока, двери и геометрии. [rTraining](../RandomForest/rooms/rTraining/rTraining.yy) содержит полноэкранный [oTraining](../RandomForest/objects/oTraining/oTraining.yy), но обычное меню открывает тот же объект поверх меню, а не эту комнату.

### Генерируемые уровни

Формат описан в [docs/generated-level-format.md](generated-level-format.md). Это
JSON с единой ASCII-картой `map`; при загрузке она разделяется на внутренние
terrain, hazards и entities. Визуал, коллизии и instances полностью выводятся
из их семантики; фаза шипов кодируется прямо символом hazard.

Текущий путь данных:

1. [funLoadChallengeCatalog](../RandomForest/scripts/funLoadChallengeCatalog/funLoadChallengeCatalog.gml) читает `challenge_levels/catalog.json` из GameMaker Included Files. [funGetLevelsCount](../RandomForest/scripts/funGetLevelsCount/funGetLevelsCount.gml) добавляет длину каталога к десяти обычным уровням.
2. [funOpenGeneratedLevel](../RandomForest/scripts/funOpenGeneratedLevel/funOpenGeneratedLevel.gml) переводит абсолютный индекс в индекс каталога, а [funGenerateLevel](../RandomForest/scripts/funGenerateLevel/funGenerateLevel.gml) читает выбранный Included File и возвращает семантический `level_data`.
3. [funValidateGeneratedLevel](../RandomForest/scripts/funValidateGeneratedLevel/funValidateGeneratedLevel.gml) проверяет ровно одного игрока `@`, одну дверь `O`/`o` и наличие обоих порогов `star_times`. Эта runtime-проверка намеренно мягче Python validator: остальная геометрия считается доверенным выводом генератора.
4. [funStyleGeneratedLevel](../RandomForest/scripts/funStyleGeneratedLevel/funStyleGeneratedLevel.gml) по топологии платформ и локальному coordinate hash детерминированно выбирает варианты `tsPlatforms`, добавляет Grass и строит `tsSpikesExt`. Глобальный RNG игры не меняется.
5. Первый экземпляр [oGeneratedLevelController](../RandomForest/objects/oGeneratedLevelController/oGeneratedLevelController.yy) меняет размер комнаты, заменяет tilemap-слои и создаёт коллизии/сущности до Create-событий камеры и HUD. Это особенно важно для первоначального `instance_number(oCoin)` в `oCoinCollector`.

Каталог задаёт окончательный порядок уровней 11+. Чтобы добавить новые уровни без изменения runtime-кода, нужно добавить JSON в Included Files и дописать его путь в конец `catalog.json`. Если игрок прошёл прежний последний уровень, после обновления ему открывается первый новый.

Одна клетка равна 12×12 игровым пикселям, а расширенные шипы рендерятся сеткой 6×6 и могут выступать за семантическую клетку. Из-за фиксированного viewport 480×270 и рамки камеры 12 пикселей минимально поддерживаемый размер — 42×25 клеток; внешний ряд и столбец карты следует оставлять пустыми, иначе камера их обрежет. Верхней границы формат не задаёт, но память tilemap и время сборки растут линейно с площадью. Сплошные клетки и одинаково направленные ловушки объединяются в прямоугольники/отрезки, поэтому число невидимых instances обычно заметно меньше числа клеток.

## Архитектура: реальные правила проекта

### Объектная иерархия

- [oEnemy](../RandomForest/objects/oEnemy/oEnemy.yy) — пустой невидимый родитель:
  - [oSlime](../RandomForest/objects/oSlime/oSlime.yy);
  - [oSkeleton](../RandomForest/objects/oSkeleton/oSkeleton.yy);
  - [oBungalo](../RandomForest/objects/oBungalo/oBungalo.yy);
  - [oSkeletonSword](../RandomForest/objects/oSkeletonSword/oSkeletonSword.yy);
  - [oBungaloSword](../RandomForest/objects/oBungaloSword/oBungaloSword.yy).
- [oSolid](../RandomForest/objects/oSolid/oSolid.yy) — родитель коллизий мира:
  - [oJumpThru](../RandomForest/objects/oJumpThru/oJumpThru.yy).
- [oPlayerSword](../RandomForest/objects/oPlayerSword/oPlayerSword.yy) — невидимая маска обычного удара:
  - [oPlayerTapSword](../RandomForest/objects/oPlayerTapSword/oPlayerTapSword.yy).
- [oAlwaysDraw](../RandomForest/objects/oAlwaysDraw/oAlwaysDraw.yy) — маркер для объектов, остающихся видимыми при выборе направления броска:
  - [oFadingText](../RandomForest/objects/oFadingText/oFadingText.yy);
  - [oHelpTutorial01](../RandomForest/objects/oHelpTutorial01/oHelpTutorial01.yy) … [oHelpTutorial06](../RandomForest/objects/oHelpTutorial06/oHelpTutorial06.yy).

Проект не использует менеджеры, ECS или явные ссылки на экземпляры. Вместо этого код систематически обращается к именам объектов как к единственным экземплярам: [oPlayer](../RandomForest/objects/oPlayer/oPlayer.yy), [oCamera](../RandomForest/objects/oCamera/oCamera.yy), [oTimeCounter](../RandomForest/objects/oTimeCounter/oTimeCounter.yy), [oCoinCollector](../RandomForest/objects/oCoinCollector/oCoinCollector.yy). Это удобно для маленькой игры, но означает контракт: в игровой комнате должен быть ровно один экземпляр каждого из них.

Особенно важно, что мечи врагов также наследуют [oEnemy](../RandomForest/objects/oEnemy/oEnemy.yy). Поэтому общий код урона игрока в [funPlayerDetectCriticalState](../RandomForest/scripts/funPlayerDetectCriticalState/funPlayerDetectCriticalState.gml) считает и тело врага, и его активный меч одним классом угрозы. Тела и мечи явно задают can_damage_player/is_dead; числовые enum разных типов больше не сравниваются.

### Типичный жизненный цикл состояния

Игрок, слизень, скелет и бунгало используют один паттерн:

1. В Step уменьшаются счётчики.
2. По self.state выбирается логика.
3. Если self.state_changed, один раз вызывается Start-функция.
4. Logic-функция меняет состояние через [funPlayerChangeState](../RandomForest/scripts/funPlayerChangeState/funPlayerChangeState.gml) или [funDefaultChangeState](../RandomForest/scripts/funDefaultChangeState/funDefaultChangeState.gml).
5. Событие окончания анимации выставляет флаг; его обрабатывают соответствующие Logic-функции.

Диспетчеры находятся в [Step игрока](../RandomForest/objects/oPlayer/Step_0.gml), [Step слизня](../RandomForest/objects/oSlime/Step_0.gml), [Step скелета](../RandomForest/objects/oSkeleton/Step_0.gml) и [Step бунгало](../RandomForest/objects/oBungalo/Step_0.gml). Флаги окончания анимации — в их [Other_7](../RandomForest/objects/oPlayer/Other_7.gml), [Other_7](../RandomForest/objects/oSlime/Other_7.gml), [Other_7](../RandomForest/objects/oSkeleton/Other_7.gml), [Other_7](../RandomForest/objects/oBungalo/Other_7.gml).

## Игрок

### Ввод и состояния

Раскладка задаётся глобально в [Create загрузчика](../RandomForest/objects/oLoading/Create_0.gml): стрелки — движение/направление, Up — прыжок, Down — пройти вниз через платформу, X — удар или отзыв меча, C — бросок/телепорт, Escape — пауза, F — полноэкранный режим. Состояние клавиш собирается [funReadInputs](../RandomForest/scripts/funReadInputs/funReadInputs.gml).

| Состояние | Что делает | Код |
| --- | --- | --- |
| idle | Стоит; случайно проигрывает blink/wondering-анимации. | [scriptPlayerIdleState](../RandomForest/scripts/scriptPlayerIdleState/scriptPlayerIdleState.gml) |
| move | Горизонтальное движение, поворот спрайта и шаги на заданных кадрах. | [scriptPlayerMoveState](../RandomForest/scripts/scriptPlayerMoveState/scriptPlayerMoveState.gml) |
| prejump | Один кадр подготовки: задаёт вертикальный импульс и создаёт визуальный эффект. | [scriptPlayerPreJumpState](../RandomForest/scripts/scriptPlayerPreJumpState/scriptPlayerPreJumpState.gml) |
| jump | Движение в подъёме. | [scriptPlayerJumpState](../RandomForest/scripts/scriptPlayerJumpState/scriptPlayerJumpState.gml) |
| fall | Движение вниз, приземление, разрешённый buffered-прыжок. | [scriptPlayerFallState](../RandomForest/scripts/scriptPlayerFallState/scriptPlayerFallState.gml) |
| teleport | Временно скрывает игрока и ждёт кадры эффектов телепорта. | [scriptPlayerTeleportState](../RandomForest/scripts/scriptPlayerTeleportState/scriptPlayerTeleportState.gml) |
| attack | Трёхударная серия и временная маска меча. | [scriptPlayerAttackState](../RandomForest/scripts/scriptPlayerAttackState/scriptPlayerAttackState.gml) |
| hurt | Вычитает отложенный урон, отталкивает, даёт короткую неуязвимость. | [scriptPlayerHurtState](../RandomForest/scripts/scriptPlayerHurtState/scriptPlayerHurtState.gml) |
| die | Проигрывает смерть и перезапускает комнату. | [scriptPlayerDieState](../RandomForest/scripts/scriptPlayerDieState/scriptPlayerDieState.gml) |

Выбор следующего обычного состояния делает [funPlayerDetectState](../RandomForest/scripts/funPlayerDetectState/funPlayerDetectState.gml). Приоритет «критических» событий — урон, затем обычная атака — задаёт [funPlayerDetectCriticalState](../RandomForest/scripts/funPlayerDetectCriticalState/funPlayerDetectCriticalState.gml). Поэтому попадание отменяет начатую атаку.

### Физика, прыжок и односторонние платформы

Параметры игрока задаются в [Create игрока](../RandomForest/objects/oPlayer/Create_0.gml):

- скорость по X: 2;
- импульс прыжка: -6.5;
- гравитация: 0.5;
- лимит падения: 6;
- буфер прыжка и coyote time: по 5 кадров;
- буфер «вниз через платформу»: 3 кадра.

[funPlayerStepMove](../RandomForest/scripts/funPlayerStepMove/funPlayerStepMove.gml) вручную ищет дальнюю допустимую позицию по Y и X, уменьшая проверяемое смещение. Это не встроенная физика GameMaker. Важно не переносить эту логику на врагов автоматически: у них отдельный [funDefaultStepMove](../RandomForest/scripts/funDefaultStepMove/funDefaultStepMove.gml) с другим ограничением скорости падения и прямой проверкой oSolid.

Игрок проверяет мир через [funPlayerCollideWithSolid](../RandomForest/scripts/funPlayerCollideWithSolid/funPlayerCollideWithSolid.gml), который читает флаг is_solid у всех совпавших объектов. У [oSolid](../RandomForest/objects/oSolid/oSolid.yy) этот флаг всегда true в [Create](../RandomForest/objects/oSolid/Create_0.gml); у [oJumpThru](../RandomForest/objects/oJumpThru/oJumpThru.yy) он обновляется в [Step](../RandomForest/objects/oJumpThru/Step_0.gml), чтобы дать пройти снизу или по Down. Разрешение нового прыжка дополнительно проверяется [funPlayerNewJumpAllowed](../RandomForest/scripts/funPlayerNewJumpAllowed/funPlayerNewJumpAllowed.gml).

### Обычная атака X

[scriptPlayerAttackState](../RandomForest/scripts/scriptPlayerAttackState/scriptPlayerAttackState.gml) выбирает одну из трёх анимаций. На кадре image_index >= 1 создаётся невидимый [oPlayerSword](../RandomForest/objects/oPlayerSword/oPlayerSword.yy), следующий за игроком в своём [Step](../RandomForest/objects/oPlayerSword/Step_0.gml). Маска уничтожается уже на image_index >= 3; таким образом именно ранние кадры спрайта наносят урон.

| Удар | Урон | Масштаб маски | Побочный эффект |
| --- | ---: | --- | --- |
| 1 | 2 | 1 × 1 | soundPlayerAttack1 |
| 2 | 2 | 0.9 × 1.7 | soundPlayerAttack2 |
| 3 | 3 | 0.8 × 2.1 | толчок камеры и soundPlayerAttack3 |

Связка «кадр анимации → хитбокс → звук → shake» лежит в [scriptPlayerAttackState](../RandomForest/scripts/scriptPlayerAttackState/scriptPlayerAttackState.gml). При изменении количества кадров, скорости анимации либо коллизионной маски нужно синхронно проверить этот скрипт и [Step bloom игрока](../RandomForest/objects/oPlayerBloom/Step_0.gml).

### Бросок C, пауза времени и телепорт

Центральный контроллер механики — [funPlayerHandleTapSword](../RandomForest/scripts/funPlayerHandleTapSword/funPlayerHandleTapSword.gml), вызываемый после обычной state machine из [Step игрока](../RandomForest/objects/oPlayer/Step_0.gml).

1. Если меч у игрока и бросок разрешён, создаётся [oTapController](../RandomForest/objects/oTapController/oTapController.yy).
2. В [Create контроллера](../RandomForest/objects/oTapController/Create_0.gml) делается снимок application_surface, деактивируются все остальные экземпляры, а текущий контроллер остаётся активным благодаря instance_deactivate_all(true). Объекты-потомки [oAlwaysDraw](../RandomForest/objects/oAlwaysDraw/oAlwaysDraw.yy) снова активируются для подсказок.
3. [Step контроллера](../RandomForest/objects/oTapController/Step_0.gml) ждёт отпускания C или 120 кадров. Стрелки выбирают одно из восьми направлений; диагональ удерживается пять кадров, чтобы случайное отпускание одной стрелки не ломало выбор.
4. Создаётся [oPlayerTapSword](../RandomForest/objects/oPlayerTapSword/oPlayerTapSword.yy), затем всё снова активируется.
5. [Step брошенного меча](../RandomForest/objects/oPlayerTapSword/Step_0.gml) перемещает его со скоростью 6, останавливает об oSolid, допускает несколько кадров пересечения с врагом и уничтожает меч при тайм-ауте, защите бунгало или отзыве.
6. Пока меч снаружи, C запускает [funPlayerTapToEmptyPlace](../RandomForest/scripts/funPlayerTapToEmptyPlace/funPlayerTapToEmptyPlace.gml): он ищет свободную позицию около меча в радиусе 12, создаёт стартовый эффект и меняет состояние на teleport.
7. [scriptPlayerTeleportState](../RandomForest/scripts/scriptPlayerTeleportState/scriptPlayerTeleportState.gml) по жёсткому порогу image_index > 3 создаёт конечный эффект и возвращает сохранённые скорости.

Ограничение «один бросок в воздухе» реализовано не отдельным состоянием: флаг tap_attack_allowed сбрасывается перед броском и снова включается, только когда [Step игрока](../RandomForest/objects/oPlayer/Step_0.gml) увидит землю.

Урон брошенного меча равен 1 в [Create](../RandomForest/objects/oPlayerTapSword/Create_0.gml), а обычные удары наносят 2/2/3. Все варианты меча распознаются врагами как oPlayerSword из-за наследования.

## Мир, сбор ягод и выход

### Ловушки и коллизии

[oTrap](../RandomForest/objects/oTrap/oTrap.yy) невидим и хранит только damage = 1 в [Create](../RandomForest/objects/oTrap/Create_0.gml); видимые шипы — тайловые слои комнат. Игрок получает этот урон через [funPlayerDetectCriticalState](../RandomForest/scripts/funPlayerDetectCriticalState/funPlayerDetectCriticalState.gml).

Враги тоже проверяют ловушки в [funSlimeDetectCriticalState](../RandomForest/scripts/funSlimeDetectCriticalState/funSlimeDetectCriticalState.gml), [funSkeletonDetectCriticalState](../RandomForest/scripts/funSkeletonDetectCriticalState/funSkeletonDetectCriticalState.gml) и [funBungaloDetectCriticalState](../RandomForest/scripts/funBungaloDetectCriticalState/funBungaloDetectCriticalState.gml). Ловушка и меч игрока уважают общий hurt_countdown_counter; пока он активен, моб пытается выйти из опасной области.

### Ягоды и портал

[oCoin](../RandomForest/objects/oCoin/oCoin.yy) при касании видимого игрока отмечается собранной, играет звук и в [Step](../RandomForest/objects/oCoin/Step_0.gml) летит к [oCoinCollector](../RandomForest/objects/oCoinCollector/oCoinCollector.yy). Только после достижения счётчика ягода уничтожается.

[oDoor](../RandomForest/objects/oDoor/oDoor.yy) в [Step](../RandomForest/objects/oDoor/Step_0.gml) открывается, когда в комнате больше нет экземпляров oCoin. До этого она пульсирует масштабом 0.3–0.4; после сбора всех ягод растёт до 1.0. При касании игрока:

- обновляется рекорд через [funUpdateTimeRecord](../RandomForest/scripts/funUpdateTimeRecord/funUpdateTimeRecord.gml);
- следующий абсолютный уровень становится доступен в общем `global.current_level`;
- игрок скрывается, таймер останавливается;
- создаётся [oFadeOut](../RandomForest/objects/oFadeOut/oFadeOut.yy);
- после callback [funShowCompletedLevel](../RandomForest/scripts/scriptBlackRoomFlow/scriptBlackRoomFlow.gml) открывает непосещённую ЧК или создаёт [oLevelPassing](../RandomForest/objects/oLevelPassing/oLevelPassing.yy) на слое UI.

[oLevelPassing](../RandomForest/objects/oLevelPassing/oLevelPassing.yy) деактивирует игровой мир в [Create](../RandomForest/objects/oLevelPassing/Create_0.gml), оставляя [oDebug](../RandomForest/objects/oDebug/oDebug.yy) и [oFullscreen](../RandomForest/objects/oFullscreen/oFullscreen.yy). В [Step](../RandomForest/objects/oLevelPassing/Step_0.gml) доступны «Дальше», «Заново», «В меню»; «Дальше» вызывает общий `funOpenLevel`, а после последнего каталожного уровня открывает `rVictory`. [Draw](../RandomForest/objects/oLevelPassing/Draw_0.gml) и [Draw GUI](../RandomForest/objects/oLevelPassing/Draw_64.gml) рисуют размытый фон, статистику и звёзды.

### Чёрная комната и диалоги

[rBlackRoom](../RandomForest/rooms/rBlackRoom/rBlackRoom.yy) — отдельная редактируемая
комната с невидимой геометрией, обычным игроком и порталом. Здесь нет игрового HUD,
ягод, врагов или светлячков; камера сохраняет обычные границы и эффекты, но не
создаёт `oFireflyManager`. Время и достижения уже зафиксированы на исходном уровне.

`oBlackRoomController` восстанавливает здоровье игрока и после входного затемнения
отсчитывает время свободного движения: 5 секунд перед первой сценой, 3 перед
остальными по умолчанию. `oDialogue` выводит сверху монолог с посимвольной печатью,
стабильными переносами, страницами и оранжевыми фрагментами. Только Enter / Return
допечатывает страницу или переключает её; движение, прыжки и атаки разрешены
во время реплик; топот и превращения временно блокируют действия. Escape остаётся паузой, F — полноэкранным режимом. Диалог наследует
`oAlwaysDraw`, поэтому виден при выборе направления броска.

`oBlackRoomPortal` открывается после последней реплики и обязательного превращения
в сценах 30/40. Награда доступна для пробы до выхода, сохраняется только при выходе. Полностью выросший портал
нужно покинуть и снова коснуться; стояние в нём не вызывает автоматического выхода.
Только завершение выхода отмечает просмотр по ID сцены и показывает сохранённый
`global.last_completion_result`. «Заново» из ЧК или её статистики открывает исходный
уровень. В тестовой комнате нет музыки, после выхода возвращается `musicGame`.

Реестр, задержки и ссылки на монологи находятся в
[narrative/black_room.json](../RandomForest/datafiles/narrative/black_room.json),
тексты — в отдельном Included File на сцену. Базовые способности и диапазон скина
задаёт `narrative/abilities.json`, вступление и будущий уровень 00 — `narrative/levels.json`.
Начальное здоровье 2; ЧК выдаёт HP, двойной прыжок, усиление ближнего комбо, тёмный
скин и топот с улучшением радиуса. Space запускает топот с земли. Формат, таймлайн
наград и условия описаны в [black-room-format.md](black-room-format.md).
Финальная ЧК и конкретные реплики остаются за пределами реализации.

## Враги

### Общий контракт

Каждый полноценный враг должен иметь минимум:

- родителя [oEnemy](../RandomForest/objects/oEnemy/oEnemy.yy);
- state, state_changed, health, damage, current_xspeed, current_yspeed, gravitation;
- явные can_damage_player и is_dead;
- обработку попадания [oPlayerSword](../RandomForest/objects/oPlayerSword/oPlayerSword.yy);
- отдельное состояние смерти, которое выставляет is_dead и отключает can_damage_player;
- слой Bloom в комнате, если создаётся его визуальный двойник.

[funEnemySeePlayer](../RandomForest/scripts/funEnemySeePlayer/funEnemySeePlayer.gml) один раз за Step проверяет направленный радиус, допустимую разницу высоты ног и прямую видимость через обычные solid-блоки. Jump-through не закрывает обзор. Вертикальный предел равен 24 px для слизня и 48 px для скелета. Памяти цели и глобального поиска пути нет: потеряв видимость, моб сразу принимает локальное решение.

[funEnemyMovement](../RandomForest/scripts/funEnemyMovement/funEnemyMovement.gml) содержит общую локальную физику. При преследовании моб сначала подходит до последней позиции, в которой центр collision mask остаётся над платформой, и только затем рассматривает прыжок или спуск; патруль сохраняет более осторожную проверку переднего края. У стены или края симулируются не более двух коротких воздушных траекторий, после чего выбирается безопасная посадка, ближайшая к игроку. При игроке сверху нижняя посадка не считается допустимым прогрессом. Симуляция повторяет реальный порядок движения Y → X, избегает oTrap и остановившийся oPlayerTapSword. Воздушное действие завершается после отрыва и устойчивой посадки, а следующие 30 кадров запрещают новый прыжок, но не обычную ходьбу. Размер комнаты и число далёких платформ на стоимость решения не влияют. Мечи скелета и бунгало хранятся по instance ID владельца; завершение одной атаки не удаляет чужое оружие.

### Слизень

[oSlime](../RandomForest/objects/oSlime/oSlime.yy) имеет 3 HP, скорость 0.5, обзор 120 px вперёд/30 px назад, контактный урон 1 и цикл idle → move → idle. Параметры находятся в [Create](../RandomForest/objects/oSlime/Create_0.gml), диспетчер — в [Step](../RandomForest/objects/oSlime/Step_0.gml).

| Поведение | Реализация |
| --- | --- |
| Видит игрока перед собой | [funSlimeSeePlayer](../RandomForest/scripts/funSlimeSeePlayer/funSlimeSeePlayer.gml) возвращает кешированную за текущий Step проверку радиуса и прямой видимости. |
| Выбирает немедленную реакцию | [funSlimeDetectState](../RandomForest/scripts/funSlimeDetectState/funSlimeDetectState.gml): Hurt, безопасный выход из опасности или доступную атаку. |
| Ожидание | [scriptSlimeIdleState](../RandomForest/scripts/scriptSlimeIdleState/scriptSlimeIdleState.gml), таймер 60 кадров. После таймера проверяет два направления на 12 px и включает move только для безопасного коридора. |
| Патруль | [scriptSlimeMoveState](../RandomForest/scripts/scriptSlimeMoveState/scriptSlimeMoveState.gml): ходьба в заранее выбранную сторону до 180 кадров без выхода на край, в ловушку или стоящий меч. MoveStart не меняет направление. |
| Атака | [scriptSlimeAttackState](../RandomForest/scripts/scriptSlimeAttackState/scriptSlimeAttackState.gml): локально преследует видимого игрока только в его сторону. На ровной поверхности идёт без прыжков; воздушное действие пробует только при блокировке, разнице высот или спуске через jump-through. После приземления выдерживает 30 кадров до следующего прыжка. В воздухе использует округлый кадр движения и плавное draw-only масштабирование. В упоре остаётся рядом и наносит существующий контактный урон. |
| Получение урона | [scriptSlimeHurtState](../RandomForest/scripts/scriptSlimeHurtState/scriptSlimeHurtState.gml): 0.5 с неуязвимости и маленький knockback. |
| Смерть и деление | [scriptSlimeDieState](../RandomForest/scripts/scriptSlimeDieState/scriptSlimeDieState.gml): большой слизень получает случайный масштаб 0.7–1.0, а на image_index >= 2 создаёт двух слизней ровно вдвое меньше, принудительно переводит их в hurt без боевого урона и запрещает повторное деление. |

### Скелет

[oSkeleton](../RandomForest/objects/oSkeleton/oSkeleton.yy) имеет 4 HP, скорость 1, обзор 160 px, радиус атаки 30 и урон 1 телом/2 мечом. Параметры — в [Create](../RandomForest/objects/oSkeleton/Create_0.gml), диспетчер — в [Step](../RandomForest/objects/oSkeleton/Step_0.gml).

| Состояние/проверка | Реализация |
| --- | --- |
| Обнаружение | [funSkeletonSeePlayer](../RandomForest/scripts/funSkeletonSeePlayer/funSkeletonSeePlayer.gml) и [funSkeletonDetectState](../RandomForest/scripts/funSkeletonDetectState/funSkeletonDetectState.gml). |
| Idle | [scriptSkeletonIdleState](../RandomForest/scripts/scriptSkeletonIdleState/scriptSkeletonIdleState.gml): проигрывает idle-анимацию и включает move только после подтверждения безопасного шага или воздушного действия. |
| Реакция | [scriptSkeletonReactState](../RandomForest/scripts/scriptSkeletonReactState/scriptSkeletonReactState.gml): поворачивается к впервые замеченному игроку и используется как стабильное ожидание видимой, но недостижимой цели. После каждого полного цикла атакует, начинает подтверждённое движение, уходит в idle при потере игрока либо повторяет React без промежуточного move-кадра. Получение удара пропускает обязательную задержку перед доступной контратакой. |
| Преследование | [scriptSkeletonMoveState](../RandomForest/scripts/scriptSkeletonMoveState/scriptSkeletonMoveState.gml): безопасно ходит, прыгает, падает с края и спускается через jump-through только в пределах одной достижимой траектории. После приземления возвращается в idle, а следующий прыжок запрещён на 30 кадров. Если безопасного действия нет, переходит в React; кадр move замораживается только во время активного воздушного действия. |
| Удар | [scriptSkeletonAttackState](../RandomForest/scripts/scriptSkeletonAttackState/scriptSkeletonAttackState.gml): создаёт личный [oSkeletonSword](../RandomForest/objects/oSkeletonSword/oSkeletonSword.yy) на кадре >= 7 и удаляет его на кадре >= 10. Повторяет удар без искусственного отхода, если игрок остаётся на допустимой высоте и в радиусе. |
| Hurt/death | [scriptSkeletonHurtState](../RandomForest/scripts/scriptSkeletonHurtState/scriptSkeletonHurtState.gml), [scriptSkeletonDieState](../RandomForest/scripts/scriptSkeletonDieState/scriptSkeletonDieState.gml). Во время Hurt скелет остаётся на месте и после завершения сразу контратакует при реальной досягаемости, иначе возвращается в idle для нового решения. |

### Бунгало

[oBungalo](../RandomForest/objects/oBungalo/oBungalo.yy) имеет 6 HP, скорость 0.7, обзор 160 px, радиус удара 40, урон 1. Его пустой collision-event [Collision_oPlayer](../RandomForest/objects/oBungalo/Collision_oPlayer.gml) ничего не делает: урон полностью идёт через общий parent oEnemy.

| Поведение | Реализация |
| --- | --- |
| Обзор и выбор состояния | [funBungaloSeePlayer](../RandomForest/scripts/funBungaloSeePlayer/funBungaloSeePlayer.gml), [funBungaloWantAttack](../RandomForest/scripts/funBungaloWantAttack/funBungaloWantAttack.gml), [funBungaloDetectState](../RandomForest/scripts/funBungaloDetectState/funBungaloDetectState.gml). |
| Idle и блуждание | [scriptBungaloIdleState](../RandomForest/scripts/scriptBungaloIdleState/scriptBungaloIdleState.gml), [scriptBungaloWalkState](../RandomForest/scripts/scriptBungaloWalkState/scriptBungaloWalkState.gml). |
| Преследование | [scriptBungaloMoveState](../RandomForest/scripts/scriptBungaloMoveState/scriptBungaloMoveState.gml) ходит только по текущей безопасной поверхности. Рывка и искусственного отхода после собственной атаки нет. |
| Обычный удар | [scriptBungaloAttackState](../RandomForest/scripts/scriptBungaloAttackState/scriptBungaloAttackState.gml) создаёт личный [oBungaloSword](../RandomForest/objects/oBungaloSword/oBungaloSword.yy) на attack_frame = 4. [Step меча](../RandomForest/objects/oBungaloSword/Step_0.gml) держит его на владельце. |
| Защита от броска | [funBungaloSeeTapSword](../RandomForest/scripts/funBungaloSeeTapSword/funBungaloSeeTapSword.gml) включает defense_activated только если траектория движущегося меча пересечёт бунгало в ближайшие восемь кадров. Стоящий и удаляющийся меч не провоцирует удар. |
| Hurt/death | [scriptBungaloHurtState](../RandomForest/scripts/scriptBungaloHurtState/scriptBungaloHurtState.gml), [scriptBungaloDieState](../RandomForest/scripts/scriptBungaloDieState/scriptBungaloDieState.gml). Во время Hurt бунгало остаётся на месте и после завершения сразу выбирает новую атаку или преследование. |

## Камера, визуал и звук

### Камера и слои

[oCamera](../RandomForest/objects/oCamera/oCamera.yy) — объект, за которым следует view 0 в игровых комнатах. [Create](../RandomForest/objects/oCamera/Create_0.gml) задаёт игрока как цель; [Step](../RandomForest/objects/oCamera/Step_0.gml) сглаживает движение, резко догоняет при большом отставании, ограничивает позицию границами комнаты и накладывает shake.

[funCameraShake](../RandomForest/scripts/funCameraShake/funCameraShake.gml) не заменяет более сильный/длинный эффект слабым. Его вызывают третий удар игрока, падение брошенного меча и неудачный телепорт.

Имена слоёв — часть API проекта:

- Background нужен [oParallax](../RandomForest/objects/oParallax/oParallax.yy) в [Create](../RandomForest/objects/oParallax/Create_0.gml) и [Draw Begin](../RandomForest/objects/oParallax/Draw_72.gml);
- Bloom нужен игроку, врагам, ягодам, двери и брошенному мечу при instance_create_layer;
- UI нужен паузе и экрану прохождения.

Переименование или удаление любого из этих слоёв ломает динамическое создание объектов. В новых игровых комнатах их надо сохранить.

### Bloom и короткие эффекты

Следующие объекты — визуальные спутники, а не источники геймплея:

- [oPlayerBloom](../RandomForest/objects/oPlayerBloom/oPlayerBloom.yy): [Create](../RandomForest/objects/oPlayerBloom/Create_0.gml), [Step](../RandomForest/objects/oPlayerBloom/Step_0.gml);
- [oSlimeBloom](../RandomForest/objects/oSlimeBloom/oSlimeBloom.yy): [Create](../RandomForest/objects/oSlimeBloom/Create_0.gml), [Step](../RandomForest/objects/oSlimeBloom/Step_0.gml);
- [oSkeletonBloom](../RandomForest/objects/oSkeletonBloom/oSkeletonBloom.yy): [Create](../RandomForest/objects/oSkeletonBloom/Create_0.gml), [Step](../RandomForest/objects/oSkeletonBloom/Step_0.gml);
- [oBungaloBloom](../RandomForest/objects/oBungaloBloom/oBungaloBloom.yy): [Create](../RandomForest/objects/oBungaloBloom/Create_0.gml), [Step](../RandomForest/objects/oBungaloBloom/Step_0.gml);
- [oCoinBloom](../RandomForest/objects/oCoinBloom/oCoinBloom.yy): [Create](../RandomForest/objects/oCoinBloom/Create_0.gml), [Step](../RandomForest/objects/oCoinBloom/Step_0.gml);
- [oPortalBloom](../RandomForest/objects/oPortalBloom/oPortalBloom.yy): [Create](../RandomForest/objects/oPortalBloom/Create_0.gml), [Step](../RandomForest/objects/oPortalBloom/Step_0.gml);
- [oSwordBloom](../RandomForest/objects/oSwordBloom/oSwordBloom.yy): [Create](../RandomForest/objects/oSwordBloom/Create_0.gml), [Step](../RandomForest/objects/oSwordBloom/Step_0.gml).

Их смещения и масштаб часто зависят от image_index конкретного спрайта. Поэтому замена анимации — не только арт-правка: визуальные спутники могут «съехать».

### Фоновые светлячки

[oFireflyManager](../RandomForest/objects/oFireflyManager/oFireflyManager.yy) создаётся камерой на depth 550: огоньки видны поверх фона, но Bloom и все остальные слои перекрывают их. Менеджер хранит целевую популяцию из одиннадцати светлячков в одном массиве структур; отдельные экземпляры, частицы, surfaces и шейдеры не используются.

Оранжевый светлячок (ОС) — специальная запись того же массива: одновременно активен максимум один. Константа `ORANGE_FIREFLY_SPAWN_CHANCE = 0.30` применяется один раз ко всей стартовой пачке и к каждому последующему одиночному спавну; после сохранённого убийства ОС на этом уровне больше не появляется. Основной цвет ОС — `#FF6400`; mystery-иконка и прогресс-бар используют приглушённый оранжевый `#DD9452`. На плитке уровня с собранным ОС за номером и значками вчетверо медленнее блуждает полупрозрачная 2×2-пиксельная версия: координаты движения остаются дробными, отрисовка привязана к игровой сетке, а скорость отражается от внутренней границы.

Светлячки блуждают в мировых координатах по плавным извилистым траекториям. Вышедший за текущий экран огонёк удаляется, а недостающее количество восполняется по одному после случайной задержки. В первом видимом кадре комнаты сразу создаются семь полностью проявленных огоньков. Новый светлячок плавно проявляется, затем светится ровно: мягкое тело диаметром около 8 px окружено заметным тёплым additive-bloom радиусом около 30 px. Размер и интенсивность ореола независимо задаются в Create менеджера. Превышение целевого количества не вызывает принудительного удаления.

Обычный и брошенный мечи могут убить светлячка касанием видимого тела. Тело светлячка исчезает в тот же кадр, а увеличенный ореол следующие десять кадров сжимается и гаснет. Это локальная механика менеджера: светлячок не считается врагом, поэтому текст урона и прочие вражеские эффекты не запускаются. Громкость его звука запечена в WAV с коэффициентом `0.035`, так как общий SFX-toggle устанавливает resource gain в `1`.

Одноразовые эффекты уничтожаются на Animation End: [oAirBurst](../RandomForest/objects/oAirBurst/oAirBurst.yy), [oAirBack](../RandomForest/objects/oAirBack/oAirBack.yy), [oTapDestroy](../RandomForest/objects/oTapDestroy/oTapDestroy.yy), [oTeleportStart](../RandomForest/objects/oTeleportStart/oTeleportStart.yy), [oTeleportEnd](../RandomForest/objects/oTeleportEnd/oTeleportEnd.yy), [oPlayerJumpEffect](../RandomForest/objects/oPlayerJumpEffect/oPlayerJumpEffect.yy), [oPlayerLandingEffect](../RandomForest/objects/oPlayerLandingEffect/oPlayerLandingEffect.yy). Их отрисовка/следование приведены в полном индексе.

### Всплывающий урон

[funShowDamageText](../RandomForest/scripts/funShowDamageText/funShowDamageText.gml) создаёт [oDamageText](../RandomForest/objects/oDamageText/oDamageText.yy) над верхней границей пострадавшего. Реально потерянное здоровье показывается серым для врагов и белым для игрока единым шрифтом 10 px. Число ступенчато поднимается на 12 внутренних пикселей и исчезает за 32 кадра, поэтому остаётся читаемым, но не перекрывает бой.

Эффект создаётся в Start-функциях hurt-состояний сразу после списания здоровья. Он не наследует oAlwaysDraw: пауза и выбор направления броска замораживают его вместе с игровым миром. Уменьшение стартового здоровья маленьких слизней после деления не считается попаданием и не создаёт текст.

### Меню, пауза, обучение и переходы

[oMenu](../RandomForest/objects/oMenu/oMenu.yy) собирает три кнопки в [Create](../RandomForest/objects/oMenu/Create_0.gml): игровой маршрут, справка и выход. До обучения маршрут называется «Начать играть» и открывает первый уровень; после — «Продолжить» и открывает общий выбор уровней. Объект обрабатывает клавиатуру/мышь в [Step](../RandomForest/objects/oMenu/Step_0.gml) и лениво создаёт размытый фон в [Draw](../RandomForest/objects/oMenu/Draw_0.gml). Общая hit-test-функция [funGetButtonByMouse](../RandomForest/scripts/funGetButtonByMouse/funGetButtonByMouse.gml) намеренно использует self.last_mouse_* текущего вызывающего объекта: её нельзя безопасно вызывать из объекта без этого набора полей.

[oLevelSelect](../RandomForest/objects/oLevelSelect/oLevelSelect.yy) объединяет обычные и сгенерированные уровни без визуального разделения. Страницы содержат по 10 кнопок; при каждом входе страница и выделение вычисляются из `global.current_level`, а стрелки позволяют просматривать остальные страницы.

Четвёртый индикатор страницы скрыт за приглушённой оранжевой иконкой-клавишей `?` ([1-bit Pixel Icons, Nikoichu](https://nikoichu.itch.io/pixel-icons)), а у соответствующего доступного уровня лишь слабо тонируется исходный ободок `sBorder4`; звёзды и значки сохраняют свои цвета.

[oPauseMenu](../RandomForest/objects/oPauseMenu/oPauseMenu.yy) похож по структуре, но при паузе делает снимок сцены, деактивирует мир и оставляет активными debug/fullscreen. Реализация: [Create](../RandomForest/objects/oPauseMenu/Create_0.gml), [Step](../RandomForest/objects/oPauseMenu/Step_0.gml), [Draw](../RandomForest/objects/oPauseMenu/Draw_0.gml), [Draw GUI](../RandomForest/objects/oPauseMenu/Draw_64.gml).

[oTraining](../RandomForest/objects/oTraining/oTraining.yy) — переиспользуемая полноэкранная справка. Её стандартный callback в [Create](../RandomForest/objects/oTraining/Create_0.gml) отмечает обучение пройденным и вызывает room_goto_next; меню и пауза переопределяют end_function перед показом. [Destroy](../RandomForest/objects/oTraining/Destroy_0.gml) всегда вызывает этот callback.

Затемнения реализуют [oFadeIn](../RandomForest/objects/oFadeIn/oFadeIn.yy) и [oFadeOut](../RandomForest/objects/oFadeOut/oFadeOut.yy). Их Step изменяет global_alpha, а два события Draw/Draw GUI накрывают и мир, и UI. Эффект размытия создаёт [funBlurSurface](../RandomForest/scripts/funBlurSurface/funBlurSurface.gml), использующий [вершинный шейдер](../RandomForest/shaders/shBlur/shBlur.vsh) и [фрагментный шейдер](../RandomForest/shaders/shBlur/shBlur.fsh): это два прохода гауссова blur по X и Y с опциональным затемнением.

Оба затемнения имеют безопасный `alpha_step = 0.05` по умолчанию; ЧК задаёт
его из своей настройки длительности перехода.

### Звуки

Музыка запускается в [Create меню](../RandomForest/objects/oMenu/Create_0.gml), переключается в [funOpenLevel](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml) и вручную повторяется в [Draw финала](../RandomForest/objects/oVictory/Draw_0.gml). Звуки действий привязаны к кадрам анимации в state-скриптах. Проверки audio_is_playing для шагов слизня и бунгало глобальны для конкретного sound asset, поэтому несколько однотипных врагов не обязаны звучать одновременно.

## Таймер, звёзды и сохранение

[oTimeCounter](../RandomForest/objects/oTimeCounter/oTimeCounter.yy) начинает инкремент в [Step](../RandomForest/objects/oTimeCounter/Step_0.gml) после любого нажатия клавиши, а не мыши. [Draw](../RandomForest/objects/oTimeCounter/Draw_0.gml) рисует значение через [funGetTimeString](../RandomForest/scripts/funGetTimeString/funGetTimeString.gml). Лимиты звёзд лежат в [funGetStarCount](../RandomForest/scripts/funGetStarCount/funGetStarCount.gml); первая цифра — порог трёх звёзд, вторая — двух, всё хуже — одна.

| Комната | 3 звезды | 2 звезды |
| --- | ---: | ---: |
| [rTutorial01](../RandomForest/rooms/rTutorial01/rTutorial01.yy) | 6 с | 9 с |
| [rTutorial02](../RandomForest/rooms/rTutorial02/rTutorial02.yy) | 9 с | 20 с |
| [rTutorial03](../RandomForest/rooms/rTutorial03/rTutorial03.yy) | 8 с | 20 с |
| [rTutorial04](../RandomForest/rooms/rTutorial04/rTutorial04.yy) | 17 с | 25 с |
| [rTutorial05](../RandomForest/rooms/rTutorial05/rTutorial05.yy) | 9 с | 25 с |
| [rTutorial06](../RandomForest/rooms/rTutorial06/rTutorial06.yy) | 7 с | 17 с |
| [rLevel01](../RandomForest/rooms/rLevel01/rLevel01.yy) | 10 с | 25 с |
| [rLevel02](../RandomForest/rooms/rLevel02/rLevel02.yy) | 7 с | 19 с |
| [rLevel03](../RandomForest/rooms/rLevel03/rLevel03.yy) | 7 с | 18 с |
| [rLevel04](../RandomForest/rooms/rLevel04/rLevel04.yy) | 60 с | 120 с |

[funLoadGameState](../RandomForest/scripts/funLoadGameState/funLoadGameState.gml) и [funSaveGameState](../RandomForest/scripts/funSaveGameState/funSaveGameState.gml) читают/пишут save.ini. `current_level` — абсолютный индекс самого дальнего открытого уровня, а `time_records` содержит по одному рекорду на каждый обычный и каталожный уровень. `is_training_completed` фактически отмечает начало кампании и открывает выбор уровней; `hit_vs_tap_text_shown` остался от отключённой подсказки и сейчас не используется. Старые отдельные challenge-ключи не читаются. При расширении каталога прохождение прежнего финального уровня открывает ровно следующий новый уровень и сбрасывает устаревший флаг победы.

`orange_firefly_records` хранит отдельный bool для каждого абсолютного уровня и сохраняется сразу при убийстве ОС, без требования пройти уровень; общий результат вычисляет [funGetOrangeFireflyCount](../RandomForest/scripts/funOrangeFireflyProgress/funOrangeFireflyProgress.gml).

`black_room_seen` хранит просмотренные ЧК по стабильным ID сцен в одноимённой секции
`save.ini`. Просмотр сохраняется при выходе через портал, а не после разговора.
Сброс кампании очищает эти флаги; отдельный сброс рекордов их сохраняет.

Функции обслуживания сохранений находятся в [scriptResetStorage](../RandomForest/scripts/scriptResetStorage/scriptResetStorage.gml): «начать заново» сбрасывает прогресс, но не рекорды и не флаг показанной подсказки; полный сброс и сброс рекордов доступны только debug-командами.

## Окно и debug

[funResizeWindow](../RandomForest/scripts/funResizeWindow/funResizeWindow.gml) берёт камеру [rLevel01](../RandomForest/rooms/rLevel01/rLevel01.yy) как эталон, назначает её всем комнатам, выставляет application_surface в размер 480 × 270 и окно в масштабе 3. [funUpdateFullscreen](../RandomForest/scripts/funUpdateFullscreen/funUpdateFullscreen.gml) применяет сохранённый флаг полноэкранного режима. [oFullscreen](../RandomForest/objects/oFullscreen/oFullscreen.yy) ловит F, сохраняет выбор и несколько кадров просит ОС центрировать окно.

[oDebug](../RandomForest/objects/oDebug/oDebug.yy) включается последовательностью D → E → B → U → G в [Step](../RandomForest/objects/oDebug/Step_0.gml). В режиме debug:

- R — общий сброс;
- T — сброс рекордов;
- N/P — следующая/предыдущая комната;
- Q — добавить все оставшиеся ягоды в счётчик и уничтожить oCoin.

Команды намеренно не защищены от неподходящей комнаты: например, Q в меню может обратиться к отсутствующему oCoinCollector.

Путь до локальных debug-сохранений: ~/Library/Application Support/com.yoyogames.macyoyorunner/save.ini

## Карта рисков и неявных связей

| Приоритет | Наблюдение | Почему важно / как безопаснее менять |
| --- | --- | --- |
| Высокий | [funGetTimeString](../RandomForest/scripts/funGetTimeString/funGetTimeString.gml) интерпретирует кадры как минуты: при 60 FPS значение 60 выводится как 01:00. | Пороги звёзд в [funGetStarCount](../RandomForest/scripts/funGetStarCount/funGetStarCount.gml) явно умножаются на 60, то есть работают в кадрах. Если нужен обычный mm:ss, форматирование нужно исправлять отдельно от порогов. |
| Высокий | Код использует объектные имена игрока, камеры и счетчиков как singletons. | Несколько игроков, камер или счетчиков создадут недетерминированность. Мечи врагов уже используют личные instance ID владельцев, но остальные singleton-контракты сохраняются. |
| Высокий | Первые десять индексов сопоставлены комнатам вручную. | При добавлении обычной комнаты синхронно обновлять [funGetRoomIndex](../RandomForest/scripts/funGetRoomIndex/funGetRoomIndex.gml), [funOpenLevel](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml), обычные пороги в [funGetStarCount](../RandomForest/scripts/funGetStarCount/funGetStarCount.gml) и `CAMPAIGN_LEVELS_COUNT`. Сгенерированные уровни добавляются только через конец каталога. |
| Высокий | Слои Background, Bloom и UI захардкожены строками. | Новая комната без любого из них ломает parallax или instance_create_layer. Копировать [rTemplate](../RandomForest/rooms/rTemplate/rTemplate.yy) безопаснее, чем создавать пустую комнату. |
| Средний | [oCoinCollector](../RandomForest/objects/oCoinCollector/oCoinCollector.yy) вычисляет coins_all в [Create](../RandomForest/objects/oCoinCollector/Create_0.gml), а в порядке создания [rTutorial01](../RandomForest/rooms/rTutorial01/rTutorial01.yy) сам счётчик идёт раньше ягод. | В зависимости от порядка Create-событий HUD может зафиксировать 0. Также его координаты для полёта ягоды обновляются в Draw, а не Step/Create. Для надёжности считать ягоды после создания комнаты или по запросу. |
| Средний | Локальная навигация врагов намеренно не строит маршрут по комнате. | Слизень и скелет проходят только один заранее симулированный прыжок/спуск к видимому игроку. Недостижимая соседняя платформа приводит к безопасному ожиданию и повторной локальной оценке, а не к обходу всей карты. |
| Средний | Тайминги урона, звуков и bloom привязаны к image_index. | Менять спрайты/скорость без прохода по [scriptPlayerAttackState](../RandomForest/scripts/scriptPlayerAttackState/scriptPlayerAttackState.gml), [scriptSkeletonAttackState](../RandomForest/scripts/scriptSkeletonAttackState/scriptSkeletonAttackState.gml), [scriptBungaloAttackState](../RandomForest/scripts/scriptBungaloAttackState/scriptBungaloAttackState.gml) и bloom-Step опасно. |
| Средний | [oMenu](../RandomForest/objects/oMenu/oMenu.yy) создаёт временную поверхность размером cam_w × cam_w, хотя blur далее ожидает cam_w × cam_h. | На не-квадратном базовом экране это выглядит как ошибка размера/лишняя память. Проверить фон и заменить вторую cam_w на cam_h при исправлении. |
| Низкий | Клавиша T одновременно скрывает таймер в [Step таймера](../RandomForest/objects/oTimeCounter/Step_0.gml) и, когда debug включён, сбрасывает рекорды в [Step debug](../RandomForest/objects/oDebug/Step_0.gml). | Переназначить одну из debug-команд, если debug будет использоваться регулярно. |
| Низкий | [oTraining](../RandomForest/objects/oTraining/oTraining.yy) вызывает end_function в [Destroy](../RandomForest/objects/oTraining/Destroy_0.gml) без проверки undefined. | Любое новое создание этого объекта обязано сразу задать callback или оставить штатный из Create. |

## Чек-лист безопасных изменений

### Добавить обычный уровень

1. Скопировать [rTemplate](../RandomForest/rooms/rTemplate/rTemplate.yy) или существующий уровень, сохранив Background, Bloom и UI.
2. Добавить ровно по одному [oPlayer](../RandomForest/objects/oPlayer/oPlayer.yy), [oCamera](../RandomForest/objects/oCamera/oCamera.yy), [oCoinCollector](../RandomForest/objects/oCoinCollector/oCoinCollector.yy), [oTimeCounter](../RandomForest/objects/oTimeCounter/oTimeCounter.yy), [oCurrentLevel](../RandomForest/objects/oCurrentLevel/oCurrentLevel.yy), [oPauseMenu](../RandomForest/objects/oPauseMenu/oPauseMenu.yy), [oDebug](../RandomForest/objects/oDebug/oDebug.yy), [oFullscreen](../RandomForest/objects/oFullscreen/oFullscreen.yy), [oParallax](../RandomForest/objects/oParallax/oParallax.yy), [oDoor](../RandomForest/objects/oDoor/oDoor.yy).
3. Добавить геометрию [oSolid](../RandomForest/objects/oSolid/oSolid.yy), при необходимости [oJumpThru](../RandomForest/objects/oJumpThru/oJumpThru.yy), [oTrap](../RandomForest/objects/oTrap/oTrap.yy), ягоды и врагов.
4. Добавить комнату в RoomOrder [RandomForest.yyp](../RandomForest/RandomForest.yyp) и все места из строки о первых десяти индексах выше.
5. Проверить открытие портала, restart, return-to-menu, fullscreen, паузу и финальный переход.

### Добавить сгенерированный уровень

1. Добавить готовый JSON в `RandomForest/datafiles/challenge_levels` и Included Files проекта.
2. Добавить его относительный путь в конец `challenge_levels/catalog.json`.
3. Не менять `CAMPAIGN_LEVELS_COUNT`: абсолютный номер и страницы выбора расширятся по длине каталога автоматически.
4. Проверить загрузку, звёзды, переход с предыдущего уровня и новый финальный переход.

### Добавить нового врага

1. Унаследовать его от [oEnemy](../RandomForest/objects/oEnemy/oEnemy.yy).
2. Инициализировать все поля физики/жизни/состояния в Create и внедрить Step-диспетчер по образцу [oSkeleton](../RandomForest/objects/oSkeleton/oSkeleton.yy) или [oBungalo](../RandomForest/objects/oBungalo/oBungalo.yy).
3. Добавить явную обработку смерти в [funPlayerDetectCriticalState](../RandomForest/scripts/funPlayerDetectCriticalState/funPlayerDetectCriticalState.gml), пока общий код не переведён на безопасный интерфейс.
4. Проверить попадание обычным и брошенным мечом, ловушкой, тело-в-тело, паузу/прицеливание броска и наличие слоя Bloom.

### Изменить анимацию удара

1. Изменить визуальный ресурс.
2. Пересмотреть номера кадров создания/удаления меча в атакующем state-скрипте.
3. Пересмотреть image_index-математику соответствующего bloom.
4. Пройти все переходы с Animation End, потому что они задают реальные границы состояний.

## Полный индекс исходников

### Объекты и события

#### Загрузка, меню и UI

- [oLoading](../RandomForest/objects/oLoading/oLoading.yy): [Create](../RandomForest/objects/oLoading/Create_0.gml), [Alarm 0](../RandomForest/objects/oLoading/Alarm_0.gml).
- [oMenu](../RandomForest/objects/oMenu/oMenu.yy): [Create](../RandomForest/objects/oMenu/Create_0.gml), [Step](../RandomForest/objects/oMenu/Step_0.gml), [Draw](../RandomForest/objects/oMenu/Draw_0.gml), [Draw GUI](../RandomForest/objects/oMenu/Draw_64.gml).
- [oLevelSelect](../RandomForest/objects/oLevelSelect/oLevelSelect.yy): [Create](../RandomForest/objects/oLevelSelect/Create_0.gml), [Step](../RandomForest/objects/oLevelSelect/Step_0.gml), [Draw](../RandomForest/objects/oLevelSelect/Draw_0.gml), [Draw GUI](../RandomForest/objects/oLevelSelect/Draw_64.gml), [Clean Up](../RandomForest/objects/oLevelSelect/CleanUp_0.gml).
- [oPauseMenu](../RandomForest/objects/oPauseMenu/oPauseMenu.yy): [Create](../RandomForest/objects/oPauseMenu/Create_0.gml), [Step](../RandomForest/objects/oPauseMenu/Step_0.gml), [Draw](../RandomForest/objects/oPauseMenu/Draw_0.gml), [Draw GUI](../RandomForest/objects/oPauseMenu/Draw_64.gml).
- [oTraining](../RandomForest/objects/oTraining/oTraining.yy): [Create](../RandomForest/objects/oTraining/Create_0.gml), [Step](../RandomForest/objects/oTraining/Step_0.gml), [Destroy](../RandomForest/objects/oTraining/Destroy_0.gml), [Draw GUI](../RandomForest/objects/oTraining/Draw_64.gml).
- [oLevelPassing](../RandomForest/objects/oLevelPassing/oLevelPassing.yy): [Create](../RandomForest/objects/oLevelPassing/Create_0.gml), [Step](../RandomForest/objects/oLevelPassing/Step_0.gml), [Draw](../RandomForest/objects/oLevelPassing/Draw_0.gml), [Draw GUI](../RandomForest/objects/oLevelPassing/Draw_64.gml).
- [oVictory](../RandomForest/objects/oVictory/oVictory.yy): [Create](../RandomForest/objects/oVictory/Create_0.gml), [Step](../RandomForest/objects/oVictory/Step_0.gml), [Draw](../RandomForest/objects/oVictory/Draw_0.gml).
- [oFadeIn](../RandomForest/objects/oFadeIn/oFadeIn.yy): [Create](../RandomForest/objects/oFadeIn/Create_0.gml), [Step](../RandomForest/objects/oFadeIn/Step_0.gml), [Draw](../RandomForest/objects/oFadeIn/Draw_0.gml), [Draw GUI](../RandomForest/objects/oFadeIn/Draw_64.gml).
- [oFadeOut](../RandomForest/objects/oFadeOut/oFadeOut.yy): [Create](../RandomForest/objects/oFadeOut/Create_0.gml), [Step](../RandomForest/objects/oFadeOut/Step_0.gml), [Draw](../RandomForest/objects/oFadeOut/Draw_0.gml), [Draw GUI](../RandomForest/objects/oFadeOut/Draw_64.gml).
- [oFullscreen](../RandomForest/objects/oFullscreen/oFullscreen.yy): [Create](../RandomForest/objects/oFullscreen/Create_0.gml), [Step](../RandomForest/objects/oFullscreen/Step_0.gml).
- [oDebug](../RandomForest/objects/oDebug/oDebug.yy): [Create](../RandomForest/objects/oDebug/Create_0.gml), [Step](../RandomForest/objects/oDebug/Step_0.gml).
- [oCurrentLevel](../RandomForest/objects/oCurrentLevel/oCurrentLevel.yy): [Create](../RandomForest/objects/oCurrentLevel/Create_0.gml).
- [oGeneratedLevelController](../RandomForest/objects/oGeneratedLevelController/oGeneratedLevelController.yy): [Create](../RandomForest/objects/oGeneratedLevelController/Create_0.gml).
- [oHealthBar](../RandomForest/objects/oHealthBar/oHealthBar.yy): [Draw](../RandomForest/objects/oHealthBar/Draw_0.gml).
- [oTimeCounter](../RandomForest/objects/oTimeCounter/oTimeCounter.yy): [Create](../RandomForest/objects/oTimeCounter/Create_0.gml), [Step](../RandomForest/objects/oTimeCounter/Step_0.gml), [Draw](../RandomForest/objects/oTimeCounter/Draw_0.gml).
- [oDamageText](../RandomForest/objects/oDamageText/oDamageText.yy): [Create](../RandomForest/objects/oDamageText/Create_0.gml), [Step](../RandomForest/objects/oDamageText/Step_0.gml), [Draw](../RandomForest/objects/oDamageText/Draw_0.gml).
- [oFadingText](../RandomForest/objects/oFadingText/oFadingText.yy): [Create](../RandomForest/objects/oFadingText/Create_0.gml), [Step](../RandomForest/objects/oFadingText/Step_0.gml), [Draw GUI](../RandomForest/objects/oFadingText/Draw_64.gml).
- [oAlwaysDraw](../RandomForest/objects/oAlwaysDraw/oAlwaysDraw.yy) и [oPointer](../RandomForest/objects/oPointer/oPointer.yy): ресурсы без собственного GML.

#### Повествование

- [oBlackRoomController](../RandomForest/objects/oBlackRoomController/oBlackRoomController.yy): [Create](../RandomForest/objects/oBlackRoomController/Create_0.gml), [Step](../RandomForest/objects/oBlackRoomController/Step_0.gml), [Clean Up](../RandomForest/objects/oBlackRoomController/CleanUp_0.gml).
- [oBlackRoomPortal](../RandomForest/objects/oBlackRoomPortal/oBlackRoomPortal.yy): [Create](../RandomForest/objects/oBlackRoomPortal/Create_0.gml), [Step](../RandomForest/objects/oBlackRoomPortal/Step_0.gml).
- [oDialogue](../RandomForest/objects/oDialogue/oDialogue.yy): [Create](../RandomForest/objects/oDialogue/Create_0.gml), [Step](../RandomForest/objects/oDialogue/Step_0.gml), [Draw GUI](../RandomForest/objects/oDialogue/Draw_64.gml).

#### Игрок и его эффекты

- [oPlayer](../RandomForest/objects/oPlayer/oPlayer.yy): [Create](../RandomForest/objects/oPlayer/Create_0.gml), [Step](../RandomForest/objects/oPlayer/Step_0.gml), [Animation End](../RandomForest/objects/oPlayer/Other_7.gml).
- [oPlayerSword](../RandomForest/objects/oPlayerSword/oPlayerSword.yy): [Create](../RandomForest/objects/oPlayerSword/Create_0.gml), [Step](../RandomForest/objects/oPlayerSword/Step_0.gml).
- [oPlayerTapSword](../RandomForest/objects/oPlayerTapSword/oPlayerTapSword.yy): [Create](../RandomForest/objects/oPlayerTapSword/Create_0.gml), [Step](../RandomForest/objects/oPlayerTapSword/Step_0.gml).
- [oTapController](../RandomForest/objects/oTapController/oTapController.yy): [Create](../RandomForest/objects/oTapController/Create_0.gml), [Step](../RandomForest/objects/oTapController/Step_0.gml), [Draw](../RandomForest/objects/oTapController/Draw_0.gml).
- [oPlayerBloom](../RandomForest/objects/oPlayerBloom/oPlayerBloom.yy): [Create](../RandomForest/objects/oPlayerBloom/Create_0.gml), [Step](../RandomForest/objects/oPlayerBloom/Step_0.gml).
- [oFireflyManager](../RandomForest/objects/oFireflyManager/oFireflyManager.yy): [Create](../RandomForest/objects/oFireflyManager/Create_0.gml), [Step](../RandomForest/objects/oFireflyManager/Step_0.gml), [Draw](../RandomForest/objects/oFireflyManager/Draw_0.gml).
- [oSwordBloom](../RandomForest/objects/oSwordBloom/oSwordBloom.yy): [Create](../RandomForest/objects/oSwordBloom/Create_0.gml), [Step](../RandomForest/objects/oSwordBloom/Step_0.gml).
- [oPlayerJumpEffect](../RandomForest/objects/oPlayerJumpEffect/oPlayerJumpEffect.yy): [Draw](../RandomForest/objects/oPlayerJumpEffect/Draw_0.gml), [Animation End](../RandomForest/objects/oPlayerJumpEffect/Other_7.gml).
- [oPlayerLandingEffect](../RandomForest/objects/oPlayerLandingEffect/oPlayerLandingEffect.yy): [Draw](../RandomForest/objects/oPlayerLandingEffect/Draw_0.gml), [Animation End](../RandomForest/objects/oPlayerLandingEffect/Other_7.gml).
- [oAirBack](../RandomForest/objects/oAirBack/oAirBack.yy): [Create](../RandomForest/objects/oAirBack/Create_0.gml), [Step](../RandomForest/objects/oAirBack/Step_0.gml), [Animation End](../RandomForest/objects/oAirBack/Other_7.gml).
- [oAirBurst](../RandomForest/objects/oAirBurst/oAirBurst.yy): [Animation End](../RandomForest/objects/oAirBurst/Other_7.gml).
- [oTapDestroy](../RandomForest/objects/oTapDestroy/oTapDestroy.yy): [Animation End](../RandomForest/objects/oTapDestroy/Other_7.gml).
- [oTeleportStart](../RandomForest/objects/oTeleportStart/oTeleportStart.yy): [Animation End](../RandomForest/objects/oTeleportStart/Other_7.gml).
- [oTeleportEnd](../RandomForest/objects/oTeleportEnd/oTeleportEnd.yy): [Animation End](../RandomForest/objects/oTeleportEnd/Other_7.gml).

#### Мир и камера

- [oCamera](../RandomForest/objects/oCamera/oCamera.yy): [Create](../RandomForest/objects/oCamera/Create_0.gml), [Step](../RandomForest/objects/oCamera/Step_0.gml).
- [oParallax](../RandomForest/objects/oParallax/oParallax.yy): [Create](../RandomForest/objects/oParallax/Create_0.gml), [Draw Begin](../RandomForest/objects/oParallax/Draw_72.gml).
- [oSolid](../RandomForest/objects/oSolid/oSolid.yy): [Create](../RandomForest/objects/oSolid/Create_0.gml).
- [oJumpThru](../RandomForest/objects/oJumpThru/oJumpThru.yy): [Create](../RandomForest/objects/oJumpThru/Create_0.gml), [Step](../RandomForest/objects/oJumpThru/Step_0.gml).
- [oTrap](../RandomForest/objects/oTrap/oTrap.yy): [Create](../RandomForest/objects/oTrap/Create_0.gml).
- [oCoin](../RandomForest/objects/oCoin/oCoin.yy): [Create](../RandomForest/objects/oCoin/Create_0.gml), [Step](../RandomForest/objects/oCoin/Step_0.gml).
- [oCoinCollector](../RandomForest/objects/oCoinCollector/oCoinCollector.yy): [Create](../RandomForest/objects/oCoinCollector/Create_0.gml), [Draw](../RandomForest/objects/oCoinCollector/Draw_0.gml).
- [oCoinBloom](../RandomForest/objects/oCoinBloom/oCoinBloom.yy): [Create](../RandomForest/objects/oCoinBloom/Create_0.gml), [Step](../RandomForest/objects/oCoinBloom/Step_0.gml).
- [oDoor](../RandomForest/objects/oDoor/oDoor.yy): [Create](../RandomForest/objects/oDoor/Create_0.gml), [Step](../RandomForest/objects/oDoor/Step_0.gml).
- [oPortalBloom](../RandomForest/objects/oPortalBloom/oPortalBloom.yy): [Create](../RandomForest/objects/oPortalBloom/Create_0.gml), [Step](../RandomForest/objects/oPortalBloom/Step_0.gml).

#### Враги

- [oEnemy](../RandomForest/objects/oEnemy/oEnemy.yy): родитель без собственного GML.
- [oSlime](../RandomForest/objects/oSlime/oSlime.yy): [Create](../RandomForest/objects/oSlime/Create_0.gml), [Step](../RandomForest/objects/oSlime/Step_0.gml), [Draw](../RandomForest/objects/oSlime/Draw_0.gml), [Animation End](../RandomForest/objects/oSlime/Other_7.gml).
- [oSlimeBloom](../RandomForest/objects/oSlimeBloom/oSlimeBloom.yy): [Create](../RandomForest/objects/oSlimeBloom/Create_0.gml), [Step](../RandomForest/objects/oSlimeBloom/Step_0.gml).
- [oSkeleton](../RandomForest/objects/oSkeleton/oSkeleton.yy): [Create](../RandomForest/objects/oSkeleton/Create_0.gml), [Step](../RandomForest/objects/oSkeleton/Step_0.gml), [Animation End](../RandomForest/objects/oSkeleton/Other_7.gml).
- [oSkeletonSword](../RandomForest/objects/oSkeletonSword/oSkeletonSword.yy): [Create](../RandomForest/objects/oSkeletonSword/Create_0.gml), [Step](../RandomForest/objects/oSkeletonSword/Step_0.gml).
- [oSkeletonBloom](../RandomForest/objects/oSkeletonBloom/oSkeletonBloom.yy): [Create](../RandomForest/objects/oSkeletonBloom/Create_0.gml), [Step](../RandomForest/objects/oSkeletonBloom/Step_0.gml).
- [oBungalo](../RandomForest/objects/oBungalo/oBungalo.yy): [Create](../RandomForest/objects/oBungalo/Create_0.gml), [Step](../RandomForest/objects/oBungalo/Step_0.gml), [Animation End](../RandomForest/objects/oBungalo/Other_7.gml), [пустой Collision с игроком](../RandomForest/objects/oBungalo/Collision_oPlayer.gml).
- [oBungaloSword](../RandomForest/objects/oBungaloSword/oBungaloSword.yy): [Create](../RandomForest/objects/oBungaloSword/Create_0.gml), [Step](../RandomForest/objects/oBungaloSword/Step_0.gml).
- [oBungaloBloom](../RandomForest/objects/oBungaloBloom/oBungaloBloom.yy): [Create](../RandomForest/objects/oBungaloBloom/Create_0.gml), [Step](../RandomForest/objects/oBungaloBloom/Step_0.gml).

#### Внутриуровневые подсказки

- [oHelpTutorial01](../RandomForest/objects/oHelpTutorial01/oHelpTutorial01.yy): [Create](../RandomForest/objects/oHelpTutorial01/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial01/Draw_64.gml).
- [oHelpTutorial02](../RandomForest/objects/oHelpTutorial02/oHelpTutorial02.yy): [Create](../RandomForest/objects/oHelpTutorial02/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial02/Draw_64.gml).
- [oHelpTutorial03](../RandomForest/objects/oHelpTutorial03/oHelpTutorial03.yy): [Create](../RandomForest/objects/oHelpTutorial03/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial03/Draw_64.gml).
- [oHelpTutorial04](../RandomForest/objects/oHelpTutorial04/oHelpTutorial04.yy): [Create](../RandomForest/objects/oHelpTutorial04/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial04/Draw_64.gml).
- [oHelpTutorial05](../RandomForest/objects/oHelpTutorial05/oHelpTutorial05.yy): [Create](../RandomForest/objects/oHelpTutorial05/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial05/Draw_64.gml).
- [oHelpTutorial06](../RandomForest/objects/oHelpTutorial06/oHelpTutorial06.yy): [Create](../RandomForest/objects/oHelpTutorial06/Create_0.gml), [Draw GUI](../RandomForest/objects/oHelpTutorial06/Draw_64.gml).

### Скрипты

#### Игрок

- [funReadInputs](../RandomForest/scripts/funReadInputs/funReadInputs.gml), [funPlayerDetectState](../RandomForest/scripts/funPlayerDetectState/funPlayerDetectState.gml), [funPlayerDetectCriticalState](../RandomForest/scripts/funPlayerDetectCriticalState/funPlayerDetectCriticalState.gml), [funPlayerChangeState](../RandomForest/scripts/funPlayerChangeState/funPlayerChangeState.gml).
- [funPlayerStepMove](../RandomForest/scripts/funPlayerStepMove/funPlayerStepMove.gml), [funPlayerCollideWithSolid](../RandomForest/scripts/funPlayerCollideWithSolid/funPlayerCollideWithSolid.gml), [funPlayerNewJumpAllowed](../RandomForest/scripts/funPlayerNewJumpAllowed/funPlayerNewJumpAllowed.gml).
- [funPlayerHandleTapSword](../RandomForest/scripts/funPlayerHandleTapSword/funPlayerHandleTapSword.gml), [funPlayerTapToEmptyPlace](../RandomForest/scripts/funPlayerTapToEmptyPlace/funPlayerTapToEmptyPlace.gml), [funPlayerTapSwordDestroy](../RandomForest/scripts/funPlayerTapSwordDestroy/funPlayerTapSwordDestroy.gml).
- [scriptPlayerIdleState](../RandomForest/scripts/scriptPlayerIdleState/scriptPlayerIdleState.gml), [scriptPlayerMoveState](../RandomForest/scripts/scriptPlayerMoveState/scriptPlayerMoveState.gml), [scriptPlayerPreJumpState](../RandomForest/scripts/scriptPlayerPreJumpState/scriptPlayerPreJumpState.gml), [scriptPlayerJumpState](../RandomForest/scripts/scriptPlayerJumpState/scriptPlayerJumpState.gml), [scriptPlayerFallState](../RandomForest/scripts/scriptPlayerFallState/scriptPlayerFallState.gml), [scriptPlayerTeleportState](../RandomForest/scripts/scriptPlayerTeleportState/scriptPlayerTeleportState.gml), [scriptPlayerAttackState](../RandomForest/scripts/scriptPlayerAttackState/scriptPlayerAttackState.gml), [scriptPlayerHurtState](../RandomForest/scripts/scriptPlayerHurtState/scriptPlayerHurtState.gml), [scriptPlayerDieState](../RandomForest/scripts/scriptPlayerDieState/scriptPlayerDieState.gml).

#### Общая физика и враги

- [funDefaultChangeState](../RandomForest/scripts/funDefaultChangeState/funDefaultChangeState.gml), [funDefaultStepMove](../RandomForest/scripts/funDefaultStepMove/funDefaultStepMove.gml), [funDefaultFullyOnGround](../RandomForest/scripts/funDefaultFullyOnGround/funDefaultFullyOnGround.gml), [funDefaultIsInView0](../RandomForest/scripts/funDefaultIsInView0/funDefaultIsInView0.gml), [funEnemyMovement](../RandomForest/scripts/funEnemyMovement/funEnemyMovement.gml), [funEnemySeePlayer](../RandomForest/scripts/funEnemySeePlayer/funEnemySeePlayer.gml).
- [funSlimeSeePlayer](../RandomForest/scripts/funSlimeSeePlayer/funSlimeSeePlayer.gml), [funSlimeDetectState](../RandomForest/scripts/funSlimeDetectState/funSlimeDetectState.gml), [funSlimeDetectCriticalState](../RandomForest/scripts/funSlimeDetectCriticalState/funSlimeDetectCriticalState.gml).
- [scriptSlimeIdleState](../RandomForest/scripts/scriptSlimeIdleState/scriptSlimeIdleState.gml), [scriptSlimeMoveState](../RandomForest/scripts/scriptSlimeMoveState/scriptSlimeMoveState.gml), [scriptSlimeAttackState](../RandomForest/scripts/scriptSlimeAttackState/scriptSlimeAttackState.gml), [scriptSlimeHurtState](../RandomForest/scripts/scriptSlimeHurtState/scriptSlimeHurtState.gml), [scriptSlimeDieState](../RandomForest/scripts/scriptSlimeDieState/scriptSlimeDieState.gml).
- [funSkeletonSeePlayer](../RandomForest/scripts/funSkeletonSeePlayer/funSkeletonSeePlayer.gml), [funSkeletonWantAttack](../RandomForest/scripts/funSkeletonWantAttack/funSkeletonWantAttack.gml), [funSkeletonDetectState](../RandomForest/scripts/funSkeletonDetectState/funSkeletonDetectState.gml), [funSkeletonDetectCriticalState](../RandomForest/scripts/funSkeletonDetectCriticalState/funSkeletonDetectCriticalState.gml).
- [scriptSkeletonIdleState](../RandomForest/scripts/scriptSkeletonIdleState/scriptSkeletonIdleState.gml), [scriptSkeletonReactState](../RandomForest/scripts/scriptSkeletonReactState/scriptSkeletonReactState.gml), [scriptSkeletonMoveState](../RandomForest/scripts/scriptSkeletonMoveState/scriptSkeletonMoveState.gml), [scriptSkeletonAttackState](../RandomForest/scripts/scriptSkeletonAttackState/scriptSkeletonAttackState.gml), [scriptSkeletonHurtState](../RandomForest/scripts/scriptSkeletonHurtState/scriptSkeletonHurtState.gml), [scriptSkeletonDieState](../RandomForest/scripts/scriptSkeletonDieState/scriptSkeletonDieState.gml).
- [funBungaloSeePlayer](../RandomForest/scripts/funBungaloSeePlayer/funBungaloSeePlayer.gml), [funBungaloSeeTapSword](../RandomForest/scripts/funBungaloSeeTapSword/funBungaloSeeTapSword.gml), [funBungaloWantAttack](../RandomForest/scripts/funBungaloWantAttack/funBungaloWantAttack.gml), [funBungaloDetectState](../RandomForest/scripts/funBungaloDetectState/funBungaloDetectState.gml), [funBungaloDetectCriticalState](../RandomForest/scripts/funBungaloDetectCriticalState/funBungaloDetectCriticalState.gml).
- [scriptBungaloIdleState](../RandomForest/scripts/scriptBungaloIdleState/scriptBungaloIdleState.gml), [scriptBungaloWalkState](../RandomForest/scripts/scriptBungaloWalkState/scriptBungaloWalkState.gml), [scriptBungaloMoveState](../RandomForest/scripts/scriptBungaloMoveState/scriptBungaloMoveState.gml), [scriptBungaloAttackState](../RandomForest/scripts/scriptBungaloAttackState/scriptBungaloAttackState.gml), [scriptBungaloHurtState](../RandomForest/scripts/scriptBungaloHurtState/scriptBungaloHurtState.gml), [scriptBungaloDieState](../RandomForest/scripts/scriptBungaloDieState/scriptBungaloDieState.gml).

#### Прогресс, UI и системные функции

- [scriptMenuFunctions](../RandomForest/scripts/scriptMenuFunctions/scriptMenuFunctions.gml), [funGetButtonByMouse](../RandomForest/scripts/funGetButtonByMouse/funGetButtonByMouse.gml), [funBlurSurface](../RandomForest/scripts/funBlurSurface/funBlurSurface.gml), [funCameraShake](../RandomForest/scripts/funCameraShake/funCameraShake.gml).
- [funFireflyChooseTarget](../RandomForest/scripts/funFireflyChooseTarget/funFireflyChooseTarget.gml), [funFireflyCreate](../RandomForest/scripts/funFireflyCreate/funFireflyCreate.gml), [funFireflyUpdate](../RandomForest/scripts/funFireflyUpdate/funFireflyUpdate.gml), [funOrangeFireflyProgress](../RandomForest/scripts/funOrangeFireflyProgress/funOrangeFireflyProgress.gml).
- [funShowDamageText](../RandomForest/scripts/funShowDamageText/funShowDamageText.gml).
- [funGetLevelsCount](../RandomForest/scripts/funGetLevelsCount/funGetLevelsCount.gml), [funGetRoomIndex](../RandomForest/scripts/funGetRoomIndex/funGetRoomIndex.gml), [funGetTimeString](../RandomForest/scripts/funGetTimeString/funGetTimeString.gml), [funGetStarCount](../RandomForest/scripts/funGetStarCount/funGetStarCount.gml), [funDrawStar](../RandomForest/scripts/funDrawStar/funDrawStar.gml), [funUpdateTimeRecord](../RandomForest/scripts/funUpdateTimeRecord/funUpdateTimeRecord.gml).
- [funLoadChallengeCatalog](../RandomForest/scripts/funLoadChallengeCatalog/funLoadChallengeCatalog.gml), [funOpenGeneratedLevel](../RandomForest/scripts/funOpenGeneratedLevel/funOpenGeneratedLevel.gml), [funGenerateLevel](../RandomForest/scripts/funGenerateLevel/funGenerateLevel.gml), [funValidateGeneratedLevel](../RandomForest/scripts/funValidateGeneratedLevel/funValidateGeneratedLevel.gml), [funStyleGeneratedLevel](../RandomForest/scripts/funStyleGeneratedLevel/funStyleGeneratedLevel.gml), [funBuildGeneratedLevel](../RandomForest/scripts/funBuildGeneratedLevel/funBuildGeneratedLevel.gml), [funDecodeGeneratedLevelMap](../RandomForest/scripts/funDecodeGeneratedLevelMap/funDecodeGeneratedLevelMap.gml).
- [funLoadGameState](../RandomForest/scripts/funLoadGameState/funLoadGameState.gml), [funSaveGameState](../RandomForest/scripts/funSaveGameState/funSaveGameState.gml), [scriptResetStorage](../RandomForest/scripts/scriptResetStorage/scriptResetStorage.gml).
- [funResizeWindow](../RandomForest/scripts/funResizeWindow/funResizeWindow.gml), [funUpdateFullscreen](../RandomForest/scripts/funUpdateFullscreen/funUpdateFullscreen.gml).

#### Скрипты повествования

- [scriptBlackRoomConfig](../RandomForest/scripts/scriptBlackRoomConfig/scriptBlackRoomConfig.gml), [scriptBlackRoomDialogue](../RandomForest/scripts/scriptBlackRoomDialogue/scriptBlackRoomDialogue.gml), [scriptBlackRoomFlow](../RandomForest/scripts/scriptBlackRoomFlow/scriptBlackRoomFlow.gml).
- [scriptDialogueText](../RandomForest/scripts/scriptDialogueText/scriptDialogueText.gml), [scriptDialogueLayout](../RandomForest/scripts/scriptDialogueLayout/scriptDialogueLayout.gml), [scriptDialoguePlayback](../RandomForest/scripts/scriptDialoguePlayback/scriptDialoguePlayback.gml).
- [scriptPortalVisual](../RandomForest/scripts/scriptPortalVisual/scriptPortalVisual.gml) — общая анимация обычного портала и портала ЧК.

### Шейдер и код комнаты

- [shBlur.vsh](../RandomForest/shaders/shBlur/shBlur.vsh), [shBlur.fsh](../RandomForest/shaders/shBlur/shBlur.fsh), [метаданные shBlur](../RandomForest/shaders/shBlur/shBlur.yy).
- [RoomCreationCode rVictory](../RandomForest/rooms/rVictory/RoomCreationCode.gml).
