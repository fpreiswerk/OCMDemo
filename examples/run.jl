using OCMDemo, Images, FileIO

experiment_file = "A1.xml"

datasets = load_datasets_xml(
  joinpath(Pkg.dir("OCMDemo"),"datasets","datasets.xml"))
experiment = load_experiment_xml(
  joinpath(Pkg.dir("OCMDemo"),"experiments",experiment_file))

# load training data
learning_acq = get_learning_acquisition(datasets,experiment)
properties = get_dataset_properties(datasets,experiment)
parameters = get_dataset_parameters(datasets,experiment)
mr_database = get_MR_images(learning_acq)
us_database = get_US_data(learning_acq)
mr2us = get_mr2us(learning_acq)

# load prediction data
prediction_acq = get_prediction_acquisition(datasets,experiment)
us_data = get_US_data(prediction_acq)

# run the reconstruction
@time result = recon_highspeed_inside(
  mr_database, us_data, mr2us,properties,experiment)

# render m-mode visualizations of the result
mmode = render_mmodes(result, mr_database,parameters,experiment)

# save as images and open in system default image viewer
save("mmode_sagital.png",colorim(mmode[:,:,:,1]))
save("mmode_coronal.png",colorim(mmode[:,:,:,2]))
run(`open mmode_sagital.png`)
run(`open mmode_coronal.png`)

exit()

data = grayim(mmode[:,:,1,1])
im = Images.imresize(data,(2000,196,1))
im_y = resize(data,(2000,196,20))

im = colorim(mmode[:,:,:,1])
im = Images.imresize(im,(2000,196))
save("/tmp/p1.png",im)
save("/tmp/p1.png",colorim(mmode[:,:,:,1]))

#im1 = Images.imresize(mmode[:,:,:,1],(2000,196,3))

save("/tmp/p1.png",grayim(im1[:,:,1]))

save("/tmp/p1.png",colorim(im1))


save("/tmp/p1.png",Images.imresize(colorim(mmode[:,:,:,1]),(2000,196,3)))
save("/tmp/p2.png",Images.imresize(colorim(mmode[:,:,:,2]),(2000,196,3)))

run(`open /tmp/p1.png`)
run(`open /tmp/p2.png`)

tmp = Images.imresize(mmode[1],(2000,196,3))

tmp = Images.imresize(Images.flipx(convert(Image,mmode[:,:,:,1])),(2000,196,3))
save("/tmp/p1_.png",tmp)
run(`open /tmp/p1_.png`)
tmp = Images.imresize(convert(Image,mmode[:,:,:,2]'),(2000,196))
save("/tmp/p2_.png",tmp)
run(`open /tmp/p2_.png`)
exit()
using ImageView
view(mmode[:,:,1])
view(mmode[:,:,2])

mmode = SharedArray(Float64,size(mr_database,1),size(result.scores,2),2)
K = parse(Int,experiment["K"])
t=8720
t=1294
i = squeeze(view(result.indices,:,t,:),2)
w = squeeze(view(result.scores,:,t,:),2)
im = render_images(i,w, mr_database, result.valid_mri_inds, K)




# using JLD
# save("/tmp/foo.jld","i",i,"w",w,"mr_database",mr_database,"result",result,"K",K)
# d = load("/tmp/foo.jld")
# i = d["i"]
# w = d["w"]
# mr_database = d["mr_database"]
# result = d["result"]
# K = d["K"]


@show result.valid_mri_inds
@show i
@show w

mmode[:,t,1] = im[:,100,1]
mmode[:,t,2] = im[:,100,2]


using JLD
using Senthetic
x=load("/tmp/tmp.jld")
result = x["result"]


X = zeros(Int64,10,20)
X = rand(10,20)

x=2

# using Images
# save("/tmp/p1.png",convert(Image,mmode[:,:,1]))
# save("/tmp/p2.png",convert(Image,mmode[:,:,2]))
# exit()
#
# save("/tmp/img.png",mmode[:,:,1])




#render_movie(scores, mr_database, valid_mr_inds, parse(Int64,experiment["K"]),
#  get_output_dir(datasets,experiment))


#
#
# using Debug
#
# cd("/Users/frank/code/julia/highspeed_usmr/")
# import Hwloc
# topology = Hwloc.topology_load()
# counts = Hwloc.histmap(topology)
# ncores = counts[:Core]
# npus = counts[:PU]
# println("This machine has $ncores cores and $npus PUs (processing units)")
# addprocs(ncores-1)
#
# @everywhere include("Algorithm/compute_frame.jl")
# @everywhere include("Algorithm/kernel_regression.jl")
# include("Algorithm/build_lookup_usdata.jl")
# include("Algorithm/compute_power_indices.jl")
# include("Algorithm/compute_Sigma.jl")
# include("Algorithm/cough_detect.jl")
# include("recon_highspeed.jl")
#
# data_root = "/Users/frank/code/julia/highspeed_usmr/"
# push!(LOAD_PATH, "/Users/frank/code/julia/highspeed_usmr/DatasetManagement")
# using DatasetManagement
# using JLD
# using FileIO
# using Images
#
# config_file = "/Users/frank/data/bwh_hdf5/datasets.xml"
# cfg = load_datasets_xml(config_file)
#
# experiment_param_file = "/Users/frank/experiments/parameters.xml"
# experiment_params = load_experiment_xml(experiment_param_file)
#
# # load training data
# learning_acq = cfg[experiment_params["dataset"]].acquisitions[
# parse(Int,experiment_params["learning_acquisition"])]
# properties = cfg[experiment_params["dataset"]].properties
# load_all_resources!(learning_acq)
# mr_database = learning_acq.resources["mr_data"].data["I"]
# # normalize images to [0 1]
# for p=1:size(mr_database,3)
#   tmp = mr_database[:,:,p,:]
#   mr_database[:,:,p,:] = tmp / maximum(tmp[:])
#   clamp!(mr_database, 0, 1)
# end
# us_database = learning_acq.resources["us_data"].data
#
# mr2us = Array{Int64,2}
# count=1
# for key in sort(collect(keys(learning_acq.resources["mr2us"].data)))
#   d = learning_acq.resources["mr2us"].data[key]
#   if(count==1)
#     mr2us = Array{Int64,2}(
#     length(collect(keys(learning_acq.resources["mr2us"].data))), length(d))
#   end
#   mr2us[count,:] = d
#   count += 1
# end
#
# # load prediction data
# prediction_acq = cfg[experiment_params["dataset"]].acquisitions[
# parse(Int,experiment_params["learning_acquisition"])]
# load_resource!(prediction_acq.resources["us_data"])
# us_data = prediction_acq.resources["us_data"].data
#
# # run reconstruction
# scores = @time recon_highspeed_online(mr_database, us_database, us_data, mr2us,
# properties,experiment_params)
#
# include("recon_highspeed.jl")
# im = render_images(squeeze(scores[500,:,:],1), mr_database,
# parse(Int64,experiment_params["K"]))
# fn = @sprintf("/tmp/usmri/frame%05i.png",500)
# Images.save(fn, Images.grayim(im[:,:,1]))
#
# Images.grayim(im[:,:,2])
#
# Pkg.update()
#
# # obtain temp dir and empty it first
# img_dest = tempdir()
# rm(img_dest,recursive=true)
#
# for t=1:size(scores,1)
#
#   #include("recon_highspeed.jl")
#   im = render_images(squeeze(scores[t,:,:],1), mr_database,
#   parse(Int64,experiment_params["K"]))
#
#   for p=1:1
#     Images.imwrite(Images.grayim(im[:,:,p])',
#     joinpath(img_dest,@sprintf("frame%05i.png",t)))
#   end
# end
#
# # render the movie
# render_movie(img_dest,properties)


# using DistributedArrays
# X = rand(100,100,200)
# A = view(X,:,:,1)
# B = rand(100,100)
# C = SharedArray(Float64,100,100,100000)
# #C = zeros(100,100,100000)
# buf = zeros(size(B))
#
# function testfun!(A::AbstractArray{Float64,2},B::AbstractArray{Float64,2},C::AbstractArray{Float64,3},buf::AbstractArray{Float64,2})
#   #@sync @parallel for i=1:size(C,2)
#   @sync @parallel for i=1:100000
#     #println(size(A))
#     #println(size(B))
#     #println(size(C))
#     A_mul_B!(buf,A,B)
#     C[:,:,i] = buf
#     #C = A*B
#   end
#   nothing
# end
# @time testfun!(A,B,C,buf)
#
#
# A = rand(100,1)
# B = rand(100,100)
# C = zeros(100)
# function mytest(A::Array{Float64,2},B::Array{Float64,2},C::Array{Float64,1})
#   tmp = zeros(size(A))
#   tmp2 = zeros(1,1)
#   for i=1:1000
#     for j=1:size(C,1)
#       #C[j] = (A'*B*A)[1]
#       A_mul_B!(tmp,B,A)
#       A_mul_B!(tmp2,A',tmp)
#     end
#   end
# end
# @time mytest(A,B,C)
