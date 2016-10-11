function kernel_regression!( ret::AbstractArray{Float64,1},
  predictor::AbstractArray{Float64,1},
  lookup::AbstractArray{Float64,2},
  Sigma_inv::AbstractArray{Float64,1},buf::Buffer)

  @inbounds for j=1:size(lookup,2)
    broadcast!(.-, buf.buf1, view(lookup,:,j), predictor)
    broadcast!(.*, buf.buf2, buf.buf1, Sigma_inv)
    inds = collect(-buf.height:0)
    ret[j] = 0
    @inbounds for i=1:buf.width
      broadcast!(+, inds, inds, buf.height)
      #this is fast ...
      #@fastmath @inbounds ret[j] += dot(view(buf.buf1,inds),view(buf.buf2,inds))
      #but the following is even faster
      @fastmath @inbounds @simd for k=1:length(inds)
         ret[j] += buf.buf2[inds[k]] * buf.buf1[inds[k]]
      end
    end
    ret[j] = exp(-0.5*ret[j])
  end

end
