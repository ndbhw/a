%% Decode AXIS capture (ILA / simulation) -> PCAP for Wireshark
% Input : axis.txt (same folder), one line per tvalid beat:
%           <tdata hex> <tkeep hex> <tlast hex> <r_cnt dec>   (r_cnt optional)
% Output: axis_decoded.pcap
clear; clc;

thisDir  = fileparts(mfilename('fullpath'));
axisFile = fullfile(thisDir, 'axis.txt');
pcapFile = fullfile(thisDir, 'axis_decoded.pcap');

%% ============================== CONFIG ==================================
% Timestamp mỗi gói = r_cnt của beat đầu gói / ClkFreq (thời gian thật trên bus).
% Capture ILA trên bus thật có backpressure: chỉ lưu beat khi tvalid & tready.

opts = struct();

% Counter r_cnt (phải khớp sim_read_top.v / ILA):
%   ClkFreq : clock của counter (Hz)  -> 156.25e6 (6.4 ns/count)
%   CntBits : số bit của counter      -> 22 (quay vòng sau ~26.84 ms;
%             khoảng cách giữa 2 gói liên tiếp phải < 26.84 ms)
opts.ClkFreq      = 156.25e6;
opts.CntBits      = 22;

% Gói đầu bị cụt (ILA/capture bắt đầu giữa gói):
%   true  : tự bỏ gói đầu nếu không có header eCPRI hoặc sai độ dài (mặc định)
%   false : giữ lại
% (Beat sau tlast cuối cùng = gói cuối bị cụt -> luôn bị bỏ, có warning)
opts.TrimPartial  = true;

% Bỏ MỌI gói không hợp lệ (không phải eCPRI 0xAEFE hoặc độ dài khác payload size):
%   false : giữ, chỉ warning (mặc định)
%   true  : bỏ khỏi pcap
opts.DropInvalid  = false;
% ========================================================================

axis2pcap(axisFile, pcapFile, opts);

% winopen(pcapFile)   % open in Wireshark (Windows)
