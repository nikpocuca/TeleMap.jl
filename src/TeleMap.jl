module TeleMap

	abstract type TelemetricMap end;
	abstract type TelemetricEvent end;
	abstract type TelemetricEvents end;
	abstract type SpeedType end;

	import Dates, KernelDensity, Rmath, DataFrames, Query, RecipesBase

	export TelemetricMap, TelemetricEvent, TelemetricEvents, SpeedType, KinematicEvent, KinematicEvents, KinematicMap, DeviationEvents, MPH, KMH

	include("Kinematic.jl")

end # module
