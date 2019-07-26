# Kinematic julia code for the purposes of analyzing telemtric data pertaining to speed,
# acceleration and other measurements dealing of the kinematic nature.

using Dates, KernelDensity, Plots


abstract type SpeedType end;

struct KMH <: SpeedType end;
struct MPH <: SpeedType end;


"""
Kinematic Event Structure

A basic structure for velocity, acceleration and timestamp.

Velocity must be positive!

"""
mutable struct KinematicEvent <: TelemetricEvent
    vel::Float64 # velocity
    aec::Float64 # acceleration
    t::DateTime # Time stamp
    speedtype::SpeedType # speed type
    function KinematicEvent(vel::Float64, aec::Float64, t::DateTime, speedtype::SpeedType)
        # Check to make sure velocity is positive
        if( vel < 0)
            error("Velocity must be positive")
        else
            ke = new(vel,aec,t, speedtype);
            return(ke);
        end
    end
end


"""
Convert!(from::KMH,to::MPH,ke::KinematicEvent)

example:

    a = KinematicEvent(0.0,1.0,DateTime(2019,07,4),KMH())

    Convert!(MPH(),KMH(),a) # throws error
    Convert!(KMH(),MPH(),a) # throws error

"""
# Conversion function from KMH to MPH
function Convert!(from::KMH,to::MPH,ke::KinematicEvent)
    if( ke.speedtype == MPH())
        error("Speed type is already in MPH")
    end
    ke.vel = ke.vel*0.6213711922;
    ke.aec = ke.aec*0.6213711922;
    ke.speedtype = MPH();
end

"""
Convert!(from::MPH,to::KMH,ke::KinematicEvent)

example:

    a = KinematicEvent(0.0,1.0,DateTime(2019,07,4),KMH())

    Convert!(MPH(),KMH(),a) # throws error
    Convert!(KMH(),MPH(),a) # throws error

"""
# Conversion function from MPH to KMH
function Convert!(from::MPH,to::KMH,ke::KinematicEvent)
    if( ke.speedtype == KMH())
        error("Speed type is already in KMH")
    end
    ke.vel = ke.vel*1.6093440000966945;
    ke.aec = ke.aec*1.6093440000966945;
    ke.speedtype = KMH();
end


"""
Kinematic Events Structure

A basic structure for velocity, acceleration and timestamp.

Velocity must be positive!

extension of the single Kinematic Event to incorproate multiple kinematic events

"""
mutable struct KinematicEvents<:TelemetricEvents
    vels::Array{Float64,1}
    aecs::Array{Float64,1}
    speedtype::SpeedType
    tstamps::Array{DateTime,1}
    function KinematicEvents(vels::Array{Float64,1},aecs::Array{Float64,1} ,speedtype::SpeedType,tstamps::Array{DateTime,1})
        if(size(vels,1) != size(aecs,1))
            error("Vels and Aecs must be the same size ")
        end
        # Check velocities
        for vel in vels
            if vel < 0.0
                error("vels cannot be negative, one of the velocities is negative")
            end
        end

        # return KinematicEvents
        kes = new(vels,aecs,speedtype,tstamps);
        return (kes);
    end
end



"""
Kinematic Map Structure

A basic structure for velocity and acceleration heat map

vel bounds , lower and upper bound for velocity

aec bounds , lower and upper bound acceleration

kernel , BivariateKDE

"""
mutable struct KinematicMap <: TelemetricMap
    vel_bounds::Array{Float64,1}
    aec_bounds::Array{Float64,1}
    kernel::BivariateKDE
    function KinematicMap(kes::KinematicEvents,vel_bounds::Array{Float64,1}, aec_bounds::Array{Float64,1})
        # Check errors
        if(size(vel_bounds,1) != 2)
            error("vel bounds must have exactly two bounds")
        elseif(size(aec_bounds,1) != 2)
            error("aec bounds must have exactly two bounds")
        end
        # Start of try catch statement, many possible errors
        try
            vels::Array{Float64,1} = kes.vels;
            aecs::Array{Float64,1} = kes.aecs;

            checks = (vels .> vel_bounds[1]) .& (vels .< vel_bounds[2]) .& (aecs .> aec_bounds[1]) .& (aecs .< aec_bounds[2])
            vels_filtered::Array{Float64,1} = vels[checks];
            aecs_filtered::Array{Float64,1} = aecs[checks];

            kernel::BivariateKDE = kde((vels_filtered,aecs_filtered)) # BivariateKDE
            km::KinematicMap = new(vel_bounds,aec_bounds,kernel);
            return (km);
        catch
            error("Kernel KernelDensity estimation failed, try using debugger and entering the function")
        end # End of try catch statement
    end # End of Constructor
end # End of mutable struct


# Import plotting function
import Plots:plot
"""
plots the KinematicMap

# example

    using Rmath

    x = rnorm(100) |> x - > abs.(x)
    y = rnorm(100)

    kes = KinematicEvents(x,y KMH())
    tele_map = KinematicMap(kes,[0.0,1.0],[-1.0,1.0])

    plot(tele_map)
"""
function plot(km::KinematicMap)
    x_h::Float64 = (km.vel_bounds[2] - km.vel_bounds[1])/100
    y_h::Float64 = (km.aec_bounds[2] - km.aec_bounds[1])/100
    xy_grid = (km.vel_bounds[1]:x_h:km.vel_bounds[2],
                km.aec_bounds[1]:y_h:km.aec_bounds[2])
    # Interpolate
    ik = InterpKDE(km.kernel);
    contour(xy_grid[1],xy_grid[2],pdf(ik,xy_grid[1],xy_grid[2]))
end



"""
DeviationEvents structure

Identify the deviational telemtric events at a power level α

contains:
events, original events
map, KinematicMap
deviants, deviant KinematicEvents
p_kernel, UnivariateKDE used to calculate

"""
mutable struct DeviationEvents <: TelemetricEvents
    α::Float64 # power level alpha, default is usually 0.05
    events::KinematicEvents
    map::KinematicMap
    deviants::KinematicEvents
    p_kernel::UnivariateKDE
    function DeviationEvents(events,map,α = 0.05)
        p_is::Array{Float64,1} = map( (v,a) -> pdf(map.kernel,v,a), events.vels,events.aecs)

    end
end



#=
using Rmath,Plots

a = rnorm(1000) |> x -> abs.(x)
b = rnorm(1000)
ke = KinematicEvents(a,b,KMH())
te = KinematicMap(ke,[0.0,0.5],[-1.0,1.0])
=#
