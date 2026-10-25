# Demo media

`survivors-demo.gif` is a six-second excerpt (00:18–00:24) from
`Screen Recording 2026-10-24 at 12.57.52 PM.mov`, recorded gameplay supplied for this example.
The 233 MB original recording is not included in the repository.

The GIF loops at 10 fps, is 640 pixels wide and uses a 128-colour palette.
Generated with FFmpeg 7.0.2:

```sh
ffmpeg -ss 18 -i "$RECORDING" -t 6 \
  -filter_complex '[0:v]fps=10,scale=640:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle' \
  -loop 0 assets/survivors-demo.gif
```

Bendvy's README screenshot comes from 00:20 of the same recording, scaled to
800 pixels wide and displayed at 480 pixels.
