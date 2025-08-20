"""
A simple Flask application that demonstrates the core API endpoints
for a car rental service. This is a prototype to illustrate how
functionality such as listing vehicles, registering users and booking
cars might be implemented on the back‑end. Data is stored in memory
for demonstration only.

How to run the server:

    python car_rental_app.py

The server will start on http://127.0.0.1:5000/. You can test the
endpoints with curl or any HTTP client. For example, to list cars:

    curl http://127.0.0.1:5000/cars

To register a user:

    curl -X POST -H "Content-Type: application/json" \
         -d '{"name":"Alice","email":"alice@example.com"}' \
         http://127.0.0.1:5000/users

To book a car:

    curl -X POST -H "Content-Type: application/json" \
         -d '{"user_id":1,"car_id":1,"start_date":"2025-08-25","end_date":"2025-08-27"}' \
         http://127.0.0.1:5000/book

This prototype does not implement authentication, payment processing
or persistent storage, but those features can be layered on using
appropriate libraries and services (e.g. JWT for auth, Stripe for
payments, SQLAlchemy for database access).
"""

from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional

from flask import Flask, jsonify, request

app = Flask(__name__)


class User:
    """Represents a user in the system."""

    _id_counter: int = 1

    def __init__(self, name: str, email: str) -> None:
        self.id: int = User._id_counter
        User._id_counter += 1
        self.name: str = name
        self.email: str = email

    def to_dict(self) -> Dict[str, object]:
        return {"id": self.id, "name": self.name, "email": self.email}


class Car:
    """Represents a car available for rent."""

    _id_counter: int = 1

    def __init__(self, name: str, car_type: str, price_per_day: float) -> None:
        self.id: int = Car._id_counter
        Car._id_counter += 1
        self.name: str = name
        self.car_type: str = car_type
        self.price_per_day: float = price_per_day
        # maintain a list of bookings for this car
        self.bookings: List[Booking] = []

    def is_available(self, start_date: datetime, end_date: datetime) -> bool:
        """Check if the car is available for the given date range."""
        for booking in self.bookings:
            # if the requested booking overlaps with an existing booking, not available
            if (start_date <= booking.end_date) and (booking.start_date <= end_date):
                return False
        return True

    def to_dict(self) -> Dict[str, object]:
        return {
            "id": self.id,
            "name": self.name,
            "type": self.car_type,
            "price_per_day": self.price_per_day,
        }


class Booking:
    """Represents a booking for a car."""

    _id_counter: int = 1

    def __init__(self, user: User, car: Car, start_date: datetime, end_date: datetime) -> None:
        self.id: int = Booking._id_counter
        Booking._id_counter += 1
        self.user: User = user
        self.car: Car = car
        self.start_date: datetime = start_date
        self.end_date: datetime = end_date

    def to_dict(self) -> Dict[str, object]:
        return {
            "id": self.id,
            "user_id": self.user.id,
            "car_id": self.car.id,
            "start_date": self.start_date.strftime("%Y-%m-%d"),
            "end_date": self.end_date.strftime("%Y-%m-%d"),
        }


class RentalService:
    """A simple in‑memory rental service to manage users, cars and bookings."""

    def __init__(self) -> None:
        self.users: Dict[int, User] = {}
        self.cars: Dict[int, Car] = {}
        self.bookings: Dict[int, Booking] = {}

    def add_user(self, name: str, email: str) -> User:
        user = User(name, email)
        self.users[user.id] = user
        return user

    def add_car(self, name: str, car_type: str, price_per_day: float) -> Car:
        car = Car(name, car_type, price_per_day)
        self.cars[car.id] = car
        return car

    def list_cars(self) -> List[Dict[str, object]]:
        return [car.to_dict() for car in self.cars.values()]

    def get_car(self, car_id: int) -> Optional[Car]:
        return self.cars.get(car_id)

    def get_user(self, user_id: int) -> Optional[User]:
        return self.users.get(user_id)

    def book_car(self, user_id: int, car_id: int, start_date: datetime, end_date: datetime) -> Booking:
        user = self.get_user(user_id)
        if not user:
            raise ValueError(f"User with id {user_id} does not exist.")
        car = self.get_car(car_id)
        if not car:
            raise ValueError(f"Car with id {car_id} does not exist.")
        # check availability
        if not car.is_available(start_date, end_date):
            raise ValueError("Car is not available for the requested period.")
        booking = Booking(user, car, start_date, end_date)
        car.bookings.append(booking)
        self.bookings[booking.id] = booking
        return booking

    def list_bookings(self) -> List[Dict[str, object]]:
        return [booking.to_dict() for booking in self.bookings.values()]


rental_service = RentalService()

# Prepopulate with some cars for demonstration
rental_service.add_car("Peugeot 208", "Economy", 45.0)
_rental_var_unused = rental_service.add_car("BMW X5", "SUV", 120.0)
rental_service.add_car("Tesla Model 3", "Electric", 150.0)


@app.route("/cars", methods=["GET"])
def list_cars():
    """Return a list of available cars with basic information."""
    return jsonify(rental_service.list_cars())


@app.route("/users", methods=["POST"])
def register_user():
    """Register a new user.

    Expected JSON payload: {"name": str, "email": str}
    Returns the created user with its assigned ID.
    """
    data = request.get_json(force=True)
    name = data.get("name")
    email = data.get("email")
    if not name or not email:
        return jsonify({"error": "Missing name or email"}), 400
    user = rental_service.add_user(name, email)
    return jsonify(user.to_dict()), 201


@app.route("/book", methods=["POST"])
def book_car_endpoint():
    """Create a new booking for a car.

    Expected JSON payload:
        {
            "user_id": int,
            "car_id": int,
            "start_date": "YYYY-MM-DD",
            "end_date": "YYYY-MM-DD"
        }
    """
    data = request.get_json(force=True)
    try:
        user_id = int(data.get("user_id"))
        car_id = int(data.get("car_id"))
        start_date = datetime.strptime(data.get("start_date"), "%Y-%m-%d")
        end_date = datetime.strptime(data.get("end_date"), "%Y-%m-%d")
    except (TypeError, ValueError) as e:
        return jsonify({"error": f"Invalid booking data: {e}"}), 400
    if end_date < start_date:
        return jsonify({"error": "End date must be after start date"}), 400
    try:
        booking = rental_service.book_car(user_id, car_id, start_date, end_date)
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    return jsonify(booking.to_dict()), 201


@app.route("/bookings", methods=["GET"])
def list_bookings_endpoint():
    """Return a list of all bookings."""
    return jsonify(rental_service.list_bookings())


if __name__ == "__main__":
    app.run(debug=True)
