#P6
#1920 1080
#255
#<frame RGB>
header = zeros(UInt8, 128)
read!(stdin, header)
println(header)
# ffmpeg.exe -i foobar.mp4 -f image2pipe -vcodec ppm pipe:1 | julia ppmhead.jl