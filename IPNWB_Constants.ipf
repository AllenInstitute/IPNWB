#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma version=0.18

#ifdef IPNWB_DEFINE_IM
#pragma IndependentModule=IPNWB
#endif

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Constants.ipf
/// @brief Constants

StrConstant PLACEHOLDER = "PLACEHOLDER"
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

/// @name Channel constants (inspired by the ITC XOP)
/// @anchor IPNWBChannelTypes
/// @{
Constant IPNWB_CHANNEL_TYPE_OTHER = -1
Constant IPNWB_CHANNEL_TYPE_ADC   = 0
Constant IPNWB_CHANNEL_TYPE_DAC   = 1
Constant IPNWB_CHANNEL_TYPE_TTL   = 3
/// @}

StrConstant CHANNEL_NAMES = "AD;DA;;TTL"

#ifdef IPNWB_INCLUDE_UTILS

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

#endif // IPNWB_INCLUDE_UTILS

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
