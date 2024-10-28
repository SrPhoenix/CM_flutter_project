// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/audio/audio_controller.dart';
import 'package:multiplayer/audio/sounds.dart';
import 'package:multiplayer/play_session/player_controller.dart';
import 'package:provider/provider.dart';

import '../style/my_button.dart';
import '../style/palette.dart';
import '../style/responsive_screen.dart';

class JoinLobbySession extends StatefulWidget {
  const JoinLobbySession({super.key});

  @override
  State<JoinLobbySession> createState() => _JoinLobbySession();
}

class _JoinLobbySession extends State<JoinLobbySession> {
  static const _gap = SizedBox(height: 60);
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final playerController = context.watch<PlayerController>();
    final audioController = context.watch<AudioController>();

    return Scaffold(
      backgroundColor: palette.backgroundSettings,
      body: ResponsiveScreen(
        squarishMainArea: ListView(
          children: [
            _gap,
            const Text(
              'Join Lobby',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 55,
                height: 1,
              ),
            ),
            _gap,
            const Text(
              'Insert Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 25,
                height: 1,
              ),
            ),
            _gap,
            
            TextField(
              controller: textController,
              maxLength: 12,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
            _gap,
            MyButton(
              onPressed: () async {
                audioController.playSfx(SfxType.buttonTap);
                await playerController.createMatch();
                if (context.mounted) {
                  GoRouter.of(context).go('/play/room');
                }
              },
              child: const Text('Create Lobby'),
            ),
            _gap,
            MyButton(
              onPressed: () async {
                audioController.playSfx(SfxType.buttonTap);
                playerController.setLobbyCode(textController.text);
                await playerController.joinMatch();
                if (context.mounted) {
                  GoRouter.of(context).go('/play/Room');
                }
              },
              child: const Text('Join Lobby'),
            ),
            _gap,
          ],
        ),
        rectangularMenuArea: Container(), // Add appropriate widget here
      ),
    );
  }
}
