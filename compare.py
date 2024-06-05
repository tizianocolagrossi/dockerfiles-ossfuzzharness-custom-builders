#!/usr/bin/env python3

from rich.progress import track
from rich.spinner import Spinner

import statistics

from matplotlib.ticker import MaxNLocator
from collections import defaultdict
import matplotlib.pyplot as plt
from rich import print
import numpy as np
import argparse
import json
import sys
import os

def get_fuzzinfo_ddl(paths):
    ddl = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    counter = 0
    for tag, path in track(paths, "Getting fuzz info..."):
        counter += 1
        with open(path) as fd:
            lines = fd.readlines()
        for line in lines[2:]:
            run_time_secs,clients,corpus,objectives,executions,exec_sec,clients_info = line.split(',')
            ddl[tag][counter]['time'].append(int(run_time_secs))
            ddl[tag][counter]['corpus'].append(int(corpus))
            ddl[tag][counter]['objectives'].append(int(objectives))
            ddl[tag][counter]['exec_s'].append(float(exec_sec))
    return ddl

def get_total_amounts_llvm_cov(json_path):
    di = dict()
    with open(json_path, 'r') as fd:
        cov_data = json.load(fd)
    
    for coverage_type in cov_data['data'][0]['totals']:
        di[coverage_type]=cov_data['data'][0]['totals'][coverage_type]['percent']
    return di

def get_cov_ddl(paths):
    ddl = defaultdict(dict)
    counter=0
    for tag, json_path in track(paths, "Getting cov data..."):
        counter += 1
        di = get_total_amounts_llvm_cov(json_path)
        ddl[tag][counter]=di
    return ddl

def get_crash_dds(paths):
    dds = defaultdict(lambda: defaultdict(lambda: defaultdict(set)))
    counter = 0
    for tag, path_out in track(paths, "Getting crashes info..."):
        counter += 1
        afltriage_5f_dir = os.path.join(path_out, 'afltriageout-first_5_frames')
        afltriage_1f_dir = os.path.join(path_out, 'afltriageout-first_frame')

        dds[tag][counter]['first-frame'] = set(os.listdir(afltriage_1f_dir))
        dds[tag][counter]['first-5-frames'] = set(os.listdir(afltriage_5f_dir))
    
    return dds

def get_enumap_dl(paths):

    dl = defaultdict(list)
    for tag, path_mapdump in track(paths, "Getting enumeration map info..."):
        with open(os.path.join(path_mapdump), 'rb') as fd:
            data = fd.read()
            data_array = np.frombuffer(data, dtype=np.uint8)

        hitted = 0
        for x in data_array:
            if x != 0:
                hitted += 1    
        dl[tag].append(hitted)
    return dl

def plot_exec_corpus_obj(ddl, libname, ext):
    if ext[0] != '.':
        ext = '.'+ext

    fig, axs = plt.subplots(3, 1, layout='constrained', figsize=(13, 15))
    prefixes = []
    colors = ["C0","C1","C2","C3","C4","C5","C6","C7",]

    tags = list(ddl.keys())
    tags.sort()

    for tag in ddl:
        with_label = True

        # get median run
        tmp_execs_finals = []
        tmp_corpus_finals = []
        tmp_objects_finals = []

        for run in ddl[tag]:
            tmp_execs_finals.append( (ddl[tag][run]['exec_s'][-1],run) )
            tmp_corpus_finals.append( (ddl[tag][run]['corpus'][-1],run) )
            tmp_objects_finals.append( (ddl[tag][run]['objectives'][-1],run) )

            tmp_execs_finals.sort()
            tmp_corpus_finals.sort()
            tmp_objects_finals.sort()

        # print('tmp_execs_finals', tmp_execs_finals,  tmp_execs_finals[1][1])
        # print('tmp_corpus_finals',tmp_corpus_finals,tmp_corpus_finals[1][1])
        # print('tmp_objects_finals',tmp_objects_finals,tmp_objects_finals[1][1])

        run_execs_median = tmp_execs_finals[1][1]
        run_corpus_median = tmp_corpus_finals[1][1]
        run_objects_median = tmp_objects_finals[1][1]

        color = colors[tags.index(tag)]
        axs[0].plot(ddl[tag][run_execs_median]['time'], ddl[tag][run_execs_median]['exec_s'], c=color, label=tag)    
        axs[1].plot(ddl[tag][run_corpus_median]['time'], ddl[tag][run_corpus_median]['corpus'], c=color, label=tag)    
        axs[2].plot(ddl[tag][run_objects_median]['time'], ddl[tag][run_objects_median]['objectives'], c=color, label=tag)    

        # for run in ddl[tag]:
        #     color = colors[tags.index(tag)]
        #     if with_label:
        #         with_label=False
        #         axs[0].plot(ddl[tag][run]['time'], ddl[tag][run]['exec_s'], c=color, label=tag)    
        #         axs[1].plot(ddl[tag][run]['time'], ddl[tag][run]['corpus'], c=color, label=tag)    
        #         axs[2].plot(ddl[tag][run]['time'], ddl[tag][run]['objectives'], c=color, label=tag)    
        #     else:
        #         axs[0].plot(ddl[tag][run]['time'], ddl[tag][run]['exec_s'], c=color)
        #         axs[1].plot(ddl[tag][run]['time'], ddl[tag][run]['corpus'], c=color)
        #         axs[2].plot(ddl[tag][run]['time'], ddl[tag][run]['objectives'], c=color)

    axs[0].set_xlabel('Time (s)')
    axs[0].set_ylabel('exec_s')
    axs[0].grid(True)
    axs[0].legend() 

    axs[1].set_xlabel('Time (s)')
    axs[1].set_ylabel('corpus')
    axs[1].grid(True)
    axs[1].legend() 

    axs[2].set_xlabel('Time (s)')
    axs[2].set_ylabel('objectives')
    axs[2].grid(True)
    axs[2].legend()    

    plt.suptitle(libname)
    plt.savefig(f"{libname}_exec_corpus_obj_in_time{ext}")

def label_median_line(bp_data, ax):
    for line in bp_data['medians']:
        (x_l, y),(x_r, _) = line.get_xydata()
        if not np.isnan(y): 
            x_line_center = x_l + (x_r - x_l)/2
            y_line_center = y  # Since it's a line and it's horisontal
            # overlay the value:  on the line, from center to right
            ax.text(x_line_center, y_line_center, # Position
                    '%.1f' % y, # Value (3f = 3 decimal float)
                    verticalalignment='center', # Centered vertically with line 
                    fontsize=8, backgroundcolor="white")
            
def plot_cov_data(ddl, libname, ext):
    if ext[0] != '.':
        ext = '.'+ext
        
    fig, axs = plt.subplots(5, 1, layout='constrained', figsize=(8, 21))
    
    ddata = defaultdict(lambda: defaultdict(list))
    tags = list(ddl.keys())
    tags.sort()

    for tag in ddl:
        for run in ddl[tag]:
            for type in ddl[tag][run]:
                ddata[tag][type].append(ddl[tag][run][type])
    
    boxplot_data_br = []
    boxplot_data_fn = []
    boxplot_data_in = []
    boxplot_data_ln = []
    boxplot_data_re = []
    labels = []
    for tag in tags:
        boxplot_data_br.append(ddata[tag]['branches'])
        boxplot_data_fn.append(ddata[tag]['functions'])
        boxplot_data_in.append(ddata[tag]['instantiations'])
        boxplot_data_ln.append(ddata[tag]['lines'])
        boxplot_data_re.append(ddata[tag]['regions'])
        labels.append(tag)
    

    bp_data = axs[0].boxplot(boxplot_data_br)
    label_median_line(bp_data, axs[0])
    axs[0].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[0].set(title='branches', ylabel='cov (%)')
    axs[0].grid(True)

    bp_data = axs[1].boxplot(boxplot_data_fn)
    label_median_line(bp_data, axs[1])
    axs[1].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[1].set(title='functions', ylabel='cov (%)')
    axs[1].grid(True)

    bp_data = axs[2].boxplot(boxplot_data_in)
    label_median_line(bp_data, axs[2])
    axs[2].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[2].set(title='instantiations', ylabel='cov (%)')
    axs[2].grid(True)

    bp_data = axs[3].boxplot(boxplot_data_ln)
    label_median_line(bp_data, axs[3])
    axs[3].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[3].set(title='lines', ylabel='cov (%)')
    axs[3].grid(True)

    bp_data = axs[4].boxplot(boxplot_data_re)
    label_median_line(bp_data, axs[4])
    axs[4].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[4].set(title='regions', ylabel='cov (%)')
    axs[4].grid(True)

    plt.suptitle(libname)
    plt.savefig(f"{libname}_cov_report{ext}")
                
def plot_enumap_data(dl, libname, ext):
    if ext[0] != '.':
        ext = '.'+ext
        
    fig, ax = plt.subplots(1, 1, layout='constrained', figsize=(8, 6))
    
    labels=[]
    boxplot_data=[]

    for tag in dl:
        labels.append(tag)
        boxplot_data.append(dl[tag])
    
    bp_data = ax.boxplot(boxplot_data)
    label_median_line(bp_data, ax)
    ax.set_xticklabels(labels,rotation=45, fontsize=8)
    ax.set(title='enumap', ylabel='enumap entries covered')
    ax.grid(True)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

  
    plt.suptitle(libname)
    plt.savefig(f"{libname}_enum_report{ext}")

def plot_crashes(dds, libname, ext):
    
    if ext[0] != '.':
        ext = '.'+ext
        
    fig, axs = plt.subplots(3, 1, layout='constrained', figsize=(8, 13))
    
    ddata = defaultdict(lambda: defaultdict(list))
    tags = list(dds.keys())
    tags.sort()

    for tag in dds:
        for run in dds[tag]:
            for type in dds[tag][run]:
                ddata[tag][type].append(dds[tag][run][type])

    boxplot_data_first_1 = []
    boxplot_data_first_5 = []

    labels = []
    for tag in tags:
        tmp_fisrt_5 = []
        tmp_fisrt_1 = []
        for crashes in ddata[tag]['first-frame']:
            tmp_fisrt_1.append(len(crashes))
        for crashes in ddata[tag]['first-5-frames']: 
            tmp_fisrt_5.append(len(crashes))
        boxplot_data_first_1.append(tmp_fisrt_1)
        boxplot_data_first_5.append(tmp_fisrt_5)
        labels.append(tag)
    
    bp_data = axs[0].boxplot(boxplot_data_first_1)
    label_median_line(bp_data, axs[0])
                
    axs[0].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[0].set(title='afltriage first frame', ylabel='crashes')
    axs[0].grid(True)
    axs[0].yaxis.set_major_locator(MaxNLocator(integer=True))

    bp_data = axs[1].boxplot(boxplot_data_first_5)
    label_median_line(bp_data, axs[1])
    axs[1].set_xticklabels(labels,rotation=45, fontsize=8)
    axs[1].set(title='afltriage first 5 frames', ylabel='crashes')
    axs[1].grid(True)
    axs[1].yaxis.set_major_locator(MaxNLocator(integer=True))



    boxplot_data_first_1_all = []
    boxplot_data_first_5_all = []
    
    labels = []
    for tag in tags:
        set_fisrt_1 = set()
        set_fisrt_5 = set()
        for crashes in ddata[tag]['first-frame']:
            for c in crashes:
                set_fisrt_1.add(c)
        for crashes in ddata[tag]['first-5-frames']: 
            for c in crashes:
                set_fisrt_5.add(c)
        boxplot_data_first_1_all.append(len(set_fisrt_1))
        boxplot_data_first_5_all.append(len(set_fisrt_5))
        labels.append(tag)
    # print(boxplot_data_default_all)
    # print(boxplot_data_first_5_all)
    # print(labels)

    group_data = {
        'first-frame':boxplot_data_first_1_all,
        'first-5-frames':boxplot_data_first_5_all,
    }

    x = np.arange(len(labels))  # the label locations
    width = 0.25  # the width of the bars
    multiplier = 0

    for attribute, measurement in group_data.items():
        offset = width * multiplier
        rects = axs[2].bar(x + offset, measurement, width, label=attribute)
        axs[2].bar_label(rects, padding=3)
        multiplier += 1
    
    axs[2].yaxis.set_major_locator(MaxNLocator(integer=True))
    axs[2].margins(y=0.2)
    axs[2].set_xticks(x + width, labels, rotation=45)
    axs[2].legend()

    axs[2].set(title='afltriage all run deduplicated', ylabel='crashes')

    plt.suptitle(libname)
    plt.savefig(f"{libname}_crash_report{ext}")

# usage compare.py pdfload-xpdf-v4.00_*

# create a keyvalue class 
class keyvalue(argparse.Action): 
    def __call__( self , parser, namespace, 
                 values, option_string = None): 
        if getattr(namespace, self.dest) == None:
            setattr(namespace, self.dest, dict()) 
        tag = values[0]
        getattr(namespace, self.dest)[tag] = values[1:] 

def main():
    opt = argparse.ArgumentParser(description="DESC", formatter_class=argparse.RawTextHelpFormatter)
    opt.add_argument('-i'  , action=keyvalue, help="-i <type> paths", required=True, nargs='+')
    opt.add_argument('-n', help="SUT name", required=True)
    opt.add_argument('-x', help="extension for output images", required=False, default='.jpg')
    args = opt.parse_args()

    inputs_dirs = args.i

    # print(inputs_dirs)

    info_csv_path_to_analyze=[]
    enumap_dump_path_to_analyze=[]
    llvmcov_path_to_analyze=[]
    out_path_to_analyze=[]
    for tag in inputs_dirs:
        for path in inputs_dirs[tag]:
            info_csv_path = os.path.join(path, 'fuzzer_stats.csv')
            info_csv_path_to_analyze.append( (tag, info_csv_path) )

            enumap_dump_path = os.path.join(path, 'mapdump','cumulative.rawdump')
            enumap_dump_path_to_analyze.append( (tag, enumap_dump_path) )

            llvmcov_path = os.path.join(path, 'llvmcov.json')
            llvmcov_path_to_analyze.append( (tag, llvmcov_path) )

            out_path_to_analyze.append( (tag, path) )
    
    fuzzers_info = get_fuzzinfo_ddl(info_csv_path_to_analyze)
    
    fuzzers_code_coverage = get_cov_ddl(llvmcov_path_to_analyze)

    fuzzers_enum_coverage = get_enumap_dl(enumap_dump_path_to_analyze)

    fuzzers_crashes_deduplicated = get_crash_dds(out_path_to_analyze)

    name=args.n
    ext=args.x
    plot_exec_corpus_obj(fuzzers_info, name, ext)
    plot_cov_data(fuzzers_code_coverage, name, ext)
    plot_enumap_data(fuzzers_enum_coverage, name, ext)
    plot_crashes(fuzzers_crashes_deduplicated, name, ext )



if __name__ == "__main__":
    main()

# /home/tiziano/Documents/dockerfiles-ossfuzzharness-custom-builders/compare.py -i baseline -i baseline-cmplog -i enumetric -i enumetric-cmplog -i enumetric++ -i enumetric++-cmplog -i enumetricbb++ -i enumetricbb++


# /home/tiziano/Documents/dockerfiles-ossfuzzharness-custom-builders/compare.py -n xpdf-4.00         -i baseline /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_baseline-*         -i baseline-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_baseline_cmplog-*       -i enumetric /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_enumetric-*       -i enumetric-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_enumetric_cmplog-*       -i enumetric++ /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_enumetric++-*       -i enumetric++-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/xpdf-v4.00/pdfload-xpdf-v4.00_enumetric++_cmplog-*       -i enumetricbb++ /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/xpdf-v4.00/pdfload-xpdf-v4.00_enumetricbb++-*       -i enumetricbb++-cmplog /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/xpdf-v4.00/pdfload-xpdf-v4.00_enumetricbb++_cmplog-*
# /home/tiziano/Documents/dockerfiles-ossfuzzharness-custom-builders/compare.py -n exiv2-0.26        -i baseline /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_baseline-*               -i baseline-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_baseline_cmplog-*             -i enumetric /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_enumetric-*             -i enumetric-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_enumetric_cmplog-*             -i enumetric++ /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_enumetric++-*             -i enumetric++-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/exiv2-v0.26/exiv2-v0.26_enumetric++_cmplog-*             -i enumetricbb++ /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/exiv2-v0.26/exiv2-v0.26_enumetricbb++-*             -i enumetricbb++-cmplog /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/exiv2-v0.26/exiv2-v0.26_enumetricbb++_cmplog-*
# /home/tiziano/Documents/dockerfiles-ossfuzzharness-custom-builders/compare.py -n bloaty-2020-05-25 -i baseline /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_baseline-*   -i baseline-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_baseline_cmplog-* -i enumetric /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_enumetric-* -i enumetric-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_enumetric_cmplog-* -i enumetric++ /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_enumetric++-* -i enumetric++-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/bloaty-2020-05-25/bloaty-2020-05-25_enumetric++_cmplog-* -i enumetricbb++ /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/bloaty-2020-05-25/bloaty-2020-05-25_enumetricbb++-* -i enumetricbb++-cmplog /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/bloaty-2020-05-25/bloaty-2020-05-25_enumetricbb++_cmplog-*
# /home/tiziano/Documents/dockerfiles-ossfuzzharness-custom-builders/compare.py -n jsoncpp-v1.9.5    -i baseline /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_baseline-*         -i baseline-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_baseline_cmplog-*       -i enumetric /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetric-*       -i enumetric-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetric_cmplog-*       -i enumetric++ /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetric++-*       -i enumetric++-cmplog /home/tiziano/Documents/new-docker-run/enumetric-v0.2.6tmp0/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetric++_cmplog-*       -i enumetricbb++ /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetricbb++-*       -i enumetricbb++-cmplog /home/tiziano/Documents/new-docker-run/new-strategy-\(trans-ctx-bb\)/jsoncpp-v1.9.5/jsoncpp-v1.9.5_enumetricbb++_cmplog-*