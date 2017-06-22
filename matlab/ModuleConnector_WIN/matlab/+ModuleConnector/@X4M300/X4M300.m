classdef X4M300
    %X4M300 is the Xethru presence sensor based on the
    % Xethru X4 SOC.
    %
    % Example
    %   mc = ModuleConnector.ModuleConnector('COM3')
    %   X4M300 = mc.get_x4m300();
    %
    % See also MODULECONNECTOR, X2M200, X2, XEP, TRANSPORT
    %
    %
    
    properties (SetAccess = private)
        X4M300_instance;    % Libpointer to C/C++ library instance
        radarInterface;     % Layer one wrapper class
    end
    
    % Buffers
    properties (SetAccess = private,Hidden) % baseband_ap / baseband_iq  buffers
        AP_framePtr = libpointer('singlePtr',zeros(1280,1)); % AP data
        AP_max_length = 1280;
        pAP_frame_counter     = libpointer('uint32Ptr',0);
        pAP_num_bins          = libpointer('uint32Ptr',0);
        pAP_bin_length        = libpointer('singlePtr',0);
        pAP_sample_frequency  = libpointer('singlePtr',0);
        pAP_carrier_frequency = libpointer('singlePtr',0);
        pAP_range_offset      = libpointer('singlePtr',0);
        pAP_amplitude         = libpointer('singlePtr',zeros(1280,1));
        pAP_phase             = libpointer('singlePtr',zeros(1280,1));
        
        IQ_framePtr = libpointer('singlePtr',zeros(1280,1)); % IQ data
        IQ_max_length = 1280;
        pIQ_frame_counter     = libpointer('uint32Ptr',0);
        pIQ_num_bins          = libpointer('uint32Ptr',0);
        pIQ_bin_length        = libpointer('singlePtr',0);
        pIQ_sample_frequency  = libpointer('singlePtr',0);
        pIQ_carrier_frequency = libpointer('singlePtr',0);
        pIQ_range_offset      = libpointer('singlePtr',0);
        pIQ_i_data            = libpointer('singlePtr',zeros(1280,1));
        pIQ_q_data            = libpointer('singlePtr',zeros(1280,1));
    end
    
    properties (SetAccess = private,Hidden) % presence single buffers
        pR_frame_counter      = libpointer('uint32Ptr',0);
        pR_sensor_state       = libpointer('uint32Ptr',0);
        pR_distance           = libpointer('singlePtr',0);
        pR_direction           = libpointer('uint8Ptr',0);
        pR_signal_quality     = libpointer('uint32Ptr',0);
    end
    
    properties (SetAccess = private,Hidden) % presence moving list buffers
        pM_maxLength = 200;
        pM_frame_counter      = libpointer('uint32Ptr',0);
        pM_sensor_state       = libpointer('uint32Ptr',0);
        pM_movementIntervalCount = libpointer('uint32Ptr',0);
        pM_detectionCount     = libpointer('uint32Ptr',0);
        pM_movementSlowItem   = libpointer('singlePtr',zeros(200,1));
        pM_movementFastItem   = libpointer('singlePtr',zeros(200,1));
        pM_detectionDistance  = libpointer('singlePtr',zeros(200,1));
        pM_detectionRadarCrossSection = libpointer('singlePtr',zeros(200,1));
        pM_detectionVelocity  = libpointer('singlePtr',zeros(200,1));
    end
    
    properties (SetAccess = private,Hidden) % system info buffers
        SI_max_length = 100;
    end
    
    
    methods
        
        function [system_info, status] = get_system_info(this, info_code)
            %GET_SYSTEM_INFO Returns a string containing system information given an infocode
            %    [system_info,status] = GET_SYSTEM_INFO(this,info_code)
            %    Info codes:
            %    XTID_SSIC_ITEMNUMBER    = 0x00, Returns the internal Novelda PCBA Item Number,
            %                                    including revision. This is programmed in Flash during manufacturing.
            %    XTID_SSIC_ORDERCODE     = 0x01, Returns the PCBA / PCBA stack order code.
            %    XTID_SSIC_FIRMWAREID    = 0x02, Returns the installed Firmware ID. As viewed from the "highest"
            %                                    level of the software, "X4M300".
            %    XTID_SSIC_VERSION       = 0x03, Returns the installed Firmware Version. As viewed from the "highest"
            %                                    level of the software.
            %    XTID_SSIC_BUILD         = 0x04, Returns information of the SW Build installed on the device
            %    XTID_SSIC_SERIALNUMBER  = 0x06, Returns the PCBA serial number
            %    XTID_SSIC_VERSIONLIST   = 0x07, Returns ID and version of all components. Calls all components and compound
            %                                    a string. E.g. "X4M300:1.0.0.3;XEP:2.3.4.5;X4C51:1.0.0.0;DSP:1.1.1.1"
            system_infoPtr = libpointer('string',blanks(this.SI_max_length));
            
            status = this.radarInterface.get_system_info( this.X4M300_instance, info_code, system_infoPtr, this.SI_max_length);
            
            system_info = system_infoPtr.Value; clear system_infoPtr;
        end
        
        function status = module_reset(this)
            %MODULE_RESET Resets and restart the module.
            status = this.radarInterface.module_reset(this.X4M300_instance);
        end
        
        function status = set_debug_level(this, debug_level)
            %SET_DEBUG_LEVEL Set the debug level of the profile.
            status = this.radarInterface.set_debug_level(this.X4M300_instance, debug_level);
        end
        
        function status = set_sensor_mode( this, mode )
            %SET_SENSOR_MODE Control the sensor module mode of execution.
            % When the module is configured to run an application, such as X4M300,
            % this method is used to control the execution.
            %
            % status = SET_SENSOR_MODE( this, mode )
            %   Run  - [0x01] Run profile application
            %   Idle - [0x11] Halts profile application, can be Run again.
            %   Stop - [0x13] Stop profile application
            %   XEP  - [0x12] Interact directly with XDriver, i.e. allow streaming directly to host
            % @return
            %	0 = Succes, other indicates some error.
            switch mode
                case {'Run','run'}
                    mode = hex2dec('1');
                case {'Idle','idle'}
                    mode = hex2dec('11');
                case {'Stop','stop'}
                    mode = hex2dec('13');
                case {'XEP','xep'}
                    mode = hex2dec('12');
            end
            status = this.radarInterface.set_sensor_mode( this.X4M300_instance, mode );
        end
        
        function status = load_profile( this, profile_id)
            %LOAD_PROFILE Loads the a preset profile.
            %
            % If another profile is loaded, the other profile is unloaded before the new profile is loaded. The profile does not start, the module remains idle.
            % status = LOAD_PROFILE( this, profile_id)
            %   profile_id = X : presence profile
            %   profile_id = Y : presence profile
            status = this.radarInterface.load_profile( this.X4M300_instance, profile_id);
        end
        
        function status = set_output_control(this, output_feature, output_ctrl)
            %SET_OUTPUT_CONTROL Control module profile output.
            %
            % Enable and disable data messages. Several calls can be made, one for each available output message the profile provides.
            %
            % output_feature:
            %     PresenceSingle (0x723bfa1e)
            %     PresenceMovingList (0x723bfa1f)
            %     BasebandIQ (0x0000000c)
            %     BasebandAP (0x0000000d)
            %
            % output_control:
            %     0 = disable
            %     >0 = enable + format. E.g. pulsedoppler output data byte or float
            status = this.radarInterface.set_output_control( this.X4M300_instance, output_feature, output_ctrl);
        end
        
        function [output_ctrl,status] = get_output_control(this, output_feature)
            %GET_OUTPUT_CONTROL Returns the output control of the specified output feature.
            output_ctrlPtr = libpointer('uint32Ptr',0);
            status = this.radarInterface.load_profile( this.X4M300_instance, output_feature, output_ctrlPtr);
            output_ctrl = double(output_ctrlPtr.Value); clear output_ctrl;
        end
        
        function status = set_detection_zone( this, start, stop )
            %SET_DETECTION_ZONE Set the desired detection zone.
            % The sensor will detect movements within this area.
            % status = SET_DETECTION_ZONE( this, start, stop )
            % 	start   Start of detection zone in meters.
            % 	stop    End of detection zone in meters.
            %   status  Successful call returns 0, otherwise error code.
            status = this.radarInterface.set_detection_zone(this.X4M300_instance,start,stop);
        end
        
        function [start,stop,status] = get_detection_zone( this )
            %GET_DETECTION_ZONE Returns the actual range window.
            % The sensor will detect movements within this area.
            % [start,stop,status] = GET_DETECTION_ZONE( this )
            % 	start   Start of detection zone in meters.
            % 	stop    End of detection zone in meters.
            %   status  Successful call returns 0, otherwise error code.
            startPtr = libpointer('singlePtr',0);
            stopPtr  = libpointer('singlePtr',0);
            status = this.radarInterface.get_detection_zone(this.X4M300_instance,startPtr,stopPtr);
            start= double(startPtr.Value);
            stop = double(stopPtr.Value);
            clear startPtr stopPtr;
        end
        
        function [start,stop,step,status] = get_detection_zone_limits( this )
            %GET_DETECTION_ZONE_LIMITS Returns the potential settings of detection zone from the module.
            % The sensor can detect movements within this area.
            % [start,stop,step,status] = GET_DETECTION_ZONE_LIMITS( this )
            % 	start   Start of detection zone in meters.
            % 	stop    End of detection zone in meters.
            %   step
            %   status  Successful call returns 0, otherwise error code.
            startPtr = libpointer('singlePtr',0);
            stopPtr  = libpointer('singlePtr',0);
            stepPtr  = libpointer('singlePtr',0);
            status = this.radarInterface.get_detection_zone_limits(this.X4M300_instance,startPtr,stopPtr,stepPtr);
            start= double(startPtr.Value);
            stop = double(stopPtr.Value);
            step = double(stepPtr.Value);
            clear startPtr stopPtr stepPtr;
        end
        
        function status = set_sensitivity( this, new_sensitivity )
            %SET_SENSITIVITY Set module sensitivity.
            % status = SET_SENSITIVITY( this, new_sensitivity )
            %   new_sensitivity Sensitivity level from 0 (low) to 9 (high).
            %   status  Successful call returns 0, otherwise error code.
            status = this.radarInterface.set_sensitivity(this.X4M300_instance,new_sensitivity);
        end
        
        function status = set_led_control( this, mode, intensity )
            %SET_LED_CONTROL Configures the module LED mode.
            % status = SET_LED_CONTROL( this, mode, intensity )
            %   mode        0:Off, 1:Simple, 2:Full(default).
            %   intensity   Intensity: Future use, 0=low, 100=high
            status = this.radarInterface.set_led_control(this.X4M300_instance, mode, intensity);
        end
        
        function int = peek_message_baseband_iq( this )
            %PEEK_MESSAGE_BASEBAND_IQ  Return the number of buffered baseband iq messages.
            % int = PEAK_MESSAGE_BASEBAND_IQ( this )
            int = double(this.radarInterface.peek_message_baseband_iq(this.X4M300_instance));
        end
        
        function int = peek_message_baseband_ap( this )
            %PEEK_MESSAGE_BASEBAND_AP  Return the number of buffered baseband ap messages.
            % int = PEAK_MESSAGE_BASEBAND_AP( this )
            int = double(this.radarInterface.peek_message_baseband_ap(this.X4M300_instance));
        end
        
        function int = peek_message_presence_single( this )
            %PEEK_MESSAGE_PRESENCE_SINGLE  Return the number of buffered presence single messages.
            % int = PEAK_MESSAGE_PRESENCE_SINGLE( this )
            int = double(this.radarInterface.peek_message_presence_single(this.X4M300_instance));
        end
        
        function int = peek_message_presence_movinglist( this )
            %PEEK_MESSAGE_PRESENCE_MOVINGLIST Return the number of buffered presence movinglist messages.
            % int = PEEK_MESSAGE_PRESENCE_MOVINGLIST( this )
            int = double(this.radarInterface.peek_message_presence_movinglist(this.X4M300_instance));
        end
        
        function [rd,status] = read_message_presence_single( this )
            % Get one buffered presence_single data message. Order is FIFO.
            % [rd,status] = READ_MESSAGE_PRESENCE_SINGLE( this )
            %   rd                  a data struct containing the presence_single data.
            %   rd.counter          message sequence number
            %   rd.sensor_state
            %   rd.distance
            %   rd.direction
            %   rd.signal_quality  A relative number from 0 to 10 where 10 indicates highest signal quality.
            status = this.radarInterface.read_message_presence_single(this.X4M300_instance, this.pR_frame_counter, this.pR_sensor_state, this.pR_distance, this.pR_direction, this.pR_signal_quality);
            rd.counter    = double(this.pR_frame_counter.Value);
            rd.presence_state   = double(this.pR_sensor_state.Value);
            rd.distance         = double(this.pR_distance.Value);
            rd.direction        = double(this.pR_direction.Value);
            rd.signal_quality   = double(this.pR_signal_quality.Value);
        end
        %
        function [md,status] = read_message_presence_movinglist( this )
            % Get one buffered presence movinglist message. Order is FIFO.
            % [md,status] = READ_MESSAGE_PRESENCE_MOVINGLIST( this )
            %   md    a data struct containing the presence data.
            %   md.counter          message sequence number
            %   md.presence_state
            %   md.movementIntervalCount
            %   md.detectionCount
            %   md.movementSlowItem
            %   md.movementFastItem
            %   md.detectionDistance
            %   md.detectionRadarCrossSection
            %   md.detectionVelocity
            status = this.radarInterface.read_message_presence_movinglist(this.X4M300_instance, this.pM_frame_counter, this.pM_sensor_state, this.pM_movementIntervalCount, this.pM_detectionCount, this.pM_movementSlowItem, this.pM_movementFastItem, this.pM_detectionDistance, this.pM_detectionRadarCrossSection, this.pM_detectionVelocity, this.pM_maxLength);
            md.counter = double(this.pM_frame_counter.Value);
            md.presence_state = double(this.pM_sensor_state.Value);
            md.movementIntervalCount = double(this.pM_movementIntervalCount.Value);
            md.detectionCount = double(this.pM_detectionCount.Value);
            md.movementSlowItem = double(this.pM_movementSlowItem.Value);
            md.movementFastItem = double(this.pM_movementFastItem.Value);
            md.detectionDistance = double(this.pM_detectionDistance.Value);
            md.detectionRadarCrossSection = double(this.pM_detectionRadarCrossSection.Value);
            md.detectionVelocity = double(this.pM_detectionVelocity.Value);
        end
        
        function [iq_data,header,status] = read_message_baseband_iq( this )
            % Get one buffered baseband IQ data message. Order is FIFO.
            % [iq_data,header,status] = READ_MESSAGE_BASEBAND_IQ( this, name )
            %   iq_data   complex vector containing i and q baseband data
            %   header    a data struct containing the following header data:
            %   header.frame_counter       message sequence number
            %   header.num_bins            number of bins in the i or q data message
            %	header.bin_length
            %	header.sample_frequency    receiver sampling frequency
            %	header.carrier_frequency   transmitter center frequency
            %	header.range_offset        range to the beginning of the frame
            %   status
            status = this.radarInterface.read_message_baseband_iq(this.X4M300_instance, this.pIQ_frame_counter, this.pIQ_num_bins, this.pIQ_bin_length, this.pIQ_sample_frequency, this.pIQ_carrier_frequency, this.pIQ_range_offset, this.pIQ_i_data, this.pIQ_q_data,this.IQ_max_length);
            header.frame_counter     = double(this.pIQ_frame_counter.Value);
            header.num_bins          = double(this.pIQ_num_bins.Value);
            header.bin_length        = double(this.pIQ_bin_length.Value);
            header.sample_frequency  = double(this.pIQ_sample_frequency.Value);
            header.carrier_frequency = double(this.pIQ_carrier_frequency.Value);
            header.range_offset      = double(this.pIQ_range_offset.Value);
            i_data    = double(this.pIQ_amplitude.Value(1:header.num_bins));
            q_data    = double(this.pIQ_phase.Value(1:header.num_bins));
            iq_data   = complex(i_data,q_data);
        end
        
        function [amplitude,phase,header,status] = read_message_baseband_ap( this )
            % Get one buffered baseband AP data message. Order is FIFO.
            % [amplitude,phase,header,status] = READ_MESSAGE_BASEBAND_AP( this, name )
            %   amplitude  vector containing the signal envelope
            %   phase      vector containing the signal phase
            %   header                      a data struct containing the following header data:
            %   header.frame_counter        message sequence number
            %   header.num_bins             number of bins in the i or q data message
            %   header.bin_length
            %   header.sample_frequency     receiver sampling frequency
            %   header.carrier_frequency    transmitter center frequency
            %   header.range_offset         range to the beginning of the frame
            %   status
            status = this.radarInterface.read_message_baseband_ap(this.X4M300_instance, this.pAP_frame_counter, this.pAP_num_bins, this.pAP_bin_length, this.pAP_sample_frequency, this.pAP_carrier_frequency, this.pAP_range_offset, this.pAP_amplitude, this.pAP_phase,this.AP_max_length);
            header.frame_counter     = double(this.pAP_frame_counter.Value);
            header.num_bins          = double(this.pAP_num_bins.Value);
            header.bin_length        = double(this.pAP_bin_length.Value);
            header.sample_frequency  = double(this.pAP_sample_frequency.Value);
            header.carrier_frequency = double(this.pAP_carrier_frequency.Value);
            header.range_offset      = double(this.pAP_range_offset.Value);
            amplitude = double(this.pAP_amplitude.Value(1:header.num_bins));
            phase     = double(this.pAP_phase.Value(1:header.num_bins));
        end
        
        function clear( this, name )
            % CLEAR Clears the in-buffer of the named subscription.
            %
            % @param[in]
            %	name Subscription identification
            this.radarInterface.clear( this.X4M300_instance, name );
        end
        
    end
    
    methods
        % Constructor
        function x4m300 = X4M300( mc )
            % Constructor
            x4m300.radarInterface = mc.radarInterface;
            x4m300.X4M300_instance = calllib(mc.lib_name,'nva_get_x2',mc.mcInstance);
            assert(~x4m300.X4M300_instance.isNull, 'create xethru failed check the logs');
        end
        
        % Destructor
        function delete( this )
            % Destructor
            clear this.pR_frame_counter this.pR_sensor_state this.pR_distance this.pR_direction this.pR_signal_quality
            clear this.pM_frame_counter this.pM_sensor_state this.pM_movementIntervalCount this.pM_detectionCount this.pM_movementSlowItem this.pM_movementFastItem this.pM_detectionDistance this.pM_detectionRadarCrossSection this.pM_detectionVelocity
            clear this.pAP_frame_counter this.pAP_num_bins this.pAP_bin_length this.pAP_sample_frequency this.pAP_carrier_frequency this.pAP_range_offset this.pAP_amplitude this.pAP_phase
            clear this.pIQ_frame_counter this.pIQ_num_bins this.pIQ_bin_length this.pIQ_sample_frequency this.pIQ_carrier_frequency this.pIQ_range_offset this.pIQ_i_data this.pIQ_q_data
            calllib(this.radarInterface.lib_name,'nva_destroy_XEP_interface',this.X4M300_instance);
            clear('this.radarInterface')
            clear('this.X4M300_instance')
        end
    end
end
