def get_trace_CC1(t_start, t_final):
    from obspy.clients.fdsn import Client
    from obspy.core.utcdatetime import UTCDateTime
    import numpy as np
    import scipy.io as sio

    client = Client("IRIS")

    t_start = UTCDateTime(t_start)
    t_final = UTCDateTime(t_final)

    # Build bulk request list: [(network, station, location, channel, t_start, t_final), ...]
    staList = [
        ('OO','AXCC1','','HH?'), ('OO','AXCC1','','BDO'),
        #('OO','AXEC1','','EH?'), ('OO','AXEC2','','HH?'), #('OO','AXEC2','','HDH'),
        #('OO','AXEC3','','EH?'), ('OO','AXAS1','','EH?'),
        #('OO','AXAS2','','EH?'), ('OO','AXID1','','EH?'),
        #('OO','AXBA1','','HH?'), ('OO','AXBA1','','HDH'),
    ]
    bulk = [(net, sta, loc, ch, t_start, t_final) for net, sta, loc, ch in staList]

    try:
        # ONE request for all channels
        stream = client.get_waveforms_bulk(bulk, attach_response=True)
    except Exception as e:
        print('Bulk request failed:', e)
        return {}

    stations=[]; sampleRate=[]; sampleCount=[]; locations=[]
    channels=[]; stime=[]; etime=[]; data=[]; networks=[]
    sensitivityFrequency=[]; sensitivity=[]

    for trace in stream:
        resp = trace.stats.response._get_overall_sensitivity_and_gain()
        stations.append(trace.stats.station)
        sampleRate.append(trace.stats.sampling_rate)
        sampleCount.append(trace.stats.npts)
        locations.append(trace.stats.location)
        channels.append(trace.stats.channel)
        stime.append(trace.stats.starttime.strftime("%Y-%m-%d:%H:%M:%S.%f"))
        etime.append(trace.stats.endtime.strftime("%Y-%m-%d:%H:%M:%S.%f"))
        data.append(trace.data)
        networks.append(trace.stats.network)
        sensitivityFrequency.append(resp[0])
        sensitivity.append(resp[1])
        print('Found:', trace.stats.station, trace.stats.channel)

    trace_dict = {
        'network': networks, 'station': stations, 'location': locations,
        'channel': channels, 'sensitivity': sensitivity,
        'sensitivityFrequency': sensitivityFrequency, 'data': data,
        'sampleCount': sampleCount, 'sampleRate': sampleRate,
        'startTime': stime, 'endTime': etime
    }
    sio.savemat('py_trace.mat', {'trace': trace_dict})
    return trace_dict