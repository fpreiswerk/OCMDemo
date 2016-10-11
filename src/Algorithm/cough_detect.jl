type CoughDetectorState

  t::Int64
  is_cough::Bool
  moving_average::Float64
  sigma::Float64
  gradients_accepted::Array{Float64}
  alpha_count::Int64
  beta_count::Int64

  CoughDetectorState() = new(0,false,0,0,Array{Float64,1}(),0,0)

end

function cough_detect!(state::CoughDetectorState, USrd::Array{Float64,2}, dt::Float64, s_mu::Int64, sigma_fac::Float64, alpha::Int64, beta::Int64 )
  state.is_cough = false
  state.t += 1

  n_warmup = convert(Int64,round(s_mu * 1000 / dt))

  v_t = norm(diff(USrd,2),1) # Equation 13

  if length(state.gradients_accepted)<=n_warmup
    # warmup phase
    state.moving_average = mean(state.gradients_accepted)
    state.sigma = std(state.gradients_accepted)
    push!(state.gradients_accepted, v_t)

  else
    # regular mode of operation
    state.moving_average = mean(state.gradients_accepted[end-n_warmup+1:end])

    if state.beta_count>0
        # currently inside a cough drag period
        state.is_cough = true
        state.beta_count -= 1
        return
    end

    triggered = abs(v_t-state.moving_average)>state.sigma*sigma_fac

    if !triggered && state.beta_count<=0
        # neither above spatial threshold nor currently in a cough
        push!(state.gradients_accepted, v_t)
        state.alpha_count = 0
    elseif triggered && state.alpha_count >= alpha
        # above spatial threshold, exceeding temporal threshold
        state.beta_count = beta
        state.is_cough = true
    elseif triggered
        # above spatial threshold, but not yet above temporal threshold
        state.alpha_count += 1
    end

    state.beta_count -= 1

  end

end
