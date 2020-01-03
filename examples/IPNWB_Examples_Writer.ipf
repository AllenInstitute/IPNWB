#pragma TextEncoding = "UTF-8"
#include "IPNWB_include"

Function NWBWriterExample()

	variable fileID
	string contents, device

	// Open a dialog for selecting an HDF5 file name
	HDF5CreateFile fileID as ""

	// fill gi/ti/si with appropriate data for your lab and experiment
	// if you don't care about that info just pass the initialized structures
	STRUCT IPNWB#GeneralInfo gi
	STRUCT IPNWB#ToplevelInfo ti
	STRUCT IPNWB#SubjectInfo si

	// takes care of initializing
	IPNWB#InitToplevelInfo(ti)
	IPNWB#InitGeneralInfo(gi)
	IPNWB#InitSubjectInfo(si)

	IPNWB#CreateCommonGroups(fileID, toplevelInfo=ti, generalInfo=gi, subjectInfo=si)

	// If you open an existing NWB file to append to, use the following command
	// to add an modification time entry, is implicitly called in IPNWB#CreateCommonGroups
	// IPNWB#AddModificationTimeEntry(locationID)

	// 1D waves from your measurement program
	// we use fake data here
	Make/FREE/N=1000 AD = (sin(p) + cos(p/10)) * enoise(0.1)
	SetScale/P x, 0, 5e-6, "s"

	// write AD data to the file
	STRUCT IPNWB#WriteChannelParams params
	IPNWB#InitWriteChannelParams(params)

	params.device          = "My Hardware"
	params.clampMode       = 0 // 0 for V_CLAMP_MODE, 1 for I_CLAMP_MODE
	params.channelSuffix   = ""
	params.sweep           = 123
	params.electrodeNumber = 1
	params.electrodeName   = "Nose of the mouse"
	params.stimset         = "My fancy sine curve"
	params.channelType     = 0 // @see IPNWB_ChannelTypes
	WAVE params.data       = AD

	device = "My selfbuilt DAC"

	IPNWB#CreateIntraCellularEphys(fileID)
	sprintf contents, "Electrode %d", params.ElectrodeNumber
	IPNWB#AddElectrode(fileID, params.electrodeName, contents, device)

	// calculate the timepoint of the first wave point relative to the session_start_time
	// last time the wave was modified (UTC)
	params.startingTime  = NumberByKeY("MODTIME", WaveInfo(AD, 0)) - date2secs(-1, -1, -1)
	params.startingTime -= ti.session_start_time // relative to the start of the session
	// we want the timestamp of the beginning of the measurement
	params.startingTime -= IndexToScale(AD, DimSize(AD, 0) - 1, 0)

	IPNWB#AddDevice(fileID, "Device name", "My hardware specs")

	STRUCT IPNWB#TimeSeriesProperties tsp
	IPNWB#InitTimeSeriesProperties(tsp, params.channelType, params.clampMode)

	// all values not added are written into the missing_fields dataset
	IPNWB#AddProperty(tsp, "capacitance_fast", 1.0)
	IPNWB#AddProperty(tsp, "capacitance_slow", 1.0)

	// setting chunkedLayout to zero makes writing faster but increases the final filesize
	IPNWB#WriteSingleChannel(fileID, "/acquisition/timeseries", params, tsp)

	// write DA, stimulus presentation and stimulus template accordingly
	// ...

	// close file
	IPNWB#H5_CloseFile(fileID)
End
