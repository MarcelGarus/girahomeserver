import 'package:meta/meta.dart';

/// An [Action] that can be sent to the `Home`.
@immutable
class Action {
  const Action(this.id, this.value);

  final int id;
  final num value;
}

/// Represents the status of a device. The fields have no intrinsic meaning.
/// Instead, meaning is assigned through the device type.
class Status {
  const Status(this.foo, this.bar);

  final String foo;
  final bool bar;

  String toString() => '($foo, $bar)';
}

/// A `Device`.
@immutable
abstract class Device {
  int get primaryId;
  List<int> get ids;
}

abstract class DeviceWithOneId implements Device {
  const DeviceWithOneId(this.id);

  final int id;

  int get primaryId => id;
  List<int> get ids => [id];
}

abstract class DeviceWithTwoIds implements Device {
  const DeviceWithTwoIds(this.firstId, this.secondId);

  final int firstId;
  final int secondId;

  int get primaryId => firstId;
  List<int> get ids => [firstId, secondId];
}

// Abstraction over toggling a device on or off.

abstract class OnOffDevice extends Device {
  Action get turnOnAction;
  Action get turnOffAction;
  bool isTurnedOn(Status status);
}

extension ToggleOnOffDevice on OnOffDevice {
  Action toggleAction(Status status) =>
      isTurnedOn(status) ? turnOffAction : turnOnAction;
}

mixin DefaultOnOffDevice on Device implements OnOffDevice {
  Action get turnOffAction => Action(primaryId, 0);
  Action get turnOnAction => Action(primaryId, 1);
  bool isTurnedOn(Status status) =>
      ((double.tryParse(status.foo) ?? 0.0) == 1.0);
}

// Concrete devices.

class Lamp extends DeviceWithOneId with DefaultOnOffDevice {
  const Lamp(int id) : super(id);
}

class DimmableLamp extends DeviceWithTwoIds with DefaultOnOffDevice {
  const DimmableLamp(int firstId, int secondId) : super(firstId, secondId);

  Action dimActionFor(double brightness) => Action(secondId, brightness);
}

class Plug extends DeviceWithOneId with DefaultOnOffDevice {
  const Plug(int id) : super(id);
}

class Blinds extends DeviceWithTwoIds {
  const Blinds(int firstId, int secondId) : super(firstId, secondId);

  Action get goUpAction => Action(firstId, 0);
  Action get goDownAction => Action(firstId, 1);
  Action get stopAction => Action(secondId, 0);
}

class Fan extends DeviceWithOneId with DefaultOnOffDevice {
  const Fan(int id) : super(id);
}

class Whirlpool extends DeviceWithOneId with DefaultOnOffDevice {
  const Whirlpool(int id) : super(id);
}

class Sunshade extends DeviceWithTwoIds {
  const Sunshade(int firstId, int secondId) : super(firstId, secondId);

  Action get retractAction => Action(firstId, 0);
  Action get extendAction => Action(firstId, 1);
  Action get stopAction => Action(secondId, 0);
}

class Thermometer extends DeviceWithOneId {
  const Thermometer(int id) : super(id);

  double temperatureInCelsius(Status status) => double.parse(status.foo);
}
