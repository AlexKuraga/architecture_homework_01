workspace "File Storage System" "Architecture of a cloud file storage system" {

    model {

        user = person "User" "User that stores files and manages folders"

        emailService = softwareSystem "Email Service" "External system that sends email notifications"

        objectStorage = softwareSystem "Object Storage" "External S3 compatible storage for binary files"


        fileStorageSystem = softwareSystem "File Storage System" "System for storing user files and folders" {

            webApp = container "Web Application" "Browser-based SPA used by users to manage folders and files" "React"

            api = container "Backend API" "API gateway and orchestration for backend services (authentication, routing, request validation)" "Spring Boot / Node.js"

            userService = container "User Service" "Manages user accounts, search by login/name mask and emits events about user changes" "Java / Spring"

            folderService = container "Folder Service" "Manages folders (create/list/delete) and enforces folder-level business rules" "Java / Spring"

            fileService = container "File Service" "Handles file upload, download, metadata management and deletion; coordinates with storage adapter" "Java / Spring"

            storageAdapter = container "Storage Adapter" "S3-compatible client for uploading/downloading/deleting binary objects" "S3 SDK / MinIO client"

            database = container "Database" "Relational DB for users, folders and file metadata (file id, name, ownerId, folderId, objectKey, size, timestamps)" "PostgreSQL"
        }

        // Relationships - context
        user -> webApp "Uses" "HTTPS"

        webApp -> api "Calls API" "REST/JSON"

        api -> userService "User API calls" "REST"
        api -> folderService "Folder API calls" "REST"
        api -> fileService "File API calls" "REST"

        folderService -> fileService "Requests deletion of files in folder" "Internal call"
        
        // Relationships between services and storage/database/external systems
        userService -> database "Read/write users" "JDBC"
        folderService -> database "Read/write folders" "JDBC"
        fileService -> database "Read/write file metadata" "JDBC"

        fileService -> storageAdapter "Upload/download files" "HTTPS"

        storageAdapter -> objectStorage "Store objects" "S3 API"

        userService -> emailService "Send confirmation email" "SMTP"
    }



    views {

        systemContext fileStorageSystem {

            include *
            autolayout lr

            title "System Context Diagram"
            description "Shows the File Storage System in relation to users and external systems"
        }



        container fileStorageSystem {

            include *
            autolayout lr

            title "Container Diagram"
            description "Containers and their responsibilities: frontend, API, domain services, DB and storage adapter."
        }



        dynamic fileStorageSystem upload_file {

            title "Upload File Scenario"

            description "User uploads a file into a folder. Backend stores binary in object storage and metadata in DB."

            user -> webApp "Select file and click Upload"

            webApp -> api "POST /folders/{folderId}/files (multipart/form-data)"

            api -> fileService "Validate request and forward upload"

            fileService -> storageAdapter "PUT /bucket/{objectKey} (stream upload)"

            storageAdapter -> objectStorage "PUT object (binary payload)"

            fileService -> database "INSERT file metadata (objectKey, ownerId, folderId, name, size, createdAt)"

            fileService -> api "Return file metadata and download URL (or objectKey)"

            api -> webApp "201 Created + file metadata"

            webApp -> user "Show upload success"
        }



        dynamic fileStorageSystem delete_folder {

            title "Delete Folder Scenario"

            description "User requests folder deletion: system finds files, deletes binaries and metadata, then removes folder."

            user -> webApp "Request folder deletion"

            webApp -> api "DELETE /folders/{folderId}"

            api -> folderService "Validate rights & request folder deletion"

            folderService -> database "SELECT files in folder"

            folderService -> fileService "Delete files"

            fileService -> storageAdapter "DELETE object for each file"

            storageAdapter -> objectStorage "DELETE /bucket/{objectKey}"

            fileService -> database "DELETE file metadata rows"

            folderService -> database "DELETE folder row"

            folderService -> api "Return result (204 No Content)"

            api -> webApp "204 No Content"

            webApp -> user "Show success confirmation"
        }



        styles {

            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        
            element "Container" {
                background #438dd5
                color #ffffff
            }
        
            relationship "Relationship" {
                thickness 2
                color #707070
            }
        
        }

    }

}