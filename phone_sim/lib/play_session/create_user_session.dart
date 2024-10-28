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

class CreateUserSession extends StatefulWidget {
  const CreateUserSession({super.key});

  @override
  State<CreateUserSession> createState() => _CreateUserSession();
}

class _CreateUserSession extends State<CreateUserSession> {
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
              'Create User Name',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 55,
                height: 1,
              ),
            ),
            _gap,
            TextField(
              controller: textController,
              autofocus: true,
              maxLength: 12,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
            ),
            _gap,
            // MyButton(
            //   onPressed: () async {
            //     audioController.playSfx(SfxType.buttonTap);
            //     playerController.setUsername(textController.text);
            //     await playerController.createPlayerSession();
            //     await playerController.createMatch();
            //     if (context.mounted) {
            //       GoRouter.of(context).go('/play/room');
            //     }
            //   },
            //   child: const Text('Create Lobby'),
            // ),
            // _gap,
            MyButton(
              onPressed: () async {
                audioController.playSfx(SfxType.buttonTap);
                playerController.setUsername(textController.text);
                await playerController.createPlayerSession();
                if (context.mounted) {
                  GoRouter.of(context).go('/play/joinRoom');
                }
              },
              child: const Text('Create User'),
            ),
            _gap,
          ],
        ),
        rectangularMenuArea: Container(), // Add appropriate widget here
      ),
    );
  }
}
