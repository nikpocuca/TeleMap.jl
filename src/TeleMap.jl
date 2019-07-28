module TeleMap

	abstract type TelemetricMap end;
	abstract type TelemetricEvent end;
	abstract type TelemetricEvents end;
	abstract type SpeedType end;

	import Plots:plot, Dates, KernelDensity, Plots, Rmath, Roots, DataFrames, Query

	export KinematicEvent, KinematicEvents, KinematicMap, DeviationEvents

	include("Kinematic.jl")

end # module
