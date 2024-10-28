// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:multiplayer/play_session/player_controller.dart';
import 'package:provider/provider.dart';

import '../style/score.dart';
import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class WinGameScreen extends StatelessWidget {
  final Score score;

  const WinGameScreen({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerController = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();

    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: palette.backgroundPlaySession,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            gap,
            Center(
              child: Text(
                '${score.playerName} won!',
                style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
              ),
            ),
            gap,
            Center(
              child: Text(
                'Time: ${score.duration}',
                style: const TextStyle(
                    fontFamily: 'Permanent Marker', fontSize: 20),
              ),
            ),
            gap,
            MyButton(
              onPressed: () async {
                audioController.playSfx(SfxType.buttonTap);
                GoRouter.of(context).go('/play/room');
              },
              child: const Text('Return to Lobby'),
            ),
          ],
        ),
        rectangularMenuArea: MyButton(
          onPressed: () {
            playerController.leaveMatch();
            GoRouter.of(context).go('/play/joinRoom');
          },
          child: const Text('Leave Lobby'),
        ),
      ),
    );
  }
}
