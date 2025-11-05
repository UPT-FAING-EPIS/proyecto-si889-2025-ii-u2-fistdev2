import 'dart:io';

String getBaseUrl() {
  // Android emulador usa el host loopback del host: 10.0.2.2
  // iOS simulador y dispositivos de escritorio pueden usar 127.0.0.1
  if (Platform.isAndroid) {
    return 'http://161.132.49.24:8003';
  }
  return 'http://161.132.49.24:8003';
}
