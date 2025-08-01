#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma version          = 0.18

#ifdef IPNWB_DEFINE_IM
#pragma IndependentModule = IPNWB
#endif // IPNWB_DEFINE_IM

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Debugging.ipf
///
/// @brief Holds functions for debugging

#ifdef IPNWB_INCLUDE_UTILS

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
///@code
///	ASSERT_TS(DataFolderExistsDFR(dfr), "MyFunc: dfr does not exist")
///	do something with dfr
///@endcode
///
/// Unlike ASSERT() this function does not print a stacktrace or jumps into the debugger. The reasons are Igor Pro limitations.
/// Therefore it is advised to prefix `errorMsg` with the current function name.
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function ASSERT_TS(variable var, string errorMsg)

	string stacktrace

	try
		AbortOnValue var == 0, 1
	catch
#if IgorVersion() >= 9.0
		// Recursion detection, if ASSERT_TS appears multiple times in StackTrace
		if(ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(1))) > 1)

			print "Double threadsafe assertion Fail encountered !"

			AbortOnValue 1, 1
		endif
#endif

		print "!!! Threadsafe assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

#ifndef AUTOMATED_TESTING

		print "Please provide the following information if you contact the MIES developers:"
		print "################################"
		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#endif // !AUTOMATED_TESTING

#if !defined(AUTOMATED_TESTING) || defined(AUTOMATED_TESTING_DEBUGGING)

#if IgorVersion() >= 9.0
		stacktrace = GetStackTrace()
#else
		stacktrace = "stacktrace not available"
#endif
		print stacktrace

#endif // !AUTOMATED_TESTING || AUTOMATED_TESTING_DEBUGGING

#ifndef AUTOMATED_TESTING

		print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
		printf "Time: %s\r", GetIso8601TimeStamp(localTimeZone = 1)
		printf "Experiment: %s (%s)\r", GetExperimentName(), GetExperimentFileType()
		printf "Igor Pro version: %s (%s)\r", GetIgorProVersion(), StringByKey("BUILD", IgorInfo(0))
		print "################################"

		printf "Assertion FAILED with message %s\r", errorMsg

#endif // !AUTOMATED_TESTING

		AbortOnValue 1, 1
	endtry
End

/// @brief Abort execution with the given message
threadsafe Function FATAL_ERROR(string errorMsg)

	FATAL_ERROR(errorMsg)
End

#if defined(DEBUGGING_ENABLED)

static StrConstant functionReturnMessage = "return value"

/// @brief Output debug information and return the parameter var.
///
/// Debug function especially designed for usage in return statements.
///
/// For example calling the following function
/// @code
/// Function doStuff()
///  variable var = 1 + 2
///  return DEBUGPRINTv(var)
/// End
/// @endcode
/// will output
/// @verbatim DEBUG doStuff(...)#L5: return value 3 @endverbatim
/// to the history.
///
/// @hidecallgraph
/// @hidecallergraph
///
///@param var     numerical argument for debug output
///@param format  optional format string to override the default of "%g"
threadsafe Function DEBUGPRINTv(variable var, [string format])

	if(ParamIsDefault(format))
		DEBUGPRINT(functionReturnMessage, var = var)
	else
		DEBUGPRINT(functionReturnMessage, var = var, format = format)
	endif

	return var
End

/// @brief Output debug information and return the parameter str
///
/// Debug function especially designed for usage in return statements.
///
/// For example calling the following function
/// @code
/// Function/s doStuff()
///  variable str= "a" + "b"
///  return DEBUGPRINTs(str)
/// End
/// @endcode
/// will output
/// @verbatim DEBUG doStuff(...)#L5: return value ab @endverbatim
/// to the history.
///
/// @hidecallgraph
/// @hidecallergraph
///
///@param str     string argument for debug output
///@param format  optional format string to override the default of "%s"
threadsafe Function/S DEBUGPRINTs(string str, [string format])

	if(ParamIsDefault(format))
		DEBUGPRINT(functionReturnMessage, str = str)
	else
		DEBUGPRINT(functionReturnMessage, str = str, format = format)
	endif

	return str
End

///@brief Generic debug output function
///
/// Outputs variables and strings with optional format argument.
///
///Examples:
/// @code
/// DEBUGPRINT("before a possible crash")
/// DEBUGPRINT("some variable", var=myVariable)
/// DEBUGPRINT("my string", str=myString)
/// DEBUGPRINT("Current state", var=state, format="%.5f")
/// @endcode
///
/// @hidecallgraph
/// @hidecallergraph
///
/// @param msg    descriptive string for the debug message
/// @param var    variable
/// @param str    string
/// @param format format string overrides the default of "%g" for variables and "%s" for strings
threadsafe Function DEBUGPRINT(string msg, [variable var, string str, string format])

	string formatted = ""
	variable numSuppliedOptParams

	// check parameters
	// valid combinations:
	// - var
	// - str
	// - var and format
	// - str and format
	// - neither var, str, format
	numSuppliedOptParams = !ParamIsDefault(var) + !ParamIsDefault(str) + !ParamIsDefault(format)

	if(numSuppliedOptParams == 0)
		// nothing to check
	elseif(numSuppliedOptParams == 1)
		ASSERT_TS(ParamIsDefault(format), "Only supplying the \"format\" parameter is not allowed")
	elseif(numSuppliedOptParams == 2)
		ASSERT_TS(!ParamIsDefault(format), "You can't supply \"var\" and \"str\" at the same time")
	else
		FATAL_ERROR("Invalid parameter combination")
	endif

	if(!ParamIsDefault(var))
		if(ParamIsDefault(format))
			format = "%g"
		endif
		sprintf formatted, format, var
	elseif(!ParamIsDefault(str))
		if(ParamIsDefault(format))
			format = "%s"
		endif
		sprintf formatted, format, str
	endif

	printf "DEBUG: %s %s\r", msg, formatted
End

/// @brief Start a timer for performance measurements
///
/// Usage:
/// @code
/// variable referenceTime = DEBUG_TIMER_START()
/// // part one to benchmark
/// DEBUGPRINT_ELAPSED(referenceTime)
/// // part two to benchmark
/// DEBUGPRINT_ELAPSED(referenceTime)
/// @endcode
threadsafe Function DEBUG_TIMER_START()

	return stopmstimer(-2)
End

/// @brief Print the elapsed time for performance measurements
/// @see DEBUG_TIMER_START()
threadsafe Function DEBUGPRINT_ELAPSED(variable referenceTime)

	DEBUGPRINT("timestamp: ", var = (stopmstimer(-2) - referenceTime) / 1e6)
End

#else

threadsafe Function DEBUGPRINTv(variable var, [string format])

	// do nothing

	return var
End

threadsafe Function/S DEBUGPRINTs(string str, [string format])

	// do nothing

	return str
End

threadsafe Function DEBUGPRINT(string msg, [variable var, string str, string format])

	// do nothing
End

threadsafe Function DEBUG_TIMER_START()

End

threadsafe Function DEBUGPRINT_ELAPSED(variable referenceTime)

End

#endif

///@brief Enable debug mode
Function EnableDebugMode()

	Execute/P/Q "SetIgorOption poundDefine=DEBUGGING_ENABLED"
	Execute/P/Q "COMPILEPROCEDURES "
End

///@brief Disable debug mode
Function DisableDebugMode()

	Execute/P/Q "SetIgorOption poundUnDefine=DEBUGGING_ENABLED"
	Execute/P/Q "COMPILEPROCEDURES "
End

// injected via script functionprofiling.sh
Function DEBUG_STOREFUNCTION()

	string funcName  = GetRTStackInfo(2)
	string callchain = GetRTStackInfo(0)
	string caller    = StringFromList(0, callchain)

	WAVE/Z wv = root:IPNWB_functionids
	if(!WaveExists(wv))
		WAVE/T functionids = ListToTextWave(FunctionList("*", ";", "KIND:18,WIN:[IPNWB]"), ";")
		Duplicate functionids, root:IPNWB_functionids/WAVE=wv
	endif
	WAVE/Z count = root:IPNWB_functioncount
	if(!WaveExists(count))
		Make/U/L/N=(DimSize(wv, 0)) root:IPNWB_functioncount = 0
		WAVE count = root:functioncount
	endif
	FindValue/TEXT=(funcName) wv
	if(V_Value != -1)
		count[V_Value] += 1
	endif
End

#endif // IPNWB_INCLUDE_UTILS
