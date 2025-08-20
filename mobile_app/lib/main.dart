import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple data model for a car. Matches the structure returned by the
/// Flask backend's /cars endpoint.
class Car {
  final int id;
  final String name;
  final String type;
  final double pricePerDay;

  Car({required this.id, required this.name, required this.type, required this.pricePerDay});

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
    );
  }
}

void main() {
  runApp(const CarRentalApp());
}

/// Root widget of the car rental application.
class CarRentalApp extends StatelessWidget {
  const CarRentalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CarListPage(),
    );
  }
}

/// Page that displays a list of cars fetched from the backend.
class CarListPage extends StatefulWidget {
  const CarListPage({Key? key}) : super(key: key);

  @override
  _CarListPageState createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  late Future<List<Car>> _futureCars;

  @override
  void initState() {
    super.initState();
    _futureCars = fetchCars();
  }

  Future<List<Car>> fetchCars() async {
    // Change the URL below to match the address where your Flask backend is running.
    // If you run the mobile app in an emulator, 'localhost' refers to the emulator
    // itself. Use your machine's IP address instead (e.g. 10.0.2.2 for Android emulator).
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/cars'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Car.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cars');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cars')), 
      body: FutureBuilder<List<Car>>(
        future: _futureCars,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No cars available'));
          }
          final cars = snapshot.data!;
          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return ListTile(
                title: Text(car.name),
                subtitle: Text('${car.type} - EUR${car.pricePerDay.toStringAsFixed(2)}/jour'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookCarPage(car: car),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Page that allows the user to book a specific car.
class BookCarPage extends StatefulWidget {
  final Car car;
  const BookCarPage({Key? key, required this.car}) : super(key: key);

  @override
  _BookCarPageState createState() => _BookCarPageState();
}

class _BookCarPageState extends State<BookCarPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  Future<void> _selectDate({required bool start}) async {
    final initialDate = start ? DateTime.now() : _startDate ?? DateTime.now();
    final firstDate = start ? DateTime.now() : _startDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
          // reset end date if before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates de location.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 1, // TODO: replace with authenticated user ID
          'car_id': widget.car.id,
          'start_date': _startDate!.toIso8601String().split('T').first,
          'end_date': _endDate!.toIso8601String().split('T').first,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation effectuée avec succès !')),
        );
        Navigator.pop(context);
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réserver ${widget.car.name}')), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.car.name,
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 8.0),
            Text('${widget.car.type} - EUR${widget.car.pricePerDay.toStringAsFixed(2)}/jour'),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de début'),
                      TextButton(
                        onPressed: () => _selectDate(start: true),
                        child: Text(_startDate == null
                            ? 'Sélectionner'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de fin'),
                      TextButton(
                        onPressed: _startDate == null ? null : () => _selectDate(start: false),
                        child: Text(_endDate == null
                            ? 'Sélectionner'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmer la réservation'),
            ),
          ],
        ),
      ),
    );
  }
}
