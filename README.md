# ToDoList(тестовое)

## Стек
UIKit · VIPER · CoreData · URLSession · GCD/OperationQueue · XCTest

## Первый запуск (seed)
При пустой БД и флаге `seededOnce == false` интерактор грузит `https://dummyjson.com/todos`,
сохраняет в CoreData и показывает список. Флаг хранится в `UserDefaults`.

## Архитектура
VIPER-модуль `ToDoList`:
- View: `ToDoListViewController`
- Presenter: `ToDoListPresenter`
- Interactor: `ToDoListInteractor`
- Router: `ToDoListRouter`
- Entity(доменные): `ToDoEntity`
- Data: `ToDoRepository` (CoreData), `ToDosAPIClient`

## Функции
- Список, добавление, редактирование, удаление, done/undo
- Поиск с дебаунсом
- Персистентность CoreData
- Фоновая обработка операций

## Тесты
- API: `ToDosAPIClientTests` (успех, HTTP-ошибка)  
- Repository: `ToDoRepositoryTests`, `ToDoRepositoryReplaceAllTests` (in-memory CoreData)  
- Presenter: `ToDoListPresenterTests` (load/map/display, роутинг, форвардинг, loading/error)  
- UI smoke: `ToDoListUITests*` (запуск)

## Решения
- Авто-мердж главного контекста CoreData
- Batch delete в SQLite, fetch+delete в in-memory (для тестов)

## Как проверить seed вручную
Удалить приложение с симулятора и запустить снова
(сбросит CoreData и `UserDefaults.seededOnce`).
