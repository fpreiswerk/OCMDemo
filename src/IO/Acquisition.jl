type Acquisition
  id::AbstractString
  directory::AbstractString
  resources::Dict{AbstractString,Resource}

  function Acquisition(id::AbstractString,directory::AbstractString,resources::Dict{AbstractString,Resource})
    this = new()
    this.id = id
    this.directory = directory
    this.resources = resources
    return this
  end
end
