import sys

if __name__ == "__main__":
    fname = sys.argv[1]
    print(fname)
    with open(fname, 'r') as f:
        lns = f.readlines()
        parsed_res = {}
        parsed_res['pulse'] = []
        parsed_res['space'] = []
        lns = lns[2:]
        for l in lns:
            
            l = l.strip('\n')
            #print(l)
            ll = l.split(' ')
            parsed_res[ll[0]].append(int(ll[1]))

        for i in range(0, len(parsed_res['pulse'])):
            print("pulse: {:6d}, space: {:6d}".format(parsed_res['pulse'][i], parsed_res['space'][i]))

