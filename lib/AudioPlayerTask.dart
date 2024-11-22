
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An [AudioHandler] for playing a single item.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  static final _item = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: const Duration(milliseconds: 5739820),
    artUri: Uri.parse('https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
  );

  final _player = AudioPlayer();
  MediaItem? _currentMediaItem;
 // final AudioCache _audioCache = AudioCache();
  /// Initialise our audio handler.
  AudioPlayerHandler() {
    // So that our clients (the Flutter UI and the system notification) know
    // what state to display, here we set up our audio handler to broadcast all
    // playback state changes as they happen via playbackState...
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen for position changes and save the last position
    _player.positionStream.listen((position) {
      saveLastPosition(position);
    });

    // ... and also the current media item via mediaItem.
    //mediaItem.add(_item);

    // Load the player.
    // _player.setAudioSource(AudioSource.uri(Uri.parse(_item.id)));
  }

  Future<void> saveLastPosition(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_position', position.inMilliseconds);
  }

  Future<Duration> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    int milliseconds = prefs.getInt('last_position') ?? 0;
    return Duration(milliseconds: milliseconds);
  }

  // Method to load and play a song dynamically
  Future<void> loadAndPlaySong1(MediaItem item) async {
    _currentMediaItem = item; // Store the current media item
    mediaItem.add(item); // Broadcast the current media item
    await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
    await _player.play(); // Start playback
  }

  Future<void> loadAndPlaySong2(MediaItem item) async {
    _currentMediaItem = item;
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
    // Load last position if it exists
    Duration lastPosition = await getLastPosition();
    if (lastPosition != Duration.zero) {
      await _player.seek(lastPosition);
    }

    await _player.play();
  }

  Future<String?> downloadAudio(String url) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${Uri.parse(url).pathSegments.last}';
    final response = await Dio().download(url, filePath);
    return response.statusCode == 200 ? filePath : null;
  }

  Future<void> loadAndPlaySong({
    id = "",
    album = "",
    title = "",
    artist = "",
    thumbnail = "",
  }) async {

    // Check if the same media item is already loaded
    if (_currentMediaItem?.id == id) {
      // If the same song is loaded, just seek to the last position and play
      Duration lastPosition = await getLastPosition();
      if (lastPosition != Duration.zero) {
        await _player.seek(lastPosition);
      }
      await _player.play();
      return; // Exit the method early
    }

    /// Use cache to load audio
   // await _audioCache.load(id);

    /* String? localFilePath = await downloadAudio(id);
    if (localFilePath != null) {
      await _player.setAudioSource(AudioSource.file(localFilePath));
      await _player.play();
      return; // Exit the method early
    }*/

    await _player.setAudioSource(AudioSource.uri(Uri.parse(id)));
    // Wait for the player to load the audio
    await _player.load(); // This is crucial to load the audio metadata

    // Get the duration of the loaded audio
    final duration = _player.duration ?? Duration.zero; // Use Duration.zero if duration is null

    final item = MediaItem(
      id: id,
      album: album,
      title: title,
      artist: artist,
      duration: duration,
      artUri: Uri.parse(thumbnail),
    );
    // Otherwise, load the new media item
    _currentMediaItem = item; // Store the current media item
    mediaItem.add(item);
    // Seek to the last position if it exists
    Duration lastPosition = await getLastPosition();
    if (lastPosition != Duration.zero) {
      await _player.seek(lastPosition);
    }

    await _player.play();
  }

  // Method to initialize the audio player with a dynamic media item
  void init(MediaItem item) {
    // Broadcast media item and playback state
    mediaItem.add(item);
    // Set the audio source dynamically
    _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
  }

  // Method to change media dynamically
  Future<void> changeMedia(MediaItem newMediaItem) async {
    mediaItem.add(newMediaItem);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(newMediaItem.id)));
  }

  // In this simple example, we handle only 4 actions: play, pause, seek and
  // stop. Any button press from the Flutter UI, notification, lock screen or
  // headset will be routed through to these 4 methods so that you can handle
  // your audio playback logic in one place.

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  /// Transform a just_audio event into an audio_service state.
  ///
  /// This method is used from the constructor. Every event received from the
  /// just_audio player will be transformed into an audio_service state so that
  /// it can be broadcast to audio_service clients.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// when app killed its called to remove notification and stop service
  @override
  Future<void> onTaskRemoved() => _player.stop();

  // Getter for current media item
  MediaItem? get currentMediaItem => _currentMediaItem;
}
