export get_learning_acquisition
export get_prediction_acquisition
export get_dataset_properties
export get_dataset_parameters
export get_MR_images
export get_US_data
export get_mr2us
export get_output_dir

function get_learning_acquisition(datasets::Dict{AbstractString,Dataset},
  experiment::Dict{AbstractString,AbstractString})
  acq = datasets[experiment["dataset"]].acquisitions[
    experiment["learning_acquisition"]]
  load_all_resources!(acq)
  return acq
end

function get_prediction_acquisition(datasets::Dict{AbstractString,Dataset},
  experiment::Dict{AbstractString,AbstractString})
  acq = datasets[experiment["dataset"]].acquisitions[
    experiment["prediction_acquisition"]]
  load_all_resources!(acq)
  return acq
end

function get_dataset_properties(datasets::Dict{AbstractString,Dataset},
  experiment::Dict{AbstractString,AbstractString})
  properties = datasets[experiment["dataset"]].properties
  return properties
end

function get_dataset_parameters(datasets::Dict{AbstractString,Dataset},
  experiment::Dict{AbstractString,AbstractString})
  parameters = datasets[experiment["dataset"]].parameters
  return parameters
end

function get_MR_images(acq::Acquisition)
  I = acq.resources["mr_data"].data["I"]
  # normalize images to [0 1]
  for p=1:size(I,3)
    tmp = I[:,:,p,:]
    I[:,:,p,:] = tmp / maximum(tmp[:])
  end
  clamp!(I, 0, 1)
  return I
end

function get_US_data(acq::Acquisition)
  return acq.resources["us_data"].data
end

"Get indices that map k-space center acquisition time to OCM acquisition time"
function get_mr2us(acq::Acquisition)
  mr2us = Array{Int64,2}
  count=1
  for key in sort(collect(keys(acq.resources["mr2us"].data)))
    d = acq.resources["mr2us"].data[key]
    if count==1
      mr2us = Array{Int64,2}(
      length(collect(keys(acq.resources["mr2us"].data))), length(d))
    end
    mr2us[count,:] = d
    count += 1
  end
  return mr2us
end

function get_output_dir(datasets::Dict{AbstractString,Dataset},
  experiment::Dict{AbstractString,AbstractString})

  dataset_dir = datasets[experiment["dataset"]].directory
  acq_dir = datasets[experiment["dataset"]].acquisitions[
  parse(Int,experiment["prediction_acquisition"])].directory

  output_dir = joinpath(dataset_dir,acq_dir,"output")

  !isdir(output_dir) ? mkdir(output_dir) : nothing
  return output_dir

end
