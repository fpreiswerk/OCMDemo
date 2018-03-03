# OCMDemo.jl
This is demo code for the paper

Preiswerk, Frank, et al. [*"Hybrid MRI‐Ultrasound acquisitions, and scannerless real‐time imaging."*](http://onlinelibrary.wiley.com/doi/10.1002/mrm.26467/full) Magnetic Resonance in Medicine (2016).

(Awarded with the [*"2017 Young Investigator Cum Laude Award by the ISMRM."*]
(https://ncigt.org/news/young-investigator-cum-laude-award-ismrm).)

## How to use
If you have already installed Julia version 0.5 or higher, you can skip the
first step.

## Install Julia
You can downoaad a version of Julia for your operating system from the
[Julia website](http://julialang.org/downloads), or use your system's package
manager. For example, on MacOS with [Homebrew](http://brew.sh) installed, you
can type

```shell
brew cask install julia
```

If installation succeeds, you will be able to start Julia
(i.e. the Read/Evaluate/Print/Loop, or REPL) by typing `julia` on your command
line.

## Install the package
In the REPL, install this package using Julia's built in package manager by typing

```julia
Pkg.clone("https://github.com/fpreiswerk/OCMDemo")
```

This will automatically install the package and all its dependencies. It might
take a while, especially if you have freshly installed Julia.

## Download the sample data
Hybrid OCM-MRI data of three subjects (A, B and H from the paper) were made
available. You can download the data by calling the `download_data.jl` script
from the REPL,

```julia
include(joinpath(Pkg.dir("OCMDemo"),"examples","download_data.jl"))
```

The data is ~400MB, so this might take a while.

## Playing around
When the sample data is downloaded, you can take a look at the example script
`run.jl`. It is located in the same folder as above, so typing

```julia
joinpath(Pkg.dir("OCMDemo"),"examples","run.jl")
```

in the REPL will reveal its location. Open it and play around, e.g. using

```julia
edit(joinpath(Pkg.dir("OCMDemo"),"examples","run.jl"))
```

All experiments are defined in XML files: Three experiment definitions are
available, `A1.xml`, `B2.xml` and `H2.xml`, respectively, corresponding to
acquisitions used in the paper. You can run any of them by changing the value
of the `experiment_file` variable.

Run the program using the following command,

```julia
include(joinpath(Pkg.dir("OCMDemo"),"examples","run.jl"))
```

or directly from the shell using

```shell
julia /path/to/run.jl
```

The script will produce an m-mode visualization, similar to Figure 5 in the
paper. The result will be saved as an image, and should automatically open
using your system's default image viewer.

## Optimization and parallel processing
The code is optimized for speed, essentially through in-place processing using
pre-allocated buffers and Julia's `broadcast` function, as well as `@fastmath`
and `@simd`. Using Julias's built in support for parallelism through `@parallel`
however caused more overhead, at least on the Julia versions I've tried. Still,
you can play around with it by inserting

```julia
OCMDemo.init_workers()
@everywhere using OCMDemo # load module on all workers
```

at the beginning of `run.jl` (after `using OCMDemo`). This will parallelize the
reconstruction of each plane (here 2).

## Cleaning up
To uninstall the package, as well as delete the downloaded sample data, simply
type

```julia
Pkg.rm("OCMDemo")
```

## Problems or questions
Please don't hesitate to contact me via [email](mailto:frank@bwh.harvard.edu) if
you are having problems using the code or if you have questions or comments.

## Credits
This work was performed with the following co-authors:

- Matthew Toews, École de technologie supérieure, Montreal
- Cheng-Chieh Cheng, Brigham and Women's Hospital, Harvard Medical School, Boston
- Jr-yuan George Chiou, righam and Women's Hospital, Harvard Medical School, Boston
- Chang-Sheng Mei, Soochow University, Taipei
- Lena F. Schaefer, Brigham and Women's Hospital, Harvard Medical School, Boston
- W. Scott Hoge, Brigham and Women's Hospital, Harvard Medical School, Boston
- Benjamin M. Schwartz, Google Inc., New York
- Lawrence P. Panych, Brigham and Women's Hospital, Harvard Medical School, Boston
- Bruno Madore, Brigham and Women's Hospital, Harvard Medical School, Boston
