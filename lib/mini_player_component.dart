import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:musicapp/common.dart';
import 'package:musicapp/main.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MiniPLayer extends StatelessWidget {
  const MiniPLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the shared audioHandler instance
    AudioHandler audioHandler = Provider.of<AudioHandler>(context);
    return StreamBuilder<AudioProcessingState>(
      stream: audioHandler.playbackState.map((state) => state.processingState).distinct(),
      builder: (context, snapshot) {
        final processingState = snapshot.data ?? AudioProcessingState.idle;

        /// Check if the service is stopped
        bool isStopped = processingState == AudioProcessingState.idle;
        return isStopped
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(
                      Radius.circular(25),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        height: 50,
                        width: 50,
                        child: StreamBuilder<MediaItem?>(
                          stream: audioHandler.mediaItem,
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
                      const SizedBox(width: 10,),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<MediaItem?>(
                              stream: audioHandler.mediaItem,
                              builder: (context, snapshot) {
                                final mediaItem = snapshot.data;
                                return Text(mediaItem?.title ?? '');
                              },
                            ),
                            StreamBuilder<MediaState>(
                              stream: _mediaStateStream(audioHandler),
                              builder: (context, snapshot) {
                                final mediaState = snapshot.data;
                                return SeekBar(
                                  duration: mediaState?.mediaItem?.duration ?? Duration.zero,
                                  position: mediaState?.position ?? Duration.zero,
                                  onChangeEnd: (newPosition) {
                                    audioHandler.seek(newPosition);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: audioHandler.playbackState.map((state) => state.playing).distinct(),
                        builder: (context, snapshot) {
                          final playing = snapshot.data ?? false;
                          return playing ? _button(Icons.pause, audioHandler.pause) : _button(Icons.play_arrow, audioHandler.play);
                        },
                      ),
                      _button(Icons.clear, audioHandler.stop),
                    ],
                  ),
                ),
              );
      },
    );
  }

  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 30.0,
        onPressed: onPressed,
      );

  // Pass the AudioHandler to the stream function.
  Stream<MediaState> _mediaStateStream(AudioHandler audioHandler) =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(audioHandler.mediaItem, AudioService.position, (mediaItem, position) => MediaState(mediaItem, position));

/*Widget player(){
    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _button(Icons.fast_rewind, audioHandler.rewind),
            if (playing) _button(Icons.pause, audioHandler.pause) else _button(Icons.play_arrow, audioHandler.play),
            _button(Icons.stop, audioHandler.stop),
            _button(Icons.fast_forward, audioHandler.fastForward),
          ],
        );
      },
    );
  }*/
}
