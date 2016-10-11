cdir = pwd()
println("foo")
exit()
tmpdir = joinpath(Pkg.dir("OCMDemo"),"tmp")
mkdir(tmpdir)
cd(tmpdir)
println("Downloading sample data... ")
try
  download("https://github.com/fpreiswerk/OCMExampleData/archive/master.zip",
    "./data.zip")
  println("\nUnpacking data... ")
  run(`unzip -oq ./data.zip -d ./`)
catch
  error("unzip or download failed.")
end
mv(joinpath("./OCMExampleData","datasets"),"../")
mv(joinpath("./OCMExampleData","experiments"),"../")
cd("Pkg.dir("OCMDemo")")
rm("tmp",recursive=true)
cd(cdir)
println("done.\n")
