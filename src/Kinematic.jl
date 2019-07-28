# Kinematic julia code for the purposes of analyzing telemtric data pertaining to speed,
# acceleration and other measurements dealing of the kinematic nature.

using Dates, KernelDensity, Plots, Rmath, DataFrames, Query

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


function Base.show(io::IO, ke::KinematicEvent)
    println(io, "---------------------------")
    println(io, "KinematicEvent object");
    println(io, "---------------------------")
    println(io, "Velocity: ", ke.vel);
    println(io, "Acceleration: ", ke.aec);
    println(io, "Timestamp: ", ke.t);
    println(io, "SpeedType: ", ke.speedtype);
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

function Base.show(io::IO, kes::KinematicEvents)
    println(io, "---------------------------")
    println(io, "KinematicEvents object");
    println(io, "---------------------------")
    println(io, "No. Events: ", (kes.vels |> size)[1] );
    println(io, "SpeedType: ", kes.speedtype);
end






function plot(ev::KinematicEvents)
    vels::Array{Float64,1} = ev.vels;
    aecs::Array{Float64,1} = ev.aecs;
    scatter(vels,aecs);
end


function plot!(ev::KinematicEvents)
    vels::Array{Float64,1} = ev.vels;
    aecs::Array{Float64,1} = ev.aecs;
    scatter!(vels,aecs);
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
    events::KinematicEvents
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
            dat::DataFrame = DataFrame(vels = vels, aecs = aecs, tstamps = kes.tstamps);
            dat_filtered::DataFrame = @from i in dat begin
                            @where i.vels > vel_bounds[1] && i.vels < vel_bounds[2]
                            @where i.aecs > aec_bounds[1] && i.aecs < aec_bounds[2]
                            @select {i.vels , i.aecs, i.tstamps}
                            @collect DataFrame
                        end

            vels_filtered::Array{Float64,1} = convert(Array{Float64,1},dat_filtered.vels);
            aecs_filtered::Array{Float64,1} = convert(Array{Float64,1},dat_filtered.aecs);

            kernel::BivariateKDE = kde((vels_filtered,aecs_filtered)) # BivariateKDE

            events = KinematicEvents(vels_filtered,
                                    aecs_filtered,
                                    kes.speedtype,
                                    convert(Array{DateTime,1},dat_filtered.tstamps));

            km::KinematicMap = new(vel_bounds,aec_bounds,kernel,events);
            return (km);
        catch e
            println("ERROR: $e")
            error("KinematicMap construction failed, try using debugger and entering the function")
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
    heatmap(xy_grid[1],xy_grid[2],pdf(ik,xy_grid[1],xy_grid[2])',fill = true,color = :plasma)
end

"""
Overlays plot KinematicMap, only one input so far.

# example

    using Rmath

    x = rnorm(100) |> x - > abs.(x)
    y = rnorm(100)

    kes = KinematicEvents(x,y KMH())
    tele_map = KinematicMap(kes,[0.0,1.0],[-1.0,1.0])

    plot!(tele_map)
"""
function plot!(km::KinematicMap)
    x_h::Float64 = (km.vel_bounds[2] - km.vel_bounds[1])/100
    y_h::Float64 = (km.aec_bounds[2] - km.aec_bounds[1])/100
    xy_grid = (km.vel_bounds[1]:x_h:km.vel_bounds[2],
                km.aec_bounds[1]:y_h:km.aec_bounds[2])
    # Interpolate
    ik = InterpKDE(km.kernel);
    contour!(xy_grid[1],xy_grid[2],pdf(ik,xy_grid[1],xy_grid[2]))
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
    bikernel::BivariateKDE
    deviants::KinematicEvents
    p_kernel::UnivariateKDE
    p_is::Array{Float64,1}
    p_star::Float64
    function DeviationEvents(events::KinematicEvents,bikernel::BivariateKDE,α = 0.05)
        ev::KinematicEvents = events
        ik = InterpKDE(bikernel);
        p_is::Array{Float64,1} = map( (v,a) -> pdf(ik,v,a), ev.vels, ev.aecs);
        try
            p_kernel = kde(p_is,npoints = 2^13);
            # Fix for numerical issues
            p_kernel.density = p_kernel.density ./ (p_kernel.density |> sum)
            # offset range due to weird left bound
            offset_p = abs(p_kernel.x[1])

            if(p_kernel.x[1] < 0)
                p_kernel.x = p_kernel.x .+ offset_p;
            end

            # Get devient events by solving for the function
            function GetStar()
                for i in 1:size(p_kernel.density,1)
                    # Solve for this
                    if( (p_kernel.density[1:i] |> sum) > α )
                        p_zero_star = p_kernel.x[(i-1)]
                        return(p_zero_star);
                    end
                end
                return nothing
            end
            p_zero_star = GetStar()

            # get all p_is less than the zero_star
            # offset p_is
            p_is = p_is .+ offset_p
            checks_p = p_is .< p_zero_star;
            deviants = KinematicEvents(ev.vels[checks_p],ev.aecs[checks_p],ev.speedtype,ev.tstamps[checks_p])
            de = new(α,events,bikernel,deviants,p_kernel,p_is,p_zero_star)
            return(de)
        catch e
            print("ERROR: $e")
            error("\n deviational events constructuion failed, try debugging, most likely KDE")
        end
    end
end

"""
Plots deviation events, only one input so far.
"""
function plot(dev::DeviationEvents)
    vels::Array{Float64,1} = dev.deviants.vels;
    aecs::Array{Float64,1} = dev.deviants.aecs;
    scatter(vels,aecs, markersize = 2);
end

"""
Overlays plot deviation events, only one input so far.
"""
function plot!(dev::DeviationEvents)
    vels::Array{Float64,1} = dev.deviants.vels;
    aecs::Array{Float64,1} = dev.deviants.aecs;
    scatter!(vels,aecs,markersize = 2);
end


#=

abstract type TelemetricMap end;
abstract type TelemetricEvent end;
abstract type TelemetricEvents end;
abstract type SpeedType end;

ev = ke
ik = InterpKDE(te.kernel)
p_is = map( (v,a) -> pdf(ik,v,a), ev.vels, ev.aecs);
p_kernel = kde(p_is);
deviants = ev
=#
#=
using Rmath,Plots

a = rnorm(10000) |> x -> abs.(x)
b = rnorm(10000)
ke = KinematicEvents(a,b,KMH(),repeat([DateTime(2019,1)],size(a,1)))
te = KinematicMap(ke,[0.0,1],[-2.0,2.0])


de = DeviationEvents(te.events,te.kernel,0.15)

plot(te)
scatter!(de.d)
=#


#=
# Example with real data
using CSV

te = CSV.read("/Users/pocucan/Downloads/2011-08-25.csv")
te = CSV.read("/Users/nik/Downloads/2011-08-25.csv")
vels = te.speed_mph |> x -> convert(Array{Float64,1},x)
aecs = te.accel_meters_ps |> x -> convert(Array{Float64,1},x)

ke = KinematicEvents(vels,aecs,MPH(),repeat([DateTime(2019,1)],size(vels,1)))
#mp = KinematicMap(ke,[30.0,50.0],[-5.0,5.0])
mp = KinematicMap(ke,[40.0,90.0],[-2.0,2.0])

dev = DeviationEvents(mp.events,mp.kernel,0.05)

dev_1 = DeviationEvents(mp.events,mp.kernel,0.01)

=#
