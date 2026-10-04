/// One row of the friends list or of a pending request: the other user plus
/// the friendship id used for accept / decline / cancel / unfriend.
class FriendEntry {
  final String id;
  final String userId;
  final String? username;
  final String name;

  const FriendEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.name,
  });

  factory FriendEntry.fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>;
    return FriendEntry(
      id: map['id'] as String,
      userId: user['id'] as String,
      username: user['username'] as String?,
      name: (user['name'] as String?) ?? '',
    );
  }

  String get label => username != null ? '@$username' : name;
}

class FriendsOverview {
  final List<FriendEntry> friends;
  final List<FriendEntry> incoming;
  final List<FriendEntry> outgoing;

  const FriendsOverview({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  factory FriendsOverview.fromMap(Map<String, dynamic> map) {
    List<FriendEntry> parse(String key) => ((map[key] as List?) ?? [])
        .map((e) => FriendEntry.fromMap(e as Map<String, dynamic>))
        .toList();
    return FriendsOverview(
      friends: parse('friends'),
      incoming: parse('incoming'),
      outgoing: parse('outgoing'),
    );
  }
}
