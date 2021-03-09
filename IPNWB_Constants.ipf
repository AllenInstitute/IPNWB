#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Constants.ipf
/// @brief Constants

StrConstant PLACEHOLDER = "PLACEHOLDER"

static StrConstant NWB_VERSION_V1 = "NWB-1.0.5"
static StrConstant NWB_VERSION_V2 = "2.2.4"
Constant NWB_VERSION_LATEST = 2

/// @name HDF5 file paths
///
/// @anchor IPNWB_GroupLocations
/// @{
StrConstant NWB_ROOT    = "/"
StrConstant NWB_GENERAL = "/general"
StrConstant NWB_SUBJECT = "/general/subject"
StrConstant NWB_DEVICES = "/general/devices"
StrConstant NWB_STIMULUS = "/general/stimsets"
StrConstant NWB_LABNOTEBOOK = "/general/labnotebook"
StrConstant NWB_INTRACELLULAR_EPHYS = "/general/intracellular_ephys"
StrConstant NWB_STIMULUS_TEMPLATES = "/stimulus/templates"
StrConstant NWB_STIMULUS_PRESENTATION = "/stimulus/presentation"
static StrConstant NWB_PATCHCLAMPSERIES_V1 = "/acquisition/timeseries"
static StrConstant NWB_PATCHCLAMPSERIES_V2 = "/acquisition"
StrConstant NWB_IMAGES = "/acquisition/images"
StrConstant NWB_EPOCHS = "/epochs"
StrConstant NWB_PROCESSING = "/processing"
StrConstant NWB_ANALYSIS = "/analysis"
StrConstant NWB_SPECIFICATIONS = "/specifications"
/// @}

/// @name IPNWB naming conventions
///
/// @{
StrConstant NWB_ELECTRODE_PREFIX = "electrode_"
/// @}

/// @name Constants for FunctionInfo and WaveType
///
/// @anchor IPNWB_IgorTypes
/// @{
Constant IGOR_TYPE_COMPLEX          = 0x001
Constant IGOR_TYPE_32BIT_FLOAT      = 0x002
Constant IGOR_TYPE_64BIT_FLOAT      = 0x004
Constant IGOR_TYPE_8BIT_INT         = 0x008
Constant IGOR_TYPE_16BIT_INT        = 0x010
Constant IGOR_TYPE_32BIT_INT        = 0x020
Constant IGOR_TYPE_UNSIGNED         = 0x040 ///< Can be combined, using bitwise or, with all integer types
Constant IGOR_TYPE_STRUCT_PARAMETER = 0x200
/// @}

/// Convenience definition to nicify expressions like DimSize(wv, ROWS)
/// easier to read than DimSize(wv, 0).
/// @{
Constant ROWS   = 0
Constant COLS   = 1
Constant LAYERS = 2
Constant CHUNKS = 3
/// @}

StrConstant CHANNEL_NAMES = "AD;DA;;TTL"

/// @name Channel constants (inspired by the ITC XOP)
/// @anchor IPNWB_ChannelTypes
/// @{
Constant CHANNEL_TYPE_OTHER = -1
Constant CHANNEL_TYPE_ADC   = 0
Constant CHANNEL_TYPE_DAC   = 1
Constant CHANNEL_TYPE_TTL   = 3
/// @}

/// @name Constants for the acquisition modes
/// @anchor IPNWB_ClampModes
/// @{
Constant V_CLAMP_MODE      = 0
Constant I_CLAMP_MODE      = 1
Constant I_EQUAL_ZERO_MODE = 2
/// @}

/// @name Parameters for gnoise and enoise
///@{
Constant NOISE_GEN_LINEAR_CONGRUENTIAL = 1 ///< Don't use for new code.
Constant NOISE_GEN_MERSENNE_TWISTER    = 2
///@}

/// Maximum length of a valid name in bytes in Igor Pro.
Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES = 31

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

/// @brief get location of the patchclamp series acquisition object
///
/// @param version  target NWB version
/// @returns        full path to patchclampseries group
threadsafe Function/S GetNWBgroupPatchClampSeries(version)
	variable version

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
threadsafe Function/S GetNWBVersionString(version)
	variable version

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
/// @}

/// @name Constants for the compression modes
/// @anchor CompressionMode
/// @{
Constant NO_COMPRESSION           = 0x0
Constant CHUNKED_COMPRESSION      = 0x1
Constant SINGLE_CHUNK_COMPRESSION = 0x2
/// @}

/// @name Constants for the reference modes
/// @anchor ReferenceMode
/// @{
Constant NO_REFERENCE     = 0x0
Constant OBJECT_REFERENCE = 0x1
Constant REGION_REFERENCE = 0x2
/// @}

/// @name Constants for NWB version 2 specifications and base classes
/// @{
StrConstant NWB_SPEC_NAME = "core"
StrConstant NWB_SPEC_VERSION = "2.2.4"
StrConstant NWB_SPEC_LOCATION = "namespace:core:json:"
StrConstant NWB_SPEC_START = "nwb.namespace"
StrConstant NWB_SPEC_INCLUDE = "nwb.base;nwb.behavior;nwb.device;nwb.ecephys;nwb.epoch;nwb.file;nwb.icephys;nwb.image;nwb.misc;nwb.ogen;nwb.ophys;nwb.retinotopy;"
StrConstant HDMF_SPEC_NAME = "hdmf-common"
StrConstant HDMF_SPEC_VERSION = "1.1.3"
StrConstant HDMF_SPEC_LOCATION = "namespace:hdmf-common:json:"
StrConstant HDMF_SPEC_START = "namespace"
StrConstant HDMF_SPEC_INCLUDE = "table;sparse;"
StrConstant NDX_MIES_SPEC_NAME = "ndx-mies"
StrConstant NDX_MIES_SPEC_VERSION = "0.1.0"
StrConstant NDX_MIES_SPEC_LOCATION = "namespace:ndx-mies:json:"
StrConstant NDX_MIES_SPEC_START = "namespace"
StrConstant NDX_MIES_SPEC_INCLUDE = "ndx-mies.extensions"
/// @}
