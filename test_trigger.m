%    create an instance of the io64 object
ioObj = io64; %#ok<*UNRCH>
%   initialize the interface to the inpoutx64 system driver
status = io64(ioObj); % if status = 0, you are now ready to write and read to a hardware port
%  EEG port address
address = hex2dec('4FB8');%standard LPT1 output port address

WaitSecs(.1);

io64(ioObj,address,1)

WaitSecs(.1);

io64(ioObj,address,0)

