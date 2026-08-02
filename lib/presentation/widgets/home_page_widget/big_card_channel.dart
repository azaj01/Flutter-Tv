import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/theme/app_colors.dart';

/// Menu tile for a channel group.
///
/// Everything inside is bounded: the icon gets a fixed box so tiles line up
/// with each other, and both text rows can shrink. The previous version sized
/// the count row with no flex, which overflowed the tile as soon as a group had
/// five-digit counts — "10469 Channels" needs more width than a half-screen
/// tile has.
class BigCardChannels extends StatelessWidget {
  const BigCardChannels({
    required this.icon,
    required this.text,
    required this.channelsCount,
    super.key,
    this.isLiveCard = false,
  });

  static const double _iconExtent = 40;

  final String icon;
  final String text;
  final int channelsCount;
  final bool isLiveCard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: _iconExtent,
              width: _iconExtent,
              child: SvgPicture.asset(icon),
            ),
            _Title(text: text, isLiveCard: isLiveCard),
            _CountRow(count: channelsCount, isLiveCard: isLiveCard),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.isLiveCard});

  final String text;
  final bool isLiveCard;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 19, color: Colors.white);

    if (!isLiveCard) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    // "Live Tv" renders the first word as a badge; fall back to plain text if
    // the title is ever a single word.
    final words = text.split(' ');
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: Colors.red,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 7),
            child: Text(
              words.first,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (words.length > 1) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              words.sublist(1).join(' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.count, required this.isLiveCard});

  final int count;
  final bool isLiveCard;

  @override
  Widget build(BuildContext context) {
    // Grey reads as "nothing here", which is the only state worth signalling.
    final dotColor = count == 0
        ? Colors.grey
        : isLiveCard
            ? Colors.redAccent
            : kPurple;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${NumberFormat.decimalPattern().format(count)} Channels',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
