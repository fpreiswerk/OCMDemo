"adds a reasonable number of workers"
function init_workers()

  stop_workers()
  # add a reasonable number of workers
  topology = Hwloc.topology_load()
  counts = Hwloc.histmap(topology)
  addprocs(counts[:Core]-1)

end

"stops any existing workers"
function stop_workers()

  length(workers())>1 ? rmprocs(workers) : nothing

end
