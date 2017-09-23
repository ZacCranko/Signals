nframes(ss::AbstractSignal) = length(ss.data)

@inline function duration(ss::AbstractSignal, fr = nframes(ss))
    t = (fr - 1)/ samplerate(ss)
    return (t == 0s ? s : t < 1ms ? μs : t < 1s ? ms : t < 1minute ? s : t < 1hr ? minute : hr)(t)
end

function show(io::IO, ss::AbstractSignal; blocks = displaysize()[2] - 2)
    type_str = string(typeof(ss))
    t = duration(ss)
    dur_str = @sprintf "%s fr (%0.2f %s)" nframes(ss) ustrip(t) unit(t)
    println(io, type_str, " ",  lpad(dur_str, displaysize()[2] - 1 - length(type_str)))
    if nframes(ss) > 0
        if isa(ss, SubSignal)
            stime = duration(ss, ss.start)
            etime  = stime + duration(ss)
            first_str = @sprintf "(%0.2f %s)" ustrip(stime) unit(stime)
            last_str  = @sprintf "(%0.2f %s)" ustrip(etime) unit(etime)
            println(io, rpad(first_str, displaysize()[2] - length(last_str)), last_str)
        end
        _blocks = min(nframes(ss), blocks)
        step =  nframes(ss) < blocks ? 1 : /(nframes(ss) - 1, _blocks - 1)
        for ch in 1:nchannels(ss)
            @printf io "[%s]\n" join(tick_string(ss[round(Int, 1 + (t-1)*step)][ch]) for t in 1:_blocks)
        end
    end
end

time2frame(sr::Frequency,      t::Time) = trunc(Int, sr*t) + 1
time2frame(ss::AbstractSignal, t::Time) = time2frame(samplerate(ss), t) 
time2frame(ss::AbstractSignal, t::TimeRange) = colon(time2frame(ss, first(t), last(t))...)
time2frame(ss::AbstractSignal, varg::Vararg{Time, N}) where N = map(t->time2frame(ss,t), varg)

copy(ss::Signal{NCh,T,SR})    where {NCh,T,SR} = Signal{NCh,T,SR}(copy(ss.data))
view(ss::Signal{NCh,T,SR}, i) where {NCh,T,SR} = SubSignal{NCh,T,SR}(first(i), view(ss.data, i))

for f in (:length, :size, :start, :endof, :eltype)
    @eval $f(ss::AbstractSignal) = $f(ss.data)
end
for f in (:getindex, :next, :done)
    @eval $f(ss::AbstractSignal, i::Int) = $f(ss.data, i::Int)
end

@inline function getindex(ss::Signal{NCh,T,SR}, r::Range{Int}) where {NCh,T,SR}
    @boundscheck 0 < first(r) && last(r) <= nframes(ss) || 0 < last(r) && first(r) <= nframes(ss) || throw(BoundsError())
    slice = Vector{SignalFrame{NCh, T}}(length(r))
    for (i, fr) in enumerate(r)
        @inbounds slice[i] = ss[i]
    end
    return Signal{NCh,T,SR}(slice)
end

getindex(ss::AbstractSignal, t::Time)              = getindex(ss, time2frame(ss, t))
getindex(ss::AbstractSignal, r::TimeRange)         = getindex(ss, colon(time2frame(ss, first(r), last(r))...))
setindex!(ss::AbstractSignal, value, key...)       = setindex!(ss.data, value, key...)
setindex!(ss::AbstractSignal, value, t::Time)      = setindex!(ss.data, value, time2frame(ss, t))
setindex!(ss::AbstractSignal, value, r::TimeRange) = setindex!(ss, value, colon(time2frame(ss, first(r), last(r))...))

function convert(::Type{Signal}, buf::SampledSignals.SampleBuf{T}) where T
    n, NCh = size(buf)
    sig = Signal{NCh,T,buf.samplerate*Hz}(n)
    for i in 1:nframes(sig)
        @inbounds sig[i] = buf.data[i,:]
    end
    return sig
end

# convert bitdepth
function convert(::Type{Signal{NCh,T}}, ss::Signal{NCh,U}) where {NCh,T,U}
    data = convert(Vector{SignalFrame{NCh,T}}, ss.data)
    return Signal{NCh,T,SR}(data)
end

function demux(ss::Signal{NCh,T,SR}, chs) where {NCh,T,SR}
    maximum(chs) <= NCh || throw(BoundsError())
    NChOut = length(chs)
    demuxed = Signal{NChOut,T,SR}(nframes(ss))
    for t in 1:nframes(ss)
        @inbounds demuxed[t] = ss[t][chs]
    end
    return demuxed
end

demux(ss::Signal, args::Vararg{Any,N}) where N = map(chs->demux(ss, chs), args)

function mux(varg::Vararg{S,N}) where S<:Signal where N
    nfr = nframes(varg[1])
    all(nframes(f) == nfr for f in varg) || throw("All signals must be of the same length")
    
    NCh = mapreduce(nchannels, +, varg)
    T   = promote_type(map(bitdepth,  varg)...)
    SR  = mean(map(samplerate, varg))
    ret = Signal{NCh,T,SR}(nfr)
    
    @inbounds for i in 1:nfr
        fr = Tuple{}()
        for s in varg
            @inbounds fr = (fr..., s[i]...)
        end
        ret[i] = SignalFrame(fr)
    end
    return ret
end