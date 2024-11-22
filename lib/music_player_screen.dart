import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/common.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import 'AudioPlayerTask.dart';
import 'main.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  MusicPlayerScreenState createState() => MusicPlayerScreenState();
}

class MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late AudioPlayerHandler _audioHandler;

  @override
  void initState() {
    super.initState();
    initializeAudio();
  }

  Future<void> initializeAudio() async {
    /* final mediaItem = MediaItem(
      id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
      album: "Science Friday",
      title: "A Salute To Head-Scratching Science",
      artist: "Science Friday and WNYC Studios",
      duration: const Duration(milliseconds: 5739820),
      artUri: Uri.parse('https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
    );*/
    _audioHandler = Provider.of<AudioHandler>(context, listen: false) as AudioPlayerHandler;
    // Check if there's a current media item and play from the last position

    if (_audioHandler.currentMediaItem != null) {
      // Assuming you store the last position in the AudioHandler
      _audioHandler.loadAndPlaySong(id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3");
    } else {
      _audioHandler.loadAndPlaySong(
        title: "Title",
        id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
        album: "Album ",
        artist: "Author Name",
        thumbnail: "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the AudioHandler using Provider
    // AudioHandler _audioHandler = Provider.of<AudioHandler>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Show media item image
            SizedBox(
              height: 200,
              width: 200,
              child: StreamBuilder<MediaItem?>(
                stream: _audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  return Image.network(
                    mediaItem?.artUri?.toString() ?? "",
                    fit: BoxFit.fill,
                    errorBuilder: (context, exception, stackTrace) {
                      return const Icon(Icons.error);
                    },
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),

            /// Show media item title
            StreamBuilder<MediaItem?>(
              stream: _audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return Text(mediaItem?.title ?? '');
              },
            ),

            /// Show media item author name
            const SizedBox(
              height: 10,
            ),
            StreamBuilder<MediaItem?>(
              stream: _audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return Text(mediaItem?.artist ?? '');
              },
            ),

            /// Play/pause/stop buttons.
            StreamBuilder<bool>(
              stream: _audioHandler.playbackState.map((state) => state.playing).distinct(),
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _button(Icons.fast_rewind, _audioHandler.rewind),
                    if (playing) _button(Icons.pause, _audioHandler.pause) else _button(Icons.play_arrow, _audioHandler.play),
                    // _button(Icons.stop, _audioHandler.stop),
                    _button(Icons.fast_forward, _audioHandler.fastForward),
                  ],
                );
              },
            ),

            /// A seek bar.
            StreamBuilder<MediaState>(
              stream: _mediaStateStream(_audioHandler),
              builder: (context, snapshot) {
                final mediaState = snapshot.data;
                return SeekBar(
                  duration: mediaState?.mediaItem?.duration ?? Duration.zero,
                  position: mediaState?.position ?? Duration.zero,
                  onChangeEnd: (newPosition) {
                    _audioHandler.seek(newPosition);
                  },
                );
              },
            ),
            // Display the processing state.
            /* StreamBuilder<AudioProcessingState>(
              stream: _audioHandler.playbackState.map((state) => state.processingState).distinct(),
              builder: (context, snapshot) {
                final processingState = snapshot.data ?? AudioProcessingState.idle;
                return Text(
                    // ignore: deprecated_member_use
                    "Processing state: ${describeEnum(processingState)}");
              },
            ),*/
          ],
        ),
      ),
    );
  }

  // Pass the AudioHandler to the stream function.
  Stream<MediaState> _mediaStateStream(AudioHandler audioHandler) =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(audioHandler.mediaItem, AudioService.position, (mediaItem, position) => MediaState(mediaItem, position));

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  /* Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          _audioHandler.mediaItem,
          AudioService.position,
              (mediaItem, position) => MediaState(mediaItem, position));
*/
  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 64.0,
        onPressed: onPressed,
      );
}
