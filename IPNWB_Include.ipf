#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IgorVersion=7.0

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Include.ipf
/// @brief Main include

/// Use the following line in the builtin Procedure window or use
/// SetIgorOption poundDefine=IPNWB_DEFINE_IM to use IPNWB in an independent module
/// #define IPNWB_DEFINE_IM

/// Use the following if you need the generic helper functions
/// #define IPNWB_INCLUDE_UTILS

#include "IPNWB_Constants" version>=0.18
#include "IPNWB_Debugging" version>=0.18
#include "IPNWB_HDF5Helpers" version>=0.18
#include "IPNWB_NWBUtils" version>=0.18
#include "IPNWB_Reader" version>=0.18
#include "IPNWB_Structures" version>=0.18
#include "IPNWB_Utils" version>=0.18
#include "IPNWB_Writer" version>=0.18
