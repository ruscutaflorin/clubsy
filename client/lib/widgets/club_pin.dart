import 'package:flutter/material.dart';

import 'package:clubsy/data/classes/club_model.dart';

/// A map pin for [club]; with [nights] of 2 or more it carries a count badge.
class ClubPin extends StatelessWidget {
  final ClubModel club;
  final bool isVisited;
  final int nights;
  final VoidCallback onTap;

  const ClubPin({
    super.key,
    required this.club,
    required this.isVisited,
    required this.nights,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 40,
            color: isVisited ? Colors.green : Colors.redAccent,
          ),
          if (nights >= 2)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                key: Key('pinCount_${club.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                alignment: Alignment.center,
                child: Text(
                  nights > 99 ? '99+' : '$nights',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
