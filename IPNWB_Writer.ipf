#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.18

// This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

/// @file IPNWB_Writer.ipf
/// @brief Generic functions related to export into the NeuroDataWithoutBorders format

/// @brief Create and fill common HDF5 groups and datasets
/// @param locationID                                               HDF5 identifier
/// @param toplevelInfo [optional, see ToplevelInfo() for defaults] datasets directly below `/`
/// @param generalInfo [optional, see GeneralInfo() for defaults]   datasets directly below `/general`
/// @param subjectInfo [optional, see SubjectInfo() for defaults]   datasets below `/general/subject`
threadsafe Function CreateCommonGroups(locationID, [toplevelInfo, generalInfo, subjectInfo])
	variable locationID
	STRUCT ToplevelInfo &toplevelInfo
	STRUCT GeneralInfo &generalInfo
	STRUCT SubjectInfo &subjectInfo

	variable groupID, version
	string session_start_time_ts

	STRUCT GeneralInfo gi
	STRUCT SubjectInfo si
	STRUCT TopLevelInfo ti

	if(ParamIsDefault(generalInfo))
		InitGeneralInfo(gi)
	else
		gi = generalInfo
	endif

	if(ParamIsDefault(subjectInfo))
		InitSubjectInfo(si)
	else
		si = subjectInfo
	endif

	if(ParamIsDefault(toplevelInfo))
		InitToplevelInfo(ti, GetNWBVersion())
	else
		ti = toplevelInfo
	endif

	version = GetNWBmajorVersion(ti.nwb_version)
	EnsureValidNWBVersion(version)
	if(version == 1)
		H5_WriteTextDataset(locationID, "nwb_version", str=ti.nwb_version)
	elseif(version == NWB_VERSION_LATEST)
		H5_WriteTextAttribute(locationID, "nwb_version", NWB_ROOT, str=ti.nwb_version)
		WriteBasicAttributes(locationID, NWB_ROOT, "core", "NWBFile")
	endif

	session_start_time_ts = GetISO8601TimeStamp(secondsSinceIgorEpoch=ti.session_start_time, numFracSecondsDigits = 3)

	H5_WriteTextDataset(locationID, "identifier", str=ti.identifier)
	// file_create_date needs to be appendable for the modified timestamps, and that is equivalent to having chunked layout
	H5_WriteTextDataset(locationID, "file_create_date", wvText=ti.file_create_date, compressionMode=CHUNKED_COMPRESSION)
	H5_WriteTextDataset(locationID, "session_start_time", str=session_start_time_ts)
	H5_WriteTextDataset(locationID, "session_description", str=ti.session_description)
	H5_WriteTextDataset(locationID, "timestamps_reference_time", str=session_start_time_ts)

	H5_CreateGroupsRecursively(locationID, NWB_GENERAL, groupID=groupID)

	WriteTextDatasetIfSet(groupID, "session_id"            , gi.session_id)
	WriteTextDatasetIfSet(groupID, "experimenter"          , gi.experimenter)
	WriteTextDatasetIfSet(groupID, "institution"           , gi.institution)
	WriteTextDatasetIfSet(groupID, "lab"                   , gi.lab)
	WriteTextDatasetIfSet(groupID, "related_publications"  , gi.related_publications)
	WriteTextDatasetIfSet(groupID, "notes"                 , gi.notes)
	WriteTextDatasetIfSet(groupID, "experiment_description", gi.experiment_description)
	WriteTextDatasetIfSet(groupID, "data_collection"       , gi.data_collection)
	WriteTextDatasetIfSet(groupID, "stimulus"              , gi.stimulus)
	WriteTextDatasetIfSet(groupID, "pharmacology"          , gi.pharmacology)
	WriteTextDatasetIfSet(groupID, "surgery"               , gi.surgery)
	WriteTextDatasetIfSet(groupID, "protocol"              , gi.protocol)
	WriteTextDatasetIfSet(groupID, "virus"                 , gi.virus)
	WriteTextDatasetIfSet(groupID, "slices"                , gi.slices)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, NWB_SUBJECT, groupID=groupID)
	if(version == NWB_VERSION_LATEST)
		WriteBasicAttributes(locationID, NWB_SUBJECT, "core", "Subject")
	endif

	WriteTextDatasetIfSet(groupID, "subject_id" , si.subject_id)
	WriteTextDatasetIfSet(groupID, "description", si.description)
	WriteTextDatasetIfSet(groupID, "species"    , si.species)
	WriteTextDatasetIfSet(groupID, "genotype"   , si.genotype)
	WriteTextDatasetIfSet(groupID, "sex"        , si.sex)
	WriteTextDatasetIfSet(groupID, "age"        , si.age)
	WriteTextDatasetIfSet(groupID, "weight"     , si.weight)

	HDF5CloseGroup/Z groupID

	H5_CreateGroupsRecursively(locationID, NWB_DEVICES)
	H5_CreateGroupsRecursively(locationID, NWB_STIMULUS_TEMPLATES)
	H5_CreateGroupsRecursively(locationID, NWB_STIMULUS_PRESENTATION)
	H5_CreateGroupsRecursively(locationID, GetNWBgroupPatchClampSeries(version))
	H5_CreateGroupsRecursively(locationID, NWB_EPOCHS)
	H5_WriteTextAttribute(locationID, "tags", NWB_EPOCHS, list="")
	H5_CreateGroupsRecursively(locationID, NWB_PROCESSING)
	H5_CreateGroupsRecursively(locationID, NWB_ANALYSIS)

	H5_CreateGroupsRecursively(locationID, NWB_STIMULUS)

	AddModificationTimeEntry(locationID, version)
End

/// @brief Create the HDF5 group for intracellular ephys
///
/// @param locationID                                    HDF5 identifier
/// @param filtering [optional, defaults to PLACEHOLDER] filtering information
threadsafe Function CreateIntraCellularEphys(locationID, [filtering])
	variable locationID
	string filtering

	variable groupID

	if(ParamIsDefault(filtering))
		filtering = PLACEHOLDER
	endif

	H5_CreateGroupsRecursively(locationID, NWB_INTRACELLULAR_EPHYS, groupID=groupID)
	H5_WriteTextDataset(groupID, "filtering" , str=filtering, overwrite=1)
	HDF5CloseGroup groupID
End

/// @brief Add an entry for the device @p name in the nwb file specified by @p locationID
///
/// @param locationID   HDF5 identifier
/// @param name         name of device to create
/// @param version      major NWB version
/// @param description  a string describing the created device
/// @returns 1 if a new device was created and 0 if it already existed
threadsafe Function AddDevice(locationID, name, version, description)
	variable locationID
	string name, description
	variable version

	variable groupID
	string path

	EnsureValidNWBVersion(version)

	sprintf path, "%s/device_%s", NWB_DEVICES, name

	if(version == 1)
		H5_CreateGroupsRecursively(locationID, NWB_DEVICES, groupID=groupID)
		H5_WriteTextDataset(groupID, path, str=description, skipIfExists=1)
	elseif(version == NWB_VERSION_LATEST)
		H5_CreateGroupsRecursively(locationID, path, groupID=groupID)
		WriteBasicAttributes(groupID, path, "core", "Device")
		H5_WriteTextAttribute(groupID, "description", path, str = description)
	endif

	HDF5CloseGroup/Z groupID
End

/// @brief Add an entry for the electrode `name` with contents `data`
threadsafe Function AddElectrode(locationID, name, version, data, device)
	variable locationID, version
	string name, data, device

	string path
	variable groupID

	EnsureValidNWBVersion(version)
	ASSERT_TS(H5_IsValidIdentifier(name), "AddElectrode: The electrode name must be a valid HDF5 identifier")

	sprintf path, "%s/%s%s", NWB_INTRACELLULAR_EPHYS, NWB_ELECTRODE_PREFIX, name
	if(H5_GroupExists(locationID, path))
		return NaN
	endif

	H5_CreateGroupsRecursively(locationID, path, groupID=groupID)

	if(version == NWB_VERSION_LATEST)
		WriteBasicAttributes(groupID, path, "core", "IntracellularElectrode")
	endif

	H5_WriteTextDataset(groupID, "description", str=data)

	if(version == 1)
		H5_WriteTextDataset(groupID, "device", str=device)
	elseif(version == NWB_VERSION_LATEST)
		sprintf path, "%s/device_%s", NWB_DEVICES, device
		H5_CreateSoftLink(groupID, "device", path)
	endif

	HDF5CloseGroup groupID
End

/// @brief Add a modification timestamp to the NWB file
threadsafe Function AddModificationTimeEntry(locationID, version)
	variable locationID, version

	EnsureValidNWBVersion(version)

	Make/FREE/T/N=1 data = GetISO8601TimeStamp(localTimeZone = version > 1)
	HDF5SaveData/Q/IGOR=0/APND=(ROWS)/Z data, locationID, "/file_create_date"

	if(V_flag)
		HDF5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT_TS(0, "AddModificationTimeEntry: Could not append to the HDF5 dataset")
	endif
End

/// @brief Mark a dataset/group as custom
///
/// According to the NWB spec everything not required should be specifically
/// marked. In NWBv2, schema extensions can be used to accomplish this.
///
/// @param locationID HDF5 identifier
/// @param name       dataset or group name
threadsafe Function MarkAsCustomEntry(locationID, name)
	variable locationID
	string name

	WriteNeuroDataType(locationID, name, "Custom")
End

/// @brief Add unit and resolution to TimeSeries dataset
///
/// @param locationID                                            HDF5 identifier
/// @param fullAbsPath                                           absolute path to the TimeSeries dataset
/// @param unitWithPrefix                                        unit with optional prefix of the data in the TimeSeries, @see ParseUnit
/// @param resolution [optional, defaults to `NaN` for unknown]  experimental resolution
/// @param overwrite [optional, defaults to false] 				 should existing attributes be overwritten
threadsafe Function AddTimeSeriesUnitAndRes(locationID, fullAbsPath, unitWithPrefix, [resolution, overwrite])
	variable locationID
	string fullAbsPath, unitWithPrefix
	variable resolution, overwrite

	string prefix, unit
	variable numPrefix

	if(ParamIsDefault(resolution))
		resolution = NaN
	endif

	overwrite = ParamIsDefault(overwrite) ? 0 : !!overwrite

	if(isEmpty(unitWithPrefix))
		numPrefix = 1
		unit      = "a.u."
	else
		ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	endif

	H5_WriteTextAttribute(locationID, "unit"      , fullAbsPath, str=unit)
	H5_WriteAttribute(locationID    , "conversion", fullAbsPath, numPrefix, IGOR_TYPE_32BIT_FLOAT)
	H5_WriteAttribute(locationID    , "resolution", fullAbsPath, resolution, IGOR_TYPE_32BIT_FLOAT)
End

/// @brief Add a TimeSeries property to the @p tsp structure
threadsafe Function AddProperty(tsp, nwbProp, value, [unit])
	STRUCT TimeSeriesProperties &tsp
	string nwbProp
	variable value
	string unit

	ASSERT_TS(FindListItem(nwbProp, tsp.missing_fields) != -1, "AddProperty: incorrect missing_fields")
	tsp.missing_fields = RemoveFromList(nwbProp, tsp.missing_fields)

	WAVE/T propNames = tsp.names
	WAVE propData    = tsp.data
	WAVE/T propUnit  = tsp.unit

	FindValue/TEXT=""/TXOP=(4) propNames
	ASSERT_TS(V_Value != -1, "AddProperty: Could not find space for new entry")
	ASSERT_TS(!IsFinite(propData[V_Value]), "AddProperty: data row already filled")

	propNames[V_value] = nwbProp
	propData[V_value]  = value
	if(!ParamIsDefault(unit))
		propUnit[V_value] = unit
	endif
End

/// @brief Add a custom TimeSeries property to the `names` and `data` waves
///
/// @see MarkAsCustomEntry
threadsafe Function AddCustomProperty(tsp, nwbProp, value)
	STRUCT TimeSeriesProperties &tsp
	string nwbProp
	variable value

	WAVE/T propNames = tsp.names
	WAVE propData    = tsp.data
	WAVE isCustom    = tsp.isCustom

	FindValue/TEXT=""/TXOP=(4) propNames
	ASSERT_TS(V_Value != -1, "AddCustomProperty: Could not find space for new entry")
	ASSERT_TS(!IsFinite(propData[V_Value]), "AddCustomProperty: data row already filled")

	propNames[V_value] = nwbProp
	propData[V_value]  = value
	isCustom[V_value]  = 1
End

/// @brief Return the next free group index of the format `data_$NUM`
threadsafe Function GetNextFreeGroupIndex(locationID, path)
	variable locationID
	string path

	string str, list
	variable idx

	if(!H5_GroupExists(locationID, path))
		return 0
	endif

	HDF5ListGroup/TYPE=(2^0) locationID, path
	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT_TS(0, "GetNextFreeGroupIndex: Could not get list of objects at path:" + path)
	endif

	list = S_HDF5ListGroup

	if(IsEmpty(list))
		return 0
	endif

	list = SortList(list, ";", 16)

	str = StringFromList(ItemsInList(list) - 1, list)
	sscanf str, "data_%d.*", idx
	ASSERT_TS(V_Flag == 1, "GetNextFreeGroupIndex: Could not find running data index")

	return idx + 1
End

/// @brief Write the data of a single channel to the NWB file
///
/// @param locationID      HDF5 file identifier
/// @param path            Absolute path in the HDF5 file where the data should
///                        be stored
/// @param version         major NWB version
/// @param p               Filled #IPNWB::WriteChannelParams structure
/// @param tsp             Filled #IPNWB::TimeSeriesProperties structure
/// @param compressionMode [optional, defaults to NO_COMPRESSION] Type of
///                        compression to use, one of @ref CompressionMode
threadsafe Function WriteSingleChannel(locationID, path, version, p, tsp, [compressionMode])
	variable locationID
	string path
	variable version
	STRUCT WriteChannelParams &p
	STRUCT TimeSeriesProperties &tsp
	variable compressionMode

	variable groupID, numPlaces, numEntries, i
	string neurodata_type, source, helpText, channelTypeStr, electrodeName, group

	if(ParamIsDefault(compressionMode))
		compressionMode = NO_COMPRESSION
	endif

	EnsureValidNWBVersion(version)

	if(p.channelType == CHANNEL_TYPE_OTHER)
		channelTypeStr = "stimset"
		sprintf group, "%s/%s", path, p.stimSet
	else
		if(!IsFinite(p.groupIndex))
			HDF5ListGroup/F/TYPE=(2^0) locationID, path
			p.groupIndex = ItemsInList(S_HDF5ListGroup)
		endif

		channelTypeStr = StringFromList(p.channelType, CHANNEL_NAMES)
		ASSERT_TS(!IsEmpty(channelTypeStr), "WriteSingleChannel: invalid channel type string")
		ASSERT_TS(IsFinite(p.channelNumber), "WriteSingleChannel: invalid channel number")

		numPlaces = max(5, ceil(log(p.groupIndex)))
		sprintf group, "%s/data_%0*d_%s%d", path, numPlaces, p.groupIndex, channelTypeStr, p.channelNumber
		if(strlen(p.channelSuffix) > 0)
			group += "_" + p.channelSuffix
		endif
	endif

	// skip writing DA data with I=0 clamp mode (it will just be constant zero)
	if(p.channelType == CHANNEL_TYPE_DAC && p.clampMode == I_EQUAL_ZERO_MODE)
		return NaN
	endif

	H5_CreateGroupsRecursively(locationID, group, groupID=groupID)
	H5_WriteTextAttribute(groupID, "description", group, str=PLACEHOLDER, overwrite=1)

	// write source attribute
	if(version == 1)
		if(isFinite(p.channelNumber))
			sprintf channelTypeStr, "%s=%d", channelTypeStr, p.channelNumber
		endif

		sprintf source, "Device=%s;Sweep=%d;%s;ElectrodeNumber=%s;ElectrodeName=%s", p.device, p.sweep, channelTypeStr, num2str(p.electrodeNumber), p.electrodeName

		if(strlen(p.channelSuffixDesc) > 0 && strlen(p.channelSuffix) > 0)
			ASSERT_TS(strsearch(p.channelSuffix, "=", 0) == -1, "WriteSingleChannel: channelSuffix must not contain an equals (=) symbol")
			ASSERT_TS(strsearch(p.channelSuffixDesc, "=", 0) == -1, "WriteSingleChannel: channelSuffixDesc must not contain an equals (=) symbol")
			source += ";" + p.channelSuffixDesc + "=" + p.channelSuffix
		endif
		H5_WriteTextAttribute(groupID, "source", group, str=source, overwrite=1)
	elseif(version == NWB_VERSION_LATEST)
		H5_WriteAttribute(groupID, "sweep_number", group, p.sweep, IGOR_TYPE_32BIT_INT | IGOR_TYPE_UNSIGNED, overwrite=1)
		AppendToSweepTable(locationID, group, p.sweep)
	endif

	// write human readable version of description
	if(p.channelType != CHANNEL_TYPE_OTHER)
		if(version == 1)
			H5_WriteTextAttribute(groupID, "comment", group, str=note(p.data), overwrite=1)
		elseif(version == NWB_VERSION_LATEST)
			H5_WriteTextAttribute(groupID, "comments", group, str=note(p.data), overwrite=1)
		endif
	endif

	// only write electrode_name for associated channels
	if(IsFinite(p.electrodeNumber) && (p.channelType == CHANNEL_TYPE_DAC || p.channelType == CHANNEL_TYPE_ADC))
		sprintf electrodeName, "electrode_%s", p.electrodeName
		if(version == 1)
			H5_WriteTextDataset(groupID, "electrode_name", str=(electrodeName), overwrite=1)
		elseif(version == NWB_VERSION_LATEST)
			sprintf path, "%s/%s", NWB_INTRACELLULAR_EPHYS, electrodeName
			H5_CreateSoftLink(groupID, "electrode", path)
		endif
	endif

	neurodata_type = DetermineDataTypeFromProperties(p.channelType, p.clampMode)
	WriteNeuroDataType(groupID, group, neurodata_type)

	numEntries = DimSize(tsp.names, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!cmpstr(tsp.names[i], ""))
			break
		endif

		H5_WriteDataset(groupID, tsp.names[i], var=tsp.data[i], varType=IGOR_TYPE_32BIT_FLOAT, overwrite=1)

		if(version == 1 && tsp.isCustom[i])
			MarkAsCustomEntry(groupID, tsp.names[i])
		endif

		if(version == 2 && cmpstr(tsp.unit[i], ""))
			H5_WriteTextAttribute(groupID, "unit", group + "/" + tsp.names[i], str=tsp.unit[i], overwrite=1)
		endif
	endfor
	if(version == 1 && cmpstr(tsp.missing_fields, ""))
		H5_WriteTextAttribute(groupID, "missing_fields", group, list=tsp.missing_fields, overwrite=1)
	endif

	H5_WriteDataset(groupID, "data", wv=p.data, compressionMode=compressionMode, overwrite=1, writeIgorAttr=1)

	// TimeSeries: datasets and attributes
	// no timestamps, control, control_description and sync
	AddTimeSeriesUnitAndRes(groupID, group + "/data", WaveUnits(p.data, -1), overwrite=1)
	if(version == 1)
		H5_WriteDataset(groupID, "num_samples", var=DimSize(p.data, ROWS), varType=IGOR_TYPE_32BIT_INT, overwrite=1)
	endif

	if(p.channelType != CHANNEL_TYPE_OTHER)
		H5_WriteDataset(groupID, "starting_time", var=p.startingTime, varType=IGOR_TYPE_64BIT_FLOAT, overwrite=1)
		H5_WriteAttribute(groupID, "rate", group + "/starting_time", p.samplingRate, IGOR_TYPE_32BIT_FLOAT, overwrite=1)
		H5_WriteTextAttribute(groupID, "unit", group + "/starting_time", str="Seconds", overwrite=1)
	endif

	if(version == 1)
		H5_WriteTextDataset(groupID, "stimulus_description", str=p.stimSet, overwrite=1)
		MarkAsCustomEntry(groupID, "stimulus_description")
	elseif(version == NWB_VERSION_LATEST)
		// mandatory attribute for PatchClampSeries
		H5_WriteTextAttribute(groupID, "stimulus_description", group, str=p.stimSet, overwrite=1)
	endif

	HDF5CloseGroup groupID
End

/// @brief Create a Dynamic Table group at path
/// Note: A dynamic table needs at least an @c id and a @c vectorData column
threadsafe static Function CreateDynamicTable(locationID, path, dt, [groupID])
	variable locationID
	string path
	STRUCT DynamicTable &dt
	variable &groupID

	variable id

	if(H5_GroupExists(locationID, path, groupID = id))
		if(ParamIsDefault(groupID))
			HDF5CloseGroup id
		else
			groupID = id
		endif
		return NaN
	endif

	H5_CreateGroupsRecursively(locationID, path, groupID = id)
	WriteBasicAttributes(id, path, dt.namespace, dt.neurodata_type)
	H5_WriteTextAttribute(id, "description", path, str = dt.description)
	H5_WriteTextAttribute(id, "colnames", path, list = dt.colnames)

	if(ParamIsDefault(groupID))
		HDF5CloseGroup id
	else
		groupID = id
	endif
End

/// @brief write the standard NWBv2 attributes to a group
threadsafe static Function WriteBasicAttributes(groupID, path, namespace, neurodata_type)
	variable groupID
	string path, namespace, neurodata_type

	H5_WriteTextAttribute(groupID, "namespace", path, str = namespace)
	WriteNeuroDataType(groupID, path, neurodata_type)
End

/// @brief Append a sweep to the sweep table
///
/// Note: NWBv2 specific function
///
/// @param locationID   HDF5 identifier
/// @param reference    path to dataset where sweep is stored
/// @param sweepNumber  sweep number
threadsafe static Function AppendToSweepTable(locationID, reference, sweepNumber)
	variable locationID
	string reference
	variable sweepNumber

	variable groupID, test, err, numIds
	variable appendMode = ROWS, compressionMode = NO_COMPRESSION
	string path

	sprintf path, "%s/sweep_table", NWB_INTRACELLULAR_EPHYS
	if(!H5_GroupExists(locationID, path, groupID = groupID))
		STRUCT DynamicTable dt
		InitDynamicTable(dt)
		dt.description = "The table which groups different PatchClampSeries together."
		dt.colnames = "series;sweep_number"
		dt.description = "A sweep table groups different PatchClampSeries together."
		dt.neurodata_type = "SweepTable"
		CreateDynamicTable(locationID, path, dt, groupID = groupID)
		appendMode = -1
		compressionMode = CHUNKED_COMPRESSION
	endif
	test = H5_GroupExists(groupID, ".")

	WAVE/Z ids = H5_LoadDataset(groupID, "id")
	numIds = WaveExists(ids) ? DimSize(ids, ROWS) : 0
	H5_WriteDataset(groupID, "id", var = numIds, varType = IGOR_TYPE_32BIT_INT, compressionMode = compressionMode, appendData = appendMode)
	H5_WriteTextDataset(groupID, "series", overwrite = 1, str = "G:" + reference, refMode = OBJECT_REFERENCE, compressionMode = compressionMode, appendData = appendMode)
	H5_WriteDataset(groupID, "series_index", var = (numIds + 1), varType = IGOR_TYPE_32BIT_INT, compressionMode = compressionMode, appendData = appendMode)
	H5_WriteDataset(groupID, "sweep_number", var = sweepNumber, varType = IGOR_TYPE_32BIT_INT | IGOR_TYPE_UNSIGNED, compressionMode = compressionMode, appendData = appendMode)

	if(appendMode == ROWS)
		HDF5CloseGroup groupID
		return Nan
	endif

	STRUCT ElementIdentifiers id
	InitElementIdentifiers(id)
	WriteBasicAttributes(groupID, "id", id.namespace, id.neurodata_type)

	STRUCT VectorData series
	InitVectorData(series)
	series.description = "The PatchClampSeries with the sweep number in that row."
	series.path = path + "/series"
	WriteBasicAttributes(groupID, "series", series.namespace, series.neurodata_type)
	H5_WriteTextAttribute(groupID, "description", "series", str = series.description)

	STRUCT VectorIndex series_index
	InitVectorIndex(series_index)
	series_index.target = series
	WriteBasicAttributes(groupID, "series_index", series_index.namespace, series_index.neurodata_type)
	H5_WriteTextAttribute(groupID, "target", "series_index", str = "D:" + series_index.target.path, refMode = OBJECT_REFERENCE)

	STRUCT VectorData sweep_number
	InitVectorData(sweep_number)
	sweep_number.description = "Sweep number of the PatchClampSeries in that row."
	WriteBasicAttributes(groupID, "sweep_number", sweep_number.namespace, sweep_number.neurodata_type)
	H5_WriteTextAttribute(groupID, "description", "sweep_number", str = sweep_number.description)

	HDF5CloseGroup groupID
End

/// @brief write NWB:N specifications that were used for creating this file
///
/// Note: non threadsafe due to limitations in @c LoadSpecification
///
/// @param locationID   open HDF5 file identifier
Function WriteSpecifications(locationID)
	variable locationID

	variable groupID, i, numSpecs
	string path, specName, specDefinition

	sprintf path, "%s/core/%s", NWB_SPECIFICATIONS, NWB_CORE_VERSION
	H5_CreateGroupsRecursively(locationID, path, groupID=groupID)
	H5_WriteTextDataset(groupID, "namespace", str=LoadSpecification(NWB_SPEC_NAMESPACE))
	numSpecs = ItemsInList(NWB_SPEC_NAMES)
	for(i = 0; i < numSpecs; i += 1)
		specName = StringFromList(i, NWB_SPEC_NAMES)
		specDefinition = LoadSpecification(specName)
		H5_WriteTextDataset(groupID, specName, str=specDefinition)
	endfor
	HDF5CloseGroup groupID

	sprintf path, "%s/hdmf-common/%s", NWB_SPECIFICATIONS, HDMF_CORE_VERSION
	H5_CreateGroupsRecursively(locationID, path, groupID=groupID)
	H5_WriteTextDataset(groupID, "namespace", str=LoadSpecification(HDMF_SPEC_NAMESPACE))
	numSpecs = ItemsInList(HDMF_SPEC_NAMES)
	for(i = 0; i < numSpecs; i += 1)
		specName = StringFromList(i, HDMF_SPEC_NAMES)
		specDefinition = LoadSpecification(specName)
		H5_WriteTextDataset(groupID, specName, str=specDefinition)
	endfor
	HDF5CloseGroup groupID

	sprintf path, "G:%s", NWB_SPECIFICATIONS
	H5_WriteTextAttribute(locationID, ".specloc", NWB_ROOT, str=path, refMode = OBJECT_REFERENCE)
End

/// @brief Write a NeuroDataType
///
/// @see ReadNeuroDataType
///
/// @param locationID     HDF5 identifier
/// @param path           Path to element who's DataType is queried
/// @param neurodata_type String version of the data type that should get
///                       written
threadsafe static Function WriteNeuroDataType(locationID, path, neurodata_type)
	variable locationID
	string path, neurodata_type

	variable version0, version1, version2
	string version, ancestry

	version0 = GetNWBmajorVersion(ReadNWBVersion(locationID))
	EnsureValidNWBVersion(version0)

	if(version0 == 1)
		ancestry = DetermineDataTypeRefTree(neurodata_type)
		// neurodata_type defaults to super class in NWBv1
		neurodata_type = StringFromList(0, ancestry)
		H5_WriteTextAttribute(locationID, "ancestry", path, list=ancestry, overwrite=1)
		H5_WriteTextAttribute(locationID, "neurodata_type", path, str=neurodata_type, overwrite=1)
		// no data_link and timestamp_link attribute as we keep all data in one file
	elseif(version0 == 2)
		/// @todo check if namespace "core" applies for every neurodata_type like @c SweepTable
		H5_WriteTextAttribute(locationID, "namespace", path, str = "core", overwrite = 1)
		H5_WriteTextAttribute(locationID, "neurodata_type", path, str = neurodata_type, overwrite = 1)
	endif
End

/// @brief Determine the ancestry tree for the specified neurodata type definition
///
/// @param ancestry A list of all previously ancester dataTypes
/// @return a specified neurodata type definition string json
threadsafe Function/S DetermineDataTypeRefTree(ancestry)
	string ancestry

	string neurodata_type = StringFromList(0, ancestry)

	strswitch(neurodata_type)
		case "VoltageClampSeries":
		case "VoltageClampStimulusSeries":
		case "CurrentClampSeries":
		case "CurrentClampStimulusSeries":
			return DetermineDataTypeRefTree(AddListItem("PatchClampSeries", ancestry))
		case "IZeroClampSeries":
			return DetermineDataTypeRefTree(AddListItem("CurrentClampSeries", ancestry))
		case "PatchClampSeries":
			return AddListItem("TimeSeries", ancestry)
		case "VectorIndex":
			return AddListItem("index", ancestry)
		case "SweepTable":
			return AddListItem("DynamicTable", ancestry)
		case "TimeSeries":
		default:
			return ancestry
	endswitch
End
