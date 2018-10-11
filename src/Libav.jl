module Libav

import BinDeps
using Dates
using SHA
using Random
using Libaudio


folder() = normpath(joinpath(@__FILE__, "../../deps"))


function uninstall()
    rm(joinpath(folder(), "FFmpeg"), force=true, recursive=true)
end


function isinstalled() 
    ok = isdir(joinpath(folder(), "FFmpeg"))
end

download(x) = run(BinDeps.download_cmd(x, basename(x)))

function fetch(url, file, sha256r, app)
    download("$(url)$(file)")
    sha256c = open("$file") do io
        sha256(io)
    end
    if isequal(bytes2hex(sha256c), lowercase(sha256r))
        printstyled("SHA256 ok, extracting...\n", color=:light_cyan)
        run(`7z x $file -o$app`)
    else
        printstyled("SHA256 mismatch, nothing installed, please try again\n", color=:light_red)
    end
    rm(file)
end


function install()
    dir = folder()  
    !isdir(dir) && mkpath(dir)
    uninstall()
    cd(dir) do
      if Sys.iswindows()
        # arch = Int == Int64 ? "x64" : "x86"
        url = "https://ffmpeg.zeranoe.com/builds/win64/static/"
        file = "ffmpeg-4.0.2-win64-static.zip"
        sha256r = "2BF3726D7B489F1FE5609E1F9D93D827FD9E9C9D21B829B254A5BAE0C3F60EC8"
        fetch(url, file, sha256r, "FFmpeg")        
      end
    end  
end





function listdevices()
    ffmpeg = joinpath(folder(), "FFmpeg/ffmpeg-4.0.2-win64-static/bin/ffmpeg.exe")
    try
        Sys.iswindows() && run(`$ffmpeg -list_devices true -f dshow -i dummy`)
        Sys.islinux() && run(`v4l2-ctl --list-devices`)
    catch
    end
end


function listoptions(device="Logitech HD Webcam C310")
    ffmpeg = joinpath(folder(), "FFmpeg/ffmpeg-4.0.2-win64-static/bin/ffmpeg.exe")
    try
        Sys.iswindows() && run(`$ffmpeg -f dshow -list_options true -i video="$(device)"`)
        Sys.islinux() && run(`ffmpeg -f v4l2 -list_formats all -i /dev/video0`)
    catch
    end
end


function record(t, mp4="foobar.mp4", s="160x120", f=30, v="Logitech HD Webcam C310", a="Microphone (HD Webcam C310)")
    ffmpeg = joinpath(folder(), "FFmpeg/ffmpeg-4.0.2-win64-static/bin/ffmpeg.exe")
    try
        Sys.iswindows() && run(`$ffmpeg -y -f dshow -t $t -video_size $s -framerate $f -pixel_format bgr24 -i video="$v":audio="$a" $mp4`)
        if Sys.islinux()
            wav = mp4[1:end-3] * "wav"
            open("capture.sh", "w") do io
                write(io, "ffmpeg -y -t $t -f alsa -ac 1 -ar 48000 -i hw:1 $wav &\n")
                write(io, "ffmpeg -y -t $t -f v4l2 -framerate $f -video_size $s -i /dev/video0 $mp4\n")
            end
            run(`chmod +x capture.sh`)
            run(`./capture.sh`)
        end
    catch
    end
end


function ripaudio(mp4="foobar.mp4", wav="foobar.wav")
    ffmpeg = joinpath(folder(), "FFmpeg/ffmpeg-4.0.2-win64-static/bin/ffmpeg.exe")
    try
        run(`$ffmpeg -y -i $mp4 $wav`)
    catch
    end
end

function ripvideo(mp4="foobar.mp4", ppm="foobar.ppm")
    ffmpeg = joinpath(folder(), "FFmpeg/ffmpeg-4.0.2-win64-static/bin/ffmpeg.exe")
    try
        run(`$ffmpeg -y -i $mp4 -f image2pipe -vcodec ppm $ppm`)
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
    Sys.iswindows() && Libav.ripaudio(mp4, w)
    x,fs = Libaudio.wavread(w)

    # norm rgb to [0,1]
    # mark x axis of rgb to sound track
    # merge new tracks

    rgb ./= maximum(rgb)
    nx = size(x,1)
    rgbw = zeros(Float32, nx, 3)
    n = size(rgb,1)
    for i = 1:n
        rgbw[max(min(round(Int, i/30 * convert(Float64, fs)), nx),1), :] = rgb[i,:]
    end
    y = [x rgbw]
    Libaudio.wavwrite(y, wav, fs, 32)
    rm(d)
    rm(w)
    return y
end




end # module
