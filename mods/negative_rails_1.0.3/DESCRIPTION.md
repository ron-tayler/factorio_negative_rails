# Negative Rails

## Русское описание

**Negative Rails** позволяет указать, какие рельсы нужно удалить при перестройке железной дороги. Удобно для замены перекрёстков и развязок: нужные старые пути сохраняются, лишние разбираются, новые строятся по чертежу.

Возьми отрицательные рельсы через кнопку на панели инструментов или **Ctrl+Shift+R** и прокладывай их обычным планировщиком рельсов. На свободном месте они остаются призраками, которые можно скопировать в чертёж. При наложении на совпадающие существующие сегменты через **Ctrl+Shift+ЛКМ** эти сегменты помечаются на демонтаж. Одна прокладываемая линия может одновременно отмечать старые пути на снос и оставлять новые отрицательные призраки, включая дуги.

Чтобы подготовить замену перекрёстка, собери в одном чертеже новые обычные пути и отрицательные рельсы, обозначающие удаляемые части старой схемы. Совмести чертёж со старым перекрёстком и размести его через **Ctrl+Shift+ЛКМ**. Можно использовать инструмент и для точечного демонтажа без чертежа.

По отрицательным рельсам не ездят поезда, а роботы не пытаются их построить и не сообщают о нехватке ресурсов для них.

**Поддерживаются только наземные рельсы. Надземные рельсы, рельсовые пандусы и опоры не поддерживаются.**

Отдельная благодарность автору [Negative Space](https://mods.factorio.com/mod/negative_space) — этот мод вдохновил идею отрицательных рельсов и их использования в чертежах.

**Хорошо сочетается с Negative Space:** Negative Rails отвечает за рельсы, а Negative Space можно использовать для светофоров и других объектов. Он указан как необязательная зависимость — Negative Rails работает и без него.

## English description

**Negative Rails** lets you specify which rail segments to remove when rebuilding a railway. It is useful for replacing junctions: keep the existing tracks you need, dismantle unwanted segments, and build the new layout from a blueprint.

Take negative rails from the shortcut bar or press **Ctrl+Shift+R**, then lay them out with the standard rail planner. On empty ground, they remain as ghosts that you can include in a blueprint. Super force placing them over matching existing segments with **Ctrl+Shift+left click** marks those segments for deconstruction. A single planned path can both mark old tracks for removal and leave new negative rail ghosts, including curves.

To prepare a junction replacement, combine the new normal tracks and the negative rails marking unwanted parts of the old layout in one blueprint. Align it with the existing junction and place it using **Ctrl+Shift+left click**. You can also use the tool for precise rail removal without a blueprint.

Trains cannot travel on negative rails. Construction robots do not try to build them, and they do not generate missing-material alerts.

**Only ground rails are supported. Elevated rails, rail ramps and rail supports are not supported.**

Special thanks to the author of [Negative Space](https://mods.factorio.com/mod/negative_space), which inspired the idea of negative rails and their use in blueprints.

**Pairs well with Negative Space:** Negative Rails handles rail segments, while Negative Space can be used for rail signals and other entities. It is listed as an optional dependency; Negative Rails also works on its own.
