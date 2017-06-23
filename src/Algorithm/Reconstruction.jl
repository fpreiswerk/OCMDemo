type Reconstruction
  indices::AbstractArray{Int64,3}
  scores::AbstractArray{Float64,3}
  valid_mri_inds::Array{Array{Int64,1},1}
  cough_labels_OCM::BitArray{1}

  Reconstruction(i::AbstractArray{Int64,3}, s::AbstractArray{Float64,3},
  v::Array{Array{Int64,1},1}, c::BitArray) = new(i,s,v,c)

end

function recon_highspeed_inside(mr_database::Array{Float64,4},
  U::Array{Float64,2},
  mr2us::Array{Int,2},
  properties::Dict{AbstractString,Any},
  experiment::Dict{AbstractString,AbstractString})

  TR = parse(Float64,properties["TR"]["value"]) # TR in ms
  N_TR = parse(Int64,properties["N_TR"]) # number of TR's per MR image
  kspace_sampling_idx = parse(Int64,properties["kspace_sampling_index"]) # Index of the TR when kspace is sampled
  N_x = parse(Int64,experiment["N_x"]) # number of USrd samples per TR
  slice_isect_sag = parse(Int64,properties["slice_isect_sag"]["value"])
  slice_isect_cor = parse(Int64,properties["slice_isect_cor"]["value"])
  K = parse(Int64,experiment["K"])
  n_planes = size(mr2us,1) # number of planes
  n_images = size(mr2us,2) # number of images per plane

  # for cough detection
  s_mu = parse(Int64,experiment["cough_detector_warmup_s"])
  alpha = convert(Int64,round(parse(Int64,experiment["cough_detector_alpha_ms"]) / TR))
  beta = convert(Int64,round(parse(Int64,experiment["cough_detector_beta_ms"]) / TR))
  sigma_fac = parse(Float64,experiment["cough_detector_sigma_fac"])

  # choose a good set of USrd variables for matching
  #high_variation_inds = compute_high_variation_inds(U, TR, N_x)
  # subsample the OCM data

  U_T = zeros(Float64,N_x * N_TR, n_images, n_planes)

  # Compute Sigma
  (Σ⁻¹,high_variation_inds) = compute_Sigma(U,TR,N_TR,N_x)

  # Here we vectorize (and replicate) the diagonal matrix Sigma for efficient
  # computation
  Σ⁻¹vec  = vec(repmat(Σ⁻¹,N_TR,1))

  U_ = zeros(Float64,length(high_variation_inds),size(U,2))

  # get the slice intersection pixels and prospectively compute a sigma for the
  # intersections
  MR_intersections = cat(3,
  mr_database[:,slice_isect_sag,1,:],mr_database[:,slice_isect_cor,2,:])
  MR_intersections = permutedims(MR_intersections,[1,3,2])
  #Σ_L = mean(mean(squeeze(std(MR_intersections[:,:,1:5],2),2),3),2)
  Σ_L = squeeze(squeeze(mean(std(MR_intersections[:,:,1:5],3),2),2),2)
  Σ_Lvec = vec(Σ_L) * length(Σ_L) # scaling to make intersection scores comparable to OCM scores
  Σ_L⁻¹vec = Σ_Lvec.^-1

  # prepare datastructures for parallel computing
  scores = convert(SharedArray,zeros(Float64,n_images,size(U,2),n_planes))

  indices = zeros(Int64,n_images,size(U,2),n_planes)
  indices_tmp = convert(SharedArray,zeros(Int64,n_images,size(U,2),n_planes))

  IJ_score_mat = zeros(Float64,n_images,n_images)

  scores_combined = zeros(Float64,n_images,n_images)
  scores_test = zeros(Float64,n_images^n_planes,size(U,2),n_planes)
  inds_test = zeros(Int64,n_images^n_planes,size(U,2),n_planes)

  scores_tmp = zeros(Float64,K,n_planes)
  inds_tmp = zeros(Int64,K,n_planes)

  # pre-allocation of buffers for optimized computation
  buf_U = OCMDemo.Buffer(N_TR,length(Σ⁻¹))
  buf_I = OCMDemo.Buffer(1,length(vec(Σ_L⁻¹vec)))

  # initialize the cough detector
  state = CoughDetectorState()
  cough_labels_MR = falses(size(mr2us,2),2) # zeros(length(mr2us[1]),n_planes)
  cough_labels_OCM = falses(size(U,2)) # zeros(size(us_database,1),2)

  current_MR_ind = ones(Int64,n_planes,1) # the currently acquired MR image
  last_MR_ind = ones(Int64,n_planes,1) # the last fully acquired MR image

  # init indices array for valid MR frames
  valid_mri_inds = Array{Array{Int64,1},1}(n_planes)
  ids_U_add = Array{Array{Int64,1},1}(n_planes)
  for p=1:n_planes
    valid_mri_inds[p] = zeros(Int64,0)
    ids_U_add[p] = zeros(Int64,0)
  end

  # main loop, for each TR (= OCM time step)
  @showprogress for i=1:size(U,2)

    # determine which MR image is currently being acquired (current_MR_ind)
    last_MR_ind = copy(current_MR_ind)
    for p=1:n_planes
      # clear any previous indices to be added to U_T
      ids_U_add[p] = Float64[]

      # mr2us points to the time when k-space center was acquired, relative to
      # the start of the acquisition. The beginning of acquisition t is at
      # mr2us[p,t] - kspace_sampling_idx + 1 and the last TR of the acquisition
      # is at mr2us[p,t] + (N_TR - kspace_sampling_idx), so at
      # mr2us[p,t] + (N_TR - kspace_sampling_idx) + 1 the acq is complete
      if last_MR_ind[p] < size(mr2us,2) &&
        i >= mr2us[p,current_MR_ind[p]] + (N_TR - kspace_sampling_idx + 1)
        # we have a new MR image

        # If none of the OCM traces of the previous image were labeled as cough,
        # the corresponding image is valid
        if current_MR_ind[p]>0 && cough_labels_MR[current_MR_ind[p],p] == false
          push!(valid_mri_inds[p],current_MR_ind[p])
        end

        # increment the current MR index
        current_MR_ind[p]+=1

        ids_U_add[p] = (mr2us[p,valid_mri_inds[p][end]]-N_TR+1):mr2us[p,valid_mri_inds[p][end]]
      end
    end

    # run cough detector for this OCM trace
    if i>1
      cough_detect!(state, U[:,collect(i-1:i)],
      TR, s_mu, sigma_fac, alpha, beta)
    end
    if state.is_cough
      # invalidate the corresponding MR frame if it was previously added
      cough_labels_OCM[i] = true
      for p=1:n_planes
        if current_MR_ind[p]>0
          cough_labels_MR[current_MR_ind[p],p] = true
        end
      end
    end

    # Envelope-detect and log the incoming OCM trace and retrieve relevant
    # variables
    U_[:,i] = log(abs(DSP.hilbert(U[:,i])[high_variation_inds,:]))

    sum(current_MR_ind == 0) && continue # MR acquisition has not yet started
    i-N_TR<1 && continue

    # the incoming OCM trace and its history (i-N_TR+1:i)
    U_t = vec(U_[:,collect(i-N_TR+1:i)])

    # if a new image acquisition is complete, compute
    # intersection scores and add OCM data to database
    p_new_I = find(diff([current_MR_ind last_MR_ind]'))

    for p=p_new_I

      # if this new image (the last fully acquired one) was labeled as a cough,
      # we don't add it to the database
      cough_labels_MR[last_MR_ind[p],p] && continue

      # walk through all intersections in an upper-triangular matrix fashion
      q=setdiff(collect(1:n_planes),p)[1]

      # get all intersection lines from the new image
      I_tL = view(MR_intersections,:,p,last_MR_ind[p])
      length(valid_mri_inds[q])==0 && continue

      # get intersection lines from all yet seen images of the other plane
      I_J = view(MR_intersections,:,q,valid_mri_inds[q])

      if p<q
        # fill in as row to the intersection score matrix
        kernel_regression!(view(IJ_score_mat,valid_mri_inds[p][end],
        valid_mri_inds[q]), I_tL, I_J, Σ_L⁻¹vec, buf_I)
      else
        tmp = permutedims(view(IJ_score_mat,valid_mri_inds[q],
        valid_mri_inds[p][end]:valid_mri_inds[p][end]),[2,1])
        kernel_regression!(vec(tmp), I_tL, I_J, Σ_L⁻¹vec, buf_I)
        IJ_score_mat[valid_mri_inds[q],
        valid_mri_inds[p][end]:valid_mri_inds[p][end]] = permutedims(tmp,[2 1])
      end

      # OCM time when k-space center of this new image was acquired
      this_mr_ind_in_us = mr2us[p,valid_mri_inds[p][end]]

      this_mr_us_trace_inds = ids_U_add[p]
      assert(length(this_mr_ind_in_us)>0)
      if minimum(this_mr_us_trace_inds)<1
        # fill up with dummy values where indices could be negative
        U_T[:,length(valid_mri_inds[p]),p] = 0 # yyy
      else
        # add all OCM traces corresponding to this MR image to database U_T
        U_T[:,length(valid_mri_inds[p]),p] =
        vec(U_[:,collect(this_mr_us_trace_inds)])
      end

    end

    @sync @parallel for p=1:n_planes

      if isempty(valid_mri_inds[p])
        # no image available from this plane yet
        continue
      end

      # match this OCM trace
      kernel_regression!(view(scores,1:length(valid_mri_inds[p]),i,p),
      U_t, view(U_T,:,1:length(valid_mri_inds[p]),p), Σ⁻¹vec, buf_U)

    end

    # compute a score for each combination of images from the two planes
    U_score_mat = vec(scores[1:length(valid_mri_inds[1]),i,1]) .*
    vec(scores[1:length(valid_mri_inds[2]),i,2])'
    final_score_mat = U_score_mat .*
    IJ_score_mat[1:length(valid_mri_inds[1]),1:length(valid_mri_inds[2])]
    f = final_score_mat[:]
    cnt=0
    cnt_i=1
    cnt_j=1

    while(true)
      (cnt_i>K && cnt_j>K) || length(f) <= cnt_i+1 || length(f) <= cnt_j+1? break : nothing
      cnt>length(f) ? break : nothing
      isempty(final_score_mat) ? continue : nothing
      x = findmax(f)

      # get row and column position of this maximum
      ij = ind2sub(final_score_mat,x[2])

      # row (plane 1)
      if cnt_i <= K && isempty(find(inds_test[1:cnt_i,i,1] .== ij[1]))
        inds_test[cnt_i,i,1] = ij[1]
        scores_test[cnt_i,i,1] = scores[ij[1],i,1]
        inds_tmp[cnt_i,1] = ij[1]
        scores_tmp[cnt_i,1] = scores[ij[1],i,1]
        cnt_i+=1
      end

      # column (plane 2)
      if cnt_j <= K && isempty(find(inds_test[1:cnt_j,i,2] .== ij[2]))
        inds_test[cnt_j,i,2] = ij[2]
        scores_test[cnt_j,i,2] = scores[ij[2],i,2]
        inds_tmp[cnt_j,2] = ij[2]
        scores_tmp[cnt_j,2] = scores[ij[2],i,2]
        cnt_j+=1
      end

      f[x[2]] = -1
      cnt+=1

    end

    scores[1:K,i,:] = copy(scores_tmp)
    indices[1:K,i,:] = copy(inds_tmp)

  end

  return Reconstruction(indices, scores, valid_mri_inds, cough_labels_OCM)
end
