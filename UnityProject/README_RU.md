# SHOHIN SURVIVAL — Unity 6 + URP

Отдельная Unity-ветка проекта. Текущая веб-версия в `main` не изменяется.

## Что уже заложено
- Unity 6 project skeleton и зависимости URP 17, Input System и Cinemachine.
- Генератор двух крупных островов с разными seed, высотой и размером.
- Базовый third-person controller с точками подключения экранного управления.
- Игровые часы: 40 реальных минут = 1 игровые сутки, счётчик дней и сезоны.
- Основы голода, жажды, здоровья и выносливости.
- Editor setup-команда для создания тестовой сцены, двух островов, океанской основы, тестового персонажа и cinematic post-processing volume.

## Как создать сцену
1. Открой папку `UnityProject` в Unity Hub с Unity 6.0 LTS.
2. Дождись установки пакетов из Packages/manifest.json.
3. В Unity выбери меню **SHOHIN → Create Cinematic Survival Prototype**.
4. Открой `Assets/Scenes/SHOHIN_Survival_Prototype.unity` и нажми Play.

## Важно
Это начальный Unity-прототип, не готовая игра и не APK. Сцена использует капсулу вместо финального humanoid-персонажа и процедурный базовый рельеф. Следующие художественные этапы: настоящая модель человека и анимации, плотная растительность, качественный океан, затонувший корабль, погода, звуковая среда и мобильный HUD/джойстик.

URP package включён в manifest. После первого открытия проверь Project Settings → Graphics и Quality: активный Render Pipeline должен быть Universal Render Pipeline Asset. При необходимости создай URP Asset через Create → Rendering → URP Asset (with Universal Renderer) и назначь его в Graphics и Quality.

На телефоне пользователя Unity Editor не запускается как обычное Android-приложение. Репозиторий хранит исходники; сборка APK требует Unity Editor на ПК или настроенного Unity Build Automation/CI с лицензированным Unity Editor.
