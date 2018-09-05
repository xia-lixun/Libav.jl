# Libav.jl
Interface to physical world via acoustics and optics

1) header:
to stdin: ffmpeg.exe -i alexa-highcontrast.mp4 -f image2pipe -vcodec ppm pipe:1 | julia ppm_head.jl
to file: ffmpeg.exe -y -i test\foobar.mp4 -f image2pipe -vcodec ppm test/foobar.ppm

2) RGB intensity
to stdin: ffmpeg.exe -i alexa-highcontrast.mp4 -f image2pipe -vcodec ppm pipe:1 | julia ppm.jl


Basic operations:
    ffmpeg -list_devices true -f dshow -i dummy
    ffmpeg -f dshow -list_options true -i video="Logitech HD Webcam C310"
    ffmpeg.exe -f dshow -t 1.44 -video_size 160x120 -framerate 30 -pixel_format bgr24 -i video="Logitech HD Webcam C310":audio="Microphone (HD Webcam C310)" foobar.mp4