import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/widgets/channel/urlify.dart';

void main() {
  test('Validate URLs', () {
    expect(
        validUrl(
            "https://matrix.totally.rip/_matrix/media/r0/download/matrix.org/cNTjfRUPrctdopunaxlyFbwb/20231127_095158_3687906800503534704.jpg"),
        isTrue);
  });
}
