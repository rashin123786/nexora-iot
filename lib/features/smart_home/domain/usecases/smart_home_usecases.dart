import '../entities/smart_home_data.dart';
import '../repositories/smart_home_repository.dart';
class ConnectSmartHome {
  final SmartHomeRepository repository;
  ConnectSmartHome(this.repository);
  Future<bool> call() => repository.connect();
}
class WatchSmartHome {
  final SmartHomeRepository repository;
  WatchSmartHome(this.repository);
  Stream<SmartHomeData> call() => repository.watchData();
}
class SetLight {
  final SmartHomeRepository repository;
  SetLight(this.repository);
  bool call(bool on) => repository.setLight(on);
}
