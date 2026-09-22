Rain uses the existing project recording, rain.mp3.

white_noise.wav is generated white noise: 30 seconds of mono, 44.1 kHz,
16-bit PCM. Samples use Python random.Random(20260922), uniform(-1, 1),
multiplied by 5500 and rounded to integers. No third-party recording is used.
Both audio files are bundled for offline looping playback.
