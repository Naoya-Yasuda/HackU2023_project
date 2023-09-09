import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_object_detection/app/app_router.dart';
import 'package:flutter_realtime_object_detection/services/navigation_service.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:audioplayers/audioplayers.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  final String audioPath = 'assets/audio/dog1b.mp3';
  final AudioPlayer audioPlayer = AudioPlayer();
  audioPlayer.play(audioPath, isLocal: true);
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AppRoute>(create: (_) => AppRoute()),
      Provider<NavigationService>(create: (_) => NavigationService()),
      Provider<TensorFlowService>(create: (_) => TensorFlowService())
    ],
    child: Application(),
    //child: MyText(),
  ));
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppRoute appRoute = Provider.of<AppRoute>(context, listen: false);
    return ScreenUtilInit(
        designSize: Size(375, 812),
        builder: () {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            onGenerateRoute: appRoute.generateRoute,
            initialRoute: AppRoute.splashScreen,
            navigatorKey: NavigationService.navigationKey,
            navigatorObservers: <NavigatorObserver>[
              NavigationService.routeObserver
            ],
          );
        });
  }
}

class MyText extends StatelessWidget {
  MyText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('hoge');
  }
}
