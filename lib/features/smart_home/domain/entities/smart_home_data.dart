class SmartHomeData {
  final bool lightOn;
  final double? temperature;
  final double? humidity;
  const SmartHomeData({this.lightOn = false, this.temperature, this.humidity});
  SmartHomeData copyWith({bool? lightOn, double? temperature, double? humidity}) => SmartHomeData(
    lightOn: lightOn ?? this.lightOn,
    temperature: temperature ?? this.temperature,
    humidity: humidity ?? this.humidity,
  );
}
