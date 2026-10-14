import 'package:get_it/get_it.dart';
import '../network/mqtt_service.dart';
import '../network/websocket_service.dart';
import '../../features/smart_home/data/datasources/virtual_bulb_simulator.dart';
import '../../features/smart_home/data/repositories/smart_home_repository_impl.dart';
import '../../features/smart_home/domain/repositories/smart_home_repository.dart';
import '../../features/smart_home/domain/usecases/smart_home_usecases.dart';
import '../../features/smart_home/presentation/bloc/smart_home_bloc.dart';

final sl = GetIt.instance;
void setupDependencies() {
  final topic = 'nexora/demo/${DateTime.now().microsecondsSinceEpoch}';
  final controller = MqttService();
  final simulator = VirtualBulbSimulator(mqtt: MqttService(), baseTopic: topic);
  sl.registerSingleton<SmartHomeRepository>(
    SmartHomeRepositoryImpl(
      controller: controller,
      simulator: simulator,
      baseTopic: topic,
    ),
  );
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());
  sl.registerLazySingleton(() => ConnectSmartHome(sl()));
  sl.registerLazySingleton(() => WatchSmartHome(sl()));
  sl.registerLazySingleton(() => SetLight(sl()));
  sl.registerFactory(() => SmartHomeBloc(
    connectSmartHome: sl(),
    watchSmartHome: sl(),
    setLight: sl(),
  ));
}
