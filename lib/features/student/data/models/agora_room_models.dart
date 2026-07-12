class AgoraRoomDto {
  const AgoraRoomDto({
    required this.channel,
    required this.uid,
    required this.token,
    required this.appId,
    required this.expireAt,
    this.participantNames = const {},
  });

  factory AgoraRoomDto.fromJson(Map<String, dynamic> j) => AgoraRoomDto(
    channel: j['channel'] as String? ?? '',
    uid: j['uid'] as String? ?? '',
    token: j['token'] as String? ?? '',
    appId: j['appId'] as String? ?? '',
    expireAt: (j['expireAt'] as num?)?.toInt() ?? 0,
    participantNames:
        (j['participantNames'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String? ?? ''),
        ) ??
        const {},
  );

  final String channel;

  final String uid;
  final String token;
  final String appId;

  /// Unix seconds when the token expires.
  final int expireAt;
  final Map<String, String> participantNames;

  bool get isValid =>
      appId.isNotEmpty && channel.isNotEmpty && token.isNotEmpty;
}
