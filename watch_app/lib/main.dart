import 'package:workout/workout.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:flutter/material.dart';

import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _watch = WatchConnectivity();

  final workout = Workout();

  final exerciseType = ExerciseType.walking;
  final features = [
    WorkoutFeature.heartRate,
  ];

  final enableGps = false;

  double heartRate = 0;
  bool gameStarted = false;

  final _log = <String>[];

  @override
  void initState() {
    super.initState();

    _watch.messageStream.listen((e) {
      print("Message: $e");
      setState(() => _log.add('Received message: $e'));
      if (e["Command"].toString() == "START_GAME") {
        startGame();
      } else if (e["Command"].toString() == "END_GAME") {
        endGame();
      }
    });

    workout.stream.listen((event) {
      print('${event.feature}: ${event.value} (${event.timestamp})');
      if (event.feature == WorkoutFeature.heartRate) {
        setState(() {
          heartRate = event.value;
        });
        var message = {'HeartRate': event.value};
        _watch.sendMessage(message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: AmbientMode(
        builder: (context, mode, child) => child!,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              gameStarted
                                  ? heartRate.toString()
                                  : "--",
                              style: const TextStyle(
                                  fontSize: 60,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Raleway'),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 40,
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void endGame() async {
    if (gameStarted) {
      await workout.stop();
      setState(() => gameStarted = false);
      WakelockPlus.disable();
    }
  }

  void startGame() async {
    if (!gameStarted) {
      final result = await workout.start(
        // In a real application, check the supported exercise types first
        exerciseType: exerciseType,
        features: features,
        enableGps: enableGps,
      );
      if (result.unsupportedFeatures.isNotEmpty) {
        debugPrint('Unsupported features: ${result.unsupportedFeatures}');
        // In a real application, update the UI to match
      } else {
        debugPrint('All requested features supported');
      }
      setState(() => gameStarted = true);
      WakelockPlus.enable();
    }
  }
}
