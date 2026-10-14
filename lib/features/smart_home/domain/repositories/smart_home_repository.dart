import '../entities/smart_home_data.dart';
abstract class SmartHomeRepository {
  Future<bool> connect();
  Stream<SmartHomeData> watchData();
  bool setLight(bool on);
  Future<void> dispose();
}
