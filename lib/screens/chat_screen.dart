import 'package:Chateo/helpers/helpers.dart';
import 'package:Chateo/theme.dart';
import 'package:jiffy/jiffy.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';
import 'package:collection/collection.dart' show IterableExtension;
import '../widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';

import '../constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final channel = ModalRoute.of(context)!.settings.arguments as Channel;
    return StreamChannel(
      channel: channel,
      child: Scaffold(
          appBar: AppBar(
            leading: Align(
              alignment: Alignment.centerRight,
              child: Avatar.medium(
                  imageUrl: getChannelImage(channel, context.user!)),
            ),
            title: _AppBarTitle(channel: channel),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButtonBorder(
                    onPressed: () {}, icon: CupertinoIcons.video_camera),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
                child: IconButtonBorder(
                    onPressed: () {}, icon: CupertinoIcons.phone),
              ),
            ],
          ),
          body: const Column(
            children: [Expanded(child: _MessageList()), _ActionBar()],
          )),
    );
  }
  // Widget getStatus(Channel channel, User user){
  // 	BetterStreamBuilder<List<Member>>()
  // }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    super.key,
    required this.channel,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getChannelName(channel, context.user!),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            // getStatus(channel, context.user!),
            BetterStreamBuilder<List<Member>>(
              stream: channel.state!.membersStream,
              initialData: channel.state!.members,
              builder: (context, data) => ConnectionStatusBuilder(
                statusBuilder: (context, status) {
                  switch (status) {
                    case ConnectionStatus.connected:
                      return _buildConnectedTitleState(context, data);
                    case ConnectionStatus.connecting:
                      return Text(
                        'Connecting',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      );
                    case ConnectionStatus.disconnected:
                      return Text(
                        'Offline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.errorColor,
                            ),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectedTitleState(
    BuildContext context,
    List<Member>? members,
  ) {
    Widget? alternativeWidget;
    final channel = StreamChannel.of(context).channel;
    final memberCount = channel.memberCount;
    if (memberCount != null && memberCount > 2) {
      var text = 'Members: $memberCount';
      final watcherCount = channel.state?.watcherCount ?? 0;
      if (watcherCount > 0) {
        text = 'watchers $watcherCount';
      }
      alternativeWidget = Text(
        text,
      );
    } else {
      final userId = StreamChatCore.of(context).currentUser?.id;
      final otherMember = members?.firstWhereOrNull(
        (element) => element.userId != userId,
      );

      if (otherMember != null) {
        if (otherMember.user?.online == true) {
          alternativeWidget = Text(
            'Online',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          );
        } else {
          late final String time;
          try {
            time = Jiffy.parseFromDateTime(otherMember.user!.lastActive!)
                .fromNow();
          } catch (e) {
            time = 'Long Time Ago';
            logger.e(e);
          }
          alternativeWidget = Text(
            'Last online: '
            '$time',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColorDark,
                ),
          );
        }
      }
    }

    return TypingIndicator(
      alternativeWidget: alternativeWidget,
    );
  }
}

class ConnectionStatusBuilder extends StatelessWidget {
  /// Creates a new ConnectionStatusBuilder
  const ConnectionStatusBuilder({
    Key? key,
    required this.statusBuilder,
    this.connectionStatusStream,
    this.errorBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  /// The asynchronous computation to which this builder is currently connected.
  final Stream<ConnectionStatus>? connectionStatusStream;

  /// The builder that will be used in case of error
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  /// The builder that will be used in case of loading
  final WidgetBuilder? loadingBuilder;

  /// The builder that will be used in case of data
  final Widget Function(BuildContext context, ConnectionStatus status)
      statusBuilder;

  @override
  Widget build(BuildContext context) {
    final stream = connectionStatusStream ??
        StreamChatCore.of(context).client.wsConnectionStatusStream;
    final client = StreamChatCore.of(context).client;
    return BetterStreamBuilder<ConnectionStatus>(
      initialData: client.wsConnectionStatus,
      stream: stream,
      noDataBuilder: loadingBuilder,
      errorBuilder: (context, error) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error);
        }
        return const Offstage();
      },
      builder: statusBuilder,
    );
  }
}

class TypingIndicator extends StatelessWidget {
  /// Instantiate a new TypingIndicator
  const TypingIndicator({
    super.key,
    this.alternativeWidget,
  });

  /// Widget built when no typings is happening
  final Widget? alternativeWidget;

  @override
  Widget build(BuildContext context) {
    final channelState = StreamChannel.of(context).channel.state!;

    final altWidget = alternativeWidget ?? const SizedBox.shrink();

    return BetterStreamBuilder<Iterable<User>>(
      initialData: channelState.typingEvents.keys,
      stream: channelState.typingEventsStream
          .map((typings) => typings.entries.map((e) => e.key)),
      builder: (context, data) {
        return Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: data.isNotEmpty == true
                ? Align(
                    alignment: Alignment.centerLeft,
                    key: ValueKey('typing-text'),
                    child: Text(
                      'Typing message',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    key: const ValueKey('altwidget'),
                    child: altWidget,
                  ),
          ),
        );
      },
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList();

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: ListView(
        children: const [
          DateLabel(label: "Yesterday"),
          _Message(message: "Hi Meesum", date: "21/7/23"),
          _Message(message: "Hello there", date: "21/7/23", byMe: true),
          _Message(
              message:
                  "I have heard that you are developing a stupid chat application",
              date: "21/7/23"),
          _Message(message: "How's it going?", date: "21/7/23"),
          _Message(
            message:
                "Ahhh yess, Chateo. It is such a wonderful app and the Ui is almost ready. this is the last thing I need to complete",
            date: "21/7/23",
            byMe: true,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  final String date;
  final bool byMe;
  static const double radius = 16;
  const _Message(
      {required this.message, required this.date, this.byMe = false});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Align(
      alignment: byMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            byMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: byMe
                ? BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(radius),
                      bottomLeft: Radius.circular(radius),
                      topLeft: Radius.circular(radius),
                    ),
                  )
                : BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(radius),
                      bottomLeft: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: (screenWidth * (2 / 3))),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  message,
                  style: byMe
                      ? Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: kWhite)
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              date,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          )
        ],
      ),
    );
  }
}

class DateLabel extends StatelessWidget {
  const DateLabel({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatefulWidget {
  const _ActionBar();

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: screenWidth),
      child: Container(
        color: Theme.of(context).cardColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton2(
                      onPressed: () {
                        logger.i('Camera');
                      },
                      icon: CupertinoIcons.camera_fill),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      height: 30,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2.5),
                      decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(24))),
                      child: TextField(
                        textAlign: TextAlign.left,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type Something...',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: Theme.of(context).disabledColor)),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GlowingActionButton(
                      size: 30,
                      color: const Color(0xFF7BCBCF),
                      icon: Icons.send_rounded,
                      onPressed: () {
                        print('send');
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
