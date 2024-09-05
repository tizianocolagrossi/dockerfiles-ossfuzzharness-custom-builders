#!/usr/bin/env python3

from statistics import median, mean, variance, stdev

from collections import defaultdict
import subprocess
from rich import print
import argparse
import json
# import sys
import os

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

import matplotlib as mpl

import tempfile
import shutil

import numpy as np

# import networkx as nx
import glob

TRIAGE_F5 = 'afltriageout-first_5_frames'
TRIAGE_F1 = 'afltriageout-first_frame'
LIBAFL_STATS_FILE = 'fuzzer_stats.csv'
CRASH_EXT = ".crash"

IMG_EXT    =".png"
IMG_PREFIX = ""

# create a keyvalue class 
class keyvalue(argparse.Action): 
    def __call__( self , parser, namespace, 
                 values, option_string = None): 
        if getattr(namespace, self.dest) == None:
            setattr(namespace, self.dest, dict()) 
        tag = values[0]
        getattr(namespace, self.dest)[tag] = values[1:] 

class Crash:
    granularity            = ""
    bucket_id              = ""
    exec_speed             = 0.0
    fault_find_at          = 0xFFFFFFFFFFFFFFFF
    fault_find_normalized  = 0xFFFFFFFFFFFFFFFF
    path_info_crash        = ""
    path_crash             = ""
    testcase_path          = ""
    testcases_equivalent   = []

    regression_test_status = []


    def __init__(self, path_info_crash, campaign_info_csv):
        self.regression_test_status = []
        self.path_info_crash = path_info_crash
        base = os.path.splitext(path_info_crash)[0]
        self.path_crash = base+CRASH_EXT
        self.exec_speed = float(campaign_info_csv.split('\n')[-2].split(',')[5])
        with open(self.path_info_crash, 'r') as file:
            json_data = file.read()
            json_data = json.loads(json_data)
            self.fault_find_at = int(json_data["faulting_execution_number"])
            self.bucket_id = json_data["bucket"]["strategy_result"]
            self.testcase_path = json_data["testcase"]
            self.testcases_equivalent = json_data["testcase_equivalent"]
        self.fault_find_normalized = self.fault_find_at/self.exec_speed
    
    def __eq__(self, other):
        return self.bucket_id == other.bucket_id
        
    
    def __hash__(self):
        return hash(self.bucket_id)

    def __str__(self):
        return self.__repr__()
    
    def __repr__(self):
        return f"{self.bucket_id}"
        # return f"Crash({self.bucket_id}, {self.regression_test_status})"
    
    def perform_regression(self, regression_software):
        
        temp_dir = tempfile.mkdtemp()
        crashes_dir = os.path.join(temp_dir, 'crashes')
        os.makedirs(crashes_dir)

        copy_file_to_directory(self.path_crash, crashes_dir)

        fuzzer_dirname = os.path.dirname(regression_software)
        fuzzer_name    = os.path.basename(regression_software)

        FUZZ_OUT       = temp_dir
        DEDUP_BUILD    = fuzzer_dirname
        FUZZER         = fuzzer_name
        cmd  = ["docker", "run", "-it", "--rm"]
        cmd += ["-v", f"{FUZZ_OUT}:/fuzz_out"]
        cmd += ["-v", f"{DEDUP_BUILD}:/dedup_build"]
        cmd += ["-e", f"FUZZING_ENGINE=libafl"]
        cmd += ["-t", "oss-base-analysis-crash", "analyze", FUZZER]

        # run outside docker
        # result = subprocess.run([regression_software, self.path_crash], capture_output=True, text=True)
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result)

        crash_found = os.listdir(os.path.join(temp_dir, TRIAGE_F1))
        print(crash_found)
        if len(crash_found) > 0:
            self.regression_test_status.append(("PERSIST", regression_software))
        else:
            self.regression_test_status.append(("NOT PERSIST", regression_software))

        shutil.rmtree(temp_dir)

def copy_file_to_directory(src_file, dest_dir):
    """
    Copies a file to a specified directory.

    :param src_file: The path to the source file to be copied.
    :param dest_dir: The path to the destination directory.
    :return: The path to the copied file.
    """
    try:
        # Check if the destination directory exists, if not, create it
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)
            print(f"Destination directory created at: {dest_dir}")

        # Copy the file to the destination directory
        dest_file = shutil.copy(src_file, dest_dir)
        print(f"File copied to: {dest_file}")

        return dest_file
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
        
def get_set_with_median_length(dict_of_list):
    # Get lengths of all lists
    lengths = [len(crashes) for crashes in dict_of_list.values()]
    
    # Find the median length
    median_length = median(lengths)
    
    # Find the list(s) with the median length
    median_lists = [value for key, value in dict_of_list.items() if len(value) == median_length]

    return set(median_lists[0])
    return

def get_set_with_median_time_crash(dict_of_list):
    # Get lengths of all lists
    mintime_by_crash = defaultdict(list)
    crash_by_bucket_id = defaultdict(list)
    for crash_by_campaign in dict_of_list.values():
        for crash in crash_by_campaign:
            mintime_by_crash[crash.bucket_id].append(crash.fault_find_normalized)
            crash_by_bucket_id[crash.bucket_id].append(crash)
    # print(mintime_by_crash)
    # print(crash_by_bucket_id)

    median_time_crashes = []
    for bucket_id in mintime_by_crash:
        median_time_fault_find = median(mintime_by_crash[bucket_id])
        # print(median_time_fault_find)
        for crash in crash_by_bucket_id[bucket_id]:
            if crash.fault_find_normalized == median_time_fault_find:
                median_time_crashes.append(crash)
                break
    
    return median_time_crashes

def get_prev_regression_alias(crash, prev_regression_crashes):
    tcaliases = [ tctmp.replace("/"+crash.regression_id, "") for tctmp in crash.testcases_equivalent]
    for prev_crash in prev_regression_crashes:
        prevtcaliases = [ tctmp.replace("/"+prev_crash.regression_id, "") for tctmp in prev_crash.testcases_equivalent]
        if len(set(tcaliases).intersection(set(prevtcaliases))) != 0:
            return prev_crash  
    return None

def assign_colors_markers(labels):
    # Available colors in matplotlib
    colors = plt.rcParams['axes.prop_cycle'].by_key()['color']
    # Available markers in matplotlib
    markers = ['o', 's', 'v', '^', '<', '>', '8', 'p', '*', 'h', 'H', 'D', 'd', 'P', 'X']

    # Ensure we have enough colors and markers
   
    unique_labels = list(set([label.replace('-cmplog', '').replace('_cmplog', '') for label in labels]))
    if len(unique_labels) > len(colors):
        raise ValueError("Number of unique labels exceeds available colors.")
    if len(unique_labels) > len(markers):
        raise ValueError("Number of unique labels exceeds available markers.")
    unique_labels.sort()

    # Create mappings for colors and markers
    label_to_color = {label: colors[i % len(colors)] for i, label in enumerate(unique_labels)}

    # Generate lists for colors and markers based on the input labels
    color_list = [label_to_color[label.replace('-cmplog', '').replace('_cmplog', '')] for label in labels]
    cmplog_marker   = 'X'
    nocmplog_marker = 'o'
    marker_list = [cmplog_marker if "cmplog" in label else nocmplog_marker for label in labels]

    legend_handles = []
    for label in label_to_color:
        c = label_to_color[label]
        legend_handles.append(Line2D([0], [0], marker="s", color='w', markerfacecolor=c, markersize=8, label=label))

    legend_handles.append(Line2D([0], [0], marker=cmplog_marker, color='w', markerfacecolor='black', markersize=8, label='cmplog'))
    legend_handles.append(Line2D([0], [0], marker=nocmplog_marker, color='w', markerfacecolor='black', markersize=8, label='no_cmplog'))

    return color_list, marker_list, legend_handles

def create_crash_time_to_trigger_plot(crash_grouping ,labels, title):

    data = defaultdict(list)
    # Fill the DataFrame with 1 where the element is in the set
    for set_name, s in zip(labels, crash_grouping):
        for element in s:
            data["Event"].append(element.bucket_id)
            data["Fuzzer"].append(set_name)
            data["Start"].append(element.fault_find_normalized)

    plt.figure(figsize=(10, 6))
    plt.grid(True)
    
    colors, markers, legend_handles = assign_colors_markers(data["Fuzzer"])
    # print(len(data["Start"]), len(colors), len(markers))   
    for i in range(len(data["Start"])):
        plt.scatter(data["Start"][i], data["Event"][i], color=colors[i], marker=markers[i], zorder=5)


    # Add titles and labels
    plt.title(title)
    plt.xlabel('executions normalized')
    plt.ylabel('crashes')
    
    # Add custom legend to the plot
    plt.legend(handles=legend_handles, title='Legend')
    # Show plot
    fst_sep = ''
    if IMG_PREFIX != '':
        fst_sep = '_'
    plt.savefig(f"{IMG_PREFIX}{fst_sep}{title.replace(' ', '_')}.{IMG_EXT}", bbox_inches='tight')
    return

def crate_crashes_intersections_plot(intersection_crash_matrix, title):
    plt.figure(figsize=(10, 6))
    sns.heatmap(intersection_crash_matrix, annot=False, cmap='viridis', cbar=True)
    plt.title(title)
    plt.xlabel('Crashes id')
    plt.ylabel('Fuzzers Campaigns')
    plt.savefig(f"{IMG_PREFIX}_{title.replace(' ', '_')}.{IMG_EXT}", bbox_inches='tight')
    return

def create_tte_violinplot(tte_grouping, labels, title):
    fig, ax = plt.subplots(nrows=1, ncols=1, figsize=(9, 4))

    # plot violin plot
    parts = ax.violinplot(tte_grouping,
                    showmeans=True,
                    showmedians=True,
                    showextrema=False)

    parts['cmedians'].set_color('#000')
    parts['cmeans'].set_color('C1')

    for pc in parts['bodies']:
        # pc.set_facecolor('#D43F3A')
        pc.set_edgecolor('black')
        pc.set_alpha(1)

    ax.set_title(f'Crashes TTE for {IMG_PREFIX}')

    # adding horizontal grid lines
    ax.yaxis.grid(True)
    ax.set_xticks([y + 1 for y in range(len(tte_grouping))],
                labels=labels, rotation=270)
    ax.set_xlabel('Fuzzing Types')
    ax.set_ylabel('times crash found')

    # Creating custom legend handles
    median_line = Line2D([0], [0], color='black', lw=2, label='Median')
    mean_line = Line2D([0], [0], color='C1', lw=2, label='Mean')

    # Adding the legend
    ax.legend(handles=[median_line, mean_line])

    plt.savefig(title, bbox_inches='tight')

def load_crashes(input_dirs):
    crashes = defaultdict(lambda: defaultdict(set))
    for type in input_dirs:
        for campaign_directory in input_dirs[type]:
            # print(campaign_directory)
            path_crash_frame_1 = os.path.join(campaign_directory, TRIAGE_F1)
            path_crash_frame_5 = os.path.join(campaign_directory, TRIAGE_F5)
            path_csv_stats = os.path.join(campaign_directory, LIBAFL_STATS_FILE)
            campaign_data_csv = ""
            if os.path.isfile(path_csv_stats):
                with open(path_csv_stats) as campaign_data_file:
                    campaign_data_csv = campaign_data_file.read()

            if os.path.isdir(path_crash_frame_1):
                for file in os.listdir(path_crash_frame_1):
                    if ".json" in file:
                        crash_metadata_triage_path = os.path.join(path_crash_frame_1, file)
                        c = Crash(crash_metadata_triage_path, campaign_data_csv)
                        crashes[type][campaign_directory].add(c)
    return crashes

def load_crashes_for_regression(inputs_dirs, base_regression_path):
    regression_paths_elaborated = defaultdict(lambda: defaultdict(list))

    for base in base_regression_path:
        for type in inputs_dirs:
            for terminal_portion in inputs_dirs[type]:          
                final_path = os.path.join(base, terminal_portion)
                final_paths_campaign = glob.glob(final_path)
                regression_base = base.split("/")[-1] if base.split("/")[-1] != '' else base.split("/")[-2]
                regression_paths_elaborated[type][regression_base]+=final_paths_campaign

    # print(regression_paths_elaborated)

    crashes = defaultdict(lambda: defaultdict(lambda: defaultdict(set)))
    for type in regression_paths_elaborated:
        for regression_base in regression_paths_elaborated[type]:
            for campaign_directory in regression_paths_elaborated[type][regression_base]:
                path_crash_frame_1 = os.path.join(campaign_directory, TRIAGE_F1)
                path_crash_frame_5 = os.path.join(campaign_directory, TRIAGE_F5)
                path_csv_stats = os.path.join(campaign_directory, LIBAFL_STATS_FILE)
                if os.path.isfile(path_csv_stats):
                    with open(path_csv_stats) as campaign_data_file:
                        campaign_data_csv = campaign_data_file.read()

                if os.path.isdir(path_crash_frame_1):
                    for file in os.listdir(path_crash_frame_1):
                        if ".json" in file:
                            crash_metadata_triage_path = os.path.join(path_crash_frame_1, file)
                            c = Crash(crash_metadata_triage_path, campaign_data_csv)
                            crashes[type][os.path.basename(campaign_directory)][regression_base].add(c)
    return crashes

def get_intersection_matrix(sets, sets_names, all_elements=[]):
     
    if len(all_elements) == 0 and len(sets) > 0:
        all_elements = list(set.union(*sets))

    intersection_crash_matrix = pd.DataFrame(0, index=sets_names, columns=all_elements)
    for campaign_name, crashes_in_campaign in zip(sets_names, sets):
        for crash in crashes_in_campaign:
            intersection_crash_matrix.at[campaign_name, crash] = 1
    intersection_crash_matrix = intersection_crash_matrix
    return intersection_crash_matrix

def perform_crash_analysis(input_dirs):
    
    crashes = load_crashes(input_dirs)
    # print(crashes)
    all_crashes= set()
    for ty in crashes:
        for campaign in crashes[ty]:
            all_crashes = all_crashes.union(crashes[ty][campaign])
    all_crashes = list(all_crashes)
    print(len(all_crashes))





    crashes_by_campaign = []
    campaign_names = []
    for type in crashes:
        for campaign_directory in crashes[type]:
            crashes_by_campaign.append(set(crashes[type][campaign_directory]))
            campaign_name = campaign_directory.split("/")[-1]
            # print(set_name)
            campaign_names.append(campaign_name)
    intersection_crash_matrix = get_intersection_matrix(crashes_by_campaign, campaign_names, all_elements=all_crashes)
    crate_crashes_intersections_plot(intersection_crash_matrix, f'Intersection of Crashes for {IMG_PREFIX}')
    

    crashes_by_fuzzer_type = []
    fuzzer_types = []
    for type in crashes:
        set_aggregated_campaign = set()
        for campaign_directory in crashes[type]:
            set_aggregated_campaign = set_aggregated_campaign.union(crashes[type][campaign_directory])
        crashes_by_fuzzer_type.append(set_aggregated_campaign)
        fuzzer_types.append(type)
 
    intersection_matrix = get_intersection_matrix(crashes_by_fuzzer_type, fuzzer_types, all_elements=all_crashes)
    crate_crashes_intersections_plot(intersection_matrix, f'Intersection of Crashes in aggregated campaigns for {IMG_PREFIX}')

    crashes_by_median_campaign = []
    median_campaigns = []
    for type in crashes:
        crashes_by_median_campaign.append(get_set_with_median_length(crashes[type]))
        median_campaigns.append(f"median_{type}")
    intersection_matrix = get_intersection_matrix(crashes_by_median_campaign, median_campaigns, all_elements=all_crashes)
    crate_crashes_intersections_plot(intersection_matrix, f'Intersection of Crashes in median campaigns for {IMG_PREFIX}')

###################################################################################################################
###################################################################################################################
###################################################################################################################
###################################################################################################################
###################################################################################################################

    group = []
    labels_group = []
    for type in crashes:
        # print(get_set_with_median_length(crashes[type]))
        group.append(get_set_with_median_length(crashes[type]))
        labels_group.append(type)

    create_crash_time_to_trigger_plot(group, labels_group, f"Crashes in time triggered median campaigns (by_n_crash) for {IMG_PREFIX}")

    group = []
    labels_group = []
    for type in crashes:
        # print(get_set_with_median_length(crashes[type]))
        group.append(get_set_with_median_time_crash(crashes[type]))
        labels_group.append(type)
    create_crash_time_to_trigger_plot(group, labels_group, f"Crashes in time triggered median campaigns (by_time_crash) for {IMG_PREFIX}")

    group = []
    labels_group = []
    for type in crashes:
        set_aggregated_campaign = list()
        for campaign_directory in crashes[type]:
            set_aggregated_campaign += crashes[type][campaign_directory]
        group.append(set_aggregated_campaign)
        labels_group.append(type)
    create_crash_time_to_trigger_plot(group, labels_group, f"Crashes in time triggered aggregated wiew for {IMG_PREFIX}")


    labels_group = []
    group = []

    for type in crashes:
        timesinruns_by_type = defaultdict(list)
        for campaign in crashes[type]:
            for crash in crashes[type][campaign]:
                timesinruns_by_type[type].append(crash.fault_find_normalized)
        # print(timesinruns_by_type)
        
        for type in timesinruns_by_type:
            labels_group.append(type)
            group.append(timesinruns_by_type[type])
    create_tte_violinplot(group, labels_group, f"{IMG_PREFIX}_crashes_ttl_by_fuzz_type.{IMG_EXT}")
        

 

def perform_regression_test_analysis(inputs_dirs, base_regression_path, regression_executables_path):

    # crashes = load_crashes(inputs_dirs)
    # for type in crashes:
    #     for campaign in crashes[type]:
    #         for crash in crashes[type][campaign]:
    #             for reg in regression_executables_path:
    #                 # print(crash)
    #                 crash.perform_regression(reg)
    #                 # print(crash, reg)

    # for type in crashes:
    #     for campaign in crashes[type]:
    #         print(f"Crash({crash.bucket_id} {crash.regression_test_status})")

    #crashes[type][ccampaign][regression] = set
    crashes = load_crashes_for_regression(inputs_dirs, base_regression_path)

    print(crashes)
    for type in crashes:
        for campaign in crashes[type]:
            regression_list = list(crashes[type][campaign].keys())
            initial_crashes = crashes[type][campaign][regression_list[0]]

            for crash in initial_crashes:
                print(crash.testcase_path)
                for regression in regression_list[1:]:
                    for reg_crash in crashes[type][campaign][regression]:
                        neutral_testcase_crash = crash.testcase_path.replace(regression_list[0], '')
                        neutral_eq_testcases_reg_crash = [tc.replace(regression, '') for tc in reg_crash.testcases_equivalent]
                        # print(neutral_testcase_crash, )
                        
                        if neutral_testcase_crash in neutral_eq_testcases_reg_crash:
                            print(regression, crash, ' eq ', reg_crash)
                    

    
                



    




def main():                                                        

    # Set global font to a monospaced font (e.g., 'Courier New')
    mpl.rcParams['font.family'] = 'monospace'
    mpl.rcParams['font.monospace'] = 'DejaVu Sans Mono'

    opt = argparse.ArgumentParser(description="DESC", formatter_class=argparse.RawTextHelpFormatter)
    opt.add_argument('-i'  , action=keyvalue, help="-i <type> paths (relative if case of regression)", required=True, nargs='+')
    opt.add_argument('-r'  , help="-r <path_regression_fuzzer_1> <path_regression_fuzzer_2>", required=False, nargs='+')
    opt.add_argument('-rb'  , help="-rb <base_path_regression_1> <base_path_regression_2>", required=False, nargs='+')
    opt.add_argument('-n', help="SUT name", required=True)
    opt.add_argument('-x', help="extension for output images", required=False, default='.jpg')
    args = opt.parse_args()

    inputs_dirs = args.i
    regression_executables_path = args.r
    base_regression_path = args.rb
    # print(inputs_dirs)
    # print(regression_bases)
    global IMG_PREFIX
    IMG_PREFIX = args.n
    
    if base_regression_path or regression_executables_path:
        perform_regression_test_analysis(inputs_dirs, base_regression_path, regression_executables_path)
    else:
        perform_crash_analysis(inputs_dirs)


    
    
    
if __name__ == "__main__":
    main()



