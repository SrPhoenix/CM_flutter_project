// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/play_session/player_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:multiplayer/style/score.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreen();
}

class _GameScreen extends State<GameScreen> {
  late PlayerController controller;
  ChartSeriesController? _myChartSeriesController;
  ChartSeriesController? _opponentChartSeriesController;
  bool lost = false;
  static const _preCelebrationDuration = Duration(milliseconds: 500);
  int upperBounder = 98;
  int lowerBounder = 82;
  late StreamSubscription dataListener;
  late String myUsername;
  late String opponentUsername;

  Map<String, List<double>> heartRateData = {};

  @override
  void initState() {
    super.initState();
    controller = context.read<PlayerController>();
    createdDataListener();
    myUsername = controller.username;
    for (Player user in controller.connectedUsers) {
      heartRateData[user.displayName] = [];
      if (user.displayName != myUsername) {
        opponentUsername = user.displayName;
      }
    }
  }

  Future<void> _playerWon(Score score) async {
    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }

  void createdDataListener() {
    dataListener = controller.uiStream.listen((data) {
      var jsonData = jsonDecode(data);
      if (jsonData["Command"] == "HEART_RATE") {
        var username = jsonData["Username"] as String;
        var heartRate = double.parse(jsonData["HeartRate"] as String);
        heartRateData[username]!.add(heartRate);
        if (heartRateData[username]!.length == 20) {
          heartRateData[username]!.removeAt(0);
          if (username == opponentUsername) {
            _opponentChartSeriesController?.updateDataSource(
                addedDataIndex: heartRateData[username]!.length - 1, removedDataIndex: 0);
          } else {
            _myChartSeriesController?.updateDataSource(
                addedDataIndex: heartRateData[username]!.length - 1, removedDataIndex: 0);
          }
        }
        setState(() {});
      } else if (jsonData["Command"] == "END_GAME") {
        Duration duration =
            Duration(seconds: int.parse(jsonData["Duration"] as String));
        _playerWon(Score(jsonData["Username"] as String, duration));
      }
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await dataListener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerController>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Serious Game!',
                    style:
                        TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.door_front_door,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      playerController.leaveMatch();
                      GoRouter.of(context).go('/play/joinRoom');
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: const NumericAxis(
                    isVisible: false,
                  ),
                  primaryYAxis: NumericAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    interval: 10,
                    minimum:
                        controller.getStartHeartRateOfUsername(myUsername) - 10,
                    maximum:
                        controller.getStartHeartRateOfUsername(myUsername) + 10,
                    plotBands: [
                      PlotBand(
                        start:
                            controller.getStartHeartRateOfUsername(myUsername) -
                                10,
                        end:
                            controller.getStartHeartRateOfUsername(myUsername) -
                                10,
                        borderColor: Colors.red,
                        borderWidth: 4,
                      ),
                      PlotBand(
                        start:
                            controller.getStartHeartRateOfUsername(myUsername) +
                                10,
                        end:
                            controller.getStartHeartRateOfUsername(myUsername) +
                                10,
                        borderColor: Colors.red,
                        borderWidth: 4,
                      ),
                    ],
                  ),
                  series: <LineSeries<double, int>>[
                    LineSeries<double, int>(
                      onRendererCreated: (ChartSeriesController controller) {
                        _myChartSeriesController = controller;
                      },
                      dataSource: heartRateData[myUsername],
                      xValueMapper: (_, index) => index,
                      yValueMapper: (heartRate, _) => heartRate,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    myUsername,
                    style:
                        TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
                  ),
                  Text(
                    (heartRateData[myUsername] != null &&
                            heartRateData[myUsername]!.isNotEmpty)
                        ? heartRateData[myUsername]!.last.toStringAsFixed(0)
                        : "--",
                    style: const TextStyle(
                        fontSize: 60,
                        color: Colors.black,
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    opponentUsername,
                    style:
                        TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
                  ),
                  Text(
                    (heartRateData[opponentUsername] != null &&
                            heartRateData[opponentUsername]!.isNotEmpty)
                        ? heartRateData[opponentUsername]!.last.toStringAsFixed(0)
                        : "--",
                    style: const TextStyle(
                        fontSize: 60,
                        color: Colors.black,
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
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: const NumericAxis(
                    isVisible: false,
                  ),
                  primaryYAxis: NumericAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    interval: 10,
                    minimum: controller
                            .getStartHeartRateOfUsername(opponentUsername) -
                        10,
                    maximum: controller
                            .getStartHeartRateOfUsername(opponentUsername) +
                        10,
                    plotBands: [
                      PlotBand(
                        start: controller.getStartHeartRateOfUsername(
                                opponentUsername) -
                            10,
                        end: controller.getStartHeartRateOfUsername(
                                opponentUsername) -
                            10,
                        borderColor: Colors.red,
                        borderWidth: 4,
                      ),
                      PlotBand(
                        start: controller.getStartHeartRateOfUsername(
                                opponentUsername) +
                            10,
                        end: controller.getStartHeartRateOfUsername(
                                opponentUsername) +
                            10,
                        borderColor: Colors.red,
                        borderWidth: 4,
                      ),
                    ],
                  ),
                  series: <LineSeries<double, int>>[
                    LineSeries<double, int>(
                      onRendererCreated: (ChartSeriesController controller) {
                        _opponentChartSeriesController = controller;
                      },
                      dataSource: heartRateData[opponentUsername],
                      xValueMapper: (_, index) => index,
                      yValueMapper: (heartRate, _) => heartRate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
