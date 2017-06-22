classdef DataRecorderInterface
    %DataRecorderInterface is a layer one MATLAB wrapper for the ModuleConnector
    % DataRecorder interface.
    %
    % Example
    %   Lib = ModuleConnector.Library
    %   
    %   mc = ModuleConector.ModuleConnector(COMPORT);
    %   
    
    properties
        lib_name 	% Used to identify the C/C++ library
    end
    
    properties (Constant)
        % Recording data types
        DataType_BasebandApDataType = uint32(2^0); % = 1 << 0
        DataType_BasebandIqDataType = uint32(2^1); % = 1 << 1,
        DataType_SleepDataType = uint32(2^2); % = 1 << 2,
        DataType_RespirationDataType = uint32(2^3); % = 1 << 3,
        DataType_PerformanceStatusType = uint32(2^4); % = 1 << 4,
        DataType_StringDataType = uint32(2^5); % = 1 << 5,
        DataType_PulseDopplerFloatDataType = uint32(2^6); % = 1 << 6,
        DataType_PulseDopplerByteDataType = uint32(2^7); % = 1 << 7,
        DataType_NoiseMapFloatDataType = uint32(2^8); % = 1 << 8,
        DataType_NoiseMapByteDataType = uint32(2^9); % = 1 << 9,
        DataType_FloatDataType = uint32(2^10); % = 1 << 10,
        DataType_ByteDataType = uint32(2^11); % = 1 << 11,
        DataType_PresenceSingleDataType = uint32(2^12); % = 1 << 12,
        DataType_PresenceMovingListDataType = uint32(2^13); % = 1 << 13,
        
        DataType_InvalidDataType = uint32(0);
        DataType_AllDataTypes = uint32(2^32); % = 0xffffffff,
    end
    
    properties (Constant)
                
    end
    
    methods
        %% Constructor        
        function dri = DataRecorderInterface(lib_name)
            dri.lib_name = lib_name;
        end
        
        %%===================================================================================
        %   DataRecorder interface API 
        %===================================================================================
        
        function recordingOptions_instance = create_recording_options(this)
            recordingOptions_instance = calllib(this.lib_name,'nva_create_recording_options');
            assert(~recordingOptions_instance.isNull, 'nva_create_recording_options failed, check the logs');
        end
        
        function recordingSplitSize_instance = create_recording_split_size(this)
            recordingSplitSize_instance = calllib(this.lib_name,'nva_create_recording_split_size');
            assert(~recordingSplitSize_instance.isNull, 'nva_create_recording_split_size failed, check the logs');
        end
        %
        %% Recording split size.
        function set_duration(this, recordingSplitSize_instance, duration)
            calllib(this.lib_name, 'set_duration', recordingSplitSize_instance, int32(duration));
        end
        %
        function set_byte_count(this, recordingSplitSize_instance, count)
            calllib(this.lib_name, 'set_byte_count', recordingSplitSize_instance, int64(count));
        end
        %
        function set_fixed_daily_hour(this, recordingSplitSize_instance, hour)
            calllib(this.lib_name, 'set_fixed_daily_hour', recordingSplitSize_instance, int32(hour));
        end
        %
        %% Recording options.
        function set_session_id(this, recordingOptions_instance, id, lengthOfId)
            calllib(this.lib_name, 'set_session_id', recordingOptions_instance, id, uint32(lengthOfId));
        end
        %
        function status = get_session_id(this, recordingOptions_instance, resultPtr, lengthPtr, maxLength)
            [status,~,result] = calllib(this.lib_name, 'get_session_id', recordingOptions_instance, resultPtr, lengthPtr, uint32(maxLength));
            assert(status==0,'get_session_id:libraryStatusFailed',strcat('Call returns status=',num2str(status)));
            resultPtr.Value = result;
        end
        %
        function set_file_split_size(this, recordingOptions_instance, recordingSplitSize_instance)
            calllib(this.lib_name, 'set_file_split_size', recordingOptions_instance, recordingSplitSize_instance);
        end
        %
        function set_directory_split_size(this, recordingOptions_instance, recordingSplitSize_instance)
            calllib(this.lib_name, 'set_directory_split_size', recordingOptions_instance, recordingSplitSize_instance);
        end
        %
        function set_data_rate_limit(this, recordingOptions_instance, limit)
            calllib(this.lib_name, 'set_data_rate_limit', recordingOptions_instance, int32(limit));
        end
        %
        function set_user_header(this, recordingOptions_instance, header, lengthOfHeader)
            calllib(this.lib_name, 'set_user_header', recordingOptions_instance, header, uint32(lengthOfHeader));
        end
        %
        %% Data recorder.
        function status = start_recording( this, dataRecorder_instance, xethruDataType, directory, lengthOfDir, recordingOptions_instance)
            status = calllib(this.lib_name, 'nva_start_recording', dataRecorder_instance,...
                uint32(xethruDataType), directory, uint32(lengthOfDir), recordingOptions_instance);
            assert(status==0,'start_recording:libraryStatusFailed',strcat('Call returns status=',num2str(status)));
        end
        %
        function stop_recording( this, dataRecorder_instance, xethruDataType)
            calllib(this.lib_name, 'nva_stop_recording', dataRecorder_instance, uint32(xethruDataType));
        end
        %
        function status = process( this, dataRecorder_instance, xethruDataType, bytes, lengthOfBytes)
            status = calllib(this.lib_name, 'nva_process', dataRecorder_instance,...
                uint32(xethruDataType), bytes, uint32(lengthOfBytes));
            assert(status==0,'process:libraryStatusFailed',strcat('Call returns status=',num2str(status)));
        end
        %
        function set_basename_for_data_type(this,dataRecorder_instance, data_type, name, lengthOfName)
            calllib(this.lib_name, 'nva_set_basename_for_data_type', dataRecorder_instance, uint32(data_type), name, uint32(lengthOfName));
        end
        %
        function status = get_basename_for_data_type(this, dataRecorder_instance, data_type, dstPtr, lengthPtr, maxLength)
            [status,~,dst] = calllib(this.lib_name, 'nva_get_basename_for_data_type', dataRecorder_instance, uint32(data_type), dstPtr, lengthPtr, uint32(maxLength));
            assert(status==0,'get_basename_for_data_type:libraryStatusFailed',strcat('Call returns status=',num2str(status)));            
            dstPtr.Value = dst(1:lengthPtr.Value);
        end       
        %
        function clear_basename_for_data_types(this, dataRecorder_instance, data_type)
            calllib(this.lib_name, 'nva_clear_basename_for_data_types', dataRecorder_instance, uint32(data_type));
        end
        
    end
    
end