import 'dart:io';

import 'girahomeserver.dart';

void main() async {
  // The home IP, port, and username should be correct.
  final home = Home(
    ip: InternetAddress('192.168.2.11'),
    port: 80,
    username: 'username',
    password: 'anypasswordwillwork',
  );
  // Not awaited, so we don't wait for an authentication.
  home.connect();
  await Future.delayed(Duration(seconds: 3));

  // Turn off all devices.
  for (var id = 0;; id++) {
    await Future.delayed(Duration(seconds: 1));
    home.run(Action(id, 0));
    print('Turned of $id.');
  }
}
