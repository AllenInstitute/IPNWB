#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma version          = 0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_NWBUtils.ipf
/// @brief NWB utility functions

#ifdef IPNWB_DEFINE_IM
#pragma IndependentModule = IPNWB
#endif // IPNWB_DEFINE_IM

static StrConstant NWB_PATCHCLAMPSERIES_V1 = "/acquisition/timeseries"
static StrConstant NWB_PATCHCLAMPSERIES_V2 = "/acquisition"

static StrConstant NWB_VERSION_V1 = "NWB-1.0.5"
static StrConstant NWB_VERSION_V2 = "2.2.4"

/// @brief Determine the namespace of the given neurodata type.
///
/// Note: - core specification "2.2.0"
///       - hdmf-common "1.1.0"
threadsafe Function/S DetermineNamespace(string neurodata_type)

	Make/T/FREE nwb_spec = {                              \
	                        "AbstractFeatureSeries",      \
	                        "AnnotationSeries",           \
	                        "AxisMap",                    \
	                        "BehavioralEpochs",           \
	                        "BehavioralEvents",           \
	                        "BehavioralTimeSeries",       \
	                        "Clustering",                 \
	                        "ClusterWaveforms",           \
	                        "CompassDirection",           \
	                        "CorrectedImageStack",        \
	                        "CurrentClampSeries",         \
	                        "CurrentClampStimulusSeries", \
	                        "DecompositionSeries",        \
	                        "Device",                     \
	                        "DfOverF",                    \
	                        "ElectricalSeries",           \
	                        "ElectrodeGroup",             \
	                        "EventDetection",             \
	                        "EventWaveform",              \
	                        "EyeTracking",                \
	                        "FeatureExtraction",          \
	                        "FilteredEphys",              \
	                        "Fluorescence",               \
	                        "GrayscaleImage",             \
	                        "Image",                      \
	                        "ImageMaskSeries",            \
	                        "Images",                     \
	                        "ImageSegmentation",          \
	                        "ImageSeries",                \
	                        "ImagingPlane",               \
	                        "ImagingRetinotopy",          \
	                        "IndexSeries",                \
	                        "IntervalSeries",             \
	                        "IntracellularElectrode",     \
	                        "IZeroClampSeries",           \
	                        "LabMetaData",                \
	                        "LFP",                        \
	                        "MotionCorrection",           \
	                        "NWBContainer",               \
	                        "NWBData",                    \
	                        "NWBDataInterface",           \
	                        "NWBFile",                    \
	                        "OpticalChannel",             \
	                        "OpticalSeries",              \
	                        "OptogeneticSeries",          \
	                        "OptogeneticStimulusSite",    \
	                        "PatchClampSeries",           \
	                        "PlaneSegmentation",          \
	                        "Position",                   \
	                        "ProcessingModule",           \
	                        "PupilTracking",              \
	                        "RetinotopyImage",            \
	                        "RetinotopyMap",              \
	                        "RGBAImage",                  \
	                        "RGBImage",                   \
	                        "RoiResponseSeries",          \
	                        "ScratchData",                \
	                        "SpatialSeries",              \
	                        "SpikeEventSeries",           \
	                        "Subject",                    \
	                        "SweepTable",                 \
	                        "TimeIntervals",              \
	                        "TimeSeries",                 \
	                        "TwoPhotonSeries",            \
	                        "Units",                      \
	                        "VoltageClampSeries",         \
	                        "VoltageClampStimulusSeries"  \
	                       }
	FindValue/TEXT=(neurodata_type)/TXOP=(0x01 | 0x04) nwb_spec
	if(V_Value != -1)
		return NWB_SPEC_NAME
	endif

	Make/T/FREE hdmf_spec = {                      \
	                         "Container",          \
	                         "CSRMatrix",          \
	                         "Data",               \
	                         "DynamicTable",       \
	                         "DynamicTableRegion", \
	                         "ElementIdentifiers", \
	                         "Index",              \
	                         "VectorData",         \
	                         "VectorIndex"         \
	                        }
	FindValue/TEXT=(neurodata_type)/TXOP=(0x01 | 0x04) hdmf_spec
	if(V_Value != -1)
		return HDMF_SPEC_NAME
	endif

	Make/T/FREE ndx_mies_spec = {                                       \
	                             "MIESMetaData",                        \
	                             "GeneratedBy",                         \
	                             "UserComment",                         \
	                             "UserCommentString",                   \
	                             "UserCommentDevice",                   \
	                             "Testpulse",                           \
	                             "TestpulseDevice",                     \
	                             "TestpulseMetadata",                   \
	                             "TestpulseRawData",                    \
	                             "LabNotebook",                         \
	                             "LabNotebookDevice",                   \
	                             "LabNotebookNumericalValues",          \
	                             "LabNotebookNumericalKeys",            \
	                             "LabNotebookTextualValues",            \
	                             "LabNotebookTextualKeys",              \
	                             "Results",                             \
	                             "ResultsNumericalValues",              \
	                             "ResultsNumericalKeys",                \
	                             "ResultsTextualValues",                \
	                             "ResultsTextualKeys",                  \
	                             "StimulusSets",                        \
	                             "StimulusSetWavebuilderParameter",     \
	                             "StimulusSetWavebuilderParameterText", \
	                             "StimulusSetWavebuilderSegmentTypes",  \
	                             "StimulusSetReferencedWaveform",       \
	                             "StimulusSetReferencedFolder",         \
	                             "StimulusSetReferenced"                \
	                            }
	FindValue/TEXT=(neurodata_type)/TXOP=(0x01 | 0x04) ndx_mies_spec
	if(V_Value != -1)
		return NDX_MIES_SPEC_NAME
	endif

	return ""
End

/// @brief Return the initial values for the missing_fields attribute depending
///        on the channel type, one of @ref IPNWBChannelTypes, and the clamp
///        mode, one in @ref IPNWB_ClampModes.
threadsafe Function/S GetTimeSeriesMissingFields(variable channelType, variable clampMode)

	string neurodata_type = DetermineDataTypeFromProperties(channelType, clampMode)

	strswitch(neurodata_type)
		case "VoltageClampSeries":
			return "gain;capacitance_fast;capacitance_slow;resistance_comp_bandwidth;resistance_comp_correction;resistance_comp_prediction;whole_cell_capacitance_comp;whole_cell_series_resistance_comp"
		case "CurrentClampSeries":
		case "IZeroClampSeries":
			return "gain;bias_current;bridge_balance;capacitance_compensation"
		case "PatchClampSeries":
		case "VoltageClampStimulusSeries":
		case "CurrentClampStimulusSeries":
			return "gain"
		case "TimeSeries": // unassociated channel data
		default:
			return ""
	endswitch
End

/// @brief Derive the channel type, one of @ref IPNWBChannelTypes, from the
///        `neurodata_type` attribute and return it
///
/// @param neurodata_type string with neurodata type specification defined in
///                       `nwb.icephys.json`_
threadsafe Function GetChannelTypeFromNeurodataType(string neurodata_type)

	strswitch(neurodata_type)
		case "VoltageClampSeries":
		case "CurrentClampSeries":
		case "IZeroClampSeries":
			return IPNWB_CHANNEL_TYPE_ADC
		case "VoltageClampStimulusSeries":
		case "CurrentClampStimulusSeries":
			return IPNWB_CHANNEL_TYPE_DAC
		case "TimeSeries": // unassociated channel data
			return IPNWB_CHANNEL_TYPE_OTHER
		default:
			ASSERT_TS(0, "Unknown neurodata_type: " + neurodata_type)
			break
	endswitch

End

/// @brief Derive the clamp mode from the `neurodata_type` attribute and return
///        it
///
/// @param neurodata_type string with neurodata type specification defined in
///                       `nwb.icephys.json`_
threadsafe Function GetClampModeFromNeurodataType(string neurodata_type)

	strswitch(neurodata_type)
		case "VoltageClampSeries":
		case "VoltageClampStimulusSeries":
			return V_CLAMP_MODE
		case "CurrentClampSeries":
		case "CurrentClampStimulusSeries":
			return I_CLAMP_MODE
		case "IZeroClampSeries":
			return I_EQUAL_ZERO_MODE
		case "TimeSeries": // unassociated channel data
			return NaN
		default:
			ASSERT_TS(0, "Unknown data type: " + neurodata_type)
			break
	endswitch
End

/// @brief Determine the neurodata type based on channel type and clamp mode
///
/// @see GetClampModeFromNeurodataType
///
/// @param channelType  one in @see IPNWBChannelTypes
/// @param clampMode    one in @see IPNWB_ClampModes
///
/// @return neurodata_type string with neurodata type specification defined in
///         `nwb.icephys.json`_
threadsafe Function/S DetermineDataTypeFromProperties(variable channelType, variable clampMode)

	switch(channelType)
		case IPNWB_CHANNEL_TYPE_ADC:
			switch(clampMode)
				case V_CLAMP_MODE:
					return "VoltageClampSeries"
				case I_CLAMP_MODE:
					return "CurrentClampSeries"
				case I_EQUAL_ZERO_MODE:
					return "IZeroClampSeries"
				default:
					// unassociated channel
					break
			endswitch
		case IPNWB_CHANNEL_TYPE_DAC:
			switch(clampMode)
				case V_CLAMP_MODE:
					return "VoltageClampStimulusSeries"
				case I_CLAMP_MODE:
					return "CurrentClampStimulusSeries"
				default:
					// unassociated channel
					break
			endswitch
		default:
			// TTL
			break
	endswitch

	return "TimeSeries"
End

/// @brief get the (major) version of the nwb file
///
/// @param fileID id of open hdf5 file
/// @returns major version e.g. 1 or 2
threadsafe Function/S ReadNWBVersion(variable fileID)

	string version

	if(!H5_AttributeExists(fileID, "/", "nwb_version"))
		WAVE/Z/T nwbVersion = H5_LoadDataSet(fileID, "/nwb_version")

		if(!WaveExists(nwbVersion))
			// fallback to old naming before IPNWB/a99dba5d (IPNWB: Raise nwb version to 1.0.5, 2016-08-05)
			WAVE/Z/T nwbVersion = H5_LoadDataSet(fileID, "/neurodata_version")
		endif
	else
		WAVE/Z/T nwbVersion = H5_LoadAttribute(fileID, "/", "nwb_version")
	endif

	if(!WaveExists(nwbVersion))
		return ""
	endif

	return nwbVersion[0]
End

/// @brief convert version string to major version
///
/// @see GetNWBVersionString
threadsafe Function GetNWBMajorVersion(string version)

	variable majorVersion, version1, version2

	AnalyzeNWBVersion(version, majorVersion, version1, version2)
	EnsureValidNWBVersion(majorVersion)

	return majorVersion
End

/// @brief convert version string to major and all minor numeric versions
///
/// @param[in]  version
/// @param[out] version0 numeric first part of the version string (major
///                      Version)
/// @param[out] version1 numeric second part of the version string (minor
///                      Version)
/// @param[out] version2 numeric third part of the version string (sub Version)
/// @returns analyzed numeric versions
threadsafe Function AnalyzeNWBVersion(string version, variable &version0, variable &version1, variable &version2)

	variable err
	string strVersion0, strVersion1, strVersion2, msg
	string regexp = "^(?:NWB-)?([0-9]+)\.([0-9]+)\.*([bx]|[0-9]+)"

	SplitString/E=(regexp) version, strVersion0, strVersion1, strVersion2
	sprintf msg, "Unexpected number of matches (%d) in nwb version string %s.", V_flag, version
	ASSERT_TS(V_flag >= 2, msg)

	version2 = str2num(strVersion2); err = GetRTError(1)
	version1 = str2num(strVersion1)
	version0 = str2num(strVersion0)

	EnsureValidNWBVersion(version0)

	return version0
End

threadsafe Function EnsureValidNWBVersion(variable version)

	ASSERT_TS(version == 1 || version == 2, "Invalid version: " + num2str(version))
End

/// @brief Load the NWB specification from files in the main directory
///
/// Note: @c Open, @c FbinRead and @c Close are not threadsafe
///
/// @param specLoc  Igor Pro file path to specifications (Path Separator: ":")
/// @param specName specifications file identifier (without trailing *.json ending)
///
/// @returns JSON string
Function/S LoadSpecification(string specLoc, string specName)

	variable refNum, err
	string msg, fileName
	string str = ""
	sprintf filename, "%s%s%s.json", SpecificationsDiscLocation(), specLoc, specName

	try
		ClearRTError()
		Open/R refNum as fileName; AbortOnRTE
		FReadLine/T="" refNum, str; AbortOnRTE
		Close refNum; AbortOnRTE
	catch
		Close/A
		err = GetRTError(1)
		sprintf msg, "Could not read file at %s. Error %d\r", fileName, err
		ASSERT_TS(0, msg)
	endtry

	return str
End

/// @brief Return Folder of NWB:N specifications.
///
/// Note: This is typically located at the location of the IPNWB program ipf files.
///       @c FunctionPath is not threadsafe
Function/S SpecificationsDiscLocation()

	return GetFolder(FunctionPath(""))
End

/// @brief Read a text attribute as semicolon `;` separated list
///
/// @param[in]  locationID HDF5 identifier, can be a file or group
/// @param[in]  path       Additional path on top of `locationID` which identifies
///                        the group or dataset
/// @param[in]  name       Name of the attribute to load
threadsafe Function/S ReadTextAttributeAsList(variable locationID, string path, string name)

	return TextWaveToList(ReadTextAttribute(locationID, path, name), ";")
End

/// @brief Read a text attribute as text wave, return a single element
///        wave with #PLACEHOLDER if it does not exist.
///
/// @param[in]  locationID HDF5 identifier, can be a file or group
/// @param[in]  path       Additional path on top of `locationID` which identifies
///                        the group or dataset
/// @param[in]  name       Name of the attribute to load
threadsafe Function/WAVE ReadTextAttribute(variable locationID, string path, string name)

	WAVE/Z/T wv = H5_LoadAttribute(locationID, path, name)

	if(!WaveExists(wv))
		Make/FREE/T/N=1 wv = PLACEHOLDER
		return wv
	endif

	ASSERT_TS(IsTextWave(wv), "Expected a text wave")

	return wv
End

/// @brief Read a text attribute as string, return #PLACEHOLDER if it does not exist
///
/// @param[in]  locationID HDF5 identifier, can be a file or group
/// @param[in]  path       Additional path on top of `locationID` which identifies
///                        the group or dataset
/// @param[in]  name       Name of the attribute to load
threadsafe Function/S ReadTextAttributeAsString(variable locationID, string path, string name)

	WAVE/Z/T wv = H5_LoadAttribute(locationID, path, name)

	if(!WaveExists(wv))
		return PLACEHOLDER
	endif

	ASSERT_TS(DimSize(wv, ROWS) == 1, "Expected exactly one row")
	ASSERT_TS(IsTextWave(wv), "Expected a text wave")

	return wv[0]
End

/// @brief Read a text attribute as number, return `NaN` if it does not exist
///
/// @param[in]  locationID HDF5 identifier, can be a file or group
/// @param[in]  path       Additional path on top of `locationID` which identifies
///                        the group or dataset
/// @param[in]  name       Name of the attribute to load
threadsafe Function ReadAttributeAsNumber(variable locationID, string path, string name)

	WAVE/Z wv = H5_LoadAttribute(locationID, path, name)

	if(!WaveExists(wv))
		return NaN
	endif

	ASSERT_TS(DimSize(wv, ROWS) == 1, "Expected exactly one row")
	ASSERT_TS(IsNumericWave(wv), "Expected a text wave")

	return wv[0]
End

/// @brief Read a text dataset as text wave, return a single element
///        wave with #PLACEHOLDER if it does not exist.
///
/// @param locationID HDF5 identifier, can be a file or group
/// @param name    Name of the HDF5 dataset
threadsafe Function/WAVE ReadTextDataSet(variable locationID, string name)

	WAVE/Z/T wv = H5_LoadDataset(locationID, name)

	if(!WaveExists(wv))
		Make/FREE/T/N=1 wv = PLACEHOLDER
		return wv
	endif

	ASSERT_TS(IsTextWave(wv), "Expected a text wave")

	return wv
End

/// @brief Read a text dataset as string, return #PLACEHOLDER if it does not exist
///
/// @param locationID HDF5 identifier, can be a file or group
/// @param name       Name of the HDF5 dataset
threadsafe Function/S ReadTextDataSetAsString(variable locationID, string name)

	WAVE/Z/T wv = H5_LoadDataset(locationID, name)

	if(!WaveExists(wv))
		return PLACEHOLDER
	endif

	ASSERT_TS(DimSize(wv, ROWS) == 1, "ReadTextDataSetAsString: Expected exactly one row")
	ASSERT_TS(IsTextWave(wv), "Expected a text wave")

	return wv[0]
End

/// @brief Read a text dataset as number, return `NaN` if it does not exist
///
/// @param locationID HDF5 identifier, can be a file or group
/// @param name       Name of the HDF5 dataset
threadsafe Function ReadDataSetAsNumber(variable locationID, string name)

	WAVE/Z wv = H5_LoadDataset(locationID, name)

	if(!WaveExists(wv))
		return NaN
	endif

	ASSERT_TS(DimSize(wv, ROWS) == 1, "Expected exactly one row")
	ASSERT_TS(IsNumericWave(wv), "Expected a numeric wave")
	return wv[0]
End

/// @brief Write a text dataset only if it is not equal to #PLACEHOLDER
///
/// @param locationID                                               HDF5 identifier, can be a file or group
/// @param name                                                     Name of the HDF5 dataset
/// @param str                                                      Contents to write into the dataset
/// @param compressionMode [optional, defaults to #NO_COMPRESSION]  Type of compression to use, one of @ref CompressionMode
threadsafe Function WriteTextDatasetIfSet(variable locationID, string name, string str, [variable compressionMode])

	if(ParamIsDefault(compressionMode))
		compressionMode = NO_COMPRESSION
	endif

	if(!cmpstr(str, PLACEHOLDER))
		return NaN
	endif

	H5_WriteTextDataset(locationID, name, str = str, compressionMode = compressionMode)
End

/// @brief Convenience getters
///
/// Igor Pro does not allow cross IM access to constants
/// @{
threadsafe Function GetNoCompression()

	return NO_COMPRESSION
End

threadsafe Function GetChunkedCompression()

	return CHUNKED_COMPRESSION
End

threadsafe Function GetSingleChunkCompression()

	return SINGLE_CHUNK_COMPRESSION
End

threadsafe Function/S CompressionModeToString(variable mode)

	switch(mode)
		case NO_COMPRESSION:
			return "no"
		case CHUNKED_COMPRESSION:
			return "chunked"
		case SINGLE_CHUNK_COMPRESSION:
			return "single chunk"
		default:
			ASSERT_TS(0, "Invalid mode: " + num2str(mode))
	endswitch
End

/// @}

/// @brief get location of the patchclamp series acquisition object
///
/// @param version  target NWB version
/// @returns        full path to patchclampseries group
threadsafe Function/S GetNWBgroupPatchClampSeries(variable version)

	if(version == 1)
		return NWB_PATCHCLAMPSERIES_V1
	elseif(version == 2)
		return NWB_PATCHCLAMPSERIES_V2
	else
		return ""
	endif
End

/// @brief get NWB version for current Igor Pro implementation
///
/// @param version  maior NWB version e.g. 2
/// @returns        full version string in the format `(?:NWB-)?[1,2]\.[0-9](?:\.[0-9])?[b]?`
threadsafe Function/S GetNWBVersionString(variable version)

	switch(version)
		case 1:
			return NWB_VERSION_V1
		case NWB_VERSION_LATEST:
			return NWB_VERSION_V2
		default:
			return ""
	endswitch
End

/// @brief get latest supported NWB version
/// @returns maior version
threadsafe Function GetNWBVersion()

	return NWB_VERSION_LATEST
End

/// @brief Return the name of the history dataset
Function/S GetHistoryAndLogFileDatasetName(variable version)

	if(version == 1)
		return "history"
	elseif(version == 2)
		return "data_collection"
	else
		ASSERT_TS(0, "Invalid nwb version")
	endif
End
