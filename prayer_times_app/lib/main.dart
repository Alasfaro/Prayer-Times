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

class LocationService {
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }
}

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PrayerTimesState createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  String _cityName = 'Mississauga'; //Default
  Map<String, dynamic>? _prayerTimes;

  @override
  void initState() {
    super.initState();
    // _fetchCityAndPrayerTimes();
    _fetchPrayerData(_cityName);
  }

//   Future<String> getCityName(Position position) async {
//   try {
//     List<Placemark> placemarks = await placemarkFromCoordinates(
//       position.latitude,
//       position.longitude,
//     );
//     Placemark place = placemarks[0];
//     return "${place.locality}, ${place.country}";
//   } catch (e) {
//     print(e);
//     return "Unknown Location";
//   }
// }

//   void _fetchCityAndPrayerTimes() async {
//     LocationService().determinePosition().then((position) async {
//       String cityName = await getCityName(position);
//       _fetchPrayerData(cityName);
//     }).catchError((error) {
//       print(error);
//       _fetchPrayerData(_cityName); // Default to Mississauga if error
//     });
//   }

  Future<void> _fetchPrayerData(String city) async {
    final response = await http.get(Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=$city&country=Canada&method=2'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timings = data['data']['timings'] as Map<String, dynamic>;
      setState(() {
        _cityName = city;
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

  Widget prayerTimeTile(String prayerName, String time, BuildContext context) {
    var isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        Icons.access_time, // Placeholder icon, change as needed
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      title: Text(
        prayerName,
        style: GoogleFonts.questrial(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        time,
        style: GoogleFonts.questrial(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 18,
        ),
      ),
    );
  }

void _showCityInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController textFieldController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Your City'),
          content: TextField(
            controller: textFieldController,
            decoration: const InputDecoration(hintText: "City Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  _cityName = textFieldController.text;
                });
                _fetchPrayerData(textFieldController.text);();
                Navigator.pop(context);
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
                      fontSize: 20, // Change font size
                      color: Colors.black, // Change text color
                      fontWeight: FontWeight.bold, // Make text bold
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