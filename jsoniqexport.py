#!/usr/bin/env python3
"""
Copyright (C) 2010 - 2021 Xilinx, Inc. All rights reserved.

This script takes a JSON packet dissection file from Wireshark as input and generates
output files to be used as stimulus input for ORAN example design simulation and/or
MATLAB for offline analysis

"""

# Script Details
__author__ = "Avinash Mohan"
__contact__ = "amohan@xilinx.com"
__email__ = "amohan@xilinx.com"
__copyright__ = "Copyright (C) 2010 - 2021 Xilinx, Inc. All rights reserved."
__date__ = "2025/06/20"
__credits__ = ["guozhenp@xilinx.com", "xud@xilinx.com"]
__deprecated__ = False
__status__ = "Beta"
__version__ = "0.2.2"

import json
import os
import argparse
import logging
#MOD - v0.1.2: corrected floating point precision issue reported by Xu
# Observation: 0.000493000 was interpreted wrongly by Python as 492.99999999999994 after multiplication
from decimal import Decimal, getcontext


# General functions
def tokenize(hexstring, length):
    """Takes an input hex string array and splits into list of substrings of defined length"""
    return (hexstring[0 + i:length + i]
            for i in range(0, len(hexstring), length))


def as_bytes(hexstring):
    """
        Splits hex string into list of bytes.
        """
    return [hexstring[i:i + 2] for i in range(0, len(hexstring), 2)]


def twos_complement(binstr, bits):
    """
       Generates 2's complement notation of a binary string for specified bits
       """
    value = int(binstr, 2)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value


class JSONPacketProcessor:
    """ Decodes the PCAP JSON data into components"""

    def __init__(self, inputfile, verbose=False, memonly=False):
        # Set up logging
        folderpath = os.getcwd()
        logfile = os.path.join(folderpath,
                               inputfile.replace(".json", "_jsonproc.log"))
        if verbose:
            logging.basicConfig(
                filename=logfile,
                level=logging.DEBUG,
                format='%(asctime)s %(levelname)-8s %(message)s',
                datefmt='%d-%m-%Y %H:%M:%S')
        else:
            logging.basicConfig(
                filename=logfile,
                level=logging.INFO,
                format='%(asctime)s %(levelname)-8s %(message)s',
                datefmt='%d-%m-%Y %H:%M:%S')
        # Logging levels are DEBUG, INFO, WARNING, ERROR, CRITICAL
        self.logger = logging.getLogger(__name__)
        # Read the JSON file
        fp = open(inputfile, 'r')
        self.data = json.loads(fp.read())
        self.memonly = memonly
        self.logger.info(
            "Number of packets detected in PCAP: " + str(len(self.data)))
        # Initialize data structures
        self.pktcount = 0
        self.iqpktcount = 0
        #MOD - v0.1.1: added hex word count for better traceability against mem file
        self.memhexwordcount = 0
        self.pkttype = None
        self.outhexarray = ""
        #self.dbgtrace = ""
        #MOD - v0.2.0: added support for hex value packet types in Wireshark 3.6.1 based on inputs from Xu
        self.pkttypedict = {
            '0': 'IQ Data',
            '2': 'Real-time Control Data',
            '0x00': 'IQ Data',
            '0x02': 'Real-time Control Data'
        }
        self.memdata = ""

    def extract_data_for_memfile(self, pkt):
        """
              Extracts the data required for .mem file from a given packet as string
              """
        dbgtrace = ""
        # Detect frame time and frame length
        dbgtrace += ''.join(["Packet ", str(self.pktcount), ": \n\t"])
        #MOD - v0.1.1: updated time parameter to us as per Gary's inputs
        #MOD - v0.1.2: corrected floating point precision issue reported by Xu
        # Observation: 0.000493000 was interpreted wrongly by Python as 492.99999999999994 after multiplication
        #pkttime = pkt['_source']['layers']['frame']['frame.time_delta']
        pkttime = pkt['_source']['layers']['frame']['frame.time_relative']
        #pktdeltahex = str(hex(int(float(pkttime) * 1e9))[2:].zfill(16))
        #pktdeltahex = str(hex(int(float(pkttime) * 1e6))[2:].zfill(16))
        # Set floating point precision to 6 decimals
        getcontext().prec = 6
        pktdeltahex = str(
            hex(int(Decimal(pkttime) * Decimal('1.0e6')))[2:].zfill(16))
        #print(Decimal(pkttime) * Decimal('1.0e6'))
        dbgtrace += ''.join(["Time: ", pkttime, " (0x", pktdeltahex, ")\n\t"])
        #dbgtrace += ''.join(["\t", str(Decimal(pkttime) * Decimal('1.0e6')), " => ", str(int(Decimal(pkttime) * Decimal('1.0e6'))), " => ", str(hex(int(Decimal(pkttime) * Decimal('1.0e6')))),"\n\t"])
        self.memdata += ''.join([pktdeltahex, '\n'])
        #MOD - v0.1.1: added hex word count for better traceability against mem file
        self.memhexwordcount = self.memhexwordcount + 1
        pktlen = pkt['_source']['layers']['frame']['frame.len']
        #MOD - v0.2.1: for pkts with length < 60 bytes, pad with additional zeroes at the end
        pkt_needs_padding = False
        if int(pktlen) < 60:
            pkt_needs_padding = True
            padbytes = 60 - int(pktlen)
            dbgtrace += ''.join([
                "Orig Pkt Len: ", pktlen, "; Needs padding by ",
                str(padbytes), " bytes\n\t"
            ])
            pktlen = '60'
        pktlenhex = str(hex(int(pktlen))[2:].zfill(16))
        dbgtrace += ''.join(["Pkt Len: ", pktlen, " (0x", pktlenhex, ")\n\t"])
        self.memdata += ''.join([pktlenhex, '\n'])
        #MOD - v0.1.1: added hex word count for better traceability against mem file
        self.memhexwordcount = self.memhexwordcount + 1
        #MOD - v0.2.0: added support for tag modifications in Wireshark 3.6.1 based on inputs from Xu
        pktdetected = False
        try:
            # Default key format for Wireshark version 2.6.9-O-RAN_FH_CUS
            self.pkttype = pkt['_source']['layers']['ecpri'][
                'eCPRI Common Header']['ecpri.message_type']
            pktdetected = True
        except KeyError as kerr:
            dbgtrace += ''.join([
                "Check for Wireshark 2.6.9 failed with key error: {0}".format(
                    kerr), "\n\t"
            ])
            pktdetected = False
        dbgtrace += ''.join([
            "Pass1 (WS 2.6.9) packet detection status: ",
            str(pktdetected), "\n\t"
        ])
        if not pktdetected:
            try:
                # Check for Wireshark version 3.6.1 key format
                self.pkttype = pkt['_source']['layers']['ecpri'][
                    'ecpri.header_tree']['ecpri.type']
                pktdetected = True
            except KeyError as kerr:
                print(
                    "ERROR: JSON file in unrecognized format. Refer to JSON extraction process in documentation for correct procedure"
                )
                dbgtrace += ''.join([
                    "Check for Wireshark 3.6.1 failed with key error: {0}".
                    format(kerr), "\n\t", "Killing script!"
                ])
                pktdetected = False
                self.logger.debug('\n' + dbgtrace)
                return False
            dbgtrace += ''.join([
                "Pass2 (WS 3.6.1) packet detection status: ",
                str(pktdetected), "\n\t"
            ])

        dbgtrace += ''.join([
            "Type: ", self.pkttype, " (", self.pkttypedict[self.pkttype], ")",
            "\n\t"
        ])
        pktraw = pkt['_source']['layers']['frame_raw'][0]
        #MOD - v0.2.1: for pkts with length < 60 bytes, pad with additional zeroes at the end
        if pkt_needs_padding:
            dbgtrace += ''.join(
                ["Pkt raw (",
                 str(len(pktraw)), "): ", pktraw, "\n\t"])
            dbgtrace += ''.join([
                "Adding ",
                str(padbytes), " padding bytes for min pkt size of 60 bytes",
                "\n\t"
            ])
            pktnew = pktraw.ljust(2 * 60, '0')
            dbgtrace += ''.join(
                ["Pkt is now (",
                 str(len(pktnew)), "): ", pktnew, "\n\t"])
            pktraw = pktnew
        pktdbgdata = []
        revhexstring = ''
        for hexstring in tokenize(pktraw, 16):
            #MOD - v0.2.2: zfill was wrongly adding leading zeroes to the last pkt; needed zero padding on trailing end only
            hex16string = hexstring.ljust(16,'0')
            pktdbgdata.append(hex16string)
            revdbgdata = reversed(as_bytes(hex16string))
            for byte in revdbgdata:
                revhexstring += str(byte)
            revhexstring += '\n'
        self.memdata += revhexstring
        #MOD - v0.1.1: added hex word count for better traceability against mem file
        self.memhexwordcount = self.memhexwordcount + len(pktdbgdata)
        dbgtrace += ''.join([
            "Raw Data: ", ','.join(pktdbgdata), "\n\tRev Data: ",
            revhexstring.replace('\n', ','), "\n\tMem data count @ EOP: ",
            str(self.memhexwordcount), "\n"
        ])
        self.logger.debug('\n' + dbgtrace)
        return True

    def extract_data_for_iqfiles(self, pkt):
        """
              Extracts the data required for IQ analysis file from a given packet as string(s)
              """
        dbgtrace = ""
        dbgtrace += '\n\t'
        sectioncount = pkt['_source']['layers']['oran_fh_cus'][
            'oran_fh_cus.numberOfsections']
        dbgtrace += ''.join([
            "IQ Packet ",
            str(self.iqpktcount), ": \n\t\tNumber of sections: ", sectioncount,
            "\n\t\t"
        ])
        section = pkt['_source']['layers']['oran_fh_cus']
        for key, val in section.items():
            if key.startswith('Section'):
                dbgtrace += ''.join([
                    "Section ID: ", val['oran_fh_cus.sectionId'],
                    "\n\t\tStarting PRB: ", val['oran_fh_cus.startPrbu'],
                    "\n\t\tNumber of PRBs: ", val['oran_fh_cus.numPrbu'],
                    "\n\t\t\t"
                ])
                for sectionkey, sectionval in val.items():
                    if sectionkey.startswith('PRB'):
                        payload = sectionval['oran_fh_cus.iq_user_data']
                        dbgtrace += ''.join(
                            [sectionkey, ": ", payload, "\n\t\t"])
                        # Split payload to list
                        payloadlist = payload.split(':')
                        dbgtrace += ''.join([
                            "\t\t\tPayload frame has ",
                            str(len(payloadlist)), " bytes => ",
                            str(int(len(payloadlist) / 2)), " words => ",
                            str(int(len(payloadlist) / 4)), " IQ pairs\n\t\t\t"
                        ])
                        bytelist = '\n'.join(payloadlist)
                        self.outhexarray += bytelist
                        self.outhexarray += '\n'
        self.iqpktcount = self.iqpktcount + 1
        self.logger.debug(dbgtrace)
        return True

    def generate_outputs(self):
        """
              Generates the processed output files from the input JSON file
              """
        for pkt in self.data:
            self.logger.info("Processing pkt " + str(self.pktcount))
            self.extract_data_for_memfile(pkt)
            if self.pkttype == "0" and self.memonly is False:
                # Process this section only for datapath
                self.logger.debug(
                    "Processing IQ for pkt " + str(self.pktcount))
                self.extract_data_for_iqfiles(pkt)
            self.pktcount = self.pktcount + 1
        print("\nDone!")
        self.logger.info("Number of packets processed: " + str(self.pktcount))
        self.logger.debug("Number of IQ payload packets processed: %d" %
                          (self.iqpktcount))


# Main starts here
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='\n\
This script takes a JSON packet dissection file from Wireshark as input and\n\
generates output files to be used as stimulus input for ORAN example design\n\
simulation and/or MATLAB for offline analysis\n\n\
Output Files Generated:\n\
   <jsonfile>_oran_sim.mem -- Stimulus file for ORAN example design simulation\n\
   <jsonfile>_iq.dump      -- IQ data in 16bit hex format\n\
   <jsonfile>_iq16.csv     -- IQ data (16bit) in signed decimal (I,Q) format',
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument(
        "jsonfile", type=str, help="Input JSON file exported from Wireshark")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Generate debug log file")
    parser.add_argument(
        "-all",
        "--generate_all",
        action="store_true",
        help=
        "Generate all output files (.mem & IQ csv/hex files) <Default Option> "
    )
    parser.add_argument(
        "-iq",
        "--generate_iq",
        action="store_true",
        help="Generate only IQ csv/hex output files ")
    parser.add_argument(
        "-mem",
        "--generate_mem",
        action="store_true",
        help="Generate only .mem output file for ORAN simulation ")
    args = parser.parse_args()
    if args.jsonfile is None:
        print("Error: No JSON file specified")
        quit()
    infile = args.jsonfile
    # Process JSON file
    pcap = JSONPacketProcessor(infile, args.verbose, args.generate_mem)
    pcap.generate_outputs()
    # Output files
    if not args.generate_iq:
        memfile = infile.replace(".json", "_oran_sim.mem")
        # Create mem file
        fmem = open(memfile, 'w')
        fmem.write(pcap.memdata)
        fmem.flush()
        fmem.close()

    if not args.generate_mem:
        outfile = infile.replace(".json", "_iq.hex")
        iqfile = infile.replace(".json", "_iq.dump")
        iqcsv1 = infile.replace(".json", "_iq16.csv")
        iqcsv2 = infile.replace(".json", "_iq15.csv")

        # Create output file
        fw = open(outfile, 'w')
        fw.write(pcap.outhexarray)
        fw.flush()
        fw.close()

        # Create IQ dump file
        hexwords = ""
        hexbyte1 = ""
        try:
            with open(outfile) as file:
                for hexbyte1 in file:
                    hexbyte2 = next(file)
                    hexword = hexbyte1.replace('\n', '') + hexbyte2
                    hexwords += hexword
                    #hexwords += '\n'
        except StopIteration:
            hexwords += hexbyte1
        #
        # Write dump file
        fw = open(iqfile, 'w')
        fw.write(hexwords)
        fw.flush()
        fw.close()

        # Create IQ CSV file
        csvlist = ""
        csvtrace = ""
        csv16list = ""
        wordcount = 0
        try:
            with open(iqfile) as file:
                for hexword1 in file:
                    wordcount = wordcount + 1
                    if wordcount % 2 == 0:
                        csv16list += str(
                            twos_complement(
                                str(
                                    bin(int(hexword1.replace('\n', ''),
                                            16))[2:].zfill(16)), 16)) + '\n'
                    else:
                        csv16list += str(
                            twos_complement(
                                str(
                                    bin(int(hexword1.replace('\n', ''),
                                            16))[2:].zfill(16)), 16)) + ','
                    csvlist += str(
                        bin(int(hexword1.replace('\n', ''), 16))[2:].zfill(16))
                    csvtrace += hexword1.replace('\n', '') + " => " + str(
                        bin(int(hexword1.replace('\n', ''),
                                16))[2:].zfill(16)) + "\n"
        except StopIteration:
            csvlist += ''

        # Write CSV output file
        fw = open(iqcsv1, 'w')
        fw.write(csv16list)
        fw.flush()
        fw.close()

    # Create debug trace files
    if args.verbose and args.generate_iq:
        # Create hex to bin conversion log for IQ CSV file
        dbgfile = infile.replace(".json", "_hex2bin.log")
        fw = open("hex2bin.log", 'w')
        fdbg = open(dbgfile, 'w')
        fdbg.write(csvtrace)
        fdbg.flush()
        fdbg.close()
