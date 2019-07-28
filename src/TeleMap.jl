module TeleMap

	abstract type TelemetricMap end;
	abstract type TelemetricEvent end;
	abstract type TelemetricEvents end;
	abstract type SpeedType end;

	import Plots, Dates, KernelDensity, Plots, Rmath, DataFrames, Query

	export KinematicEvent, KinematicEvents, KinematicMap, DeviationEvents, plot

	include("Kinematic.jl")

end # module
