import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Times',
      theme: ThemeData (
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.questrialTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: Scaffold(
        backgroundColor: Color.fromRGBO(167, 201, 139, 0.8),
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Prayer Times in Mississauga'),
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
        body: Center(
          child: Container(
            height: 350,
            width: 300,
            decoration: BoxDecoration(
              color: Color.fromRGBO(191, 148, 103, 1),
              borderRadius: BorderRadius.circular(20)
            ), 
            child: const PrayerTimes(),
          ),
        )
      ),
    );
  }
}

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PrayerTimesState createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  Future<Map<String, dynamic>>? _prayerTimes;

  @override
  void initState() {
    super.initState();
    _prayerTimes = fetchPrayerTimes();
  }

  Future<Map<String, dynamic>> fetchPrayerTimes() async {
    final response = await http.get(Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=Mississauga&country=Canada&method=2'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timings = data['data']['timings'] as Map<String, dynamic>;
      Map<String, String> selectTimings = {
        'Fajr': convertTo12Hour(timings['Fajr']),
        'Sunrise': convertTo12Hour(timings['Sunrise']),
        'Dhuhr': convertTo12Hour(timings['Dhuhr']),
        'Asr': convertTo12Hour(timings['Asr']),
        'Maghrib': convertTo12Hour(timings['Maghrib']),
        'Isha': convertTo12Hour(timings['Isha']),
      };
      String midnight = getMidnight(timings['Isha'], timings['Fajr']);
      selectTimings['Midnight'] = convertTo12Hour(midnight);
      return selectTimings;
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


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _prayerTimes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return ListView(
            children: snapshot.data!.entries.map((entry) {
              return ListTile(
                title: Text(
                  "${entry.key}: ${entry.value}",
                  style: const TextStyle(
                    fontSize: 20, // Change font size
                    color: Colors.black, // Change text color
                    fontWeight: FontWeight.bold, // Make text bold
                  ),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}
