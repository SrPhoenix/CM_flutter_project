// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encapsulates a score and the arithmetic to compute it.
class Score {

  final String duration;

  final String playerName;

  factory Score(String playerName, Duration duration) {
    final buf = StringBuffer();
    if (duration.inHours > 0) {
      buf.write('${duration.inHours}');
      buf.write(':');
    }
    final minutes = duration.inMinutes % Duration.minutesPerHour;
    if (minutes > 9) {
      buf.write('$minutes');
    } else {
      buf.write('0');
      buf.write('$minutes');
    }
    buf.write(':');
    buf.write((duration.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0'));

    return Score._( buf.toString(), playerName);
  }

  // ignore: non_constant_identifier_names
  factory Score.DurationString(String playerName, double score, String duration) {

    return Score._(duration, playerName);
  }


  const Score._(this.duration, this.playerName);


  @override
  String toString() => 'Score<$duration,$playerName>';
}
