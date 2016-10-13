function load_datasets_xml(filename::AbstractString)

  datasets = Dict{AbstractString,Dataset}()
  (basedir,fn) = splitdir(filename)
  xdoc = parse_file(filename)
  xroot = LightXML.root(xdoc)
  ces = get_elements_by_tagname(xroot, "dataset")
  for e=ces
    d = load_dataset_config_xml(
      joinpath(basedir,attribute(e,"dir")))
    datasets[d.id] = d
  end
  return datasets
end

function load_dataset_config_xml(datapath::AbstractString)
  config_xdoc = parse_file("$(datapath)/config.xml")
  xroot = root(config_xdoc)
  dsname = attribute(xroot,"name")
  out = Dict()

  # read the properties
  properties = Dict()
  ces = get_elements_by_tagname(xroot, "properties")
  for c=child_nodes(ces[1])
    if is_elementnode(c)
      c = XMLElement(c)
      attributes = delete!(attributes_dict(c),"name")
      if length(attributes)>1
        properties[attribute(c,"name")] = attributes
      else
        properties[attribute(c,"name")] = attribute(c,"value")
      end
    end
  end

  # read the parameters
  parameters = Dict()
  ces = get_elements_by_tagname(xroot, "parameters")
  for c=child_nodes(ces[1])
    if is_elementnode(c)
      c = XMLElement(c)
      attributes = delete!(attributes_dict(c),"name")
      if length(attributes)>1
        parameters[attribute(c,"name")] = attributes
      else
        parameters[attribute(c,"name")] = attribute(c,"value")
      end
    end
  end

  # read all acquisitions
  acquisitions = Dict{AbstractString,Acquisition}()
  xacqs = get_elements_by_tagname(xroot,"acquisition")
  for a=xacqs
    resources = Dict{AbstractString,Resource}()
    xresources = get_elements_by_tagname(a,"resource")
    for r=xresources
      fn = joinpath(datapath,attribute(a,"dir"),attribute(r,"filename"))
      resources[attribute(r,"name")] = Resource(attribute(r,"name"),fn)
    end
    acquisitions[attribute(a,"id")] = Acquisition(attribute(a,"id"),attribute(a,"dir"),resources)
  end
  # put everything together and return
  dataset = Dataset(dsname,datapath,acquisitions,properties,parameters)
  return dataset
end

function load_experiment_xml(filename::AbstractString)
  parameters = Dict{AbstractString,AbstractString}()
  !isfile(filename) ? error("File $(filename) does not exist") : nothing
  xdoc = parse_file(filename)
  xroot = LightXML.root(xdoc)
  ces = get_elements_by_tagname(xroot, "parameter")
  for e=ces
    parameters[attribute(e,"name")] = attribute(e,"value")
  end
  return parameters
end
