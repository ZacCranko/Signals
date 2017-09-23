# Sample frames
struct SignalFrame{NCh, T<:Real}
    frame::NTuple{NCh, T}

    SignalFrame{NCh,T}(frame::NTuple{NCh,T}) where {NCh,T} = new(frame)
end
SignalFrame{NCh,T}(args::Vararg{<:Real,NCh}) where {NCh,T} = SignalFrame{NCh,T}(NTuple{NCh,T}((args)))
SignalFrame(args::Vararg{T,NCh})       where {NCh,T<:Real} = SignalFrame{NCh,T}(NTuple{NCh,T}((args)))

abstract type AbstractSignal{NCh,T,SR} end

const MonoSignal{T,SR} = AbstractSignal{1,T,SR} where {T,SR}

nchannels(ss::AbstractSignal{NCh,T,SR})  where {NCh,T,SR} = NCh
bitdepth(ss::AbstractSignal{NCh,T,SR})   where {NCh,T,SR} = T
samplerate(ss::AbstractSignal{NCh,T,SR}) where {NCh,T,SR} = SR

struct Signal{NCh,T,SR} <: AbstractSignal{NCh,T,SR}
    data::AbstractVector{SignalFrame{NCh,T}}
    Signal{NCh,T,SR}(data::AbstractVector{SignalFrame{NCh,T}}) where {NCh,T,SR} = new{NCh,T,Quantity{Float64}(kHz(isa(SR, Quantity) ? SR : SR*Hz))}(data)
end

Signal{NCh,T,SR}(n::Int) where {NCh,T,SR} = Signal{NCh,T,SR}(Vector{SignalFrame{NCh,T}}(n))
Signal{NCh,T,SR}()       where {NCh,T,SR} = Signal{NCh,T,SR}(0)

struct SubSignal{NCh,T,SR} <: AbstractSignal{NCh,T,SR}
    start::Int
    data::AbstractVector{SignalFrame{NCh,T}}
    SubSignal{NCh,T,SR}(start::Int, data::AbstractVector{SignalFrame{NCh,T}}) where {NCh,T,SR} = new{NCh,T,Quantity{Float64}(kHz(isa(SR, Quantity) ? SR : SR*Hz))}(start, data)
end

struct TimeRange
    start::Time
    stop::Time
end

colon(start::T, stop::U) where {T<:Time, U<:Time} = TimeRange(start, stop)
show(io::IO, r::TimeRange) = print(io, repr(first(r)), ':', repr(last(r)))
first(r::TimeRange)  = r.start
last(r::TimeRange)   = r.stop
length(r::TimeRange) = last(r) - first(r)