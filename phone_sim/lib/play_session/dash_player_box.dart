//Retirado de https://github.com/imaNNeo/flappy_dash

import 'package:flutter/material.dart';

class DashPlayerBox extends StatelessWidget {
  const DashPlayerBox({
    super.key,
    required this.playerName,
    required this.isMe,
    required this.isHost,
  });

  final String playerName;
  final bool isMe;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final boxWidth = constraints.maxWidth;
      final iconSize = boxWidth * 0.25;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
           10,
          ),
          border: Border.all(
            color: isMe ? Colors.red.shade600 : Colors.black45,
            width: 2,
          ),
        ),
        child: Row(
          children: [
              
            SizedBox(width: boxWidth * 0.04),
            Icon(
                isHost? Icons.star : Icons.person,
                color: Colors.yellow.shade600,
                size: iconSize,
              ),
            SizedBox(width: boxWidth * 0.04),
            Expanded(
              child: Text(
                playerName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: boxWidth * 0.12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
