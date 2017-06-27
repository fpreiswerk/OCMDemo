module OCMDemo

  using ProgressMeter
  using DSP
  using Hwloc
  using LightXML

  include("Util/Buffer.jl")
  include("Algorithm/build_lookup_usdata.jl")
  #include("Algorithm/compute_high_variation_inds.jl")
  include("Algorithm/compute_Sigma.jl")
  include("Algorithm/cough_detect.jl")
  include("Algorithm/kernel_regression.jl")
  include("Algorithm/Reconstruction.jl")
  include("Algorithm/render.jl")
  include("IO/Resource.jl")
  include("IO/Dataset.jl")
  include("IO/xml_functions.jl")
  include("Util/helpers.jl")
  include("Util/workers.jl")

  export
    load_datasets_xml,
    load_experiment_xml,
    recon_highspeed_inside,
    render_mmodes,
    render_corresponding_synthetic,
    init_workers,
    stop_workers

end # module
