import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:musicapp/mini_player_component.dart';
import 'package:musicapp/music_player_screen.dart';
import 'package:provider/provider.dart';
import 'AudioPlayerTask.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioHandler audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.robinson.musicapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  //runApp(const MyApp());
  runApp(
    Provider<AudioHandler>(
      create: (_) => audioHandler,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player Demo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ElevatedButton(
            child: const Text('Open Music Player'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
              );
            },
          ),
          const Expanded(
            child: SizedBox()
          ),
          const MiniPLayer()
        ],
      ),
    );
  }
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
