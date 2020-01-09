#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Reader.ipf
/// @brief Generic functions related to import from the NeuroDataWithoutBorders format

/// @brief List devices in given hdf5 file
///
/// @param fileID  identifier of open HDF5 file
/// @param version major NWB version
/// @return        comma separated list of devices
threadsafe Function/S ReadDevices(fileID, version)
	variable fileID, version

	string devices, path
	variable i, numDevices

	EnsureValidNWBVersion(version)

	if(version == 1)
		devices = H5_ListGroupMembers(fileID, NWB_DEVICES)
	elseif(version == NWB_VERSION_LATEST)
		devices = H5_ListGroups(fileID, NWB_DEVICES)
		numDevices = ItemsInList(devices)
		for(i = numDevices - 1; i >= 0; i -= 1)
			sprintf path, "%s/%s", NWB_DEVICES, StringFromList(i, devices)
			if(!!cmpstr(ReadTextAttributeAsString(fileID, path, "neurodata_type"), "Device"))
				devices = RemoveListItem(i, devices)
			endif
		endfor
	endif

	return RemovePrefixFromListItem("device_", devices)
End

/// @brief return name of electrode
///
/// @see AddElectrode
///
/// @param discLocation full path to file in Igor disc path notation
/// @param seriesPath   Full Path inside HDF5 structure to TimeSeries group
/// @param version      major NWB version
/// @return the name of the electrode or "" for unassociated channels
threadsafe Function/S ReadElectrodeName(discLocation, seriesPath, version)
	string discLocation, seriesPath
	variable version

	string h5path, link, regExp, electrode, electrodeName
	variable locationID
	STRUCT ReadChannelParams p

	EnsureValidNWBVersion(version)

	AnalyseChannelName(seriesPath, p)
	sprintf h5path, "%s/electrode", seriesPath

	if(version == 1)
		h5path += "_name"
		locationID = H5_OpenFile(discLocation)
		electrode = ReadTextDataSetAsString(locationID, h5path)
		H5_CloseFile(locationID)
	elseif(version == NWB_VERSION_LATEST)
		link = H5_GetLinkTarget(discLocation, h5path)
		sprintf regExp, "%s/(.+)", NWB_INTRACELLULAR_EPHYS
		SplitString/E=regExp link, electrode
		ASSERT_TS(V_flag == 1, "ReadElectrodeName: invalid link target")
	endif

	sprintf regExp, "%s(.+)", NWB_ELECTRODE_PREFIX
	SplitString/E=regExp electrode, electrodeName
	ASSERT_TS(V_flag == 1, "ReadElectrodeName: invalid electrode name")

	return electrodeName
End

/// @brief List groups inside /general/labnotebook
///
/// @param  fileID identifier of open HDF5 file
/// @return        list with name of all groups inside /general/labnotebook/*
threadsafe Function/S ReadLabNoteBooks(fileID)
	variable fileID

	string result = ""

	if(H5_GroupExists(fileID, NWB_LABNOTEBOOK))
		result = H5_ListGroups(fileID, NWB_LABNOTEBOOK)
	endif

	return result
End

/// @brief List all acquisition channels.
///
/// @param  fileID  identifier of open HDF5 file
/// @param  version NWB major version
/// @return         comma separated list of channels
threadsafe Function/S ReadAcquisition(fileID, version)
	variable fileID, version

	string group

	EnsureValidNWBVersion(version)

	group = GetNWBgroupPatchClampSeries(version)

	return AddPrefixToEachListItem(group + "/", H5_ListGroups(fileID, group))
End

/// @brief List all stimulus channels.
///
/// @param  fileID identifier of open HDF5 file
/// @return        comma separated list of channels
threadsafe Function/S ReadStimulus(fileID)
	variable fileID

	return AddPrefixToEachListItem(NWB_STIMULUS_PRESENTATION + "/", H5_ListGroups(fileID, NWB_STIMULUS_PRESENTATION))
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

	return H5_ListGroupMembers(fileID, NWB_STIMULUS)
End

/// @brief Try to extract information from channel name string
///
/// @param[in]  channel  Input channel name in form data_00000_TTL1_3
/// @param[out] p        ReadChannelParams structure to get filled
threadsafe Function AnalyseChannelName(channel, p)
	string channel
	STRUCT ReadChannelParams &p

	string groupIndex, channelTypeStr, channelNumber, channelID

	channel = GetBaseName(channel, sep = "/")

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
/// Function is NWBv1 specific @see LoadSweepNumber
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

/// @brief Load sweep number from specified channel name
///
/// @param locationID   id of an open hdf5 group containing channel
/// @param channel      name of channel for which sweep number is loaded
/// @param version      NWB maior version
/// @return             sweep number
threadsafe Function LoadSweepNumber(locationID, channel, version)
	variable locationID
	string channel
	variable version

	STRUCT ReadChannelParams params

	EnsureValidNWBVersion(version)

	if(version == 1)
		LoadSourceAttribute(locationID, channel, params)
		return params.sweep
	elseif(version == NWB_VERSION_LATEST)
		return NaN
	endif
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
		path = "."
	endif

	path += "/" + channel
	Assert_TS(H5_GroupExists(locationID, path), "LoadDataWave: Path is not in nwb file")

	path += "/data"
	return H5_LoadDataset(locationID, path)
End

/// @brief Load single TimeSeries data as a wave from @c NWB_PATCHCLAMPSERIES_V[12]
///
/// @param locationID   id of an open hdf5 group or file
/// @param path         name or path of TimeSeries for which data is loaded
/// @param version      NWB major version
/// @return             reference to wave containing loaded data
threadsafe Function/Wave LoadTimeseries(locationID, path, version)
	variable locationID
	string path
	variable version

	EnsureValidNWBVersion(version)

	WAVE data = LoadDataWave(locationID, GetBaseName(path, sep = "/"), path = GetNWBgroupPatchClampSeries(version))

	return data
End

/// @brief Load single TimeSeries data as a wave from @c NWB_STIMULUS_PRESENTATION
///
/// @param locationID   id of an open hdf5 group or file
/// @param path         name or path of TimeSeries for which data is loaded
/// @return             reference to wave containing loaded data
threadsafe Function/Wave LoadStimulus(locationID, path)
	variable locationID
	string path

	WAVE data = LoadDataWave(locationID, GetBaseName(path, sep = "/"), path = NWB_STIMULUS_PRESENTATION)

	return data
End

/// @brief Open hdf5 group containing acquisition channels
///
/// @param fileID  id of an open hdf5 group or file
/// @param version NWB major version
///
/// @return id of hdf5 group
threadsafe Function OpenAcquisition(fileID, version)
	variable fileID
	variable version

	EnsureValidNWBVersion(version)

	return H5_OpenGroup(fileID, GetNWBgroupPatchClampSeries(version))
End

/// @brief Open hdf5 group containing stimulus channels
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
threadsafe Function OpenStimulus(fileID)
	variable fileID

	return H5_OpenGroup(fileID, NWB_STIMULUS_PRESENTATION)
End

/// @brief Open hdf5 group containing stimsets
///
/// @param fileID id of an open hdf5 group or file
///
/// @return id of hdf5 group
threadsafe Function OpenStimset(fileID)
	variable fileID

	ASSERT_TS(StimsetPathExists(fileID), "OpenStimset: Path is not in nwb file")

	return H5_OpenGroup(fileID, NWB_STIMULUS)
End

/// @brief Check if the path to the stimsets exist in the NWB file.
threadsafe Function StimsetPathExists(fileID)
	variable fileID

	return H5_GroupExists(fileID, NWB_STIMULUS)
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
	string neurodata_type, entry, list

	neurodata_type = ReadNeuroDataType(locationID, channel)
	clampMode = GetClampModeFromNeurodataType(neurodata_type)
	channelType = GetChannelTypeFromNeurodataType(neurodata_type)

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

/// @brief Read nwb data type
///
/// @see WriteNeuroDataType
///
/// @param fileID  HDF5 identifier of file (not group)
/// @param name    Path to element who's DataType is queried
///
/// @return string with data type (e.g. uint, DynamicTable, SweepTable)
threadsafe Function/S ReadNeuroDataType(fileID, name)
	variable fileID
	string name

	variable version0
	string ancestry
	string neurodata_type = ""

	version0 = GetNWBmajorVersion(ReadNWBVersion(fileID))
	EnsureValidNWBVersion(version0)

	if(version0 == 1)
		ancestry = ReadTextAttributeAsList(fileID, name, "ancestry")
		neurodata_type = StringFromList(ItemsInList(ancestry) - 1, ancestry)
	elseif(version0 == 2)
		neurodata_type = ReadTextAttributeAsString(fileID, name, "neurodata_type")
	endif

	return neurodata_type
End

/// @brief Return the two SweepTable data columns `sweep_number` and `series`
///
/// @todo Allow Executions for files with missing SweepTable entry using @ref
/// LoadSweepNumber
///
/// @param locationID  HDF5 identifier
/// @param version      major NWB version
///
/// @return sweep_number and path to TimeSeries as waves
Function [WAVE/Z sweep_number, WAVE/Z/T series] LoadSweepTable(variable locationID, variable version)

	string path
	variable groupID

	ASSERT_TS(version == 2, "SweepTable is only available for NWB version 2")
	sprintf path, "%s/%s", NWB_INTRACELLULAR_EPHYS, "sweep_table"

	if(IPNWB#H5_GroupExists(locationID, path, groupID = groupID))
		WAVE sweep_number = IPNWB#H5_LoadDataset(groupID, "sweep_number")
		WAVE/T series = IPNWB#H5_LoadDataset(groupID, "series")
		series[] = (series[p])[2,inf] // Remove leading group linker "G:"
		HDF5CloseGroup/Z groupID
		return [sweep_number, series]
	endif

	return [$"", $""]
End
