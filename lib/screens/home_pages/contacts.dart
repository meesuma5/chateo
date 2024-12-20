import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final userListController = StreamUserListController(
      client: StreamChatCore.of(context).client,
      filter: Filter.and([
        Filter.notEqual('id', context.user!.id),
        Filter.notEqual('role', 'admin'),
      ]));
  @override
  void initState() {
    userListController.doInitialLoad();
    super.initState();
  }

  @override
  void dispose() {
    userListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedValueListenableBuilder<int, User>(
      valueListenable: userListController,
      builder: (context, value, child) {
        return value.when(
          (users, nextPageKey, error) => LazyLoadScrollView(
            onEndOfPage: () async {
              if (nextPageKey != null) {
                userListController.loadMore(nextPageKey);
              }
            },
            child: ListView.builder(
              /// We're using the users length when there are no more
              /// pages to load and there are no errors with pagination.
              /// In case we need to show a loading indicator or and error
              /// tile we're increasing the count by 1.
              itemCount: (nextPageKey != null || error != null)
                  ? users.length + 1
                  : users.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == users.length) {
                  if (error != null) {
                    return TextButton(
                      onPressed: () {
                        userListController.retry();
                      },
                      child: Text(error.message),
                    );
                  }
                  return const CircularProgressIndicator();
                }

                final _user = users[index];
                return _ContactTile(
                  user: _user,
                );
              },
            ),
          ),
          loading: () => Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: SpinKitChasingDots(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          error: (e) => Center(
            child: Text(
              'Oh no, something went wrong. '
              'Please check your config. $e',
            ),
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.user,
  });
  final User user;
  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  void createChannel(BuildContext context) async {
    final core = StreamChatCore.of(context);
    final channel = core.client.channel('messaging', extraData: {
      'members': [core.currentUser!.id, widget.user.id],
    });
    await channel.watch();
    Navigator.pushNamed(context, '/chat', arguments: channel);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Card(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            createChannel(context);
          },
          splashColor: Theme.of(context).primaryColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Avatar.medium(imageUrl: widget.user.image ?? genericUrl),
                const SizedBox(width: 16),
                Text(
                  widget.user.name.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
