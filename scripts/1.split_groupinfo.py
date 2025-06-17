
import sys
import os
from configparser import ConfigParser

#group_info = sys.argv[1]
#out_dir = sys.argv[2]
#one_gene = sys.argv[3]

config = sys.argv[1]
parser = ConfigParser()
parser.read(config)

group_info = parser.get('required_option', 'Group_information')
temp_dir = parser.get('required_option', 'Output_directory')+ '/' +parser.get('Result', 'temp_path') + '/'
out_dir = parser.get('required_option', 'Output_directory')+ '/' +parser.get('Result', 'temp_path') + '/groupinfo/'

f = open(group_info, 'r')
lines = f.readlines()

group_dict = dict()
for line in lines:
    key = '_'.join(line.split('\t')[0:2])
    #print(key)
    if key not in group_dict.keys():
        group_dict[key] = list()

    group_dict[key].append(line.split('\t')[2])


if '/' not in out_dir:
    out_dir += '/'

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

#if not os.path.exists(out_dir+'/'+one_gene):
#    os.makedirs(out_dir+'/'+one_gene)

g = open(temp_dir + 'group_info.stat','w')
for key, val in sorted(group_dict.items(),key = lambda item: len(item[1]), reverse=True):
    tmp = len(val) * (len(val)-1) / 2
    g.write('{} {}\n'.format(key,int(tmp)))
    if len(val)>1:
        with open(out_dir+key+'.txt','w') as out_data:
            for ID in val:
                out_data.write(key.split('_')[0])
                out_data.write('\t')
                out_data.write(key.split('_')[1])
                out_data.write('\t')
                out_data.write(ID)
#    else:
#         with open(parser.get('required_option','Output_directory')+'/'+parser.get('Result','temp_path')+'/'+parser.get('Temp_folders','one_gene_list')+'/'+key+'.txt','w') as out_data:
#            out_data.write(key.split('_')[0])
#            out_data.write('\t')
#            out_data.write(key.split('_')[1])
#            out_data.write('\t')
#            out_data.write(val[0])
g.close()
