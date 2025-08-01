#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma version          = 0.18

#ifdef IPNWB_DEFINE_IM
#pragma IndependentModule = IPNWB
#endif // IPNWB_DEFINE_IM

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @brief Helper structure for WriteSingleChannel()
Structure WriteChannelParams
	string device ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string stimSet ///< name of the template simulus set
	string channelSuffix ///< custom channel suffix, in case the channel number is ambiguous
	string channelSuffixDesc ///< description of the channel suffix, will be added to the `source` attribute
	variable samplingRate ///< sampling rate in Hz
	variable startingTime ///< timestamp since Igor Pro epoch in UTC of the start of this measurement
	variable sweep ///< running number for each measurement
	variable channelType ///< channel type, one of @ref IPNWBChannelTypes
	variable channelNumber ///< running number of the channel
	variable electrodeNumber ///< electrode identifier the channel was acquired with
	string electrodeName ///< electrode identifier the channel was acquired with (string version)
	variable clampMode ///< clamp mode, one of @ref IPNWB_ClampModes
	variable groupIndex ///< Should be filled with the result of GetNextFreeGroupIndex(locationID, path) before
	///  the first call and must stay constant for all channels for this measurement.
	///  If `NaN` an automatic solution is provided.
	WAVE data ///< channel data
	WAVE/T epochs ///< epoch information (optional)
	///  Expected format:
	///  size nx4
	///   Columns:
	///   - Start time [s] in stimset coordinates
	///   - End time [s] in stimset coordinates
	///   - key value pair lists using "=" and ";" separators
	///   - Tree level (convertible to double)
EndStructure

/// @brief Initialize WriteChannelParams structure
threadsafe Function InitWriteChannelParams(STRUCT WriteChannelParams &p)

	p.groupIndex = NaN

	WAVE/Z/T p.epochs = $""
End

/// @brief Loader structure analog to WriteChannelParams
Structure ReadChannelParams
	string device ///< name of the measure device, e.g. "ITC18USB_Dev_0"
	string channelSuffix ///< custom channel suffix, in case the channel number is ambiguous
	variable sweep ///< running number for each measurement
	variable channelType ///< channel type, one of @ref IPNWBChannelTypes
	variable channelNumber ///< running number of the hardware channel
	variable electrodeNumber ///< electrode identifier the channel was acquired with
	variable groupIndex ///< constant for all channels in this measurement.
	variable ttlBit ///< additional information to make the channel number unambigous, in the range 2^0, ..., 2^3
	variable samplingRate ///< sampling rate in Hz
EndStructure

/// @brief Initialization routine for InitReadChannelParams
threadsafe Function InitReadChannelParams(STRUCT ReadChannelParams &p)

	p.device          = ""
	p.channelSuffix   = ""
	p.sweep           = NaN
	p.channelType     = NaN
	p.channelNumber   = NaN
	p.electrodeNumber = NaN
	p.groupIndex      = NaN
	p.ttlBit          = NaN
	p.samplingRate    = NaN
End

/// @brief Structure to hold all properties of the NWB file directly below `/general`
Structure GeneralInfo
	string session_id
	string experimenter
	string institution
	string lab
	string related_publications
	string notes
	string experiment_description
	string data_collection
	string stimulus
	string pharmacology
	string surgery
	string protocol
	string virus
	string slices
EndStructure

/// @brief Initialization routine for GeneralInfo
threadsafe Function InitGeneralInfo(STRUCT GeneralInfo &gi)

	gi.session_id             = PLACEHOLDER
	gi.experimenter           = PLACEHOLDER
	gi.institution            = PLACEHOLDER
	gi.lab                    = PLACEHOLDER
	gi.related_publications   = PLACEHOLDER
	gi.notes                  = PLACEHOLDER
	gi.experiment_description = PLACEHOLDER
	gi.data_collection        = PLACEHOLDER
	gi.stimulus               = PLACEHOLDER
	gi.pharmacology           = PLACEHOLDER
	gi.surgery                = PLACEHOLDER
	gi.protocol               = PLACEHOLDER
	gi.virus                  = PLACEHOLDER
	gi.slices                 = PLACEHOLDER
End

/// @brief Structure to hold all properties of the NWB file directly below `/general/subject`
Structure SubjectInfo
	string age
	string date_of_birth // isodatetime
	string description
	string genotype
	string sex
	string species
	string subject_id
	string weight
EndStructure

/// @brief Initialization routine for SubjectInfo
threadsafe Function InitSubjectInfo(STRUCT SubjectInfo &si)

	si.age           = PLACEHOLDER
	si.date_of_birth = PLACEHOLDER
	si.description   = PLACEHOLDER
	si.genotype      = PLACEHOLDER
	si.sex           = PLACEHOLDER
	si.species       = PLACEHOLDER
	si.subject_id    = PLACEHOLDER
	si.weight        = PLACEHOLDER
End

/// @brief Structure to hold all properties of the NWB file directly below `/`
Structure ToplevelInfo
	string session_description
	/// timestamp in seconds since Igor Pro epoch, UTC timezone
	variable session_start_time
	string nwb_version ///< NWB specification version
	string identifier
	WAVE/T file_create_date
EndStructure

/// @brief Initialization routine for ToplevelInfo
///
/// @param ti       TopLevelInfo Structure
/// @param version  [optional] defaults to latest version specified in NWB_VERSION_LATEST
threadsafe Function InitToplevelInfo(STRUCT ToplevelInfo &ti, variable version)

	ti.session_description = PLACEHOLDER
	ti.session_start_time  = DateTimeInUTC()
	ti.nwb_version         = GetNWBVersionString(version)
	ti.identifier          = Hash(GetISO8601TimeStamp() + num2str(enoise(1, NOISE_GEN_MERSENNE_TWISTER)), 1)

	if(version == 1)
		Make/N=1/T/FREE file_create_date = GetISO8601TimeStamp()
	elseif(version == NWB_VERSION_LATEST)
		Make/N=1/T/FREE file_create_date = GetISO8601TimeStamp(numFracSecondsDigits = 3, localTimeZone = 1)
	endif
	WAVE/T ti.file_create_date = file_create_date
End

/// @brief Holds class specific entries for TimeSeries objects
///
/// Usage for writers
/// @code
/// 	STRUCT TimeSeriesProperties tsp
/// 	InitTimeSeriesProperties(tsp, channelType, clampMode)
/// 	AddProperty(tsp, "gain", 1.23456)
/// 	// more calls tp AddProperty()
/// 	WriteSingleChannel(locationID, path, p, tsp)
/// @endcode
///
/// and for readers
/// @code
/// 	STRUCT TimeSeriesProperties tsp
/// 	InitTimeSeriesProperties(tsp, channelType, clampMode)
/// 	ReadTimeSeriesProperties(groupID, channel, tsp)
/// @endcode
///
Structure TimeSeriesProperties
	WAVE/T names
	WAVE data
	WAVE/T unit
	WAVE isCustom ///< NWBv1: 1 if the entry should be marked as NWB custom
	string missing_fields ///< keep track of missing fields while reading
	string neurodata_type // TimeSeries type
EndStructure

/// @brief Initialization of TimeSeriesProperties
///
/// @param[out] tsp         structure to initialize
/// @param[in]  channelType one of @ref IPNWBChannelTypes
/// @param[in]  clampMode   one of @ref IPNWB_ClampModes
threadsafe Function InitTimeSeriesProperties(STRUCT TimeSeriesProperties &tsp, variable channelType, variable clampMode)

	Make/FREE/T names = ""
	WAVE/T tsp.names = names

	Make/FREE data = NaN
	WAVE tsp.data = data

	Make/FREE/T unit = ""
	WAVE/T tsp.unit = unit

	Make/FREE isCustom = 0 // NWBv1 specific
	WAVE tsp.isCustom = isCustom

	// AddProperty() will remove the entries on addition of values
	tsp.missing_fields = GetTimeSeriesMissingFields(channelType, clampMode)

	tsp.neurodata_type = DetermineDataTypeFromProperties(channelType, clampMode)
End

Structure DynamicTable
	string colnames
	string description
	string data_type
EndStructure

threadsafe Function InitDynamicTable(STRUCT DynamicTable &dt)

	dt.colnames    = ""
	dt.description = "Description of what is in this dynamic table."
	dt.data_type   = "DynamicTable"
End

Structure ElementIdentifiers
	string data_type
EndStructure

threadsafe Function InitElementIdentifiers(STRUCT ElementIdentifiers &eli)

	eli.data_type = "ElementIdentifiers"
End

Structure VectorData
	string description
	string data_type
	string path
EndStructure

threadsafe Function InitVectorData(STRUCT VectorData &vd)

	vd.description = "Description of what these vectors represent."
	vd.data_type   = "VectorData"
	vd.path        = ""
End

Structure VectorIndex
	string data_type
	STRUCT VectorData target
EndStructure

threadsafe Function InitVectorIndex(STRUCT VectorIndex &vi, STRUCT VectorData &vd)

	vi.target      = vd
	vi.data_type   = "VectorIndex"
End
