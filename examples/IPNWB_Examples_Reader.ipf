#pragma TextEncoding = "UTF-8"
#include "IPNWB_include"

Function NWBReaderExample()

	variable fileID, groupID, integrityCheck, numChannels, i
	string contents, device, listOfDevices, elem, list
	STRUCT IPNWB#ReadChannelParams p
	STRUCT IPNWB#TimeSeriesProperties tsp

	// Open a dialog for selecting an HDF5 file name
	fileID = IPNWB#H5_OpenFile("c:\\NWB-Sample-20160216.nwb")

	listOfDevices = IPNWB#ReadDevices(fileID)

	integrityCheck = IPNWB#CheckIntegrity(fileID)

	printf "NWB integrity check: %s\r", SelectString(integrityCheck,"failed", "passed")
	printf "List of devices: %s\r", listOfDevices

	list    = IPNWB#ReadAcquisition(fileID)
	groupID = IPNWB#OpenAcquisition(fileID)

	numChannels = ItemsInList(list)

	printf "\rLoading acquired data (%d)\r", numChannels

	for(i = 0; i < numChannels; i += 1)
		elem = StringFromList(i, list)

		IPNWB#LoadSourceAttribute(groupID, elem, p)

		WAVE wv = IPNWB#LoadDataWave(groupID, elem)
		Duplicate/O wv, $elem

		IPNWB#ReadTimeSeriesProperties(groupID, elem, tsp)
		print tsp
	endfor

	HDF5CloseGroup groupID

	list    = IPNWB#ReadStimulus(fileID)
	groupID = IPNWB#OpenStimulus(fileID)

	numChannels = ItemsInList(list)

	printf "\rLoading presentation data (%d)\r", numChannels

	for(i = 0; i < numChannels; i += 1)
		elem = StringFromList(i, list)

		IPNWB#LoadSourceAttribute(groupID, elem, p)

		WAVE wv = IPNWB#LoadDataWave(groupID, elem)
		Duplicate/O wv, $elem

		IPNWB#ReadTimeSeriesProperties(groupID, elem, tsp)
		print tsp
	endfor

	HDF5CloseGroup groupID

	STRUCT IPNWB#ToplevelInfo toplevelInfo
	IPNWB#ReadTopLevelInfo(fileID, toplevelInfo)
	print toplevelInfo
	print toplevelInfo.file_create_date

	STRUCT IPNWB#GeneralInfo generalInfo
	IPNWB#ReadGeneralInfo(fileID, generalInfo)
	print generalInfo

	STRUCT IPNWB#SubjectInfo subjectInfo
	IPNWB#ReadSubjectInfo(fileID, subjectInfo)
	print subjectInfo

	// close file
	HDF5CloseFile fileID
End
