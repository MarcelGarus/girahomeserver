import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:girahomeserver/girahomeserver.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'data.dart';
import 'utils.dart';

enum HomeState {
  notConnected,
  connecting,
  authenticating,
  authenticated,
}

class StatusUpdate {
  StatusUpdate(this.id, this.status);

  final int id;
  final Status status;

  String toString() => 'Update $id to $status';
}

/// A controllable home.
class Home {
  Home({
    @required this.ip,
    @required this.port,
    @required this.username,
    @required this.password,
  });

  // Connection information.
  final InternetAddress ip;
  final int port;
  final String username;
  final String password;

  // Connection.
  Socket _socket;
  final _stateController =
      BehaviorSubject<HomeState>.seeded(HomeState.notConnected);
  Stream<HomeState> get stateStream => _stateController.stream;
  HomeState get state => _stateController.value;

  final _deviceStates = <int, Status>{};
  final _updatesController = StreamController<StatusUpdate>.broadcast();
  Stream<StatusUpdate> get updates => _updatesController.stream;
  Stream<StatusUpdate> updatesForIds(List<int> ids) =>
      updates.where((update) => ids.contains(update.id));
  Stream<StatusUpdate> updatesFor(Device device) => updatesForIds(device.ids);
  Stream<StatusUpdate> updatesForAny(List<Device> devices) => updatesForIds(
      devices.map((device) => device.ids).fold([], (a, b) => a + b));
  Status statusOf(Device device) => _deviceStates[device.ids.first];
  Stream<Status> statesFor(Device device) =>
      Stream.value(_deviceStates[device.ids.first])
          .concatWith([updatesFor(device).map((update) => update.status)]);

  Future<void> connect() => _reconnect();
  Future<void> _reconnect() async {
    _stateController.add(HomeState.connecting);
    final socket = await Socket.connect(ip, port);

    socket.add('GET /QUAD/LOGIN \r\n\r\n'.utf8Encoded);

    void _handlePacket(List<int> packet) {
      // print('Received packet data is ${packet.utf8Decoded}');
      final args = packet.utf8Decoded.split('|');

      if (args.isEmpty || args.first.isEmpty) {
        return; // Skip empty packets.
      }

      final type = int.parse(args.first);
      switch (type) {
        // Request for a username.
        case 100:
          _stateController.add(HomeState.authenticating);
          socket.add('90|$username|\x00'.utf8Encoded);
          break;
        // Request for password hash.
        case 91:
          final salt = args[1];
          final hash = _createHash(username, password, salt);
          socket.add('92|$hash|\x00'.utf8Encoded);
          break;
        // Successfully signed in.
        case 93:
          _socket = socket;
          _stateController.add(HomeState.authenticated);
          // TODO: save session details
          break;
        case 1:
        case 2:
          if (args.length == 4) {
            final id = int.parse(args[1]);
            if (id >= 1000 &&
                !{
                  18183,
                  18180,
                  18181,
                  18178,
                  18182,
                  18175,
                  18176,
                  18177,
                  18179,
                  15883
                }.contains(id)) {
              // print('Updated $id with args $args');
            }
            final status = Status(args[2], args[3] == 1);
            _deviceStates[id] = status;
            if (!_updatesController.isClosed) {
              _updatesController.add(StatusUpdate(id, status));
            }
          }
      }
    }

    // For efficiency reasons, multiple packets may be put into a single TCP
    // packet. Home server packets always end with a null byte (\0), so if we
    // encounter one, we know we just read a complete packet.
    List<int> buffer = [];
    socket.listen(
      (newBytes) {
        buffer.addAll(newBytes);
        while (true) {
          // print('Buffer is $buffer.');
          final nullByteIndex = buffer.indexOf(0);
          if (nullByteIndex >= 0) {
            _handlePacket(buffer.sublist(0, nullByteIndex));
            buffer.removeRange(0, nullByteIndex + 1);
          } else {
            // There may be an unfinished packet still in the buffer that will
            // probably be completed with the next TCP packet.
            break;
          }
        }
      },
      onDone: () {
        _stateController.add(HomeState.notConnected);
        throw 'Connection closed.';
      },
      onError: (error) {
        _stateController.add(HomeState.notConnected);
        throw error;
      },
      cancelOnError: true,
    );
    await stateStream.firstWhere((state) => state == HomeState.authenticated);
  }

  void refresh() => _socket.add('94||\x00'.utf8Encoded);

  void run(Action action) {
    _socket.add('1|${action.id}|${action.value}\x00'.utf8Encoded);
  }

  Future<void> dispose() async {
    await Future.wait([
      _stateController.close(),
      _updatesController.close(),
      _socket.close(),
    ]);
  }
}

String _createHash(String username, String password, String saltString) {
  final salt = saltString.utf8Encoded;
  final a = [for (var i = 0; i < 64; i++) salt.at(i, or: 0) ^ 92].utf8Decoded;
  final b = [for (var i = 0; i < 64; i++) salt.at(i, or: 0) ^ 54].utf8Decoded;
  var hash = md5
      .convert('$b$username$password'.utf8Encoded)
      .bytes
      .hexEncoded
      .toUpperCase();
  hash = md5.convert('$a$hash'.utf8Encoded).bytes.hexEncoded.toUpperCase();
  return hash;
}
