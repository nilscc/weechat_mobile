import 'package:flutter/material.dart';

typedef ColorCodes = Map<int, Color>;

final ColorCodes defaultColorCodes = {
  1: Colors.black,
  2: Colors.grey.shade800,
  3: Colors.red.shade900,
  4: Colors.red.shade400,
  5: Colors.green.shade800,
  6: Colors.green.shade400,
  7: Colors.brown,
  8: Colors.yellow,
  9: Colors.blue.shade800,
  10: Colors.lightBlue,
  11: Colors.pink.shade800,
  12: Colors.pink.shade400,
  13: Colors.cyan.shade800,
  14: Colors.cyan.shade400,
  15: Colors.grey,
  16: Colors.white,
};

const _default = null;

final
    //_black = colorCodes[1],
    //_darkgray = colorCodes[2],
    _darkred = 3,
    _red = _darkred,
    _lightred = 4,
    _darkgreen = 5,
    _green = _darkgreen,
    _lightgreen = 6,
    _brown = 7,
    _yellow = 8,
    _darkblue = 9,
    _blue = _darkblue,
    // _lightblue = 10,
    _darkmagenta = 11,
    _magenta = _darkmagenta,
    _lightmagenta = 12,
    _darkcyan = 13,
    _cyan = _darkcyan,
    _lightcyan = 14,
    // _gray = 15,
    _white = 16;

// Color options taken from:
// https://weechat.org/files/doc/stable/weechat_dev.en.html#color_codes_in_strings
// Colors for options are default colors taken straight from iset summary.
final _colorOptions = {
  // 'weechat.color.bar_more': _lightmagenta,
  1: {'weechat.color.chat': _default},
  // 'weechat.color.chat_bg': _default,
  11: {'weechat.color.chat_buffer': _white},
  13: {'weechat.color.chat_channel': _white},
  43: {'weechat.color.chat_day_change': _cyan},
  28: {'weechat.color.chat_delimiters': _green},
  29: {'weechat.color.chat_highlight': _yellow},
  // 'weechat.color.chat_highlight_bg': _magenta,
  27: {'weechat.color.chat_host': _cyan},
  36: {'weechat.color.chat_inactive_buffer': _default},
  35: {'weechat.color.chat_inactive_window': _default},
  14: {'weechat.color.chat_nick': _lightcyan},
  //'weechat.color.chat_nick_colors': [_cyan,_magenta,_green,_brown,_lightblue,_default,_lightcyan,_lightmagenta,_lightgreen,_blue],
  38: {'weechat.color.chat_nick_offline': _default},
  39: {'weechat.color.chat_nick_offline_highlight': _default},
  // 'weechat.color.chat_nick_offline_highlight_bg': _blue,
  16: {'weechat.color.chat_nick_other': _cyan},
  40: {'weechat.color.chat_nick_prefix': _green},
  15: {'weechat.color.chat_nick_self': _white},
  41: {'weechat.color.chat_nick_suffix': _green},
  6: {'weechat.color.chat_prefix_action': _white},
  33: {'weechat.color.chat_prefix_buffer': _brown},
  // 'weechat.color.chat_prefix_buffer_inactive_buffer': _default,
  4: {'weechat.color.chat_prefix_error': _yellow},
  7: {'weechat.color.chat_prefix_join': _lightgreen},
  9: {'weechat.color.chat_prefix_more': _lightmagenta},
  5: {'weechat.color.chat_prefix_network': _magenta},
  8: {'weechat.color.chat_prefix_quit': _lightred},
  10: {'weechat.color.chat_prefix_suffix': _green},
  30: {'weechat.color.chat_read_marker': _magenta},
  // 'weechat.color.chat_read_marker_bg': _default,
  12: {'weechat.color.chat_server': _brown},
  34: {'weechat.color.chat_tags': _red},
  31: {'weechat.color.chat_text_found': _yellow},
  // 'weechat.color.chat_text_found_bg': _lightmagenta,
  2: {'weechat.color.chat_time': _default},
  3: {'weechat.color.chat_time_delimiters': _brown},
  32: {'weechat.color.chat_value': _cyan},
  44: {'weechat.color.chat_value_null': _blue},
  42: {'weechat.color.emphasized': _yellow},
  // 'weechat.color.emphasized_bg': _magenta,
  // 'weechat.color.input_actions': _lightgreen,
  // 'weechat.color.input_text_not_found': _red,
  // 'weechat.color.item_away': _yellow,
  // 'weechat.color.nicklist_away': _cyan,
  // 'weechat.color.nicklist_group': _green,
  0: {'weechat.color.separator': _blue},
  // 'weechat.color.status_count_highlight': _magenta,
  // 'weechat.color.status_count_msg': _brown,
  // 'weechat.color.status_count_other': _default,
  // 'weechat.color.status_count_private': _green,
  // 'weechat.color.status_data_highlight': _lightmagenta,
  // 'weechat.color.status_data_msg': _yellow,
  // 'weechat.color.status_data_other': _default,
  // 'weechat.color.status_data_private': _lightgreen,
  // 'weechat.color.status_filter': _green,
  // 'weechat.color.status_more': _yellow,
  // 'weechat.color.status_mouse': _green,
  // 'weechat.color.status_name': _white,
  // 'weechat.color.status_name_ssl': _lightgreen,
  // 'weechat.color.status_nicklist_count': _default,
  // 'weechat.color.status_number': _yellow,
  // 'weechat.color.status_time': _default,
};

typedef ColorCode = int;

final Map<int, ColorCode?> colorOptions =
    _colorOptions.map((key, value) => MapEntry(key, value.values.first));
