import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/widgets/channel/urlify.dart';

void main() {
  test('Validate URLs', () {
    expect(
        validUrl(
            "https://matrix.some.tld/_matrix/media/r0/download/matrix.org/slkdjfslijflsijd/123456_123456_12345698374598734.jpg"),
        isTrue);
  });
}
