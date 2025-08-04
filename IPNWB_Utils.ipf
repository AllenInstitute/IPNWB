#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma version=0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Utils.ipf
/// @brief Utility functions

#ifdef IPNWB_DEFINE_IM
#pragma IndependentModule=IPNWB
#endif

#ifdef IPNWB_INCLUDE_UTILS

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if var is a NaN, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsNaN(var)
	variable var

	return numType(var) == 2
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function isNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function isEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Return the seconds since Igor Pro epoch (1/1/1904) in UTC time zone
threadsafe Function DateTimeInUTC()
	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Returns one if var is an integer and zero otherwise
threadsafe Function IsInteger(var)
	variable var

	return IsFinite(var) && trunc(var) == var
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904)
///                              in UTC (or local time zone depending on `localTimeZone`)
/// @param numFracSecondsDigits  [optional, defaults to zero] Number of sub-second digits
/// @param localTimeZone         [optional, defaults to false] Use the local time zone instead of UTC
threadsafe Function/S GetISO8601TimeStamp([secondsSinceIgorEpoch, numFracSecondsDigits, localTimeZone])
	variable secondsSinceIgorEpoch, numFracSecondsDigits, localTimeZone

	string str
	variable timezone

	if(ParamIsDefault(localTimeZone))
		localTimeZone = 0
	else
		localTimeZone = !!localTimeZone
	endif

	if(ParamIsDefault(numFracSecondsDigits))
		numFracSecondsDigits = 0
	else
		ASSERT_TS(IsInteger(numFracSecondsDigits) && numFracSecondsDigits >= 0, "Invalid value for numFracSecondsDigits")
	endif

	if(ParamIsDefault(secondsSinceIgorEpoch))
		if(localTimeZone)
			secondsSinceIgorEpoch = DateTime
		else
			secondsSinceIgorEpoch = DateTimeInUTC()
		endif
	endif

	if(localTimeZone)
		timezone = Date2Secs(-1,-1,-1)
		sprintf str, "%sT%s%+03d:%02d", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits), trunc(timezone / 3600), abs(mod(timezone / 60, 60))
	else
		sprintf str, "%sT%sZ", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits)
	endif

	return str
End

/// @brief Parse a simple unit with prefix into its prefix and unit.
///
/// Note: The currently allowed units are the SI base units [1] and other
/// common derived units.  And in accordance to SI definitions, "kg" is a
/// *base* unit. "Simple" unit means means one unit with prefix, not e.g.
/// "km/s".
///
/// @param[in]  unitWithPrefix string to parse, examples are "ms" or "kHz"
/// @param[out] prefix         symbol of decimal multipler of the unit,
///                            see below or [1] chapter 3 for the full list
/// @param[out] numPrefix      numerical value of the decimal multiplier
/// @param[out] unit           unit
///
/// \rst
///
/// =====  ======  ===============
/// Name   Symbol  Numerical value
/// =====  ======  ===============
/// yotta    Y        1e24
/// zetta    Z        1e21
/// exa      E        1e18
/// peta     P        1e15
/// tera     T        1e12
/// giga     G        1e9
/// mega     M        1e6
/// kilo     k        1e3
/// hecto    h        1e2
/// deca     da       1e1
/// deci     d        1e-1
/// centi    c        1e-2
/// milli    m        1e-3
/// micro    mu       1e-6
/// nano     n        1e-9
/// pico     p        1e-12
/// femto    f        1e-15
/// atto     a        1e-18
/// zepto    z        1e-21
/// yocto    y        1e-24
/// =====  ======  ===============
///
/// \endrst
///
/// [1]: 8th edition of the SI Brochure (2014), http://www.bipm.org/en/publications/si-brochure
threadsafe Function ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	string unitWithPrefix
	string &prefix
	variable &numPrefix
	string &unit

	string expr

	ASSERT_TS(!isEmpty(unitWithPrefix), "ParseUnit: empty unit")

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	expr = "(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|a.u.)"

	SplitString/E=(expr) unitWithPrefix, prefix, unit
	ASSERT_TS(V_flag >= 1, "ParseUnit: Could not parse unit string")

	numPrefix = GetDecimalMultiplierValue(prefix)
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
threadsafe Function GetDecimalMultiplierValue(prefix)
	string prefix

	if(isEmpty(prefix))
		return 1
	endif

	Make/FREE/T prefixes = {"Y", "Z", "E", "P", "T", "G", "M", "k", "h", "da", "d", "c", "m", "mu", "n", "p", "f", "a", "z", "y"}
	Make/FREE/D values   = {1e24, 1e21, 1e18, 1e15, 1e12, 1e9, 1e6, 1e3, 1e2, 1e1, 1e-1, 1e-2, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15, 1e-18, 1e-21, 1e-24}

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT_TS(V_Value != -1, "GetDecimalMultiplierValue: Could not find prefix")
	ASSERT_TS(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "GetDecimalMultiplierValue: prefixes and values wave sizes must match")

	return values[V_Value]
End

/// @brief Return 1 if the wave is a text wave, zero otherwise
threadsafe Function IsTextWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 2
End

/// @brief Return 1 if the wave is a numeric wave, zero otherwise
threadsafe Function IsNumericWave(wv)
	WAVE wv

	return WaveType(wv, 1) == 1
End

/// @brief Remove a string prefix from each list item and
/// return the new list
threadsafe Function/S RemovePrefixFromListItem(prefix, list, [listSep])
	string prefix, list
	string listSep
	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	string result, entry
	variable numEntries, i, len

	result = ""
	len = strlen(prefix)
	numEntries = ItemsInList(list, listSep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, listSep)
		if(!cmpstr(entry[0,(len-1)], prefix))
			entry = entry[(len),inf]
		endif
		result = AddListItem(entry, result, listSep, inf)
	endfor

	return result
End

/// @brief Turn a persistent wave into a free wave
threadsafe Function/Wave MakeWaveFree(wv)
	WAVE wv

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr

	return wv
End

/// @brief Returns a wave name not used in the given datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the wave name, might be shorted due to Igor Pro limitations
threadsafe Function/S UniqueWaveName(dfr, baseName)
	dfref dfr
	string baseName

	variable index, numRuns
	string name
	string path

	ASSERT_TS(!isEmpty(baseName), "UniqueWaveName: baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "UniqueWaveName: dfr does not exist")

	// shorten basename so that we can attach some numbers
	numRuns = 10000
	baseName = CleanupName(baseName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - (ceil(log(numRuns)) + 1)], 0)
	path = GetDataFolder(1, dfr)
	name = baseName

	do
		if(!WaveExists($(path + name)))
			return name
		endif

		name = baseName + "_" + num2istr(index)

		index += 1
	while(index < numRuns)

	DEBUGPRINT("Could not find a unique folder with trials:", var = numRuns)

	return ""
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// Taken from http://www.igorexchange.com/node/2055
threadsafe Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	switch(DataFolderRefStatus(dfr))
		case 0: // invalid ref, does not exist
			return 0
		case 1: // might be valid
			dataFolder = GetDataFolder(1,dfr)
			return cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder)
		case 3: // free data folders always exist
			return 1
		default:
			ASSERT_TS(0, "DataFolderExistsDFR: unknown status")
			return 0
	endswitch
End

/// @brief Return the base name of the file
///
/// Given `path/file.suffix` this gives `file`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetBaseName(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(3, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the file extension (suffix)
///
/// Given `path/file.suffix` this gives `suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetFileSuffix(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(4, filePathWithSuffix, sep, 0, 0)
End

/// @brief Return the folder of the file
///
/// Given `/path/file.suffix` this gives `path/`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetFolder(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(1, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the filename with extension
///
/// Given `path/file.suffix` this gives `file.suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
threadsafe Function/S GetFile(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(0, filePathWithSuffix, sep, 1, 0)
End

/// @brief Parse a ISO8601 timestamp, e.g. created by GetISO8601TimeStamp(), and returns the number
/// of seconds, including fractional parts, since Igor Pro epoch (1/1/1904) in UTC time zone
///
/// Accepts also the following specialities:
/// - no UTC timezone specifier (UTC timezone is still used)
/// - ` `/`T` between date and time
/// - fractional seconds
/// - `,`/`.` as decimal separator
threadsafe Function ParseISO8601TimeStamp(timestamp)
	string timestamp

	string year, month, day, hour, minute, second, regexp, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute
	variable secondsSinceEpoch, timeOffset

	regexp = "^([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[T ]{1}([[:digit:]]+):([[:digit:]]+)(?::([[:digit:]]+)([.,][[:digit:]]+)?)?(?:Z|([\+-])([[:digit:]]+)(?::([[:digit:]]+))?)?$"
	SplitString/E=regexp timestamp, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute

	if(V_flag < 5)
		return NaN
	endif

	secondsSinceEpoch  = date2secs(str2num(year), str2num(month), str2num(day))
	secondsSinceEpoch += 60 * 60 * str2num(hour) + 60 * str2num(minute)
	if(!IsEmpty(second))
		secondsSinceEpoch += str2num(second)
	endif

	if(!IsEmpty(tzOffsetSign) && !IsEmpty(tzOffsetHour))
		timeOffset = str2num(tzOffsetHour) * 3600
		if(!IsEmpty(tzOffsetMinute))
			timeOffset -= str2num(tzOffsetMinute) * 60
		endif

		if(!cmpstr(tzOffsetSign, "+"))
			secondsSinceEpoch -= timeOffset
		elseif(!cmpstr(tzOffsetSign, "-"))
			secondsSinceEpoch += timeOffset
		else
			ASSERT_TS(0, "Invalid case")
		endif
	endif

	if(!IsEmpty(fracSeconds))
		secondsSinceEpoch += str2num(ReplaceString(",", fracSeconds, "."))
	endif

	return secondsSinceEpoch
End

/// @brief Convert a text wave to string list
threadsafe Function/S TextWaveToList(txtWave, sep)
	WAVE/T txtWave
	string sep

	string list = ""
	variable i, numRows

	ASSERT_TS(IsTextWave(txtWave), "Expected a text wave")
	ASSERT_TS(DimSize(txtWave, COLS) == 0, "Expected a 1D wave")

	numRows = DimSize(txtWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		list = AddListItem(txtWave[i], list, sep, Inf)
	endfor

	return list
End

/// @brief Recursively resolve shortcuts to files/directories
///
/// @return full path or an empty string if the file does not exist or the
/// 		shortcut points to a non existing file/folder
Function/S ResolveAlias(path, [pathName])
	string pathName, path

	if(ParamIsDefault(pathName))
		GetFileFolderInfo/Q/Z path
	else
		GetFileFolderInfo/P=$pathName/Q/Z path
	endif

	if(V_flag)
		return ""
	endif

	if(!V_IsAliasShortcut)
		return path
	endif

	if(ParamIsDefault(pathName))
		return ResolveAlias(S_aliasPath)
	else
		return ResolveAlias(S_aliasPath, pathName = pathName)
	endif
End

/// @brief Check wether the given path points to an existing file
///
/// Resolves shortcuts and symlinks recursively.
Function FileExists(filepath)
	string filepath

	filepath = ResolveAlias(filepath)
	GetFileFolderInfo/Q/Z filepath

	return !V_Flag && V_IsFile
End

/// @brief Check wether the given path points to an existing folder
Function FolderExists(folderpath)
	string folderpath

	folderpath = ResolveAlias(folderpath)
	GetFileFolderInfo/Q/Z folderpath

	return !V_Flag && V_isFolder
End

/// @brief Add a string prefix to each list item and
/// return the new list
threadsafe Function/S AddPrefixToEachListItem(prefix, list)
	string prefix, list

	string result = ""
	variable numEntries, i

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(prefix + StringFromList(i, list), result, ";", inf)
	endfor

	return result
End

/// @brief Initializes the random number generator with a new seed between (0,1]
/// The time base is assumed to be at least 0.1 microsecond precise, so a new seed
/// is available every 0.1 microsecond.
///
/// Usage example for the case that one needs n non reproducible random numbers.
/// Whenever the following code block is executed a new seed is set, resulting in a different series of numbers
///
/// \rst
/// .. code-block:: igorpro
///
///		Make/D/N=(n) newRandoms
///		NewRandomSeed() // Initialize random number series with a new seed
///		newRandoms[] = GetReproducibleRandom() // Get n randoms from the new series
///
/// \endrst
threadsafe Function NewRandomSeed()

	SetRandomSeed/BETR=1 ((stopmstimer(-2) * 10 ) & 0xffffffff) / 2^32

End

/// @brief Return a random value in the range (0,1] which can be used as a seed for `SetRandomSeed`
///
/// Return a reproducible random number depending on the RNG seed.
threadsafe Function GetReproducibleRandom()

	variable randomSeed

	do
		randomSeed = abs(enoise(1, NOISE_GEN_MERSENNE_TWISTER))
	while(randomSeed == 0)

	return randomSeed
End

/// @brief Helper structure for GenerateRFC4122UUID()
static Structure Uuid
	uint32  time_low
	uint16  time_mid
	uint16  time_hi_and_version
	uint16  clock_seq
	uint16  node0
	uint16  node1
	uint16  node2
EndStructure

/// @brief Generate a version 4 UUID according to https://tools.ietf.org/html/rfc4122
///
/// @verbatim
///
///     4.4.  Algorithms for Creating a UUID from Truly Random or
///           Pseudo-Random Numbers
///
///        The version 4 UUID is meant for generating UUIDs from truly-random or
///        pseudo-random numbers.
///
///        The algorithm is as follows:
///
///        o  Set the two most significant bits (bits 6 and 7) of the
///           clock_seq_hi_and_reserved to zero and one, respectively.
///
///        o  Set the four most significant bits (bits 12 through 15) of the
///           time_hi_and_version field to the 4-bit version number from
///           Section 4.1.3.
///
///        o  Set all the other bits to randomly (or pseudo-randomly) chosen
///           values.
///
///     See Section 4.5 for a discussion on random numbers.
///
///     [...]
///
///      In the absence of explicit application or presentation protocol
///      specification to the contrary, a UUID is encoded as a 128-bit object,
///      as follows:
///
///      The fields are encoded as 16 octets, with the sizes and order of the
///      fields defined above, and with each field encoded with the Most
///      Significant Byte first (known as network byte order).  Note that the
///      field names, particularly for multiplexed fields, follow historical
///      practice.
///
///      0                   1                   2                   3
///       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                          time_low                             |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |       time_mid                |         time_hi_and_version   |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |clk_seq_hi_res |  clk_seq_low  |         node (0-1)            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                         node (2-5)                            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///     [...]
///
///     4.1.3.  Version
///
///        The version number is in the most significant 4 bits of the time
///        stamp (bits 4 through 7 of the time_hi_and_version field).
///
///        The following table lists the currently-defined versions for this
///        UUID variant.
///
///        Msb0  Msb1  Msb2  Msb3   Version  Description
///
///         0     0     0     1        1     The time-based version
///                                          specified in this document.
///
///         0     0     1     0        2     DCE Security version, with
///                                          embedded POSIX UIDs.
///
///         0     0     1     1        3     The name-based version
///                                          specified in this document
///                                          that uses MD5 hashing.
///
///         0     1     0     0        4     The randomly or pseudo-
///                                          randomly generated version
///                                          specified in this document.
///
///         0     1     0     1        5     The name-based version
///                                          specified in this document
///                                          that uses SHA-1 hashing.
///
///        The version is more accurately a sub-type; again, we retain the term
///        for compatibility.
///
/// @endverbatim
///
/// See also https://www.rfc-editor.org/errata/eid3546 and https://www.rfc-editor.org/errata/eid1957
/// for some clarifications.
threadsafe Function/S GenerateRFC4122UUID()

	string str, randomness
	STRUCT Uuid uu

	randomness = Hash(num2strHighPrec(GetReproducibleRandom(), precision=15), 1)

	WAVE binary = HexToBinary(randomness)

	uu.time_low = binary[0] | (binary[1] << 8) | (binary[2] << 16) | (binary[3] << 24)
	uu.time_mid = binary[4] | (binary[5] << 8)
	uu.time_hi_and_version = binary[6] | (binary[7] << 8)
	uu.clock_seq = binary[8] | (binary[9] << 8)

	uu.node0 = binary[10] | (binary[11] << 8)
	uu.node1 = binary[12] | (binary[13] << 8)
	uu.node2 = binary[14] | (binary[15] << 8)

	// set the version
	uu.clock_seq = (uu.clock_seq & 0x3FFF) | 0x8000
	uu.time_hi_and_version = (uu.time_hi_and_version & 0x0FFF) | 0x4000

	sprintf str, "%8.8x-%4.4x-%4.4x-%4.4x-%4.4x%4.4x%4.4x", uu.time_low, uu.time_mid, uu.time_hi_and_version, uu.clock_seq, uu.node0, uu.node1, uu.node2

	return str
End

/// @brief Convert a hexadecimal character into a number
threadsafe Function HexToNumber(ch)
	string ch

	variable var

	ASSERT_TS(strlen(ch) <= 2, "Expected only up to two characters")

	sscanf ch, "%x", var
	ASSERT_TS(V_flag == 1, "Unexpected string")

	return var
End

/// @brief Convert a number into hexadecimal
threadsafe Function/S NumberToHex(var)
	variable var

	string str

	ASSERT_TS(IsInteger(var) && var >= 0 && var < 256 , "Invalid input")

	sprintf str, "%02x", var

	return str
End

/// @brief Convert a string in hex format to an unsigned binary wave
///
/// This function works on a byte level so it does not care about endianess.
threadsafe Function/WAVE HexToBinary(str)
	string str

	variable length

	length = strlen(str)
	ASSERT_TS(mod(length, 2) == 0, "Expected a string with a power of 2 length")

	Make/N=(length / 2)/FREE/B/U bin = HexToNumber(str[p * 2]) | (HexToNumber(str[p * 2 + 1]) << 4)

	return bin
End

/// @brief Converts a number to a string with specified precision (digits after decimal dot).
/// This function is an extension for the regular num2str that is limited to 5 digits.
/// Input numbers are rounded using the "round-half-to-even" rule to the given precision.
/// The default precision is 5.
/// If val is complex only the real part is converted to a string.
/// @param[in] val       number that should be converted to a string
/// @param[in] precision [optional, default 5] number of precision digits after the decimal dot using "round-half-to-even" rounding rule.
///                      Precision must be in the range 0 to 15.
/// @return string with textual number representation
threadsafe Function/S num2strHighPrec(val, [precision])
	variable val, precision

	string str

	precision = ParamIsDefault(precision) ? 5 : precision
	ASSERT_TS(precision >= 0 && precision <= 15, "Invalid precision, must be >= 0 and <= 15.")

	sprintf str, "%.*f", precision, val

	return str
End

/// @brief Helper function for try/catch with AbortOnRTE
///
/// Not clearing the RTE before calling `AbortOnRTE` will always trigger the RTE no
/// matter what you do in that line.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
///    try
///       ClearRTError()
///       myFunc(); AbortOnRTE
///    catch
///      err = GetRTError(1)
///    endtry
///
/// \endrst
threadsafe Function ClearRTError()

	variable err = GetRTError(1)
End

/// @brief Normalize the line endings in the given string to either classic Mac OS/Igor Pro EOLs (`\r`)
///        or Unix EOLs (`\n`)
threadsafe Function/S NormalizeToEOL(str, eol)
	string str, eol

	str = ReplaceString("\r\n", str, eol)

	if(!cmpstr(eol, "\r"))
		str = ReplaceString("\n", str, eol)
	elseif(!cmpstr(eol, "\n"))
		str = ReplaceString("\r", str, eol)
	else
		ASSERT_TS(0, "unsupported EOL character")
	endif

	return str
End

#if IgorVersion() >= 9.0

/// @brief Return a nicely formatted multiline stacktrace
threadsafe Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output
	variable i, numCallers

	if(ParamIsDefault(prefix))
		prefix = ""
	endif

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	if(numCallers < 3)
		// our caller was called directly
		return "Stacktrace not available"
	endif

	output = prefix + "Stacktrace:\r"

	for(i = 0; i < numCallers - 2; i += 1)
		entry = StringFromList(i, stacktrace)
		func  = StringFromList(0, entry, ",")
		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End

#else

/// @brief Return a nicely formatted multiline stacktrace
Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output, module
	variable i, numCallers

	if(ParamIsDefault(prefix))
		prefix = ""
	endif

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	if(numCallers < 3)
		// our caller was called directly
		return "Stacktrace not available"
	endif

	output = prefix + "Stacktrace:\r"

	for(i = 0; i < numCallers - 2; i += 1)
		entry = StringFromList(i, stacktrace)
		func  = StringFromList(0, entry, ",")
		module = StringByKey("MODULE", FunctionInfo(func))

		if(!IsEmpty(module))
			func = module + "#" + func
		endif

		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End

#endif

threadsafe Function/S GetExperimentName()
	return IgorInfo(1)
End

/// @brief Return the experiment file type
threadsafe Function/S GetExperimentFileType()

#if IgorVersion() >= 9.0
	return IgorInfo(11)
#else
	if(!cmpstr(GetExperimentName(), UNTITLED_EXPERIMENT))
		return ""
	else
		// hardcoded to pxp
		return "Packed"
	endif
#endif

End

/// @brief Return the Igor Pro version string
threadsafe Function/S GetIgorProVersion()
	return StringByKey("IGORFILEVERSION", IgorInfo(3))
End

/// @brief Return the path converted to a windows style path
threadsafe Function/S GetWindowsPath(path)
	string path

	return ParseFilepath(5, path, "\\", 0, 0)
End

threadsafe Function SetEpochsDimensionLabels(WAVE wv)
	SetDimLabel COLS, 0, StartTime, wv
	SetDimLabel COLS, 1, EndTime, wv
	SetDimLabel COLS, 2, Tags, wv
	SetDimLabel COLS, 3, TreeLevel, wv
End

/// @brief Returns an unsorted free wave with all unique entries from wv neglecting NaN/Inf.
///
/// uses built-in igor function FindDuplicates. Entries are deleted from left to right.
Function/Wave GetUniqueEntries(wv, [caseSensitive])
	Wave wv
	variable caseSensitive

	variable numRows, i

	if(IsTextWave(wv))
		if(ParamIsDefault(caseSensitive))
			caseSensitive = 1
		else
			caseSensitive = !!caseSensitive
		endif

		return GetUniqueTextEntries(wv, caseSensitive=caseSensitive)
	endif

	numRows = DimSize(wv, ROWS)
	ASSERT_TS(numRows == numpnts(wv), "Wave must be 1D")

	Duplicate/FREE wv, result

	if(numRows <= 1)
		return result
	endif

	FindDuplicates/RN=result wv

	/// @todo this should be removed as it does not belong into this function
	WaveTransform/O zapNaNs wv
	WaveTransform/O zapINFs wv

	return result
End

/// @brief Convenience wrapper around GetUniqueTextEntries() for string lists
Function/S GetUniqueTextEntriesFromList(list, [sep, caseSensitive])
	string list, sep
	variable caseSensitive

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT_TS(strlen(sep) == 1, "Separator should be one byte long")
	endif

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	WAVE/T wv = ListToTextWave(list, sep)
	WAVE/T unique = GetUniqueTextEntries(wv, caseSensitive=caseSensitive)

	return TextWaveToList(unique, sep)
End

/// @brief Search and Remove Duplicates from Text Wave wv
///
/// Duplicates are removed from left to right
///
/// @param wv             text wave reference
/// @param caseSensitive  [optional] Indicates whether comparison should be case sensitive. defaults to True
///
/// @return free wave with unique entries
static Function/Wave GetUniqueTextEntries(wv, [caseSensitive])
	Wave/T wv
	variable caseSensitive

	variable numEntries, numDuplicates, i

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	numEntries = DimSize(wv, ROWS)
	ASSERT_TS(numEntries == numpnts(wv), "Wave must be 1D.")

	Duplicate/T/FREE wv result
	if(numEntries <= 1)
		return result
	endif

	if(caseSensitive)
		FindDuplicates/RT=result wv
	else
		Make/I/FREE index
		MAKE/T/FREE/N=(numEntries) duplicates = LowerStr(wv[p])
		FindDuplicates/INDX=index duplicates
		numDuplicates = DimSize(index, ROWS)
		for(i = numDuplicates - 1; i >= 0; i -= 1)
			DeletePoints index[i], 1, result
		endfor
	endif

	return result
End

/// @brief Updates the numeric value of `key` found in the wave note to `val`
///
/// @param wv     wave
/// @param key    key of the Key/Value pair
/// @param val    value of the Key/Value pair
/// @param format [optional] printf compatible format string to set
///               the conversion to string for `val`
///
/// The expected wave note format is: `key1:val1;key2:val2;`
threadsafe Function SetNumberInWaveNote(wv, key, val, [format])
	Wave wv
	string key
	variable val
	string format

	string str

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	if(!ParamIsDefault(format))
		ASSERT_TS(!IsEmpty(format), "Empty format")
		sprintf str, format, val
		Note/K wv, ReplaceStringByKey(key, note(wv), str)
	else
		Note/K wv, ReplaceNumberByKey(key, note(wv), val)
	endif
End

/// @brief Returns the numeric value of `key` found in the wave note,
/// returns NaN if it could not be found
///
/// The expected wave note format is: `key1:val1;key2:val2;`
threadsafe Function GetNumberFromWaveNote(wv, key)
	Wave wv
	string key

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(key), "Empty key")

	return NumberByKey(key, note(wv))
End

#endif // IPNWB_INCLUDE_UTILS
