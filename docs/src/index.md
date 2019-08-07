# TeleMap.jl 

A package for the creation and analysis of telemetric heat maps.

## Kinematic Maps 

Kinematic maps are probability heat maps of velocity and accleration. These maps are estimated using 
telemetry events via Bivariate Kernel Density Estimation. Each heat map contains a lower and upper bound for velocitiy (speed) and acceleration. 

```@docs
KinematicEvent(vel::Float64, aec::Float64, t::DateTime, speedtype::SpeedType)
```

```@docs
KinematicEvents(vels::Array{Float64,1},aecs::Array{Float64,1} ,speedtype::SpeedType,tstamps::Array{DateTime,1})
```

```@docs
KinematicMap(kes::KinematicEvents,vel_bounds::Array{Float64,1}, aec_bounds::Array{Float64,1})
```


