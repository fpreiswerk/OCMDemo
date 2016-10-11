"""
Preallocation for evaluation of kernel
"""
type Buffer

  width::Int64
  height::Int64
  buf1::Array{Float64,1}
  buf2::Array{Float64,1}

  function Buffer(width::Int64, height::Int64)

    buf1 = zeros(width*height)
    buf2 = zeros(width*height)
    inds = Array{Range,1}(width)
    ids = collect(-height-1:0)
    new(width,height,buf1,buf2)

  end

end
