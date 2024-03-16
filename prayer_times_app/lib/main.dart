import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrayerTimes(),
      theme: ThemeData (
      primarySwatch: Colors.blue,
      textTheme: GoogleFonts.questrialTextTheme(
        Theme.of(context).textTheme,
      ),
    ),
  );}
}

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PrayerTimesState createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  String? _cityName = 'Your City'; //Default
    String? _countryName = 'Your Country'; //Default
  Map<String, dynamic>? _prayerTimes;


  Future<Map<String, String>> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    print("Position: ${position.latitude}, ${position.longitude}");
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
    );
    Placemark place = placemarks[0];
    String city = place.locality ?? "Your City";
    String country = place.country ?? "Your Country";
    return {"city": city, "country": country};
  }


  Future<void> getPrayerTime(String city, String country) async {
    final response = await http.get(Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=2'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timings = data['data']['timings'] as Map<String, dynamic>;
      setState(() {
        _cityName = city;
        _countryName = country;
        _prayerTimes = {
          'Fajr': convertTo12Hour(timings['Fajr']),
          'Sunrise': convertTo12Hour(timings['Sunrise']),
          'Dhuhr': convertTo12Hour(timings['Dhuhr']),
          'Asr': convertTo12Hour(timings['Asr']),
          'Maghrib': convertTo12Hour(timings['Maghrib']),
          'Isha': convertTo12Hour(timings['Isha']),
        };
        String midnight = getMidnight(timings['Isha'], timings['Fajr']);
        _prayerTimes?['Midnight'] = convertTo12Hour(midnight);
      });     
    } else {
      throw Exception('Failed to load prayer times');
    }
  }


  String getMidnight(String isha, String fajr) {
    final ishaDt = DateFormat('HH:mm').parse(isha);
    final fajrDt = DateFormat('HH:mm').parse(fajr);
    Duration diff = fajrDt.difference(ishaDt);
    if (diff.isNegative) {
      diff = const Duration(hours: 24) + diff; 
    }
    final midnightDt = ishaDt.add(diff ~/ 2);
    return DateFormat('h:mm a').format(midnightDt);
}

  String convertTo12Hour(String time) {
    final time24 = DateFormat('HH:mm').parse(time);
    return DateFormat('h:mm a').format(time24);
  }


  Future<void> _fetchLocationAndPrayerTimes() async {
    try {
      final location = await getLocation();
      if (location["city"] != null && location["country"] != null) {
        await getPrayerTime(location["city"]!, location["country"]!);
      } else {
        print("Location could not be determined.");
      }
    } catch (e) {
      print(e);
      await getPrayerTime('Mississauga', 'Canada');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPrayerTimes();
  }


  void _showCityInputDialog() {
    TextEditingController cityController = TextEditingController();
    TextEditingController countryController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityController,
                decoration: const InputDecoration(hintText: "City"),
              ),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(hintText: "Country"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                final String cityInput = cityController.text;
                final String countryInput = countryController.text;
                if (cityInput.isNotEmpty && countryInput.isNotEmpty) {
                  getPrayerTime(cityInput, countryInput);
                  Navigator.of(context).pop();
                } else {
                  print("Please enter both city and country.");
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(167, 201, 139, 0.8),
      appBar: AppBar(
        title: Text('Prayer Times in $_cityName'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {},
          icon: const FaIcon(FontAwesomeIcons.moon),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.mosque
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCityInputDialog,
        tooltip: 'Enter City',
        backgroundColor: const Color.fromRGBO(191, 148, 103, 1),
        child: const Icon(
            Icons.edit_location,
            color: Color.fromARGB(255, 57, 56, 56),
          ),
      ),
      body: Center(
        child: Container(
          height: 350,
          width: 300,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(191, 148, 103, 1),
            borderRadius: BorderRadius.circular(20)
          ), 
          child: _prayerTimes == null ? const CircularProgressIndicator() : ListView(
            children: _prayerTimes!.entries.map((entry) {
              return ListTile(
                title: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      )
    );
  }

}