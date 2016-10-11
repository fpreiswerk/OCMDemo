"""
Compute the covariance matrix Σ from the first 5 seconds seconds of OCM signals
"""
function compute_Sigma( ocm_data::Array{Float64,2},
  TR::Float64,
  N_TR::Int64,
  N_x::Int64)

  first_nonzero = findfirst(ocm_data[1,:]!=0)
  U_ = ocm_data[:,collect(first_nonzero:first_nonzero+convert(Int64,floor(5000/TR)))]
  U_ = abs(DSP.hilbert(U_)) # envelope-detection
  U_ = log(U_) # simple version of attenuation correction
  Σ  = std(U_,2)

  high_variation_inds = sortperm(Σ[:,1],rev=true)[1:N_x]
  Σ = Σ[high_variation_inds].^-1

  # scale according to Equation 15
  Σ = Σ / ( (N_x * N_TR) * exp(TR/10) )

  return Σ, high_variation_inds
end
