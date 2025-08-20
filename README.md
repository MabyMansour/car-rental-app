# Car Rental Application

This repository contains a prototype of a cross‑platform car rental application for managing vehicle reservations for an agency.

## Contents

- **car_rental_app.py** – a Python Flask back‑end that exposes simple endpoints to list cars, register users and create bookings.
- **mobile_app/lib/main.dart** – a Flutter mobile client that retrieves the list of vehicles from the API and allows a user to select dates and create a reservation.
- **web_app/index.html** – a minimal web page that will be expanded into a full web interface in the future.

## Getting Started

### Backend (Flask)

1. Install dependencies:

   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install flask
   ```

2. Run the server:

   ```bash
   python car_rental_app.py
   ```

   The API will be available at `http://127.0.0.1:5000`. Endpoints include:

   - `GET /cars` – list available cars.
   - `POST /users` – create a user (name & email).
   - `POST /book` – create a booking (user_id, car_id, start_date, end_date).
   - `GET /bookings` – list bookings.

### Mobile App (Flutter)

1. Ensure Flutter is installed (`flutter doctor`).
2. Navigate into the `mobile_app` directory and run:

   ```bash
   flutter pub get
   flutter run
   ```

3. Update the `baseUrl` in `lib/main.dart` if your Flask API is running on a different host/port.

### Web App

1. Start the back‑end server as above.
2. Serve the contents of the `web_app` directory via a simple web server:

   ```bash
   cd web_app
   python -m http.server 8000
   ```

3. Open your browser to `http://localhost:8000/index.html`.

## Next Steps

This repository is a starting point. Future improvements include:

- Persisting data in a real database.
- Authentication, payment integration and notifications.
- Expanding the web interface and refining the mobile UI.
- Adding tests and documentation.
