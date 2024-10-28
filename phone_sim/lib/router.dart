// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:multiplayer/play_session/create_user_session.dart';
import 'package:multiplayer/play_session/game_screen.dart';
import 'package:multiplayer/play_session/join_lobby_session.dart';
import 'package:multiplayer/win_game/score.dart';
import 'package:multiplayer/win_game/win_game_screen.dart';
import 'package:provider/provider.dart';

import 'main_menu/main_menu_screen.dart';
import 'play_session/play_session_screen.dart';
import 'settings/settings_screen.dart';
import 'style/my_transition.dart';
import 'style/palette.dart';

/// The router describes the game's navigational hierarchy, from the main
/// screen through settings screens all the way to each individual level.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(key: Key('main menu')),
      routes: [
        GoRoute(
          path: 'play',
          pageBuilder: (context, state) => buildMyTransition<void>(
            key: const ValueKey('play'),
            color: context.watch<Palette>().backgroundPlaySession,
            child: CreateUserSession(
              key: Key('level selection'),
            ),
          ),
          routes: [
            GoRoute(
              path: 'room',
              pageBuilder: (context, state) {

                return buildMyTransition<void>(
                  key: const ValueKey('room'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: PlaySessionRoomScreen(
                    key: const Key('Room'),
                  ),
                );
              },
            ),
            GoRoute(
              path: 'joinRoom',
              pageBuilder: (context, state) {
                return buildMyTransition<void>(
                  key: const ValueKey('joinRoom'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: JoinLobbySession(
                    key: const Key('Join Lobby'),
                  ),
                );
              },
            ),
            GoRoute(
              path: 'game',
              pageBuilder: (context, state) {
                return buildMyTransition<void>(
                  key: const ValueKey('game'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: GameScreen(
                    key: const Key('Game'),
                  ),
                );
              },
            ),
            GoRoute(
              path: 'won',
              redirect: (context, state) {
                if (state.extra == null) {
                  // Trying to navigate to a win screen without any data.
                  // Possibly by using the browser's back button.
                  return '/';
                }

                // Otherwise, do not redirect.
                return null;
              },
              pageBuilder: (context, state) {
                final map = state.extra! as Map<String, dynamic>;
                final score = map['score'] as Score;

                return buildMyTransition<void>(
                  key: const ValueKey('won'),
                  color: context.watch<Palette>().backgroundPlaySession,
                  child: WinGameScreen(
                    score: score,
                    key: const Key('win game'),
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),
      ],
    ),
  ],
);
