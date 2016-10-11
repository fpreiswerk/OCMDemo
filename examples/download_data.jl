cdir = pwd()
tmpdir = joinpath(Pkg.dir("OCMDemo"),"tmp")
if cdir == tmpdir
  cdir = joinpath(Pkg.dir("OCMDemo"))
end
isdir(tmpdir) || mkdir(tmpdir)
cd(tmpdir)
println("Downloading sample data... ")
try
  download("https://www.dropbox.com/s/slkmlm3r3ummooa/OCMExampleData.tar.gz?dl=1",
    "./data.tar.gz")
  println("\nUnpacking data... ")
  run(`tar -zxvf ./data.tar.gz`)
catch
  error("download or file extraction failed.")
end
mv(joinpath("./OCMExampleData","datasets"),"../datasets",remove_destination=true)
mv(joinpath("./OCMExampleData","experiments"),"../experiments",remove_destination=true)
cd("../")
rm("tmp",recursive=true)
cd(cdir)
println("done.\n")
