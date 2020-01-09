#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

static StrConstant PATH_STIMSETS = "/general/stimsets"

/// @file IPNWB_Reader.ipf
/// @brief Generic functions related to import from the NeuroDataWithoutBorders format

/// @brief List devices in given hdf5 file
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of devices
threadsafe Function/S ReadDevices(fileID)
	variable fileID

	return RemovePrefixFromListItem("device_", H5_ListGroupMembers(fileID, "/general/devices"))
End

/// @brief List groups inside /general/labnotebook
///
/// @param  fileID identifier of open HDF5 file
/// @return        list with name of all groups inside /general/labnotebook/*
threadsafe Function/S ReadLabNoteBooks(fileID)
	variable fileID

	string result = ""
	string path = "/general/labnotebook"

	if(H5_GroupExists(fileID, path))
		result = H5_ListGroups(fileID, path)
	endif

	return result
End

/// @brief List all acquisition channels.
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of channels
threadsafe Function/S ReadAcquisition(fileID)
	variable fileID

	return H5_ListGroups(fileID, "/acquisition/timeseries")
End

/// @brief List all stimulus channels.
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of channels
threadsafe Function/S ReadStimulus(fileID)
	variable fileID

	return H5_ListGroups(fileID, "/stimulus/presentation")
End

/// @brief List all stimsets
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of contents of the stimset group
threadsafe Function/S ReadStimsets(fileID)
	variable fileID

	ASSERT_TS(H5_IsFileOpen(fileID), "ReadStimsets: given HDF5 file identifier is not valid")

	if(!StimsetPathExists(fileID))
		return ""
	endif

	return H5_ListGroupMembers(fileID, PATH_STIMSETS)
End

/// @brief Try to extract information from channel name string
///
/// @param[in]  channel  Input channel name in form data_00000_TTL1_3
/// @param[out] p        ReadChannelParams structure to get filled
threadsafe Function AnalyseChannelName(channel, p)
	string channel
	STRUCT ReadChannelParams &p

	string groupIndex, channelTypeStr, channelNumber, channelID

	SplitString/E="^(?i)data_([A-Z0-9]+)_([A-Z]+)([0-9]+)(?:_([A-Z0-9]+)){0,1}" channel, groupIndex, channelID, channelNumber, p.channelSuffix
	p.groupIndex = str2num(groupIndex)
	p.ttlBit = str2num(p.channelSuffix)
	strswitch(channelID)
		case "AD":
			p.channelType = CHANNEL_TYPE_ADC
			break
		case "DA":
			p.channelType = CHANNEL_TYPE_DAC
			break
		case "TTL":
			p.channelType = CHANNEL_TYPE_TTL
			break
		default:
			p.channelType = CHANNEL_TYPE_OTHER
	endswitch
	p.channelNumber = str2num(channelNumber)
End

/// @brief Read parameters from source attribute
///
/// @param[in]  locationID   HDF5 group specified channel is a member of
/// @param[in]  channel      channel to load
/// @param[out] p            ReadChannelParams structure to get filled
threadsafe Function LoadSourceAttribute(locationID, channel, p)
	variable locationID
	string channel
	STRUCT ReadChannelParams &p

	string attribute, property, value
	variable numStrings, i, error

	WAVE/T/Z wv = H5_LoadAttribute(locationID, channel, "source")
	ASSERT_TS(WaveExists(wv) && IsTextWave(wv), "Could not find the source attribute")

	numStrings = DimSize(wv, ROWS)

	// new format since eaa5e724 (H5_WriteTextAttribute: Force dataspace to SIMPLE
	// for lists, 2016-08-28)
	// source has now always one element
	if(numStrings == 1)
		WAVE/T list = ListToTextWave(wv[0], ";")
		numStrings = DimSize(list, ROWS)
	else
		WAVE/T list = wv
	endif

	for(i = 0; i < numStrings; i += 1)
		SplitString/E="(.*)=(.*)" list[i], property, value
		strswitch(property)
			case "Device":
				p.device = value
				break
			case "Sweep":
				p.sweep = str2num(value)
				break
			case "ElectrodeNumber":
				p.electrodeNumber = str2num(value)
				break
			case "AD":
				p.channelType = CHANNEL_TYPE_ADC
				p.channelNumber = str2num(value)
				break
			case "DA":
				p.channelType = CHANNEL_TYPE_DAC
				p.channelNumber = str2num(value)
				break
			case "TTL":
				p.channelType = CHANNEL_TYPE_TTL
				p.channelNumber = str2num(value)
				break
			case "TTLBit":
				p.ttlBit = str2num(value)
				break
			default:
		endswitch
	endfor
End

/// @brief Load data wave from specified path
///
/// @param locationID   id of an open hdf5 group containing channel
///                     id can also be of an open nwb file. In this case specify (optional) path.
/// @param channel      name of channel for which data attribute is loaded
/// @param path         use path to specify group inside hdf5 file where ./channel/data is located.
/// @return             reference to free wave containing loaded data
threadsafe Function/Wave LoadDataWave(locationID, channel, [path])
	variable locationID
	string channel, path

	if(ParamIsDefault(path))
		path = "./"
	endif

	Assert_TS(H5_GroupExists(locationID, path), "LoadDataWave: Path is not in nwb file")

	path += channel + "/data"

	return H5_LoadDataset(locationID, path)
End

/// @brief Load single channel data as a wave from /acquisition/timeseries
///
/// @param locationID   id of an open hdf5 group or file
/// @param channel      name of channel for which data attribute is loaded
/// @return             reference to wave containing loaded data
threadsafe Function/Wave LoadTimeseries(locationID, channel)
	variable locationID
	string channel

	WAVE data = LoadDataWave(locationID, channel, path = "/acquisition/timeseries/")

	return data
End

/// @brief Load single channel data as a wave from /stimulus/presentation/
///
/// @param locationID    id of an open hdf5 group or file
/// @param channel       name of channel for which data attribute is loaded
/// @return             reference to wave containing loaded data
threadsafe Function/Wave LoadStimulus(locationID, channel)
	variable locationID
	string channel

	WAVE data = LoadDataWave(locationID, channel, path = "/stimulus/presentation/")

	return data
End

/// @brief Open hdf5 group containing acquisition channels
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
threadsafe Function OpenAcquisition(fileID)
	variable fileID

	return H5_OpenGroup(fileID, "/acquisition/timeseries")
End

/// @brief Open hdf5 group containing stimulus channels
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
threadsafe Function OpenStimulus(fileID)
	variable fileID

	return H5_OpenGroup(fileID, "/stimulus/presentation")
End

/// @brief Open hdf5 group containing stimsets
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
threadsafe Function OpenStimset(fileID)
	variable fileID

	ASSERT_TS(StimsetPathExists(fileID), "OpenStimset: Path is not in nwb file")

	return H5_OpenGroup(fileID, PATH_STIMSETS)
End

/// @brief Check if the path to the stimsets exist in the NWB file.
threadsafe Function StimsetPathExists(fileID)
	variable fileID

	return H5_GroupExists(fileID, PATH_STIMSETS)
End

/// @brief Read in all NWB datasets from the root group ('/')
threadsafe Function ReadTopLevelInfo(fileID, toplevelInfo)
	variable fileID
	STRUCT ToplevelInfo &toplevelInfo

	variable groupID

	groupID = H5_OpenGroup(fileID, "/")

	toplevelInfo.session_description     = ReadTextDataSetAsString(groupID, "session_description")
	toplevelInfo.nwb_version             = ReadTextDataSetAsString(groupID, "nwb_version")
	toplevelInfo.identifier              = ReadTextDataSetAsString(groupID, "identifier")
	toplevelInfo.session_start_time      = ParseISO8601TimeStamp(ReadTextDataSetAsString(groupID, "session_start_time"))
	WAVE/T toplevelInfo.file_create_date = ReadTextDataSet(groupID, "file_create_date")

	HDF5CloseGroup/Z groupID
End

/// @brief Read in all standard NWB datasets from the group '/general'
threadsafe Function ReadGeneralInfo(fileID, generalinfo)
	variable fileID
	STRUCT GeneralInfo &generalinfo

	variable groupID

	groupID = H5_OpenGroup(fileID, "/general")

	generalInfo.session_id             = ReadTextDataSetAsString(groupID, "session_id")
	generalInfo.experimenter           = ReadTextDataSetAsString(groupID, "experimenter")
	generalInfo.institution            = ReadTextDataSetAsString(groupID, "institution")
	generalInfo.lab                    = ReadTextDataSetAsString(groupID, "lab")
	generalInfo.related_publications   = ReadTextDataSetAsString(groupID, "related_publications")
	generalInfo.notes                  = ReadTextDataSetAsString(groupID, "notes")
	generalInfo.experiment_description = ReadTextDataSetAsString(groupID, "experiment_description")
	generalInfo.data_collection        = ReadTextDataSetAsString(groupID, "data_collection")
	generalInfo.stimulus               = ReadTextDataSetAsString(groupID, "stimulus")
	generalInfo.pharmacology           = ReadTextDataSetAsString(groupID, "pharmacology")
	generalInfo.surgery                = ReadTextDataSetAsString(groupID, "surgery")
	generalInfo.protocol               = ReadTextDataSetAsString(groupID, "protocol")
	generalInfo.virus                  = ReadTextDataSetAsString(groupID, "virus")
	generalInfo.slices                 = ReadTextDataSetAsString(groupID, "slices")

	HDF5CloseGroup/Z groupID
End

/// @brief Read in all NWB datasets from the root group '/general/subject'
threadsafe Function ReadSubjectInfo(fileID, subjectInfo)
	variable fileID
	STRUCT SubjectInfo &subjectInfo

	variable groupID

	groupID = H5_OpenGroup(fileID, "/general/subject")

	subjectInfo.subject_id  = ReadTextDataSetAsString(groupID, "subject_id")
	subjectInfo.description = ReadTextDataSetAsString(groupID, "description")
	subjectInfo.species     = ReadTextDataSetAsString(groupID, "species")
	subjectInfo.genotype    = ReadTextDataSetAsString(groupID, "genotype")
	subjectInfo.sex         = ReadTextDataSetAsString(groupID, "sex")
	subjectInfo.age         = ReadTextDataSetAsString(groupID, "age")
	subjectInfo.weight      = ReadTextDataSetAsString(groupID, "weight")

	HDF5CloseGroup/Z groupID
End

/// @brief Read the TimeSeries properties from the given group in locationID
///
/// @param[in]  locationID TimeSeries group ID
/// @param[in]  channel    TimeSeries group name
/// @param[out] tsp        TimeSeriesProperties structure
threadsafe Function ReadTimeSeriesProperties(locationID, channel, tsp)
	variable locationID
	string channel
	STRUCT TimeSeriesProperties &tsp

	variable clampMode, i, numEntries, value, channelType, groupID, idx
	string ancestry, entry, list

	ancestry = ReadTextAttributeAsList(locationID, channel, "ancestry")
	clampMode = GetClampModeFromAncestry(ancestry)
	channelType = GetChannelTypeFromAncestry(ancestry)

	InitTimeSeriesProperties(tsp, channelType, clampMode)

	groupID = H5_OpenGroup(locationID, channel)

	list = ""
	numEntries = ItemsInList(tsp.missing_fields)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, tsp.missing_fields)

		value = ReadDataSetAsNumber(groupID, entry)
		if(IsNaN(value))
			continue
		endif

		tsp.names[idx] = entry
		tsp.data[idx] = value
		tsp.isCustom[idx] = 0

		idx += 1

		list = AddListItem(entry, list, ";", inf)
	endfor

	HDF5CloseGroup/Z groupID

	Redimension/N=(idx) tsp.names, tsp.data, tsp.isCustom

	tsp.missing_fields = RemoveFromList(list, tsp.missing_fields)

	if(strlen(tsp.missing_fields) > 0)
		// unify list formatting to end with ;
		tsp.missing_fields = RemoveEnding(tsp.missing_fields, ";") + ";"
	endif
End
