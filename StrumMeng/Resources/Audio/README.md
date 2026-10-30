# Listen guitar samples

The supplied recordings are bundled locally. Their Up/Down direction labels follow the project
owner's mapping; the code does not classify strum direction.

- Active Down: `Listen_Down_2.wav` (existing sample selected by the project owner).
- Active Up: `Listen_Up_Extracted.wav`, cropped from the owner-supplied
  `C_AcousticGuitar_RodrigoMercador_3.wav`.

The combined take has strong attacks around 0.12 s and 0.54 s. The extracted Up begins at
0.505 s, just before the second attack, and ends at 2.505 s. A 3 ms fade-in avoids an edge click;
the final 30 ms fades out. The downstroke's lingering resonance cannot be completely removed by
cropping. The original files and previous sample variants are retained.

Reproduce with FFmpeg (replace SOURCE and OUTPUT with the appropriate paths):

```sh
ffmpeg -i SOURCE.wav \
  -af 'atrim=start=0.505:end=2.505,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.003,afade=t=out:st=1.97:d=0.03' \
  -ac 1 -ar 16000 -c:a pcm_s16le OUTPUT.wav
```

Listen composes the selected pattern from these samples with natural overlapping decay. Rest
slots have no new attack, but an earlier strum can still ring through a rest.
