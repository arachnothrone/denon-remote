'''
Decoding raw stream from Denon RC-978 
captured with LIRC's mode2 command, e.g.:

    mode2 > denon_MUTE.txt

Looks like pulse-distance coding (pulse + short space = 0, pulse + long space = 1)

0x6413
0x1bf3

Avg pulse: 714.1, avg space 1: 325.5, avg space 0: 1373.2
Avg pulse: 727.0, avg space 1: 311.8, avg space 0: 1364.1
Avg pulse: 758.0, avg space 1: 286.7, avg space 0: 1325.2
733.0333333 308 1354.166667

'''
import sys


if __name__ == "__main__":
    fname = sys.argv[1]
    #print(fname)
    with open(fname, 'r') as f:
        lns = f.readlines()
        parsed_res = {}
        parsed_res['pulse'] = []
        parsed_res['space'] = []

        # remove system info, first space (a long one, beginning of the recording) and the last pulse (stop)
        lns = lns[2:-1]
        
        for l in lns:
            
            l = l.strip('\n')
            #print(l)
            ll = l.split(' ')
            if int(ll[1]) > 50:
                parsed_res[ll[0]].append(int(ll[1]))

        print("pulse_len={}, space_len={}".format(len(parsed_res['pulse']), len(parsed_res['space'])))
        decoded_value = 0x00
        decoded_val_str = ""
        avgPls = []
        avgSpc0 = []
        avgSpc1 = []

        for i in range(0, len(parsed_res['pulse'])):
            decoded_data_type = ""

            pls = parsed_res['pulse'][i]
            spc = parsed_res['space'][i]
            if (pls > 600) and (pls / spc < 0.1):
                # Header
                print("------------------------------------------------- >>> 0x{:0x} <--- Decoded".format(decoded_value))
                # print("------------------------------------------------- >>> 0x{:0x} {}".format(decoded_value, hex(int(decoded_val_str, 2))))
                decoded_data_type = "HEADER"
                decoded_value = 0x00
                decoded_val_str = ""
            elif (pls > 600) and (pls / spc > 1.6):
                # logial "0"
                decoded_data_type = "DATA_BIT_0"
                decoded_value <<= 1
                decoded_val_str = "0" + decoded_val_str

                avgPls.append(pls)
                avgSpc1.append(spc)

            elif (pls > 600) and (pls / spc < 1.0):
                # logical "1"
                decoded_data_type = "DATA_BIT_1"
                decoded_value <<= 1
                decoded_value += 1
                decoded_val_str = "1" + decoded_val_str

                avgPls.append(pls)
                avgSpc0.append(spc)

            else:
                decoded_data_type = "Unknown"

            print("pulse: {:6d}, space: {:6d} ---> {} {:0b}".format(pls, spc, decoded_data_type, decoded_value))

        # print("------------------------------------------------- >>> 0x{:0x} {}".format(decoded_value, hex(int(decoded_val_str, 2))))
        print("------------------------------------------------- >>> 0x{:0x} <--- Decoded".format(decoded_value))
        print("Avg pulse: {}, avg space 1: {}, avg space 0: {}".format(round(sum(avgPls) / len(avgPls), 1), round(sum(avgSpc1)/len(avgSpc1), 1), round(sum(avgSpc0)/len(avgSpc0), 1)))



