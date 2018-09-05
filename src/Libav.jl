module Libav
using Random





function listdevices()
    try
        run(`ffmpeg -list_devices true -f dshow -i dummy`)
    catch
    end
end


function listoptions(device="Logitech HD Webcam C310")
    try
        run(`ffmpeg -f dshow -list_options true -i video="$(device)"`)
    catch
    end
end


function record(t, mp4="foobar.mp4", s="160x120", f=30, v="Logitech HD Webcam C310", a="Microphone (HD Webcam C310)")
    try
        run(`ffmpeg.exe -y -f dshow -t $t -video_size $s -framerate $f -pixel_format bgr24 -i video="$v":audio="$a" $mp4`)
    catch
    end
end


function ripaudio(mp4="foobar.mp4", wav="foobar.wav")
    try
        run(`ffmpeg.exe -y -i $mp4 $wav`)
    catch
    end
end

function ripvideo(mp4="foobar.mp4", ppm="foobar.ppm")
    try
        run(`ffmpeg.exe -y -i $mp4 -f image2pipe -vcodec ppm $ppm`)
    catch
    end
end


#P6
#1920 1080
#255
#<frame RGB>
function ppmheader(ppm)
    header = zeros(UInt8, 128)
    open(ppm, "r") do io
        read!(io, header)
    end
    return header
end


function udiff(a::UInt8, b::UInt8)
    a > b ? (a-b) : (b-a)
end


function rgbintense(ppm="foobar.ppm", h=480, v=640, fps=30, tsilent::Tuple{<:Real,<:Real}=(1,2))

    p6 = [0x50, 0x36, 0x0a]
    depth = [0x32, 0x35, 0x35, 0x0a]
    out = randstring()
    noisefloor = out * ".ppm"

    header = zeros(UInt8, length(p6) + length(string(h)) + 1 + length(string(v)) + 1 + length(depth))
    f0 = zeros(UInt8, h*v*3)
    fn = zeros(UInt64, h*v*3)
    fx = zeros(UInt8, h*v*3)

    n = 1
    open(ppm, "r") do io
        while !eof(io)
            read!(io, header)
            read!(io, fx)
            n += 1
        end
    end
    rgb = zeros(Float32, n, 3)
 
    open(ppm, "r") do io
        i1 = round(Int, tsilent[1] * fps)
        i2 = round(Int, tsilent[2] * fps)
        for i = 1:i1
            read!(io, header)
            read!(io, f0)
        end
        for i = i1+1:i2
            read!(io, header)
            read!(io, f0)
            fn .+= f0
        end
        f0 .= convert(Vector{UInt8},div.(fn,i2-i1))
    end
    open(noisefloor, "w") do io
        write(io, header)
        write(io, f0)
    end

    open(ppm, "r") do io
        i = 1
        while !eof(io)
            read!(io, header)
            read!(io, fx)
            # opt 1) signal[i] = sum(frame) - md
            # opt 2) signal[i] = udiff.(sum(frame), md)
            for k = 1:3
                rgb[i,k] = sum(udiff.(fx[k:3:end], f0[k:3:end])) / (h*v)
            end 
            i += 1
        end
        @assert i == n
    end
    # open(out * ".dat", "w") do f
    #     for j = 1:n
    #         write(f, "$(rgb[j,1]), $(rgb[j,2]), $(rgb[j,3])\n")
    #     end
    # end
    return rgb, out
end




function wavrgbintense(t, mp4, tsilent, wav)
    
    r = randstring()
    d = r * ".ppm"
    w = r * ".wav"

    Libav.record(t, mp4)
    Libav.ripvideo(mp4, d)
    rgb, out = Libav.rgbintense(d, 160, 120, 30, tsilent)
    Libav.ripaudio(mp4, w)
    x,fs = Libaudio.wavread(w)

    # norm rgb to [0,1]
    # mark x axis of rgb to sound track
    # merge new tracks

    rgb ./= maximum(rgb)
    rgbw = zeros(Float32, size(x,1), 3)
    n = size(rgb,1)
    for i = 1:n
        rgbw[round(Int, i/30 * convert(Float64, fs)),:] = rgb[i,:]
    end
    y = [x rgbw]
    Libaudio.wavwrite(y, wav, fs, 32)
    rm(d)
    rm(w)
    return y
end




end # module
