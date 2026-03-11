# Домашнее задание 01 - Документирование архитектуры

## Вариант 11
**Хранение файлов https://360.yandex.ru/disk/**  
Приложение должно содержать следующие данные:
- папка
- файл
- пользователь
Реализовать API:
- Создание нового пользователя
- Поиск пользователя по логину
- Поиск пользователя по маске имя и фамилии
- Создание новой папки
- Получение списка всех папок
- Создание файла в папке
- Получение файла по имение
- Удаление фалйла
- Удаление папки

## Краткое описание системы
Система предназначена для хранения пользовательских файлов и папок.  
Метаданные (пользователи, папки, мета-информация о файлах) хранятся в реляционной базе данных PostgreSQL. Бинарные данные файлов хранятся в S3-совместимом объектном хранилище, например, MinIO. Фронтенд - Single Page Application (React), backend организован по принципу разделения ответственности: User Service, Folder Service, File Service. Также имеется API-шлюз/оркестратор.

## Роли пользователей и внешние системы
- Роль:
  - **User** - зарегистрированный пользователь, который управляет папками и файлами.
- Внешние системы:
  - Object Storage (S3-compatible) - хранение бинарных объектов (файлов).
  - Email Service (SMTP) - отправка подтверждений/уведомлений пользователю (опционально).

## Компоненты / контейнеры и их ответственность
1. **Web Application (React SPA)**  
   Интерфейс пользователя: регистрация, поиск пользователей, создание папок, загрузка/скачивание/удаление файлов.

2. **Backend API (API gateway / orchestrator)**  
   Точка входа для всех REST API-запросов; выполняет маршрутизацию запросов к соответствующим internal services, валидацию и агрегацию ответов.

3. **User Service**  
   Управление пользователями: создание, поиск по логину, поиск по маске имени/фамилии; отправка уведомлений через Email Service.

4. **Folder Service**  
   Создание, получение списка и удаление папок. При удалении инициирует удаление файлов в папке.

5. **File Service**  
   Управление файлами: загрузка, координация записи в Object Storage и метаданных в DB, получение файла, генерация ссылок / проксирование, удаление файла.

6. **Storage Adapter**  
   Абстракция над S3-совместимым хранилищем: PUT/GET/DELETE объектов, генерация pre-signed URLs при необходимости.

7. **Database (PostgreSQL)**  
   Таблицы: users, folders, files (columns: id, name, owner_id, folder_id, object_key, size, created_at, ...).

## Диаграммы
- **System Context (C1)** - показывает User, File Storage System, Object Storage и Email Service.
- **Container Diagram (C2)** - показывает Web App, Backend API, User/Folder/File services, Storage Adapter и Database.
- **Dynamic Diagram (C4 dynamic)**
  - Upload File (основной сценарий): UI → API → File Service → Storage Adapter → Object Storage → DB
  - Delete Folder: UI → API → Folder Service → (File Service → Storage Adapter → Object Storage → DB) → DB

## Основные REST-API
- `POST /users` - создать пользователя
- `GET /users?login={login}` - получить пользователя по логину
- `GET /users/search?nameMask={mask}` - поиск пользователей по маске
- `POST /folders` - создать новую папку
- `GET /folders` - список всех папок пользователя
- `POST /folders/{folderId}/files` - загрузить файл в папку
- `GET /folders/{folderId}/files/{fileName}` - получить файл по имени
- `DELETE /folders/{folderId}/files/{fileId}` - удалить файл
- `DELETE /folders/{folderId}` - удалить папку


## Сценарий Upload File (шаги)
1. Пользователь выбирает файл → Web App отправляет `POST /folders/{folderId}/files`.
2. API валидирует запрос и передаёт в File Service.
3. File Service генерирует `objectKey` и через Storage Adapter делает `PUT` в Object Storage.
4. После успешной загрузки File Service сохраняет метаданные в Database.
5. File Service возвращает метаданные (id, name, objectKey, downloadUrl) через API → Web App отображает результат.

## Результат проделанной работы
- `workspace.dsl` - модель и определения view.
- `readme.md` - файл с описанием выбранного варианта, ролями, внешними системами, use-cases, описанием контейнеров, технологиями и сценарием.

## Технологии и протоколы
- Frontend: React (SPA), HTTPS
- Backend: Spring Boot / Node.js, REST/HTTPS (JSON)
- Database: PostgreSQL, JDBC
- Object Storage: S3 API
- Email: SMTP
