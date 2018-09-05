import Libav
using Test



modulepath(name) = realpath(joinpath(dirname(pathof(name)),".."))


# Example
# ffmpeg.exe -y -i foobar.mp4 -f image2pipe -vcodec ppm foobar.ppm
# output:
# 0x50, 0x36, 0x0a                                          P6^J
# 0x31, 0x36, 0x30, 0x20, 0x31, 0x32, 0x30, 0x0a            160 120^J 
# 0x32, 0x35, 0x35, 0x0a                                    255^J 
# ... 
function ppmheader_test()
    m = modulepath(Libav)
    p = joinpath(m, "test/foobar.mp4")
    d = joinpath(m, "test/foobar.ppm")
    Libav.ripvideo(p, d)
    # run(`ffmpeg.exe -y -i $p -f image2pipe -vcodec ppm $d`)
    h = Libav.ppmheader(d)
end
let h = ppmheader_test()
    @info h
end


function rgbintense_test()
    m = modulepath(Libav)
    p = joinpath(m, "test/alexa-hc-red.mp4")
    d = joinpath(m, "test/alexa-hc-red.ppm")
    Libav.ripvideo(p, d)
    rgb, noiseppm = Libav.rgbintense(d, 480, 640, 30, (2,4))
end
let (rgb, noiseppm) = rgbintense_test()
    @info noiseppm
    rm(joinpath(modulepath(Libav), "test/alexa-hc-red.ppm"))
end