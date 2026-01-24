# Grocery System 🛒

A complete system for intelligent shopping list management, built with a microservices architecture and a modern mobile application in Flutter.

## 🚀 Key Features

### 📱 Mobile Application (Frontend)
*   **Authentication**: Secure login with Google (Google Sign-In).
*   **List Management**:
    *   Create shopping lists scheduled by date.
    *   Edit purchase dates.
    *   **Close Lists**: Finalize purchase by registering the total amount spent (locks future edits).
    *   Delete lists.
*   **Item Management**:
    *   **Smart Search**: Autocomplete for existing products in the global catalog.
    *   **On-the-fly Creation**: If a product doesn't exist, it is automatically created with an assigned category.
    *   Edit quantity and unit (Kg, Lt, Unit, etc.).
    *   Mark as bought/pending.
*   **Modern UI/UX**: Clean design (Material 3), visual status feedback, and optimized user experience (Bottom Sheets, Cards).

### ⚙️ Backend (Microservices)
The system uses a distributed architecture orchestrated with Docker Compose:

1.  **User Service (Port 8000)**: User management and authentication (JWT Tokens).
2.  **Product Service (Port 8002)**: Master catalog of products and categories.
3.  **Shopping List Service (Port 8001)**: Business logic for lists and items.
4.  **API Gateway (Nginx - Port 80)**: Single entry point that routes requests to the corresponding services.
5.  **Database (PostgreSQL)**: Centralized data persistence.

## 🛠️ Technologies

*   **Frontend**: Flutter (Dart)
*   **Backend**: Python (Django REST Framework)
*   **Database**: PostgreSQL 15
*   **Infrastructure**: Docker & Docker Compose
*   **Gateway**: Nginx

## 📦 Installation and Deployment

### Prerequisites
*   Docker and Docker Compose installed.
*   Flutter SDK installed (to run the mobile app).
*   Android/iOS Device or Emulator.

### 1. Start the Backend
In the project root, execute:

```bash
docker compose up --build
```

This will start all necessary containers. Verify they are running with `docker ps`.

*   **Gateway**: `http://localhost:80` (API accessible here)
*   **User Admin**: `http://localhost:8000/admin`
*   **List Admin**: `http://localhost:8001/admin`
*   **Product Admin**: `http://localhost:8002/admin`

### 2. Configure the Mobile App
1.  Navigate to the app directory:
    ```bash
    cd grocery_app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Configure your machine's IP in `lib/config/environment.dart` (if using Android emulator, it's usually `10.0.2.2`, for physical device use your LAN IP).
4.  Run the application:
    ```bash
    flutter run
    ```

## 📂 Project Structure

```
Grocery_system/
├── compose.yml              # Container orchestration
├── gateway/                 # Nginx configuration
├── grocery_app/             # Flutter application
│   ├── lib/
│   │   ├── config/          # Theme and environment variables
│   │   ├── models/          # Data models
│   │   ├── screens/         # Screens (Login, Home, Detail)
│   │   └── services/        # HTTP communication with Gateway
├── product_service/         # Product Microservice (Django)
├── shopping_list_service/   # List Microservice (Django)
├── user_service/            # User Microservice (Django)
└── init_sql/                # Initial DB scripts
```

## 📝 Additional Notes
*   The default currency is configured as **S/. (Soles)**.
*   The system validates that purchases cannot be scheduled for past dates.
*   Closed lists are read-only to maintain a reliable history.

---
Developed using Flutter and Microservices with Django REST Framework.
