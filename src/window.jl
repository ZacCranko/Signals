@inline function window(ss::Signal, step::Int, len::Int)
    n = div(nframes(ss) - len, step) + 1
    return (view(ss, colon(1 + (i-1)*step, (i-1)*step + len)) for i in 1:n)
end
@inline window(ss::Signal, step::Time, len::Time) = window(ss, time2frame(ss, step, len)...)

@inline function window(ss::Signal{NCh,T,SR}, step::Int, flt::Signal{1,U,SR}) where {NCh,T,U,SR}
    return (w .* flt for w in window(ss, step, nframes(flt)))
end
@inline window(ss::Signal{NCh,<:Real,SR}, step::Time, flt::Signal{1,<:Real,SR}) where {NCh,SR} = window(ss, time2frame(ss, step), flt)

function _show_windowing(ss::Signal; blocks = displaysize()[2] - 2)
    t = duration(ss)
    dur_str = @sprintf "%0.2f %s" ustrip(t) unit(t)
    println(lpad(dur_str, displaysize()[2]))
    if nframes(ss) > 0
        _blocks = min(nframes(ss), blocks)
        step =  nframes(ss) < blocks ? 1 : /(nframes(ss) - 1, _blocks - 1)
        for ch in 1:nchannels(ss)
            @printf "[%s]\n" join(tick_string(ss[round(Int, 1 + (t-1)*step)][ch]) for t in 1:_blocks)
        end
    end
end


function show_windowing(ss_iter)
    for ss in ss_iter
        _show_windowing(ss)
    end
end

