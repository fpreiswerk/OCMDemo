import HDF5

type Resource
  id::AbstractString
  filename::AbstractString
  data::Any

  function Resource(id::AbstractString,filename::AbstractString)
    this = new()
    this.id = id
    this.filename = filename
    return this
  end
end

# to avoid mutually-circular type definition, we include this file here
include("./Acquisition.jl")

function load_resource!(r::Resource)
  fid = HDF5.h5open(r.filename, "r")
  obj = fid["$(r.id)"]

  if(typeof(obj) == HDF5.HDF5Dataset)
    r.data = HDF5.read(obj)
  else
    data = Dict{AbstractString,Any}()
    for ds in obj
      data[splitdir(HDF5.name(ds))[2]] = HDF5.read(ds)
    end
    r.data = data
  end
  close(fid)
end

function load_all_resources!(acq::Acquisition)
  for res in acq.resources
    load_resource!(res[2])
  end
end
