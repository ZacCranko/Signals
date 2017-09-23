module Signals
using FixedPointNumbers, Unitful
import LibSndFile, SampledSignals

# signal frames
import Base: convert, show, copy,
    # array functions
    done, length, size, start, endof, next, first, last, colon,
    view, setindex!, getindex, eltype,
    # math functions
    zero, one, +, -, *, /, abs, sqrt, log, sum, max, min, maxabs

import SampledSignals: samplerate, nframes
import Unitful: Time, Frequency

@unit kHz "kHz" KiloHertz 1000/u"s" true
const Hz     = u"Hz"   
const MHz    = u"MHz"   
const hr     = u"hr"
const minute = u"minute"
const s      = u"s"
const ms     = u"ms"
const μs     = u"μs"

function tick_string(_x::Real)
    x = convert(Float64, _x)
    ticks = (' ', '⡀','⣀', '⣄', '⣤', '⣦', '⣶', '⣷', '⣿')
    n = length(ticks)
    if real2dbfs(x) > 1
        return ticks[end]
    elseif real2dbfs(x) < -60
        return ticks[1]
    else
        return ticks[trunc(Int, (n - 1)*(60 + real2dbfs(x))/60 + 1)]
    end
end

real2dbfs(x)  = 20log10(abs(x))

for f in (:types, :signalframe, :signal, :window, :dsp)
    include("$f.jl")
end

load(path)::Signal = LibSndFile.load(path)

export 
    # unitful
    Time, Frequency, hr, minute, s, ms, μs, MHz, kHz, Hz,
    # types
    AbstractSignal, Signal, SignalFrame,
    nchannels, bitdepth, samplerate, nframes, duration, 
    demux, splmax, splmin, window, load,
    # dsp
    peak, generate_sine
end # module