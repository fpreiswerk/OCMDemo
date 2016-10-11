"""

"""
function build_ocm_lookup( ocm_data::Array{Float64,2},
  mr2us::Array{Int,2},
  width::Int,
  subsample_temporal::Int)

  a = size(ocm_data,1) # number of samples per timestep
  b = convert(Int,floor(width/subsample_temporal)) # number of TR's per image
  n_planes = size(mr2us,1) # number of planes
  n_MRI = size(mr2us,2) # number of MR images per plane

  ocm_data_lookup = zeros(Float64,a*b,n_MRI,n_planes)

  for plane=1:n_planes
    for i=1:n_MRI
      this_mr_ind_in_us = mr2us[plane,i]
      this_mr_us_trace_inds = floor(
      collect(this_mr_ind_in_us-width+1:subsample_temporal:this_mr_ind_in_us))
      if minimum(this_mr_us_trace_inds)<1
        # just for the beginning where indices could be negative
        ocm_data_lookup[:,i,plane] = 0
      else
        ocm_data_lookup[:,i,plane] = vec(ocm_data[:,this_mr_us_trace_inds])
      end
    end
  end

  return ocm_data_lookup

end
