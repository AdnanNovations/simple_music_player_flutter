import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:music_player/custom_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MusicPlayer(),
    );
  }
}

class MusicPlayerController extends GetxController {
  late final FlutterSoundPlayer player;

  StreamSubscription? playerSubs;

  RxInt selectedMusic = RxInt(0);
  RxDouble musicDuration = RxDouble(0);
  RxDouble totalDuration = RxDouble(0);
  RxBool isPlaying = RxBool(false);

  List<Map<String, dynamic>> musicList = [
    {
      "sound": "assets/sounds/NCS.mp3",
      "image": "assets/nature-1.jpg",
      "title": "On & On (feat. Daniel Levi)",
      "author": "Cartoon, Jéja"
    },
    {
      "sound": "assets/sounds/Himitsu.mp3",
      "image": "assets/nature-2.jpg",
      "title": "Adventures",
      "author": "A Himitsu"
    },
  ];

  @override
  void onInit() {
    super.onInit();

    player = FlutterSoundPlayer();
    player.openPlayer().then((_) async {
      await player.setSubscriptionDuration(const Duration(milliseconds: 50));
      playerSubs = player.onProgress!.listen((e) {
        totalDuration.value = e.duration.inMilliseconds.toDouble();
        musicDuration.value = e.position.inMilliseconds.toDouble();
      });
    });
  }

  @override
  void onClose() {
    player.stopPlayer();

    playerSubs?.cancel();
    playerSubs = null;

    player.closePlayer();

    super.onClose();
  }

  String musicDurationStringFormat(double milliseconds) {
    int seconds = milliseconds ~/ 1000;
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  Future playMusic() async {
    final musicData = await getAssetData(musicList[selectedMusic.value]["sound"]);
    await player.startPlayer(
        fromDataBuffer: musicData,
        codec: Codec.mp3,
        whenFinished: () {
          isPlaying.value = false;
          nextMusic();
        }
    );
    isPlaying.value = true;
  }

  Future pauseMusic() async {
    await player.pausePlayer();
    isPlaying.value = false;
  }

  Future nextMusic() async {
    selectedMusic.value++;
    await playMusic();
  }

  Future previousMusic() async {
    selectedMusic.value--;
    await playMusic();
  }

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future seekMusic(double newVal) async {
    musicDuration.value = newVal;
    await player.seekToPlayer(Duration(milliseconds: newVal.floor()));
  }
}

class MusicPlayer extends StatelessWidget {
  const MusicPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MusicPlayerController mpc = Get.put(MusicPlayerController());

    return Scaffold(
      body: Center(
        child: Obx(() => Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.black
                    ),
                    width: Get.width,
                    padding: const EdgeInsets.all(10).copyWith(left: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mpc.musicList[mpc.selectedMusic.value]["title"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14
                          ),
                        ),
                        Text(
                          mpc.musicList[mpc.selectedMusic.value]["author"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              fontSize: 12
                          ),
                        ),
                        Obx(() => SliderTheme(
                          data: const SliderThemeData(
                            trackShape: CustomSliderTrackShape(),
                            thumbShape: CustomSliderThumbShape(),
                            overlayShape: CustomSliderOverlayShape(),
                          ),
                          child: Slider(
                            value: mpc.musicDuration.value,
                            min: 0,
                            max: mpc.totalDuration.value,
                            onChanged: (newVal) {
                              mpc.seekMusic(newVal);
                            },
                          ),
                        )),
                        Obx(() => Row(
                          children: [
                            Text(
                              mpc.musicDurationStringFormat(mpc.musicDuration.value),
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12
                              ),
                            ),
                            Text(
                              " : ${mpc.musicDurationStringFormat(mpc.totalDuration.value)}",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12
                              ),
                            ),
                          ],
                        ))
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.8)
                    ),
                    width: Get.width,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.backward),
                            color: Colors.white,
                            onPressed: () {
                              mpc.previousMusic();
                            },
                          ),
                          Obx(() => IconButton(
                            icon: FaIcon(mpc.isPlaying.isTrue ?
                             FontAwesomeIcons.pause : FontAwesomeIcons.play),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.green
                            ),
                            onPressed: () {
                              if (mpc.isPlaying.isTrue) {
                                mpc.pauseMusic();
                              } else {
                                mpc.playMusic();
                              }
                            },
                          )),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.forward),
                            color: Colors.white,
                            onPressed: () {
                              mpc.nextMusic();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 25,
              width: 115,
              height: 115,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Obx(() => AnimatedRotation(
                      duration: const Duration(seconds: 1),
                      turns: mpc.musicDuration.value / 20000,
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                image: AssetImage(mpc.musicList[0]["image"]),
                                fit: BoxFit.cover
                            )
                        ),
                      ),
                    )),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        )),
      ),
    );
  }
}