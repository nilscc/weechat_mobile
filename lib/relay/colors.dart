// See https://weechat.org/files/doc/stable/weechat_dev.en.html#color_codes_in_strings
// And also for reference:
// https://github.com/ubergeek42/weechat-android/blob/379f0863e9eef70d83462a5d13e8de932eb785b5/relay/src/main/java/com/ubergeek42/weechat/Color.java
// https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-color.h

const _attributes = ['F', 'B', '*', '!', '/', '_', '|'];
const _combiners = [',', '~'];

String stripColors(String raw) {
  final List<int> i = [];

  bool colorCode = false;
  bool setAttribute = false;
  bool remAttribute = false;

  final it = raw.runes.iterator;
  while (it.moveNext()) {
    if (it.current == 0x1A || it.current == 0x1B) {
      it.moveNext();
      continue;
    }

    if (it.current == 0x1C)
      continue;

    if (it.current == 0x19) {
      colorCode = true;
      continue;
    }

    if (colorCode) {
      if (_attributes.contains(it.currentAsString)) {}
      else if (it.currentAsString == '@') {
        // extended: move 5 characters
        it.moveNext();
        it.moveNext();
        it.moveNext();
        it.moveNext();
        it.moveNext();
        it.moveNext();
        if (!_combiners.contains(it.currentAsString)) {
          it.movePrevious();
          colorCode = false;
        }
      } else {
        // standard: move 2 characters
        it.moveNext();
        it.moveNext();
        if (!_combiners.contains(it.currentAsString)) {
          it.movePrevious();
          colorCode = false;
        }
      }

      continue;
    }

    i.add(it.current);
  }

  return String.fromCharCodes(i);
}