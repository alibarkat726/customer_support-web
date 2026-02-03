# Customer Service Bot - Web Client

This is a Flutter Web application designed to interact with the Customer Service Bot backend.

## Prerequisites
- **Flutter SDK**: Installed and configured.
- **Python Backend**: The existing `customer_service_bot` backend must be running.

## Setup

1. **Navigate to the web project directory**:
   ```bash
   cd customer_service_web
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

## Running the Application

1. **Start the Backend**:
   Ensure your Python backend is running on port 8000.
   ```bash
   # From the root customer_service_bot directory
   uvicorn app.main:app --reloadkkkh
   ```

2. **Run Flutter Web**:
   ```bash
   # From the customer_service_web directory
   flutter run -d chrome
   ```
   *Note: If you run into CORS issues, you might need to launch Chrome with CORS disabled for testing, or configure CORS in your FastAPI backend.*

## Features
- **Customer Chat**: Connect as a customer (enter a generic ID) to chat with the bot.
- **Owner Dashboard**: Toggle the LLM auto-reply feature and upload new documents to the knowledge base.
- **Premium UI**: Dark mode design with glassmorphism and smooth animations.

## Troubleshooting
- **Connection Refused**: Ensure the backend is running at `http://127.0.0.1:8000`. If running on an emulator, change `lib/services/api_service.dart` to use `10.0.2.2`.
- **WebSocket Error**: Check if the `customer_id` is provided correctly.
