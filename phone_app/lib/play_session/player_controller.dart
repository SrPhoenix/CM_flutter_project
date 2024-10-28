// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nakama/nakama.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'dart:math';
import 'dart:async';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class PlayerController extends ChangeNotifier {
  static final _log = Logger('PlayerController');
  // static final _host = "192.168.160.57";
  static final _host = "192.168.1.92";
  static const String _chars = 'ABCDEF1234567890';
  final Random _rnd = Random();

  String username = 'Anonymous${Random().nextInt(1000)}';
  String lobbyCode = '';
  List<Player> connectedUsers = [];
  bool _isHost = false;
  late String userId;

  late final NakamaBaseClient _client;
  late final Session _session;
  late final NakamaWebsocketClient _socket;
  late Match _match;
  late UserPresence hostPresence;
  late StreamSubscription<MatchData> dataSubscription;

  Map<String, List<double>> heartRateFullData = {};
  static const double threshold = 10;
  late DateTime _startOfPlay;

  final _watch = WatchConnectivity();
  var startHeartRate = 0.0;
  var currentHeartRate = 0.0;
  late StreamSubscription<Map<String, dynamic>> watchMessages;

  bool allReady = false;

  final StreamController<String> _uiStreamController =
      StreamController<String>.broadcast();
  Stream<String> get uiStream => _uiStreamController.stream;

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  PlayerController() {
    connectToNakama();
    createWatchListener();
  }

  Future<void> connectToNakama() async {
    _client = getNakamaClient(
      host: _host,
      ssl: false,
      serverKey: 'defaultkey',
    );
  }

  Future<void> createPlayerSession() async {
    _session = await _client.authenticateDevice(
        deviceId: 'devicefrom$username', username: username);

    userId = _session.userId;
    notifyListeners();

    if (kDebugMode) {
      print("Username: $username");
      print("UserId: $userId");
    }

    _socket = NakamaWebsocketClient.init(
      host: _host,
      ssl: false,
      token: _session.token,
    );
  }

  Future<void> createMatch() async {
    lobbyCode = getRandomString(6);

    createDataListener();

    _match = await _socket.createMatch(lobbyCode);
    if (kDebugMode) {
      print('Match created with ID: $lobbyCode');
    }

    _isHost = true;
    connectedUsers.add(Player(
        isMe: true, isHost: true, displayName: username, isReady: false));

    Map<String, dynamic> message = {'Username': username, "IsHost": true};
    sendMessage(1, message);
  }

  Future<void> joinMatch() async {
    createDataListener();
    _match = await _socket.createMatch(lobbyCode);
    if (kDebugMode) {
      print('Joined match with ID: $lobbyCode');
    }
    _isHost = false;
    connectedUsers.add(Player(
        isMe: true, isHost: false, displayName: username, isReady: false));

    _isHost = false;

    Map<String, dynamic> message = {'Username': username, "IsHost": false};
    sendMessage(1, message);
  }

  void createDataListener() {
    dataSubscription = _socket.onMatchData.listen((data) {
      Map<String, dynamic> message;
      final content = utf8.decode(data.data);
      if (kDebugMode) {
        print(
            'User ${data.presence.userId} sent $content with code ${data.opCode}');
      }
      final jsonContent = jsonDecode(content) as Map<String, dynamic>;
      switch (data.opCode) {
        //Someone asked who is in lobby
        case 1:
          message = {'Username': username, "IsHost": _isHost};
          Player? newPlayer;
          for (var user in connectedUsers) {
            if (user.displayName != jsonContent["Username"]) {
              newPlayer = Player(
                isMe: false,
                isHost:
                    jsonContent["IsHost"].toString().toLowerCase() == 'true',
                displayName: jsonContent["Username"] as String,
                isReady: false,
              );
              break;
            }
          }
          if (newPlayer != null) {
            connectedUsers.add(newPlayer);
            notifyListeners();
          }

          sendMessage(2, message);
          break;
        //Someone told me it is in the lobby
        case 2:
          connectedUsers.add(Player(
            isMe: false,
            isHost: jsonContent["IsHost"].toString().toLowerCase() == 'true',
            displayName: jsonContent["Username"] as String,
            isReady: false,
          ));
          notifyListeners();
        //Leave match
        case 3:
          connectedUsers.removeWhere(
              (element) => element.displayName == jsonContent["Username"]);
          if (jsonContent["IsHost"].toString().toLowerCase() == 'true') {
            connectedUsers
                .sort((a, b) => a.displayName.compareTo(b.displayName));
            connectedUsers[0].isHost = true;
            if (connectedUsers[0].displayName == username) {
              _isHost = true;
            }
          }
          notifyListeners();
          break;
        //Game has started
        case 4:
          _uiStreamController.sink.add('{"Command":"GAME_STARTED"}');
          //start game on watch
          startGame();
          break;
        //HeartRate data from other people
        case 5:
          var username = jsonContent["Username"] as String;
          var heartRate = double.parse(jsonContent["HeartRate"] as String);
          if (!allReady) {
            var playersReady = 0;
            for (var player in connectedUsers) {
              if (player.displayName == username) {
                player.isReady = true;
              }
              if (player.isReady) {
                playersReady = playersReady + 1;
              }
            }
            if (playersReady < connectedUsers.length) {
              break;
            }
            allReady = true;
            heartRateFullData.forEach((key, list) {
              if (list.isNotEmpty) {
                list = [list.last];
              } else {
                list = [];
              }
            });
            heartRateFullData[username] = [heartRate];
            _startOfPlay = DateTime.now();
          }

          _uiStreamController.sink.add(
              '{"Command":"HEART_RATE","Username":"$username","HeartRate":"$heartRate"}');
          if (heartRateFullData.keys.contains(username)) {
            heartRateFullData[username]!.add(heartRate);
          } else {
            heartRateFullData[username] = [heartRate];
          }
          if (_isHost) {
            if (hasGameEnded(username, heartRate)) {
              endGame(
                  username, DateTime.now().difference(_startOfPlay).inSeconds);
            }
          }
          break;
        //Game ended, user xxx has lost
        case 6:
          var username = jsonContent["Username"] as String;
          var duration = jsonContent["Duration"] as int;
          _uiStreamController.sink.add(
              '{"Command":"END_GAME","Username":"$username","Duration":"$duration"}');
          for (Player user in connectedUsers) {
            user.isReady = false;
          }
          var message = {'Command': 'END_GAME'};
          _watch.sendMessage(message);
        default:
          _log.fine(() =>
              'User ${data.presence.username} sent $content and code ${data.opCode}');
      }
    });
  }

  void createWatchListener() {
    _watch.messageStream.listen((e) {
      // print("Whole: $e");
      // print("Bool: ${e.containsKey("HeartRate")}");
      // print("Type: ${e["HeartRate"].runtimeType}");
      // print("Value: ${e["HeartRate"]}");
      // print("Len Data: ${hearRateData.length}");
      // print("Len FullData: ${hearRateFullData.length}");
      var heartRate = e["HeartRate"] as double;
      heartRate = double.parse(heartRate.toStringAsFixed(0));
      if (heartRate != 0.0) {
        if (startHeartRate == 0) {
          startHeartRate = heartRate;
        }

        sendMessage(5, {
          "Command": "HEART_RATE",
          "Username": username,
          "HeartRate": "$heartRate"
        });
        if (!allReady) {
          var playersReady = 0;
          for (var player in connectedUsers) {
            if (player.displayName == username) {
              player.isReady = true;
            }
            if (player.isReady) {
              playersReady = playersReady + 1;
            }
          }
          if (playersReady < connectedUsers.length) {
            return;
          }
          allReady = true;
          heartRateFullData.forEach((key, list) {
            if (list.isNotEmpty) {
              list = [list.last];
            } else {
              list = [];
            }
          });
          heartRateFullData[username] = [heartRate];
          _startOfPlay = DateTime.now();
        }
        currentHeartRate = heartRate;
        if (heartRateFullData.keys.contains(username)) {
          heartRateFullData[username]!.add(heartRate);
        } else {
          heartRateFullData[username] = [heartRate];
        }

        _uiStreamController.sink.add(
            '{"Command":"HEART_RATE","Username":"$username","HeartRate":"$heartRate"}');
        if (_isHost) {
          if (hasGameEnded(username, heartRate)) {
            endGame(
                username, DateTime.now().difference(_startOfPlay).inSeconds);
          }
        }
      }
    });
  }

  void startGame() {
    var message = {'Command': 'START_GAME'};
    _watch.sendMessage(message);
    _startOfPlay = DateTime.now();
    for (Player user in connectedUsers) {
      heartRateFullData[user.displayName] = [];
      user.isReady = false;
    }
    allReady = false;
  }

  bool hasGameEnded(String username, double heartRate) {
    if (connectedUsers.length == 1) {
      return true;
    }
    if (heartRateFullData[username]![0] + threshold < heartRate ||
        heartRateFullData[username]![0] - threshold > heartRate) {
      return true;
    }
    return false;
  }

  void endGame(String username, int duration) {
    var message = {'Command': 'END_GAME'};
    Player? winningPlayer;
    _watch.sendMessage(message);
    for (Player user in connectedUsers) {
      if (user.displayName != username) {
        winningPlayer = user;
        user.isReady = false;
      }
    }
    allReady = false;

    winningPlayer ??= Player(
        isMe: false, isHost: false, displayName: "No one", isReady: false);

    sendMessage(
        6, {'Username': winningPlayer.displayName, 'Duration': duration});
    _uiStreamController.sink.add(
        '{"Command":"END_GAME","Username":"${winningPlayer.displayName}","Duration":"$duration"}');
  }

  double getStartHeartRateOfUsername(String username) {
    if (heartRateFullData[username]!.isEmpty) {
      return 0;
    }
    return heartRateFullData[username]![0];
  }

  bool getHost() {
    return _isHost;
  }

  Future<void> leaveMatch() async {
    var message = {'Username': username, "IsHost": _isHost};
    sendMessage(3, message);

    await _socket.leaveMatch(_match.matchId);
    if (kDebugMode) {
      print('Left match with id: ${_match.matchId}');
    }
    await dataSubscription.cancel();

    connectedUsers = [];
    notifyListeners();
  }

  void sendMessage(int opcode, Map<String, dynamic> data) {
    _socket.sendMatchData(
      matchId: _match.matchId,
      opCode: Int64(opcode),
      data: utf8.encode(jsonEncode(data)),
    );
  }

  void setUsername(String username) {
    this.username = username;
    notifyListeners();
  }

  void setLobbyCode(String code) {
    lobbyCode = code.toUpperCase();
    notifyListeners();
  }
}

class Player {
  final String displayName;
  final bool isMe;
  bool isHost;
  bool isReady;

  Player(
      {required this.isMe,
      required this.isHost,
      required this.displayName,
      required this.isReady});
}
