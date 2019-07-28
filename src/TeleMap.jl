module TeleMap

	abstract type TelemetricMap end;
	abstract type TelemetricEvent end;
	abstract type TelemetricEvents end;
	abstract type SpeedType end;

	import Dates, KernelDensity, Rmath, DataFrames, Query, RecipesBase

	export KinematicEvent, KinematicEvents, KinematicMap, DeviationEvents

	include("Kinematic.jl")

end # module
