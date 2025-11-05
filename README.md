
# 📚 EvoLearn — Aplicación Móvil de Aprendizaje Inteligente

EvoLearn es una aplicación móvil creada para ayudarte a **organizar**, **estudiar** y **resumir contenido** de manera eficiente.  
Podrás subir tus archivos PDF, gestionarlos en carpetas personalizadas y generar **resúmenes automáticos** y **quizzes** usando IA 🤖✨.

---

## 🚀 Tecnologías utilizadas

| Parte        | Tecnología |
|-------------|------------|
| **Frontend** | Flutter (Dart) |
| **Backend**  | PHP (API REST) |
| **Base Datos** | MySQL |
| **IA** | Servicio externo (OpenAI / LLM compatible) |

---

## 📦 Backend (PHP)

### ✅ Requisitos
- PHP 8+
- Composer
- Servidor Apache o Nginx
- MySQL

### 🔧 Instalación Backend

1. Clonar el proyecto:
```bash
git clone https://github.com/tu-repo/backend-evolearn.git
cd backend-evolearn
```

2. Instalar dependencias con Composer:
```bash
composer install
```

3. Importar la base de datos:
```sql
mysql -u tu_usuario -p tu_base_de_datos < database.sql
```

4. Configurar credenciales en `.env`:
```
DB_HOST=localhost
DB_NAME=tu_base_de_datos
DB_USER=tu_usuario
DB_PASS=tu_password
```

5. Iniciar servidor local:
```bash
php -S localhost:8000 -t public
```

Tu API estará disponible en:  
👉 `http://localhost:8000`

---

## 📱 Frontend (Flutter)

### ✅ Requisitos
- Flutter SDK 3.x
- Android Studio o Visual Studio Code
- Emulador o dispositivo físico

### 🔧 Instalación Frontend

1. Clonar el proyecto:
```bash
git clone https://github.com/tu-repo/frontend-evolearn.git
cd frontend-evolearn
```

2. Descargar dependencias:
```bash
flutter pub get
```

3. Crear archivo de configuración `/lib/config.dart`:
```dart
const String API_URL = "http://localhost:8000"; // cambiar si deployas
```

4. Ejecutar la app:
```bash
flutter run
```

---

## 📦 Generar APK (release)

> ⚠️ Antes de generar APK configura firma 🔐:  
https://docs.flutter.dev/deployment/android#signing-the-app

1. Limpia build:
```bash
flutter clean
```

2. Genera el APK release:
```bash
flutter build apk --release
```

El archivo se generará en:  
👉 `build/app/outputs/flutter-apk/app-release.apk`

---

## 🗂 Estructura del Proyecto

```
/
├── backend/        → API REST en PHP
├── frontend/       → Aplicación Flutter
└── README.md
```

---

## 🤝 Contribución

¡Contribuciones son bienvenidas!  
Puedes abrir un Issue o enviar un Pull Request 🚀.

---

## 📜 Licencia

Este proyecto está bajo la licencia **MIT**.

---

### 💡 Autor(es)
**Akhtar Oviedo, Ahmed Hasan		-	(2022074261)**
**Anampa Pancca, David Jordan		-	(2022074268)**
**Salas Jimenez, Walter Emmanuel 	-	(2022073896)**
