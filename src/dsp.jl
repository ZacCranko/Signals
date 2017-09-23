function peak(ss::Signal)
    pk = zero(eltype(ss))
    for frame in ss
        pk = splmax(pk, frame)
    end
    return pk
end

function generate_sine(dur::Time, freq::Frequency; sr::Frequency = 44.1kHz)
    T = Float32
    sig   = Signal{1,T,sr}(time2frame(sr, dur))
    coeff = Float64(freq * 2pi / sr)
    for i in 1:nframes(sig)
        j = i-1
        sig[i] = sin(coeff * j)
    end
    return sig
end