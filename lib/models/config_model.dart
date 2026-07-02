class SongMasterItem {
  dynamic
  count; // Can be int (e.g. 24) or String (e.g. "Vinayagar Suprabatham")
  String code; // e.g. "hr", "mo"
  String folder; // e.g. "SS", "VO"
  String mode; // "SYS" or "CUS"
  String name; // Localized name/label

  SongMasterItem({
    required this.count,
    required this.code,
    required this.folder,
    required this.mode,
    required this.name,
  });

  factory SongMasterItem.fromList(List<dynamic> list) {
    return SongMasterItem(
      count: list.isNotEmpty ? list[0] : 0,
      code: list.length > 1 ? list[1]?.toString() ?? '' : '',
      folder: list.length > 2 ? list[2]?.toString() ?? '' : '',
      mode: list.length > 3 ? list[3]?.toString() ?? '' : '',
      name: list.length > 4 ? list[4]?.toString() ?? '' : '',
    );
  }

  List<dynamic> toList() {
    return [count, code, folder, mode, name];
  }

  SongMasterItem copyWith({
    dynamic id,
    String? code,
    String? category,
    String? source,
    String? name,
  }) {
    return SongMasterItem(
      count: id ?? this.count,
      code: code ?? this.code,
      folder: category ?? this.folder,
      mode: source ?? this.mode,
      name: name ?? this.name,
    );
  }
}

class AlarmConfig {
  String tit;
  String? id;
  bool state;
  List<dynamic> tim;
  List<int> sc;
  String type;

  AlarmConfig({
    required this.tit,
    this.id,
    required this.state,
    required this.tim,
    required this.sc,
    required this.type,
  });

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      tit: json['tit'] ?? '',
      id: json['id'],
      state: json['state'] ?? false,
      tim: List<dynamic>.from(json['tim'] ?? []),
      sc: List<int>.from(json['SC'] ?? []),
      type: json['type'] ?? 'time',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tit': tit,
      'id': id,
      'state': state,
      'tim': tim,
      'SC': sc,
      'type': type,
    };
  }

  // Helpers for extracting scheduler components from `tim`
  List<int> get minutes => List<int>.from(tim.isNotEmpty ? tim[0] : [0, 0]);

  List<List<int>> get hourRanges {
    if (tim.length < 2) return [];
    return (tim[1] as List).map((e) => List<int>.from(e)).toList();
  }

  List<List<int>> get dayOfMonthRanges {
    if (tim.length < 3)
      return [
        [1, 31],
      ];
    return (tim[2] as List).map((e) => List<int>.from(e)).toList();
  }

  List<List<int>> get monthRanges {
    if (tim.length < 4)
      return [
        [1, 12],
      ];
    return (tim[3] as List).map((e) => List<int>.from(e)).toList();
  }

  List<int> get weekdays {
    if (tim.length < 5) return [1, 2, 3, 4, 5, 6, 7];
    return List<int>.from(tim[4]);
  }

  List<int> get extra {
    if (tim.length < 6) return [0];
    return List<int>.from(tim[5]);
  }

  int get endHour {
    final ranges = hourRanges;
    if (ranges.isEmpty) return 0;
    int maxHr = 0;
    for (final r in ranges) {
      if (r.isNotEmpty && r.last > maxHr) {
        maxHr = r.last;
      }
    }
    return maxHr;
  }

  int get endMinute {
    final mins = minutes;
    return mins.length >= 2 ? mins[1] : 0;
  }

  int get endTimeInMinutes => endHour * 60 + endMinute;

  // Setters to update schedule components
  void updateSchedule({
    List<int>? minutes,
    List<List<int>>? hourRanges,
    List<List<int>>? dayOfMonthRanges,
    List<List<int>>? monthRanges,
    List<int>? weekdays,
    List<int>? extra,
  }) {
    final newMinutes = minutes ?? this.minutes;
    final newHourRanges = hourRanges ?? this.hourRanges;
    final newDayOfMonthRanges = dayOfMonthRanges ?? this.dayOfMonthRanges;
    final newMonthRanges = monthRanges ?? this.monthRanges;
    final newWeekdays = weekdays ?? this.weekdays;
    final newExtra = extra ?? this.extra;

    tim = [
      newMinutes,
      newHourRanges,
      newDayOfMonthRanges,
      newMonthRanges,
      newWeekdays,
      newExtra,
    ];
  }

  AlarmConfig copyWith({
    String? tit,
    String? id,
    bool? state,
    List<dynamic>? tim,
    List<int>? sc,
    String? type,
  }) {
    return AlarmConfig(
      tit: tit ?? this.tit,
      id: id ?? this.id,
      state: state ?? this.state,
      tim: tim ?? List<dynamic>.from(this.tim),
      sc: sc ?? List<int>.from(this.sc),
      type: type ?? this.type,
    );
  }
}

class Playlist {
  String name;
  List<int> sc;

  Playlist({required this.name, required this.sc});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      name: json['name'] ?? '',
      sc: List<int>.from(json['SC'] ?? json['tracks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'SC': sc};
  }

  Playlist copyWith({String? name, List<int>? sc}) {
    return Playlist(name: name ?? this.name, sc: sc ?? List<int>.from(this.sc));
  }
}

class Config {
  List<AlarmConfig> alarmConfig;
  List<dynamic> silentHours; // Can contain range lists like [start, end]
  List<SongMasterItem> songMaster;
  List<Playlist> playlists;

  Config({
    required this.alarmConfig,
    required this.silentHours,
    required this.songMaster,
    required this.playlists,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      alarmConfig: (json['AlarmConfig'] as List? ?? [])
          .map((e) => AlarmConfig.fromJson(e))
          .toList(),
      silentHours: List<dynamic>.from(json['silentHours'] ?? []),
      songMaster: (json['SongMaster'] as List? ?? [])
          .map((e) => SongMasterItem.fromList(e))
          .toList(),
      playlists: (json['Playlists'] as List? ?? [])
          .map((e) => Playlist.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AlarmConfig': alarmConfig.map((e) => e.toJson()).toList(),
      'silentHours': silentHours,
      'SongMaster': songMaster.map((e) => e.toList()).toList(),
      'Playlists': playlists.map((e) => e.toJson()).toList(),
    };
  }

  Config copyWith({
    List<AlarmConfig>? alarmConfig,
    List<dynamic>? silentHours,
    List<SongMasterItem>? songMaster,
    List<Playlist>? playlists,
  }) {
    return Config(
      alarmConfig: alarmConfig ?? this.alarmConfig,
      silentHours: silentHours ?? this.silentHours,
      songMaster: songMaster ?? this.songMaster,
      playlists: playlists ?? this.playlists,
    );
  }
}
