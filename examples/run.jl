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

# you can render the synthetic MR images corresponding to the acquired MR images
# using this function
synthetic_imgs_original_speed = render_corresponding_synthetic(result, mr_database, mr2us, experiment)

# save the mmode as images
save("mmode_sagital.png",colorim(mmode[:,:,:,1]))
save("mmode_coronal.png",colorim(mmode[:,:,:,2]))

# open in system default image viewer
if isdir("/Users")
  # likely MacOS
  run(`open mmode_sagital.png`)
elseif isdir("/home")
  # likely Linux
  run(`display mmode_sagital.png`)
else
  # likely Windows
  run(`mmode_coronal.png`)
end
