import 'package:flutter/material.dart';
import 'package:lesson74yandex/services/geolocation_service.dart';
import 'package:lesson74yandex/views/screens/homepage.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await GeolocationService.init();

  runApp(const MainRunner());
}

class MainRunner extends StatelessWidget {
  const MainRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}
