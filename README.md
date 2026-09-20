# Пиши (Pishi)

Быстрый, минималистичный и надёжный текстовый редактор заметок для iPhone и iPad. Полностью локальное приложение: без сервера, интернета, API-ключей и сторонних библиотек.

## 1. О приложении

«Пиши» — нативное iOS-приложение для заметок. Главные приоритеты: скорость, надёжность сохранения, удобство набора текста, минималистичный интерфейс и отсутствие визуального шума.

## 2. Возможности

- Создание, редактирование и удаление заметок
- Поиск по заголовку и содержимому (без учёта регистра)
- Закрепление заметок (закреплённые всегда сверху)
- Архив: архивирование и восстановление
- Дублирование заметок
- Экспорт в TXT и Markdown (системный Share Sheet)
- Импорт TXT/Markdown через fileImporter (UTF-8)
- Список и сетка отображения
- Сортировка: по изменению, по созданию, по названию, закреплённые, новые, старые
- Фильтры: все, закреплённые, архив, недавно изменённые
- Автосохранение с debounce и статусом «Сохранено / Сохранение…»
- Поиск внутри открытой заметки с подсветкой и навигацией по совпадениям
- Undo/Redo в редакторе (UITextView)
- Статистика: слова, символы, строки, время изменения
- Отмена удаления (undo-баннер) + подтверждение удаления (настраивается)
- Светлая/тёмная/системная тема, Dynamic Type, VoiceOver
- Настройки: шрифт, размер, интервал автосохранения, перенос строк и др.

## 3. Системные требования

- macOS с Xcode 16.x (рекомендуется Xcode 16.2+)
- iOS 17.0+ (iPhone и iPad)
- Swift 6

## 4. Версия Xcode

Проект собирается Xcode 16.x. В GitHub Actions используется `macos-15` с Xcode 16.2 (`Xcode_16.2.app`). Если эта версия недоступна на раннере, workflow автоматически берёт последнюю доступную 16.x через `xcodes` / `xcode-select`.

## 5. Минимальная версия iOS

iOS 17.0. Все API совместимы с iOS 17; более новые API не используются.

## 6. Технологии

- Swift 6, SwiftUI, SwiftData
- MVVM
- UITextView через UIViewRepresentable (полноценный редактор: undo/redo, выделение, copy/paste)
- XCTest (unit), XCUITest (UI)
- GitHub Actions (macOS runner, Simulator build без подписи)

## 7. Архитектура

MVVM:

- **Models** — `Note` (SwiftData `@Model`), `SortOption`, `NoteFilter`, `DisplayMode`
- **Views** — `NotesListView`, `NoteRowView`, `NoteGridItemView`, `NoteEditorView`, `SettingsView`, `ArchiveView`, `EmptyStateView` + компоненты (`SearchBar`, `SaveStatusView`, `NoteStatisticsView`, `SortMenuView`, `TextViewRepresentable`)
- **ViewModels** — `NotesListViewModel` (список, поиск, фильтры, удаление с undo), `NoteEditorViewModel` (debounce-автосохранение, поиск в заметке, экспорт)
- **Services** — `PersistenceController` (SwiftData CRUD), `ExportService`, `ImportService`, `SettingsStore`
- **Utilities** — `String+Statistics`, `AppTheme`, `Constants`

Зависимости передаются через инициализаторы (dependency injection): ViewModel получают `PersistenceController`, тесты используют in-memory контейнер.

Автосохранение: текст не пишется в SwiftData после каждого символа — используется debounce (0,5–2 с, настраивается). Принудительное сохранение при закрытии редактора, переходе между экранами и уходе приложения в background. Пустые новые заметки не оставляются в базе.

## 8. Структура проекта

```
Pishi/
├── Pishi.xcodeproj
├── Pishi/
│   ├── App/PishiApp.swift
│   ├── Models/ (Note, SortOption, NoteFilter, DisplayMode)
│   ├── Views/ (NotesListView, NoteRowView, NoteGridItemView, NoteEditorView,
│   │           SettingsView, ArchiveView, EmptyStateView, Components/)
│   ├── ViewModels/ (NotesListViewModel, NoteEditorViewModel)
│   ├── Services/ (PersistenceController, ExportService, ImportService, SettingsStore)
│   ├── Utilities/ (String+Statistics, AppTheme, Constants)
│   └── Resources/Localizable.xcstrings
├── PishiTests/ (NoteTests, NotesListViewModelTests, NoteEditorViewModelTests, PersistenceControllerTests)
├── PishiUITests/ (PishiUITests, PishiLaunchTests)
├── .github/workflows/ (ios.yml, release.yml)
├── scripts/run_tests.sh
├── .gitignore
└── README.md
```

## 9. Как открыть в Xcode

1. Распакуйте/склонируйте репозиторий.
2. Откройте `Pishi.xcodeproj` в Xcode 16.x.
3. Проект использует file-system-synchronized groups (Xcode 16): все файлы в папках `Pishi/`, `PishiTests/`, `PishiUITests/` подхватываются автоматически.

## 10. Как запустить

1. Выберите scheme **Pishi** и любой iPhone/iPad Simulator (iOS 17+).
2. Нажмите Run (⌘R). Подпись не требуется для Simulator.

## 11. Как запускать тесты

В Xcode: ⌘U (все тесты) или Product → Test.

Через xcodebuild:

```bash
xcodebuild test \
  -project Pishi.xcodeproj \
  -scheme Pishi \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

## 12. Как запускать run_tests.sh

```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

Скрипт сам найдёт доступный Simulator, соберёт приложение и запустит unit + UI тесты. Не требует Homebrew, CocoaPods и Apple Developer Account.

## 13. Как создать GitHub repository

1. github.com → New repository → имя `Pishi` → без README (он уже есть).
2. Локально:

```bash
git init
git add .
git commit -m "Initial iOS app"
git branch -M main
git remote add origin URL_РЕПОЗИТОРИЯ
git push -u origin main
```

## 14. Как работает GitHub Actions

`.github/workflows/ios.yml` запускается при push в `main`/`develop`, при PR в `main` и вручную (`workflow_dispatch`). Шаги: checkout → вывод версий macOS/Xcode/Swift → список Simulator → build → unit tests → UI tests → сохранение `.xcresult` как artifact. Сборка идёт на Simulator без подписи (`CODE_SIGNING_ALLOWED=NO`).

## 15. Как посмотреть artifacts

Вкладка **Actions** → нужный run → раздел **Artifacts** внизу страницы → скачать `xcresult`.

## 16. Как настроить release

`.github/workflows/release.yml` запускается вручную или по тегу `v*`. При наличии всех Secrets создаёт временный keychain, импортирует сертификат и provisioning profile, собирает `.xcarchive`, упаковывает `.ipa`, сохраняет archive как artifact и удаляет временные данные. Значения Secrets в логи не выводятся.

## 17. Как добавить GitHub Secrets

Settings → Secrets and variables → Actions → New repository secret:

| Secret | Назначение | Только release |
|---|---|---|
| `BUILD_CERTIFICATE_BASE64` | .p12 сертификат в base64 | ✅ |
| `P12_PASSWORD` | пароль .p12 | ✅ |
| `BUILD_PROVISION_PROFILE_BASE64` | provisioning profile в base64 | ✅ |
| `KEYCHAIN_PASSWORD` | пароль временного keychain | ✅ |
| `APPLE_ID` | Apple ID для нотаризации/загрузки | ✅ |
| `APPLE_TEAM_ID` | Team ID | ✅ |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID App Store Connect API | ✅ |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | ✅ |
| `APP_STORE_CONNECT_API_KEY_BASE64` | .p8 ключ в base64 | ✅ |

Получение base64: `base64 -i certificate.p12 | pbcopy` (macOS).

## 18. Что работает без Apple Developer Account

- Сборка в Xcode для Simulator
- Все unit и UI тесты
- GitHub Actions CI (build + tests)
- Локальный `run_tests.sh`

## 19. Что требует Apple Developer Account

- Archive/сборка для устройства
- Подпись и provisioning profiles
- Загрузка в App Store Connect
- Release workflow

## 20–21. Типичные ошибки CI и решения

| Ошибка | Причина | Решение |
|---|---|---|
| Xcode version mismatch | нужной версии нет на раннере | workflow сам выбирает доступную 16.x; либо укажите существующую в `DEVELOPER_DIR` |
| simulator not found | имя устройства недоступно | используйте `xcrun simctl list devices available` и поправьте destination |
| scheme not found | scheme не зашарена | проверьте наличие `Pishi.xcodeproj/xcshareddata/xcschemes/Pishi.xcscheme` |
| project not found | неверный путь | запускайте из корня репозитория |
| signing error | не отключена подпись | добавьте `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` |
| SwiftData test failure | тесты пишут в настоящую базу | тесты обязаны использовать `PersistenceController(inMemory: true)` |
| UI test timeout | медленный раннер | увеличьте timeout, уменьшите число UI-тестов на run |
| destination unavailable | Simulator не создан | `xcodebuild -downloadPlatform iOS` или другой destination |
| .xcresult не создан | тесты не запускались | проверьте шаги build/test выше по логу |
| permission denied run_tests.sh | нет +x | `chmod +x scripts/run_tests.sh` |
| YAML syntax error | битый workflow | проверьте отступы/кавы в ios.yml |
| отсутствующий Secret | release без настроек | добавьте Secrets из раздела 17 |

## 22. Возможности второй версии

- iCloud-синхронизация (CloudKit)
- Папки и теги
- Избранное
- Расширенный Markdown-рендеринг
- Виджеты и Shortcuts
- Share Extension
- Spotlight-поиск (CoreSpotlight)
- Блокировка Face ID
- Дополнительные темы
- Экспорт PDF
- Импорт нескольких файлов
