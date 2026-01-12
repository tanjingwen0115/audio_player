import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'GoogleSans',
    ),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: AudioPlayerUI()),
    ),
  ),
);

class AudioPlayerUI extends StatefulWidget {
  const AudioPlayerUI({super.key});

  @override
  State<AudioPlayerUI> createState() => _AudioPlayerUIState();
}

class _AudioPlayerUIState extends State<AudioPlayerUI> {
  // --- STATE VARIABLES ---
  bool isPlaying = true;
  bool isMinimized = false;
  bool isRepeatOne = false;

  Offset _miniPos = const Offset(20, 100);

  double currentSeconds = 0.0;
  double bufferedSeconds = 0.0;
  Timer? _playbackTimer;

  double? hoverSeconds;
  double? hoverX;

  // --- PLAYLIST DATA ---
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _playlist = [
    {
      "title": "Black Friday (pretty like the ones in movies)",
      "artist": "Lost Frequencies, Tom Odell",
      "image": "assets/43hgY77tfrzPLPp.png",
      "isLocal": true,
      "duration": 311.0,
      "isLiked": true,
      "bufferedPercent": 0.85,
    },
    {
      "title": "Starboy",
      // Very long name to test scrolling
      "artist": "The Weeknd, Daft Punk, and a very long list of other collaborating artists",
      "image": "https://i.scdn.co/image/ab67616d0000b2734718e28c64edcc4ef37da89d",
      "isLocal": false,
      "duration": 230.0,
      "isLiked": false,
      "bufferedPercent": 0.40,
    },
    {
      "title": "Midnight City",
      "artist": "M83",
      "image": "https://i.scdn.co/image/ab67616d0000b27329587425447a111a0c4f3643",
      "isLocal": false,
      "duration": 243.0,
      "isLiked": false,
      "bufferedPercent": 0.95,
    },
    {
      "title": "Heat Waves",
      "artist": "Glass Animals",
      "image": "https://i.scdn.co/image/ab67616d0000b2739e495fb707973f3390850eea",
      "isLocal": false,
      "duration": 238.0,
      "isLiked": false,
      "bufferedPercent": 1.0,
    },
  ];

  // --- STYLES ---
  final Color cardBg = const Color(0xFF2e3240);
  final Color accentBlue = const Color(0xFF004a77);
  final Color textGrey = const Color(0xFFB0B3B8);

  @override
  void initState() {
    super.initState();
    double total = _playlist[0]['duration'];
    double percent = _playlist[0]['bufferedPercent'];
    bufferedSeconds = total * percent;
    if (isPlaying) _startTimer();
  }

  // --- NAVIGATION LOGIC ---
  void _nextSong() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      _resetStateForNewSong();
    });
  }

  void _prevSong() {
    setState(() {
      if (currentSeconds > 3) {
        currentSeconds = 0;
      } else {
        _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
        _resetStateForNewSong();
      }
    });
  }

  void _resetStateForNewSong() {
    currentSeconds = 0;
    double total = _playlist[_currentIndex]['duration'];
    double percent = _playlist[_currentIndex]['bufferedPercent'];
    bufferedSeconds = total * percent;

    isPlaying = true;
    _playbackTimer?.cancel();
    _startTimer();
  }

  void _startTimer() {
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        double total = _playlist[_currentIndex]['duration'];
        if (currentSeconds < total) {
          currentSeconds++;
        } else {
          if (isRepeatOne) {
            currentSeconds = 0;
          } else {
            _nextSong();
          }
        }
      });
    });
  }

  void _togglePlayback() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _startTimer();
      } else {
        _playbackTimer?.cancel();
      }
    });
  }

  String _formatDuration(double seconds) {
    int mins = seconds.toInt() ~/ 60;
    int secs = seconds.toInt() % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songData = _playlist[_currentIndex];
    final String songName = songData['title'];
    final String artistName = songData['artist'];
    final double totalSeconds = songData['duration'];
    final bool isLocalImage = songData['isLocal'];
    final String imagePath = songData['image'];
    final bool isLiked = songData['isLiked'];

    return Stack(
      children: [
        if (!isMinimized)
          Center(
            child: _buildFullPlayer(
              songName,
              artistName,
              totalSeconds,
              imagePath,
              isLocalImage,
              isLiked,
            ),
          ),
        if (isMinimized)
          Positioned(
            left: _miniPos.dx,
            top: _miniPos.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _miniPos += details.delta;
                });
              },
              onTap: () {
                setState(() {
                  isMinimized = false;
                });
              },
              child: _buildMiniPlayer(),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      key: const ValueKey("MiniPlayer"),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPlaying ? Colors.greenAccent : Colors.grey.withOpacity(0.3),
          width: isPlaying ? 3 : 2,
        ),
      ),
      child: Center(
        child: SoundWave(isPlaying: isPlaying),
      ),
    );
  }

  Widget _buildFullPlayer(
      String songName,
      String artistName,
      double totalSeconds,
      String imagePath,
      bool isLocalImage,
      bool isLiked) {

    final playButtonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed))
          return const Color(0xFF002B45);
        if (states.contains(WidgetState.hovered))
          return const Color(0xFF003B60);
        return accentBlue;
      }),
      shape: WidgetStateProperty.all(const CircleBorder()),
      padding: WidgetStateProperty.all(EdgeInsets.zero),
    );

    final controlButtonStyle = ButtonStyle(
      overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.pressed)) return Colors.black;
        if (states.contains(WidgetState.hovered)) return Colors.white;
        return Colors.transparent;
      }),
    );

    return Container(
      key: const ValueKey("FullPlayer"),
      width: 448,
      height: 277,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(29.0, 30.0, 29.0, 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOP ROW
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // IMAGE SECTION
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: isLocalImage
                              ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(color: Colors.white10),
                          )
                              : Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.white10,
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // TEXT SECTION
                      SizedBox(
                        width: 291,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. SONG TITLE
                            SizedBox(
                              height: 30,
                              child: AutoMarquee(
                                // KEY ADDED HERE: Forces reset when title changes
                                key: ValueKey(songName),
                                text: songName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // 2. ARTIST NAME
                            SizedBox(
                              height: 24,
                              child: AutoMarquee(
                                // KEY ADDED HERE: Forces reset when artist changes
                                key: ValueKey(artistName),
                                text: artistName,
                                style: TextStyle(
                                    color: textGrey.withOpacity(0.5),
                                    fontSize: 18,
                                    height: 1.1
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PROGRESS BAR AREA
                SizedBox(
                  width: 388,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 2,
                            width: double.infinity,
                            color: const Color(0xFF585b66),
                          ),
                          Container(
                            height: 2,
                            width: constraints.maxWidth *
                                (bufferedSeconds / totalSeconds),
                            color: const Color(0xFF96989f),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onHover: (event) {
                              setState(() {
                                double percent = event.localPosition.dx /
                                    constraints.maxWidth;
                                hoverSeconds = (percent * totalSeconds).clamp(
                                  0,
                                  totalSeconds,
                                );
                                hoverX = event.localPosition.dx;
                              });
                            },
                            onExit: (_) => setState(() => hoverSeconds = null),
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 0,
                                ),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: Colors.white,
                                trackShape: ZeroPaddingTrackShape(),
                              ),
                              child: Slider(
                                value: currentSeconds,
                                max: totalSeconds,
                                onChanged: (v) =>
                                    setState(() => currentSeconds = v),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // TIME LABELS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(currentSeconds),
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(totalSeconds),
                        style: TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // CONTROLS
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 291,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 33.6,
                          height: 33.6,
                          child: IconButton(
                            style: controlButtonStyle,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isRepeatOne ? Icons.repeat_one : Icons.repeat,
                              color: isRepeatOne ? Colors.green : Colors.white,
                              size: 28,
                            ),
                            onPressed: () =>
                                setState(() => isRepeatOne = !isRepeatOne),
                          ),
                        ),
                        SizedBox(
                          width: 33.6,
                          height: 33.6,
                          child: IconButton(
                            style: controlButtonStyle,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _prevSong,
                          ),
                        ),
                        SizedBox(
                          width: 67.2,
                          height: 67.2,
                          child: FilledButton(
                            style: playButtonStyle,
                            onPressed: _togglePlayback,
                            child: Center(
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 33.6,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 33.6,
                          height: 33.6,
                          child: IconButton(
                            style: controlButtonStyle,
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _nextSong,
                          ),
                        ),
                        SizedBox(
                          width: 33.6,
                          height: 33.6,
                          child: IconButton(
                            style: controlButtonStyle,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _playlist[_currentIndex]['isLiked'] = !isLiked;
                              });
                            },
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              tooltip: "Minimize",
              onPressed: () => setState(() => isMinimized = true),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Rest of classes remain unchanged)
class AutoMarquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  const AutoMarquee({super.key, required this.text, required this.style});
  @override
  State<AutoMarquee> createState() => _AutoMarqueeState();
}

class _AutoMarqueeState extends State<AutoMarquee> {
  late ScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      await Future.delayed(const Duration(seconds: 2));
      while (_scrollController.hasClients) {
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: (maxScroll * 45).toInt()),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}

class SoundWave extends StatefulWidget {
  final bool isPlaying;
  const SoundWave({super.key, required this.isPlaying});

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave> {
  List<double> heights = [10, 15, 8, 20];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _startAnimation();
  }

  @override
  void didUpdateWidget(SoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        heights = List.generate(
          4,
              (_) => (5 + (DateTime.now().millisecond % 20)).toDouble(),
        );
      });
    });
  }

  void _stopAnimation() {
    _timer?.cancel();
    setState(() {
      heights = [4, 4, 4, 4];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: heights.map((h) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: h,
          decoration: BoxDecoration(
            color: widget.isPlaying ? Colors.white : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}

class ZeroPaddingTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}