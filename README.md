# Client library for the Gira HomeServer

This is a client library for the Gira HomeServer written in [Dart](https://dart.dev).

## Usage

Create a `Home` and connect to it:

```dart
final home = Home(
  ip: InternetAddress('192.168.2.11'),
  port: 80,
  username: 'username',
  password: 'password',
);
await home.connect();
```

Additionally, you can create descriptions of devices:

```dart
final lamp = Lamp(18081);
```

Using these devices, you can create actions.
The `home` can execute these:

```dart
final action = lamp.turnOnAction;
home.run(action); // Actually turns the light on.
```

## Exploit

As described in my blog articles [mgar.us/gira](https://mgar.us/gira) and [mgar.us/gira-hack](https://mgar.us/gira-hack), the Gira HomeServer is vulnerable.
The `main.dart` file contains a program that doesn't need the password and turns off all devices in a home.
