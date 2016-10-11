type Dataset

  id::AbstractString
  directory::AbstractString
  acquisitions::Dict{AbstractString,Acquisition}
  properties::Dict{AbstractString,Any}
  parameters::Dict{AbstractString,Any}

  function Dataset(id::AbstractString, directory::AbstractString,
    acquisitions::Dict{AbstractString,Acquisition},properties::Dict,parameters::Dict)
    this = new()
    this.id = id
    this.directory = directory
    this.acquisitions = acquisitions
    this.properties = properties
    this.parameters = parameters
    return this
  end

end
