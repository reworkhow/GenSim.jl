# XSim

[![Build Status](https://travis-ci.org/reworkhow/GenSim.jl.svg?branch=master)](https://travis-ci.org/reworkhow/GenSim.jl)

XSim is a fast and user-friendly tool to simulate sequence data and complicated pedigree structures

####Features

* An efficient CPOS algorithm
* Using founders that are characterized by real genome sequence data
* Complicated pedigree structures among descendants

####Quick-start

```Julia
using XSim

#set genome information
chrLength, numChr, numLoci, mutRate = 1.0, 1, 100, 0.0
locusInt  = chrLength/numLoci
mapPos    = [0:locusInt:(chrLength-0.0001)]
geneFreq  = fill(0.5,numLoci)

XSim.init(numChr,numLoci,chrLength,geneFreq,mapPos,mutRate)
xsim = XSim.startPop()

#generate populations
ngen,popSize    = 10,10
xsim.popSample(ngen,popSize)

xsim1 = XSim.popNew(10)
xsim2 = XSim.popcross(5,xsim1,xsim2)

#generate genotypes
M=xsim2.getGenotypes()
```

####Authors and Contributors

* Hao Cheng, Rohan Fernando and Dorian Garrick



