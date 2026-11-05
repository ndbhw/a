function [packets, info] = axis2pcap(axisFile, pcapFile, opts)
%AXIS2PCAP Decode AXIS beats captured from RU FPGA (ILA/sim) into a PCAP file.
%
%   [packets, info] = axis2pcap(axisFile, pcapFile, opts)
%
%   axisFile : text file, one AXIS beat (tvalid=1) per line:
%                  <tdata 16 hex> <tkeep 2 hex> <tlast 1 hex> [<r_cnt dec>]
%              e.g. "3b566355b0de14da ff 0 1234"
%              Byte 0 of the Ethernet frame is tdata[7:0] (little-endian AXIS),
%              tkeep bit i marks byte i (tdata[8i+7:8i]) as valid.
%              The 4th column (clock counter, decimal) is optional.
%   pcapFile : output PCAP file name (.pcap)
%   opts     : optional struct
%       .TimeMode      'counter' - timestamp from r_cnt of the first beat of each
%                                  packet (real time on the AXIS bus). Falls
%                                  back to 'oran' if the file has no 4th column.
%                      'oran'    - timestamp from O-RAN header (frame/subframe/
%                                  slot/symbol), same as the MATLAB example
%                                  GenerateCUPlaneMessagesForORANFronthaulTestExample
%                      'index'   - packet i gets timestamp i*TimeStep
%       .ClkFreq       counter clock in Hz (default 156.25e6)
%       .CntBits       counter width in bits (default 22, wraps every ~26.84 ms)
%       .SCS           subcarrier spacing in kHz (default 30)
%       .CPlaneOffset  C-Plane time offset in seconds (default 0)
%       .UPlaneOffset  U-Plane time offset in seconds (default 120e-6 =
%                      mPlaneConfig.Tcp_adv_dl in the example)
%       .TimeStep      seconds between packets for 'index' mode (default 1e-6)
%       .TrimPartial   drop the first packet if it is incomplete, i.e. capture
%                      started in the middle of a packet (default true).
%                      Beats after the last tlast are always dropped.
%       .DropInvalid   drop all packets that are not eCPRI or whose length does
%                      not match the eCPRI payload size (default false)
%       .Verbose       print summary (default true)
%
%   packets : cell array of uint8 column vectors (one Ethernet frame each)
%   info    : struct array with per-packet decoded header fields

    if nargin < 3, opts = struct(); end
    opts = setDefault(opts, 'TimeMode',     'counter');
    opts = setDefault(opts, 'ClkFreq',      156.25e6);
    opts = setDefault(opts, 'CntBits',      22);
    opts = setDefault(opts, 'SCS',          30);
    opts = setDefault(opts, 'CPlaneOffset', 0);
    opts = setDefault(opts, 'UPlaneOffset', 120e-6);
    opts = setDefault(opts, 'TimeStep',     1e-6);
    opts = setDefault(opts, 'TrimPartial',  true);
    opts = setDefault(opts, 'DropInvalid',  false);
    opts = setDefault(opts, 'Verbose',      true);

    %% 1) Read AXIS beats
    [bytes, mask, tlast, cnt] = readAxisFile(axisFile);
    nBeats = size(bytes, 1);

    if strcmpi(opts.TimeMode, 'counter') && all(isnan(cnt))
        warning('axis2pcap:noCounter', ...
            'No counter column in %s -> using TimeMode = ''oran''.', axisFile);
        opts.TimeMode = 'oran';
    end

    %% 2) Reassemble Ethernet frames on tlast
    % Valid bytes of all beats in stream order (beat by beat, byte 0 first)
    bT     = bytes.';
    mT     = mask.';
    stream = bT(mT);                         % uint8 column vector
    cntCum = cumsum(sum(mask, 2));           % number of valid bytes up to each beat

    lastIdx = find(tlast);
    if isempty(lastIdx)
        error('axis2pcap:noTlast', 'No tlast found in %s', axisFile);
    end
    if lastIdx(end) < nBeats
        warning('axis2pcap:trailing', ...
            '%d beat(s) after the last tlast were ignored (incomplete packet).', ...
            nBeats - lastIdx(end));
    end
    pktEnd   = cntCum(lastIdx);
    pktStart = [0; pktEnd(1:end-1)] + 1;
    nPkt     = numel(pktEnd);

    packets = cell(nPkt, 1);
    for k = 1:nPkt
        packets{k} = stream(pktStart(k):pktEnd(k));
    end

    %% 3) Decode Ethernet / eCPRI / O-RAN header fields
    info = repmat(struct('Length', 0, 'VLAN', NaN, 'EtherType', 0, ...
        'Valid', false, 'LenOK', false, 'Plane', "", 'eCPRIType', NaN, 'eAxCID', NaN, ...
        'SeqID', NaN, 'DataDirection', NaN, 'FrameID', NaN, ...
        'SubframeID', NaN, 'SlotID', NaN, 'SymbolID', NaN, 'Cnt', NaN, 'Time', 0), nPkt, 1);
    firstBeat = [1; lastIdx(1:end-1) + 1];   % first beat (SOP) of each packet
    for k = 1:nPkt
        info(k) = parseHeader(packets{k}, info(k));
        info(k).Cnt = cnt(firstBeat(k));
    end

    good = ([info.Valid] & [info.LenOK]).';

    % Capture started in the middle of a packet -> first fragment has no
    % valid header / wrong length
    if opts.TrimPartial && nPkt > 0 && ~good(1)
        warning('axis2pcap:leading', ...
            'First packet (%d bytes, %d beat(s)) is incomplete and was dropped.', ...
            info(1).Length, lastIdx(1));
        packets(1) = []; info(1) = []; good(1) = [];
        nPkt = nPkt - 1;
    end

    if any(~good)
        bad = find(~good);
        warning('axis2pcap:badPkt', ...
            '%d packet(s) are not eCPRI or have wrong length (first: #%d, %d bytes).', ...
            numel(bad), bad(1), info(bad(1)).Length);
        if opts.DropInvalid
            packets = packets(good);
            info    = info(good);
            nPkt    = numel(packets);
            if opts.Verbose
                fprintf('Dropped %d invalid packet(s).\n', numel(bad));
            end
        end
    end

    %% 4) Timestamps
    t = computeTimes(info, opts);
    for k = 1:nPkt
        info(k).Time = t(k);
    end
    % Seconds -> integer microseconds (truncate, like the example).
    % Round to picoseconds first to remove floating-point error, otherwise
    % e.g. r_cnt = 308125 (exactly 1972 us) gives 1971.99999 -> 1971.
    tUs = floor(round(t * 1e12) / 1e6);

    %% 5) Write PCAP (Ethernet link type = 1)
    writePcap(pcapFile, packets, tUs);

    %% Summary
    if opts.Verbose
        nC = sum([info.Plane] == "C-Plane");
        nU = sum([info.Plane] == "U-Plane");
        fprintf('Beats: %d | Packets: %d (C-Plane: %d, U-Plane: %d, other: %d)\n', ...
            nBeats, nPkt, nC, nU, nPkt - nC - nU);
        fprintf('Written: %s\n', pcapFile);
    end
end

%% ========================================================================
function [bytes, mask, tlast, cnt] = readAxisFile(axisFile)
% Return bytes (Nx8 uint8, column 1 = tdata[7:0]), mask (Nx8 logical),
% tlast (Nx1 logical), cnt (Nx1 double, NaN if the file has no counter column)
    fid = fopen(axisFile, 'r');
    if fid < 0
        error('axis2pcap:open', 'Cannot open %s', axisFile);
    end
    % Number of columns from the first non-empty line (3 or 4)
    nCol = 0;
    while ~feof(fid) && nCol == 0
        nCol = numel(strsplit(strtrim(fgetl(fid))));
        if nCol == 1, nCol = 0; end              % empty line
    end
    frewind(fid);
    if nCol >= 4
        C = textscan(fid, '%s %s %s %f %*[^\n]');
    else
        C = textscan(fid, '%s %s %s %*[^\n]');
    end
    fclose(fid);

    tdataS = C{1}; tkeepS = C{2}; tlastS = C{3};
    n = min([numel(tdataS) numel(tkeepS) numel(tlastS)]);
    tdataS = tdataS(1:n); tkeepS = tkeepS(1:n); tlastS = tlastS(1:n);
    if nCol >= 4
        cnt = C{4};
        cnt(end+1:n) = NaN;
        cnt = cnt(1:n);
    else
        cnt = nan(n, 1);
    end

    % Hex char -> nibble lookup
    lut = nan(1, 256);
    lut(double('0'):double('9')) = 0:9;
    lut(double('a'):double('f')) = 10:15;
    lut(double('A'):double('F')) = 10:15;

    % tdata: left pad to 16 hex chars
    tdC = char(pad(tdataS, 16, 'left', '0'));
    nib = lut(double(tdC));
    if any(isnan(nib(:)))
        bad = find(any(isnan(nib), 2), 1);
        error('axis2pcap:hex', 'Invalid hex in tdata at line %d: "%s"', bad, tdataS{bad});
    end
    msbFirst = nib(:, 1:2:end) * 16 + nib(:, 2:2:end);   % column 1 = tdata[63:56]
    bytes    = uint8(fliplr(msbFirst));                    % column 1 = tdata[7:0]

    % tkeep
    tkC = char(pad(tkeepS, 2, 'left', '0'));
    kn  = lut(double(tkC));
    kv  = kn(:, 1) * 16 + kn(:, 2);
    mask = logical(bitget(repmat(kv, 1, 8), repmat(1:8, n, 1)));

    % tlast
    tlC   = char(tlastS);
    tlast = reshape(lut(double(tlC(:, end))), [], 1) ~= 0;
end

%% ========================================================================
function s = parseHeader(p, s)
    p = double(p);
    s.Length = numel(p);
    if numel(p) < 14, return; end

    L = 14;
    ethType = p(13) * 256 + p(14);
    if ethType == hex2dec('8100') && numel(p) >= 18      % VLAN tag
        s.VLAN  = bitand(p(15) * 256 + p(16), 4095);
        ethType = p(17) * 256 + p(18);
        L = 18;
    end
    s.EtherType = ethType;

    % eCPRI (0xAEFE): 4B common header + 2B eAxC (ecpriRtcid/PcId) + 2B SeqId
    % O-RAN common header (4B): dataDir|payloadVer|filterIdx, frameId,
    %                           subframeId(4)|slotId(6)|symbolId(6)
    if ethType ~= hex2dec('AEFE') || numel(p) < L + 12
        return;
    end
    s.Valid     = true;
    s.eCPRIType = p(L + 2);

    % Length check: Ethernet hdr + 4B eCPRI common hdr + eCPRI payload size.
    % Allow Ethernet padding to 60B for short frames and an optional 4B FCS.
    expLen  = L + 4 + p(L + 3) * 256 + p(L + 4);
    len     = numel(p);
    s.LenOK = (len == expLen) || (len == expLen + 4) || ...
              (expLen < 60 && len >= 60 && len <= 64);
    switch s.eCPRIType
        case 0, s.Plane = "U-Plane";   % IQ data
        case 2, s.Plane = "C-Plane";   % Real-time control
        otherwise, s.Plane = "eCPRI";
    end
    s.eAxCID = p(L + 5) * 256 + p(L + 6);
    s.SeqID  = p(L + 7);

    o = L + 8;                                          % start of O-RAN header
    s.DataDirection = bitshift(p(o + 1), -7);
    s.FrameID       = p(o + 2);
    s.SubframeID    = bitshift(p(o + 3), -4);
    s.SlotID        = bitand(p(o + 3), 15) * 4 + bitshift(p(o + 4), -6);
    s.SymbolID      = bitand(p(o + 4), 63);
end

%% ========================================================================
function t = computeTimes(info, opts)
    n = numel(info);
    if strcmpi(opts.TimeMode, 'index')
        t = (0:n-1).' * opts.TimeStep;
        return;
    end

    if strcmpi(opts.TimeMode, 'counter')
        % Real time on the bus: r_cnt at the first beat of each packet.
        % Unwrap the CntBits-bit counter (assumes gap between 2 packets
        % < 2^CntBits / ClkFreq, i.e. ~26.84 ms for 22 bit @156.25 MHz)
        c = [info.Cnt].';
        d = diff(c);
        d(d < 0) = d(d < 0) + 2^opts.CntBits;
        c = c(1) + [0; cumsum(d)];
        t = c / opts.ClkFreq;
        return;
    end

    % Symbol start times within a 1 ms subframe (normal CP), as in the example
    scs = opts.SCS;
    if exist('nrOFDMInfo', 'file')
        ifo = nrOFDMInfo(273, scs, 'CyclicPrefix', 'normal');
        symTimes = [0 cumsum(ifo.SymbolLengths / ifo.SampleRate)];
        symPerSlot = ifo.SymbolsPerSlot;
    else
        % Fallback: equal symbol duration
        nSym = 14 * scs / 15;
        symTimes = (0:nSym) * 1e-3 / nSym;
        symPerSlot = 14;
    end

    t = zeros(n, 1);
    framePeriod = 256 * 10e-3;                       % frameId wraps at 256
    wrap = 0;
    prev = -inf;
    warnedRange = false;
    for k = 1:n
        s = info(k);
        if ~s.Valid
            % Non-eCPRI packet: reuse previous time
            t(k) = max(prev, 0);
            continue;
        end
        symIdx = 1 + s.SymbolID + symPerSlot * s.SlotID;
        if symIdx <= numel(symTimes)
            tSym = symTimes(symIdx);
        else
            % slotId/symbolId outside the table of opts.SCS (e.g. PRACH or
            % other numerology): approximate with equal slot/symbol duration
            nSlot = (numel(symTimes) - 1) / symPerSlot;      % slots per subframe
            slotDur = 1e-3 / nSlot;
            tSym = s.SlotID * slotDur + s.SymbolID * slotDur / symPerSlot;
            if ~warnedRange
                warning('axis2pcap:symRange', ['Packet %d: slotId=%d/symbolId=%d ' ...
                    'exceeds SCS=%g kHz table, using approximate timestamp.'], ...
                    k, s.SlotID, s.SymbolID, scs);
                warnedRange = true;
            end
        end
        st = tSym + 1e-3 * s.SubframeID + 10e-3 * s.FrameID;
        if s.Plane == "U-Plane"
            st = st + opts.UPlaneOffset;
        else
            st = st + opts.CPlaneOffset;
        end
        st = st + wrap;
        if st < prev - framePeriod / 2               % frameId wrapped 255 -> 0
            wrap = wrap + framePeriod;
            st   = st + framePeriod;
        end
        t(k) = st;
        prev = st;
    end
end

%% ========================================================================
function writePcap(pcapFile, packets, tUs)
    if isfile(pcapFile)
        ws = warning('off', 'MATLAB:DELETE:Permission');
        delete(pcapFile);
        warning(ws);
        if isfile(pcapFile)
            error('axis2pcap:locked', ...
                'Cannot overwrite %s (file is open in Wireshark?). Close it and run again.', ...
                pcapFile);
        end
    end
    ethernetLinkType = 1;

    if exist('pcapWriter', 'class') || exist('pcapWriter', 'file')
        % Same writer as the MATLAB example (Communications Toolbox)
        % pcapWriter does not accept a path in FileName -> cd to target folder
        [fp, fn] = fileparts(pcapFile);
        oldDir = pwd;
        if ~isempty(fp), cd(fp); end
        cleanupDir = onCleanup(@() cd(oldDir));
        pcapObj = pcapWriter(FileName = fn);
        writeGlobalHeader(pcapObj, ethernetLinkType);
        for k = 1:numel(packets)
            write(pcapObj, packets{k}, tUs(k));
        end
        clear pcapObj;                                % release object -> close file
        clear cleanupDir;
    else
        % Fallback: plain libpcap writer (microsecond resolution, little-endian)
        fid = fopen(pcapFile, 'w', 'ieee-le');
        if fid < 0
            error('axis2pcap:write', 'Cannot create %s', pcapFile);
        end
        fwrite(fid, hex2dec('A1B2C3D4'), 'uint32');   % magic
        fwrite(fid, [2 4], 'uint16');                 % version 2.4
        fwrite(fid, [0 0 65535 ethernetLinkType], 'uint32'); % thiszone, sigfigs, snaplen, linktype
        for k = 1:numel(packets)
            sec  = floor(tUs(k) / 1e6);
            usec = tUs(k) - sec * 1e6;
            len  = numel(packets{k});
            fwrite(fid, [sec usec len len], 'uint32');
            fwrite(fid, packets{k}, 'uint8');
        end
        fclose(fid);
    end
end

%% ========================================================================
function opts = setDefault(opts, name, value)
    if ~isfield(opts, name) || isempty(opts.(name))
        opts.(name) = value;
    end
end
