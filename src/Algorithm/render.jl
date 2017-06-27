using Images, Colors

function render_images(indices::AbstractArray{Int64,2}, scores::AbstractArray{Float64,2},
  images::Array{Float64,4}, valid_mri_inds::Array{Array{Int64,1},1}, K::Int64)

  images_out = zeros(Float64,size(images,1),size(images,2),size(scores,2))

  for p=1:size(scores,2)
    inds = indices[:,p][1:K]
    weights = scores[:,p][1:K]

    sx = size(images,1)
    sy = size(images,2)

    image_rec = zeros(Float64,sx,sy)
    for i=1:K
      if weights[i]>0
        image_rec += images[:,:,p,valid_mri_inds[p][inds[i]]] .* weights[i]
      end
    end
    image_rec /= sum(weights)

    if length(find(isnan(image_rec)))>0
      image_rec[:] = 0
    end

    images_out[:,:,p] = image_rec
  end

  return images_out
end

# function render_movie(scores::Array{Float64,3}, images::Array{Float64,4},
#   valid_mr_inds::Array{Array{Int64,1},1}, K::Int64, dest::AbstractString)
#
#   for t=1:size(scores,1)
#     im = render_images(squeeze(scores[t,:,:],1), images, valid_mr_inds, K)
#     for p=1:size(scores,3)
#       fn = @sprintf "frame_planes%s_%05i.png" p t
#       save(joinpath(dest,fn),Images.grayim(im[:,:,p])')
#     end
#   end
# end
#
# function write_movie(dir::AbstractString,
#   properties::Dict{AbstractString,AbstractString})
#
#   TR = float(properties["TR"])
#   input_framerate = 1000/TR
#
#   println("Rendering using ffmpeg...")
#   command = string("ffmpeg -framerate ",@sprintf("%1.3f ", input_framerate),
#   "-i $dir/frame\%05d.png ", "-c:v libx264 -r 30 ",
#   "-pix_fmt yuv420p ", "$dir/out.mp4")
#
#   run(`command`)
#   println("... done")
# end

function render_mmodes(rec::Reconstruction, mr_database::Array{Float64,4},
  parameters::Dict{AbstractString,Any},
  experiment::Dict{AbstractString,AbstractString})

  mmode = SharedArray(Float64,size(rec.scores,2),size(mr_database,1),3,2)
  K = parse(Int,experiment["K"])

  mr_database_ = zeros(Float64,size(mr_database,1),1,size(mr_database,3),size(mr_database,4))
  mr_database_[:,:,1,:] = mr_database[:,parse(Int64,parameters["smri_mmode_pos_sag"]["value"]),1,:]
  mr_database_[:,:,2,:] = mr_database[:,parse(Int64,parameters["smri_mmode_pos_cor"]["value"]),2,:]

  for t=1:size(rec.scores,2)
    i = view(rec.indices,:,t,:)
    w = view(rec.scores,:,t,:)
    im = render_images(i,w, mr_database_, rec.valid_mri_inds, K)

    mmode[t,:,:,1] = repmat(im[:,:,1],1,3)
    mmode[t,:,:,2] = repmat(im[:,:,2],1,3)
  end

  # normalize to [0,1] and mark coughs in red
  for p=1:size(mmode,4)

    mmode[:,:,:,p] = mmode[:,:,:,p] - minimum(mmode[:,:,:,p])
    mmode[:,:,:,p] = mmode[:,:,:,p] / maximum(mmode[:,:,:,p])
    mmode[find(rec.cough_labels_OCM),collect(1:30),1,p] = 1
  end

  return mmode

end

function render_corresponding_synthetic(rec::OCMDemo.Reconstruction, mr_database::Array{Float64,4},
  mr2us::Array{Int64,2}, experiment::Dict{AbstractString,AbstractString})

  images = SharedArray(Float64,size(mr2us,2),size(mr_database,1),size(mr_database,2),2)

  K = parse(Int,experiment["K"])

  for t=1:size(mr2us,2)
    i_sag = view(rec.indices,:,mr2us[1,t],1:1)
    w_sag = view(rec.scores,:,mr2us[1,t],1:1)
    images[t,:,:,1] = render_images(i_sag,w_sag, mr_database, rec.valid_mri_inds, K)
    i_cor = view(rec.indices,:,mr2us[2,t],2:2)
    w_cor = view(rec.scores,:,mr2us[2,t],2:2)
    images[t,:,:,2] = render_images(i_cor,w_cor, mr_database, rec.valid_mri_inds, K)
  end

  return images

end
