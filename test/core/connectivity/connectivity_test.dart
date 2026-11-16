import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonde/core/connectivity/connectivity_provider.dart';

void main() {
  test("hasConnection est vrai dès qu'un réseau est disponible", () {
    expect(hasConnection([ConnectivityResult.wifi]), isTrue);
    expect(
      hasConnection([ConnectivityResult.none, ConnectivityResult.mobile]),
      isTrue,
    );
  });

  test('hasConnection est faux sans réseau', () {
    expect(hasConnection([ConnectivityResult.none]), isFalse);
    expect(hasConnection([]), isFalse);
  });
}
